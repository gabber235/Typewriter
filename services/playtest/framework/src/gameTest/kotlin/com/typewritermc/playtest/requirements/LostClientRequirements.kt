package com.typewritermc.playtest.requirements

import com.typewritermc.playtest.ClientLost
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.clientLostAlongside
import com.typewritermc.playtest.crashClient
import com.typewritermc.playtest.freezeClient
import com.typewritermc.playtest.ticks
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.string.shouldContain
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

val LostClientRequirements by testSuite(compartment = { GameCompartment }) {
    clientLostAlongside(
        "LOST-1",
        "a client that crashes fails its own attempt with the reason, the attempt beside it keeps its verdicts, and a new client serves later attempts",
    ) {
        crashClient(player)

        val lost = shouldThrow<ClientLost> { within(10.ticks) { player sees chat("Goodbye") } }

        lost.report shouldContain "${player.name}'s client was lost: its "
    }

    clientLostAlongside(
        "FROZEN-1",
        "a client that stops acking fails its own attempt within 10 s with the reason, the attempt beside it keeps its verdicts, and a new client serves later attempts",
    ) {
        val frozenAt = TimeSource.Monotonic.markNow()

        val lost = freezeClient(player) { shouldThrow<ClientLost> { within(10.ticks) { player sees chat("Goodbye") } } }

        frozenAt.elapsedNow() shouldBeLessThan 10.seconds
        lost.report shouldContain "${player.name}'s client was lost: it acked no tick for 5 s"
    }
}
