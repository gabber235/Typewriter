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
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)

        val chat = work.begin(setOf(player), "chat")

        work.holds(listOf(player), 11) shouldBe true
        chat.end()
        work.holds(listOf(player), 11) shouldBe false
    }

    test("work that already runs, begun during a tick, holds the tick after it until it ends") {
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)
        work.tickStarted(11)

        work.begin(setOf(player), "chat")

        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe true
    }

    test("a scheduled task begun between ticks lets the next tick start, whose heartbeat starts it, and holds the one after") {
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)

        val lookup = work.schedule(setOf(player), "Ledger lookup")

        work.holds(listOf(player), 11) shouldBe false
        work.tickStarted(11)
        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe true
        lookup.end()
        work.holds(listOf(player), 12) shouldBe false
    }

    test("a scheduled task begun during a tick lets the tick after it start, whose heartbeat starts it") {
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)
        work.tickStarted(11)

        work.schedule(setOf(player), "Ledger lookup")

        work.tickEnded(11)
        work.holds(listOf(player), 12) shouldBe false
        work.tickStarted(12)
        work.tickEnded(12)
        work.holds(listOf(player), 13) shouldBe true
    }

    test("a player's work holds the ticks of no other player") {
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)
        work.begin(setOf(partner), "Ledger lookup")
        work.tickStarted(11)
        work.tickEnded(11)

        work.holds(listOf(player), 12) shouldBe false
        work.quiet(listOf(player)) shouldBe true
        work.holds(listOf(player, partner), 12) shouldBe true
        work.quiet(listOf(player, partner)) shouldBe false
    }

    test("a player is quiet only once every piece of its work ended, even a task that holds no tick yet") {
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)

        val lookup = work.schedule(setOf(player), "Ledger lookup")
        val save = work.schedule(setOf(player), "Ledger save")

        work.quiet(listOf(player)) shouldBe false
        lookup.end()
        lookup.end()
        work.quiet(listOf(player)) shouldBe false
        save.end()
        work.quiet(listOf(player)) shouldBe true
    }

    test("work still running at its 1 s deadline is reported hung then, with no check between ticks") {
        val watch = ManualWatch()
        val reports = mutableListOf<WorkLedger.Hung>()
        val work = WorkLedger(watch)
        work.reportHungTo(reports::add)
        work.tickEnded(10)
        work.begin(setOf(player), "Ledger lookup")

        watch.advance(WorkLedger.HUNG_NANOS - 1)
        reports.shouldBeEmpty()
        watch.advance(1)

        reports shouldContainExactly listOf(WorkLedger.Hung(setOf(player), "Ledger lookup", 10))
    }

    test("one watchdog watches all open work: a single alarm, at the deadline of the oldest") {
        val watch = ManualWatch()
        val work = WorkLedger(watch)

        work.begin(setOf(player), "Ledger lookup")
        watch.advance(200_000_000L)
        work.begin(setOf(player), "Ledger save")
        watch.advance(300_000_000L)
        work.schedule(setOf(partner), "Profile save")

        watch.pending shouldContainExactly listOf(WorkLedger.HUNG_NANOS)
    }

    test("the watchdog passes over work that ended before it woke and wakes again at the deadline of the oldest still open") {
        val watch = ManualWatch()
        val reports = mutableListOf<WorkLedger.Hung>()
        val work = WorkLedger(watch)
        work.reportHungTo(reports::add)
        work.tickEnded(10)
        val lookup = work.begin(setOf(player), "Ledger lookup")
        watch.advance(400_000_000L)
        work.begin(setOf(player), "Ledger save")
        lookup.end()

        watch.advance(600_000_000L)
        reports.shouldBeEmpty()
        watch.pending shouldContainExactly listOf(WorkLedger.HUNG_NANOS + 400_000_000L)
        watch.advance(400_000_000L)

        reports shouldContainExactly listOf(WorkLedger.Hung(setOf(player), "Ledger save", 10))
        watch.pending.shouldBeEmpty()
    }

    test("hung work holds no tick from its deadline on") {
        val watch = ManualWatch()
        val work = WorkLedger(watch)
        work.tickEnded(10)
        work.begin(setOf(player), "Ledger lookup")
        work.holds(listOf(player), 11) shouldBe true

        watch.advance(WorkLedger.HUNG_NANOS)

        work.holds(listOf(player), 11) shouldBe false
    }

    test("hung work leaves its player quiet, so its attempt can settle") {
        val watch = ManualWatch()
        val work = WorkLedger(watch)
        work.begin(setOf(player), "Ledger lookup")
        work.quiet(listOf(player)) shouldBe false

        watch.advance(WorkLedger.HUNG_NANOS)

        work.quiet(listOf(player)) shouldBe true
    }

    test("only the deadline decides hung: work that ends before its deadline runs is never reported, however long it ran") {
        val watch = ManualWatch()
        val reports = mutableListOf<WorkLedger.Hung>()
        val work = WorkLedger(watch)
        work.reportHungTo(reports::add)
        val lookup = work.begin(setOf(player), "Ledger lookup")

        lookup.end()
        watch.advance(WorkLedger.HUNG_NANOS)

        reports.shouldBeEmpty()
        work.ended().shouldBeEmpty()
    }

    test("hung work that ends later is reported once as ended, so its player can come back") {
        val watch = ManualWatch()
        val work = WorkLedger(watch)
        work.tickEnded(10)
        val lookup = work.begin(setOf(player), "Ledger lookup")
        watch.advance(WorkLedger.HUNG_NANOS)
        work.ended().shouldBeEmpty()

        lookup.end()

        work.ended() shouldContainExactly listOf(WorkLedger.Hung(setOf(player), "Ledger lookup", 10))
        work.ended().shouldBeEmpty()
    }

    test("hung work that ends while its hang is still being reported is reported ended only after the hang went out") {
        val watch = ManualWatch()
        val endedWhileReporting = mutableListOf<List<WorkLedger.Hung>>()
        val work = WorkLedger(watch)
        work.tickEnded(10)
        val lookup = work.begin(setOf(player), "Ledger lookup")
        work.reportHungTo {
            lookup.end()
            endedWhileReporting += work.ended()
        }

        watch.advance(WorkLedger.HUNG_NANOS)

        endedWhileReporting shouldContainExactly listOf(emptyList())
        work.ended() shouldContainExactly listOf(WorkLedger.Hung(setOf(player), "Ledger lookup", 10))
    }

    test("work for no player holds the next tick while any player is claimed, and no tick while none is") {
        val work = WorkLedger(ManualWatch())
        work.tickEnded(10)

        val apply = work.begin(null, "content apply")

        work.holds(listOf(player), 11) shouldBe true
        work.holds(emptyList(), 11) shouldBe false
        work.quiet(listOf(partner)) shouldBe false
        apply.end()
        work.holds(listOf(player), 11) shouldBe false
        work.quiet(listOf(partner)) shouldBe true
    }

    test("work that fails is reported once, then, with its cause, and holds no tick from then on") {
        val failures = mutableListOf<WorkLedger.Failed>()
        val work = WorkLedger(ManualWatch())
        work.reportFailedTo(failures::add)
        work.tickEnded(10)
        val take = work.begin(setOf(player), "kv create sessions minecraft.1")

        take.failed("the broker is unreachable")
        take.failed("again")
        take.end()

        failures shouldContainExactly
            listOf(WorkLedger.Failed(setOf(player), "kv create sessions minecraft.1", 10, "the broker is unreachable"))
        work.holds(listOf(player), 11) shouldBe false
        work.quiet(listOf(player)) shouldBe true
    }

    test("hung work that fails later ends as hung work does, without a second report") {
        val watch = ManualWatch()
        val failures = mutableListOf<WorkLedger.Failed>()
        val work = WorkLedger(watch)
        work.reportFailedTo(failures::add)
        work.tickEnded(10)
        val take = work.begin(setOf(player), "kv create sessions minecraft.1")
        watch.advance(WorkLedger.HUNG_NANOS)

        take.failed("timed out")

        failures.shouldBeEmpty()
        work.ended() shouldContainExactly listOf(WorkLedger.Hung(setOf(player), "kv create sessions minecraft.1", 10))
    }

    test("work for no player that hangs or fails is reported for the players claimed at that moment") {
        val watch = ManualWatch()
        val hung = mutableListOf<WorkLedger.Hung>()
        val failed = mutableListOf<WorkLedger.Failed>()
        val work = WorkLedger(watch)
        work.reportHungTo(hung::add)
        work.reportFailedTo(failed::add)
        work.tickEnded(10)
        work.begin(null, "content apply")
        val publish = work.begin(null, "publish realm.events")

        work.claimed(setOf(player, partner))
        publish.failed("no responders")
        work.claimed(setOf(player))
        watch.advance(WorkLedger.HUNG_NANOS)

        failed shouldContainExactly listOf(WorkLedger.Failed(setOf(player, partner), "publish realm.events", 10, "no responders"))
        hung shouldContainExactly listOf(WorkLedger.Hung(setOf(player), "content apply", 10))
    }
}
