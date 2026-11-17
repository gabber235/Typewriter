package com.typewritermc.playtest.wire

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.doubles.shouldBeLessThanOrEqual
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

val HeapShareTest by testSuite {
    test("the heaps of the game parts that can run at once fit in half the machine with the default 4 clients") {
        HeapShare.concurrent(4) shouldBeLessThanOrEqual HeapShare.CONCURRENT_LIMIT
        HeapShare.overLimit(4) shouldBe null
    }

    test("each client beyond the default adds its share, and a pool of more clients than fit says so") {
        HeapShare.concurrent(6) shouldBe HeapShare.concurrent(4) + 2 * HeapShare.CLIENT.percent

        val reason = HeapShare.overLimit(5).shouldNotBeNull()

        reason shouldContain "5 clients"
        reason shouldContain "54.5%"
        reason shouldContain "at most 4 clients"
    }
}
