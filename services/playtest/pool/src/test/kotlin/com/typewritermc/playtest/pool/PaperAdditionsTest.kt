package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import java.nio.file.Files
import kotlin.io.path.createDirectories
import kotlin.io.path.readText

val PaperAdditionsTest by testSuite {
    test("every module's files land in Paper's folder at their own paths, beside the framework's") {
        val paper = Files.createTempDirectory("paper").also { it.resolve("plugins").createDirectories() }
        Files.writeString(paper.resolve("plugins/playtest-plugin.jar"), "framework")
        val typewriter =
            addition(
                mapOf(
                    "plugins/typewriter.jar" to "loader",
                    "plugins/Typewriter/artifacts/inbox/manual/engine.jar" to "engine",
                ),
            )
        val sibling = addition(mapOf("plugins/Sibling/config.yml" to "a: 1"))

        PaperAdditions(listOf(typewriter, sibling)).copyInto(paper)

        paper.resolve("plugins/playtest-plugin.jar").readText() shouldBe "framework"
        paper.resolve("plugins/typewriter.jar").readText() shouldBe "loader"
        paper.resolve("plugins/Typewriter/artifacts/inbox/manual/engine.jar").readText() shouldBe "engine"
        paper.resolve("plugins/Sibling/config.yml").readText() shouldBe "a: 1"
    }

    test("two modules may add the same file when its content agrees, and fail naming both when it differs") {
        val paper = Files.createTempDirectory("paper")
        val first = addition(mapOf("plugins/typewriter.jar" to "loader"))
        val same = addition(mapOf("plugins/typewriter.jar" to "loader"))
        val other = addition(mapOf("plugins/typewriter.jar" to "another loader"))

        PaperAdditions(listOf(first, same)).copyInto(paper)
        val clash = shouldThrow<IllegalStateException> { PaperAdditions(listOf(first, other)).copyInto(Files.createTempDirectory("paper")) }

        paper.resolve("plugins/typewriter.jar").readText() shouldBe "loader"
        clash.message shouldContain "plugins/typewriter.jar"
        clash.message shouldContain first.toString()
        clash.message shouldContain other.toString()
    }

    test("Paper's environment is every module's, and two modules that set one name to different values fail naming it") {
        val typewriter = addition(env = mapOf("TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties"))
        val sibling = addition(env = mapOf("SIBLING" to "1", "TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties"))
        val other = addition(env = mapOf("TYPEWRITER_CONFIG_FILE" to "/elsewhere.properties"))

        PaperAdditions(listOf(typewriter, sibling)).environment shouldBe
            mapOf("TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties", "SIBLING" to "1")
        shouldThrow<IllegalStateException> { PaperAdditions(listOf(typewriter, other)).environment }.message shouldContain
            "TYPEWRITER_CONFIG_FILE"
    }

    test("a build whose modules add nothing leaves Paper's folder and environment as the framework sets them") {
        val paper = Files.createTempDirectory("paper")

        PaperAdditions(listOf(addition())).copyInto(paper)

        Files.list(paper).use { it.count() } shouldBe 0
        PaperAdditions(listOf()).environment shouldBe mapOf()
    }
}
