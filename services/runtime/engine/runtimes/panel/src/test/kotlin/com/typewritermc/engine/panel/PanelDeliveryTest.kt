package com.typewritermc.engine.panel

import com.typewritermc.engine.delivery.testing.DeliveryHarness
import com.typewritermc.engine.delivery.testing.TestEventCodec
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.provided
import com.typewritermc.engine.events.testing.testShapes
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.EventResult
import com.typewritermc.events.EventShape
import com.typewritermc.events.HandlerPlan
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.protocol.transport.RealmActorRouteScope
import com.typewritermc.protocol.transport.generated.eventEmit
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.event.EmitEventRequest
import skirout.editor.v1.event.EmitEventResponse
import skirout.editor.v1.event.EventStatus
import skirout.editor.v1.event.OccurrenceId
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import skirout.editor.v1.event.EventResult as WireResult
import skirout.editor.v1.event.EventSubject as WireSubject
import skirout.kernel.v1.identity.PrincipalId as WirePrincipalId

/** The panel engine as a holder of panel users and as the gateway panel tabs emit events through. */
val PanelDeliveryTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("PANEL-EMIT-1: a tab's event at a player held by a game engine runs there and the tab gets done") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val panel = engine("panel-realm", shapes(), kind = panelModule)
            val game = engine("primary-game", shapes() + afterPoke { ran += it })
            val alex = player()
            game.reporter.connected(alex, SessionId("alex"))
            panel.reporter.connected(USER, SessionId("tab"))
            sees(panel, alex, "primary-game")
            sees(panel, USER, "panel-realm")

            val answer = tab("user", "tab").emit(session = "tab", subject = alex, event = Poke(alex))

            answer.finalResult() shouldBe WireResult.DONE
            ran shouldContainExactly listOf(Poke(alex))
        }
    }

    test("PANEL-EMIT-2: a tab naming a session it does not hold is refused and nothing is sent") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val panel = engine("panel-realm", shapes(), kind = panelModule)
            val game = engine("primary-game", shapes() + afterPoke { ran += it })
            val alex = player()
            val sam = Protagonist(PrincipalId(PrincipalId.USER, "sam"))
            game.reporter.connected(alex, SessionId("alex"))
            panel.reporter.connected(sam, SessionId("sams-tab"))
            sees(panel, alex, "primary-game")
            sees(panel, sam, "panel-realm")

            val answer = tab("user", "tab").emit(session = "sams-tab", subject = alex, event = Poke(alex))

            answer.shouldBeInstanceOf<EmitEventResponse.SessionNotHeldErrorWrapper>()
            ran.shouldBeEmpty()
        }
    }

    test("PANEL-HOLD-1: an event at a panel user reaches the panel engine holding the user's tab") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val panel = engine("panel-realm", shapes() + afterPoke { ran += it }, kind = panelModule)
            val game = engine("primary-game", shapes())
            panel.reporter.connected(USER, SessionId("tab"))
            sees(game, USER, "panel-realm")

            game.emitter.send(Poke(USER)) shouldBe EventResult.Done

            ran shouldContainExactly listOf(Poke(USER))
        }
    }
}

private val USER = Protagonist(PrincipalId(PrincipalId.USER, "user"))

private fun player() = Protagonist(PrincipalId(PrincipalId.MINECRAFT, UUID.randomUUID().toString()))

private fun shapes() = testShapes.map { provided(it, listOf(EventShape::class)) }

private fun afterPoke(run: (Poke) -> Unit) =
    listOf(provided(after(Poke::class) { poke, _ -> run(poke) }, listOf(AfterHandler::class, HandlerPlan::class)))

/** Emits [event] at [subject] as caused by this tab's [session], waiting long enough for a final answer. */
private suspend fun Communicator.emit(
    session: String,
    subject: Protagonist,
    event: Poke,
): EmitEventResponse {
    val actor = RealmActorRouteScope("organization", "realm", "user")
    val request =
        EmitEventRequest(
            occurrence = OccurrenceId(value = UUID.randomUUID().toString()),
            session = skirout.kernel.v1.identity.SessionId(value = session),
            subject = WireSubject.createProtagonist(principal = WirePrincipalId(kind = subject.principal.kind, id = subject.principal.id)),
            event = TestEventCodec().encode(event),
            waitMs = 3000,
            confirmed = false,
        )
    return when (val result = request(actor.eventEmit, actor, request)) {
        is CommunicationResult.Success -> result.value
        is CommunicationResult.Failure -> error("the tab's emit failed: ${result.error}")
    }
}

private fun EmitEventResponse.finalResult(): WireResult {
    val status = shouldBeInstanceOf<EmitEventResponse.SuccessWrapper>().value
    return status.shouldBeInstanceOf<EventStatus.FinalWrapper>().value
}
