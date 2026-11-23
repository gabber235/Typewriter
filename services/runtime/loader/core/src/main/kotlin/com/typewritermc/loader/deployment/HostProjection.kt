package com.typewritermc.loader.deployment

import com.typewritermc.discovery.DeploymentSelection
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.EnginePlugins
import com.typewritermc.discovery.IneligibleReason
import com.typewritermc.discovery.SourcePartCatalogEntry
import com.typewritermc.discovery.SourcePartEligibilityResolver
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.EnabledPlugin
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.loader.api.EngineCoverage
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.EngineImplementationTarget
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.SourcePartKey
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

/**
 * Pins the responding host roles, API versions, enabled plugins and facts used to select deployment artifacts.
 *
 * This selection comes from presence observations, not a complete backend assignment snapshot. Every selected
 * host must have an API version. The Realm host also receives the panel engine; primary engines use their own set.
 * A host's plugins decide which source parts its engines run; a host absent from [pluginsByService] reports none.
 */
@Serializable
data class RealmDeploymentSelection(
    val realmService: ServiceId,
    val primaryEngineServices: Set<ServiceId>,
    val serviceApis: Map<ServiceId, com.typewritermc.imprint.ArtifactVersion>,
    val factsByService: Map<ServiceId, Map<String, String>> = emptyMap(),
    val pluginsByService: Map<ServiceId, List<EnabledPlugin>> = emptyMap(),
) {
    init {
        require(serviceApis.keys.containsAll(selectedServices())) {
            "Every selected service must declare its host API version."
        }
    }

    fun selectedServices(): Set<ServiceId> = primaryEngineServices + realmService

    fun factsFor(serviceId: ServiceId): Map<String, String> = factsByService[serviceId].orEmpty()

    fun pluginsOf(serviceId: ServiceId): List<EnabledPlugin> = pluginsByService[serviceId].orEmpty()
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
 * Derives runtime roles and source part eligibility for a selected host.
 *
 * Unselected hosts and missing required manifests are rejected. Extension parts retain eligible placements or
 * concrete reasons when none of the projected engines can load them; the plugins [serviceId] reports take part in
 * that decision, so a change in them changes this host's projection alone. The publication target ignores plugins:
 * it stands for every primary engine, whatever each one has enabled.
 */
fun DeploymentSnapshot.projectFor(
    realmId: String,
    selection: RealmDeploymentSelection,
    serviceId: ServiceId,
    manifests: Map<ArtifactId, ImprintManifest>,
): HostDeploymentProjection {
    require(serviceId in selection.selectedServices()) { "Cannot project a deployment for an unselected service." }
    val projected = projectedRuntimes(selection, serviceId)
    val extensions = projectedExtensions(projected, manifests, EnginePlugins.Reported(selection.pluginsOf(serviceId)))
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
        facts = selection.factsFor(serviceId),
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
            .resolve(DeploymentSelection(engineManifest, selectedExtensions, EnginePlugins.Unchecked), extensionManifests)
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
    selection: RealmDeploymentSelection,
    serviceId: ServiceId,
): List<ProjectedRuntime> =
    buildList {
        if (serviceId == selection.realmService) {
            add(ProjectedRuntime.realm(content.realm))
            add(ProjectedRuntime.panelEngine(content.panelEngine))
        }
        if (serviceId in selection.primaryEngineServices) {
            add(ProjectedRuntime.primaryEngine(content.primaryEngine))
        }
    }

private fun DeploymentSnapshot.projectedExtensions(
    runtimes: List<ProjectedRuntime>,
    manifests: Map<ArtifactId, ImprintManifest>,
    plugins: EnginePlugins,
): List<ProjectedExtension> {
    val eligibilityByPlacement = eligibilityByPlacement(runtimes, manifests, plugins)
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
                                    .flatMap { ineligible -> ineligible.reasons.map(IneligibleReason::message) }
                                    .distinct()
                                    .ifEmpty { listOf("No projected engine can load this source part.") }
                            SourcePartDisposition.Ineligible(reasons)
                        }
                    ProjectedSourcePart(sourcePart.name, disposition)
                },
        )
    }
}

/** Each engine runtime of [runtimes] with every source part's eligibility on it, judged with [plugins]. */
private fun DeploymentSnapshot.eligibilityByPlacement(
    runtimes: List<ProjectedRuntime>,
    manifests: Map<ArtifactId, ImprintManifest>,
    plugins: EnginePlugins,
): Map<RuntimePlacement, Map<Pair<ArtifactId, String>, SourcePartCatalogEntry>> {
    val extensionManifests = manifests.values.filterIsInstance<ExtensionManifest>()
    val selectedExtensions = content.extensions.mapTo(linkedSetOf()) { it.coordinate.id }
    return runtimes
        .filter { it.placement != RuntimePlacement.REALM }
        .associate { runtime ->
            val engine = manifests[runtime.artifact.coordinate.id] as? EngineManifest
            requireNotNull(engine) { "Runtime ${runtime.artifact.coordinate.id} is missing its engine manifest." }
            val entries =
                SourcePartEligibilityResolver
                    .resolve(DeploymentSelection(engine, selectedExtensions, plugins), extensionManifests)
                    .associateBy { it.artifact to it.sourcePart }
            runtime.placement to entries
        }
}

/**
 * What the engines of the Realm run in this deployment: the panel engine on the Realm's host and every primary engine
 * host of [selection], each judged with the plugins it reports. A part no engine runs says what it needs: an engine of
 * the wrong kind is no reason while one of the part's kind exists, and without one the part needs that kind once.
 */
fun DeploymentSnapshot.engineCoverage(
    selection: RealmDeploymentSelection,
    manifests: Map<ArtifactId, ImprintManifest>,
): EngineCoverage {
    val selected = content.extensions.mapTo(hashSetOf()) { it.coordinate.id }
    val onEngines =
        selection
            .selectedServices()
            .flatMap { service ->
                eligibilityByPlacement(
                    projectedRuntimes(selection, service),
                    manifests,
                    EnginePlugins.Reported(selection.pluginsOf(service)),
                ).flatMap { (placement, entries) -> entries.values.map { placement to it } }
            }.filter { (_, entry) -> entry.artifact in selected }
            .groupBy({ (_, entry) -> SourcePartKey(entry.artifact, entry.sourcePart) }, { (placement, entry) ->
                placement to
                    entry.eligibility
            })
    return EngineCoverage(onEngines.mapValues { (_, engines) -> engines.coverage() })
}

/** One part's coverage from its eligibility on each engine of the Realm. */
private fun List<Pair<RuntimePlacement, Eligibility>>.coverage(): SourcePartDisposition {
    val placements = filter { (_, eligibility) -> eligibility is Eligibility.Eligible }.mapTo(linkedSetOf()) { it.first }
    if (placements.isNotEmpty()) return SourcePartDisposition.Eligible(placements)
    val perEngine = map { (_, eligibility) -> (eligibility as Eligibility.Ineligible).reasons }
    val ofItsKind = perEngine.any { reasons -> reasons.none { it is IneligibleReason.EngineMismatch } }
    val reasons = perEngine.flatten().filterNot { ofItsKind && it is IneligibleReason.EngineMismatch }
    return SourcePartDisposition.Ineligible(reasons.map(IneligibleReason::need).distinct())
}
