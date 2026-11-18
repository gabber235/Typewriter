package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.WindowMissed
import com.typewritermc.playtest.mark
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.string.shouldContain
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.wire.StateKind

// The state these requirements read is a mark Paper keeps for the player, which no player perceives:
// it stands in for a record in a store, read from the test JVM after each tick.
val StateRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("STATE-1", "a state check passes at the first tick of its window after which the state it reads holds") {
        mark(player, StateKind.EXPERIENCE)

        within(10.ticks) { state("Paper keeps an experience mark") { StateKind.EXPERIENCE in attempt.query(player) } }
    }

    requirement(
        "STATE-2",
        "a never state check fails its window at the first tick after which the state it reads holds",
        demonstrates = Demonstrates.FAILURE,
    ) {
        val missed =
            shouldThrow<WindowMissed> {
                mark(player, StateKind.EXPERIENCE)
                within(10.ticks) {
                    state("Paper keeps the player") { attempt.query(player).isNotEmpty() }
                    never.state("Paper keeps an experience mark") { StateKind.EXPERIENCE in attempt.query(player) }
                }
            }

        missed.report shouldContain "Paper keeps an experience mark held at tick 1 of the 10 tick window"
    }
}
