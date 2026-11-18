package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeInstanceOf
import java.nio.file.Files
import java.nio.file.attribute.FileTime
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.writeText

val AotCacheTest by testSuite {
    test("a key changes with the JDK, with any file's content and with any flag, not with a rebuilt but equal file") {
        val dir = Files.createTempDirectory("aot-key")
        val paper = dir.resolve("paper.jar").also { it.writeText("paper 26.3 build 242") }
        val plugin = dir.resolve("playtest-plugin.jar").also { it.writeText("plugin 1") }
        val flags = listOf("-XX:TieredStopAtLevel=1", "-XX:+UseSerialGC")
        val key = AotCache.key("zulu 25.0.3", listOf(paper, plugin), flags)

        AotCache.key("zulu 25.0.4", listOf(paper, plugin), flags) shouldNotBe key
        AotCache.key("zulu 25.0.3", listOf(paper, plugin), flags + "-Xss512k") shouldNotBe key
        Files.setLastModifiedTime(plugin, FileTime.fromMillis(0))
        AotCache.key("zulu 25.0.3", listOf(paper, plugin), flags) shouldBe key
        plugin.writeText("plugin 2")
        AotCache.key("zulu 25.0.3", listOf(paper, plugin), flags) shouldNotBe key
    }

    test("a boot whose key has no cache trains one, and once it trained, boots use it, even after the halt Paper ends with") {
        val cache = AotCache(Files.createTempDirectory("aot"))

        val train = cache.boot("k1", "paper-gv-1").shouldBeInstanceOf<AotCache.Boot.Train>()
        train.output.writeText("trained")
        cache.trained(train, 1)

        val use = cache.boot("k1", "paper-gv-2").shouldBeInstanceOf<AotCache.Boot.Use>()
        Files.readString(use.cache) shouldBe "trained"
    }

    test("a cache trained for a new key replaces the caches of older keys") {
        val dir = Files.createTempDirectory("aot")
        val cache = AotCache(dir)
        val old = cache.boot("k1", "paper-gv-1") as AotCache.Boot.Train
        old.output.writeText("old")
        cache.trained(old, 0)

        val train = cache.boot("k2", "paper-gv-1").shouldBeInstanceOf<AotCache.Boot.Train>()
        train.output.writeText("new")
        cache.trained(train, 0)

        dir.listDirectoryEntries().map { it.name } shouldContainExactly
            listOf((cache.boot("k2", "paper-gv-1") as AotCache.Boot.Use).cache.name)
    }

    test("a training boot that was killed, or that never finished its cache, leaves none behind, so the next boot trains again") {
        val dir = Files.createTempDirectory("aot")
        val cache = AotCache(dir)
        val killed = cache.boot("k1", "paper-gv-1") as AotCache.Boot.Train
        killed.output.writeText("half written")
        val unfinished = cache.boot("k1", "paper-gv-2") as AotCache.Boot.Train
        unfinished.output.writeText("half written")
        unfinished.output.resolveSibling("${unfinished.output.name}.config").writeText("recorded classes")

        cache.trained(killed, 137)
        cache.trained(unfinished, 0)

        dir.listDirectoryEntries() shouldBe listOf()
        cache.boot("k1", "paper-gv-1").shouldBeInstanceOf<AotCache.Boot.Train>()
    }
}
