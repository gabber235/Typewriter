package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.HostedArtifactManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.archive.ImprintArchive
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedArtifactPackage
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedExtensionArtifact
import com.typewritermc.loader.api.HostedRuntimeDirectories
import com.typewritermc.loader.api.HostedRuntimeIdentity
import com.typewritermc.loader.api.HostedSourcePart
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.ProjectedRuntime
import com.typewritermc.loader.runtime.HostedRuntimeLoader
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.loader.work.HostWork
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import skirout.service.v1.rollout.ProjectionReference
import java.nio.file.Path
import kotlin.io.path.createDirectories

/**
 * Retrieves and validates an exact host projection before runtime staging.
 */
interface ProjectionSource {
    suspend fun fetch(reference: ProjectionReference): HostDeploymentProjection
}

/**
 * Provides a local path for verified digest addressed artifact bytes.
 *
 * The file must remain available during loading; the caller does not own deletion of shared cache content.
 */
interface VerifiedArtifactSource {
    suspend fun fetch(digest: com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest): Path
}

/**
 * Where one assignment's runtimes live on this host: the service [serviceId] hosting [assignment], with every
 * runtime's state and deployments under [workDirectory].
 */
class AssignmentPlace(
    val serviceId: ServiceId,
    val assignment: ArtifactHostAssignment,
    private val workDirectory: Path,
) {
    val realmId: RealmId get() = assignment.realmId

    /** Who the runtime at [placement] is. */
    fun identity(placement: RuntimePlacement): HostedRuntimeIdentity =
        HostedRuntimeIdentity(serviceId.value, realmId.value, placement, assignment.engineIdOf(placement))

    /** The state kept across deployments of the runtime at [placement], and the directory of its deployment of [projection]. */
    fun directories(
        placement: RuntimePlacement,
        projection: ProjectionReference,
    ): HostedRuntimeDirectories {
        val runtime = workDirectory.resolve("runtime").resolve(placement.name.lowercase())
        return HostedRuntimeDirectories(
            runtime.resolve("state").also(Path::createDirectories),
            runtime.resolve("deployments").resolve(projection.blob.value).also(Path::createDirectories),
        )
    }
}

/** The runtimes of one staged projection in order, the view of the host each holds, and the host's [work]. */
class StagedRuntimes(
    val runtimes: List<LoadedHostedRuntime>,
    val hosts: List<RuntimeHost>,
    val work: HostWork,
)

/**
 * Stages the projections of one [place]: fetches each from [projections] and its artifacts from [artifacts], checks
 * every manifest against the projection, and stages each runtime through [loader] with its own view from [hosts].
 */
