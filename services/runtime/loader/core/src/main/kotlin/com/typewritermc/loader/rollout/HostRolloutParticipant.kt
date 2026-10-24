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
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.HostedRuntimeIdentity
import com.typewritermc.loader.api.HostedSourcePart
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.ProjectedExtension
import com.typewritermc.loader.deployment.ProjectedRuntime
import com.typewritermc.loader.runtime.HostedRuntimeLoader
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import skirout.service.v1.rollout.ActiveParticipant
import skirout.service.v1.rollout.ActiveProjection
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.RecoverableParticipantState
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.StagedCandidate
import java.nio.file.Path
import java.util.concurrent.TimeoutException
import kotlin.io.path.createDirectories
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

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
 * Observes every participant lifecycle transition on this host, such as the host execution report.
 *
 * The coordinator does not depend on these observations; it queries participant status directly.
 */
fun interface ParticipantStatusListener {
    fun changed(status: ParticipantStatus)
}

/**
 * Owns staged, active, and retained projections for one Realm and host.
 *
 * A mutex serializes commands and rejects stale or conflicting attempts. Commit quiesces the baseline before
 * activating a candidate and attempts recovery on failure. Successful replacement retains one prior projection for
 * rollback. The assignment lifecycle must close the participant and its health monitor.
 */
