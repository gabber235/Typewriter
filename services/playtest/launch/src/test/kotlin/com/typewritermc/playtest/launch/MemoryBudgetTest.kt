package com.typewritermc.playtest.launch

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.longs.shouldBeLessThanOrEqual
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

/** The memory CI's 4x16 game runner reports (MemTotal, run 45115703169's kernel log). */
private const val CI_RUNNER_MIB = 16_053L

val MemoryBudgetTest by testSuite {
    test("the CI runner runs one restart Paper at a time beside the shared Paper and the default 4 clients") {
        val budget = MemoryBudget(CI_RUNNER_MIB, 4)

        budget.ownPapers() shouldBe 1
        budget.refusal().shouldBeNull()
    }

    test("a machine of twice the memory runs more restart Papers at once, up to the slots the build sets up") {
        MemoryBudget(2 * CI_RUNNER_MIB, 4).ownPapers() shouldBeGreaterThan 1
        MemoryBudget(16 * CI_RUNNER_MIB, 4).ownPapers() shouldBe MemoryBudget.OWN_PAPER_SLOTS
    }

    test("every part that can run at once fits in the machine beside the reserve, at any size") {
        for (machine in 12_000L..200_000L step 997) {
            val budget = MemoryBudget(machine, 4)
            if (budget.refusal() != null) continue

            budget.residentMib(budget.ownPapers()) shouldBeLessThanOrEqual machine - MemoryBudget.RESERVE_MIB
        }
    }

    test("a pool of more clients than leave room for one restart Paper refuses, naming how many fit") {
        val reason = MemoryBudget(CI_RUNNER_MIB, 6).refusal().shouldNotBeNull()

        reason shouldContain "6 clients"
        reason shouldContain "run at most 4 clients (cargo xtask e2e game --clients 4)"
    }

    test("a machine too small for even one client and a restart Paper refuses, saying so") {
        val reason = MemoryBudget(8_192, 1).refusal().shouldNotBeNull()

        reason shouldContain "8192 MiB"
        reason shouldContain "too small"
    }
}
