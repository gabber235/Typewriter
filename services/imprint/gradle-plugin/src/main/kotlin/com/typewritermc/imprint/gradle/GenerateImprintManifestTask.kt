package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ExtensionSourcePart
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.IMPRINT_CONTRIBUTIONS_PATH
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.FileCollection
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import java.io.File
import java.security.MessageDigest
import java.util.zip.ZipFile

private const val RECORD_SEPARATOR = '\u001F'
private const val LIST_SEPARATOR = '\u001E'
private const val HOSTED_RUNTIME_PROVIDER = "META-INF/services/com.typewritermc.loader.api.HostedRuntimeProvider"

internal fun Project.registerManifestTask(
    declaration: DeclaredArtifact,
    relationships: List<ConfiguredRelationship>,
    engineCoreArtifacts: FileCollection,
): org.gradle.api.tasks.TaskProvider<GenerateImprintManifestTask> {
    val productionParts =
        if (declaration.kind == ArtifactKind.EXTENSION) {
            listOf("common") + declaration.sourceParts.map(DeclaredSourcePart::name)
        } else {
            listOf("main")
        }
    val contributionFiles =
        fileTree(layout.buildDirectory.dir("generated/ksp")) {
            it.include("*/resources/$IMPRINT_CONTRIBUTIONS_PATH/**")
        }
    return tasks.register("generateImprintManifest", GenerateImprintManifestTask::class.java) { task ->
        task.artifactKind.set(declaration.kind.name)
        task.artifactId.set(declaration.id.value)
        task.artifactVersion.set(declaration.version.value)
        task.hostApiConstraint.set(declaration.hostApi?.expression.orEmpty())
        task.sourcePartKinds.set(
            declaration.sourceParts.map { sourcePart ->
                val kind =
                    when (sourcePart) {
                        is DeclaredEngineSourcePart -> ArtifactKind.ENGINE
                        is DeclaredCapabilitySourcePart -> ArtifactKind.CAPABILITY
                    }
                listOf(
                    sourcePart.name,
                    kind.name,
                    sourcePart.includes.joinToString(LIST_SEPARATOR.toString()),
                ).joinToString(RECORD_SEPARATOR.toString())
            },
        )
        task.relationshipRecords.set(
            providers.provider {
                relationships.map { relationship ->
                    val direct =
                        relationship.directFiles.files.singleOrNull()
                            ?: throw GradleException(
                                "Imprint relationship ${relationship.sourcePart} ${relationship.index} must resolve one artifact.",
                            )
                    listOf(
                        relationship.sourcePart,
                        relationship.index.toString(),
                        relationship.expectedKind.name,
                        relationship.constraint,
                        direct.sha256(),
                    ).joinToString(RECORD_SEPARATOR.toString())
                }
            },
        )
        task.relationshipArtifacts.from(relationships.map(ConfiguredRelationship::directFiles))
        task.graphArtifacts.from(relationships.map(ConfiguredRelationship::configuration))
        task.contributionFiles.from(contributionFiles)
        task.engineCoreArtifacts.from(engineCoreArtifacts)
        if (declaration.kind == ArtifactKind.REALM || declaration.kind == ArtifactKind.ENGINE) {
            task.providerArtifacts.from(
                configurations.getByName("runtimeClasspath"),
                fileTree("src/main/resources") { it.include(HOSTED_RUNTIME_PROVIDER) },
            )
        }
        task.outputFile.set(layout.buildDirectory.file("generated/imprint/artifact.cbor"))
        val kspTasks = productionParts.map { part -> if (part == "main") "kspKotlin" else "ksp${part.capitalized()}Kotlin" }
        task.dependsOn(tasks.matching { it.name in kspTasks })
    }
}

/** Produces the one canonical manifest embedded in an Imprint artifact. */
@CacheableTask
abstract class GenerateImprintManifestTask : DefaultTask() {
    @get:Input
    abstract val artifactKind: Property<String>

    @get:Input
    abstract val artifactId: Property<String>

