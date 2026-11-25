package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.RunEnd
import skirout.harness.v1.test_run.TestRun
import java.net.InetAddress
import java.net.ServerSocket
import java.nio.file.Files

val PoolTest by testSuite {
    test("a game that cannot start fails the pool and leaves why in the run's file, before any session joined") {
        val dir = Files.createTempDirectory("pool")
        // No plugin jar was built, so the shared Paper's folder cannot be set up.
        val settings =
            PoolSettings(
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
                clients = 1,
            )

        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            shouldThrowAny { Pool(settings, server).run() }
        }

        val run = TestRun.serializer.fromJsonCode(Files.readString(settings.run.file))
        run.runId shouldBe "run-1"
        run.attemptPolicy shouldBe AttemptPolicy.RerunFailuresWrapper(4)
        run.end.shouldBeInstanceOf<RunEnd.CouldNotRunWrapper>().value shouldContain "${settings.launched.pluginJar}"
    }
}
