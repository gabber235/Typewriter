package com.typewritermc.playtest.pool

import build.skir.JsonFlavor
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.Attempt
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.Conclusion
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.LossCause
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Pacing
import skirout.harness.v1.test_run.Part
import skirout.harness.v1.test_run.PartEnd
import skirout.harness.v1.test_run.PartKind
import skirout.harness.v1.test_run.RunEnd
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.test_run.TestCase
import skirout.harness.v1.test_run.TestRun
import skirout.harness.v1.test_run.WindowEnd
import skirout.harness.v1.wire.Result
import skirout.harness.v1.wire.Submit
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * The attempts of [run], the one run the pool serves, written into its [file] under its [policy], naming
 * its [logs] folder relative to the file. Every attempt of one case, a requirement retried or repeated,
 * lands in that case, and a paced attempt among the case's paced attempts. The file also lists every part
 * the game started and how it ended. It is written as the pool takes up the run, over whatever an
 * earlier run left, and again after every attempt and part loss the run records, so a pool that dies
 * leaves the attempts that ended. It reads as cut short until the pool ends the run; it names why the
 * game could not serve the run once it failed, also when that happened before any session joined, and
 * which part's loss stopped it, with the attempts that loss interrupted and the cases that never ran;
 * [stillOut] names, by case, the players hung work keeps out of the pool.
 */
internal class RunRecords(
    private val run: String,
    private val file: Path,
    logs: Path,
    private val policy: AttemptPolicy,
    clock: () -> Long = System::currentTimeMillis,
    private val stillOut: () -> Map<String, String> = { mapOf() },
) {
    private val clock = clock
    private val startedAtMillis = clock()

    /** The logs folder as the run file names it, relative to the file. */
    private val logsFolder =
        file
            .toAbsolutePath()
            .parent
            .relativize(logs.toAbsolutePath())
            .toString()

    private val logsDir = logs.toAbsolutePath()

    private val cases = linkedMapOf<String, TestCase>()

    private val parts = mutableListOf<Part>()

    /** Why the game could not serve the run; null while it could. */
    private var failure: String? = null

    /** How a lost part stopped the run; null while nothing did. */
    private var stop: RunEnd? = null

    /** The submissions whose attempts a lost part interrupted: their own results come too late to count. */
    private val interrupted = mutableSetOf<Long>()

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
        if (submit.submission in interrupted) return
        val outcome = result.failure?.let { Outcome.createFailed(message = it, firstBroken = result.firstBroken) } ?: Outcome.PASSED
        add(
            submit,
            outcome,
            result.durationMillis,
            (claimed + result.steps).sortedBy { it.atMillis },
            result.folder,
            result.artifacts,
            covered,
            result.windows,
        )
        write()
    }

    /**
     * The case [testId] made its last attempt: whether the change [touched] it, what its [pacing] does,
     * and what its session concluded of it, which readers take as its verdict.
     */
    fun concluded(
        testId: String,
        touched: Boolean,
        pacing: Pacing,
        conclusion: Conclusion,
    ) {
        val case = cases[testId] ?: return
        cases[testId] = case.copy(touched = touched, pacing = pacing, conclusion = conclusion)
        write()
    }

    /** The game started the part [name] of [kind], logging into [log]; a part of that name already listed keeps its place. */
    fun started(
        name: String,
        kind: PartKind,
        log: Path,
    ) {
        if (parts.any { it.name == name && it.end == PartEnd.RAN_TO_END }) return
        parts += Part(name = name, kind = kind, log = logName(log), end = PartEnd.RAN_TO_END)
        write()
    }

    /**
     * The part [name] was lost for [cause], other than when an attempt asked for it. A part whose log
     * was [kept] under another name, as a replaced client's, is listed under that name from now on.
     */
    fun lost(
        name: String,
        cause: LossCause,
        kept: Path? = null,
    ) {
        val index = parts.indexOfFirst { it.name == name && it.end == PartEnd.RAN_TO_END }
        if (index < 0) return
        val part = parts[index]
        val log = kept?.let(::logName) ?: part.log
        parts[index] =
            part.copy(
                name = kept?.fileName?.toString()?.removeSuffix(".log") ?: part.name,
                log = log,
                end = PartEnd.createLost(cause = cause, atMillis = clock()),
            )
        write()
    }

    /**
     * The loss of the part [part] stopped the run: each of [interrupted] ran when it happened and ends
     * interrupted, and [notRun] never ran.
     */
    fun stopped(
        part: String,
        interrupted: List<Submit>,
        notRun: List<Submit>,
    ) {
        interrupted.forEach {
            this.interrupted += it.submission
            add(it, Outcome.createInterrupted(part = part), 0, listOf())
        }
        stop = RunEnd.createLost(part = part, notRun = notRun.map { it.testId }.distinct())
        write()
    }

    /** [log] as the run file names a part's log: relative to the logs folder. */
    private fun logName(log: Path): String = logsDir.relativize(log.toAbsolutePath()).toString()

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
        windows: List<WindowEnd> = listOf(),
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
                paceMillis = submit.paceMillis,
                windows = windows,
            )
        val case =
            cases[submit.testId]
                ?: TestCase(
                    id = submit.testId,
                    requirement = submit.requirement,
                    demonstrates = submit.demonstrates,
                    attempts = listOf(),
                    touched = false,
                    paced = listOf(),
                    pacing = Pacing.GATES,
                    // Until its session concludes it, readers judge the case by its attempts.
                    conclusion = null,
                )
        // A paced attempt runs after the case's attempts passed and is never one of them.
        cases[submit.testId] = if (submit.paced) case.copy(paced = case.paced + attempt) else case.copy(attempts = case.attempts + attempt)
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
                // `cargo xtask e2e game` names the commit. The logs folder is named from the start, so a run
                // cut short, as a job that hit its time limit leaves it, still points at its pool log.
                logs = logsFolder,
                end = end,
                parts = parts.toList(),
                // `cargo xtask e2e --demos` marks its demo run once the run is over.
                evidenceOnly = false,
            )
        Files.createDirectories(file.toAbsolutePath().parent)
        val partial = file.resolveSibling("${file.fileName}.partial")
        Files.writeString(partial, TestRun.serializer.toJsonCode(testRun, JsonFlavor.READABLE))
        Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }

    /**
     * How the run ends as its file says now: a part whose loss stopped it, then a game that failed,
     * outweighs the pool's end of the run.
     */
    private val end: RunEnd
        get() = stop ?: failure?.let { RunEnd.CouldNotRunWrapper(it) } ?: if (finished) RunEnd.COMPLETED else RunEnd.CUT_SHORT

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
