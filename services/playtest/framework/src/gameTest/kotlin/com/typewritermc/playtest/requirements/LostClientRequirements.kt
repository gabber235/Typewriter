package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.ClientLost
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.WindowMissed
import com.typewritermc.playtest.alongside
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.crashClient
import com.typewritermc.playtest.cueOnceOpen
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.string.shouldContain

val LostClientRequirements by testSuite(compartment = { GameCompartment }) {
    alongside(
        "LOST-1",
        "a client that crashes fails its own attempt with the reason, the attempt beside it keeps its verdicts, and a new client serves later attempts",
        busy = { otherWaits ->
            probe.chat(player, "Hello")
            otherWaits.await()

            crashClient(player)

            val lost = shouldThrow<ClientLost> { within(10.ticks) { player sees chat("Goodbye") } }
            lost.report shouldContain "${player.name}'s client was lost: its "
        },
        other = { waiting ->
            val hello = probe.chat(player, "Hello")

            val missed = cueOnceOpen(waiting) { shouldThrow<WindowMissed> { within(20.ticks) { player sees chat("Goodbye") } } }

            missed.report shouldContain
                "${player.name} did not see chat \"Goodbye\" within 20 ticks (ticks ${hello.tick + 1} to ${hello.tick + 20})"
            within(10.ticks) { player sees chat("Hello") }
        },
        // The whole pool, so this attempt runs only once the crashed client's replacement is ready.
        afterwardPlayers = 4,
        afterward = {
            probe.chat(players, "Fresh")

            within(10.ticks) { players.forEach { it sees chat("Fresh") } }
        },
    )
}
