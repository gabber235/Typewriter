package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.util.UUID

val StepPolicyTest by testSuite {
    val claimed = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val free = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("a free player's client behind the last tick holds back the next tick until it acks it") {
        var granted = 0
        val policy = stepPolicy({ granted++ })
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
        val policy = stepPolicy({ granted++ })
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
        val policy = stepPolicy({ granted++ }, acks = Acks { now }, stalled = { stalled += it.player() })
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
        val policy = stepPolicy({ granted++ }, connected = { it !in closed })
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

    test("a claimed player who left keeps its counted work holding the next tick until its attempt is released") {
        var granted = 0
        val work = WorkLedger(ManualWatch())
        val policy = stepPolicy({ granted++ }, work = work)
        policy.claim(listOf(claimed))
        policy.tickEnded(10)
        work.tickEnded(10)
        policy.lose(claimed)

        work.begin(setOf(claimed), "session take")
        policy.run()
        granted shouldBe 0

        policy.release(listOf(claimed))
        policy.run()
        granted shouldBe 1
    }
}
