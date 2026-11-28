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

    test("a window reading state between its ticks lets no tick run on its Paper, idle or for another window, until it stops") {
        var granted = 0
        val policy = stepPolicy({ granted++ })
        policy.claim(listOf(claimed, free))
        policy.tickEnded(10)
        policy.acked(claimed, 10, false)
        policy.acked(free, 10, false)
        policy.stepUntil(claimed, 11, 1)
        policy.run()
        policy.tickEnded(11)
        policy.acked(claimed, 11, false)
        policy.acked(free, 11, false)
        // Tick 11's barrier goes out; the window now reads its state checks before it asks for tick 12.
        policy.run()

        policy.run()
        policy.stepUntil(free, 20, 2)
        policy.run()
        granted shouldBe 1

        policy.stop(claimed)
        policy.run()
        granted shouldBe 2
    }

    test("each player of a window whose tick already ran gets its barrier at once, though another player of it took its own first") {
        val barriers = mutableListOf<Pair<UUID, Int>>()
        val policy = stepPolicy({}, barrier = { player, id -> barriers += player to id })
        policy.claim(listOf(claimed, free))
        policy.tickEnded(13)
        policy.acked(claimed, 13, false)
        policy.acked(free, 13, false)

        policy.stepUntil(claimed, 11, 3)
        policy.run()
        policy.stepUntil(free, 11, 4)
        policy.run()

        barriers shouldBe listOf(claimed to 3, free to 4)
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
