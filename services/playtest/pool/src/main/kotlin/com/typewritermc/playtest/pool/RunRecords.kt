package com.typewritermc.playtest.pool

import build.skir.JsonFlavor
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.Attempt
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.RunEnd
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
 * The attempts of [run], the one run the pool serves, written into its [file] under its [policy]. Every
 * attempt of one case, a requirement retried or repeated, lands in that case, and its demo in the case's
 * demo. The file is written as the pool takes up the run, over whatever an earlier run left, and again
 * after every attempt the run records, so a pool that dies leaves the attempts that ended. It reads as
 * cut short until the pool ends the run, and names why the game could not serve the run once it
 * failed, also when that happened before any session joined; [stillOut] names, by case, the players
 * hung work keeps out of the pool.
 */
internal class RunRecords(
    private val run: String,
    private val file: Path,
    private val policy: AttemptPolicy,
    clock: () -> Long = System::currentTimeMillis,
    private val stillOut: () -> Map<String, String> = { mapOf() },
) {
    private val startedAtMillis = clock()
    private val cases = linkedMapOf<String, TestCase>()

    /** Why the game could not serve the run; null while it could. */
    private var failure: String? = null

    /** Whether the pool ended the run, as the build's last tests ended. */
    private var finished = false

    init {
        write()
    }

    /**
     * One attempt of [submit] ended with [result]. Its steps are the pool's own, [claimed] (waiting for
     * its players, their wipe), then what its bodies did; [covered] is the plugin code it ran.
     */
    fun record(
        submit: Submit,
        result: Result,
        claimed: List<Step> = listOf(),
        covered: List<CoveredClass> = listOf(),
    ) {
        val outcome = result.failure?.let { Outcome.createFailed(message = it, firstBroken = result.firstBroken) } ?: Outcome.PASSED
        add(
            submit,
            outcome,
            result.durationMillis,
            (claimed + result.steps).sortedBy { it.atMillis },
            result.folder,
            result.artifacts,
            covered,
        )
        write()
    }

    /** A session left before [unfinished] ended: each gets a failed attempt saying [reason]. */
    fun abandoned(
        unfinished: List<Submit>,
        reason: String,
    ) {
        unfinished.forEach { add(it, Outcome.createFailed(message = reason, firstBroken = null), 0, listOf()) }
        write()
    }

    /** The pool ended the run, every test of the build done: the file reads as complete. */
    fun finished() {
        finished = true
        write()
    }

    /** The game cannot serve the run, for [reason]: its file says so, beside the attempts that ended. */
    fun failed(reason: String) {
        failure = reason
        write()
    }

    private fun add(
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

    /** Writes the run as a `TestRun` into its file. */
    private fun write() {
        val notes = stillOut()
        val testRun =
            TestRun(
                runId = run,
                runner = Runner.GAME,
                commit = "",
                startedAtMillis = startedAtMillis,
                attemptPolicy = policy,
                cases = cases.values.map { case -> notes[case.id]?.let { note -> case.noting(note) } ?: case },
                // `cargo xtask e2e game` names the commit and the run's logs folder, as it chose both.
                logs = "",
                end = end,
            )
        Files.createDirectories(file.toAbsolutePath().parent)
        val partial = file.resolveSibling("${file.fileName}.partial")
        Files.writeString(partial, TestRun.serializer.toJsonCode(testRun, JsonFlavor.READABLE))
        Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }

    /** How the run ends as its file says now: a game that failed outweighs the pool's end of the run. */
    private val end: RunEnd
        get() = failure?.let { RunEnd.CouldNotRunWrapper(it) } ?: if (finished) RunEnd.COMPLETED else RunEnd.CUT_SHORT

    /** This case with [note] joined to each failure. */
    private fun TestCase.noting(note: String): TestCase =
        copy(
            attempts =
                attempts.map { attempt ->
                    val failed = (attempt.outcome as? Outcome.FailedWrapper)?.value ?: return@map attempt
                    attempt.copy(outcome = Outcome.createFailed(message = "${failed.message}\n$note", firstBroken = failed.firstBroken))
                },
        )
}
