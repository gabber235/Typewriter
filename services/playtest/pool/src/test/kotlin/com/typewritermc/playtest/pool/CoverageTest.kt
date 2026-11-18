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

    test("Paper's coverage agent counts only the packages the build names, never a library a plugin bundles") {
        val classes = Files.createTempDirectory("classes")

        val options = Coverage.agentOptions(listOf("com.typewritermc"), classes).split(",")

        options shouldContain "includes=com.typewritermc.*"
        options shouldContain "classdumpdir=$classes"
    }

    test("a submission no Paper read for covers nothing and costs no step of its record") {
        val coverage = Coverage()

        coverage.covered(Files.createTempDirectory("classes")).shouldBeEmpty()
        coverage.latest.shouldBeEmpty()
        coverage.cost().shouldBeNull()
    }

    test("two plugins' classes of one name each count their own lines, as two plugins that bundle one library hold them") {
        val classes = Files.createTempDirectory("classes")
        val framework = Counted(classes)
        val typewriter = Counted(classes, twin = true)
        val coverage = Coverage()
        framework.run(1)
        typewriter.run(1)
        coverage.add(framework.readAndReset())
        coverage.add(typewriter.readAndReset())

        val covered = coverage.covered(classes).single()

        covered.name shouldBe "com/typewritermc/playtest/pool/Counted\$Subject"
        covered.lines shouldContainAll listOf(Counted.lineOf(1), Counted.twinLineOf())
    }
}
