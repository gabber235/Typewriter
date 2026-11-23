package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.COMMON_SOURCE_PART
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.EntryTypeId
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ExtensionSourcePart
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.PluginRequirement
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint

internal data class ResolvedRelationship(
    val sourcePart: String,
    val index: Int,
    val constraint: VersionConstraint,
    val manifest: ImprintManifest,
) {
    val requirement: ArtifactRequirement
        get() = ArtifactRequirement(manifest.id, constraint)
}

internal data class ManifestSourcePart(
    val name: String,
    val kind: ArtifactKind,
    val includes: List<String>,
    val plugins: List<PluginRequirement>,
)

internal data class ManifestDependencies(
    val relationships: List<ResolvedRelationship>,
    val manifests: Map<ArtifactId, ImprintManifest>,
    val capabilityGraph: List<ResolvedArtifact>,
)

internal fun resolveManifestDependencies(
    context: ManifestAssemblyContext,
    relationships: List<ResolvedRelationship>,
    manifests: Map<ArtifactId, ImprintManifest>,
): ManifestDependencies =
    ManifestDependencies(
        relationships = relationships,
        manifests = manifests,
        capabilityGraph =
            when (context.artifactKind) {
                ArtifactKind.ENGINE,
                ArtifactKind.CAPABILITY,
                -> resolveCapabilityGraph(relationships, manifests)

                ArtifactKind.REALM,
                ArtifactKind.EXTENSION,
                -> emptyList()
            },
    )

internal fun createManifest(
    context: ManifestAssemblyContext,
    hostApi: VersionConstraint?,
    sourceParts: List<ManifestSourcePart>,
    dependencies: ManifestDependencies,
    content: ManifestContent,
    handledEntries: Map<String, List<EntryTypeId>>,
): ImprintManifest =
    when (context.artifactKind) {
        ArtifactKind.REALM -> {
            RealmManifest(
                id = context.artifactId,
                version = context.artifactVersion,
                hostApi = hostApi.requireHosted(context),
                runtimeEntrypointClass = content.runtimeEntrypoints.single(),
                contributions = content.contributions,
            )
        }

        ArtifactKind.ENGINE -> {
            EngineManifest(
                id = context.artifactId,
                version = context.artifactVersion,
                hostApi = hostApi.requireHosted(context),
                runtimeEntrypointClass = content.runtimeEntrypoints.single(),
                directCapabilities =
                    canonicalRequirements(
                        dependencies.relationships.map(ResolvedRelationship::requirement),
                        context.artifactId.value,
                    ),
                resolvedCapabilities = dependencies.capabilityGraph,
                bundledComponents = dependencies.capabilityGraph,
                contributions = content.contributions,
            )
        }

        ArtifactKind.CAPABILITY -> {
            CapabilityManifest(
                id = context.artifactId,
                version = context.artifactVersion,
                directRequirements =
                    canonicalRequirements(
                        dependencies.relationships.map(ResolvedRelationship::requirement),
                        context.artifactId.value,
                    ),
                resolvedCapabilities = dependencies.capabilityGraph,
                contributions = content.contributions,
            )
        }

        ArtifactKind.EXTENSION -> {
            extensionManifest(
                context = context,
                sourceParts = sourceParts,
                dependencies = dependencies,
                content = content,
                handledEntries = handledEntries,
            )
        }
    }

internal fun ImprintManifest.descriptor(): ResolvedArtifact =
    ResolvedArtifact(
        id = id,
        version = version,
        kind =
            when (this) {
                is EngineManifest -> ArtifactKind.ENGINE
                is CapabilityManifest -> ArtifactKind.CAPABILITY
                is ExtensionManifest -> ArtifactKind.EXTENSION
                is RealmManifest -> ArtifactKind.REALM
            },
    )

