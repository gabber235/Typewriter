package com.typewritermc.realm.deployment

import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeProvider
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.realm.DefaultRealmRuntimeFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Stages Realm owned resources from the loader context.
 *
 * Success transfers ownership to the managed runtime, while activation remains a separate lifecycle step.
 */
fun interface RealmRuntimeFactory {
    suspend fun stage(context: HostedDeploymentContext): ManagedRealmRuntime
}

/**
 * Defines Realm activation and reversible quiescing beneath the loader lifecycle adapter.
 *
 * Stop is final cleanup; resume may recreate active resources retained only as configuration during quiescence.
 */
interface ManagedRealmRuntime {
    suspend fun activate()

    suspend fun quiesce()

    suspend fun resume()

    suspend fun stop()
}

/**
 * Exposes Realm staging through the shared hosted provider contract.
 *
 * The adapter reports activation success or failure as loader health. It does not continuously aggregate compiler
 * or route health into that signal.
 */
class RealmDeploymentEntrypoint(
    private val factory: RealmRuntimeFactory = DefaultRealmRuntimeFactory(),
) : HostedRuntimeProvider {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = RealmDeploymentRuntime(factory.stage(context))
}

private class RealmDeploymentRuntime(
    private val realm: ManagedRealmRuntime,
) : StagedHostedRuntime {
    private val mutableHealth = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = mutableHealth

    override suspend fun activate() {
        try {
            realm.activate()
            mutableHealth.value = RuntimeHealth.Healthy
        } catch (failure: Throwable) {
            mutableHealth.value = RuntimeHealth.Unhealthy(failure.message ?: "Realm activation failed.")
            throw failure
        }
    }

    override suspend fun quiesce() {
        realm.quiesce()
        mutableHealth.value = RuntimeHealth.Staged
    }

    override suspend fun resume() {
        realm.resume()
        mutableHealth.value = RuntimeHealth.Healthy
    }

    override suspend fun close() {
        realm.stop()
    }
}
