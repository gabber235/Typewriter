package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

val MemoryBudgetTest by testSuite {
    val mib = 1024L * 1024

    test(
        "own Papers wait for the room the pool, the shared Paper and each client with its display leave in the budget, " +
            "at most one per slot the build prepares",
    ) {
        data class Row(
            val budgetMib: Long,
            val clients: Int,
            val displays: Boolean,
            val ownPapers: Int,
        )
        // The parts that run the whole run take 3904 MiB for the shared Paper, 812 for the pool and 1775 per
        // client with 64 for its display: 10233 MiB for 3 clients with displays. An own Paper takes 2393 MiB.
        val table =
            listOf(
                // The playtest suite on the CI runner: the machine less the system and Gradle's test run.
                Row(13_237, 3, displays = true, ownPapers = 1),
                // The game suite on the CI runner, less the stack too: room for no own Paper.
                Row(10_748, 3, displays = true, ownPapers = 0),
                Row(15_600, 3, displays = true, ownPapers = 2),
                Row(15_600, 3, displays = false, ownPapers = 2),
                Row(40_000, 3, displays = true, ownPapers = 2),
            )
        for (row in table) {
            withClue(row) {
                MemoryBudget(row.budgetMib * mib, "the test's").ownPaperRoom(row.clients, row.displays).most shouldBe
                    row.ownPapers
            }
        }
    }

    test(
        "a pool whose parts that run the whole run alone take more than the budget is refused, naming the numbers and the clients that fit",
    ) {
        val reason = MemoryBudget(10_000 * mib, "the game's cgroup").overBudget(3, displays = true).shouldNotBeNull()

        reason shouldBe
            "3 clients with their displays, the shared Paper and the pool take 10.0 GiB " +
            "of the game's 9.8 GiB budget (the game's cgroup); run at most 2 clients (cargo xtask e2e game --clients 2)"
    }

    test("a pool whose parts that run the whole run fit runs, also where no own Paper fits beside them") {
        MemoryBudget(10_748 * mib, "the game's cgroup").overBudget(3, displays = true) shouldBe null
    }
}
