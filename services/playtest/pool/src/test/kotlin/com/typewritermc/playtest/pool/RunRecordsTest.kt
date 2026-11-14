package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Submit
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.TestRun
import java.nio.file.Files

val RunRecordsTest by testSuite {
    test("a run's file holds each attempt as a case, in the order they ended, with the failure and its line") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        records.started("run-1")
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1),
            Result(1, 420, null, null),
        )
        records.record(
            "run-1",
            Submit(2, "WINDOW-1 a check that never holds fails", "WINDOW-1", 1),
            Result(2, 900, "gv-1 did not see chat \"Goodbye\"", "WindowRequirements.kt:17"),
        )

        records.write("run-1", file)

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.runner shouldBe Runner.GAME
        run.startedAtMillis shouldBe 1_000
        run.attemptPolicy shouldBe AttemptPolicy.ExactlyWrapper(1)
        run.cases.map { it.id } shouldBe
            listOf("PROBE-1 a chat line the probe sends reaches the player", "WINDOW-1 a check that never holds fails")
        run.cases.map { it.requirement } shouldBe listOf("PROBE-1", "WINDOW-1")
        run.cases[0]
            .attempts
            .single()
            .outcome shouldBe Outcome.PASSED
        run.cases[0]
            .attempts
            .single()
            .durationMillis shouldBe 420
        run.cases[1]
            .attempts
            .single()
            .outcome shouldBe
            Outcome.createFailed(message = "gv-1 did not see chat \"Goodbye\"", firstBroken = "WindowRequirements.kt:17")
    }

    test("each run's file holds only that run's attempts") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1),
            Result(1, 420, null, null),
        )
        records.record("run-2", Submit(1, "WINDOW-1 a check that never holds fails", "WINDOW-1", 1), Result(1, 900, null, null))

        records.write("run-2", dir.resolve("run-2.json"))

        TestRun.serializer
            .fromJsonCode(Files.readString(dir.resolve("run-2.json")))
            .cases
            .map { it.requirement } shouldBe
            listOf("WINDOW-1")
    }

    test("a player still out at the end of the run is named on the case whose work hung on it") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val hung = "HUNG-1 work still running 1 s after it began fails the attempt"
        records.record(
            "run-1",
            Submit(1, hung, "HUNG-1", 1),
            Result(1, 1_500, "gv-1's work \"Ledger lookup\" hung", "WorkRequirements.kt:30"),
        )
        records.record("run-1", Submit(2, "PROBE-1 a chat line reaches the player", "PROBE-1", 1), Result(2, 420, null, null))

        records.write(
            "run-1",
            file,
            stillOut =
                mapOf(hung to "gv-1 stayed out of the pool for the rest of the run: its work \"Ledger lookup\" never ended."),
        )

        val cases = TestRun.serializer.fromJsonCode(Files.readString(file)).cases
        cases[0].attempts.single().outcome shouldBe
            Outcome.createFailed(
                message =
                    "gv-1's work \"Ledger lookup\" hung\n" +
                        "gv-1 stayed out of the pool for the rest of the run: its work \"Ledger lookup\" never ended.",
                firstBroken = "WorkRequirements.kt:30",
            )
        cases[1].attempts.single().outcome shouldBe Outcome.PASSED
    }
}
