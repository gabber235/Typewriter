package com.typewritermc.playtest.pool

import skirout.harness.v1.test_run.AttemptPolicy
import java.nio.file.Files
import java.nio.file.Path

/**
 * Settings of a pool serving run `run-1` with [clients] clients, rerunning failures up to four times. Every launched
 * file is named under [dir] and none exists, so a case writes the ones it needs.
 */
internal fun poolSettings(
    dir: Path,
    clients: Int,
) = PoolSettings(
    poolDir = Files.createDirectories(dir.resolve("pool")),
    run =
        ServedRun(
            id = "run-1",
            file = dir.resolve("results/test_run.json"),
            policy = AttemptPolicy.RerunFailuresWrapper(4),
            logs = Files.createDirectories(dir.resolve("logs")),
        ),
    launched =
        Launched(
            java = dir.resolve("java"),
            paperDir = dir.resolve("paper"),
            agentJar = dir.resolve("agent.jar"),
            coverageAgentJar = dir.resolve("coverage-agent.jar"),
            pluginJar = dir.resolve("plugin.jar"),
            clientLaunch = dir.resolve("client-launch.json"),
        ),
    clients = clients,
)
