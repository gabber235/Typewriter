package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.WindowMissed
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

val WindowRequirements by testSuite(compartment = { GameCompartment }) {
    requirement("WINDOW-1", "a check that never holds fails after its window, naming the tick and what the player perceived") {
        val hello = probe.chat(player, "Hello")

        val missed = shouldThrow<WindowMissed> { within(5.ticks) { player sees chat("Goodbye") } }

        val (first, last) = hello.tick + 1 to hello.tick + 5
        missed.report shouldContain "${player.name} did not see chat \"Goodbye\" within 5 ticks (ticks $first to $last)"
        missed.report shouldContain "At tick $last ${player.name} perceived chat \"Hello\""
        missed.at shouldBe "WindowRequirements.kt:17"
        within(10.ticks) { player sees chat("Hello") }
    }
}