private fun extensionManifest(
    context: ManifestAssemblyContext,
    sourceParts: List<ManifestSourcePart>,
    dependencies: ManifestDependencies,
    content: ManifestContent,
    handledEntries: Map<String, List<EntryTypeId>>,
): ExtensionManifest {
    val known = sourceParts.map(ManifestSourcePart::name).toSet() + COMMON_SOURCE_PART
    (handledEntries.keys - known).firstOrNull()?.let { unknown ->
        throw IllegalArgumentException("Handled entries name unknown source part $unknown.")
    }

    fun handled(part: String): List<EntryTypeId> = handledEntries[part].orEmpty().distinct().sortedBy(EntryTypeId::canonicalText)
    val parts = mutableListOf<ExtensionSourcePart>(CommonExtensionSourcePart(handled(COMMON_SOURCE_PART)))
    val provenance = linkedMapOf<ArtifactId, ResolvedArtifact>()
    val guarantees = linkedMapOf<String, SourcePartGuarantee>()
    sourceParts.sortedBy(ManifestSourcePart::name).forEach { sourcePart ->
        val sourceRelationships = dependencies.relationships.filter { it.sourcePart == sourcePart.name }
        when (sourcePart.kind) {
            ArtifactKind.ENGINE -> {
                val relationship = sourceRelationships.single()
                val engine = relationship.manifest as EngineManifest
                val descriptor = engine.descriptor()
                parts +=
                    EngineExtensionSourcePart(
                        sourcePart.name,
                        relationship.requirement,
                        descriptor,
                        sourcePart.includes.sorted(),
                        neededPlugins(sourcePart, sourceParts),
                        handled(sourcePart.name),
                    )
                guarantees[sourcePart.name] =
                    EngineSourcePartGuarantee(
                        engine.id,
                        relationship.constraint,
                        engine.resolvedCapabilities.associateBy(ResolvedArtifact::id),
                    )
                provenance[descriptor.id] = descriptor
                engine.resolvedCapabilities.forEach { provenance[it.id] = it }
            }

            ArtifactKind.CAPABILITY -> {
                val graph = resolveCapabilityGraph(sourceRelationships, dependencies.manifests)
                parts +=
                    CapabilityExtensionSourcePart(
                        sourcePart.name,
                        canonicalRequirements(
                            sourceRelationships.map(ResolvedRelationship::requirement),
                            sourcePart.name,
                        ),
                        graph,
                        sourcePart.includes.sorted(),
                        neededPlugins(sourcePart, sourceParts),
                        handled(sourcePart.name),
                    )
                guarantees[sourcePart.name] = CapabilitySourcePartGuarantee(graph.associateBy(ResolvedArtifact::id))
                graph.forEach { provenance[it.id] = it }
            }

            ArtifactKind.EXTENSION -> {
                error("Extensions cannot target extensions.")
            }

            ArtifactKind.REALM -> {
                error("Extensions cannot target Realm artifacts.")
            }
        }
    }
    validateIncludedTargets(parts, guarantees)
    return ExtensionManifest(
        id = context.artifactId,
        version = context.artifactVersion,
        sourceParts = parts,
        buildProvenance = provenance.values.sortedBy { it.id.value },
        contributions = content.contributions,
    )
}

/** The plugins [sourcePart] uses itself and those of every part it includes, directly or through another include. */
private fun neededPlugins(
    sourcePart: ManifestSourcePart,
    sourceParts: List<ManifestSourcePart>,
): List<PluginRequirement> {
    val partsByName = sourceParts.associateBy(ManifestSourcePart::name)
    val reached = linkedSetOf<String>()

    fun reach(name: String) {
        if (!reached.add(name)) return
        partsByName.getValue(name).includes.forEach(::reach)
    }
    reach(sourcePart.name)
    return reached.flatMap { partsByName.getValue(it).plugins }.distinct().sortedBy(PluginRequirement::name)
}

private fun VersionConstraint?.requireHosted(context: ManifestAssemblyContext): VersionConstraint =
    this ?: throw IllegalArgumentException(
        "Hosted Imprint artifact ${context.artifactId} must declare a host API constraint.",
    )

private fun validateIncludedTargets(
    sourceParts: List<ExtensionSourcePart>,
    guarantees: Map<String, SourcePartGuarantee>,
) {
    sourceParts.filter { it !is CommonExtensionSourcePart }.forEach { sourcePart ->
        val includingGuarantee = guarantees.getValue(sourcePart.name)
        sourcePart.includes.forEach { includedName ->
            val includedGuarantee = guarantees.getValue(includedName)
            when (includedGuarantee) {
                is CapabilitySourcePartGuarantee -> {
                    val missing =
                        includedGuarantee.capabilities.values.filter { includedCapability ->
                            includingGuarantee.capabilities[includedCapability.id] != includedCapability
                        }
                    if (missing.isNotEmpty()) {
                        throw IllegalArgumentException(
                            "Extension source set ${sourcePart.name} cannot include $includedName because its target " +
                                "does not guarantee capabilities ${missing.joinToString { it.id.value }}.",
                        )
                    }
                }

                is EngineSourcePartGuarantee -> {
                    val includingEngine = includingGuarantee as? EngineSourcePartGuarantee
                    if (includingEngine == null ||
                        includingEngine.engineId != includedGuarantee.engineId ||
                        !includingEngine.constraint.isEquivalentTo(includedGuarantee.constraint)
                    ) {
                        throw IllegalArgumentException(
                            "Extension source set ${sourcePart.name} cannot include engine specific source set " +
                                "$includedName because they do not target the same engine contract.",
                        )
                    }
                }
            }
        }
    }
}

