package com.typewritermc.engine.paper

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import com.typewritermc.services.libs.communicator.kv.LeaseState
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.testSuite
import java.time.Instant
import java.time.temporal.ChronoUnit
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

    requirement(
        "GAME-S3",
        "a player who quits leaves their session with no holder, still alive for a rejoin or a server move",
        // The other player stays on Paper, so Paper runs the ticks the window counts while the leaver is away.
        players = 2,
    ) {
        val (leaver, _) = players
        StackObserver.fromEnvironment().use { observer ->
            observer.session(leaver.uuid) ?: error("the player had no session before quitting")

            leaver.quit()
            within(20.ticks) {
                state("the session is alive and held by no engine") { observer.session(leaver.uuid)?.state == LeaseState.Vacant }
                never.state("the session is gone") { observer.session(leaver.uuid) == null }
            }
        }
    }

    requirement(
        "GAME-S4",
        "a player who rejoins holds the session with a claim stamped at that login",
    ) {
        StackObserver.fromEnvironment().use { observer ->
            player.quit()
            val left = Instant.now().truncatedTo(ChronoUnit.MILLIS)

            player.rejoin()
            within(20.ticks) {
                state("the session's claim is stamped with a login after the player left") {
                    val held = observer.session(player.uuid)?.state as? LeaseState.Held
                    held != null && held.claimed >= left && held.claimed <= Instant.now()
                }
            }
        }
    }
}
