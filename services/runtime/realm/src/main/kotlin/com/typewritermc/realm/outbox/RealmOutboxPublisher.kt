package com.typewritermc.realm.outbox

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import java.time.Clock
import kotlin.coroutines.coroutineContext
import kotlin.time.toJavaDuration
import kotlin.time.toKotlinDuration

internal class RealmOutboxPublisher(
    private val outbox: RealmOutbox,
    private val scope: CoroutineScope,
    private val clock: Clock,
    private val retryPolicy: RetryPolicy,
    private val delayScheduler: DelayScheduler,
) {
    private var publisher: Job? = null

    suspend fun replaceCommunicator(communicator: Communicator) {
        stop()
        publisher = scope.launch { publishPending(communicator) }
        outbox.signalPending()
    }

    suspend fun stop() {
        publisher?.cancelAndJoin()
        publisher = null
    }

    private suspend fun publishPending(communicator: Communicator) {
        while (true) {
            coroutineContext.ensureActive()
            val pending = outbox.pending(1)
            if (pending.isEmpty()) {
                outbox.awaitPending()
                continue
            }
            val row = pending.single()
            val eligibilityDelay =
                java.time.Duration
                    .between(clock.instant(), row.availableAt)
                    .toKotlinDuration()
            if (eligibilityDelay.isPositive()) {
                delayScheduler.delay(eligibilityDelay)
                continue
            }
            coroutineContext.ensureActive()
            when (communicator.publishEncoded(row.event)) {
                is CommunicationResult.Success -> {
                    outbox.markPublished(row.id, clock.instant())
                }

                is CommunicationResult.Failure -> {
                    val retryDelay = retryPolicy.delayFor(row.attempts)
                    outbox.markFailed(row.id, clock.instant().plus(retryDelay.toJavaDuration()))
                    delayScheduler.delay(retryDelay)
                }
            }
        }
    }
}