class ProjectionStager(
    private val place: AssignmentPlace,
    private val hosts: RuntimeHosts,
    private val projections: ProjectionSource,
    private val artifacts: VerifiedArtifactSource,
    private val loader: HostedRuntimeStager = HostedRuntimeLoader(),
    private val telemetry: ServiceTelemetry? = null,
) {
    /**
     * Fetches the projection [reference] names and stages its runtimes, each with its own view of the host; on a
     * failure it closes what it staged and the views it opened.
     */
    suspend fun stage(reference: ProjectionReference): StagedRuntimes =
        telemetry.artifactSpan(
            "artifact.projection.stage",
            "artifact-projection-stage-failed",
        ) { span ->
            span?.annotate {
                attribute("realm.id", place.realmId.value)
                attribute("service.id", place.serviceId.value)
                attribute("projection.digest", reference.blob.value)
                attribute("deployment.generation", reference.generation)
            }
            stageContents(reference, projections.fetch(reference))
        }

    private suspend fun stageContents(
        reference: ProjectionReference,
        projection: HostDeploymentProjection,
    ): StagedRuntimes {
        val runtimePaths =
            projection.runtimes.associateWith { runtime -> artifacts.fetch(runtime.artifact.digest) }
        val extensionPaths =
            projection.extensions.associate { extension ->
                extension.artifact.coordinate.id to artifacts.fetch(extension.artifact.digest)
            }
        val manifestByPath =
            (runtimePaths.values + extensionPaths.values)
                .distinct()
                .associateWith(ImprintArchive::require)
        runtimePaths.forEach { (runtime, path) ->
            validateManifest(runtime.artifact, path, manifestByPath.getValue(path))
        }
        projection.extensions.forEach { extension ->
            val path = extensionPaths.getValue(extension.artifact.coordinate.id)
            validateManifest(extension.artifact, path, manifestByPath.getValue(path))
        }
        val loaded = mutableListOf<LoadedHostedRuntime>()
        val runtimeHosts = mutableListOf<RuntimeHost>()
        try {
            projection.runtimes.forEach { runtime ->
                val runtimePath = runtimePaths.getValue(runtime)
                val artifactPackage =
                    projection.artifactPackage(
                        runtime,
                        runtimePath,
                        runtimePaths.values.toList(),
                        extensionPaths,
                        manifestByPath,
                    )
                val runtimeHost =
                    hosts.open(WorkRuntime("${runtime.placement.name.lowercase()} of projection ${reference.blob.value}"))
                runtimeHosts += runtimeHost
                val context =
                    HostedDeploymentContext(
                        identity = place.identity(runtime.placement),
                        directories = place.directories(runtime.placement, reference),
                        artifacts = artifactPackage,
                        publicationTarget = projection.publicationTarget,
                        engineImplementation = runtime.implementation,
                        facts = projection.facts,
                        host = runtimeHost,
                    )
                loaded += loader.stage(context)
            }
            require(loaded.all { it.runtime.health.value == RuntimeHealth.Staged }) {
                "Every local runtime must report staged before the projection is accepted."
            }
            return StagedRuntimes(loaded, runtimeHosts, hosts.work)
        } catch (failure: Throwable) {
            withContext(NonCancellable) {
                loaded.asReversed().forEach { runtime -> runtime.closePreserving(failure) }
                runtimeHosts.forEach(RuntimeHost::close)
            }
            throw failure
        }
    }

    private fun HostDeploymentProjection.artifactPackage(
        runtime: ProjectedRuntime,
        runtimePath: Path,
        catalogArtifacts: List<Path>,
        extensionPaths: Map<com.typewritermc.imprint.ArtifactId, Path>,
        manifestByPath: Map<Path, ImprintManifest>,
    ): HostedArtifactPackage =
        HostedArtifactPackage(
            runtimeArtifact =
                HostedArtifact(
                    runtimePath,
                    manifestByPath.getValue(runtimePath) as? HostedArtifactManifest
                        ?: error("Hosted runtime ${runtime.artifact.coordinate.id} has a non hosted manifest."),
                ),
            catalogArtifacts =
                catalogArtifacts
                    .distinct()
                    .map { path -> HostedArtifact(path, manifestByPath.getValue(path)) },
            extensions =
                extensions.map { extension ->
                    val path = extensionPaths.getValue(extension.artifact.coordinate.id)
                    HostedExtensionArtifact(
                        id = extension.artifact.coordinate.id,
                        path = path,
                        manifest =
                            manifestByPath.getValue(path) as? ExtensionManifest
                                ?: error("Hosted extension ${extension.artifact.coordinate.id} has a non extension manifest."),
                        sourceParts = extension.sourceParts.map { it.forRuntime(runtime.placement) },
                    )
                },
        )

    private fun validateManifest(
        artifact: DeploymentArtifact,
        path: Path,
        manifest: ImprintManifest,
    ) {
        require(manifest.id == artifact.coordinate.id) {
            "Artifact ${path.fileName} manifest id ${manifest.id} differs from ${artifact.coordinate.id}."
        }
        require(manifest.version == artifact.coordinate.version) {
            "Artifact ${path.fileName} manifest version ${manifest.version} differs from ${artifact.coordinate.version}."
        }
        val kind =
            when (manifest) {
                is com.typewritermc.imprint.RealmManifest -> ArtifactKind.REALM
                is com.typewritermc.imprint.EngineManifest -> ArtifactKind.ENGINE
                is com.typewritermc.imprint.CapabilityManifest -> ArtifactKind.CAPABILITY
                is com.typewritermc.imprint.ExtensionManifest -> ArtifactKind.EXTENSION
            }
        require(kind == artifact.kind) {
            "Artifact ${path.fileName} manifest kind $kind differs from ${artifact.kind}."
        }
    }

    private fun com.typewritermc.loader.deployment.ProjectedSourcePart.forRuntime(placement: RuntimePlacement): HostedSourcePart {
        val current = disposition
        val narrowed =
            when {
                placement == RuntimePlacement.REALM -> {
                    current
                }

                current is SourcePartDisposition.Eligible && placement in current.placements -> {
                    SourcePartDisposition.Eligible(setOf(placement))
                }

                current is SourcePartDisposition.Ineligible -> {
                    current
                }

                else -> {
                    SourcePartDisposition.Ineligible(listOf("Source part is not eligible for $placement."))
                }
            }
        return HostedSourcePart(name, narrowed)
    }
}
