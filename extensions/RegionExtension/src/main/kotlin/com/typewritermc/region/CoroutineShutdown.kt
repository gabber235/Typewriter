package com.typewritermc.region

import kotlinx.coroutines.Job
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * How long a shutdown waits for a coroutine to finish its cleanup before giving up on it.
 */
private val SHUTDOWN_TIMEOUT: Duration = 2.seconds

/**
 * Cancels the job and waits for it to actually finish.
 *
 * Cancelling alone is not enough. A reload closes the extension's class loader as soon as every
 * `Initializable` has shut down, so a coroutine that is still winding down resumes into a class
 * loader that is gone, and fails with a `NoClassDefFoundError` while running the cleanup that was
 * supposed to despawn its entities. Waiting keeps that cleanup inside the class loader's
 * lifetime.
 *
 * The wait is bounded, because a cleanup can also be unable to finish: on a server shutdown the
 * Bukkit scheduler is already disposed, so a hop to the main thread may never be dispatched.
 * Waiting without a bound would hang the shutdown in that case; the bound leaves a warning in
 * the log instead.
 */
internal suspend fun Job.cancelAndJoinBounded(timeout: Duration = SHUTDOWN_TIMEOUT) {
    cancel()
    withTimeoutOrNull(timeout) { join() }
}
