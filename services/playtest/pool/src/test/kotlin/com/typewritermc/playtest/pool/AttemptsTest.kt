package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe

val AttemptsTest by testSuite {
    test("an attempt that ends before its lease stops its restart Paper and says why, while the pool can still find the attempt") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        val attempts = Attempts<String>()
        attempts.start(1, "RESTART-1", listOf("gv-1"), paper)
        var heard = listOf<Do>()
        var found: String? = null

        attempts.end(1, "the client of gv-1 was lost before its lease") { todo ->
            heard = todo
            found = attempts.of("gv-1")
        }

        heard shouldContainExactly listOf(Do.Note("stops, as attempt 1 ended: the client of gv-1 was lost before its lease"), Do.Return(1))
        found shouldBe "RESTART-1"
        attempts[1].shouldBeNull()
        attempts.of("gv-1").shouldBeNull()
    }

    test("an attempt ends once: ending it again tells its Paper nothing") {
        val paper = OwnPaper("paper-gv-1", setOf("gv-1"))
        paper.claim(1)
        val attempts = Attempts<String>()
        attempts.start(1, "RESTART-1", listOf("gv-1"), paper)
        attempts.end(1, "its Paper was lost") {}
        var heard: List<Do>? = null

        attempts.end(1, "its session left") { heard = it }

        heard.shouldBeNull()
    }

    test("a running attempt is found by its id and by each of its players, and the others run on once one ends") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2", "gv-3"))
        val attempts = Attempts<String>()
        attempts.start(1, "CHAT-1", listOf("gv-1"), paper)
        attempts.start(2, "GROUP-1", listOf("gv-2", "gv-3"), paper)

        attempts.end(1, "its session sent its result") {}

        attempts.of("gv-3") shouldBe "GROUP-1"
        attempts[2] shouldBe "GROUP-1"
        attempts.of("gv-1").shouldBeNull()
        attempts.all shouldContainExactly listOf("GROUP-1")
    }

    test("a leased attempt is overdue once its lease's deadline passed, and the next deadline is the earliest one still running") {
        val paper = SharedPaper("paper", setOf("gv-1", "gv-2", "gv-3"))
        val attempts = Attempts<String>()
        attempts.start(1, "STUCK-1", listOf("gv-1"), paper)
        attempts.start(2, "CHAT-1", listOf("gv-2"), paper)
        attempts.start(3, "GROUP-1", listOf("gv-3"), paper)
        attempts.leased(1, until = 1_000)
        attempts.leased(2, until = 900)
        attempts.leased(3, until = 2_000)

        attempts.end(2, "its session sent its result") {}

        attempts.nextDeadline() shouldBe 1_000
        attempts.overdue(999).shouldBeEmpty()
        attempts.overdue(1_000) shouldContainExactly listOf("STUCK-1")
    }

    test("an attempt still waiting for its lease has no deadline") {
        val paper = SharedPaper("paper", setOf("gv-1"))
        val attempts = Attempts<String>()
        attempts.start(1, "RESTART-1", listOf("gv-1"), paper)

        attempts.nextDeadline().shouldBeNull()
        attempts.overdue(Long.MAX_VALUE).shouldBeEmpty()
    }
}
