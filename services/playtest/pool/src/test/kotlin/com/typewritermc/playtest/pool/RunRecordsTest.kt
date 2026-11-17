package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
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
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            submitted(1, "PROBE-1 a chat line the probe sends reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        records.record(
            "run-1",
            submitted(2, "WINDOW-1 a check that never holds fails", Demonstrates.FAILURE),
            Result.partial(
                submission = 2,
                durationMillis = 900,
                failure = "gv-1 did not see chat \"Goodbye\"",
                firstBroken = "WindowRequirements.kt:17",
            ),
        )

        records.ended("run-1", "session")

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
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
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

        records.ended("run-1", "session")

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
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        val probe = "PROBE-1 a chat line reaches the player"
        records.record(
            "run-1",
            submitted(1, probe),
            Result.partial(submission = 1, durationMillis = 420),
        )
        records.record(
            "run-1",
            submitted(2, probe, demo = true),
            Result.partial(
                submission = 2,
                durationMillis = 640,
                folder = "PROBE-1-a-chat-line-reaches-the-player/demo",
                artifacts = listOf(Artifact(kind = ArtifactKind.CLIP, path = "clips/gv-1.mp4")),
            ),
        )

        records.ended("run-1", "session")

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
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        val flaky = "FLAKY-1 a requirement that fails its first attempt and passes its second is flaky"
        records.record(
            "run-1",
            submitted(1, flaky, Demonstrates.FAILURE),
            Result.partial(submission = 1, durationMillis = 300, failure = "missed"),
        )
        records.record(
            "run-1",
            submitted(2, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 2, durationMillis = 420),
        )
        records.record(
            "run-1",
            submitted(7, flaky, Demonstrates.FAILURE),
            Result.partial(submission = 7, durationMillis = 310),
        )

        records.ended("run-1", "session")

        val cases = TestRun.serializer.fromJsonCode(Files.readString(file)).cases
        cases.map { it.requirement } shouldBe listOf("FLAKY-1", "PROBE-1")
        cases[0].attempts.map { it.outcome } shouldBe listOf(Outcome.createFailed(message = "missed", firstBroken = null), Outcome.PASSED)
    }

    test("the run file states the attempt policy its session ran under") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")

        records.joined("run-1", "retrying", dir.resolve("retried.json"), retries)
        records.joined("run-2", "repeating", dir.resolve("repeated.json"), AttemptPolicy.ExactlyWrapper(3))
        records.ended("run-1", "retrying")
        records.ended("run-2", "repeating")

        TestRun.serializer.fromJsonCode(Files.readString(dir.resolve("retried.json"))).attemptPolicy shouldBe
            AttemptPolicy.RerunFailuresWrapper(4)
        TestRun.serializer.fromJsonCode(Files.readString(dir.resolve("repeated.json"))).attemptPolicy shouldBe
            AttemptPolicy.ExactlyWrapper(3)
    }

    test("each case says what its requirement declares it demonstrates") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE).forEachIndexed { index, demonstrates ->
            records.record(
                "run-1",
                submitted(index.toLong(), "CASE-$index", demonstrates = demonstrates),
                Result.partial(submission = index.toLong(), durationMillis = 1),
            )
        }

        records.ended("run-1", "session")

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .map { it.demonstrates } shouldBe
            listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE)
    }

    test("an attempt's steps hold the pool's claim and wipe, then what its body did, each with its start and duration") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
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

        records.ended("run-1", "session")

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
        records.joined("run-1", "first", dir.resolve("run-1.json"), retries)
        records.joined("run-2", "second", dir.resolve("run-2.json"), retries)
        records.record(
            "run-1",
            submitted(1, "PROBE-1 a chat line the probe sends reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        records.record(
            "run-2",
            submitted(1, "WINDOW-1 a check that never holds fails", Demonstrates.FAILURE),
            Result.partial(submission = 1, durationMillis = 900),
        )

        records.ended("run-2", "second")

        TestRun.serializer
            .fromJsonCode(Files.readString(dir.resolve("run-2.json")))
            .cases
            .map { it.requirement } shouldBe listOf("WINDOW-1")
    }

    test("an attempt whose test JVM ended first fails in its run's file, whichever session of the run writes it") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")
        val killed =
            submitted(3, "PROBE-2 the first input after a far teleport acts there")
        val gone = Outcome.createFailed(message = "its test JVM ended before the attempt did; see pool.log", firstBroken = null)

        listOf("run-1", "run-2").forEach { run ->
            records.joined(run, "sibling", dir.resolve("$run.json"), retries)
            records.joined(run, "killed", dir.resolve("$run.json"), retries)
        }
        // The sibling session ended before the killed one left: its leaving writes the file again.
        records.record(
            "run-1",
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )
        records.ended("run-1", "sibling")
        records.abandoned("run-1", "killed", listOf(killed), "its test JVM ended before the attempt did; see pool.log")
        // The killed session left first: the file holds the failure from then on.
        records.abandoned("run-2", "killed", listOf(killed), "its test JVM ended before the attempt did; see pool.log")
        records.ended("run-2", "sibling")

        for (file in listOf("run-1.json", "run-2.json")) {
            val cases = TestRun.serializer.fromJsonCode(Files.readString(dir.resolve(file))).cases
            cases.single { it.requirement == "PROBE-2" }.attempts.map { it.outcome } shouldBe listOf(gone)
        }
    }

    test("a player still out at the end of the run is named on the case whose work hung on it") {
        val hung = "HUNG-1 work still running 1 s after it began fails the attempt"
        val records =
            RunRecords(clock = { 1_000 }) { run ->
                mapOf(hung to "gv-1 stayed out of the pool for the rest of $run: its work \"Ledger lookup\" never ended.").filter {
                    run ==
                        "run-1"
                }
            }
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            submitted(1, hung, Demonstrates.FAILURE),
            Result.partial(
                submission = 1,
                durationMillis = 1_500,
                failure = "gv-1's work \"Ledger lookup\" hung",
                firstBroken = "WorkRequirements.kt:30",
            ),
        )
        records.record(
            "run-1",
            submitted(2, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 2, durationMillis = 420),
        )

        records.ended("run-1", "session")

        val cases = TestRun.serializer.fromJsonCode(Files.readString(file)).cases
        cases[0].attempts.single().outcome shouldBe
            Outcome.createFailed(
                message =
                    "gv-1's work \"Ledger lookup\" hung\n" +
                        "gv-1 stayed out of the pool for the rest of run-1: its work \"Ledger lookup\" never ended.",
                firstBroken = "WorkRequirements.kt:30",
            )
        cases[1].attempts.single().outcome shouldBe Outcome.PASSED
    }

    test("the run file names its run, holds every attempt so far and reads as cut short until the run's last session ends") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        records.joined("run-1", "first module", file, retries)
        records.joined("run-1", "second module", file, retries)

        records.record(
            "run-1",
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        read().runId shouldBe "run-1"
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1")
        read().end shouldBe RunEnd.CUT_SHORT

        records.ended("run-1", "first module")
        read().end shouldBe RunEnd.CUT_SHORT

        records.record(
            "run-1",
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )
        records.ended("run-1", "second module")
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        read().end shouldBe RunEnd.COMPLETED
    }

    test("a run the game could not serve says why in its file, even while sessions are open, and keeps the attempts that ended") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        records.failed("run-1", "Paper stopped; see paper.log")
        val whileOpen = read().end
        records.ended("run-1", "session")

        whileOpen shouldBe RunEnd.CouldNotRunWrapper("Paper stopped; see paper.log")
        read().end shouldBe RunEnd.CouldNotRunWrapper("Paper stopped; see paper.log")
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1")
    }

    test("a later pool of the run takes up the file an earlier pool of it left, and adds its attempts") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        val earlier = RunRecords(clock = { 1_000 })
        earlier.joined("run-1", "first module", file, retries)
        earlier.record(
            "run-1",
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        earlier.ended("run-1", "first module")
        read().end shouldBe RunEnd.COMPLETED

        val later = RunRecords(clock = { 9_000 })
        later.continueFrom("run-1", file) shouldBe true
        later.joined("run-1", "second module", file, retries) shouldBe null
        // The run goes on, so a pool that dies now leaves a run that was cut short.
        read().end shouldBe RunEnd.CUT_SHORT
        later.record(
            "run-1",
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )
        later.ended("run-1", "second module")

        read().cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        read().startedAtMillis shouldBe 1_000
        read().end shouldBe RunEnd.COMPLETED
    }

    test("a pool takes up no file another run left, and writes its own run over it") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val earlier = RunRecords(clock = { 1_000 })
        earlier.joined("run-1", "session", file, retries)
        earlier.record(
            "run-1",
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        val other = RunRecords(clock = { 9_000 })
        other.continueFrom("run-2", file) shouldBe false
        other.joined("run-2", "session", file, retries)
        other.ended("run-2", "session")

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.runId shouldBe "run-2"
        run.cases shouldBe listOf()
    }

    test("a session that names another run file or attempt policy than its run's first session is refused") {
        val records = RunRecords(clock = { 1_000 })
        val dir = Files.createTempDirectory("run-records")
        val file = dir.resolve("test_run.json")

        records.joined("run-1", "first", file, retries) shouldBe null
        val elsewhere = records.joined("run-1", "elsewhere", dir.resolve("other.json"), retries)
        val repeated = records.joined("run-1", "repeated", file, AttemptPolicy.ExactlyWrapper(3))

        elsewhere.shouldNotBeNull() shouldContain "$file"
        elsewhere shouldContain "${dir.resolve("other.json")}"
        repeated.shouldNotBeNull() shouldContain "exactly 3"
        // A refused session never joined the run, so the first session's end ends it.
        records.ended("run-1", "first")
        TestRun.serializer.fromJsonCode(Files.readString(file)).end shouldBe RunEnd.COMPLETED
    }
}