    @get:Input
    abstract val artifactVersion: Property<String>

    @get:Input
    abstract val hostApiConstraint: Property<String>

    @get:Input
    abstract val sourcePartKinds: ListProperty<String>

    @get:Input
    abstract val relationshipRecords: ListProperty<String>

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val relationshipArtifacts: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val graphArtifacts: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val contributionFiles: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val engineCoreArtifacts: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val providerArtifacts: ConfigurableFileCollection

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun generate() {
        val id = ArtifactId(artifactId.get())
        val version = ArtifactVersion(artifactVersion.get())
        val kind = ArtifactKind.valueOf(artifactKind.get())
        val allManifests = readGraphManifests()
        val relationships = readRelationships(allManifests)
        val localContributions = readContributions(id)
        val engineCoreContributions = if (kind == ArtifactKind.ENGINE) readEngineCoreContributions(id) else emptyList()
        if (kind in setOf(ArtifactKind.REALM, ArtifactKind.ENGINE)) {
            validateHostedRuntimeProvider()
        }
        val manifest =
            when (kind) {
                ArtifactKind.REALM -> {
                    RealmManifest(
                        id = id,
                        version = version,
                        hostApi = requiredHostApi(),
                        contributions = canonicalContributions(localContributions),
                    )
                }

                ArtifactKind.ENGINE -> {
                    engineManifest(id, version, relationships, allManifests, localContributions + engineCoreContributions)
                }

                ArtifactKind.CAPABILITY -> {
                    capabilityManifest(id, version, relationships, allManifests, localContributions)
                }

                ArtifactKind.EXTENSION -> {
                    extensionManifest(id, version, relationships, allManifests, localContributions)
                }
            }
        outputFile.get().asFile.apply {
            parentFile.mkdirs()
            writeBytes(ImprintManifestCodec.encode(manifest))
        }
    }

    private fun validateHostedRuntimeProvider() {
        val providers =
            providerArtifacts.files
                .flatMap { file ->
                    when {
                        file.isDirectory -> {
                            file
                                .resolve(HOSTED_RUNTIME_PROVIDER)
                                .takeIf(File::isFile)
                                ?.readLines()
                                .orEmpty()
                        }

                        file.isFile && file.invariantSeparatorsPath.endsWith(HOSTED_RUNTIME_PROVIDER) -> {
                            file.readLines()
                        }

                        file.isFile && file.name.endsWith(".jar") -> {
                            ZipFile(file).use { archive ->
                                archive
                                    .getEntry(HOSTED_RUNTIME_PROVIDER)
                                    ?.let { entry ->
                                        archive.getInputStream(entry).bufferedReader().readLines()
                                    }.orEmpty()
                            }
                        }

                        else -> {
                            emptyList()
                        }
                    }
                }.map(String::trim)
                .filter { it.isNotEmpty() && !it.startsWith('#') }
                .distinct()
        if (providers.size != 1) {
            throw GradleException(
                "A hosted artifact must supply exactly one HostedRuntimeProvider, but found ${providers.size}.",
            )
        }
    }

    private fun requiredHostApi(): VersionConstraint {
        val expression = hostApiConstraint.get()
        if (expression.isBlank()) {
            throw GradleException("Hosted Imprint artifacts must declare a host API constraint.")
        }
        return VersionConstraint(expression)
    }

    private fun readGraphManifests(): Map<ArtifactId, ImprintManifest> {
        val manifests =
            graphArtifacts.files
                .sortedBy(File::getAbsolutePath)
                .mapNotNull(::readManifestOrNull)
        val duplicates =
            manifests.groupBy(ImprintManifest::id).filterValues { values ->
                values.map { it.version to it::class }.distinct().size > 1
            }
        if (duplicates.isNotEmpty()) {
            throw GradleException("Conflicting Imprint artifacts resolved for ${duplicates.keys.joinToString()}.")
        }
        return manifests.associateBy(ImprintManifest::id)
    }

