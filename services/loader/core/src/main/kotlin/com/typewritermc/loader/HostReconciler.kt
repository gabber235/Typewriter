package com.typewritermc.loader

import java.nio.file.Path
import java.time.Clock
import java.time.Duration

class HostReconciler(
    private val hostId: String,
    private val workDirectory: Path,
    private val runtimeFactory: DeploymentRuntimeFactory,
    private val stateStore: HostStateStore,
    private val reporter: suspend (HostExecutionReport) -> Unit = {},
    private val clock: Clock = Clock.systemUTC(),
    private val quiesceTimeout: Duration = Duration.ofSeconds(30),
) {
    private val active = mutableMapOf<ChildKind, ActiveDeployment>()
    private var applied: DesiredTopology? = null

    suspend fun restore(): DesiredTopology? {
        val stored = stateStore.load() ?: return null
        val staged = stageChanges(stored)
        activate(stored, staged)
        return stored
    }

    suspend fun reconcile(desired: DesiredTopology): ReconciliationResult {
        val current = applied
        if (current != null && desired.revision < current.revision) {
            return ReconciliationResult.IgnoredStale(current.revision)
        }
        if (desired == current) return ReconciliationResult.Unchanged

        val staged =
            try {
                stageChanges(desired)
            } catch (failure: Throwable) {
                reportFailure(desired.revision, current, failure)
                return ReconciliationResult.RolledBack(failure)
            }

        return try {
            activate(desired, staged)
            stateStore.save(desired)
            reporter(HostExecutionReport(desired.revision, ReconciliationStatus.ACTIVE))
            ReconciliationResult.Applied(desired.revision)
        } catch (failure: Throwable) {
            staged.values.forEach { deployment -> runCatching { deployment.runtime.stop() } }
            reportFailure(desired.revision, current, failure)
            ReconciliationResult.RolledBack(failure)
        }
    }

    suspend fun stop() {
        val deadline = clock.instant().plus(quiesceTimeout)
        active.values.reversed().forEach { it.runtime.quiesce(deadline) }
        active.values.reversed().forEach { it.runtime.stop() }
        active.clear()
    }

    private suspend fun reportFailure(
        revision: Long,
        current: DesiredTopology?,
        failure: Throwable,
    ) {
        reporter(
            HostExecutionReport(
                revision,
                if (current == null) ReconciliationStatus.FAILED else ReconciliationStatus.ROLLED_BACK,
                failure.message ?: failure::class.simpleName,
            ),
        )
    }

    private suspend fun stageChanges(desired: DesiredTopology): Map<ChildKind, ActiveDeployment> {
        val staged = linkedMapOf<ChildKind, ActiveDeployment>()
        try {
            ChildKind.entries.forEach { kind ->
                val child = desired.child(kind) ?: return@forEach
                if (active[kind]?.child == child) return@forEach
                val context = DeploymentContext(hostId, workDirectory.resolve(kind.name.lowercase()), child)
                staged[kind] = ActiveDeployment(child, runtimeFactory.stage(child, context))
            }
        } catch (failure: Throwable) {
            staged.values.reversed().forEach { deployment -> runCatching { deployment.runtime.stop() } }
            throw failure
        }
        return staged
    }

    private suspend fun activate(
        desired: DesiredTopology,
        staged: Map<ChildKind, ActiveDeployment>,
    ) {
        val replaced = ChildKind.entries.filter { kind -> active[kind]?.child != desired.child(kind) }
        val retained = replaced.mapNotNull(active::get).reversed()
        val deadline = clock.instant().plus(quiesceTimeout)
        retained.forEach { it.runtime.quiesce(deadline) }
        try {
            replaced.mapNotNull(staged::get).forEach { deployment ->
                (deployment.runtime as? ReplaceableDeploymentRuntime)?.activate()
            }
        } catch (failure: Throwable) {
            retained.reversed().forEach { deployment ->
                (deployment.runtime as? ReplaceableDeploymentRuntime)?.resume()
            }
            throw failure
        }
        retained.forEach { it.runtime.stop() }
        replaced.forEach { kind ->
            val replacement = staged[kind]
            if (replacement == null) active.remove(kind) else active[kind] = replacement
        }
        applied = desired
    }

    private data class ActiveDeployment(
        val child: DesiredChild,
        val runtime: DeploymentRuntime,
    )
}

sealed interface ReconciliationResult {
    data class Applied(
        val revision: Long,
    ) : ReconciliationResult

    data class IgnoredStale(
        val appliedRevision: Long,
    ) : ReconciliationResult

    data class RolledBack(
        val cause: Throwable,
    ) : ReconciliationResult

    data object Unchanged : ReconciliationResult
}
