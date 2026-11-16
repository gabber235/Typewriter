package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
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
}
