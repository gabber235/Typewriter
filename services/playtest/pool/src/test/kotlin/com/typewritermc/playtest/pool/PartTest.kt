package com.typewritermc.playtest.pool

import com.typewritermc.playtest.launch.PartFile
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.optional.shouldBePresent
import io.kotest.matchers.shouldBe
import java.nio.file.Files

val PartTest by testSuite {
    test("a part names its process in its folder, and the next boot in that folder names the new process") {
        val dir = Files.createTempDirectory("paper")
        val log = dir.resolve("paper.log")
        val first = Part.launch("Paper", PartCommand(listOf("sleep", "30"), dir, mapOf()), log)
        first.process.destroyForcibly().waitFor()

        val again = Part.launch("Paper", PartCommand(listOf("sleep", "30"), dir, mapOf()), log, append = true)

        try {
            PartFile.read(dir.resolve(PartFile.NAME)).flatMap(PartFile::running) shouldBePresent {
                it.pid() shouldBe again.process.pid()
            }
        } finally {
            again.process.destroyForcibly()
        }
    }
}
