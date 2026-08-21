package com.typewritermc.loader

import java.nio.file.Path
import java.time.Instant

/**
 * Starts a loader managed child deployment after its artifacts have been staged and verified.
 *
 * Implementations own child specific initialization. They must return only after the deployment is ready to serve, or
 * throw so the loader can retain the previous deployment.
 */
interface DeploymentEntrypoint {
    suspend fun start(context: DeploymentContext): DeploymentRuntime
}

/**
 * Controls the lifetime of one active child deployment.
 *
 * [quiesce] stops accepting new work and attempts to finish owned work before the absolute [Instant] deadline. [stop]
 * releases all resources and must be safe after a partial start or earlier quiesce.
 */
interface DeploymentRuntime {
    suspend fun quiesce(deadline: Instant)

    suspend fun stop()
}

/**
 * Adds reversible activation to runtimes that can participate in staged replacement.
 *
 * The loader stages replacements before quiescing the current runtime. If activation fails, [resume] restores the
 * retained runtime before the failed replacement is stopped.
 */
interface ReplaceableDeploymentRuntime : DeploymentRuntime {
    suspend fun activate()

    suspend fun resume()
}

/**
 * Supplies stable host ownership and isolated storage to a staged child deployment.
 *
 * [workDirectory] belongs exclusively to [child] on this host. A factory may write staged state there, but must not
 * mutate another child directory.
 */
data class DeploymentContext(
    val hostId: String,
    val workDirectory: Path,
    val child: DesiredChild,
    val service: LoaderServiceConnection,
)

/**
 * Stages a requested child runtime without making it externally active.
 *
 * A successful result must be independently stoppable. Throwing leaves the currently active deployment untouched, and
 * the loader stops any siblings staged during the same reconciliation.
 */
fun interface DeploymentRuntimeFactory {
    suspend fun stage(
        child: DesiredChild,
        context: DeploymentContext,
    ): DeploymentRuntime
}