    private fun readRelationships(allManifests: Map<ArtifactId, ImprintManifest>): List<ResolvedRelationship> =
        relationshipRecords
            .get()
            .map { record ->
                val fields = record.split(RECORD_SEPARATOR)
                if (fields.size != 5) throw GradleException("Invalid internal Imprint relationship record.")
                val file =
                    relationshipArtifacts.files.singleOrNull { it.sha256() == fields[4] }
                        ?: throw GradleException("Cannot associate an Imprint relationship with its resolved artifact.")
                val manifest =
                    readManifestOrNull(file)
                        ?: throw GradleException("Dependency ${file.name} does not contain $IMPRINT_MANIFEST_PATH.")
                val expectedKind = ArtifactKind.valueOf(fields[2])
                val actual = manifest.descriptor()
                if (actual.kind != expectedKind) {
                    throw GradleException(
                        "Dependency path ${fields[0]} requires $expectedKind but ${manifest.id} is ${actual.kind}.",
                    )
                }
                val constraint = VersionConstraint(fields[3])
                if (!constraint.accepts(manifest.version)) {
                    throw GradleException(
                        "Dependency path ${fields[0]} ${manifest.id} ${manifest.version} does not satisfy $constraint.",
                    )
                }
                if (allManifests[manifest.id] == null) {
                    throw GradleException("Resolved Imprint dependency ${manifest.id} is absent from the dependency graph.")
                }
                ResolvedRelationship(fields[0], fields[1].toInt(), constraint, manifest)
            }.sortedWith(compareBy(ResolvedRelationship::sourcePart, ResolvedRelationship::index))

    private fun engineManifest(
        id: ArtifactId,
        version: ArtifactVersion,
        relationships: List<ResolvedRelationship>,
        allManifests: Map<ArtifactId, ImprintManifest>,
        localContributions: List<GeneratedContribution>,
    ): EngineManifest {
        val direct = canonicalRequirements(relationships.map(ResolvedRelationship::requirement), id.value)
        val graph = resolveCapabilityGraph(relationships, allManifests)
        val capabilityContributions =
            graph.flatMap { descriptor -> allManifests.getValue(descriptor.id).contributions }
        return EngineManifest(
            id = id,
            version = version,
            hostApi = requiredHostApi(),
            directCapabilities = direct,
            resolvedCapabilities = graph,
            bundledComponents = graph,
            contributions = canonicalContributions(localContributions + capabilityContributions),
        )
    }

    private fun capabilityManifest(
        id: ArtifactId,
        version: ArtifactVersion,
        relationships: List<ResolvedRelationship>,
        allManifests: Map<ArtifactId, ImprintManifest>,
        localContributions: List<GeneratedContribution>,
    ): CapabilityManifest =
        CapabilityManifest(
            id = id,
            version = version,
            directRequirements = canonicalRequirements(relationships.map(ResolvedRelationship::requirement), id.value),
            resolvedCapabilities = resolveCapabilityGraph(relationships, allManifests),
            contributions = canonicalContributions(localContributions),
        )

