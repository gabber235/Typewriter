package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import java.nio.file.Files

val CoverageTest by testSuite {
    test("an attempt covers the lines of the code that ran in it, by class and source file, and not the code that did not") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage<Long>()
        paper.run(1)
        coverage.add(1, paper.readAndReset())

        val covered = coverage.covered(1, paper.classes).single()

        covered.name() shouldBe "com/typewritermc/playtest/pool/Counted\$Subject"
        covered.source() shouldBe "com/typewritermc/playtest/pool/Counted.kt"
        covered.lines() shouldContain Counted.lineOf(1)
        covered.lines() shouldNotContain Counted.lineOf(2)
    }

    test("an attempt's reads add up to everything that ran in it") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage<Long>()
        paper.run(1)
        coverage.add(1, paper.readAndReset())
        paper.run(2)
        coverage.add(1, paper.readAndReset())

        coverage.covered(1, paper.classes).single().lines() shouldContainAll listOf(Counted.lineOf(1), Counted.lineOf(2))
    }

    test("a read counts only for the attempts it was handed to") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage<Long>()
        paper.run(1)
        coverage.add(1, paper.readAndReset())
        paper.run(2)
        coverage.add(2, paper.readAndReset())

        coverage.covered(1, paper.classes).single().lines() shouldNotContain Counted.lineOf(2)
        coverage.covered(2, paper.classes).single().lines() shouldNotContain Counted.lineOf(1)
        coverage.covered(3, paper.classes).shouldBeEmpty()
    }

    test("an attempt that ended covers nothing any more") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage<Long>()
        paper.run(1)
        coverage.add(1, paper.readAndReset())

        coverage.forget(1)

        coverage.covered(1, paper.classes).shouldBeEmpty()
    }

    test("an attempt's last analysis stays its coverage until it ends, with what its reads and analyses cost") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage<Long>()
        paper.run(1)
        coverage.add(1, paper.readAndReset(), readNanos = 400_000)

        val analysed = coverage.covered(1, paper.classes)
        paper.run(2)
        coverage.add(1, paper.readAndReset(), readNanos = 100_000)

        coverage.latest(1) shouldBe analysed
        coverage.cost(1)?.says() shouldStartWith "coverage: 2 reads held Paper's main thread 0.500 ms; 1 analyses took"
        coverage.forget(1)
        coverage.latest(1).shouldBeEmpty()
        coverage.cost(1).shouldBeNull()
    }

    test("a session that leaves without sending its results releases the coverage of every attempt it ran, and no other session's") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage<Pair<String, Long>>()
        for (attempt in listOf("module" to 1L, "module" to 2L, "ide" to 1L)) {
            paper.run(1)
            coverage.add(attempt, paper.readAndReset())
            coverage.covered(attempt, paper.classes)
        }

        coverage.forget { (session, _) -> session == "module" }

        coverage.covered("module" to 1L, paper.classes).shouldBeEmpty()
        coverage.latest("module" to 2L).shouldBeEmpty()
        coverage.cost("module" to 2L).shouldBeNull()
        coverage.latest("ide" to 1L).shouldNotBeEmpty()
    }
}
