package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import java.net.SocketTimeoutException
import java.nio.file.Files
import kotlin.time.Duration.Companion.milliseconds

val PoolLauncherTest by testSuite {
    test("a pool another run left running is stopped with its whole game and replaced, and never joined") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "earlier run").use { stale ->
            val game = stale.game
            var replacement: StandInPool? = null

            val socket =
                PoolLauncher(
                    launcherSettings(dir, "this run"),
                ) { standInPool(dir, "this run").also { replacement = it }.process }.connect()

            socket.port shouldBe replacement?.server?.localPort
            stale.process.isAlive shouldBe false
            game.filter { it.isAlive }.shouldBeEmpty()
            stale.server.soTimeout = 1
            shouldThrow<SocketTimeoutException> { stale.server.accept() }
            replacement?.close()
        }
    }

    test("a pool of this run that answers is joined, and nothing starts or stops") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "this run").use { running ->
            val socket = PoolLauncher(launcherSettings(dir, "this run")) { error("no pool starts while one of this run answers") }.connect()

            socket.port shouldBe running.server.localPort
            running.process.isAlive shouldBe true
        }
    }

    test("a pool file whose pool died starts a new pool") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "this run").close()
        var replacement: StandInPool? = null

        val socket =
            PoolLauncher(
                launcherSettings(dir, "this run"),
            ) { standInPool(dir, "this run").also { replacement = it }.process }.connect()

        socket.port shouldBe replacement?.server?.localPort
        replacement?.close()
    }

    test("a pool of this run on its way out is waited for until it exits by itself, then replaced") {
        val dir = Files.createTempDirectory("pool")
        val going = standInPool(dir, "this run", going = true, command = listOf("sleep", "1"))
        var replacement: StandInPool? = null

        val socket =
            PoolLauncher(
                launcherSettings(dir, "this run"),
            ) { standInPool(dir, "this run").also { replacement = it }.process }.connect()

        going.process.exitValue() shouldBe 0
        socket.port shouldBe replacement?.server?.localPort
        replacement?.close()
    }

    test("a pool of this run that stays on its way out too long is stopped and replaced") {
        val dir = Files.createTempDirectory("pool")
        standInPool(dir, "this run", going = true).use { stuck ->
            var replacement: StandInPool? = null

            val socket =
                PoolLauncher(launcherSettings(dir, "this run"), going = 300.milliseconds) {
                    standInPool(dir, "this run").also { replacement = it }.process
                }.connect()

            stuck.process.isAlive shouldBe false
            socket.port shouldBe replacement?.server?.localPort
            replacement?.close()
        }
    }
}
