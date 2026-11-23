package com.typewritermc.engine.delivery.testing

import com.typewritermc.engine.delivery.toResult
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.provided
import com.typewritermc.engine.events.testing.testShapes
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.events.Event
import com.typewritermc.events.EventResult
import com.typewritermc.events.EventShape
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.VerdictHandler
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.event.DeliverEventRequest
import skirout.editor.v1.event.DeliverEventResponse
import skirout.editor.v1.event.EventDelivery
import skirout.editor.v1.event.EventStatus
import skirout.editor.v1.event.OccurrenceId
import java.util.UUID
import skirout.editor.v1.event.EventSubject as WireSubject
import skirout.kernel.v1.identity.PrincipalId as WirePrincipalId
import skirout.kernel.v1.identity.Protagonist as WireProtagonist

/** The roles an after handler of the test events is asked for by. */
val AFTER_PLAN = listOf(AfterHandler::class, HandlerPlan::class)

/** The roles a verdict handler of the test events is asked for by. */
val VERDICT_PLAN = listOf(VerdictHandler::class, HandlerPlan::class)

/** A Minecraft player no other test names. */
fun randomPlayer() = Protagonist(PrincipalId(PrincipalId.MINECRAFT, UUID.randomUUID().toString()))

/** The shapes of the test events, as parts an engine is given. */
fun shapeParts(): List<EnginePartProvider> = testShapes.map { provided(it, listOf(EventShape::class)) }

/** An after handler of [Poke] that runs [run], as the parts an engine is given. */
fun afterPoke(run: suspend (Poke) -> Unit): List<EnginePartProvider> =
    listOf(provided(after(Poke::class) { poke, _ -> run(poke) }, AFTER_PLAN))

/** A first ask of [event] sent with [subject], as a sender builds it, waiting long enough for a final answer. */
fun firstAsk(
    subject: Protagonist,
    event: Event,
) = DeliverEventRequest(
    delivery =
        EventDelivery(
            occurrence = OccurrenceId(value = UUID.randomUUID().toString()),
            subject = WireSubject.ProtagonistWrapper(WireProtagonist(principal = WirePrincipalId(kind = subject.principal.kind, id = subject.principal.id))),
            event = TestEventCodec().encode(event),
            origin = null,
        ),
    waitMs = 2000,
    confirmed = false,
)

/** This ask again, saying the sender had an answer before. */
fun DeliverEventRequest.confirmedAsk() = DeliverEventRequest(delivery = delivery, waitMs = waitMs, confirmed = true)

/** The final result this answer carries; fails when it carries none. */
fun DeliverEventResponse?.finalResult(): EventResult {
    val status = this.shouldBeInstanceOf<DeliverEventResponse.SuccessWrapper>().value
    return status.shouldBeInstanceOf<EventStatus.FinalWrapper>().value.toResult(TestEventCodec())
}
