package com.typewritermc.realm.deployment

import com.typewritermc.loader.DeploymentContext
import com.typewritermc.loader.DeploymentEntrypoint
import com.typewritermc.loader.DeploymentRuntime
import java.time.Instant

fun interface RealmRuntimeFactory {
    suspend fun start(context: DeploymentContext): ManagedRealmRuntime
}

interface ManagedRealmRuntime {
    suspend fun prepareUpgradeCheckpoint(): RealmUpgradeCheckpoint

    suspend fun stop()
}

data object CompatibleNoOperationCheckpoint : RealmUpgradeCheckpoint

sealed interface RealmUpgradeCheckpoint

class RealmDeploymentEntrypoint(
    private val factory: RealmRuntimeFactory,
) : DeploymentEntrypoint {
    override suspend fun start(context: DeploymentContext): DeploymentRuntime = RealmDeploymentRuntime(factory.start(context))
}

private class RealmDeploymentRuntime(
    private val realm: ManagedRealmRuntime,
) : DeploymentRuntime {
    private var checkpoint: RealmUpgradeCheckpoint? = null

    override suspend fun quiesce(deadline: Instant) {
        checkpoint = realm.prepareUpgradeCheckpoint()
    }

    override suspend fun stop() {
        check(checkpoint == null || checkpoint == CompatibleNoOperationCheckpoint) {
            "Unsupported Realm upgrade checkpoint."
        }
        realm.stop()
    }
}
