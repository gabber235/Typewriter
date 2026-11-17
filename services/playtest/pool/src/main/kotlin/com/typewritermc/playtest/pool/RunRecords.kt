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
 * retried or repeated, lands in that case, and its demo in the case's demo. Each session names its
 * run's file as it joins, and the file is written again after every attempt the run records, so a
 * pool that dies leaves the attempts that ended. It reads as ended once every session of the run
 * ended or left; [stillOut] names the players each run's hung work keeps out of the pool.
 */
internal class RunRecords(
    private val clock: () -> Long = System::currentTimeMillis,
    private val stillOut: (run: String) -> Map<String, String> = { mapOf() },
) {
    private class Run(
        val startedAtMillis: Long,
    ) {
        val cases = linkedMapOf<String, TestCase>()

        /** Where the run's file goes and how its attempts are made, as its first session named them. */
        var file: Path? = null
        var policy: Message.AttemptPolicy? = null

        /** The sessions of the run that joined and have neither ended nor left. */
        val open = mutableSetOf<Any>()
    }

    private val runs = mutableMapOf<String, Run>()

    /**
     * [session] joined [run], naming its [file] and [policy]; the run starts with its first session.
     * Returns why the session is refused when the run's first session named another file or policy.
     */
    fun joined(
        run: String,
        session: Any,
        file: Path,
        policy: Message.AttemptPolicy,
    ): String? {
        val record = runOf(run)
        val named = record.file
        if (named != null && (named != file || record.policy != policy)) {
            return "this session names the run file $file under ${policy.said}, but run $run writes $named under " +
                "${record.policy?.said}: every session of a run names the same file and policy"
        }
        record.file = file
        record.policy = policy
        record.open += session
        return null
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
        write(run)
    }

    /** [session] left before [unfinished] ended: each gets a failed attempt saying [reason]. */
    fun abandoned(
        run: String,
        session: Any,
        unfinished: List<Submit>,
        reason: String,
    ) {
        unfinished.forEach { add(run, it, Outcome.createFailed(message = reason, firstBroken = null), 0, listOf()) }
        runOf(run).open -= session
        write(run)
    }

    /** [session] of [run] ended. */
    fun ended(
        run: String,
        session: Any,
    ) {
        runOf(run).open -= session
        write(run)
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

    /** Writes [run] as a `TestRun` into the file its sessions named, once one did. */
    private fun write(run: String) {
        val record = runOf(run)
        val file = record.file ?: return
        val policy = record.policy ?: return
        val notes = stillOut(run)
        val testRun =
            TestRun(
                runner = Runner.GAME,
                commit = "",
                startedAtMillis = record.startedAtMillis,
                attemptPolicy = policy.inRun,
                cases = record.cases.values.map { case -> notes[case.id]?.let { note -> case.noting(note) } ?: case },
                // `cargo xtask e2e game` names the commit and the run's logs folder, as it chose both.
                logs = "",
                ended = record.open.isEmpty(),
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

    private val Message.AttemptPolicy.said: String
        get() =
            when (kind()) {
                Message.AttemptPolicy.Kind.RERUN_FAILURES -> "reruns up to ${attempts()} attempts"
                Message.AttemptPolicy.Kind.EXACTLY -> "exactly ${attempts()} attempts"
            }

    private val Message.AttemptPolicy.inRun: AttemptPolicy
        get() =
            when (kind()) {
                Message.AttemptPolicy.Kind.RERUN_FAILURES -> AttemptPolicy.RerunFailuresWrapper(attempts())
                Message.AttemptPolicy.Kind.EXACTLY -> AttemptPolicy.ExactlyWrapper(attempts())
            }
}
