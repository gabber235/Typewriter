package com.typewritermc.playtest

import com.typewritermc.playtest.launch.PoolFile
import java.io.IOException
import java.net.InetAddress
import java.net.Socket
import kotlin.jvm.optionals.getOrNull

/**
 * A connection to the pool of this test JVM's run, which the build started before any of its tests and
 * which names itself in the pool file of the pool folder once it listens. A pool of another run, or one
 * of this run that died, is no pool of this run: the session fails at once, pointing at the pool's log,
 * and never starts or stops a pool.
 */
internal fun connectToPool(settings: PlaytestSettings): Socket {
    val pool = PoolFile.read(settings.poolDir.resolve(PoolFile.NAME)).getOrNull()
    val unavailable = { why: String -> GameUnavailable("$why; see ${settings.poolLog}") }
    when {
        pool == null -> {
            throw unavailable("no game pool runs in ${settings.poolDir}")
        }

        pool.run() != settings.run -> {
            throw unavailable("the game pool in ${settings.poolDir} serves the run ${pool.run()}, not this run ${settings.run}")
        }

        pool.process().running().isEmpty -> {
            throw unavailable("the game pool of this run exited")
        }
    }
    try {
        return Socket(InetAddress.getLoopbackAddress(), pool.port()).apply { tcpNoDelay = true }
    } catch (refused: IOException) {
        throw GameUnavailable("the game pool of this run does not answer: ${refused.message}; see ${settings.poolLog}", refused)
    }
}
