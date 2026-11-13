package com.typewritermc.playtest

import java.io.IOException
import java.net.InetAddress
import java.net.Socket
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.readText

/**
 * Finds the worktree's game pool through its `pool.port` file, or starts one. The pool itself holds
 * `pool.lock`: two test JVMs that start a pool at once each spawn one, the loser exits, and both
 * connect to the winner.
 */
internal class PoolLauncher(
    private val settings: PlaytestSettings,
) {
    private val portFile: Path = settings.poolDir.resolve("pool.port")

    fun connect(): Socket {
        settings.poolDir.createDirectories()
        tryConnect()?.let { return it }
        val pool = start()
        val deadline = System.nanoTime() + START_NANOS
        while (System.nanoTime() < deadline) {
            tryConnect()?.let { return it }
            // A pool that lost the lock to another starter exits cleanly; the winner's port follows.
            if (!pool.isAlive && pool.exitValue() != 0) {
                throw GameUnavailable("the game pool exited with ${pool.exitValue()} while starting; see ${settings.poolLog}")
            }
            Thread.sleep(POLL_MILLIS)
        }
        throw GameUnavailable("the game pool did not open its port within ${START_NANOS / 1_000_000_000} s; see ${settings.poolLog}")
    }

    private fun tryConnect(): Socket? {
        val port = runCatching { portFile.readText().trim().toInt() }.getOrNull() ?: return null
        try {
            return Socket(InetAddress.getLoopbackAddress(), port).apply { tcpNoDelay = true }
        } catch (_: IOException) {
            // A port file left by a pool that died: nobody answers, so a new pool starts.
            return null
        }
    }

    private fun start(): Process =
        ProcessBuilder(
            listOf(settings.java.toString()) +
                settings.forwarded.map { (key, value) -> "-D$key=$value" } +
                listOf("-cp", settings.poolClasspath, POOL_MAIN),
        ).redirectErrorStream(true)
            .redirectOutput(ProcessBuilder.Redirect.appendTo(settings.poolLog.toFile()))
            .redirectInput(ProcessBuilder.Redirect.from(java.io.File("/dev/null")))
            .start()

    private companion object {
        const val POOL_MAIN = "com.typewritermc.playtest.pool.PoolKt"
        const val START_NANOS = 60_000_000_000L
        const val POLL_MILLIS = 50L
    }
}
