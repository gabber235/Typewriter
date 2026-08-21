package com.typewritermc.loader

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import java.nio.file.Path

/**
 * Starts one official service host and keeps it reconciled with control plane topology snapshots.
 *
 * Registration establishes the stable host identity. When registration is unavailable, [start] restores the last
 * applied topology from local storage and returns an offline host without a topology watch.
 */
class HostLoader(
    private val entrypoint: HostEntrypoint,
    private val workDirectory: Path,
    private val controlPlane: HostControlPlane,
    private val runtimeFactory: DeploymentRuntimeFactory,
    private val scope: CoroutineScope,
) {
    suspend fun start(): RunningHost {
        val stateDirectory = workDirectory.resolve("state")
        val identityStore = HostIdentityStore(stateDirectory.resolve("host-id"))
        val stateStore = FileHostStateStore(stateDirectory.resolve("topology.bin"))
        val registration =
            try {
                controlPlane.register(entrypoint).also { identityStore.save(it.hostId) }
            } catch (failure: Throwable) {
                if (failure is CancellationException) throw failure
                val hostId = identityStore.load() ?: throw failure
                val reconciler = HostReconciler(hostId, workDirectory, runtimeFactory, stateStore)
                reconciler.restore()
                return RunningHost(reconciler, null)
            }
        val reconciler =
            HostReconciler(
                registration.hostId,
                workDirectory,
                runtimeFactory,
                stateStore,
                reporter = { report -> controlPlane.report(registration.hostId, report) },
            )
        reconciler.restore()
        val watch =
            scope.launch {
                controlPlane.watchExecution(registration.hostId).collect(reconciler::reconcile)
            }
        return RunningHost(reconciler, watch)
    }
}

/**
 * Owns the topology watch and active child runtimes created by [HostLoader].
 *
 * [stop] first ends the watch, then quiesces and stops children through the reconciler. It suspends until cleanup has
 * completed.
 */
class RunningHost internal constructor(
    private val reconciler: HostReconciler,
    private val watch: Job?,
) {
    suspend fun stop() {
        watch?.cancel()
        watch?.join()
        reconciler.stop()
    }
}
