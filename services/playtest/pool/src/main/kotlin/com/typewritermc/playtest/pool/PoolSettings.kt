package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.ofRepeat
import skirout.harness.v1.test_run.AttemptPolicy
import java.nio.file.Path

/**
 * Where the pool lives and what it launches. The first test JVM starts the pool with every
 * `-Dplaytest.*` property its game test task set.
 */
internal class PoolSettings(
    val poolDir: Path,
    /** The run that started the pool, the only one it serves. */
    val run: String,
    /** The run's file, which the pool writes after every attempt and a pool that continues the run takes up. */
    val testRun: Path,
    /** How the run makes the attempts of each requirement, as its file states. */
    val policy: AttemptPolicy,
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
                run = checkNotNull(System.getProperty("playtest.run")) { "playtest.run is not set: the game test task sets it" },
                testRun = path("playtest.testRun"),
                policy = AttemptPolicy.ofRepeat(System.getProperty("playtest.repeat")),
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
