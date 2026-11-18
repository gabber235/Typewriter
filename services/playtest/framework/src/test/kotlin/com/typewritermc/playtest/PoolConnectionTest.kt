package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import java.nio.file.Files
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

val PoolConnectionTest by testSuite {
    test("a session connects to the pool of its run") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "this run").use { running ->
            val socket = connectToPool(launcherSettings(dir, "this run"))

            socket.port shouldBe running.server.localPort
        }
    }

    test("a session whose run's pool died fails at once, naming the pool's log") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "this run").close()
        val begun = TimeSource.Monotonic.markNow()

        val unavailable = shouldThrow<GameUnavailable> { connectToPool(launcherSettings(dir, "this run")) }

        begun.elapsedNow() shouldBeLessThan 5.seconds
        unavailable.message shouldContain "${dir.resolve("logs/pool.log")}"
    }

    test("a session finds no pool of its run in a pool another run left, and leaves that pool alone") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "earlier run").use { other ->
            val unavailable = shouldThrow<GameUnavailable> { connectToPool(launcherSettings(dir, "this run")) }

            unavailable.message shouldContain "${dir.resolve("logs/pool.log")}"
            other.process.isAlive shouldBe true
        }
    }

    test("a session with no pool file fails at once, naming the pool's log") {
        val dir = Files.createTempDirectory("pool")

        val unavailable = shouldThrow<GameUnavailable> { connectToPool(launcherSettings(dir, "this run")) }

        unavailable.message shouldContain "${dir.resolve("logs/pool.log")}"
    }
}
