package com.typewritermc.engine.paper

import com.typewritermc.identity.SessionId
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.bridge.PlaytestSignal
import com.typewritermc.playtest.bridge.PlaytestSignalDefinition
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.coroutineScope
import skirout.editor.v1.event.EventResult
import skirout.editor.v1.event.EventSubject
import skirout.kernel.v1.identity.PrincipalId
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import com.typewritermc.identity.PrincipalId as Principal
import com.typewritermc.identity.Protagonist as Player

val EventDeliveryRequirements by testSuite(
    compartment = { GameCompartment },
    testConfig =
        TestConfig.aroundAll { requirements ->
            StackObserver.fromEnvironment().use { it.awaitActive("game_paper_0", 3.minutes) }
            requirements()
        },
) {
    requirement(
        "GAME-D1",
        "an event a panel tab emits at a player runs on the Paper that holds the player, and the tab gets done",
    ) {
        val author = StackAuthor.shared()
        val id = player.uuid.toString()
        val signal =
            author.encode(
                PlaytestSignalDefinition.id.use(),
                PlaytestSignal(Player(Principal(Principal.MINECRAFT, id)), "Signal from the panel"),
            )
        author.panelTab {
            StackObserver.fromEnvironment().use { observer ->
                eventually(10.seconds) { observer.session(protagonist, SessionId(session)).shouldNotBeNull() }
            }
            coroutineScope {
                val result =
                    outside("the panel tab emits the signal at the player") {
                        emit(EventSubject.createProtagonist(principal = PrincipalId(kind = Principal.MINECRAFT, id = id)), signal)
                    }
                within(40.ticks) { player sees chat("Signal from the panel") }
                result.await() shouldBe EventResult.DONE
            }
        }
    }
}
