package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import java.util.UUID

val AcksTest by testSuite {
    val player = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val partner = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("a client that acks nothing for 5 s after a tick ended stalls, reported once") {
        var now = 0L
        val acks = Acks { now }
        acks.acked(player, 10)
        acks.tickEnded(11)

        now = Acks.STALL_NANOS - 1
        acks.stalled().shouldBeEmpty()
        now = Acks.STALL_NANOS

        acks.stalled() shouldContainExactly listOf(Acks.Stalled(player, 10))
        acks.stalled().shouldBeEmpty()
        acks.lastAcked(player) shouldBe -1
    }

    test("an ack that still lags behind starts the 5 s again") {
        var now = 0L
        val acks = Acks { now }
        acks.acked(player, 10)
        acks.tickEnded(11)
        acks.tickEnded(12)

        now = 3_000_000_000L
        acks.acked(player, 11)
        now = 3_000_000_000L + Acks.STALL_NANOS - 1
        acks.stalled().shouldBeEmpty()
        now = 3_000_000_000L + Acks.STALL_NANOS

        acks.stalled() shouldContainExactly listOf(Acks.Stalled(player, 11))
    }

    test("a client that acked the last tick never stalls, however long no tick runs") {
        var now = 0L
        val acks = Acks { now }
        acks.acked(player, 10)
        acks.tickEnded(11)
        acks.acked(player, 11)

        now = 60 * Acks.STALL_NANOS

        acks.stalled().shouldBeEmpty()
    }

    test("a client that never acked, still loading its world, is not watched") {
        var now = 0L
        val acks = Acks { now }
        acks.acked(partner, 10)
        acks.tickEnded(11)
        acks.acked(partner, 11)

        now = 60 * Acks.STALL_NANOS

        acks.stalled().shouldBeEmpty()
    }

    test("a client whose player left is not watched") {
        var now = 0L
        val acks = Acks { now }
        acks.acked(player, 10)
        acks.tickEnded(11)

        acks.lose(player)
        now = 60 * Acks.STALL_NANOS

        acks.stalled().shouldBeEmpty()
    }
}
