package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import kotlin.io.path.exists

val PapersTest by testSuite {
    test(
        "a restart attempt claimed again while its old Paper still exits gets a Paper of its own; the old one's exit and end reach only the old one",
    ) {
        val papers = scratchPapers()
        val old = papers.restart(23, setOf("gv-1"))
        old.rules.claim(23)
        old.rules.ended(23, "the client of gv-1 was lost before its lease")

        val new = papers.restart(24, setOf("gv-1"))

        new.name shouldNotBe old.name
        papers[old.name] shouldBe old
        old.rules.exited(143) shouldContainExactly listOf(Do.Gone)
        papers.gone(old)
        papers[old.name].shouldBeNull()
        papers[new.name] shouldBe new
        new.folder.dir.exists() shouldBe true
        old.folder.dir.exists() shouldBe false
    }

    test("a Paper's name is its own: a second Paper under the name of one that runs is refused") {
        val papers = scratchPapers()
        papers.add(sharedPaper())

        shouldThrow<IllegalStateException> {
            papers.add(sharedPaper())
        }
    }

    test("each own Paper running at once has a slot of its own after the shared Paper's 0, and a gone Paper's slot serves the next") {
        val papers = scratchPapers()
        papers.add(sharedPaper())

        val first = papers.restart(1, setOf("gv-2"))
        val second = papers.restart(2, setOf("gv-3"))
        papers.gone(first)
        val third = papers.restart(3, setOf("gv-4"))

        first.folder.slot shouldBe 1
        second.folder.slot shouldBe 2
        third.folder.slot shouldBe 1
    }
}
