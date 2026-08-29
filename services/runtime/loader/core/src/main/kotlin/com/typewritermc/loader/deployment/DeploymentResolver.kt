package com.typewritermc.loader.deployment

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.HostedArtifactManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.loader.artifact.ArtifactProvenance
import com.typewritermc.loader.artifact.DeploymentArtifact

@kotlinx.serialization.Serializable
data class ArtifactCandidate(
    val artifact: DeploymentArtifact,
    val manifest: ImprintManifest,
    val provenance: ArtifactProvenance,
    val importRevision: Long,
) {
    init {
        require(importRevision >= 1) { "Import revision must be positive." }
        require(artifact.coordinate.id == manifest.id) { "Artifact coordinate and manifest ids differ." }
        require(artifact.coordinate.version == manifest.version) { "Artifact coordinate and manifest versions differ." }
        require(artifact.kind == manifest.kind()) { "Artifact kind and manifest kind differ." }
        manifest.validateIntegrity()
    }
}

class CandidateIndex(
    candidates: Collection<ArtifactCandidate>,
) {
    private val accepted =
        candidates
            .groupBy { it.artifact.coordinate }
            .mapValues { (_, duplicates) -> duplicates.maxBy(ArtifactCandidate::importRevision) }
            .values
            .toList()

    fun realms(): List<ArtifactCandidate> = accepted.filter { it.manifest is RealmManifest }

    fun engines(id: ArtifactId): List<ArtifactCandidate> = accepted.filter { it.manifest is EngineManifest && it.manifest.id == id }

    fun extensions(): List<ArtifactCandidate> = accepted.filter { it.manifest is ExtensionManifest }
}

sealed interface ResolutionResult {
    data class Resolved(
        val content: DeploymentContent,
        val manifests: Map<ArtifactId, ImprintManifest>,
    ) : ResolutionResult

    data class Rejected(
        val problems: List<String>,
    ) : ResolutionResult
}

fun resolveDeployment(
    candidates: CandidateIndex,
    topology: RealmTopology,
    primaryEngine: PrimaryEngineTarget,
    intent: RealmLoaderIntent,
): ResolutionResult {
    val problems = mutableListOf<String>()
    val realms = candidates.realms()
    val realmIds = realms.map { it.manifest.id }.distinct()
    if (realmIds.size != 1) {
        problems += "Accepted candidates must contain exactly one Realm artifact identity."
    }

    val realm =
        realms
            .filter { it.supports(topology.hostApis.getValue(topology.realmHost)) }
            .maxByOrNull { it.artifact.coordinate.version }
            ?: run {
                problems += "No Realm artifact supports the Realm host API."
                null
            }
    val primary =
        candidates
            .engines(primaryEngine.id)
            .filter { primaryEngine.version.accepts(it.artifact.coordinate.version) }
            .filter { candidate ->
                topology.primaryEngineHosts.all { host -> candidate.supports(topology.hostApis.getValue(host)) }
            }.maxByOrNull { it.artifact.coordinate.version }
            ?: run {
                problems += "No compatible primary engine satisfies ${primaryEngine.id} ${primaryEngine.version}."
                null
            }
    val panel =
        candidates
            .engines(intent.panelEngine.id)
            .filter { intent.panelEngine.version.accepts(it.artifact.coordinate.version) }
            .filter { it.supports(topology.hostApis.getValue(topology.realmHost)) }
            .maxByOrNull { it.artifact.coordinate.version }
            ?: run {
                problems += "No compatible panel engine satisfies ${intent.panelEngine.id} ${intent.panelEngine.version}."
                null
            }
    val extensions =
        candidates
            .extensions()
            .groupBy { it.artifact.coordinate.id }
            .mapValues { (_, versions) -> versions.maxBy { it.artifact.coordinate.version } }
            .values
            .sortedBy { it.artifact.coordinate.id.value }

    if (problems.isNotEmpty() || realm == null || primary == null || panel == null) {
        return ResolutionResult.Rejected(problems)
    }
    val selected = listOf(realm, primary, panel) + extensions
    val conflictingCoordinates =
        selected
            .groupBy { it.artifact.coordinate.id }
            .filterValues { versions -> versions.map { it.artifact.coordinate }.distinct().size > 1 }
            .keys
    if (conflictingCoordinates.isNotEmpty()) {
        return ResolutionResult.Rejected(
            conflictingCoordinates
                .sortedBy(ArtifactId::value)
                .map { "Deployment artifact ${it.value} resolved to multiple versions." },
        )
    }
    val content =
        DeploymentContent(
            realm = realm.artifact,
            primaryEngine = primary.artifact,
            panelEngine = panel.artifact,
            extensions = extensions.map(ArtifactCandidate::artifact),
        ).canonical()
    return ResolutionResult.Resolved(
        content,
        selected.associate { it.manifest.id to it.manifest },
    )
}

private fun ArtifactCandidate.supports(hostApi: com.typewritermc.imprint.ArtifactVersion): Boolean =
    (manifest as HostedArtifactManifest).hostApi.accepts(hostApi)

private fun ImprintManifest.kind(): ArtifactKind =
    when (this) {
        is RealmManifest -> ArtifactKind.REALM
        is EngineManifest -> ArtifactKind.ENGINE
        is com.typewritermc.imprint.CapabilityManifest -> ArtifactKind.CAPABILITY
        is ExtensionManifest -> ArtifactKind.EXTENSION
    }

private fun ImprintManifest.validateIntegrity(): Unit =
    when (this) {
        is RealmManifest -> {
            Unit
        }

        is EngineManifest -> {
            require(resolvedCapabilities.map { it.id }.distinct().size == resolvedCapabilities.size) {
                "Engine capability graph contains duplicate artifact identities."
            }
            directCapabilities.forEach { requirement ->
                val resolved = resolvedCapabilities.singleOrNull { it.id == requirement.id }
                require(resolved != null && requirement.version.accepts(resolved.version)) {
                    "Engine capability requirement ${requirement.id} does not match its resolved graph."
                }
            }
            require(bundledComponents.map { it.id }.distinct().size == bundledComponents.size) {
                "Engine bundled components contain duplicate artifact identities."
            }
        }

        is ExtensionManifest -> {
            require(buildProvenance.map { it.id }.distinct().size == buildProvenance.size) {
                "Extension build provenance contains duplicate artifact identities."
            }
            sourceParts.forEach { sourcePart ->
                when (sourcePart) {
                    is EngineExtensionSourcePart -> {
                        require(sourcePart.requirement.version.accepts(sourcePart.resolved.version)) {
                            "Extension engine requirement ${sourcePart.requirement.id} does not match its provenance."
                        }
                    }

                    is CapabilityExtensionSourcePart -> {
                        sourcePart.requirements.forEach { requirement ->
                            val resolved = sourcePart.resolved.singleOrNull { it.id == requirement.id }
                            require(resolved != null && requirement.version.accepts(resolved.version)) {
                                "Extension capability requirement ${requirement.id} does not match its provenance."
                            }
                        }
                    }

                    CommonExtensionSourcePart -> {
                        Unit
                    }
                }
            }
        }

        is com.typewritermc.imprint.CapabilityManifest -> {
            require(resolvedCapabilities.map { it.id }.distinct().size == resolvedCapabilities.size) {
                "Capability graph contains duplicate artifact identities."
            }
            directRequirements.forEach { requirement ->
                val resolved = resolvedCapabilities.singleOrNull { it.id == requirement.id }
                require(resolved != null && requirement.version.accepts(resolved.version)) {
                    "Capability requirement ${requirement.id} does not match its resolved graph."
                }
            }
        }
    }
