package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import skirout.harness.v1.wire.PaperLossKind

val OwnPaperTest by testSuite {
    test("the attempt stands at the spawn, its players join only once their Paper is up, and it steps once all of them joined") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1", "gv-2"))

        paper.claim(1) shouldBe PaperRules.Claiming(OwnPaper.REGION, listOf(Do.Boot(1)))
        paper.connected() shouldContainExactly listOf(Do.RegionsAhead(listOf(OwnPaper.REGION)), Do.Gather(1), Do.Connect)
        paper.joined("gv-1").shouldBeEmpty()
        paper.joined("gv-2") shouldContainExactly listOf(Do.Step)
    }

    test("the first time every player steps with the Paper, the attempt claims them") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1", "gv-2"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.joined("gv-2")

        paper.ready("gv-1").shouldBeEmpty()
        paper.ready("gv-2") shouldContainExactly listOf(Do.Claim(1))
    }

    test("a restart kills the Paper, boots it again and answers once every player is back, resumed unwiped") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.restart(7) shouldContainExactly listOf(Do.Kill(1))
        paper.exited(137) shouldContainExactly listOf(Do.Boot(2))
        paper.connected() shouldContainExactly listOf(Do.RegionsAhead(listOf(OwnPaper.REGION)), Do.Gather(1), Do.Connect)
        paper.joined("gv-1") shouldContainExactly listOf(Do.Step)
        paper.ready("gv-1") shouldContainExactly listOf(Do.Forget("gv-1"), Do.Resume(1))
        paper.resumed(41) shouldContainExactly listOf(Do.Restarted(1, 7, 41))
    }

    test("what a client recorded until it steps with the Paper booted again shows the killed one and is forgotten") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1", "gv-2"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.joined("gv-2")
        paper.ready("gv-1")
        paper.ready("gv-2")
        paper.restart(7)
        paper.exited(137)
        paper.connected()
        paper.joined("gv-1")
        paper.joined("gv-2")

        paper.ready("gv-1") shouldContainExactly listOf(Do.Forget("gv-1"))
        paper.ready("gv-2") shouldContainExactly listOf(Do.Forget("gv-2"), Do.Resume(1))
    }

    test("a client dropping off a killed Paper or a dead one is part of the restart, but off a Paper that runs it is lost") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.dropped("gv-1", "Disconnected", paperAlive = true) shouldContainExactly
            listOf(Do.Lose("gv-1", "it lost its Paper: Disconnected"))
        paper.dropped("gv-1", "Disconnected", paperAlive = false) shouldContainExactly listOf(Do.Forget("gv-1"))
        paper.restart(7)
        paper.dropped("gv-1", "Disconnected", paperAlive = true) shouldContainExactly listOf(Do.Forget("gv-1"))
    }

    test("a Paper that exits while it boots again is lost, naming its exit code, and gone") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.restart(7)
        paper.exited(137)

        paper.exited(137) shouldContainExactly listOf(Do.Lost(1, PaperLossKind.EXITED_WHILE_BOOTING, "paper-gv-1 exited with code 137 while it booted"), Do.Gone)
        paper.ended(1, "its session sent its result").shouldBeEmpty()
    }

    test("a Paper that exits while its attempt runs is lost, and one that exits during its first boot too") {
        val running = OwnPaper("paper-gv-1", setOf("gv-1"))
        running.claim(1)
        running.connected()
        running.joined("gv-1")
        running.ready("gv-1")
        val booting = OwnPaper("paper-gv-2", setOf("gv-2"))
        booting.claim(2)

        running.exited(1) shouldContainExactly listOf(Do.Lost(1, PaperLossKind.EXITED_WHILE_RUNNING, "paper-gv-1 exited with code 1 while its attempt ran"), Do.Gone)
        booting.exited(1) shouldContainExactly listOf(Do.Lost(2, PaperLossKind.EXITED_WHILE_BOOTING, "paper-gv-2 exited with code 1 while it booted"), Do.Gone)
    }

    test("a Paper that cannot resume its attempt after a restart is lost") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.restart(7)
        paper.exited(137)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.failed(PaperLossKind.RESUME_FAILED, "paper-gv-1 could not resume its attempt: the player gv-1 is not online") shouldContainExactly
            listOf(Do.Lost(1, PaperLossKind.RESUME_FAILED, "paper-gv-1 could not resume its attempt: the player gv-1 is not online"))
        paper.resumed(41).shouldBeEmpty()
    }

    test("a Paper whose boot outlives the limit is lost; the limit of an earlier boot no longer counts") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.restart(7)
        paper.exited(137)

        paper.bootTimedOut(1).shouldBeEmpty()
        paper.bootTimedOut(2) shouldContainExactly listOf(Do.Lost(1, PaperLossKind.BOOT_TIMED_OUT, "paper-gv-1 did not boot within ${OwnPaper.BOOT_SECONDS} s"))
    }

    test("once its attempt ended, the Paper says why, the players go back, a drop is no loss and the Paper's exit is its end") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.ended(1, "its session sent its result") shouldContainExactly
            listOf(Do.Note("stops, as attempt 1 ended: its session sent its result"), Do.Return(1))
        paper.dropped("gv-1", "Disconnected", paperAlive = true) shouldContainExactly listOf(Do.Forget("gv-1"))
        paper.exited(1) shouldContainExactly listOf(Do.Gone)
    }

    test("an attempt that ends while its Paper still boots stops it, saying why; the Paper gathers nobody and its exit is its end") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)

        paper.ended(1, "the client of gv-1 was lost before its lease") shouldContainExactly
            listOf(Do.Note("stops, as attempt 1 ended: the client of gv-1 was lost before its lease"), Do.Return(1))
        paper.connected() shouldContainExactly listOf(Do.RegionsAhead(listOf(OwnPaper.REGION)))
        paper.exited(143) shouldContainExactly listOf(Do.Gone)
    }

    test("the Paper's own pool connection closing is no loss; its process's exit tells") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        paper.connected()

        paper.closed().shouldBeEmpty()
    }
}
