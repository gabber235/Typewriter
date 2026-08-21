package com.typewritermc.realm.deployment

import com.typewritermc.loader.DeploymentContext
import com.typewritermc.loader.DeploymentEntrypoint
import com.typewritermc.loader.DeploymentRuntime
import com.typewritermc.realm.DefaultRealmRuntimeFactory
import java.time.Instant

/** Starts the complete Realm, panel engine, and Realm targeted extension scope for one deployment. */
fun interface RealmRuntimeFactory {
    suspend fun start(context: DeploymentContext): ManagedRealmRuntime
}

/**
 * Exposes the upgrade preparation and final shutdown boundary of a running Realm deployment.
 *
 * The scaffold accepts only [CompatibleNoOperationCheckpoint]. Future checkpoint types must define compatible state
 * transfer before the loader can replace those Realm versions.
 */
interface ManagedRealmRuntime {
    suspend fun prepareUpgradeCheckpoint(): RealmUpgradeCheckpoint

    suspend fun stop()
}

/** States that the stopped Realm requires no data migration before a compatible replacement starts. */
data object CompatibleNoOperationCheckpoint : RealmUpgradeCheckpoint

/** Captures Realm state required by a later runtime version during whole deployment replacement. */
sealed interface RealmUpgradeCheckpoint

/**
 * Adapts a managed Realm runtime to the stable loader deployment lifecycle.
 *
 * Quiescing prepares exactly one upgrade checkpoint. Stopping rejects unsupported checkpoint types before releasing the
 * Realm, preventing silent state loss during a future migration.
 */
class RealmDeploymentEntrypoint(
    private val factory: RealmRuntimeFactory = DefaultRealmRuntimeFactory(),
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