/**
 * Validates the exact Gradle selections against every reachable manifest requirement. Constraints accumulate
 * across dependency paths, so revisiting an already resolved capability still checks the new intersection.
 * This validates the selected graph rather than choosing another version when constraints conflict.
 */
private fun resolveCapabilityGraph(
    direct: List<ResolvedRelationship>,
    allManifests: Map<ArtifactId, ImprintManifest>,
): List<ResolvedArtifact> {
    val mergedRequirements = linkedMapOf<ArtifactId, VersionConstraint>()
    val resolved = linkedMapOf<ArtifactId, ResolvedArtifact>()
    val visiting = mutableListOf<ArtifactId>()

    fun resolve(requirement: ArtifactRequirement) {
        val merged = mergedRequirements[requirement.id]?.intersect(requirement.version) ?: requirement.version
        if (mergedRequirements[requirement.id] != null &&
            mergedRequirements.getValue(requirement.id).intersect(requirement.version) == null
        ) {
            throw IllegalArgumentException(
                "Dependency path ${(visiting + requirement.id).joinToString(" > ")} has incompatible constraints.",
            )
        }
        mergedRequirements[requirement.id] = merged
        val manifest =
            allManifests[requirement.id]
                ?: throw IllegalArgumentException(
                    "Dependency path ${(visiting + requirement.id).joinToString(" > ")} has no resolved manifest.",
                )
        if (manifest !is CapabilityManifest) {
            throw IllegalArgumentException(
                "Dependency path ${(visiting + requirement.id).joinToString(" > ")} requires a capability.",
            )
        }
        if (!merged.accepts(manifest.version)) {
            throw IllegalArgumentException(
                "Dependency path ${(visiting + requirement.id).joinToString(" > ")} resolved ${manifest.version}, " +
                    "which does not satisfy $merged.",
            )
        }
        if (requirement.id in visiting) {
            throw IllegalArgumentException(
                "Cyclic capability dependency path ${(visiting + requirement.id).joinToString(" > ")}.",
            )
        }
        if (resolved[requirement.id] != null) return

        visiting += requirement.id
        manifest.directRequirements.forEach(::resolve)
        visiting.removeLast()
        resolved[requirement.id] = manifest.descriptor()
    }

    direct.map(ResolvedRelationship::requirement).forEach(::resolve)
    return resolved.values.sortedBy { it.id.value }
}

private fun canonicalRequirements(
    requirements: List<ArtifactRequirement>,
    dependencyPath: String,
): List<ArtifactRequirement> {
    val constraints = linkedMapOf<ArtifactId, VersionConstraint>()
    requirements.forEach { requirement ->
        val existing = constraints[requirement.id]
        val merged = existing?.intersect(requirement.version) ?: requirement.version
        if (existing != null && existing.intersect(requirement.version) == null) {
            throw IllegalArgumentException(
                "Dependency path $dependencyPath > ${requirement.id} has incompatible constraints.",
            )
        }
        constraints[requirement.id] = merged
    }
    return constraints.map { (id, version) -> ArtifactRequirement(id, version) }.sortedBy { it.id.value }
}

private sealed interface SourcePartGuarantee {
    val capabilities: Map<ArtifactId, ResolvedArtifact>
}

private data class EngineSourcePartGuarantee(
    val engineId: ArtifactId,
    val constraint: VersionConstraint,
    override val capabilities: Map<ArtifactId, ResolvedArtifact>,
) : SourcePartGuarantee

private data class CapabilitySourcePartGuarantee(
    override val capabilities: Map<ArtifactId, ResolvedArtifact>,
) : SourcePartGuarantee
