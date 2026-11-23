package com.typewritermc.engine.panel

import com.typewritermc.engine.delivery.testing.DeliveryHarness
import com.typewritermc.engine.delivery.testing.afterPoke
import com.typewritermc.engine.delivery.testing.randomPlayer
import com.typewritermc.engine.delivery.testing.shapeParts
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.panel.testing.PANEL_USER
import com.typewritermc.engine.panel.testing.emit
import com.typewritermc.engine.panel.testing.finalResult
import com.typewritermc.events.EventResult
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.event.EmitEventResponse
import java.util.concurrent.CopyOnWriteArrayList
import skirout.editor.v1.event.EventResult as WireResult

/** The panel engine as a holder of panel users and as the gateway panel tabs emit events through. */
val PanelDeliveryTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("PANEL-EMIT-1: a tab's event at a player held by a game engine runs there and the tab gets done") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val panel = engine("panel-realm", shapeParts(), kind = panelModule)
            val game = engine("primary-game", shapeParts() + afterPoke { ran += it })
            val alex = randomPlayer()
            game.reporter.connected(alex, SessionId("alex"))
            panel.reporter.connected(PANEL_USER, SessionId("tab"))
            sees(panel, alex, "primary-game")
            sees(panel, PANEL_USER, "panel-realm")

            val answer = tab("user", "tab").emit(session = "tab", subject = alex, event = Poke(alex))

            answer.finalResult() shouldBe WireResult.DONE
            ran shouldContainExactly listOf(Poke(alex))
        }
    }

    test("PANEL-EMIT-2: a tab naming a session it does not hold is refused and nothing is sent") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val panel = engine("panel-realm", shapeParts(), kind = panelModule)
            val game = engine("primary-game", shapeParts() + afterPoke { ran += it })
            val alex = randomPlayer()
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
            val panel = engine("panel-realm", shapeParts() + afterPoke { ran += it }, kind = panelModule)
            val game = engine("primary-game", shapeParts())
            panel.reporter.connected(PANEL_USER, SessionId("tab"))
            sees(game, PANEL_USER, "panel-realm")

            game.emitter.send(Poke(PANEL_USER)) shouldBe EventResult.Done

            ran shouldContainExactly listOf(Poke(PANEL_USER))
        }
    }
}
