package com.typewritermc.engine.paper

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.testSuite
import kotlin.time.Duration.Companion.minutes

/** The service of the shared Paper's loader, as the stack's engine binder names slot 0. */
private const val SHARED_PAPER = "game_paper_0"

val PaperSessionRequirements by testSuite(
    compartment = { GameCompartment },
    // Once, before any requirement claims a player: the shared Paper's engine must run before a
    // requirement can rely on it. The wait is wall clock, so it stays outside every window.
    testConfig =
        TestConfig.aroundAll { requirements ->
            StackObserver.fromEnvironment().use { it.awaitActive(SHARED_PAPER, 3.minutes) }
            requirements()
        },
) {
    requirement(
        "GAME-S1",
        "a player who joins the game Paper has a session in the stack's Realm, held by that Paper's engine",
    ) {
        StackObserver.fromEnvironment().use { observer ->
            val engine = observer.engineId(SHARED_PAPER)
            player.quit()
            player.rejoin()
            within(20.ticks) {
                state("the player's session is held by the shared Paper's engine") {
                    observer.session(player.uuid)?.holder == engine
                }
            }
        }
    }

    requirement(
        "GAME-S2",
        "a player who quits and rejoins the game Paper keeps their session and when it began",
    ) {
        StackObserver.fromEnvironment().use { observer ->
            val engine = observer.engineId(SHARED_PAPER)
            val before = observer.session(player.uuid) ?: error("the player had no session before quitting")

            player.quit()
            player.rejoin()
            within(20.ticks) {
                state("the session is held by the shared Paper's engine since it first began") {
                    val session = observer.session(player.uuid)
                    session != null && session.holder == engine && session.value.since == before.value.since
                }
                never.state("the session is gone") { observer.session(player.uuid) == null }
            }
        }
    }
}
