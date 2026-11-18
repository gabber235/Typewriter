package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import java.nio.file.Files

val CoverageTest by testSuite {
    test("a submission covers the lines of the code that ran in its attempts, by class and source file, and not the code that did not") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage()
        paper.run(1)
        coverage.add(paper.readAndReset())

        val covered = coverage.covered(paper.classes).single()

        covered.name shouldBe "com/typewritermc/playtest/pool/Counted\$Subject"
        covered.source shouldBe "com/typewritermc/playtest/pool/Counted.kt"
        covered.lines shouldContain Counted.lineOf(1)
        covered.lines shouldNotContain Counted.lineOf(2)
    }

    test("a submission's reads add up to everything that ran in it") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage()
        paper.run(1)
        coverage.add(paper.readAndReset())
        paper.run(2)
        coverage.add(paper.readAndReset())

        coverage.covered(paper.classes).single().lines shouldContainAll listOf(Counted.lineOf(1), Counted.lineOf(2))
    }

    test("a submission's last analysis stays its coverage, with what its reads and analyses cost") {
        val paper = Counted(Files.createTempDirectory("classes"))
        val coverage = Coverage()
        paper.run(1)
        coverage.add(paper.readAndReset(), readNanos = 400_000)

        val analysed = coverage.covered(paper.classes)
        paper.run(2)
        coverage.add(paper.readAndReset(), readNanos = 100_000)

        coverage.latest shouldBe analysed
        coverage.cost()?.says shouldStartWith "coverage: 2 reads held Paper's main thread 0.500 ms; 1 analyses took"
    }

    test("a submission no Paper read for covers nothing and costs no step of its record") {
        val coverage = Coverage()

        coverage.covered(Files.createTempDirectory("classes")).shouldBeEmpty()
        coverage.latest.shouldBeEmpty()
        coverage.cost().shouldBeNull()
    }
}
