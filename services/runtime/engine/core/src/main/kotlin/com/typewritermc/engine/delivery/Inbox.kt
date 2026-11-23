package com.typewritermc.engine.delivery

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.delivery.Occurrences.First
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.SubjectHolding
import com.typewritermc.events.Event
import com.typewritermc.events.EventResult
import kotlinx.coroutines.launch
import skirout.editor.v1.event.DeliverEventRequest
import skirout.editor.v1.event.DeliverEventResponse
import skirout.editor.v1.event.EventStatus
import kotlin.time.Duration.Companion.milliseconds

/**
 * The holder side of delivery: answers every ask about an occurrence sent to this engine. The first ask queues the
 * occurrence, if this engine holds its subject, and every later ask with the same occurrence waits on that one run in
 * [occurrences], so an occurrence runs here once however often it is asked. Each answer comes once the occurrence is
 * final or once the ask's wait passed. An ask that says the sender had an answer before, about an occurrence this engine
 * no longer knows, means this engine lost it by restarting.
 */
class Inbox(
    private val holding: SubjectHolding,
    private val runtime: EventRuntime,
    private val codec: EventCodec,
    private val occurrences: Occurrences,
) {
    suspend fun answer(request: DeliverEventRequest): DeliverEventResponse =
        occurrences.answer(request.delivery.occurrence.value, request.waitMs.coerceAtLeast(0).milliseconds, { first(request) }) { result ->
            DeliverEventResponse.SuccessWrapper(result?.let { EventStatus.FinalWrapper(it.toWire(codec)) } ?: EventStatus.RUNNING)
        }

    /**
     * What the first ask about an occurrence leads to: refused when the sender had an answer before or this engine does
     * not hold the subject; a final failure when this engine cannot run it; else its run on this engine.
     */
    private fun first(request: DeliverEventRequest): First<DeliverEventResponse> {
        val delivery = request.delivery
        if (request.confirmed) return First.Refused(DeliverEventResponse.createForgottenError(occurrence = delivery.occurrence))
        val subject = delivery.subject.toIdentity() ?: return failed(UNKNOWN_SUBJECT)
        if (!holding.holds(subject)) return First.Refused(DeliverEventResponse.createNotHeldError(subject = delivery.subject))
        val event =
            when (val decoded = codec.decode(delivery.event)) {
                is Decoded.Unknown -> return failed(unknownType(decoded.type))
                is Decoded.Value -> decoded.value as? Event ?: return failed(unknownType("${decoded.value::class.simpleName}"))
            }
        if (runtime.subjectOf(event) != subject) return failed(SUBJECT_MISMATCH)
        val origin = delivery.origin?.toOrigin()
        return First.Run { runtime.run(event, origin) }
    }

    private fun failed(reason: EventResult.Failed) = First.Run { reason }

    private companion object {
        val UNKNOWN_SUBJECT = deliveryFailure("unknown_subject", "This engine does not know the kind of identity the event is about.")
        val SUBJECT_MISMATCH = deliveryFailure("subject_mismatch", "The event is about another identity than the subject it was sent with.")

        fun unknownType(type: String) = deliveryFailure("unknown_type", "This engine cannot decode an event of type $type.")
    }
}

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
