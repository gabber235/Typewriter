package com.typewritermc.playtest.wire

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.optional.shouldBeEmpty
import io.kotest.matchers.optional.shouldBePresent
import io.kotest.matchers.shouldBe
import java.nio.file.Files

val PartFileTest by testSuite {
    test("a part file reads back as the process that wrote it, which runs") {
        val file = Files.createTempDirectory("part").resolve(PartFile.NAME)
        val written = PartFile.of(ProcessHandle.current())

        written.write(file)

        PartFile.read(file) shouldBePresent { it shouldBe written }
        written.running() shouldBePresent { it.pid() shouldBe ProcessHandle.current().pid() }
    }

    test("a part file left behind names no process once its process ended, nor when another process took its pid") {
        val ended = ProcessBuilder("true").start().apply { waitFor() }
        val self = PartFile.of(ProcessHandle.current())

        PartFile(ended.pid(), 0).running().shouldBeEmpty()
        PartFile(self.pid(), self.startedMillis() - 1_000).running().shouldBeEmpty()
    }

    test("a folder without a part file, or with a file that is not one, names no process") {
        val dir = Files.createTempDirectory("part")
        Files.writeString(dir.resolve("other"), "41234\n")

        PartFile.read(dir.resolve(PartFile.NAME)).shouldBeEmpty()
        PartFile.read(dir.resolve("other")).shouldBeEmpty()
    }
}