class HostRolloutParticipant(
    internal val realmId: RealmId,
    internal val serviceId: ServiceId,
    private val workDirectory: Path,
    private val host: HostedRuntimeHost,
    private val projections: ProjectionSource,
    private val artifacts: VerifiedArtifactSource,
    private val statuses: ParticipantStatusListener,
    private val scope: CoroutineScope,
    private val runtimeLoader: HostedRuntimeStager = HostedRuntimeLoader(),
    private val lifecycleTimeout: Duration = 30.seconds,
    private val telemetry: ServiceTelemetry? = null,
) {
    private val commands = Mutex()
    private var localState: LocalParticipantState = LocalParticipantState.Empty
    private var latestAttemptOrdinal = 0L
    private var latestAttemptReference: ProjectionReference? = null
    private var healthMonitor: Job? = null

    @Volatile
    private var currentActiveProjection: ActiveProjection? = null

    val activeProjection: ActiveProjection?
        get() = currentActiveProjection

    /** Returns the local status for the queried [attempt], including the active projection health when present. */
    suspend fun status(attempt: RolloutAttempt): ParticipantStatus {
        attempt.requireValid()
        return commands.withLock {
            when (val state = localState) {
                LocalParticipantState.Empty -> status(attempt, ParticipantPhase.IDLE)
                is LocalParticipantState.Staged -> status(state.attempt, state.stagedPhase())
                is LocalParticipantState.Active -> state.toContract()
            }
        }
    }

    /**
     * Applies one command atomically with respect to other commands, or returns null when the command does not list
     * this host. Stale and conflicting attempts, rejections and failures reply with their error variant, each naming
     * this host so the coordinator can stop collecting early.
     */
    suspend fun apply(request: ApplyRolloutCommandRequest): ApplyRolloutCommandResponse? {
        request.requireValid()
        val attempt = request.attempt
        val command = request.command
        val reference = command.projectionOf(serviceId.value) ?: return null
        return telemetry.artifactSpan(
            "artifact.rollout.command",
            "artifact-rollout-command-failed",
        ) { span ->
            span?.annotate {
                attribute("realm.id", realmId.value)
                attribute("service.id", serviceId.value)
                attribute("rollout.attempt", attempt.ordinal)
                attribute("deployment.generation", attempt.generation)
                attribute("rollout.command", command.commandKind.label)
            }
            applyCommand(attempt, command, reference, span)
        }
    }

    private suspend fun applyCommand(
        attempt: RolloutAttempt,
        command: RolloutCommand,
        reference: ProjectionReference,
        span: MainSpanScope?,
    ): ApplyRolloutCommandResponse =
        commands.withLock {
            val id = serviceId.value
            if (attempt.ordinal < latestAttemptOrdinal) {
                span?.annotate { attribute("rollout.command_stale", true) }
                return@withLock ApplyRolloutCommandResponse.createStaleAttemptError(serviceId = id)
            }
            if (attempt.ordinal == latestAttemptOrdinal && latestAttemptReference != null && latestAttemptReference != reference) {
                span?.annotate { attribute("rollout.command_conflict", true) }
                return@withLock ApplyRolloutCommandResponse.createAttemptConflictError(serviceId = id)
            }
            latestAttemptOrdinal = attempt.ordinal
            latestAttemptReference = reference
            try {
                when (command) {
                    is RolloutCommand.StageWrapper -> {
                        stage(attempt, reference)
                    }

                    is RolloutCommand.CommitWrapper -> {
                        commit(attempt, reference)
                    }

                    is RolloutCommand.AbortWrapper -> {
                        abort(attempt, reference)
                    }

                    is RolloutCommand.RollBackWrapper -> {
                        rollback(attempt, reference, requireNotNull(command.value.participants.findByKey(id)).target)
                    }

                    else -> {
                        error("Rollout command is unknown.")
                    }
                }
                ApplyRolloutCommandResponse.createAccepted(serviceId = id)
            } catch (rejection: CommandRejectedException) {
                ApplyRolloutCommandResponse.createCommandRejectedError(serviceId = id, reason = rejection.message.orEmpty())
            } catch (failure: Throwable) {
                failure.rethrowExceptional()
                span?.recordDegraded(ErrorSlug.of("artifact-rollout-command-internal-failure"), failure)
                val reason = failure.message ?: "Rollout command failed."
                observe(
                    attempt,
                    ParticipantPhase.createFailed(command = command.commandKind, recoverable = localState.toRecoverable(), reason = reason),
                )
                ApplyRolloutCommandResponse.createCommandFailedError(serviceId = id, reason = reason)
            }
        }

    private suspend fun stage(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
    ) {
        when (val state = localState) {
            is LocalParticipantState.Staged -> {
                if (state.reference == reference && state.attempt == attempt) return
                if (state.reference == reference && attempt.ordinal > state.attempt.ordinal) {
                    localState = state.copy(attempt = attempt)
                    observe(attempt, state.stagedPhase())
                    return
                }
                rejectUnless(attempt.ordinal > state.attempt.ordinal) { "The rollout attempt conflicts with another staged projection." }
            }

            is LocalParticipantState.Active -> {
                if (state.reference == reference && state.attempt == attempt) return
            }

            LocalParticipantState.Empty -> {}
        }
        val baseline = localState.activeOrNull()
        observe(attempt, ParticipantPhase.createStaging(candidate = reference, baseline = baseline?.activeProjection()))
        val projection = projections.fetch(reference)
        val replacement = stageProjection(reference, projection)
        val previousStaged = localState as? LocalParticipantState.Staged
        try {
            previousStaged?.projection?.close()
        } catch (failure: Throwable) {
            replacement.closePreserving(failure)
            throw failure
        }
        localState = LocalParticipantState.Staged(attempt, reference, replacement, baseline)
        observe(attempt, ParticipantPhase.createStaged(candidate = reference, baseline = baseline?.activeProjection()))
    }

    private suspend fun commit(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
    ) {
        val active = localState as? LocalParticipantState.Active
        if (active?.reference == reference) return
        val staged = localState as? LocalParticipantState.Staged
        rejectUnless(staged != null) { "Projection was not staged." }
        requireNotNull(staged)
        rejectUnless(staged.reference == reference) { "Another projection is staged." }
        rejectUnless(staged.attempt == attempt) { "The staged projection belongs to another rollout attempt." }
        observe(attempt, ParticipantPhase.createCommitting(candidate = reference, baseline = staged.baseline?.activeProjection()))
        val baseline = staged.baseline
        try {
            baseline?.projection?.quiesce()
            staged.projection.activate()
        } catch (failure: Throwable) {
            withContext(NonCancellable) {
                staged.projection.closePreserving(failure)
                baseline?.projection?.resumePreserving(failure)
            }
            localState = baseline ?: LocalParticipantState.Empty
            throw failure
        }
        val replacement = LocalParticipantState.Active(attempt, reference, staged.projection, baseline?.copy(retained = null))
        localState = replacement
        monitorHealth(replacement)
        baseline?.retained?.projection?.close()
    }

    private suspend fun abort(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
    ) {
        val staged = localState as? LocalParticipantState.Staged
        if (staged == null || staged.reference != reference) return
        observe(attempt, ParticipantPhase.createAborting(candidate = reference, baseline = staged.baseline?.activeProjection()))
        staged.projection.close()
        localState = staged.baseline?.copy(attempt = attempt) ?: LocalParticipantState.Empty
        observeCurrent(attempt)
    }

    private suspend fun rollback(
        attempt: RolloutAttempt,
        failedReference: ProjectionReference,
        target: RollbackTarget,
    ) {
        val staged = localState as? LocalParticipantState.Staged
        if (staged != null) {
            rejectUnless(staged.reference == failedReference) { "The rollback command does not identify the staged projection." }
            staged.projection.close()
            localState = staged.baseline?.copy(attempt = attempt) ?: LocalParticipantState.Empty
            observeCurrent(attempt)
            return
        }
        val active = localState as? LocalParticipantState.Active
        if (target.matches(active?.reference)) return
        rejectUnless(active != null) { "There is no active projection to roll back." }
        requireNotNull(active)
        rejectUnless(active.reference == failedReference) { "The rollback command does not identify the active projection." }
        when (target) {
            is RollbackTarget.ProjectionWrapper -> {
                rejectUnless(active.retained != null) { "The requested rollback projection is not retained." }
                rejectUnless(active.retained?.reference == target.value) { "Retained projection differs from the rollback target." }
            }

            else -> {
                rejectUnless(active.retained == null) { "Rollback target is empty while a retained projection exists." }
            }
        }
        observe(attempt, ParticipantPhase.createRollingBack(failed = failedReference, target = target))
        stopHealthMonitor()
        when (target) {
            is RollbackTarget.ProjectionWrapper -> {
                val retained = requireNotNull(active.retained)
                try {
                    active.projection.quiesce()
                    retained.projection.resume()
                } catch (failure: Throwable) {
                    withContext(NonCancellable) {
                        active.projection.resumePreserving(failure)
                        monitorHealth(active)
                    }
                    throw failure
                }
                active.projection.close()
                val restored = retained.copy(attempt = attempt, retained = null)
                localState = restored
                monitorHealth(restored)
            }

            else -> {
                try {
                    active.projection.quiesce()
                } catch (failure: Throwable) {
                    monitorHealth(active)
                    throw failure
                }
                try {
                    active.projection.close()
                } finally {
                    localState = LocalParticipantState.Empty
                    currentActiveProjection = null
                }
                observe(attempt, ParticipantPhase.IDLE)
            }
        }
    }

    private suspend fun stageProjection(
        reference: ProjectionReference,
        projection: HostDeploymentProjection,
    ): LocalProjection =
        telemetry.artifactSpan(
            "artifact.projection.stage",
            "artifact-projection-stage-failed",
        ) { span ->
            span?.annotate {
                attribute("realm.id", realmId.value)
                attribute("service.id", serviceId.value)
                attribute("projection.digest", reference.blob.value)
                attribute("deployment.generation", reference.generation)
            }
            stageProjectionContents(reference, projection)
        }

    private suspend fun stageProjectionContents(
        reference: ProjectionReference,
        projection: HostDeploymentProjection,
    ): LocalProjection {
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
                val deploymentDirectory =
                    workDirectory
                        .resolve("runtime")
                        .resolve(runtime.placement.name.lowercase())
                        .resolve("deployments")
                        .resolve(reference.blob.value)
                        .also(Path::createDirectories)
                val stateDirectory =
                    workDirectory
                        .resolve("runtime")
                        .resolve(runtime.placement.name.lowercase())
                        .resolve("state")
                        .also(Path::createDirectories)
                val context =
                    HostedDeploymentContext(
                        identity = HostedRuntimeIdentity(serviceId.value, realmId.value, runtime.placement),
                        directories = HostedRuntimeDirectories(stateDirectory, deploymentDirectory),
                        artifacts = artifactPackage,
                        publicationTarget = projection.publicationTarget,
                        engineImplementation = runtime.implementation,
                        facts = projection.facts,
                        host = host,
                    )
                loaded += runtimeLoader.stage(context)
            }
            require(loaded.all { it.runtime.health.value == RuntimeHealth.Staged }) {
                "Every local runtime must report staged before the projection is accepted."
            }
            return LocalProjection(loaded, scope, lifecycleTimeout)
        } catch (failure: Throwable) {
            withContext(NonCancellable) {
                loaded.asReversed().forEach { runtime -> runtime.closePreserving(failure) }
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

    private suspend fun monitorHealth(active: LocalParticipantState.Active) {
        stopHealthMonitor()
        currentActiveProjection = active.activeProjection()
        healthMonitor =
            scope.launch {
                active.projection.health.collect { health ->
                    val current =
                        commands.withLock {
                            (localState as? LocalParticipantState.Active)?.takeIf { it.reference == active.reference }
                        } ?: return@collect
                    currentActiveProjection = current.activeProjection(health)
                    statuses.changed(current.toContract(health))
                }
            }
    }

    private fun observeCurrent(attempt: RolloutAttempt) {
        when (val current = localState) {
            LocalParticipantState.Empty -> observe(attempt, ParticipantPhase.IDLE)
            is LocalParticipantState.Staged -> observe(current.attempt, current.stagedPhase())
            is LocalParticipantState.Active -> statuses.changed(current.toContract())
        }
    }

    private fun observe(
        attempt: RolloutAttempt,
        phase: ParticipantPhase,
    ) = statuses.changed(status(attempt, phase))

    private fun status(
        attempt: RolloutAttempt,
        phase: ParticipantPhase,
    ) = ParticipantStatus(serviceId = serviceId.value, attempt = attempt, phase = phase)

    private fun LocalParticipantState.Staged.stagedPhase() =
        ParticipantPhase.createStaged(candidate = reference, baseline = baseline?.activeProjection())

    private fun LocalParticipantState.Active.toContract(health: ProjectionHealth = projection.health.value) =
        status(attempt, ParticipantPhase.ActiveWrapper(activeParticipant(health)))

    private suspend fun stopHealthMonitor() {
        healthMonitor?.cancelAndJoin()
        healthMonitor = null
    }

    /** Stops health observation and closes every staged, active, or retained runtime, preserving retryable ownership on failure. */
    suspend fun close() =
        commands.withLock {
            stopHealthMonitor()
            localState.close()
            localState = LocalParticipantState.Empty
            currentActiveProjection = null
        }

    internal sealed interface LocalParticipantState {
        data object Empty : LocalParticipantState

        data class Staged(
            val attempt: RolloutAttempt,
            val reference: ProjectionReference,
            val projection: LocalProjection,
            val baseline: Active?,
        ) : LocalParticipantState

        data class Active(
            val attempt: RolloutAttempt,
            val reference: ProjectionReference,
            val projection: LocalProjection,
            val retained: Active?,
        ) : LocalParticipantState {
            fun activeProjection(health: ProjectionHealth = projection.health.value) =
                ActiveProjection(projection = reference, health = health)

            fun activeParticipant(health: ProjectionHealth = projection.health.value) =
                ActiveParticipant(current = activeProjection(health), retained = retained?.reference)
        }
    }

    /**
     * Owns the ordered runtimes and combined health of one local projection.
     *
     * Activation and resume follow runtime order; quiesce and close reverse it. A failed transition compensates
     * only completed steps, in reverse order, with a deadline per step. Failed closures retain their runtime
     * handles for retry so the containing participant can keep ownership until cleanup succeeds.
     */
    internal class LocalProjection(
        private val runtimes: List<LoadedHostedRuntime>,
        scope: CoroutineScope,
        private val lifecycleTimeout: Duration,
    ) {
        private val mutableHealth = MutableStateFlow(runtimes.map { it.runtime.health.value }.toProjectionHealth())
        val health: StateFlow<ProjectionHealth> = mutableHealth
        private val healthMonitor =
            scope.launch {
                combine(runtimes.map { it.runtime.health }) { values -> values.toList().toProjectionHealth() }
                    .collect { mutableHealth.value = it }
            }

        suspend fun activate() =
            transition(
                ordered = runtimes,
                operationName = "activate",
                operation = { it.runtime.activate() },
                compensationName = "quiesce",
                compensate = { it.runtime.quiesce() },
            )

        suspend fun quiesce() =
            transition(
                ordered = runtimes.asReversed(),
                operationName = "quiesce",
                operation = { it.runtime.quiesce() },
                compensationName = "resume",
                compensate = { it.runtime.resume() },
            )

        suspend fun resume() =
            transition(
                ordered = runtimes,
                operationName = "resume",
                operation = { it.runtime.resume() },
                compensationName = "quiesce",
                compensate = { it.runtime.quiesce() },
            )

        private val pendingClose = runtimes.toMutableList()

        suspend fun close() {
            healthMonitor.cancelAndJoin()
            val failures = mutableListOf<Throwable>()
            pendingClose.toList().asReversed().forEach { runtime ->
                try {
                    withinLifecycleDeadline("close") { runtime.close() }
                    pendingClose.remove(runtime)
                } catch (failure: Throwable) {
                    failures += failure
                }
            }
            failures.firstOrNull()?.let { failure ->
                failures.drop(1).forEach(failure::addSuppressed)
                throw failure
            }
        }

        private suspend fun transition(
            ordered: List<LoadedHostedRuntime>,
            operationName: String,
            operation: suspend (LoadedHostedRuntime) -> Unit,
            compensationName: String,
            compensate: suspend (LoadedHostedRuntime) -> Unit,
        ) {
            val completed = mutableListOf<LoadedHostedRuntime>()
            try {
                ordered.forEach { runtime ->
                    withinLifecycleDeadline(operationName) { operation(runtime) }
                    completed += runtime
                }
            } catch (failure: Throwable) {
                withContext(NonCancellable) {
                    completed.asReversed().forEach { runtime ->
                        runCatchingSuspend {
                            withinLifecycleDeadline("$compensationName compensation") { compensate(runtime) }
                        }.exceptionOrNull()?.let(failure::addSuppressed)
                    }
                }
                throw failure
            }
        }

        private suspend fun withinLifecycleDeadline(
            operationName: String,
            operation: suspend () -> Unit,
        ) {
            val completed = withTimeoutOrNull(lifecycleTimeout) { operation() }
            currentCoroutineContext().ensureActive()
            if (completed == null) {
                throw TimeoutException("Hosted runtime $operationName exceeded lifecycle deadline of $lifecycleTimeout")
            }
        }
    }
}

private fun HostRolloutParticipant.LocalParticipantState.activeOrNull() = this as? HostRolloutParticipant.LocalParticipantState.Active

private fun HostRolloutParticipant.LocalParticipantState.toRecoverable(): RecoverableParticipantState =
    when (this) {
        HostRolloutParticipant.LocalParticipantState.Empty -> {
            RecoverableParticipantState.EMPTY
        }

        is HostRolloutParticipant.LocalParticipantState.Active -> {
            RecoverableParticipantState.ActiveWrapper(activeParticipant())
        }

        is HostRolloutParticipant.LocalParticipantState.Staged -> {
            RecoverableParticipantState.StagedWrapper(StagedCandidate(candidate = reference, baseline = baseline?.activeProjection()))
        }
    }

private suspend fun HostRolloutParticipant.LocalParticipantState.close() {
    when (this) {
        HostRolloutParticipant.LocalParticipantState.Empty -> {}

        is HostRolloutParticipant.LocalParticipantState.Staged -> {
            projection.close()
            baseline?.projection?.close()
            baseline?.retained?.projection?.close()
        }

        is HostRolloutParticipant.LocalParticipantState.Active -> {
            projection.close()
            retained?.projection?.close()
            retained?.retained?.projection?.close()
        }
    }
}

private fun RollbackTarget.matches(reference: ProjectionReference?): Boolean =
    when (this) {
        is RollbackTarget.ProjectionWrapper -> reference == value
        else -> reference == null
    }

private suspend fun HostRolloutParticipant.LocalProjection.closePreserving(failure: Throwable) {
    runCatchingSuspend { close() }.exceptionOrNull()?.let(failure::addSuppressed)
}

private suspend fun HostRolloutParticipant.LocalProjection.resumePreserving(failure: Throwable) {
    runCatchingSuspend { resume() }.exceptionOrNull()?.let(failure::addSuppressed)
}

private suspend fun LoadedHostedRuntime.closePreserving(failure: Throwable) {
    runCatchingSuspend { close() }.exceptionOrNull()?.let(failure::addSuppressed)
}

private suspend fun <Value> runCatchingSuspend(block: suspend () -> Value): Result<Value> =
    try {
        Result.success(block())
    } catch (failure: Throwable) {
        failure.rethrowExceptional()
        Result.failure(failure)
    }

private class CommandRejectedException(
    message: String,
) : IllegalStateException(message)

private inline fun rejectUnless(
    condition: Boolean,
    message: () -> String,
) {
    if (!condition) throw CommandRejectedException(message())
}
