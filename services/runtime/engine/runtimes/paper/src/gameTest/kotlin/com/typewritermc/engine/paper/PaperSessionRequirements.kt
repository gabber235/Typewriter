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
        "GAME-S2",
        "a quit writes the session key within the window; the rejoin rewrites it, held by the engine, since kept",
        players = 2,
    ) {
        // The stayer steps the ticks of the windows while the leaver is away.
        val leaver = players.first()
        StackObserver.fromEnvironment().use { observer ->
            val engine = observer.engineId(SHARED_PAPER)
            val joined = observer.session(leaver.uuid) ?: error("the player had no session before quitting")

            leaver.quit()
            within(10.ticks) {
                state("the quit wrote the session key") { (observer.session(leaver.uuid)?.revision ?: 0) > joined.revision }
            }
            val quit = observer.session(leaver.uuid) ?: error("the session ended before the rejoin")

            leaver.rejoin()
            within(20.ticks) {
                state("the rejoin wrote the session key, held by the shared Paper's engine since the session began") {
                    val session = observer.session(leaver.uuid)
                    session != null &&
                        session.revision > quit.revision &&
                        session.entry.holder == engine &&
                        session.entry.since == joined.entry.since
                }
                never.state("the session is gone") { observer.session(leaver.uuid) == null }
            }
        }
    }
}
