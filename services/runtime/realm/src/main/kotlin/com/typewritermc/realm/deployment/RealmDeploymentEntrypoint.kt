package com.typewritermc.realm.deployment

import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
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
    /** Starts database, compiler, and route resources for a staged deployment. */
    suspend fun activate()

    /** Stops active Realm work while retaining staged configuration for a possible resume. */
    suspend fun quiesce()

    /** Reestablishes active resources after [quiesce]. */
    suspend fun resume()

    /** Permanently releases staged and active resources. */
    suspend fun stop()
}

/**
 * Exposes Realm staging through the shared hosted entrypoint contract.
 *
 * The adapter reports activation success or failure as loader health. It does not continuously aggregate compiler
 * or route health into that signal.
 */
@ImprintRuntimeEntrypoint
class RealmDeploymentEntrypoint(
    private val factory: RealmRuntimeFactory = DefaultRealmRuntimeFactory(),
) : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = RealmDeploymentRuntime(factory.stage(context))
}

internal class RealmDeploymentRuntime(
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

    /** The loader close operation is terminal and delegates ownership release to the managed Realm. */
    override suspend fun close() {
        realm.stop()
    }
}
