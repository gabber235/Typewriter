package com.typewritermc.playtest

import com.typewritermc.playtest.wire.PoolFile
import java.io.File
import java.io.IOException
import java.net.InetAddress
import java.net.Socket
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import kotlin.io.path.createDirectories
import kotlin.jvm.optionals.getOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * Finds the worktree's game pool through the pool file it leaves in the pool folder, or starts one. A
 * pool serves the run that started it and no other: a pool of another run, which an earlier run left
 * behind or whose test JVMs died, is stopped with its whole game and replaced, never joined, so its
 * logs folder and settings never take in this run. A pool of this run that no longer answers is on its
 * way out, as once its last session left; it is waited for, and stopped once it stays [going] too long.
 * The pool holds `pool.lock`: two test JVMs that start a pool at once each spawn one, the loser exits,
 * and both connect to the winner.
 */
internal class PoolLauncher(
    private val settings: PlaytestSettings,
    private val going: Duration = GOING,
    private val startPool: () -> Process = { start(settings) },
) {
    private val poolFile = settings.poolDir.resolve(PoolFile.NAME)

    fun connect(): Socket {
        settings.poolDir.createDirectories()
        settings.logs.createDirectories()
        val deadline = System.nanoTime() + CONNECT.inWholeNanoseconds
        var started: Process? = null
        var goingSince: Long? = null
        while (System.nanoTime() < deadline) {
            val pool = PoolFile.read(poolFile).getOrNull()
            val process = pool?.process()?.running()?.getOrNull()
            when {
                pool == null || process == null -> {
                    goingSince = null
                    started = started?.takeIf { it.isAlive } ?: start(after = started)
                }

                pool.run() != settings.run -> {
                    stop(process, "it serves the run ${pool.run()}, not this run ${settings.run}")
                }

                else -> {
                    tryConnect(pool.port())?.let { return it }
                    val since = goingSince ?: System.nanoTime().also { goingSince = it }
                    if (System.nanoTime() - since > going.inWholeNanoseconds) stop(process, "it stopped answering over $going ago")
                }
            }
            Thread.sleep(POLL_MILLIS)
        }
        throw GameUnavailable("no game pool of this run answered within $CONNECT; see ${settings.poolLog}")
    }

    /**
     * Starts a pool, unless the one started [after] failed while starting. One that lost the lock to
     * another starter exits cleanly, and the winner's pool file follows.
     */
    private fun start(after: Process?): Process {
        if (after != null && after.exitValue() != 0) {
            throw GameUnavailable("the game pool exited with ${after.exitValue()} while starting; see ${settings.poolLog}")
        }
        return startPool()
    }

    /**
     * Ends [pool] and every process of its game (Paper, the clients and their displays) at once, as a
     * crash would, and waits until all are gone; the pool first, so it starts nothing in place of what ends.
     */
    private fun stop(
        pool: ProcessHandle,
        why: String,
    ) {
        System.err.println("Stopping the game pool ${pool.pid()} and its game: $why")
        val all = listOf(pool) + pool.descendants().toList()
        all.forEach { it.destroyForcibly() }
        for (process in all) {
            try {
                process.onExit().get(STOP_SECONDS, TimeUnit.SECONDS)
            } catch (_: TimeoutException) {
                throw GameUnavailable(
                    "the game pool ${pool.pid()} ($why) still runs process ${process.pid()} $STOP_SECONDS s after it was killed",
                )
            }
        }
    }

    /** A connection to the pool on [port], or null when it does not answer, as while it is on its way out. */
    private fun tryConnect(port: Int): Socket? {
        try {
            return Socket(InetAddress.getLoopbackAddress(), port).apply { tcpNoDelay = true }
        } catch (_: IOException) {
            return null
        }
    }

    private companion object {
        const val POOL_MAIN = "com.typewritermc.playtest.pool.PoolKt"
        const val POLL_MILLIS = 50L
        const val STOP_SECONDS = 10L

        /** How long a test JVM looks for a pool of its run that answers, a replacement's start included. */
        val CONNECT = 3.minutes

        /** How long a pool that left its run may take to stop its game and exit: its own Papers' exits and the parts' stops. */
        val GOING = 90.seconds

        /** Starts a pool with every `playtest.*` property of this test JVM; it appends its output to the run's pool log. */
        fun start(settings: PlaytestSettings): Process =
            ProcessBuilder(
                listOf(settings.java.toString()) +
                    settings.forwarded.map { (key, value) -> "-D$key=$value" } +
                    listOf("-cp", settings.poolClasspath, POOL_MAIN),
            ).redirectErrorStream(true)
                .redirectOutput(ProcessBuilder.Redirect.appendTo(settings.poolLog.toFile()))
                .redirectInput(ProcessBuilder.Redirect.from(File("/dev/null")))
                .start()
    }
}
