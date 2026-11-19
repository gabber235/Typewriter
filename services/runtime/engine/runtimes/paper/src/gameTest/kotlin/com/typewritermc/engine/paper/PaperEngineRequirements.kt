package com.typewritermc.engine.paper

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.testSuite
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.topology.ChildRuntimeStatus
import kotlin.time.Duration.Companion.minutes

/** The service of the shared Paper's loader, as the stack's engine binder names slot 0. */
private const val SHARED_PAPER = "game_paper_0"

val PaperEngineRequirements by testSuite(
    compartment = { GameCompartment },
    // Once, before any requirement claims a player: the shared Paper's engine must run before a
    // requirement can rely on it. The wait is wall clock, so it stays outside every window.
    testConfig =
        TestConfig.aroundAll { requirements ->
            StackObserver.fromEnvironment().use { it.awaitActive(SHARED_PAPER, 3.minutes) }
            requirements()
        },
) {
    // Node 3's GAME-S1 (a player joins, then its session key appears) replaces this requirement.
    requirement(
        "PAPER-ENGINE-1",
        "a player who joins the game Paper finds Typewriter's Paper engine active on the stack's Realm",
    ) {
        val realm = System.getenv("STACK_REALM") ?: error("STACK_REALM is not set: run the game suite through cargo xtask e2e game")
        player.quit()

        StackObserver.fromEnvironment().use { observer ->
            player.rejoin()
            within(20.ticks) {
                state("the shared Paper's engine reports active on the stack's Realm in the organization topology") {
                    val engine = observer.engine(SHARED_PAPER)
                    val key = engine?.realm?.realmId?.key as? RecordIdKey.StringWrapper
                    engine?.state?.status == ChildRuntimeStatus.ACTIVE && key?.value == realm
                }
            }
        }
    }
}
