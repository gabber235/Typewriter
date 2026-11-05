package com.typewritermc.services.libs.utils

import kotlinx.coroutines.channels.Channel
import kotlin.time.Duration

/**
 * Deterministic [DelayScheduler] for tests.
 *
 * Every requested delay runs [onDelay] and becomes visible to [awaitRequest]. By default a delay
 * returns at once. With [holdDelays] each delay keeps waiting until [resume] releases it, so a test
 * can observe the state a component holds while it waits.
 */
class FakeDelayScheduler(
    private val holdDelays: Boolean = false,
    private val onDelay: suspend (Duration) -> Unit = {},
) : DelayScheduler {
    private val requests = Channel<Duration>(Channel.UNLIMITED)
    private val releases = Channel<Unit>(Channel.UNLIMITED)

    override suspend fun delay(duration: Duration) {
        onDelay(duration)
        requests.send(duration)
        if (holdDelays) releases.receive()
    }

    /** Suspends until the next delay is requested and returns its duration. */
    suspend fun awaitRequest(): Duration = requests.receive()

    /** Releases one held delay. */
    fun resume() {
        check(releases.trySend(Unit).isSuccess) { "The release channel refused a resume." }
    }
}
