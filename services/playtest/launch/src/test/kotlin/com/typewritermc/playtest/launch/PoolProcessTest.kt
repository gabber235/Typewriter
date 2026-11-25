package com.typewritermc.playtest.launch

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.optional.shouldBePresent
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

val PoolProcessTest by testSuite {
    test("the pool's JVM caps its heap at its share of the pool's memory limit") {
        PoolProcess.command("java", mapOf("playtest.run" to "run-1"), "pool.jar") shouldContain PartLimit.POOL.heapFlag()
    }

    test("the pool runs with every playtest property of its build, on the pool's classpath") {
        PoolProcess.command("java", mapOf("playtest.run" to "run-1", "playtest.clients" to "4"), "pool.jar") shouldContainAll
            listOf("-Dplaytest.run=run-1", "-Dplaytest.clients=4", "pool.jar", PoolProcess.MAIN)
    }

    test("a started pool already listens for its run when the build's first test looks for it") {
        val dir = Files.createTempDirectory("pool")
        val poolFile = dir.resolve(PoolFile.NAME)

        PoolProcess.start(standInPool(poolFile, "run-1"), dir.resolve("pool.log"), poolFile, "run-1").use { pool ->
            PoolFile.read(poolFile) shouldBePresent {
                run() shouldBe "run-1"
                process().running() shouldBePresent { pid() shouldBe pool.pid() }
            }
        }
    }

    test("a pool that exits before it listens hands the build back at once") {
        val dir = Files.createTempDirectory("pool")
        val begun = TimeSource.Monotonic.markNow()

        PoolProcess.start(listOf("false"), dir.resolve("pool.log"), dir.resolve(PoolFile.NAME), "run-1").close()

        begun.elapsedNow() shouldBeLessThan 10.seconds
    }

    test("closing a pool ends its input, and the pool exits by itself") {
        val dir = Files.createTempDirectory("pool")
        val poolFile = dir.resolve(PoolFile.NAME)
        val pool = PoolProcess.start(standInPool(poolFile, "run-1"), dir.resolve("pool.log"), poolFile, "run-1")
        val process = ProcessHandle.of(pool.pid()).get()

        pool.close()

        process.isAlive shouldBe false
    }

    test("a pool still running once its time to exit is over is killed with every process it started") {
        // The shell never reads its input, as a pool stuck stopping its game; its child stands for that game.
        val process = ProcessBuilder("sh", "-c", "sleep 300 & sleep 300").start()
        val deadline = System.nanoTime() + 5_000_000_000L
        while (process.descendants().count() < 2 && System.nanoTime() < deadline) Thread.sleep(10)
        val game = process.descendants().toList()

        PoolProcess(process, Duration.ofMillis(300)).close()

        process.isAlive shouldBe false
        game.filter { it.isAlive } shouldBe listOf()
    }
}
