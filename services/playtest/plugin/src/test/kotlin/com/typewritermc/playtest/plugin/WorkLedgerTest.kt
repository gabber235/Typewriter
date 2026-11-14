package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import java.util.UUID

val WorkLedgerTest by testSuite {
    val player = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val partner = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("work begun between ticks lets the next tick start and holds the one after until it ends") {
        val work = WorkLedger { 0L }
        work.tickEnded(10)

        val lookup = work.begin(player, "gv-1", "Ledger lookup")

        work.holds(listOf(player), 11) shouldBe false
        work.tickStarted(11)
        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe true
        lookup.end()
        work.holds(listOf(player), 12) shouldBe false
    }

    test("work begun during a tick lets the tick after it start, whose heartbeat starts a Bukkit async task") {
        val work = WorkLedger { 0L }
        work.tickEnded(10)
        work.tickStarted(11)

        work.begin(player, "gv-1", "Ledger lookup")

        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe false
        work.tickStarted(12)
        work.tickEnded(12)
        work.holds(listOf(player), 13) shouldBe true
    }

    test("a player's work holds the ticks of no other player") {
        val work = WorkLedger { 0L }
        work.tickEnded(10)
        work.begin(partner, "gv-2", "Ledger lookup")
        work.tickStarted(11)
        work.tickEnded(11)

        work.holds(listOf(player), 12) shouldBe false
        work.quiet(listOf(player)) shouldBe true
        work.holds(listOf(player, partner), 12) shouldBe true
        work.quiet(listOf(player, partner)) shouldBe false
    }

    test("a player is quiet only once every piece of its work ended, even work that holds no tick yet") {
        val work = WorkLedger { 0L }
        work.tickEnded(10)

        val lookup = work.begin(player, "gv-1", "Ledger lookup")
        val save = work.begin(player, "gv-1", "Ledger save")

        work.quiet(listOf(player)) shouldBe false
        lookup.end()
        lookup.end()
        work.quiet(listOf(player)) shouldBe false
        save.end()
        work.quiet(listOf(player)) shouldBe true
    }

    test("work still running 1 s after it began is reported once as hung, then holds no tick") {
        var now = 0L
        val work = WorkLedger { now }
        work.tickEnded(10)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")
        work.tickStarted(11)
        work.tickEnded(11)

        now = WorkLedger.HUNG_NANOS - 1
        work.hung().shouldBeEmpty()
        work.holds(listOf(player), 12) shouldBe true

        now = WorkLedger.HUNG_NANOS
        work.hung() shouldContainExactly listOf(WorkLedger.Hung(player, "gv-1", "Ledger lookup", 10))
        work.hung().shouldBeEmpty()
        work.holds(listOf(player), 12) shouldBe false
        work.quiet(listOf(player)) shouldBe true
        lookup.end()
        work.hung().shouldBeEmpty()
    }

    test("work that ended before its limit is never reported as hung") {
        var now = 0L
        val work = WorkLedger { now }
        work.tickEnded(10)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")

        now = WorkLedger.HUNG_NANOS - 1
        lookup.end()
        now = 5 * WorkLedger.HUNG_NANOS

        work.hung().shouldBeEmpty()
    }

    test("hung work that ends later is reported once as ended, so its player can come back") {
        var now = 0L
        val work = WorkLedger { now }
        work.tickEnded(10)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")
        now = WorkLedger.HUNG_NANOS
        work.hung()
        work.ended().shouldBeEmpty()

        lookup.end()

        work.ended() shouldContainExactly listOf(WorkLedger.Hung(player, "gv-1", "Ledger lookup", 10))
        work.ended().shouldBeEmpty()
    }

    test("work that ends before its limit is never reported as ended hung work") {
        var now = 0L
        val work = WorkLedger { now }
        val lookup = work.begin(player, "gv-1", "Ledger lookup")

        lookup.end()
        now = WorkLedger.HUNG_NANOS

        work.hung().shouldBeEmpty()
        work.ended().shouldBeEmpty()
    }
}
