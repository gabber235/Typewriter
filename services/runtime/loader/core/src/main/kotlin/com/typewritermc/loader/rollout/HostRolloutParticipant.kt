package com.typewritermc.loader.rollout

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
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.ProjectedExtension
import com.typewritermc.loader.deployment.ProjectedRuntime
import com.typewritermc.loader.runtime.HostedRuntimeLoader
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.nio.file.Path
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
    suspend fun fetch(digest: com.typewritermc.loader.artifact.ArtifactDigest): Path
}

/**
 * Publishes participant lifecycle observations.
 *
 * Delivery can fail separately from the runtime transition; direct status probes provide another observation path.
 */
fun interface ParticipantStatePublisher {
    suspend fun publish(event: ParticipantStateChanged)
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
    internal val hostId: HostId,
    private val workDirectory: Path,
    private val host: HostedRuntimeHost,
    private val projections: ProjectionSource,
    private val artifacts: VerifiedArtifactSource,
    private val states: ParticipantStatePublisher,
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
    private var currentActiveProjection: ActiveProjectionReference? = null

    val activeProjection: ActiveProjectionReference?
        get() = currentActiveProjection

    fun accepts(envelope: RolloutEnvelope): Boolean = envelope.realmId == realmId && hostId in envelope.participants

    suspend fun currentStatus(attempt: RolloutAttempt): ParticipantStatus =
        commands.withLock {
            when (val state = localState) {
                LocalParticipantState.Empty -> {
                    ParticipantStatus.Idle(attempt, hostId)
                }

                is LocalParticipantState.Staged -> {
                    ParticipantStatus.Staged(state.attempt, hostId, state.reference, state.baseline.toContract())
                }

                is LocalParticipantState.Active -> {
                    state.toContract(hostId)
                }
            }
        }

    suspend fun handle(envelope: RolloutEnvelope): CommandAcceptance =
        telemetry.artifactSpan(
            "artifact.rollout.command",
            "artifact-rollout-command-failed",
        ) { span ->
            span?.annotate {
                attribute("realm.id", realmId.value)
                attribute("host.id", hostId.value)
                attribute("rollout.attempt", envelope.attempt.ordinal)
                attribute("deployment.generation", envelope.attempt.generation.value)
                attribute("rollout.command", envelope.command.kind.name)
            }
            handleCommand(envelope, span).also { acceptance ->
                span?.annotate {
                    attribute("rollout.command_accepted", acceptance.accepted)
                    attribute("rollout.command_internal_failure", acceptance.internalFailure)
                }
            }
        }

    private suspend fun handleCommand(
        envelope: RolloutEnvelope,
        span: MainSpanScope?,
    ): CommandAcceptance {
        require(accepts(envelope)) { "Host is not a participant in this rollout." }
        return commands.withLock {
            val reference = envelope.projections.getValue(hostId)
            if (envelope.attempt.ordinal < latestAttemptOrdinal) {
                span?.annotate { attribute("rollout.command_stale", true) }
                return@withLock CommandAcceptance(hostId, false, "Rollout attempt is stale.")
            }
            if (envelope.attempt.ordinal == latestAttemptOrdinal && latestAttemptReference != null && latestAttemptReference != reference) {
                span?.annotate { attribute("rollout.command_conflict", true) }
                return@withLock CommandAcceptance(hostId, false, "Rollout attempt conflicts with another projection.")
            }
            latestAttemptOrdinal = envelope.attempt.ordinal
            latestAttemptReference = reference
            try {
                when (val command = envelope.command) {
                    RolloutCommand.Stage -> stage(envelope.attempt, reference)
                    RolloutCommand.Commit -> commit(envelope.attempt, reference)
                    RolloutCommand.Abort -> abort(envelope.attempt, reference)
                    is RolloutCommand.Rollback -> rollback(envelope.attempt, reference, command.targets.getValue(hostId))
                }
                CommandAcceptance(hostId, true)
            } catch (rejection: CommandRejectedException) {
                CommandAcceptance(hostId, false, rejection.message)
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                span?.recordDegraded(ErrorSlug.of("artifact-rollout-command-internal-failure"), failure)
                val recoverable = localState.toRecoverable()
                publish(
                    ParticipantStatus.Failed(
                        attempt = envelope.attempt,
                        hostId = hostId,
                        command = envelope.command.kind,
                        recoverable = recoverable,
                        reason = failure.message ?: "Rollout command failed.",
                    ),
                )
                CommandAcceptance(hostId, false, failure.message, internalFailure = true)
            }
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
                    publish(ParticipantStatus.Staged(attempt, hostId, reference, state.baseline.toContract()))
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
        publish(ParticipantStatus.Staging(attempt, hostId, reference, baseline.toContract()))
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
        publish(ParticipantStatus.Staged(attempt, hostId, reference, baseline.toContract()))
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
        publish(ParticipantStatus.Committing(attempt, hostId, reference, staged.baseline.toContract()))
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
        publish(ParticipantStatus.Aborting(attempt, hostId, reference, staged.baseline.toContract()))
        staged.projection.close()
        localState = staged.baseline?.copy(attempt = attempt) ?: LocalParticipantState.Empty
        publishCurrent(attempt)
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
            publishCurrent(attempt)
            return
        }
        val active = localState as? LocalParticipantState.Active
        if (target.matches(active?.reference)) return
        rejectUnless(active != null) { "There is no active projection to roll back." }
        requireNotNull(active)
        rejectUnless(active.reference == failedReference) { "The rollback command does not identify the active projection." }
        when (target) {
            RollbackTarget.Empty -> {
                rejectUnless(active.retained == null) { "Rollback target is empty while a retained projection exists." }
            }

            is RollbackTarget.Projection -> {
                rejectUnless(active.retained != null) { "The requested rollback projection is not retained." }
                rejectUnless(active.retained?.reference == target.reference) { "Retained projection differs from the rollback target." }
            }
        }
        publish(ParticipantStatus.RollingBack(attempt, hostId, failedReference, target))
        stopHealthMonitor()
        when (target) {
            RollbackTarget.Empty -> {
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
                publish(ParticipantStatus.Idle(attempt, hostId))
            }

            is RollbackTarget.Projection -> {
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
                attribute("host.id", hostId.value)
                attribute("projection.digest", reference.blob.value)
                attribute("deployment.generation", reference.generation.value)
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
        val loaded = mutableListOf<LoadedHostedRuntime>()
        try {
            projection.runtimes.forEach { runtime ->
                val runtimePath = runtimePaths.getValue(runtime)
                val artifactPackage = projection.artifactPackage(runtime, runtimePath, runtimePaths.values.toList(), extensionPaths)
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
                        identity = HostedRuntimeIdentity(hostId.value, realmId.value, runtime.placement),
                        directories = HostedRuntimeDirectories(stateDirectory, deploymentDirectory),
                        artifacts = artifactPackage,
                        facts = projection.facts,
                        host = host,
                    )
                loaded += runtimeLoader.stage(context, artifactPackage.executableArtifacts)
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
    ): HostedArtifactPackage =
        HostedArtifactPackage(
            runtimeArtifact = runtimePath,
            catalogArtifacts = catalogArtifacts,
            extensions =
                extensions.map { extension ->
                    HostedExtensionArtifact(
                        id = extension.artifact.coordinate.id,
                        path = extensionPaths.getValue(extension.artifact.coordinate.id),
                        sourceParts = extension.sourceParts.map { it.forRuntime(runtime.placement) },
                    )
                },
        )

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
        currentActiveProjection = ActiveProjectionReference(active.reference, active.projection.health.value)
        healthMonitor =
            scope.launch {
                active.projection.health.collect { health ->
                    val current =
                        commands.withLock {
                            (localState as? LocalParticipantState.Active)?.takeIf { it.reference == active.reference }
                        } ?: return@collect
                    currentActiveProjection = ActiveProjectionReference(current.reference, health)
                    publish(current.toContract(hostId, health))
                }
            }
    }

    private suspend fun publishCurrent(attempt: RolloutAttempt) {
        when (val current = localState) {
            LocalParticipantState.Empty -> {
                publish(ParticipantStatus.Idle(attempt, hostId))
            }

            is LocalParticipantState.Staged -> {
                publish(ParticipantStatus.Staged(current.attempt, hostId, current.reference, current.baseline.toContract()))
            }

            is LocalParticipantState.Active -> {
                publish(current.toContract(hostId))
            }
        }
    }

    private suspend fun publish(status: ParticipantStatus) {
        states.publish(ParticipantStateChanged(realmId, status))
    }

    private suspend fun stopHealthMonitor() {
        healthMonitor?.cancelAndJoin()
        healthMonitor = null
    }

    suspend fun close() =
        commands.withLock {
            stopHealthMonitor()
            val failure = runCatchingSuspend { localState.close() }.exceptionOrNull()
            localState = LocalParticipantState.Empty
            currentActiveProjection = null
            failure?.let { throw it }
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
            fun toContract(
                hostId: HostId,
                health: RuntimeHealthSnapshot = projection.health.value,
            ) = ParticipantStatus.Active(
                attempt,
                hostId,
                ActiveProjectionReference(reference, health),
                retained?.let { RetainedProjection.Present(it.reference) } ?: RetainedProjection.None,
            )
        }
    }

    internal class LocalProjection(
        private val runtimes: List<LoadedHostedRuntime>,
        scope: CoroutineScope,
        private val lifecycleTimeout: Duration,
    ) {
        private val mutableHealth = MutableStateFlow(valuesAtConstruction(runtimes).toSnapshot())
        val health: StateFlow<RuntimeHealthSnapshot> = mutableHealth
        private val healthMonitor =
            scope.launch {
                combine(runtimes.map { it.runtime.health }) { values -> values.toSnapshot() }
                    .collect { mutableHealth.value = it }
            }

        suspend fun activate() =
            transition(
                ordered = runtimes,
                operation = { it.runtime.activate() },
                compensate = { it.runtime.quiesce() },
            )

        suspend fun quiesce() =
            transition(
                ordered = runtimes.asReversed(),
                operation = { it.runtime.quiesce() },
                compensate = { it.runtime.resume() },
            )

        suspend fun resume() =
            transition(
                ordered = runtimes,
                operation = { it.runtime.resume() },
                compensate = { it.runtime.quiesce() },
            )

        suspend fun close() {
            healthMonitor.cancelAndJoin()
            val failures = mutableListOf<Throwable>()
            runtimes.asReversed().forEach { runtime ->
                try {
                    withTimeout(lifecycleTimeout) { runtime.close() }
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
            operation: suspend (LoadedHostedRuntime) -> Unit,
            compensate: suspend (LoadedHostedRuntime) -> Unit,
        ) {
            val completed = mutableListOf<LoadedHostedRuntime>()
            try {
                ordered.forEach { runtime ->
                    withTimeout(lifecycleTimeout) { operation(runtime) }
                    completed += runtime
                }
            } catch (failure: Throwable) {
                withContext(NonCancellable) {
                    completed.asReversed().forEach { runtime ->
                        runCatchingSuspend {
                            withTimeout(lifecycleTimeout) { compensate(runtime) }
                        }.exceptionOrNull()?.let(failure::addSuppressed)
                    }
                }
                throw failure
            }
        }

        companion object {
            private fun valuesAtConstruction(runtimes: List<LoadedHostedRuntime>) = runtimes.map { it.runtime.health.value }.toTypedArray()
        }
    }
}

private fun Array<RuntimeHealth>.toSnapshot(): RuntimeHealthSnapshot {
    val unhealthy = filterIsInstance<RuntimeHealth.Unhealthy>()
    return when {
        unhealthy.isNotEmpty() -> RuntimeHealthSnapshot.Unhealthy(unhealthy.map(RuntimeHealth.Unhealthy::reason))
        all { it == RuntimeHealth.Healthy } -> RuntimeHealthSnapshot.Healthy
        else -> RuntimeHealthSnapshot.Staged
    }
}

private fun HostRolloutParticipant.LocalParticipantState?.toContract(): ActiveBaseline =
    (this as? HostRolloutParticipant.LocalParticipantState.Active)
        ?.let { ActiveBaseline.Present(ActiveProjectionReference(it.reference, it.projection.health.value)) }
        ?: ActiveBaseline.Empty

private fun HostRolloutParticipant.LocalParticipantState.activeOrNull() = this as? HostRolloutParticipant.LocalParticipantState.Active

private fun HostRolloutParticipant.LocalParticipantState.toRecoverable(): RecoverableParticipantState =
    when (this) {
        HostRolloutParticipant.LocalParticipantState.Empty -> {
            RecoverableParticipantState.Empty
        }

        is HostRolloutParticipant.LocalParticipantState.Active -> {
            RecoverableParticipantState.Active(
                ActiveProjectionReference(reference, projection.health.value),
                retained?.let { RetainedProjection.Present(it.reference) } ?: RetainedProjection.None,
            )
        }

        is HostRolloutParticipant.LocalParticipantState.Staged -> {
            RecoverableParticipantState.Staged(reference, baseline.toContract())
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
        RollbackTarget.Empty -> reference == null
        is RollbackTarget.Projection -> reference == this.reference
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
        rethrowExceptionalThrowable(failure)
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
