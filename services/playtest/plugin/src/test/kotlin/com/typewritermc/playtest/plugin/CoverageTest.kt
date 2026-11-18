package com.typewritermc.playtest.plugin

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val CoverageTest by testSuite {
    test("an attempt that runs alone gets exactly the code that ran while it held its players") {
        val paper = Ran()
        val coverage = Coverage(paper::readAndReset, paper.reads::add)
        paper.run("before")
        coverage.started(1)
        paper.run("probe")
        coverage.settled(1)
        paper.run("after")
        coverage.started(2)

        paper.covered() shouldBe mapOf(1L to setOf("probe"))
    }

    test("attempts that overlap each get what ran while they overlapped, and only that") {
        val paper = Ran()
        val coverage = Coverage(paper::readAndReset, paper.reads::add)
        coverage.started(1)
        paper.run("first alone")
        coverage.started(2)
        paper.run("both")
        coverage.settled(1)
        paper.run("second alone")
        coverage.settled(2)

        paper.covered() shouldBe
            mapOf(
                1L to setOf("first alone", "both"),
                2L to setOf("both", "second alone"),
            )
    }

    test("an attempt that ended without settling gets nothing that ran after it ended") {
        val paper = Ran()
        val coverage = Coverage(paper::readAndReset, paper.reads::add)
        coverage.started(1)
        coverage.started(2)
        paper.run("both")
        coverage.ended(1)
        coverage.settled(2)
        paper.run("later")
        coverage.started(3)
        paper.run("third")
        coverage.settled(3)

        paper.covered() shouldBe mapOf(1L to setOf("both"), 2L to setOf("both"), 3L to setOf("third"))
    }
}
