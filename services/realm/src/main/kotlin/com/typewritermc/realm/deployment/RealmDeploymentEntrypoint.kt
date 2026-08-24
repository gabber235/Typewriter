package com.typewritermc.realm.deployment

import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeProvider
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.realm.DefaultRealmRuntimeFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

fun interface RealmRuntimeFactory {
    suspend fun stage(context: HostedDeploymentContext): ManagedRealmRuntime
}

interface ManagedRealmRuntime {
    suspend fun activate()

    suspend fun quiesce()

    suspend fun resume()

    suspend fun stop()
}

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
