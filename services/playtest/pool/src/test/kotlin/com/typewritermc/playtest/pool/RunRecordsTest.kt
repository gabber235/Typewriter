package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message.AttemptPolicy
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.Demonstrates
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Submit
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.ArtifactKind
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.test_run.TestRun
import java.nio.file.Files
import skirout.harness.v1.test_run.AttemptPolicy as RunPolicy
import skirout.harness.v1.test_run.Demonstrates as RunDemonstrates

val RunRecordsTest by testSuite {
    val retries = AttemptPolicy(AttemptPolicy.Kind.RERUN_FAILURES, 4)

    test("a run's file holds each case in the order its first attempt ended, with the failure and its line") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        records.started("run-1")
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH),
            Result(1, 420, null, null, listOf(), "", listOf()),
        )
        records.record(
            "run-1",
            Submit(2, "WINDOW-1 a check that never holds fails", "WINDOW-1", 1, Demonstrates.FAILURE),
            Result(2, 900, "gv-1 did not see chat \"Goodbye\"", "WindowRequirements.kt:17", listOf(), "", listOf()),
        )

        records.ended("run-1", file, retries)

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.runner shouldBe Runner.GAME
        run.startedAtMillis shouldBe 1_000
        run.cases.map { it.id } shouldBe
            listOf("PROBE-1 a chat line the probe sends reaches the player", "WINDOW-1 a check that never holds fails")
        run.cases.map { it.requirement } shouldBe listOf("PROBE-1", "WINDOW-1")
        run.cases[0].attempts.map { it.outcome to it.durationMillis } shouldBe listOf(Outcome.PASSED to 420L)
        run.cases[1].attempts.map { it.outcome } shouldBe
            listOf(Outcome.createFailed(message = "gv-1 did not see chat \"Goodbye\"", firstBroken = "WindowRequirements.kt:17"))
    }

    test("the frames an attempt wrote land in the run file as screenshots in the attempt's folder") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.record(
            "run-1",
            Submit(1, "GOLDEN-1 a sidebar matches its golden", "GOLDEN-1", 1, Demonstrates.HAPPY_PATH),
            Result(
                1,
                120,
                "the frame differs from golden sidebar",
                null,
                listOf(),
                "GOLDEN-1/attempt-1",
                listOf("sidebar.png", "sidebar.diff.png"),
            ),
        )

        records.ended("run-1", file, retries)

        val attempt =
            TestRun.serializer
                .fromJsonCode(Files.readString(file))
                .cases
                .single()
                .attempts
                .single()
        attempt.folder shouldBe "GOLDEN-1/attempt-1"
        attempt.artifacts shouldBe
            listOf(
                Artifact(kind = ArtifactKind.SCREENSHOT, path = "sidebar.png"),
                Artifact(kind = ArtifactKind.SCREENSHOT, path = "sidebar.diff.png"),
            )
    }

    test("every attempt of one case lands in that case, in the order the attempts ended") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val flaky = "FLAKY-1 a requirement that fails its first attempt and passes its second is flaky"
        records.record(
            "run-1",
            Submit(1, flaky, "FLAKY-1", 1, Demonstrates.FAILURE),
            Result(1, 300, "missed", null, listOf(), "", listOf()),
        )
        records.record(
            "run-1",
            Submit(2, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH),
            Result(2, 420, null, null, listOf(), "", listOf()),
        )
        records.record("run-1", Submit(7, flaky, "FLAKY-1", 1, Demonstrates.FAILURE), Result(7, 310, null, null, listOf(), "", listOf()))

        records.ended("run-1", file, retries)

        val cases = TestRun.serializer.fromJsonCode(Files.readString(file)).cases
        cases.map { it.requirement } shouldBe listOf("FLAKY-1", "PROBE-1")
        cases[0].attempts.map { it.outcome } shouldBe listOf(Outcome.createFailed(message = "missed", firstBroken = null), Outcome.PASSED)
    }

    test("the run file states the attempt policy its session ran under") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")

        records.ended("run-1", dir.resolve("retried.json"), retries)
        records.ended("run-2", dir.resolve("repeated.json"), AttemptPolicy(AttemptPolicy.Kind.EXACTLY, 3))

        TestRun.serializer.fromJsonCode(Files.readString(dir.resolve("retried.json"))).attemptPolicy shouldBe
            RunPolicy.RerunFailuresWrapper(4)
        TestRun.serializer.fromJsonCode(Files.readString(dir.resolve("repeated.json"))).attemptPolicy shouldBe
            RunPolicy.ExactlyWrapper(3)
    }

    test("each case says what its requirement declares it demonstrates") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE).forEachIndexed { index, demonstrates ->
            records.record(
                "run-1",
                Submit(index.toLong(), "CASE-$index", "CASE-$index", 1, demonstrates),
                Result(index.toLong(), 1, null, null, listOf(), "", listOf()),
            )
        }

        records.ended("run-1", file, retries)

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .map { it.demonstrates } shouldBe
            listOf(RunDemonstrates.HAPPY_PATH, RunDemonstrates.FAILURE, RunDemonstrates.EDGE_CASE)
    }

    test("an attempt's steps hold the pool's claim and wipe, then what its body did, each with its start and duration") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH),
            Result(
                1,
                120,
                null,
                null,
                listOf(
                    AttemptStep(1_050, 20, "probe Chat[text=Hello]"),
                    AttemptStep(1_070, 100, "window of 10 ticks held at tick 1, stepped 1"),
                ),
                "",
                listOf(),
            ),
            claimed = listOf(AttemptStep(1_000, 30, "claim gv-1"), AttemptStep(1_030, 20, "wipe gv-1 into region (1024, 0)")),
        )

        records.ended("run-1", file, retries)

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .single()
            .attempts
            .single()
            .steps shouldBe
            listOf(
                Step(atMillis = 1_000, actor = null, says = "claim gv-1", durationMillis = 30),
                Step(atMillis = 1_030, actor = null, says = "wipe gv-1 into region (1024, 0)", durationMillis = 20),
                Step(atMillis = 1_050, actor = null, says = "probe Chat[text=Hello]", durationMillis = 20),
                Step(atMillis = 1_070, actor = null, says = "window of 10 ticks held at tick 1, stepped 1", durationMillis = 100),
            )
    }

    test("each run's file holds only that run's attempts") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH),
            Result(1, 420, null, null, listOf(), "", listOf()),
        )
        records.record(
            "run-2",
            Submit(1, "WINDOW-1 a check that never holds fails", "WINDOW-1", 1, Demonstrates.FAILURE),
            Result(1, 900, null, null, listOf(), "", listOf()),
        )

        records.ended("run-2", dir.resolve("run-2.json"), retries)

        TestRun.serializer
            .fromJsonCode(Files.readString(dir.resolve("run-2.json")))
            .cases
            .map { it.requirement } shouldBe listOf("WINDOW-1")
    }

    test("an attempt whose test JVM ended first fails in its run's file, whichever session of the run writes it") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")
        val killed = Submit(3, "PROBE-2 the first input after a far teleport acts there", "PROBE-2", 1, Demonstrates.HAPPY_PATH)
        val gone = Outcome.createFailed(message = "its test JVM ended before the attempt did; see pool.log", firstBroken = null)

        // The sibling session wrote the run file before the killed one left: its leaving writes it again.
        records.record(
            "run-1",
            Submit(1, "SIBLING-1 a second module's requirement reaches its player", "SIBLING-1", 1, Demonstrates.HAPPY_PATH),
            Result(1, 400, null, null, listOf(), "", listOf()),
        )
        records.ended("run-1", dir.resolve("run-1.json"), retries)
        records.abandoned("run-1", listOf(killed), "its test JVM ended before the attempt did; see pool.log")
        // The killed session left first: the sibling's end writes the failure.
        records.abandoned("run-2", listOf(killed), "its test JVM ended before the attempt did; see pool.log")
        records.ended("run-2", dir.resolve("run-2.json"), retries)

        for (file in listOf("run-1.json", "run-2.json")) {
            val cases = TestRun.serializer.fromJsonCode(Files.readString(dir.resolve(file))).cases
            cases.single { it.requirement == "PROBE-2" }.attempts.map { it.outcome } shouldBe listOf(gone)
        }
    }

    test("a player still out at the end of the run is named on the case whose work hung on it") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val hung = "HUNG-1 work still running 1 s after it began fails the attempt"
        records.record(
            "run-1",
            Submit(1, hung, "HUNG-1", 1, Demonstrates.FAILURE),
            Result(1, 1_500, "gv-1's work \"Ledger lookup\" hung", "WorkRequirements.kt:30", listOf(), "", listOf()),
        )
        records.record(
            "run-1",
            Submit(2, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH),
            Result(2, 420, null, null, listOf(), "", listOf()),
        )

        records.ended(
            "run-1",
            file,
            retries,
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
