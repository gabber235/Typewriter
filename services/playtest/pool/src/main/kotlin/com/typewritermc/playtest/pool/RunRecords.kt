package com.typewritermc.playtest.pool

import build.skir.JsonFlavor
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.Attempt
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.test_run.TestCase
import skirout.harness.v1.test_run.TestRun
import skirout.harness.v1.wire.Result
import skirout.harness.v1.wire.Submit
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * The attempts of every run the pool served, kept per run id. Every attempt of one case, a requirement
 * retried or repeated, lands in that case, and its demo in the case's demo. Each session names its
 * run's file as it joins, and the file is written again after every attempt the run records, so a
 * pool that dies leaves the attempts that ended. It reads as cut short while a session of the run is
 * open, and names why the game could not serve the run once it failed; [stillOut] names the players
 * each run's hung work keeps out of the pool. A later pool of the same run takes up the file an
 * earlier one left ([continueFrom]).
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
        var policy: AttemptPolicy? = null

        /** Why the game could not serve the run; empty while it could. */
        var failure = ""

        /** The sessions of the run that joined and have neither ended nor left. */
        val open = mutableSetOf<Any>()
    }

    private val runs = mutableMapOf<String, Run>()

    /**
     * [session] joined [run], naming its [file] and [policy]; the run starts with its first session, and
     * its file reads as cut short from then until its last session ended.
     * Returns why the session is refused when the run's first session named another file or policy.
     */
    fun joined(
        run: String,
        session: Any,
        file: Path,
        policy: AttemptPolicy,
    ): String? {
        val record = runOf(run)
        val named = record.file
        val ranUnder = record.policy
        if ((named != null && named != file) || (ranUnder != null && ranUnder != policy)) {
            return "this session names the run file $file under ${policy.said}, but run $run writes $named under " +
                "${ranUnder?.said}: every session of a run names the same file and policy"
        }
        record.file = file
        record.policy = policy
        record.open += session
        // The run goes on again, as when a later module's session joins after the others ended.
        write(run)
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
        claimed: List<Step> = listOf(),
        covered: List<CoveredClass> = listOf(),
    ) {
        val outcome = result.failure?.let { Outcome.createFailed(message = it, firstBroken = result.firstBroken) } ?: Outcome.PASSED
        add(
            run,
            submit,
            outcome,
            result.durationMillis,
            (claimed + result.steps).sortedBy { it.atMillis },
            result.folder,
            result.artifacts,
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

    /** The game cannot serve [run], for [reason]: its file says so, beside the attempts that ended. */
    fun failed(
        run: String,
        reason: String,
    ) {
        runOf(run).failure = reason
        write(run)
    }

    /**
     * Takes up [run] where an earlier pool of it left [file], as when that pool stopped before a later
     * module's tests started, so this pool adds to the run instead of starting it over. Returns whether
     * [file] held [run]; a file of another run is written over once this run records something.
     */
    fun continueFrom(
        run: String,
        file: Path,
    ): Boolean {
        if (!Files.exists(file)) return false
        val earlier = TestRun.serializer.fromJsonCode(Files.readString(file))
        if (earlier.runId != run) return false
        val record = Run(earlier.startedAtMillis)
        earlier.cases.forEach { record.cases[it.id] = it }
        record.file = file
        record.policy = earlier.attemptPolicy
        record.failure = earlier.failure
        runs[run] = record
        return true
    }

    private fun runOf(run: String): Run = runs.getOrPut(run) { Run(clock()) }

    private fun add(
        run: String,
        submit: Submit,
        outcome: Outcome,
        durationMillis: Long,
        steps: List<Step>,
        folder: String = "",
        artifacts: List<Artifact> = listOf(),
        covered: List<CoveredClass> = listOf(),
    ) {
        val attempt =
            Attempt(
                outcome = outcome,
                span = null,
                durationMillis = durationMillis,
                artifacts = artifacts,
                folder = folder,
                steps = steps,
                taps = listOf(),
                covered = covered,
            )
        val cases = runOf(run).cases
        val case =
            cases[submit.testId]
                ?: TestCase(
                    id = submit.testId,
                    requirement = submit.requirement,
                    demonstrates = submit.demonstrates,
                    attempts = listOf(),
                    demo = null,
                )
        // A demo runs after the case's last attempt and is never one of its attempts.
        cases[submit.testId] = if (submit.demo) case.copy(demo = attempt) else case.copy(attempts = case.attempts + attempt)
    }

    /** Writes [run] as a `TestRun` into the file its sessions named, once one did. */
    private fun write(run: String) {
        val record = runOf(run)
        val file = record.file ?: return
        val policy = record.policy ?: return
        val notes = stillOut(run)
        val testRun =
            TestRun(
                runId = run,
                runner = Runner.GAME,
                commit = "",
                startedAtMillis = record.startedAtMillis,
                attemptPolicy = policy,
                cases = record.cases.values.map { case -> notes[case.id]?.let { note -> case.noting(note) } ?: case },
                // `cargo xtask e2e game` names the commit and the run's logs folder, as it chose both.
                logs = "",
                failure = record.failure,
                cutShort = record.open.isNotEmpty(),
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

    private val AttemptPolicy.said: String
        get() =
            when (this) {
                is AttemptPolicy.RerunFailuresWrapper -> "reruns up to $value attempts"
                is AttemptPolicy.ExactlyWrapper -> "exactly $value attempts"
                else -> "an attempt policy this pool does not know ($this)"
            }
}
