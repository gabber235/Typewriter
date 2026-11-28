package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.async
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** A host drains its work in flight before it stops or rolls out, for at most a configured bound. */
val WorkDrainTest by testSuite {
    test("a drain with no work in flight returns at once with nothing left") {
        runTest {
            InFlightWork().drain(10.seconds, "shutdown", null).shouldBeEmpty()

            currentTime shouldBe 0L
        }
    }

    test("a drain returns as soon as the work in flight ended") {
        runTest {
            val work = InFlightWork()
            val item = work.begin("kv update sessions alex", null)

            val drained = async { work.drain(10.seconds, "shutdown", null) }
            advanceTimeBy(500.milliseconds)
            runCurrent()
            drained.isCompleted shouldBe false
            item.end()

            drained.await().shouldBeEmpty()
            (currentTime < 1_000L) shouldBe true
        }
    }

    test("a drain whose bound runs out logs and returns every item still in flight") {
        runTest {
            TelemetryTestHarness.create().use { memory ->
                val work = InFlightWork()
                val stuck = work.begin("request realm.authoring", null)
                work.begin("engine task join", null).end()

                val left = work.drain(2.seconds, "rollout", memory.telemetry)

                left shouldContainExactly listOf(stuck)
                currentTime shouldBe 2_000L
                val log = memory.finishedLogs().single()
                log.severityText shouldBe LogSeverity.WARN.name
                log.bodyValue.toString() shouldContain "request realm.authoring"
                log.bodyValue.toString() shouldContain "rollout"
            }
        }
    }

    test("a drain of some runtimes waits only for their work in flight") {
        runTest {
            val work = InFlightWork()
            val leaving = WorkRuntime("leaving engine")
            val sibling = WorkRuntime("sibling engine")
            work.of(sibling).begin("engine task chat", null)
            val leavingTask = work.of(leaving).begin("engine task join", null)

            val drained = async { work.drain(10.seconds, "rollout", null, setOf(leaving)) }
            advanceTimeBy(500.milliseconds)
            runCurrent()
            drained.isCompleted shouldBe false
            leavingTask.end()

            drained.await().shouldBeEmpty()
            (currentTime < 1_000L) shouldBe true
        }
    }
}
