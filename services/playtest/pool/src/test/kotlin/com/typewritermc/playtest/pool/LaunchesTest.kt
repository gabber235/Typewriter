package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import skirout.harness.v1.test_run.AttemptPolicy
import java.nio.file.Files

val LaunchesTest by testSuite {
    test(
        "every game JVM the pool starts caps its heap at its share of its kind's memory limit: the shared Paper, an own Paper and a client",
    ) {
        val dir = Files.createTempDirectory("launches")
        val settings =
            PoolSettings(
                poolDir = dir.resolve("pool"),
                run = "run-1",
                testRun = dir.resolve("test_run.json"),
                policy = AttemptPolicy.RerunFailuresWrapper(4),
                logs = dir.resolve("logs"),
                java = dir.resolve("java"),
                paperDir = dir.resolve("paper"),
                agentJar = dir.resolve("agent.jar"),
                coverageAgentJar = dir.resolve("coverage-agent.jar"),
                pluginJar = dir.resolve("plugin.jar"),
                clientLaunch = dir.resolve("client-launch.json"),
                clients = 4,
            )
        Files.writeString(
            settings.clientLaunch,
            """{"jvmArgs": [], "classpath": ["client.jar"], "main": "net.minecraft.client.main.Main", "args": []}""",
        )
        val server = PaperServer(listOf(dir.resolve("server.jar")), "io.papermc.paper.PaperBootstrap")
        val folder = PaperFolder("paper", dir.resolve("paper"), 25565, dir.resolve("paper.log"), slot = 0)

        // 66% of 3904 MiB, 46% of 2393 MiB and 42% of 1775 MiB.
        Launches.sharedPaper(settings, 4000, folder, server, "output=none") shouldContain "-Xmx2576m"
        Launches.ownPaper(settings, 4000, folder, server, "output=none", listOf()) shouldContain "-Xmx1100m"
        Launches.client(settings, 4000, "gv-1", InputPath.SDL, dir.resolve("client-gv-1")) shouldContain "-Xmx745m"
    }
}
