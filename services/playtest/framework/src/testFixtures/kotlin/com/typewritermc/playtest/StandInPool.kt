package com.typewritermc.playtest

import com.typewritermc.playtest.launch.PoolFile
import java.net.InetAddress
import java.net.ServerSocket
import java.nio.file.Path

/**
 * A process standing in for a game pool in a pool folder: it runs [process], and a pool file of its run
 * names it with the port of [server], which answers like a pool's while it is open. [game] are the
 * processes it started, as a pool starts Paper and its clients.
 */
class StandInPool(
    val process: Process,
    val server: ServerSocket,
) : AutoCloseable {
    val game: List<ProcessHandle> get() = process.descendants().toList()

    override fun close() {
        server.close()
        (game + process.toHandle()).forEach { it.destroyForcibly() }
    }
}

/**
 * Starts a stand in pool of [run] in [poolDir], a shell with a child that stands for its game, and names
 * it in the folder's pool file; it answers on its server.
 */
fun standInPool(
    poolDir: Path,
    run: String,
): StandInPool {
    val process = ProcessBuilder("sh", "-c", "sleep 300 & sleep 300").start()
    val server = ServerSocket(0, 16, InetAddress.getLoopbackAddress())
    PoolFile.of(server.localPort, run, process.toHandle()).write(poolDir.resolve(PoolFile.NAME))
    // The shell starts its game children as it runs; a stand in counts once they exist.
    val deadline = System.nanoTime() + 5_000_000_000L
    while (process.descendants().count() < 2 && System.nanoTime() < deadline) Thread.sleep(10)
    return StandInPool(process, server)
}

/** Settings of a test JVM of [run] whose pool lives in [poolDir]. */
internal fun launcherSettings(
    poolDir: Path,
    run: String,
): PlaytestSettings =
    PlaytestSettings(
        poolDir = poolDir,
        logs = poolDir.resolve("logs"),
        run = run,
        testRun = poolDir.resolve("test_run.json"),
        root = poolDir,
        goldens = "goldens",
        goldenImages = poolDir.resolve("images"),
        mesa = "",
        pinnedRunner = false,
    )
