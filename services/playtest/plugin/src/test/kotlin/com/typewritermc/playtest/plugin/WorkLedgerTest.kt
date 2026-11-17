package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import java.util.UUID

val WorkLedgerTest by testSuite {
    val player = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val partner = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("work that already runs, begun between ticks, holds the next tick until it ends") {
        val work = WorkLedger({ 0L }) { _, _ -> }
        work.tickEnded(10)

        val chat = work.begin(player, "gv-1", "chat")

        work.holds(listOf(player), 11) shouldBe true
        chat.end()
        work.holds(listOf(player), 11) shouldBe false
    }

    test("work that already runs, begun during a tick, holds the tick after it until it ends") {
        val work = WorkLedger({ 0L }) { _, _ -> }
        work.tickEnded(10)
        work.tickStarted(11)

        work.begin(player, "gv-1", "chat")

        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe true
    }

    test("a scheduled task begun between ticks lets the next tick start, whose heartbeat starts it, and holds the one after") {
        val work = WorkLedger({ 0L }) { _, _ -> }
        work.tickEnded(10)

        val lookup = work.schedule(player, "gv-1", "Ledger lookup")

        work.holds(listOf(player), 11) shouldBe false
        work.tickStarted(11)
        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe true
        lookup.end()
        work.holds(listOf(player), 12) shouldBe false
    }

    test("a scheduled task begun during a tick lets the tick after it start, whose heartbeat starts it") {
        val work = WorkLedger({ 0L }) { _, _ -> }
        work.tickEnded(10)
        work.tickStarted(11)

        work.schedule(player, "gv-1", "Ledger lookup")

        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe false
        work.tickStarted(12)
        work.tickEnded(12)
        work.holds(listOf(player), 13) shouldBe true
    }

    test("a player's work holds the ticks of no other player") {
        val work = WorkLedger({ 0L }) { _, _ -> }
        work.tickEnded(10)
        work.begin(partner, "gv-2", "Ledger lookup")
        work.tickStarted(11)
        work.tickEnded(11)

        work.holds(listOf(player), 12) shouldBe false
        work.quiet(listOf(player)) shouldBe true
        work.holds(listOf(player, partner), 12) shouldBe true
        work.quiet(listOf(player, partner)) shouldBe false
    }

    test("a player is quiet only once every piece of its work ended, even a task that holds no tick yet") {
        val work = WorkLedger({ 0L }) { _, _ -> }
        work.tickEnded(10)

        val lookup = work.schedule(player, "gv-1", "Ledger lookup")
        val save = work.schedule(player, "gv-1", "Ledger save")

        work.quiet(listOf(player)) shouldBe false
        lookup.end()
        lookup.end()
        work.quiet(listOf(player)) shouldBe false
        save.end()
        work.quiet(listOf(player)) shouldBe true
    }

    test("work still running at its 1 s deadline is reported hung by the deadline, before it ends, with no check between ticks") {
        val deadlines = mutableListOf<Pair<Long, Runnable>>()
        val reports = mutableListOf<String>()
        val work = WorkLedger({ 0L }) { after, task -> deadlines += after to task }
        work.reportHungTo { reports += "hung ${it.name}" }
        work.tickEnded(10)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")
        work.tickStarted(11)
        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe true

        deadlines.map { it.first } shouldContainExactly listOf(WorkLedger.HUNG_NANOS)
        deadlines.single().second.run()
        reports += "ended"
        lookup.end()

        reports shouldContainExactly listOf("hung Ledger lookup", "ended")
        work.holds(listOf(player), 12) shouldBe false
        work.quiet(listOf(player)) shouldBe true
        work.ended() shouldContainExactly listOf(WorkLedger.Hung(player, "gv-1", "Ledger lookup", 10))
        work.ended().shouldBeEmpty()
    }

    test("work that ends before its deadline is never reported as hung or as ended hung work") {
        val deadlines = mutableListOf<Runnable>()
        val reports = mutableListOf<WorkLedger.Hung>()
        val work = WorkLedger({ WorkLedger.HUNG_NANOS - 1 }) { _, task -> deadlines += task }
        work.reportHungTo(reports::add)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")

        lookup.end()
        deadlines.forEach(Runnable::run)

        reports.shouldBeEmpty()
        work.ended().shouldBeEmpty()
    }

    test("work that ended past its limit before its late deadline ran is reported hung once when it ends, then as ended") {
        var now = 0L
        val deadlines = mutableListOf<Runnable>()
        val reports = mutableListOf<WorkLedger.Hung>()
        val work = WorkLedger({ now }) { _, task -> deadlines += task }
        work.reportHungTo(reports::add)
        work.tickEnded(10)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")

        now = WorkLedger.HUNG_NANOS + 500_000_000L
        lookup.end()
        deadlines.forEach(Runnable::run)

        val report = WorkLedger.Hung(player, "gv-1", "Ledger lookup", 10)
        reports shouldContainExactly listOf(report)
        work.ended() shouldContainExactly listOf(report)
        work.ended().shouldBeEmpty()
        work.quiet(listOf(player)) shouldBe true
    }

    test("hung work that ends later is reported once as ended, so its player can come back") {
        val deadlines = mutableListOf<Runnable>()
        val work = WorkLedger({ 0L }) { _, task -> deadlines += task }
        work.tickEnded(10)
        val lookup = work.begin(player, "gv-1", "Ledger lookup")
        deadlines.forEach(Runnable::run)
        work.ended().shouldBeEmpty()

        lookup.end()

        work.ended() shouldContainExactly listOf(WorkLedger.Hung(player, "gv-1", "Ledger lookup", 10))
        work.ended().shouldBeEmpty()
    }
}
