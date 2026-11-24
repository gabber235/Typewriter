package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.util.UUID

val StepPolicyTest by testSuite {
    val claimed = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val free = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("a free player's client behind the last tick holds back the next tick until it acks it") {
        var granted = 0
        val policy = policy({ granted++ })
        policy.claim(listOf(claimed))
        policy.acked(claimed, 9, false)
        policy.acked(free, 9, false)
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.stepUntil(claimed, 20, 1)

        policy.run()
        granted shouldBe 0

        policy.acked(free, 10, false)
        policy.run()
        granted shouldBe 1
    }

    test("a client that never acked a tick, still joining, holds back no tick") {
        var granted = 0
        val policy = policy({ granted++ })
        policy.claim(listOf(claimed))
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.stepUntil(claimed, 20, 1)

        policy.run()

        granted shouldBe 1
    }

    test("a free player's client that stalls for 5 s counts as lost and holds back no tick from then on") {
        var now = 0L
        var granted = 0
        val stalled = mutableListOf<UUID>()
        val policy = policy({ granted++ }, clock = { now }, reportStalled = { stalled += it })
        policy.claim(listOf(claimed))
        policy.acked(claimed, 9, false)
        policy.acked(free, 9, false)
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.stepUntil(claimed, 20, 1)
        policy.run()

        now = Acks.STALL_NANOS
        policy.run()

        stalled shouldBe listOf(free)
        granted shouldBe 1
    }

    test("a client whose connection closed holds back no tick, though Paper notices its player leave only in a tick") {
        var granted = 0
        val closed = mutableSetOf<UUID>()
        val policy = policy({ granted++ }, connected = { it !in closed })
        policy.claim(listOf(claimed))
        policy.acked(claimed, 9, false)
        policy.acked(free, 9, false)
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.stepUntil(claimed, 20, 1)

        closed += free
        policy.run()

        granted shouldBe 1
    }

    test("at a pace, a tick a window waits for is granted no sooner than the pace after the tick before it") {
        var now = 0L
        var granted = 0
        val policy = policy({ granted++ }, clock = { now })
        policy.claim(listOf(claimed))
        policy.pace(50)
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.stepUntil(claimed, 20, 1)
        policy.run()
        granted shouldBe 1
        policy.tickEnded(11)
        policy.acked(claimed, 11, false)

        now = 49_000_000L
        policy.run()
        granted shouldBe 1

        now = 50_000_000L
        policy.run()
        granted shouldBe 2

        policy.pace(0)
        policy.tickEnded(12)
        policy.acked(claimed, 12, false)
        policy.run()
        granted shouldBe 3
    }

    test("a delivery ends with the tick after which its client holds everything sent, however many ticks it took") {
        var granted = 0
        val ended = mutableListOf<Int>()
        val policy = policy({ granted++ })
        policy.claim(listOf(claimed))
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.deliver(listOf(claimed)) { tick -> ended += tick }

        // Tick 11 ends with nothing left to send, so the step ping of tick 12 goes out after it all.
        for (tick in 11..12) {
            policy.run()
            policy.tickEnded(tick)
            policy.acked(claimed, tick, false)
        }
        ended shouldBe listOf()
        policy.run()

        ended shouldBe listOf(12)
        granted shouldBe 2
    }
}

/**
 * A step policy whose granted ticks run [grantTick], with nothing left to send, every main thread task
 * run at once and no counted work; [clock] is its wall clock, [reportStalled] hears each stalled client
 * and [connected] says whose connection is open.
 */
private fun policy(
    grantTick: () -> Unit,
    clock: () -> Long = { 0L },
    reportStalled: (UUID) -> Unit = {},
    connected: (UUID) -> Boolean = { true },
) = StepPolicy(
    { false },
    grantTick,
    { _, _ -> },
    { true },
    { it.run() },
    WorkLedger { _, _ -> },
    {},
    Acks { clock() },
    { reportStalled(it.player()) },
    connected,
    { clock() },
)
