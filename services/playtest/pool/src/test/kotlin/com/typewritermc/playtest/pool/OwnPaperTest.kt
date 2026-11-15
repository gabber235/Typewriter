package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.OwnPaper.Do
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly

val OwnPaperTest by testSuite {
    test("the players are told to join only once their Paper is up, and it steps once all of them joined") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1", "gv-2"))

        paper.start() shouldContainExactly listOf(Do.Boot)
        paper.connected() shouldContainExactly listOf(Do.Connect)
        paper.joined("gv-1").shouldBeEmpty()
        paper.joined("gv-2") shouldContainExactly listOf(Do.Step)
    }

    test("the first time every player steps with the Paper, the attempt claims them") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1", "gv-2"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.joined("gv-2")

        paper.ready("gv-1").shouldBeEmpty()
        paper.ready("gv-2") shouldContainExactly listOf(Do.Claim)
    }

    test("a restart kills the Paper, boots it again and answers once every player is back, resumed unwiped") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.restart(7) shouldContainExactly listOf(Do.Kill)
        paper.exited(137) shouldContainExactly listOf(Do.Boot)
        paper.connected() shouldContainExactly listOf(Do.Connect)
        paper.joined("gv-1") shouldContainExactly listOf(Do.Step)
        paper.ready("gv-1") shouldContainExactly listOf(Do.Resume)
        paper.resumed(41) shouldContainExactly listOf(Do.Restarted(7, 41))
    }

    test("a client dropping off a killed Paper is part of the restart, but not off a Paper that runs") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.dropsExpected.shouldBeFalse()

        paper.restart(7)

        paper.dropsExpected.shouldBeTrue()
    }

    test("a Paper that exits while it boots again is lost, naming its exit code") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.restart(7)
        paper.exited(137)

        paper.exited(137) shouldContainExactly listOf(Do.Lost("paper-gv-1 exited with code 137 while it booted"))
        paper.ended().shouldBeEmpty()
    }

    test("a Paper that exits while its attempt runs is lost, and one that exits during its first boot too") {
        val running = OwnPaper("paper-gv-1", setOf("gv-1"))
        running.start()
        running.connected()
        running.joined("gv-1")
        running.ready("gv-1")
        val booting = OwnPaper("paper-gv-2", setOf("gv-2"))
        booting.start()

        running.exited(1) shouldContainExactly listOf(Do.Lost("paper-gv-1 exited with code 1 while its attempt ran"))
        booting.exited(1) shouldContainExactly listOf(Do.Lost("paper-gv-2 exited with code 1 while it booted"))
    }

    test("a Paper that cannot resume its attempt after a restart is lost") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.restart(7)
        paper.exited(137)
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.failed("paper-gv-1 could not resume its attempt: the player gv-1 is not online") shouldContainExactly
            listOf(Do.Lost("paper-gv-1 could not resume its attempt: the player gv-1 is not online"))
        paper.resumed(41).shouldBeEmpty()
    }

    test("a Paper whose boot outlives the limit is lost; the limit of an earlier boot no longer counts") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")
        paper.restart(7)
        paper.exited(137)

        paper.bootTimedOut(1).shouldBeEmpty()
        paper.bootTimedOut(paper.boots) shouldContainExactly
            listOf(Do.Lost("paper-gv-1 did not boot within ${OwnPaper.BOOT_SECONDS} s"))
    }

    test("once its attempt ended, the players go back and the Paper's exit is no loss") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.start()
        paper.connected()
        paper.joined("gv-1")
        paper.ready("gv-1")

        paper.ended() shouldContainExactly listOf(Do.Return)
        paper.dropsExpected.shouldBeTrue()
        paper.exited(1).shouldBeEmpty()
    }
}
