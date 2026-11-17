package com.typewritermc.playtest.wire

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.doubles.shouldBeLessThanOrEqual

val HeapShareTest by testSuite {
    test("the heaps of the game parts that can run at once fit in half the machine") {
        HeapShare.concurrent() shouldBeLessThanOrEqual HeapShare.CONCURRENT_LIMIT
    }
}
