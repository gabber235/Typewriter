package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe

val LifetimeTest by testSuite {
    test("a pool that no session of its run reached stops once its owner had the time to open one") {
        val lifetime = Lifetime<String>(startedAt = 1_000, ownerMillis = 60_000)

        lifetime.over(60_999) shouldBe false
        lifetime.wakeAt() shouldBe 61_000
        lifetime.over(61_000) shouldBe true
    }

    test("a pool runs while any session of its run is connected, however long, and stops once the last one left") {
        val lifetime = Lifetime<String>(startedAt = 1_000, ownerMillis = 60_000)
        lifetime.joined("module")
        lifetime.joined("sibling")

        lifetime.left("module")

        lifetime.over(1_000_000) shouldBe false
        lifetime.wakeAt().shouldBeNull()
        lifetime.left("sibling")
        lifetime.over(1_001) shouldBe true
    }
}
