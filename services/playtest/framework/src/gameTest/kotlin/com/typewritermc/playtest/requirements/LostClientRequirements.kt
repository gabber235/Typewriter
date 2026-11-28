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
import io.kotest.matchers.collections.shouldBeIn
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.LossCause
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

val LostClientRequirements by testSuite(compartment = { GameCompartment }) {
    clientLostAlongside(
        "LOST-1",
        "a client that crashes fails its own attempt with the reason, the attempt beside it keeps its verdicts, and a new client serves later attempts",
    ) {
        crashClient(player)

        val lost = shouldThrow<ClientLost> { within(10.ticks) { player sees chat("Goodbye") } }

        // The crash shows first as the process's exit, the pool connection closing or Paper seeing the player leave.
        lost.loss.kind shouldBeIn listOf(LossCause.Kind.EXITED_WRAPPER, LossCause.Kind.LEFT_WRAPPER, LossCause.Kind.LEFT_PAPER_WRAPPER)
    }

    clientLostAlongside(
        "FROZEN-1",
        "a client that stops acking fails its own attempt within 15 s with the reason, the attempt beside it keeps its verdicts, and a new client serves later attempts",
    ) {
        val frozenAt = TimeSource.Monotonic.markNow()

        val lost = freezeClient(player) { shouldThrow<ClientLost> { within(10.ticks) { player sees chat("Goodbye") } } }

        // Paper's acks find the client stalled after 5 s without an ack and the pool replaces it; 15 s leaves
        // room for a loaded machine.
        frozenAt.elapsedNow() shouldBeLessThan 15.seconds
        lost.loss shouldBe LossCause.STALLED
    }
}
