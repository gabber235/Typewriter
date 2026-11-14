package com.typewritermc.playtest.pool

import build.skir.JsonFlavor
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Submit
import skirout.harness.v1.test_run.Attempt
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.test_run.Outcome
import skirout.harness.v1.test_run.Runner
import skirout.harness.v1.test_run.TestCase
import skirout.harness.v1.test_run.TestRun
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/** The attempts of every run the pool served, kept per run id until the run's session asks for its file. */
internal class RunRecords(
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private class Run(
        val startedAtMillis: Long,
    ) {
        val cases = mutableListOf<TestCase>()
    }

    private val runs = mutableMapOf<String, Run>()

    /** A session of [run] joined; the run starts with its first session. */
    fun started(run: String) {
        runs.getOrPut(run) { Run(clock()) }
    }

    fun record(
        run: String,
        submit: Submit,
        result: Result,
    ) {
        val outcome = result.failure()?.let { Outcome.createFailed(message = it, firstBroken = result.firstBroken()) } ?: Outcome.PASSED
        val attempt =
            Attempt(
                outcome = outcome,
                span = null,
                durationMillis = result.durationMillis(),
                artifacts = listOf(),
                folder = "",
                steps = listOf(),
                taps = listOf(),
            )
        runs.getOrPut(run) { Run(clock()) }.cases +=
            TestCase(
                id = submit.testId(),
                requirement = submit.requirement(),
                demonstrates = Demonstrates.HAPPY_PATH,
                attempts = listOf(attempt),
            )
    }

    /** This case with [note] joined to its failure. */
    private fun TestCase.noting(note: String): TestCase =
        copy(
            attempts =
                attempts.map { attempt ->
                    val failed = (attempt.outcome as? Outcome.FailedWrapper)?.value ?: return@map attempt
                    attempt.copy(outcome = Outcome.createFailed(message = "${failed.message}\n$note", firstBroken = failed.firstBroken))
                },
        )

    /**
     * Writes [run] as a `TestRun` into [file], replacing what an earlier session of the run wrote. Each
     * note in [stillOut] joins the failure of the case its test id names: a player that case's hung
     * work keeps out of the pool.
     */
    fun write(
        run: String,
        file: Path,
        stillOut: Map<String, String> = mapOf(),
    ) {
        val record = runs.getOrPut(run) { Run(clock()) }
        val testRun =
            TestRun(
                runner = Runner.GAME,
                commit = "",
                startedAtMillis = record.startedAtMillis,
                attemptPolicy = AttemptPolicy.ExactlyWrapper(1),
                cases = record.cases.map { case -> stillOut[case.id]?.let { note -> case.noting(note) } ?: case },
            )
        Files.createDirectories(file.toAbsolutePath().parent)
        val partial = file.resolveSibling("${file.fileName}.partial")
        Files.writeString(partial, TestRun.serializer.toJsonCode(testRun, JsonFlavor.READABLE))
        Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    }
}
