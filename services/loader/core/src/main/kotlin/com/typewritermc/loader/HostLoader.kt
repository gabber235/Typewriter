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
    private val service: LoaderService? = null,
) {
    suspend fun start(): RunningHost =
        try {
            service?.start()?.requireSuccess("start")
            startHost()
        } catch (failure: Throwable) {
            runCatching { service?.stop() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }

    private suspend fun startHost(): RunningHost {
        val stateDirectory = workDirectory.resolve("state")
        val identityStore = HostIdentityStore(stateDirectory.resolve("host-id"))
        val stateStore = FileHostStateStore(stateDirectory.resolve("topology.bin"))
        val registration =
            try {
                controlPlane.register(entrypoint).also { identityStore.save(it.hostId) }
            } catch (failure: Throwable) {
                if (failure is CancellationException) throw failure
                val hostId = identityStore.load() ?: throw failure
                val reconciler =
                    HostReconciler(
                        hostId,
                        workDirectory,
                        runtimeFactory,
                        stateStore,
                        service ?: UnavailableLoaderServiceConnection,
                    )
                reconciler.restore()
                return RunningHost(reconciler, null, service)
            }
        val reconciler =
            HostReconciler(
                registration.hostId,
                workDirectory,
                runtimeFactory,
                stateStore,
                service ?: UnavailableLoaderServiceConnection,
                reporter = { report -> controlPlane.report(registration.hostId, report) },
            )
        reconciler.restore()
        val watch =
            scope.launch {
                controlPlane.watchExecution(registration.hostId).collect(reconciler::reconcile)
            }
        return RunningHost(reconciler, watch, service)
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
    private val ownedService: LoaderService? = null,
) {
    val service: LoaderServiceConnection = ownedService ?: UnavailableLoaderServiceConnection

    suspend fun stop() {
        try {
            watch?.cancel()
            watch?.join()
            reconciler.stop()
        } finally {
            ownedService?.stop()?.requireSuccess("stop")
        }
    }
}

private fun <Value> com.typewritermc.services.libs.registrar.RegistrarResult<Value>.requireSuccess(operation: String): Value =
    when (this) {
        is com.typewritermc.services.libs.registrar.RegistrarResult.Success -> value
        is com.typewritermc.services.libs.registrar.RegistrarResult.Failure -> error("Loader registration $operation failed: $failure")
    }

private fun com.typewritermc.services.libs.registrar.RegistrarStopResult.requireSuccess(operation: String) {
    if (this is com.typewritermc.services.libs.registrar.RegistrarStopResult.Failure) {
        error("Loader registration $operation failed: $failures")
    }
}
