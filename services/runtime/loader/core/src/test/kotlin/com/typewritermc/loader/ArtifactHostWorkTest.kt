package com.typewritermc.loader

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.testing.withIdleHost
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.seconds

/** A host exports its work in flight as a metric and drains it before it stops. */
val ArtifactHostWorkTest by testSuite {
    test("a started host exports its work in flight as a metric until it stops") {
        runTest {
            TelemetryTestHarness.create().use { memory ->
                val work = InFlightWork()
                withIdleHost(work, 10.seconds, memory.openTelemetry) { host ->
                    val item = work.begin("kv update sessions alex", null)

                    memory.gaugeValue("typewriter.work.in_flight") shouldBe 1L
                    item.end()
                    memory.gaugeValue("typewriter.work.in_flight") shouldBe 0L

                    host.stop()
                    memory.metrics().filter { it.name == "typewriter.work.in_flight" }.shouldBeEmpty()
                }
            }
        }
    }

    test("a host that stops with work still in flight waits out its drain bound, then logs that work") {
        runTest {
            TelemetryTestHarness.create().use { memory ->
                val work = InFlightWork()
                withIdleHost(work, 2.seconds, memory.openTelemetry) { host ->
                    work.begin("request realm.authoring", null)
                    val began = currentTime

                    host.stop()

                    (currentTime - began >= 2_000L) shouldBe true
                    val leftover = memory.finishedLogs().map { it.bodyValue.toString() }.single { "request realm.authoring" in it }
                    leftover shouldContain "shutdown"
                }
            }
        }
    }
}
