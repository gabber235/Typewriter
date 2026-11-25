package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.ofRepeat
import skirout.harness.v1.test_run.AttemptPolicy
import java.nio.file.Path

/**
 * Where the pool lives and what it launches. The build starts the pool with every `-Dplaytest.*`
 * property its game test tasks set.
 */
internal class PoolSettings(
    val poolDir: Path,
    /** The run that started the pool, the only one it serves. */
    val run: String,
    /** The run's file, which the pool writes as it takes up the run and after every attempt. */
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
    /** The packages of the build's own code, the only classes coverage counts. */
    val coveredPackages: List<String> = listOf("com.typewritermc"),
    /** What the build's game modules add to every Paper. */
    val paperAdditions: PaperAdditions = PaperAdditions(listOf()),
    /** The cgroup the run's tree gives the game, where each part runs in a leaf of its own; null where there is none. */
    val cgroup: Path? = null,
    /** The memory the pool's parts may take together: the game cgroup's limit, or half the machine. */
    val memoryBudget: MemoryBudget = cgroup?.let { PartLeaves(it).budget() } ?: MemoryBudget.halfTheMachine(),
) {
    /** Where the ahead of time caches for the restart Papers' boots stay across runs. */
    val aotDir: Path get() = poolDir.resolve("aot")

    /** The pool's own log, which the build appends the pool's output to. */
    val poolLog: Path get() = logs.resolve("pool.log")

    companion object {
        fun fromSystemProperties() =
            PoolSettings(
                poolDir = path("playtest.poolDir"),
                run = required("playtest.run"),
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
                coveredPackages = required("playtest.coveredPackages").split(",").filter(String::isNotEmpty),
                paperAdditions =
                    PaperAdditions(
                        System
                            .getProperty("playtest.paperAdditions", "")
                            .split(java.io.File.pathSeparator)
                            .filter(String::isNotEmpty)
                            .map(Path::of),
                    ),
                cgroup = System.getProperty("playtest.cgroup")?.takeIf(String::isNotEmpty)?.let(Path::of),
            )

        private fun path(name: String): Path = Path.of(required(name))

        private fun required(name: String): String =
            checkNotNull(System.getProperty(name)) { "$name is not set: the game test task sets it" }
    }
}
