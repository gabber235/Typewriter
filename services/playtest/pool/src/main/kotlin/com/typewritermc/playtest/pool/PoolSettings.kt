package com.typewritermc.playtest.pool

import java.nio.file.Path

/**
 * Where the pool lives and what it launches. The first test JVM starts the pool with every
 * `-Dplaytest.*` property its game test task set.
 */
internal class PoolSettings(
    val poolDir: Path,
    /** The run's logs folder: the pool's own log, and one for every Paper, client and display. */
    val logs: Path,
    val java: Path,
    val paperDir: Path,
    val agentJar: Path,
    /** The JaCoCo agent every Paper runs with, so each attempt's coverage can be read. */
    val coverageAgentJar: Path,
    val pluginJar: Path,
    val clientLaunch: Path,
    /** How many warm clients the pool keeps, each with a player of its own. */
    val clients: Int,
) {
    /** Where the ahead of time caches for the restart Papers' boots stay across runs. */
    val aotDir: Path get() = poolDir.resolve("aot")

    /** The pool's own log, which every test JVM that starts a pool appends that pool's output to. */
    val poolLog: Path get() = logs.resolve("pool.log")

    companion object {
        fun fromSystemProperties() =
            PoolSettings(
                poolDir = path("playtest.poolDir"),
                logs = path("playtest.logs"),
                java = path("playtest.java"),
                paperDir = path("playtest.paper"),
                agentJar = path("playtest.agent"),
                coverageAgentJar = path("playtest.coverageAgent"),
                pluginJar = path("playtest.plugin"),
                clientLaunch = path("playtest.clientLaunch"),
                clients = System.getProperty("playtest.clients", "4").toInt(),
            )

        private fun path(name: String): Path =
            Path.of(checkNotNull(System.getProperty(name)) { "$name is not set: the game test task sets it" })
    }
}
