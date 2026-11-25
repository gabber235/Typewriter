package com.typewritermc.playtest.pool

import com.typewritermc.playtest.launch.PartLimit
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.ArtifactKind
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.Conclusion
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.test_run.LossCause
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Pacing
import skirout.harness.v1.test_run.Part
import skirout.harness.v1.test_run.PartEnd
import skirout.harness.v1.test_run.PartKind
import skirout.harness.v1.test_run.RunEnd
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.test_run.TestRun
import skirout.harness.v1.test_run.WindowEnd
import skirout.harness.v1.wire.Result
import java.nio.file.Files

val RunRecordsTest by testSuite {
    val retries = AttemptPolicy.RerunFailuresWrapper(4)

    test("a run's file holds each case in the order its first attempt ended, with the failure and its line") {
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
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

        records.finished()

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
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
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

        records.finished()

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

    test("a paced attempt lands among its case's paced attempts with its pace and windows, and never counts as an attempt") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        val probe = "PROBE-1 a chat line reaches the player"
        val held = WindowEnd(at = "ProbeRequirements.kt:20", length = 10, heldAt = 1, afterWallClock = false)
        records.record(submitted(1, probe), Result.partial(submission = 1, durationMillis = 420, windows = listOf(held)))
        records.record(
            submitted(2, probe, paceMillis = 50, paced = true),
            Result.partial(submission = 2, durationMillis = 640, windows = listOf(held.copy(heldAt = 3))),
        )

        records.finished()

        val case =
            TestRun.serializer
                .fromJsonCode(Files.readString(file))
                .cases
                .single()
        case.attempts.map { Triple(it.durationMillis, it.paceMillis, it.windows) } shouldBe listOf(Triple(420L, 0, listOf(held)))
        case.paced.map { Triple(it.durationMillis, it.paceMillis, it.windows) } shouldBe
            listOf(Triple(640L, 50, listOf(held.copy(heldAt = 3))))
    }

    test("a concluded case says whether the change touched it, what its pacing does to the verdict, and what the session concluded") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        val probe = "PROBE-1 a chat line reaches the player"
        val session = "GAME-S1 a joined player's session is listed"
        records.record(submitted(1, probe), Result.partial(submission = 1, durationMillis = 420))
        records.record(submitted(2, session), Result.partial(submission = 2, durationMillis = 420))

        val ticks = "attempt 1 at 0 ms held ProbeRequirements.kt:12 at tick 2; at 50 ms held ProbeRequirements.kt:12 at tick 3"
        records.concluded(probe, touched = true, pacing = Pacing.GATES, conclusion = Conclusion.UnsteadyWrapper(ticks))
        records.concluded(session, touched = false, pacing = Pacing.REPORTS, conclusion = Conclusion.PASSED)
        records.finished()

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .map { listOf(it.id, it.touched, it.pacing, it.conclusion) } shouldBe
            listOf(
                listOf(probe, true, Pacing.GATES, Conclusion.UnsteadyWrapper(ticks)),
                listOf(session, false, Pacing.REPORTS, Conclusion.PASSED),
            )
    }

    test(
        "every part the run started is listed with its log, its kind's memory limit and how it ended; a lost client keeps its kept log's name",
    ) {
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        val logs = file.resolveSibling("logs/1")
        val records = RunRecords("run-1", file, logs, retries, clock = { 7_000 })
        records.started("paper", PartKind.SHARED_PAPER, logs.resolve("paper.log"))
        records.started("client-gv-1", PartKind.CLIENT, logs.resolve("client-gv-1.log"))
        records.started("display-gv-1", PartKind.DISPLAY, logs.resolve("display-gv-1.log"))

        records.lost("client-gv-1", LossCause.ExitedWrapper(137), kept = logs.resolve("client-gv-1-lost-1.log"))
        records.started("client-gv-1", PartKind.CLIENT, logs.resolve("client-gv-1.log"))
        records.finished()

        TestRun.serializer.fromJsonCode(Files.readString(file)).parts shouldBe
            listOf(
                Part(
                    name = "paper",
                    kind = PartKind.SHARED_PAPER,
                    log = "paper.log",
                    end = PartEnd.RAN_TO_END,
                    limitBytes = PartLimit.SHARED_PAPER.limitBytes,
                ),
                Part(
                    name = "client-gv-1-lost-1",
                    kind = PartKind.CLIENT,
                    log = "client-gv-1-lost-1.log",
                    end = PartEnd.createLost(cause = LossCause.ExitedWrapper(137), atMillis = 7_000),
                    limitBytes = PartLimit.CLIENT.limitBytes,
                ),
                Part(
                    name = "display-gv-1",
                    kind = PartKind.DISPLAY,
                    log = "display-gv-1.log",
                    end = PartEnd.RAN_TO_END,
                    limitBytes = PartLimit.DISPLAY.limitBytes,
                ),
                Part(
                    name = "client-gv-1",
                    kind = PartKind.CLIENT,
                    log = "client-gv-1.log",
                    end = PartEnd.RAN_TO_END,
                    limitBytes = PartLimit.CLIENT.limitBytes,
                ),
            )
    }

    test(
        "a run a lost part stopped interrupts the attempts that ran, lists the cases still waiting as never run, and ignores their later results",
    ) {
        val file = Files.createTempDirectory("run-records").resolve("results/test_run.json")
        val logs = file.resolveSibling("logs/1")
        val records = RunRecords("run-1", file, logs, retries, clock = { 9_000 })
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        val ran = submitted(1, "PROBE-1 a chat line reaches the player")
        val running = submitted(2, "MOVE-1 a player walks to a block")
        val waiting = submitted(3, "GROUP-1 a line sent to a group reaches each member")
        records.started("paper", PartKind.SHARED_PAPER, logs.resolve("paper.log"))
        records.record(ran, Result.partial(submission = 1, durationMillis = 420))

        records.lost("paper", LossCause.ExitedWrapper(137))
        records.stopped("paper", interrupted = listOf(running), notRun = listOf(waiting))
        records.record(running, Result.partial(submission = 2, durationMillis = 30, failure = "the game cannot run: paper exited"))
        records.finished()

        read().end shouldBe RunEnd.createLost(part = "paper", notRun = listOf("GROUP-1 a line sent to a group reaches each member"))
        read().cases.map { case -> case.id to case.attempts.map { it.outcome } } shouldBe
            listOf(
                "PROBE-1 a chat line reaches the player" to listOf(Outcome.PASSED),
                "MOVE-1 a player walks to a block" to listOf(Outcome.createInterrupted(part = "paper")),
            )
    }

    test("every attempt of one case lands in that case, in the order the attempts ended") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
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

        records.finished()

        val cases = TestRun.serializer.fromJsonCode(Files.readString(file)).cases
        cases.map { it.requirement } shouldBe listOf("FLAKY-1", "PROBE-1")
        cases[0].attempts.map { it.outcome } shouldBe listOf(Outcome.createFailed(message = "missed", firstBroken = null), Outcome.PASSED)
    }

    test("the run file states the attempt policy the run makes its attempts under") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), AttemptPolicy.ExactlyWrapper(3), clock = { 1_000 })

        records.finished()

        TestRun.serializer.fromJsonCode(Files.readString(file)).attemptPolicy shouldBe AttemptPolicy.ExactlyWrapper(3)
    }

    test("each case says what its requirement declares it demonstrates") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE).forEachIndexed { index, demonstrates ->
            records.record(
                submitted(index.toLong(), "CASE-$index", demonstrates = demonstrates),
                Result.partial(submission = index.toLong(), durationMillis = 1),
            )
        }

        records.finished()

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .map { it.demonstrates } shouldBe
            listOf(Demonstrates.HAPPY_PATH, Demonstrates.FAILURE, Demonstrates.EDGE_CASE)
    }

    test("an attempt's steps hold the pool's claim and wipe, then what its body did, each with its start and duration") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
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

        records.finished()

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

    test("an attempt whose test JVM ended first fails in its run's file") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        val killed = submitted(3, "PROBE-2 the first input after a far teleport acts there")

        records.abandoned(listOf(killed), "its test JVM ended before the attempt did; see pool.log")

        TestRun.serializer
            .fromJsonCode(Files.readString(file))
            .cases
            .single()
            .attempts
            .map { it.outcome } shouldBe
            listOf(Outcome.createFailed(message = "its test JVM ended before the attempt did; see pool.log", firstBroken = null))
    }

    test("a player still out at the end of the run is named on the case whose work hung on it") {
        val hung = "HUNG-1 work still running 1 s after it began fails the attempt"
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records =
            RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 }) {
                mapOf(hung to "gv-1 stayed out of the pool for the rest of the run: its work \"Ledger lookup\" never ended.")
            }
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

        records.finished()

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

    test("the run file reads as this run, cut short, from the moment the pool takes it up, over a file an earlier run left") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 }).record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        RunRecords("run-2", file, file.resolveSibling("logs/1"), retries, clock = { 9_000 })

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.runId shouldBe "run-2"
        run.cases shouldBe listOf()
        run.end shouldBe RunEnd.CUT_SHORT
    }

    test("a run cut short names its logs folder beside its file, so the pool log of a run that never ended can be published") {
        val file = Files.createTempDirectory("run-records").resolve("game/test_run.json")

        RunRecords("run-1", file, file.resolveSibling("logs/4"), retries, clock = { 1_000 })

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.end shouldBe RunEnd.CUT_SHORT
        run.logs shouldBe "logs/4"
    }

    test("the run file of a pool that crashed reads cut short and keeps every attempt that ended") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        records.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        // The pool dies here: nothing ends the run.

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.cases.map { it.requirement } shouldBe listOf("PROBE-1")
        run.end shouldBe RunEnd.CUT_SHORT
    }

    test("a run the pool ended reads completed, with every attempt of every module") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        records.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )
        records.record(
            submitted(1, "SIBLING-1 a second module's requirement reaches its player"),
            Result.partial(submission = 1, durationMillis = 400),
        )

        records.finished()

        val run = TestRun.serializer.fromJsonCode(Files.readString(file))
        run.cases.map { it.requirement } shouldBe listOf("PROBE-1", "SIBLING-1")
        run.end shouldBe RunEnd.COMPLETED
    }

    test("a run the game could not serve says why in its file, also once the pool ended it, and keeps the attempts that ended") {
        val file = Files.createTempDirectory("run-records").resolve("test_run.json")
        val records = RunRecords("run-1", file, file.resolveSibling("logs/1"), retries, clock = { 1_000 })
        val read = { TestRun.serializer.fromJsonCode(Files.readString(file)) }
        records.record(
            submitted(1, "PROBE-1 a chat line reaches the player"),
            Result.partial(submission = 1, durationMillis = 420),
        )

        records.failed("Paper stopped; see paper.log")
        val whileRunning = read().end
        records.finished()

        whileRunning shouldBe RunEnd.CouldNotRunWrapper("Paper stopped; see paper.log")
        read().end shouldBe RunEnd.CouldNotRunWrapper("Paper stopped; see paper.log")
        read().cases.map { it.requirement } shouldBe listOf("PROBE-1")
    }
}
