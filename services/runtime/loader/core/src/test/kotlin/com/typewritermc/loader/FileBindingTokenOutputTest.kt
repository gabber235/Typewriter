package com.typewritermc.loader

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.attribute.PosixFilePermission

val FileBindingTokenOutputTest by testSuite {
    test("a rotated token replaces the previous one and leaves no temporary file behind") {
        val directory = Files.createTempDirectory("binding-token")
        val file = directory.resolve("state/registration-token")
        val output = FileBindingTokenOutput(file)

        output.display("first-token")
        output.display("second-token")

        Files.readString(file) shouldBe "second-token"
        Files.list(file.parent).use { it.toList() } shouldContainExactly listOf(file)
    }

    test("only the owner can read the token file") {
        val file = Files.createTempDirectory("binding-token-permissions").resolve("registration-token")

        FileBindingTokenOutput(file).display("secret-token")

        // The test file systems support POSIX permissions; elsewhere the platform default applies.
        Files.getPosixFilePermissions(file) shouldBe setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE)
    }

    test("clearing the token deletes its file") {
        val file = Files.createTempDirectory("binding-token-cleared").resolve("registration-token")
        val output = FileBindingTokenOutput(file)
        output.display("bound-token")

        output.cleared()

        Files.exists(file) shouldBe false
    }
}
