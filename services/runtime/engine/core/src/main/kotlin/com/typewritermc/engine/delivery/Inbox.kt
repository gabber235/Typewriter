package com.typewritermc.engine.delivery

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.SubjectHolding
import com.typewritermc.events.Event
import com.typewritermc.events.EventResult
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import skirout.editor.v1.event.DeliverEventRequest
import skirout.editor.v1.event.DeliverEventResponse
import skirout.editor.v1.event.EventDelivery
import skirout.editor.v1.event.EventStatus
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The holder side of delivery: answers every ask about an occurrence sent to this engine. The first ask queues the
 * occurrence, if this engine holds its subject, and every later ask with the same occurrence waits on that one run, so
 * an occurrence runs here once however often it is asked. Each answer comes once the occurrence is final or once the
 * ask's wait passed. An occurrence is kept for the [timings]' window after it was final and last asked; an ask that says the sender
 * had an answer before, about an occurrence this engine does not know, means this engine lost it by restarting.
 */
class Inbox(
    private val holding: SubjectHolding,
    private val runtime: EventRuntime,
    private val codec: EventCodec,
    private val scope: CoroutineScope,
    private val timings: DeliveryTimings = DeliveryTimings(),
    private val time: TimeSource = TimeSource.Monotonic,
) {
    private val occurrences = ConcurrentHashMap<String, Occurrence>()

    private class Occurrence(
        val result: Deferred<EventResult>,
        @Volatile var asked: TimeMark,
    )

    init {
        scope.launch {
            while (isActive) {
                delay(timings.kept / 2)
                forgetOld()
            }
        }
    }

    suspend fun answer(request: DeliverEventRequest): DeliverEventResponse {
        val id = request.delivery.occurrence.value
        val occurrence =
            occurrences[id] ?: when (val first = first(request)) {
                is First.Refused -> return first.response
                is First.Accepted -> occurrences.putIfAbsent(id, first.occurrence) ?: first.occurrence
            }
        occurrence.result.start()
        occurrence.asked = time.markNow()
        val result = withTimeoutOrNull(request.waitMs.coerceAtLeast(0).milliseconds) { occurrence.result.await() }
        occurrence.asked = time.markNow()
        val status = result?.let { EventStatus.FinalWrapper(it.toWire(codec)) } ?: EventStatus.RUNNING
        return DeliverEventResponse.SuccessWrapper(status)
    }

    private sealed interface First {
        class Accepted(
            val occurrence: Occurrence,
        ) : First

        class Refused(
            val response: DeliverEventResponse,
        ) : First
    }

    /**
     * What the first ask about an occurrence leads to: refused when the sender had an answer before or this engine does
     * not hold the subject; else an occurrence whose run starts once it is the one kept, so a racing ask runs nothing.
     */
    private fun first(request: DeliverEventRequest): First {
        val delivery = request.delivery
        if (request.confirmed) return First.Refused(DeliverEventResponse.createForgottenError(occurrence = delivery.occurrence))
        val subject = delivery.subject.toIdentity() ?: return accepted(final(UNKNOWN_SUBJECT))
        if (!holding.holds(subject)) return First.Refused(DeliverEventResponse.createNotHeldError(subject = delivery.subject))
        val event =
            when (val decoded = codec.decode(delivery.event)) {
                is Decoded.Unknown -> return accepted(final(unknownType(decoded.type)))
                is Decoded.Value -> decoded.value as? Event ?: return accepted(final(unknownType("${decoded.value::class.simpleName}")))
            }
        if (runtime.subjectOf(event) != subject) return accepted(final(SUBJECT_MISMATCH))
        return accepted(scope.async(start = CoroutineStart.LAZY) { runtime.run(event, delivery.originOrNull()) })
    }

    private fun accepted(result: Deferred<EventResult>) = First.Accepted(Occurrence(result, time.markNow()))

    private fun final(result: EventResult): Deferred<EventResult> = CompletableDeferred(result)

    private fun forgetOld() {
        occurrences.entries.removeIf { (_, occurrence) -> occurrence.result.isCompleted && occurrence.asked.elapsedNow() > timings.kept }
    }

    private companion object {
        val UNKNOWN_SUBJECT = deliveryFailure("unknown_subject", "This engine does not know the kind of identity the event is about.")
        val SUBJECT_MISMATCH = deliveryFailure("subject_mismatch", "The event is about another identity than the subject it was sent with.")

        fun unknownType(type: String) = deliveryFailure("unknown_type", "This engine cannot decode an event of type $type.")
    }
}

private fun EventDelivery.originOrNull() = origin?.toOrigin()

/** Serves [inbox] on [link] while the engine is active. */
class InboxRegistrar(
    private val link: EngineLink,
    private val inbox: Inbox,
) : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        scope.coroutineScope.launch { link.serve(inbox::answer) }
    }
}
