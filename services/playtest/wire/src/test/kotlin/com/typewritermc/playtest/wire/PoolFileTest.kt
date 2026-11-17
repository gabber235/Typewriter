package com.typewritermc.playtest.wire

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.optional.shouldBeEmpty
import io.kotest.matchers.optional.shouldBePresent
import io.kotest.matchers.shouldBe
import java.nio.file.Files

val PoolFileTest by testSuite {
    test("a pool file reads back as the port, run and process of the pool that wrote it, which runs") {
        val file = Files.createTempDirectory("pool").resolve(PoolFile.NAME)
        val written = PoolFile.of(41_234, "run-1")

        written.write(file)

        PoolFile.read(file) shouldBePresent { it shouldBe written }
        written.process().running() shouldBePresent { it.pid() shouldBe ProcessHandle.current().pid() }
    }

    test("a folder without a pool file, or with a file that is not one, holds no pool") {
        val dir = Files.createTempDirectory("pool")
        Files.writeString(dir.resolve("other"), "41234\n")

        PoolFile.read(dir.resolve(PoolFile.NAME)).shouldBeEmpty()
        PoolFile.read(dir.resolve("other")).shouldBeEmpty()
    }
}