    private fun extensionManifest(
        id: ArtifactId,
        version: ArtifactVersion,
        relationships: List<ResolvedRelationship>,
        allManifests: Map<ArtifactId, ImprintManifest>,
        localContributions: List<GeneratedContribution>,
    ): ExtensionManifest {
        val parts = mutableListOf<ExtensionSourcePart>(CommonExtensionSourcePart)
        val provenance = linkedMapOf<ArtifactId, ResolvedArtifact>()
        val guarantees = linkedMapOf<String, SourcePartGuarantee>()
        sourcePartKinds.get().sorted().forEach { sourcePartRecord ->
            val fields = sourcePartRecord.split(RECORD_SEPARATOR, limit = 3)
            val name = fields[0]
            val kindName = fields[1]
            val includes =
                fields
                    .getOrElse(2) { "" }
                    .split(LIST_SEPARATOR)
                    .filter(String::isNotBlank)
                    .sorted()
            val sourceRelationships = relationships.filter { it.sourcePart == name }
            when (val kind = ArtifactKind.valueOf(kindName)) {
                ArtifactKind.ENGINE -> {
                    val relationship = sourceRelationships.single()
                    val engine = relationship.manifest as EngineManifest
                    val descriptor = engine.descriptor()
                    parts += EngineExtensionSourcePart(name, relationship.requirement, descriptor, includes)
                    guarantees[name] =
                        EngineSourcePartGuarantee(
                            engine.id,
                            relationship.constraint,
                            engine.resolvedCapabilities.associateBy(ResolvedArtifact::id),
                        )
                    provenance[descriptor.id] = descriptor
                    engine.resolvedCapabilities.forEach { provenance[it.id] = it }
                }

                ArtifactKind.CAPABILITY -> {
                    val graph = resolveCapabilityGraph(sourceRelationships, allManifests)
                    parts +=
                        CapabilityExtensionSourcePart(
                            name,
                            canonicalRequirements(
                                sourceRelationships.map(ResolvedRelationship::requirement),
                                name,
                            ),
                            graph,
                            includes,
                        )
                    guarantees[name] = CapabilitySourcePartGuarantee(graph.associateBy(ResolvedArtifact::id))
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
            id = id,
            version = version,
            sourceParts = parts,
            buildProvenance = provenance.values.sortedBy { it.id.value },
            contributions = canonicalContributions(localContributions),
        )
    }

    private fun validateIncludedTargets(
        sourceParts: List<ExtensionSourcePart>,
        guarantees: Map<String, SourcePartGuarantee>,
    ) {
        sourceParts.filter { it != CommonExtensionSourcePart }.forEach { sourcePart ->
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
                            throw GradleException(
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
                            throw GradleException(
                                "Extension source set ${sourcePart.name} cannot include engine specific source set " +
                                    "$includedName because they do not target the same engine contract.",
                            )
                        }
                    }
                }
            }
        }
    }

    private fun resolveCapabilityGraph(
        direct: List<ResolvedRelationship>,
        allManifests: Map<ArtifactId, ImprintManifest>,
    ): List<ResolvedArtifact> {
        val mergedRequirements = linkedMapOf<ArtifactId, VersionConstraint>()
        val resolved = linkedMapOf<ArtifactId, ResolvedArtifact>()
        val visiting = mutableListOf<ArtifactId>()

        fun resolve(requirement: ArtifactRequirement) {
            val merged =
                mergedRequirements[requirement.id]?.intersect(requirement.version) ?: requirement.version
            if (mergedRequirements[requirement.id] != null &&
                mergedRequirements.getValue(requirement.id).intersect(requirement.version) == null
            ) {
                throw GradleException(
                    "Dependency path ${(visiting + requirement.id).joinToString(" > ")} has incompatible constraints.",
                )
            }
            mergedRequirements[requirement.id] = merged
            val manifest =
                allManifests[requirement.id]
                    ?: throw GradleException(
                        "Dependency path ${(visiting + requirement.id).joinToString(" > ")} has no resolved manifest.",
                    )
            if (manifest !is CapabilityManifest) {
                throw GradleException(
                    "Dependency path ${(visiting + requirement.id).joinToString(" > ")} requires a capability.",
                )
            }
            if (!merged.accepts(manifest.version)) {
                throw GradleException(
                    "Dependency path ${(visiting + requirement.id).joinToString(" > ")} resolved ${manifest.version}, " +
                        "which does not satisfy $merged.",
                )
            }
            if (requirement.id in visiting) {
                throw GradleException(
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

    private fun readContributions(origin: ArtifactId): List<GeneratedContribution> =
        contributionFiles.files
            .sortedBy(File::getAbsolutePath)
            .map { file ->
                val path = file.invariantSeparatorsPath
                val resourcesMarker = "/resources/$IMPRINT_CONTRIBUTIONS_PATH/"
                if (resourcesMarker !in path) throw GradleException("Unsafe Imprint contribution path ${file.name}.")
                val prefix = path.substringBefore(resourcesMarker)
                val sourcePart = prefix.substringAfterLast('/')
                val contributionPath = path.substringAfter(resourcesMarker)
                val producer = contributionPath.substringBefore('/')
                val name = contributionPath.substringAfter('/', "")
                if (sourcePart.isBlank() || producer.isBlank() || name.isBlank() ||
                    contributionPath.split('/').any { it == "." || it == ".." }
                ) {
                    throw GradleException("Unsafe Imprint contribution path $contributionPath.")
                }
                GeneratedContribution(origin, sourcePart, producer, name, file.readBytes())
            }.let(::canonicalContributions)

    private fun readEngineCoreContributions(origin: ArtifactId): List<GeneratedContribution> {
        if (engineCoreArtifacts.isEmpty) return emptyList()
        val artifact =
            engineCoreArtifacts.files.singleOrNull()
                ?: throw GradleException("An engine must resolve exactly one direct engine core artifact.")
        if (!artifact.isFile || !artifact.name.endsWith(".jar")) {
            throw GradleException("Engine core contribution artifact ${artifact.name} must be a JAR.")
        }
        val prefix = "$IMPRINT_CONTRIBUTIONS_PATH/"
        return ZipFile(artifact)
            .use { archive ->
                archive
                    .entries()
                    .asSequence()
                    .filterNot { it.isDirectory }
                    .filter { it.name.startsWith(prefix) }
                    .map { entry ->
                        val contributionPath = entry.name.removePrefix(prefix)
                        val producer = contributionPath.substringBefore('/')
                        val name = contributionPath.substringAfter('/', "")
                        if (producer.isBlank() || name.isBlank()) {
                            throw GradleException("Unsafe engine core contribution path ${entry.name}.")
                        }
                        GeneratedContribution(
                            origin = origin,
                            sourcePart = "main",
                            producer = producer,
                            name = "core/$name",
                            payload = archive.getInputStream(entry).use { it.readBytes() },
                        )
                    }.toList()
            }.let(::canonicalContributions)
    }

    private fun canonicalContributions(contributions: List<GeneratedContribution>): List<GeneratedContribution> {
        val duplicates =
            contributions
                .groupBy { listOf(it.origin.value, it.sourcePart, it.producer, it.name) }
                .filterValues { it.size > 1 }
        if (duplicates.isNotEmpty()) {
            throw GradleException("Duplicate Imprint contribution keys: ${duplicates.keys.joinToString()}.")
        }
        return contributions.sortedWith(
            compareBy(
                { it.origin.value },
                GeneratedContribution::sourcePart,
                GeneratedContribution::producer,
                GeneratedContribution::name,
            ),
        )
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
                throw GradleException(
                    "Dependency path $dependencyPath > ${requirement.id} has incompatible constraints.",
                )
            }
            constraints[requirement.id] = merged
        }
        return constraints.map { (id, version) -> ArtifactRequirement(id, version) }.sortedBy { it.id.value }
    }
}

private data class ResolvedRelationship(
    val sourcePart: String,
    val index: Int,
    val constraint: VersionConstraint,
    val manifest: ImprintManifest,
) {
    val requirement: ArtifactRequirement
        get() = ArtifactRequirement(manifest.id, constraint)
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

private fun ImprintManifest.descriptor(): ResolvedArtifact =
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

private fun readManifestOrNull(file: File): ImprintManifest? {
    if (!file.isFile || !file.name.endsWith(".jar")) return null
    return ZipFile(file).use { archive ->
        val entry = archive.getEntry(IMPRINT_MANIFEST_PATH) ?: return@use null
        try {
            ImprintManifestCodec.decode(archive.getInputStream(entry).readBytes())
        } catch (exception: Exception) {
            throw GradleException("Cannot read Imprint manifest from ${file.name}: ${exception.message}", exception)
        }
    }
}

private fun File.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(readBytes()).joinToString("") { byte -> "%02x".format(byte) }
