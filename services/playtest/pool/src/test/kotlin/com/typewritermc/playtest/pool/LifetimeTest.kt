package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe

val LifetimeTest by testSuite {
    test("a pool that no session of its run reached stops once its owner had the time to open one") {
        val lifetime = Lifetime<String>(startedAt = 1_000, ownerMillis = 60_000, graceMillis = 60_000)

        lifetime.over(60_999) shouldBe false
        lifetime.wakeAt() shouldBe 61_000
        lifetime.over(61_000) shouldBe true
    }

    test("a pool runs while any session of its run is connected, however long, and stops once the last one left a grace ago") {
        val lifetime = Lifetime<String>(startedAt = 1_000, ownerMillis = 60_000, graceMillis = 60_000)
        lifetime.joined("module")
        lifetime.joined("sibling")

        lifetime.left("module", at = 2_000)

        lifetime.over(1_000_000) shouldBe false
        lifetime.wakeAt().shouldBeNull()
        lifetime.left("sibling", at = 10_000)
        lifetime.over(69_999) shouldBe false
        lifetime.wakeAt() shouldBe 70_000
        lifetime.over(70_000) shouldBe true
    }

    test("a session of the run that comes within the grace keeps the pool for itself, as a module whose tests start later") {
        val lifetime = Lifetime<String>(startedAt = 1_000, ownerMillis = 60_000, graceMillis = 60_000)
        lifetime.joined("module")
        lifetime.left("module", at = 10_000)

        lifetime.joined("sibling")

        lifetime.over(1_000_000) shouldBe false
        lifetime.wakeAt().shouldBeNull()
        lifetime.left("sibling", at = 200_000)
        lifetime.wakeAt() shouldBe 260_000
    }
}
