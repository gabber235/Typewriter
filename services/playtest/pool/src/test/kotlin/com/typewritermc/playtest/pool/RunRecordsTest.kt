package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message.AttemptPolicy
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.Demonstrates
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Submit
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
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
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
        )
        records.record(
            "run-1",
            Submit(2, "WINDOW-1 a check that never holds fails", "WINDOW-1", 1, Demonstrates.FAILURE, false, false),
            Result(2, 900, "gv-1 did not see chat \"Goodbye\"", "WindowRequirements.kt:17", listOf(), "", listOf(), listOf()),
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

    test("the frames an attempt wrote land in the run file as screenshots in the attempt's folder") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            Submit(1, "GOLDEN-1 a sidebar matches its golden", "GOLDEN-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(
                1,
                120,
                "the frame differs from golden sidebar",
                null,
                listOf(),
                "GOLDEN-1/attempt-1",
                listOf("sidebar.png", "sidebar.diff.png"),
                listOf(),
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
            Submit(1, probe, "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
        )
        records.record(
            "run-1",
            Submit(2, probe, "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, true),
            Result(2, 640, null, null, listOf(), "PROBE-1-a-chat-line-reaches-the-player/demo", listOf(), listOf("clips/gv-1.mp4")),
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
            Submit(1, flaky, "FLAKY-1", 1, Demonstrates.FAILURE, false, false),
            Result(1, 300, "missed", null, listOf(), "", listOf(), listOf()),
        )
        records.record(
            "run-1",
            Submit(2, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(2, 420, null, null, listOf(), "", listOf(), listOf()),
        )
        records.record(
            "run-1",
            Submit(7, flaky, "FLAKY-1", 1, Demonstrates.FAILURE, false, false),
            Result(7, 310, null, null, listOf(), "", listOf(), listOf()),
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
        records.joined("run-2", "repeating", dir.resolve("repeated.json"), AttemptPolicy(AttemptPolicy.Kind.EXACTLY, 3))
        records.ended("run-1", "retrying")
        records.ended("run-2", "repeating")

        TestRun.serializer.fromJsonCode(Files.readString(dir.resolve("retried.json"))).attemptPolicy shouldBe
            RunPolicy.RerunFailuresWrapper(4)
        TestRun.serializer.fromJsonCode(Files.readString(dir.resolve("repeated.json"))).attemptPolicy shouldBe
            RunPolicy.ExactlyWrapper(3)
    }

    test("each case says what its requirement declares it demonstrates") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE).forEachIndexed { index, demonstrates ->
            records.record(
                "run-1",
                Submit(index.toLong(), "CASE-$index", "CASE-$index", 1, demonstrates, false, false),
                Result(index.toLong(), 1, null, null, listOf(), "", listOf(), listOf()),
            )
        }

        records.ended("run-1", "session")

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .map { it.demonstrates } shouldBe
            listOf(RunDemonstrates.HAPPY_PATH, RunDemonstrates.FAILURE, RunDemonstrates.EDGE_CASE)
    }

    test("an attempt's steps hold the pool's claim and wipe, then what its body did, each with its start and duration") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
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
                listOf(),
            ),
            claimed = listOf(AttemptStep(1_000, 30, "claim gv-1"), AttemptStep(1_030, 20, "wipe gv-1 into region (1024, 0)")),
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
            Submit(1, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
        )
        records.record(
            "run-2",
            Submit(1, "WINDOW-1 a check that never holds fails", "WINDOW-1", 1, Demonstrates.FAILURE, false, false),
            Result(1, 900, null, null, listOf(), "", listOf(), listOf()),
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
            Submit(3, "PROBE-2 the first input after a far teleport acts there", "PROBE-2", 1, Demonstrates.HAPPY_PATH, false, false)
        val gone = Outcome.createFailed(message = "its test JVM ended before the attempt did; see pool.log", firstBroken = null)

        listOf("run-1", "run-2").forEach { run ->
            records.joined(run, "sibling", dir.resolve("$run.json"), retries)
            records.joined(run, "killed", dir.resolve("$run.json"), retries)
        }
        // The sibling session ended before the killed one left: its leaving writes the file again.
        records.record(
            "run-1",
            Submit(1, "SIBLING-1 a second module's requirement reaches its player", "SIBLING-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 400, null, null, listOf(), "", listOf(), listOf()),
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
            Submit(1, hung, "HUNG-1", 1, Demonstrates.FAILURE, false, false),
            Result(1, 1_500, "gv-1's work \"Ledger lookup\" hung", "WorkRequirements.kt:30", listOf(), "", listOf(), listOf()),
        )
        records.record(
            "run-1",
            Submit(2, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(2, 420, null, null, listOf(), "", listOf(), listOf()),
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
            Submit(1, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
        )
        read().runId shouldBe "run-1"
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1")
        read().cutShort shouldBe true

        records.ended("run-1", "first module")
        read().cutShort shouldBe true

        records.record(
            "run-1",
            Submit(1, "SIBLING-1 a second module's requirement reaches its player", "SIBLING-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 400, null, null, listOf(), "", listOf(), listOf()),
        )
        records.ended("run-1", "second module")
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        read().cutShort shouldBe false
        read().failure shouldBe ""
    }

    test("a run the game could not serve says why in its file and keeps the attempts that ended before") {
        val records = RunRecords(clock = { 1_000 })
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        records.joined("run-1", "session", file, retries)
        records.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
        )

        records.failed("run-1", "Paper stopped; see paper.log")
        records.ended("run-1", "session")

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.failure shouldBe "Paper stopped; see paper.log"
        run.cases.map { it.requirement } shouldBe listOf("PROBE-1")
        run.cutShort shouldBe false
    }

    test("a later pool of the run takes up the file an earlier pool of it left, and adds its attempts") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        val earlier = RunRecords(clock = { 1_000 })
        earlier.joined("run-1", "first module", file, retries)
        earlier.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
        )
        earlier.ended("run-1", "first module")
        read().cutShort shouldBe false

        val later = RunRecords(clock = { 9_000 })
        later.continueFrom("run-1", file) shouldBe true
        later.joined("run-1", "second module", file, retries) shouldBe null
        // The run goes on, so a pool that dies now leaves a run that was cut short.
        read().cutShort shouldBe true
        later.record(
            "run-1",
            Submit(1, "SIBLING-1 a second module's requirement reaches its player", "SIBLING-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 400, null, null, listOf(), "", listOf(), listOf()),
        )
        later.ended("run-1", "second module")

        read().cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        read().startedAtMillis shouldBe 1_000
        read().cutShort shouldBe false
    }

    test("a pool takes up no file another run left, and writes its own run over it") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val earlier = RunRecords(clock = { 1_000 })
        earlier.joined("run-1", "session", file, retries)
        earlier.record(
            "run-1",
            Submit(1, "PROBE-1 a chat line reaches the player", "PROBE-1", 1, Demonstrates.HAPPY_PATH, false, false),
            Result(1, 420, null, null, listOf(), "", listOf(), listOf()),
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
        val repeated = records.joined("run-1", "repeated", file, AttemptPolicy(AttemptPolicy.Kind.EXACTLY, 3))

        elsewhere.shouldNotBeNull() shouldContain "$file"
        elsewhere shouldContain "${dir.resolve("other.json")}"
        repeated.shouldNotBeNull() shouldContain "exactly 3"
        // A refused session never joined the run, so the first session's end ends it.
        records.ended("run-1", "first")
        TestRun.serializer.fromJsonCode(Files.readString(file)).cutShort shouldBe false
    }
}
