package com.typewritermc.services.libs.telemetry

import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe

/** A gauge exports what a service reads now, such as how much work runs, at every collection. */
val GaugeTest by testSuite {
    test("a gauge reports what it reads at each collection until it closes") {
        TelemetryTestHarness.create().use { memory ->
            var running = 3L
            val gauge = memory.telemetry.gauge("typewriter.work.in_flight", "{item}") { running }

            memory.gaugeValue("typewriter.work.in_flight") shouldBe 3L
            running = 0L
            memory.gaugeValue("typewriter.work.in_flight") shouldBe 0L

            gauge.close()
            memory.metrics().filter { it.name == "typewriter.work.in_flight" }.shouldBeEmpty()
        }
    }
}
