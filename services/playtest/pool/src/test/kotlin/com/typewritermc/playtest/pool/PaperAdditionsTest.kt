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

        PaperAdditions(listOf(typewriter, sibling)).environment(slot = 0) shouldBe
            mapOf("TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties", "SIBLING" to "1", "PLAYTEST_PAPER_SLOT" to "0")
        shouldThrow<IllegalStateException> { PaperAdditions(listOf(typewriter, other)).environment(slot = 0) }.message shouldContain
            "TYPEWRITER_CONFIG_FILE"
    }

    test("a slot's environment reaches only that slot's Paper, which also learns its slot") {
        val typewriter =
            addition(
                env = mapOf("TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties"),
                slotEnv =
                    mapOf(
                        0 to mapOf("TYPEWRITER_REGISTRATION_TOKEN_FILE" to "/stack/0/token"),
                        2 to mapOf("TYPEWRITER_REGISTRATION_TOKEN_FILE" to "/stack/2/token"),
                    ),
            )
        val additions = PaperAdditions(listOf(typewriter))

        additions.environment(slot = 0) shouldBe
            mapOf(
                "TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties",
                "TYPEWRITER_REGISTRATION_TOKEN_FILE" to "/stack/0/token",
                "PLAYTEST_PAPER_SLOT" to "0",
            )
        additions.environment(slot = 1) shouldBe
            mapOf("TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties", "PLAYTEST_PAPER_SLOT" to "1")
        additions.environment(slot = 2)["TYPEWRITER_REGISTRATION_TOKEN_FILE"] shouldBe "/stack/2/token"
    }

    test("a slot's environment that disagrees with another module's for the same slot fails naming the variable") {
        val first = addition(slotEnv = mapOf(1 to mapOf("TOKEN" to "/a")))
        val second = addition(env = mapOf("TOKEN" to "/b"))

        shouldThrow<IllegalStateException> { PaperAdditions(listOf(first, second)).environment(slot = 1) }.message shouldContain "TOKEN"
        PaperAdditions(listOf(first, second)).environment(slot = 2)["TOKEN"] shouldBe "/b"
    }

    test("a value a module takes from the run's environment is filled in as Paper boots, and one the run does not set fails naming it") {
        val typewriter =
            addition(
                env = mapOf("TYPEWRITER_CONFIG_FILE" to "\${TYPEWRITER_CONFIG_FILE}"),
                slotEnv = mapOf(1 to mapOf("TYPEWRITER_REGISTRATION_TOKEN_FILE" to "\${STACK_GAME_ENGINES}/1/registration-token")),
            )
        val stack = mapOf("TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties", "STACK_GAME_ENGINES" to "/stack/engines")

        PaperAdditions(listOf(typewriter), run = stack).environment(slot = 1) shouldBe
            mapOf(
                "TYPEWRITER_CONFIG_FILE" to "/stack/paper.properties",
                "TYPEWRITER_REGISTRATION_TOKEN_FILE" to "/stack/engines/1/registration-token",
                "PLAYTEST_PAPER_SLOT" to "1",
            )
        val unset = shouldThrow<IllegalStateException> { PaperAdditions(listOf(typewriter), run = mapOf()).environment(slot = 0) }
        unset.message shouldContain "TYPEWRITER_CONFIG_FILE"
        unset.message shouldContain "not set"
    }

    test("the paths kept per slot are every module's, each once") {
        val typewriter = addition(kept = listOf("plugins/Typewriter/state"))
        val sibling = addition(kept = listOf("plugins/Sibling/data", "plugins/Typewriter/state"))

        PaperAdditions(listOf(typewriter, sibling)).kept shouldBe listOf("plugins/Typewriter/state", "plugins/Sibling/data")
    }

    test("a build whose modules add nothing leaves Paper's folder and environment as the framework sets them") {
        val paper = Files.createTempDirectory("paper")

        PaperAdditions(listOf(addition())).copyInto(paper)

        Files.list(paper).use { it.count() } shouldBe 0
        PaperAdditions(listOf()).environment(slot = 0) shouldBe mapOf("PLAYTEST_PAPER_SLOT" to "0")
        PaperAdditions(listOf()).kept shouldBe listOf()
    }
}
