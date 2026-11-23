package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import skirout.harness.v1.test_run.AttemptPolicy
import java.nio.file.Files

val LaunchesTest by testSuite {
    test("every Paper the pool starts caps its heap and the memory it keeps beside its heap, and every client caps its heap") {
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

        val bounded = listOf("-XX:MaxRAMPercentage", "-XX:MaxDirectMemorySize", "-XX:MaxMetaspaceSize", "-XX:ReservedCodeCacheSize")

        Launches.sharedPaper(settings, 4000, folder, server, "output=none").map { it.substringBefore('=') } shouldContainAll bounded
        Launches.ownPaper(settings, 4000, folder, server, "output=none", listOf()).map { it.substringBefore('=') } shouldContainAll bounded
        // A client's memory beside its heap is mostly the software renderer's, which no JVM flag bounds.
        Launches.client(settings, 4000, "gv-1", InputPath.SDL, dir.resolve("client-gv-1")).map { it.substringBefore('=') } shouldContain
            "-XX:MaxRAMPercentage"
    }
}
