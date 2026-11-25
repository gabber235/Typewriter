package com.typewritermc.loader

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.rollout.ArtifactHost
import com.typewritermc.loader.rollout.ArtifactHostAssignmentSource
import com.typewritermc.loader.testing.StartupLoaderService
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import kotlin.time.Duration.Companion.seconds

/** A host exports its work in flight as a metric and drains it before it stops. */
val ArtifactHostWorkTest by testSuite {
    test("a started host exports its work in flight as a metric until it stops") {
        runTest {
            TelemetryTestHarness.create().use { memory ->
                val workDirectory = Files.createTempDirectory("typewriter-host-work")
                val work = InFlightWork()
                val host =
                    ArtifactHost(
                        ServiceId("host"),
                        workDirectory,
                        StartupLoaderService(workDirectory.resolve("artifacts"), memory.openTelemetry),
                        ArtifactHostAssignmentSource { emptyFlow() },
                        work,
                        10.seconds,
                        backgroundScope,
                    )
                host.start()
                val item = work.begin("kv update sessions alex", null)

                memory.gaugeValue("typewriter.work.in_flight") shouldBe 1L
                item.end()
                memory.gaugeValue("typewriter.work.in_flight") shouldBe 0L

                host.stop()
                memory.metrics().filter { it.name == "typewriter.work.in_flight" }.shouldBeEmpty()
                workDirectory.toFile().deleteRecursively()
            }
        }
    }

    test("a host that stops with work still in flight waits out its drain bound, then logs that work") {
        runTest {
            TelemetryTestHarness.create().use { memory ->
                val workDirectory = Files.createTempDirectory("typewriter-host-work")
                val work = InFlightWork()
                val host =
                    ArtifactHost(
                        ServiceId("host"),
                        workDirectory,
                        StartupLoaderService(workDirectory.resolve("artifacts"), memory.openTelemetry),
                        ArtifactHostAssignmentSource { emptyFlow() },
                        work,
                        2.seconds,
                        backgroundScope,
                    )
                host.start()
                work.begin("request realm.authoring", null)
                val began = currentTime

                host.stop()

                (currentTime - began >= 2_000L) shouldBe true
                memory.finishedLogs().map { it.bodyValue.toString() }.single { "request realm.authoring" in it } shouldContain "shutdown"
                workDirectory.toFile().deleteRecursively()
            }
        }
    }
}
