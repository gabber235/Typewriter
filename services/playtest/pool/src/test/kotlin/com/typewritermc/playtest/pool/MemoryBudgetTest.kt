package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

val MemoryBudgetTest by testSuite {
    val gib = 1024L * 1024 * 1024

    test(
        "the pool runs as many own Papers at once as fit in its memory beside itself, the shared Paper and each client, at most one per slot",
    ) {
        data class Row(
            val budget: Long,
            val clients: Int,
            val displays: Boolean,
            val ownPapers: Int,
        )
        val table =
            listOf(
                Row(16 * gib, 4, displays = true, ownPapers = 1),
                Row(16 * gib, 4, displays = false, ownPapers = 2),
                Row(20 * gib, 4, displays = true, ownPapers = 2),
                Row(14 * gib, 4, displays = true, ownPapers = 0),
            )
        for (row in table) {
            withClue(row) { MemoryBudget(row.budget, "the test's").ownPapers(row.clients, row.displays) shouldBe row.ownPapers }
        }
    }

    test("a pool whose memory holds no own Paper beside its other parts says how many clients would fit") {
        val reason = MemoryBudget(14 * gib, "half the machine").overBudget(4, displays = true).shouldNotBeNull()

        reason shouldBe
            "4 clients with their displays, the shared Paper and the pool take 13.6 GiB of the pool's 14.0 GiB (half the machine), " +
            "leaving no room for an own Paper of 1.6 GiB; run at most 3 clients (cargo xtask e2e game --clients 3)"
        MemoryBudget(16 * gib, "half the machine").overBudget(4, displays = true) shouldBe null
    }
}
