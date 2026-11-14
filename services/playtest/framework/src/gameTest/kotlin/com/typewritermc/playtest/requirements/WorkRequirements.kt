package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.WindowMissed
import com.typewritermc.playtest.WorkHung
import com.typewritermc.playtest.alongside
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.cueOnceOpen
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import com.typewritermc.playtest.work
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.comparables.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

val WorkRequirements by testSuite(compartment = { GameCompartment }) {
    requirement(
        "ASYNC-1",
        "a chat line that counted work sends after 120 ms of wall clock shows within 4 ticks, as ticks wait for the work",
    ) {
        work(player, "Ledger lookup", millis = 120, then = "Ledger ready")

        within(4.ticks) { player sees chat("Ledger ready") }
    }

    requirement(
        "HUNG-1",
        "work still running 1 s after it began fails the attempt, naming the work, the player and its tick, and is never cancelled",
    ) {
        val began = work(player, "Ledger lookup", millis = 1_500, then = "Ledger late")

        val hung = shouldThrow<WorkHung> { within(4.ticks) { player sees chat("Ledger late") } }

        hung.report shouldBe
            "${player.name}'s work \"Ledger lookup\" began after tick ${began.tick} and still ran 1 s later; it was not cancelled."
        // Hung work holds no tick, so a window this long outlasts the work's last half second.
        within(2_000.ticks) { player sees chat("Ledger late") }
    }

    alongside(
        "ALONGSIDE-1",
        "one attempt's slow work holds the ticks of the attempt beside it, whose window still counts exactly its ticks",
        busy = { otherWaits ->
            otherWaits.await()
            work(player, "Ledger lookup", millis = 300, then = "Ledger ready")

            within(4.ticks) { player sees chat("Ledger ready") }
        },
        other = { waiting ->
            val hello = probe.chat(player, "Hello")
            val opened = TimeSource.Monotonic.markNow()

            val missed = cueOnceOpen(waiting) { shouldThrow<WindowMissed> { within(20.ticks) { player sees chat("Goodbye") } } }

            opened.elapsedNow() shouldBeGreaterThan 300.milliseconds
            missed.report shouldContain
                "${player.name} did not see chat \"Goodbye\" within 20 ticks (ticks ${hello.tick + 1} to ${hello.tick + 20})"
            within(10.ticks) { player sees chat("Hello") }
        },
    )

    alongside(
        "ALONGSIDE-2",
        "hung work fails only its own attempt, while the attempt beside it keeps its verdicts",
        busy = { otherWaits ->
            otherWaits.await()
            work(player, "Ledger lookup", millis = 1_500, then = "Ledger late")

            shouldThrow<WorkHung> { within(4.ticks) { player sees chat("Ledger late") } }
            within(2_000.ticks) { player sees chat("Ledger late") }
        },
        other = { waiting ->
            val hello = probe.chat(player, "Hello")
            val opened = TimeSource.Monotonic.markNow()

            val missed = cueOnceOpen(waiting) { shouldThrow<WindowMissed> { within(20.ticks) { player sees chat("Goodbye") } } }

            opened.elapsedNow() shouldBeGreaterThan 1.seconds
            missed.report shouldContain
                "${player.name} did not see chat \"Goodbye\" within 20 ticks (ticks ${hello.tick + 1} to ${hello.tick + 20})"
            within(10.ticks) { player sees chat("Hello") }
        },
    )
}
