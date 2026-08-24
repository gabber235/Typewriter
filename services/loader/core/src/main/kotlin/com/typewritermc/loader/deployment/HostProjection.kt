package com.typewritermc.loader.deployment

import com.typewritermc.discovery.DeploymentSelection
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.SourcePartEligibilityResolver
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.artifact.DeploymentArtifact
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

@JvmInline
@Serializable
value class HostId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Host id must not be blank." }
    }
}

@Serializable
data class RealmTopology(
    val realmHost: HostId,
    val primaryEngineHosts: Set<HostId>,
    val hostApis: Map<HostId, com.typewritermc.imprint.ArtifactVersion>,
    val factsByHost: Map<HostId, Map<String, String>> = emptyMap(),
) {
    init {
        require(hostApis.keys.containsAll(assignedHosts())) { "Every assigned host must declare its host API version." }
    }

    fun assignedHosts(): Set<HostId> = primaryEngineHosts + realmHost

    fun factsFor(hostId: HostId): Map<String, String> = factsByHost[hostId].orEmpty()
}

@Serializable
data class ProjectedRuntime(
    val placement: RuntimePlacement,
    val artifact: DeploymentArtifact,
) {
    companion object {
        fun realm(artifact: DeploymentArtifact) = ProjectedRuntime(RuntimePlacement.REALM, artifact)

        fun panelEngine(artifact: DeploymentArtifact) = ProjectedRuntime(RuntimePlacement.PANEL_ENGINE, artifact)

        fun primaryEngine(artifact: DeploymentArtifact) = ProjectedRuntime(RuntimePlacement.PRIMARY_ENGINE, artifact)
    }
}

@Serializable
data class ProjectedSourcePart(
    val name: String,
    val disposition: SourcePartDisposition,
)

@Serializable
data class ProjectedExtension(
    val artifact: DeploymentArtifact,
    val sourceParts: List<ProjectedSourcePart>,
)

@Serializable
data class HostDeploymentProjection(
    val realmId: String,
    val generation: DeploymentGeneration,
    val hostId: HostId,
    val runtimes: List<ProjectedRuntime>,
    val extensions: List<ProjectedExtension>,
    val facts: Map<String, String>,
) {
    fun canonical(): HostDeploymentProjection =
        copy(
            runtimes = runtimes.sortedBy { it.placement.name },
            extensions =
                extensions
                    .sortedBy { it.artifact.coordinate.id.value }
                    .map { extension ->
                        extension.copy(sourceParts = extension.sourceParts.sortedBy(ProjectedSourcePart::name))
                    },
            facts = facts.toSortedMap(),
        )
}

@OptIn(ExperimentalSerializationApi::class)
object HostDeploymentProjectionCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(projection: HostDeploymentProjection): ByteArray = cbor.encodeToByteArray(projection.canonical())

    fun decode(bytes: ByteArray): HostDeploymentProjection = cbor.decodeFromByteArray(bytes)
}

fun DeploymentSnapshot.projectFor(
    realmId: String,
    topology: RealmTopology,
    hostId: HostId,
    manifests: Map<ArtifactId, ImprintManifest>,
): HostDeploymentProjection {
    require(hostId in topology.assignedHosts()) { "Cannot project a deployment for an unassigned host." }
    val runtimes = projectedRuntimes(topology, hostId)
    val extensions = projectedExtensions(runtimes, manifests)
    return HostDeploymentProjection(
        realmId = realmId,
        generation = generation,
        hostId = hostId,
        runtimes = runtimes,
        extensions = extensions,
        facts = topology.factsFor(hostId),
    ).canonical()
}

private fun DeploymentSnapshot.projectedRuntimes(
    topology: RealmTopology,
    hostId: HostId,
): List<ProjectedRuntime> =
    buildList {
        if (hostId == topology.realmHost) {
            add(ProjectedRuntime.realm(content.realm))
            add(ProjectedRuntime.panelEngine(content.panelEngine))
        }
        if (hostId in topology.primaryEngineHosts) {
            add(ProjectedRuntime.primaryEngine(content.primaryEngine))
        }
    }

private fun DeploymentSnapshot.projectedExtensions(
    runtimes: List<ProjectedRuntime>,
    manifests: Map<ArtifactId, ImprintManifest>,
): List<ProjectedExtension> {
    val extensionManifests = manifests.values.filterIsInstance<ExtensionManifest>()
    val selectedExtensions = content.extensions.mapTo(linkedSetOf()) { it.coordinate.id }
    val eligibilityByPlacement =
        runtimes
            .filter { it.placement != RuntimePlacement.REALM }
            .associate { runtime ->
                val engine = manifests[runtime.artifact.coordinate.id] as? EngineManifest
                requireNotNull(engine) { "Runtime ${runtime.artifact.coordinate.id} is missing its engine manifest." }
                val entries =
                    SourcePartEligibilityResolver
                        .resolve(DeploymentSelection(engine, selectedExtensions), extensionManifests)
                        .associateBy { it.artifact to it.sourcePart }
                runtime.placement to entries
            }
    return content.extensions.map { artifact ->
        val manifest = manifests[artifact.coordinate.id] as? ExtensionManifest
        requireNotNull(manifest) { "Extension ${artifact.coordinate.id} is missing its manifest." }
        ProjectedExtension(
            artifact = artifact,
            sourceParts =
                manifest.sourceParts.map { sourcePart ->
                    val eligiblePlacements =
                        eligibilityByPlacement
                            .filterValues { entries ->
                                entries.getValue(manifest.id to sourcePart.name).eligibility is Eligibility.Eligible
                            }.keys
                    val disposition =
                        if (eligiblePlacements.isNotEmpty()) {
                            SourcePartDisposition.Eligible(eligiblePlacements)
                        } else {
                            val reasons =
                                eligibilityByPlacement.values
                                    .map { it.getValue(manifest.id to sourcePart.name).eligibility }
                                    .filterIsInstance<Eligibility.Ineligible>()
                                    .flatMap(Eligibility.Ineligible::reasons)
                                    .distinct()
                                    .ifEmpty { listOf("No projected engine can load this source part.") }
                            SourcePartDisposition.Ineligible(reasons)
                        }
                    ProjectedSourcePart(sourcePart.name, disposition)
                },
        )
    }
}
