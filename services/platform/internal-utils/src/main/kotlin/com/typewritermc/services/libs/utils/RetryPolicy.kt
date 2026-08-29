package com.typewritermc.services.libs.utils

import kotlin.math.pow
import kotlin.time.Duration
import kotlin.time.Duration.Companion.nanoseconds

/** Calculates bounded retry delays without owning time, randomness, or execution. */
sealed interface RetryPolicy {
    /** Returns the delay for a zero-based [attempt] and normalized [jitterSample]. */
    fun delayFor(
        attempt: Long,
        jitterSample: Double = 0.5,
    ): Duration

    companion object {
        /** Creates a policy that always returns [delay]. */
        fun fixed(delay: Duration): RetryPolicy {
            requirePositiveFinite(delay, "delay")
            return FixedRetryPolicy(delay)
        }

        /** Creates a policy whose delay grows from [initial] up to [maximum]. */
        fun exponential(
            initial: Duration,
            maximum: Duration,
            multiplier: Double = 2.0,
            jitterRatio: Double = 0.0,
        ): RetryPolicy {
            requirePositiveFinite(initial, "initial")
            requirePositiveFinite(maximum, "maximum")
            require(initial <= maximum) { "initial must not exceed maximum" }
            require(multiplier.isFinite() && multiplier > 1.0) { "multiplier must be finite and greater than 1" }
            require(jitterRatio in 0.0..1.0) { "jitterRatio must be between 0 and 1" }
            return ExponentialRetryPolicy(initial, maximum, multiplier, jitterRatio)
        }
    }
}

private class FixedRetryPolicy(
    private val delay: Duration,
) : RetryPolicy {
    override fun delayFor(
        attempt: Long,
        jitterSample: Double,
    ): Duration {
        validateInputs(attempt, jitterSample)
        return delay
    }
}

private class ExponentialRetryPolicy(
    private val initial: Duration,
    private val maximum: Duration,
    private val multiplier: Double,
    private val jitterRatio: Double,
) : RetryPolicy {
    override fun delayFor(
        attempt: Long,
        jitterSample: Double,
    ): Duration {
        validateInputs(attempt, jitterSample)
        val growthFactor = multiplier.pow(attempt.toDouble())
        val unjittered = (initial * growthFactor).coerceAtMost(maximum)
        val jitterFactor = 1.0 + jitterRatio * (2.0 * jitterSample - 1.0)
        return (unjittered * jitterFactor)
            .coerceAtLeast(1.nanoseconds)
            .coerceAtMost(maximum)
    }
}

private fun requirePositiveFinite(
    duration: Duration,
    name: String,
) {
    require(duration.isFinite() && duration > Duration.ZERO) { "$name must be finite and positive" }
}

private fun validateInputs(
    attempt: Long,
    jitterSample: Double,
) {
    require(attempt >= 0) { "attempt must be nonnegative" }
    require(jitterSample in 0.0..1.0) { "jitterSample must be between 0 and 1" }
}
