package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.util.UUID

val StepPolicyTest by testSuite {
    val claimed = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val free = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("a free player's client behind the last tick holds back the next tick until it acks it") {
        var granted = 0
        val policy =
            StepPolicy({ false }, { granted++ }, { _, _ -> }, { true }, { it.run() }, WorkLedger { _, _ -> }, {}, Acks { 0L }, {})
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
        val policy =
            StepPolicy({ false }, { granted++ }, { _, _ -> }, { true }, { it.run() }, WorkLedger { _, _ -> }, {}, Acks { 0L }, {})
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
        val policy =
            StepPolicy(
                { false },
                { granted++ },
                { _, _ -> },
                { true },
                { it.run() },
                WorkLedger { _, _ -> },
                {},
                Acks { now },
                { stalled += it.player() },
            )
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
}
