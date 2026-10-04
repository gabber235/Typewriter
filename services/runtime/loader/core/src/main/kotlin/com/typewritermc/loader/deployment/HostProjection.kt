package com.typewritermc.loader.deployment

import com.typewritermc.discovery.DeploymentSelection
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.SourcePartEligibilityResolver
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.EngineImplementationTarget
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

/**
 * Describes service assignments, API versions, and deployment facts.
 *
 * Every assigned host must have an API version. The Realm host receives the panel engine as well; primary engines
 * use their own host set.
 */
@Serializable
data class RealmTopology(
    val realmService: ServiceId,
    val primaryEngineServices: Set<ServiceId>,
    val serviceApis: Map<ServiceId, com.typewritermc.imprint.ArtifactVersion>,
    val factsByService: Map<ServiceId, Map<String, String>> = emptyMap(),
) {
    init {
        require(serviceApis.keys.containsAll(assignedServices())) {
            "Every assigned service must declare its host API version."
        }
    }

    fun assignedServices(): Set<ServiceId> = primaryEngineServices + realmService

    fun factsFor(serviceId: ServiceId): Map<String, String> = factsByService[serviceId].orEmpty()
}

/** Assigns one selected artifact to the role it performs on a host. */
@Serializable
data class ProjectedRuntime(
    val placement: RuntimePlacement,
    val artifact: DeploymentArtifact,
    val implementation: EngineImplementationTarget? = null,
) {
    companion object {
        fun realm(artifact: DeploymentArtifact) = ProjectedRuntime(RuntimePlacement.REALM, artifact)

        fun panelEngine(artifact: DeploymentArtifact) = ProjectedRuntime(RuntimePlacement.PANEL_ENGINE, artifact)

        fun primaryEngine(artifact: DeploymentArtifact) = ProjectedRuntime(RuntimePlacement.PRIMARY_ENGINE, artifact)
    }
}

/** Records the source part decision made for one projected extension. */
@Serializable
data class ProjectedSourcePart(
    val name: String,
    val disposition: SourcePartDisposition,
)

/** Carries one extension and its host specific source part decisions. */
@Serializable
data class ProjectedExtension(
    val artifact: DeploymentArtifact,
    val sourceParts: List<ProjectedSourcePart>,
)

/**
 * Pins runtime roles, extension source part dispositions, and facts for one host generation.
 *
 * Canonicalization sorts roles, extensions, source parts, and fact keys. This projection is specific to a host
 * even when deployment content is shared.
 */
@Serializable
data class HostDeploymentProjection(
    val realmId: String,
    val generation: DeploymentGeneration,
    val serviceId: ServiceId,
    val runtimes: List<ProjectedRuntime>,
    val extensions: List<ProjectedExtension>,
    val publicationTarget: EngineImplementationTarget,
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
            publicationTarget = publicationTarget,
            facts = facts.toSortedMap(),
        )
}

/**
 * Serializes canonical projections as CBOR with defaults included.
 *
 * Decoding reconstructs metadata; retrieval must separately verify digest, host, Realm, and generation.
 */
@OptIn(ExperimentalSerializationApi::class)
object HostDeploymentProjectionCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(projection: HostDeploymentProjection): ByteArray = cbor.encodeToByteArray(projection.canonical())

    fun decode(bytes: ByteArray): HostDeploymentProjection = cbor.decodeFromByteArray(bytes)
}

/**
 * Derives runtime roles and source part eligibility for an assigned host.
 *
 * Unassigned hosts and missing required manifests are rejected. Extension parts retain eligible placements or
 * concrete reasons when none of the projected engines can load them.
 */
fun DeploymentSnapshot.projectFor(
    realmId: String,
    topology: RealmTopology,
    serviceId: ServiceId,
    manifests: Map<ArtifactId, ImprintManifest>,
): HostDeploymentProjection {
    require(serviceId in topology.assignedServices()) { "Cannot project a deployment for an unassigned service." }
    val projected = projectedRuntimes(topology, serviceId)
    val extensions = projectedExtensions(projected, manifests)
    val publicationTarget = primaryEngineImplementation(manifests)
    val runtimes =
        projected.map { runtime ->
            when (runtime.placement) {
                RuntimePlacement.REALM -> runtime
                RuntimePlacement.PRIMARY_ENGINE -> runtime.copy(implementation = publicationTarget)
                RuntimePlacement.PANEL_ENGINE -> runtime.copy(implementation = runtime.implementation(extensions))
            }
        }
    return HostDeploymentProjection(
        realmId = realmId,
        generation = generation,
        serviceId = serviceId,
        runtimes = runtimes,
        extensions = extensions,
        publicationTarget = publicationTarget,
        facts = topology.factsFor(serviceId),
    ).canonical()
}

private fun ProjectedRuntime.implementation(extensions: List<ProjectedExtension>): EngineImplementationTarget =
    EngineImplementationTarget(
        placement = placement,
        engine = artifact.toImplementationArtifact(emptyList()),
        extensions =
            extensions
                .mapNotNull { extension ->
                    extension.sourceParts
                        .filter { part ->
                            val eligible = part.disposition as? SourcePartDisposition.Eligible
                            eligible != null && placement in eligible.placements
                        }.map(ProjectedSourcePart::name)
                        .sorted()
                        .takeIf(List<String>::isNotEmpty)
                        ?.let(extension.artifact::toImplementationArtifact)
                }.sortedBy { it.id.value },
    )

private fun DeploymentSnapshot.primaryEngineImplementation(manifests: Map<ArtifactId, ImprintManifest>): EngineImplementationTarget {
    val engineArtifact = content.primaryEngine
    val engineManifest = manifests[engineArtifact.coordinate.id] as? EngineManifest
    requireNotNull(engineManifest) { "Primary engine ${engineArtifact.coordinate.id} is missing its engine manifest." }
    val extensionManifests = manifests.values.filterIsInstance<ExtensionManifest>()
    val selectedExtensions = content.extensions.mapTo(linkedSetOf()) { it.coordinate.id }
    val eligibleParts =
        SourcePartEligibilityResolver
            .resolve(DeploymentSelection(engineManifest, selectedExtensions), extensionManifests)
            .filter { it.eligibility is Eligibility.Eligible }
            .groupBy({ it.artifact }, { it.sourcePart })
    return EngineImplementationTarget(
        placement = RuntimePlacement.PRIMARY_ENGINE,
        engine = engineArtifact.toImplementationArtifact(emptyList()),
        extensions =
            content.extensions
                .mapNotNull { artifact ->
                    eligibleParts[artifact.coordinate.id]
                        ?.sorted()
                        ?.takeIf(List<String>::isNotEmpty)
                        ?.let(artifact::toImplementationArtifact)
                }.sortedBy { it.id.value },
    )
}

private fun DeploymentArtifact.toImplementationArtifact(sourceParts: List<String>) =
    EngineImplementationArtifact(
        id = coordinate.id,
        version = coordinate.version,
        digest = digest,
        sourceParts = sourceParts,
    )

private fun DeploymentSnapshot.projectedRuntimes(
    topology: RealmTopology,
    serviceId: ServiceId,
): List<ProjectedRuntime> =
    buildList {
        if (serviceId == topology.realmService) {
            add(ProjectedRuntime.realm(content.realm))
            add(ProjectedRuntime.panelEngine(content.panelEngine))
        }
        if (serviceId in topology.primaryEngineServices) {
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
