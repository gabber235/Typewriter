package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import skirout.harness.v1.test_run.LossCause

val SharedPaperTest by testSuite {
    test("once up, the shared Paper hears the regions ahead and every client is told to join it") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2"))

        val todo = paper.connected()

        todo
            .filterIsInstance<Do.RegionsAhead>()
            .single()
            .regions.size shouldBe 2
        todo.last() shouldBe Do.Connect
    }

    test("the shared Paper steps once every client joined, and only once") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2"))
        paper.connected()

        paper.joined("gv-1").shouldBeEmpty()
        paper.joined("gv-2") shouldContainExactly listOf(Do.Step)
        paper.joined("gv-1").shouldBeEmpty()
    }

    test("each ready client's player serves claims, and the game boots once every client was ready") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2"))

        paper.ready("gv-1") shouldContainExactly listOf(Do.Free("gv-1"))
        paper.ready("gv-2") shouldContainExactly listOf(Do.Free("gv-2"), Do.Booted)
        paper.ready("gv-1") shouldContainExactly listOf(Do.Free("gv-1"))
    }

    test("a client that comes anew before the boot holds the boot until it is ready again") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2"))
        paper.ready("gv-1")

        paper.arriving("gv-1")

        paper.ready("gv-2") shouldContainExactly listOf(Do.Free("gv-2"))
        paper.ready("gv-1") shouldContainExactly listOf(Do.Free("gv-1"), Do.Booted)
    }

    test("a client that drops off the shared Paper is lost, and must join again before the Paper steps") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2"))
        paper.joined("gv-1")

        paper.dropped("gv-1", "Disconnected", paperAlive = true) shouldContainExactly
            listOf(Do.Lose("gv-1", "it lost its Paper: Disconnected"))
        paper.dropped("gv-2", "Disconnected", paperAlive = false) shouldContainExactly
            listOf(Do.Lose("gv-2", "it lost its Paper: Disconnected"))
        paper.joined("gv-2").shouldBeEmpty()
        paper.joined("gv-1") shouldContainExactly listOf(Do.Step)
    }

    test("each attempt stands in a region no earlier attempt got, and Paper hears the regions the next claims get") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2"))
        val ahead =
            paper
                .connected()
                .filterIsInstance<Do.RegionsAhead>()
                .single()
                .regions

        val first = paper.claim(1)
        val second = paper.claim(2)

        first.region shouldBe ahead.first()
        second.region shouldNotBe first.region
        first.todo.first() shouldBe Do.Claim(1)
        second.todo
            .filterIsInstance<Do.RegionsAhead>()
            .single()
            .regions shouldNotContain second.region
    }

    test(
        "the game fails when the shared Paper misses its boot limit, exits, closes its pool connection or cannot claim, each loss with its cause",
    ) {
        val paper = SharedPaper("paper", setOf("gv-1"))

        paper.bootTimedOut(1) shouldContainExactly
            listOf(Do.Fail("the game was not ready within ${SharedPaper.BOOT_SECONDS} s", LossCause.NEVER_READY))
        paper.exited(137) shouldContainExactly listOf(Do.Fail("paper exited with code 137", LossCause.ExitedWrapper(137)))
        paper.closed() shouldContainExactly
            listOf(Do.Fail("paper closed its pool connection", LossCause.LeftWrapper("it closed its pool connection")))
        paper.failed("paper could not claim gv-1: no such player") shouldContainExactly
            listOf(
                Do.Fail("paper could not claim gv-1: no such player", LossCause.BrokeWrapper("paper could not claim gv-1: no such player")),
            )
    }

    test("a booted game outlives the boot limit") {
        val paper = SharedPaper("paper", setOf("gv-1"))
        paper.ready("gv-1")

        paper.bootTimedOut(1).shouldBeEmpty()
    }

    test("an attempt on the shared Paper restarts nothing, and its end leaves the shared Paper running") {
        val paper = SharedPaper("paper", setOf("gv-1"))
        paper.claim(1)

        paper.restart(7) shouldContainExactly
            listOf(Do.Note("an attempt asked to restart paper, which only an attempt with a Paper of its own may restart"))
        paper.resumed(41).shouldBeEmpty()
        paper.ended(1, "its session sent its result").shouldBeEmpty()
    }
}
