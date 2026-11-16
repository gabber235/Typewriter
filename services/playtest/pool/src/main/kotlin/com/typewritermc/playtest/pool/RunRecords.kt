package com.typewritermc.playtest.pool

import build.skir.JsonFlavor
import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Submit
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.ArtifactKind
import skirout.harness.v1.test_run.Attempt
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.test_run.TestCase
import skirout.harness.v1.test_run.TestRun
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * The attempts of every run the pool served, kept per run id. Every attempt of one case, a requirement
 * retried or repeated, lands in that case, and its demo in the case's demo. A session's end writes its run's file, and the file is
 * written again whenever a later session of the run ends or leaves without ending, so the last file
 * holds every attempt the run made.
 */
internal class RunRecords(
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private class Run(
        val startedAtMillis: Long,
    ) {
        val cases = linkedMapOf<String, TestCase>()

        /** Where the run's file goes and how its attempts were made, once a session of the run ended. */
        var file: Path? = null
        var policy: Message.AttemptPolicy? = null
    }

    private val runs = mutableMapOf<String, Run>()

    /** A session of [run] joined; the run starts with its first session. */
    fun started(run: String) {
        runOf(run)
    }

    /**
     * One attempt of [submit] ended with [result]. Its steps are the pool's own, [claimed] (waiting for
     * its players, their wipe), then what its bodies did; [covered] is the plugin code it ran.
     */
    fun record(
        run: String,
        submit: Submit,
        result: Result,
        claimed: List<AttemptStep> = listOf(),
        covered: List<Message.CoveredClass> = listOf(),
    ) {
        val outcome = result.failure()?.let { Outcome.createFailed(message = it, firstBroken = result.firstBroken()) } ?: Outcome.PASSED
        add(
            run,
            submit,
            outcome,
            result.durationMillis(),
            (claimed + result.steps()).sortedBy { it.atMillis() },
            result.folder(),
            result.screenshots(),
            result.clips(),
            covered,
        )
    }

    /**
     * A session of [run] left before [unfinished] ended: each gets a failed attempt saying [reason], and
     * the run's file is written again once a session of the run named it.
     */
    fun abandoned(
        run: String,
        unfinished: List<Submit>,
        reason: String,
        stillOut: Map<String, String> = mapOf(),
    ) {
        unfinished.forEach { add(run, it, Outcome.createFailed(message = reason, firstBroken = null), 0, listOf()) }
        val record = runOf(run)
        val file = record.file ?: return
        val policy = record.policy ?: return
        write(record, file, policy, stillOut)
    }

    /**
     * A session of [run] ended: writes the run, made under [policy], as a `TestRun` into [file],
     * replacing what an earlier session of the run wrote. Each note in [stillOut] joins the failure of
     * the case its test id names: a player that case's hung work keeps out of the pool.
     */
    fun ended(
        run: String,
        file: Path,
        policy: Message.AttemptPolicy,
        stillOut: Map<String, String> = mapOf(),
    ) {
        val record = runOf(run)
        record.file = file
        record.policy = policy
        write(record, file, policy, stillOut)
    }

    private fun runOf(run: String): Run = runs.getOrPut(run) { Run(clock()) }

    private fun add(
        run: String,
        submit: Submit,
        outcome: Outcome,
        durationMillis: Long,
        steps: List<AttemptStep>,
        folder: String = "",
        screenshots: List<String> = listOf(),
        clips: List<String> = listOf(),
        covered: List<Message.CoveredClass> = listOf(),
    ) {
        val attempt =
            Attempt(
                outcome = outcome,
                span = null,
                durationMillis = durationMillis,
                artifacts =
                    screenshots.map { Artifact(kind = ArtifactKind.SCREENSHOT, path = it) } +
                        clips.map { Artifact(kind = ArtifactKind.CLIP, path = it) },
                folder = folder,
                steps = steps.map { Step(atMillis = it.atMillis(), actor = null, says = it.says(), durationMillis = it.durationMillis()) },
                taps = listOf(),
                covered = covered.map { CoveredClass(name = it.name(), source = it.source(), lines = it.lines()) },
            )
        val cases = runOf(run).cases
        val case =
            cases[submit.testId()]
                ?: TestCase(
                    id = submit.testId(),
                    requirement = submit.requirement(),
                    demonstrates = submit.demonstrates().inRun,
                    attempts = listOf(),
                    demo = null,
                )
        // A demo runs after the case's last attempt and is never one of its attempts.
        cases[submit.testId()] = if (submit.demo()) case.copy(demo = attempt) else case.copy(attempts = case.attempts + attempt)
    }

    private fun write(
        record: Run,
        file: Path,
        policy: Message.AttemptPolicy,
        stillOut: Map<String, String>,
    ) {
        val testRun =
            TestRun(
                runner = Runner.GAME,
                commit = "",
                startedAtMillis = record.startedAtMillis,
                attemptPolicy = policy.inRun,
                cases = record.cases.values.map { case -> stillOut[case.id]?.let { note -> case.noting(note) } ?: case },
            )
        Files.createDirectories(file.toAbsolutePath().parent)
        val partial = file.resolveSibling("${file.fileName}.partial")
        Files.writeString(partial, TestRun.serializer.toJsonCode(testRun, JsonFlavor.READABLE))
        Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }

    /** This case with [note] joined to each failure. */
    private fun TestCase.noting(note: String): TestCase =
        copy(
            attempts =
                attempts.map { attempt ->
                    val failed = (attempt.outcome as? Outcome.FailedWrapper)?.value ?: return@map attempt
                    attempt.copy(outcome = Outcome.createFailed(message = "${failed.message}\n$note", firstBroken = failed.firstBroken))
                },
        )

    private val Message.Demonstrates.inRun: Demonstrates
        get() =
            when (this) {
                Message.Demonstrates.HAPPY_PATH -> Demonstrates.HAPPY_PATH
                Message.Demonstrates.FAILURE -> Demonstrates.FAILURE
                Message.Demonstrates.EDGE_CASE -> Demonstrates.EDGE_CASE
            }

    private val Message.AttemptPolicy.inRun: AttemptPolicy
        get() =
            when (kind()) {
                Message.AttemptPolicy.Kind.RERUN_FAILURES -> AttemptPolicy.RerunFailuresWrapper(attempts())
                Message.AttemptPolicy.Kind.EXACTLY -> AttemptPolicy.ExactlyWrapper(attempts())
            }
}
