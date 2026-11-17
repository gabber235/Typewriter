package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.ArtifactKind
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.RunEnd
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.test_run.TestRun
import skirout.harness.v1.wire.Result
import java.nio.file.Files

val RunRecordsTest by testSuite {
    val retries = AttemptPolicy.RerunFailuresWrapper(4)

    test("a run's file holds each case in the order its first attempt ended, with the failure and its line") {
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        records.joined("session")
        records.record(
            submitted(1, "PROBE-1 a chat line the probe sends reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        records.record(
            submitted(2, "WINDOW-1 a check that never holds fails", Demonstrates.FAILURE),
            Result.partial(
                submission = 2,
                durationMillis = 900,
                failure = "gv-1 did not see chat \"Goodbye\"",
                firstBroken = "WindowRequirements.kt:17",
            ),
        )

        records.ended("session")

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

    test("the frames and golden candidates an attempt wrote land in the run file as its artifacts in its folder") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        records.joined("session")
        records.record(
            submitted(1, "GOLDEN-1 a sidebar matches its golden"),
            Result.partial(
                submission = 1,
                durationMillis = 120,
                failure = "the frame differs from golden sidebar",
                folder = "GOLDEN-1/attempt-1",
                artifacts =
                    listOf(
                        Artifact(kind = ArtifactKind.SCREENSHOT, path = "sidebar.png"),
                        Artifact(kind = ArtifactKind.GOLDEN, path = "sidebar.golden"),
                        Artifact(kind = ArtifactKind.SCREENSHOT, path = "sidebar.diff.png"),
                    ),
            ),
        )

        records.ended("session")

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
                Artifact(kind = ArtifactKind.GOLDEN, path = "sidebar.golden"),
                Artifact(kind = ArtifactKind.SCREENSHOT, path = "sidebar.diff.png"),
            )
    }

    test("a demo lands in its case's demo with its clips, and never counts as an attempt") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        records.joined("session")
        val probe = "PROBE-1 a chat line reaches the player"
        records.record(
            submitted(1, probe),
            Result.partial(submission = 1, durationMillis = 420),
        )
        records.record(
            submitted(2, probe, demo = true),
            Result.partial(
                submission = 2,
                durationMillis = 640,
                folder = "PROBE-1-a-chat-line-reaches-the-player/demo",
                artifacts = listOf(Artifact(kind = ArtifactKind.CLIP, path = "clips/gv-1.mp4")),
            ),
        )

        records.ended("session")

        val case =
            TestRun.serializer
                .fromJsonCode(Files.readString(file))
                .cases
                .single()
        case.attempts.map { it.durationMillis } shouldBe listOf(420L)
        case.demo?.durationMillis shouldBe 640L
        case.demo?.outcome shouldBe Outcome.PASSED
        case.demo?.folder shouldBe "PROBE-1-a-chat-line-reaches-the-player/demo"
        case.demo?.artifacts shouldBe listOf(Artifact(kind = ArtifactKind.CLIP, path = "clips/gv-1.mp4"))
    }

    test("every attempt of one case lands in that case, in the order the attempts ended") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        records.joined("session")
        val flaky = "FLAKY-1 a requirement that fails its first attempt and passes its second is flaky"
        records.record(
            submitted(1, flaky, Demonstrates.FAILURE),
            Result.partial(submission = 1, durationMillis = 300, failure = "missed"),
        )
        records.record(
            submitted(2, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 2, durationMillis = 420),
        )
        records.record(
            submitted(7, flaky, Demonstrates.FAILURE),
            Result.partial(submission = 7, durationMillis = 310),
        )

        records.ended("session")

        val cases = TestRun.serializer.fromJsonCode(Files.readString(file)).cases
        cases.map { it.requirement } shouldBe listOf("FLAKY-1", "PROBE-1")
        cases[0].attempts.map { it.outcome } shouldBe listOf(Outcome.createFailed(message = "missed", firstBroken = null), Outcome.PASSED)
    }

    test("the run file states the attempt policy the run makes its attempts under") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, AttemptPolicy.ExactlyWrapper(3), clock = { 1_000 })

        records.joined("session")
        records.ended("session")

        TestRun.serializer.fromJsonCode(Files.readString(file)).attemptPolicy shouldBe AttemptPolicy.ExactlyWrapper(3)
    }

    test("each case says what its requirement declares it demonstrates") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        records.joined("session")
        listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE).forEachIndexed { index, demonstrates ->
            records.record(
                submitted(index.toLong(), "CASE-$index", demonstrates = demonstrates),
                Result.partial(submission = index.toLong(), durationMillis = 1),
            )
        }

        records.ended("session")

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .map { it.demonstrates } shouldBe
            listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE)
    }

    test("an attempt's steps hold the pool's claim and wipe, then what its body did, each with its start and duration") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        records.joined("session")
        records.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(
                submission = 1,
                durationMillis = 120,
                steps =
                    listOf(
                        Step.partial(atMillis = 1_050, durationMillis = 20, says = "probe Chat[text=Hello]"),
                        Step.partial(atMillis = 1_070, durationMillis = 100, says = "window of 10 ticks held at tick 1, stepped 1"),
                    ),
            ),
            claimed =
                listOf(
                    Step.partial(atMillis = 1_000, durationMillis = 30, says = "claim gv-1"),
                    Step.partial(atMillis = 1_030, durationMillis = 20, says = "wipe gv-1 into region (1024, 0)"),
                ),
        )

        records.ended("session")

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

    test("an attempt whose test JVM ended first fails in its run's file, whichever session of the run writes it") {
        val dir = Files.createTempDirectory("run-records")
        val killed =
            submitted(3, "PROBE-2 the first input after a far teleport acts there")
        val gone = Outcome.createFailed(message = "its test JVM ended before the attempt did; see pool.log", firstBroken = null)
        val siblingEndsFirst = RunRecords("run-1", dir.resolve("run-1.json"), retries, clock = { 1_000 })
        val killedLeavesFirst = RunRecords("run-2", dir.resolve("run-2.json"), retries, clock = { 1_000 })
        listOf(siblingEndsFirst, killedLeavesFirst).forEach { records ->
            records.joined("sibling")
            records.joined("killed")
        }

        // The sibling session ended before the killed one left: its leaving writes the file again.
        siblingEndsFirst.record(
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )
        siblingEndsFirst.ended("sibling")
        siblingEndsFirst.abandoned("killed", listOf(killed), "its test JVM ended before the attempt did; see pool.log")
        // The killed session left first: the file holds the failure from then on.
        killedLeavesFirst.abandoned("killed", listOf(killed), "its test JVM ended before the attempt did; see pool.log")
        killedLeavesFirst.ended("sibling")

        for (file in listOf("run-1.json", "run-2.json")) {
            val cases = TestRun.serializer.fromJsonCode(Files.readString(dir.resolve(file))).cases
            cases.single { it.requirement == "PROBE-2" }.attempts.map { it.outcome } shouldBe listOf(gone)
        }
    }

    test("a player still out at the end of the run is named on the case whose work hung on it") {
        val hung = "HUNG-1 work still running 1 s after it began fails the attempt"
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records =
            RunRecords("run-1", file, retries, clock = { 1_000 }) {
                mapOf(hung to "gv-1 stayed out of the pool for the rest of the run: its work \"Ledger lookup\" never ended.")
            }
        records.joined("session")
        records.record(
            submitted(1, hung, Demonstrates.FAILURE),
            Result.partial(
                submission = 1,
                durationMillis = 1_500,
                failure = "gv-1's work \"Ledger lookup\" hung",
                firstBroken = "WorkRequirements.kt:30",
            ),
        )
        records.record(
            submitted(2, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 2, durationMillis = 420),
        )

        records.ended("session")

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

    test("the run file names its run, holds every attempt so far and reads as cut short until the run's last session ends") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        records.joined("first module")
        records.joined("second module")

        records.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        read().runId shouldBe "run-1"
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1")
        read().end shouldBe RunEnd.CUT_SHORT

        records.ended("first module")
        read().end shouldBe RunEnd.CUT_SHORT

        records.record(
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )
        records.ended("second module")
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        read().end shouldBe RunEnd.COMPLETED
    }

    test("a run the game could not serve says why in its file, even while sessions are open, and keeps the attempts that ended") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, retries, clock = { 1_000 })
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        records.joined("session")
        records.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        records.failed("Paper stopped; see paper.log")
        val whileOpen = read().end
        records.ended("session")

        whileOpen shouldBe RunEnd.CouldNotRunWrapper("Paper stopped; see paper.log")
        read().end shouldBe RunEnd.CouldNotRunWrapper("Paper stopped; see paper.log")
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1")
    }

    test("a later pool of the run takes up the file an earlier pool of it left, and adds its attempts") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        val earlier = RunRecords("run-1", file, retries, clock = { 1_000 })
        earlier.joined("first module")
        earlier.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        earlier.ended("first module")
        read().end shouldBe RunEnd.COMPLETED

        val later = RunRecords("run-1", file, retries, clock = { 9_000 })
        later.continueFrom() shouldBe true
        later.joined("second module")
        // The run goes on, so a pool that dies now leaves a run that was cut short.
        read().end shouldBe RunEnd.CUT_SHORT
        later.record(
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )
        later.ended("second module")

        read().cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        read().startedAtMillis shouldBe 1_000
        read().end shouldBe RunEnd.COMPLETED
    }

    test("a pool takes up no file another run left, and writes its own run over it") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val earlier = RunRecords("run-1", file, retries, clock = { 1_000 })
        earlier.joined("session")
        earlier.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        val other = RunRecords("run-2", file, retries, clock = { 9_000 })
        other.continueFrom() shouldBe false
        other.joined("session")
        other.ended("session")

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.runId shouldBe "run-2"
        run.cases shouldBe listOf()
    }
}
