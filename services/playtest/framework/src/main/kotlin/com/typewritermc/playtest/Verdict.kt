package com.typewritermc.playtest

import skirout.harness.v1.test_run.AttemptPolicy
import java.net.URL

/**
 * The requirement can never run as written, for example a window without a positive check, or the pool
 * declined it; another attempt would be refused the same way, so it is never retried.
 */
open class RequirementRefused(
    message: String,
) : AssertionError(message)

/**
 * The requirement failed an attempt and passed a later one. It blocks like a failure: a requirement
 * that fails only sometimes proves nothing. Its stack trace starts at the body's line of the first
 * failure, which is its [cause].
 */
class RequirementFlaky(
    message: String,
    cause: Throwable,
) : AssertionError(message, cause)

/**
 * The requirement's demo, its run once more with clips, ended otherwise than its last attempt: a clip
 * that shows another outcome than the verdict proves nothing. Its [cause] is the failure the one that
 * failed met.
 */
class DemoDiffers(
    message: String,
    cause: Throwable,
) : AssertionError(message, cause)

/**
 * Why a demo that ended with [demo] after a last attempt that ended with [last], each null for a pass,
 * fails the requirement; null when both passed or both failed.
 */
internal fun demoDiffers(
    last: Throwable?,
    demo: Throwable?,
): DemoDiffers? =
    when {
        (last == null) == (demo == null) -> null
        demo != null -> DemoDiffers("the demo failed where the last attempt passed: ${demo.described}", demo)
        else -> DemoDiffers("the demo passed where the last attempt failed: ${checkNotNull(last).described}", last)
    }

/** Where a requirement's own code lives, to find its lines in a stack trace. */
internal class RequirementCode private constructor(
    private val location: URL?,
) {
    /** Whether [frame] runs the requirement's own code. */
    fun owns(frame: StackTraceElement): Boolean =
        location != null &&
            runCatching {
                Class
                    .forName(frame.className, false, RequirementCode::class.java.classLoader)
                    .protectionDomain.codeSource
                    ?.location
            }.getOrNull() == location

    /** The first frame of [trace] in the requirement's own code, as `File.kt:line`. */
    fun line(trace: Array<StackTraceElement>): String? = trace.firstOrNull(::owns)?.let { "${it.fileName}:${it.lineNumber}" }

    companion object {
        /** The code [code], a body or any lambda of the requirement's source, belongs to. */
        fun of(code: Any): RequirementCode =
            RequirementCode(
                code.javaClass.protectionDomain.codeSource
                    ?.location,
            )
    }
}

/** What a requirement's attempts prove under its run's policy. */
internal sealed interface Verdict {
    /** Every attempt passed. */
    data object Passed : Verdict

    /** An attempt failed and a later one passed. */
    data class Flaky(
        val failures: List<Throwable>,
        val attempts: Int,
    ) : Verdict

    /** The requirement failed: every attempt, any attempt of a repeat, or it was refused. */
    data class Failed(
        val failures: List<Throwable>,
        val attempts: Int,
    ) : Verdict

    /** It failed, but the quarantine holds it: reported, not blocking. */
    data class Quarantined(
        val failures: List<Throwable>,
        val attempts: Int,
    ) : Verdict

    /**
     * Ends the requirement's test as its verdict says: a failure or a flaky pass fails it, with the
     * stack trace starting in the requirement's [code]; a pass or a quarantined failure lets it pass.
     */
    fun conclude(code: RequirementCode) {
        when (this) {
            Passed -> {}

            is Quarantined -> {
                System.err.println("Quarantined, not blocking: ${failures.joinToString("\n") { it.described }}")
            }

            is Failed -> {
                throw failures.last().also { last -> failures.dropLast(1).forEach(last::addSuppressed) }
            }

            is Flaky -> {
                val first = failures.first()
                val failed = if (failures.size == 1) "attempt 1" else "attempts ${(1..failures.size).joinToString(", ")}"
                val each = failures.withIndex().joinToString("\n") { (index, failure) -> "Attempt ${index + 1}: ${failure.described}" }
                val flaky =
                    RequirementFlaky(
                        "flaky: $failed of $attempts failed and attempt $attempts passed; a flaky requirement blocks like a failure.\n$each",
                        first,
                    )
                // The body's line comes first, so the report and the IDE point at the requirement, not the framework.
                flaky.stackTrace =
                    first.stackTrace
                        .dropWhile { !code.owns(it) }
                        .ifEmpty { first.stackTrace.toList() }
                        .toTypedArray()
                throw flaky
            }
        }
    }
}

/** What [this] says to a reader: an assertion's message, anything else with its type. */
internal val Throwable.described: String get() = if (this is AssertionError) message ?: toString() else toString()

/**
 * Runs the attempts of one requirement as [this] policy asks: [attempt] runs attempt `number` (from 1)
 * and returns why it failed, or null. Under `RERUN_FAILURES` a failed attempt runs again until one
 * passes or the limit is reached; under `EXACTLY` every attempt runs. A refusal or a broken game ends at
 * once, as any later attempt would end the same way, and a quarantined requirement runs once unless the
 * run repeats it.
 */
internal suspend fun AttemptPolicy.attempt(
    quarantined: Boolean,
    attempt: suspend (number: Int) -> Throwable?,
): Verdict {
    val outcomes = mutableListOf<Throwable?>()
    for (number in 1..attempts) {
        val failure = attempt(number)
        outcomes += failure
        if (!again(failure, quarantined)) break
    }
    return verdict(outcomes, quarantined)
}

/** The most attempts this policy makes of a requirement; a policy this build does not know makes one. */
private val AttemptPolicy.attempts: Int
    get() =
        when (this) {
            is AttemptPolicy.RerunFailuresWrapper -> value
            is AttemptPolicy.ExactlyWrapper -> value
            else -> 1
        }

/** Whether another attempt follows one that ended with [failure], null for a pass. */
private fun AttemptPolicy.again(
    failure: Throwable?,
    quarantined: Boolean,
): Boolean =
    when {
        failure is RequirementRefused || failure is GameUnavailable -> false
        this is AttemptPolicy.ExactlyWrapper -> true
        else -> failure != null && !quarantined
    }

/** What [outcomes], each attempt's failure or null for a pass, prove under this policy. */
private fun AttemptPolicy.verdict(
    outcomes: List<Throwable?>,
    quarantined: Boolean,
): Verdict {
    val failures = outcomes.filterNotNull()
    return when {
        failures.isEmpty() -> Verdict.Passed
        quarantined -> Verdict.Quarantined(failures, outcomes.size)
        this is AttemptPolicy.RerunFailuresWrapper && outcomes.last() == null -> Verdict.Flaky(failures, outcomes.size)
        else -> Verdict.Failed(failures, outcomes.size)
    }
}

/**
 * How a requirement's body ended: its [failure], or, when it returned without one and never [proved]
 * something (a window with a positive check that held, or a golden frame), a refusal, since a body
 * without a positive check could never fail.
 */
internal fun bodyEnded(
    failure: Throwable?,
    proved: Boolean,
): Throwable? =
    failure ?: if (proved) {
        null
    } else {
        RequirementRefused(
            "the requirement's body made no positive check, so it could never fail: wait for what the player " +
                "should see with `within`, or compare a still scene with `looksLike`",
        )
    }
