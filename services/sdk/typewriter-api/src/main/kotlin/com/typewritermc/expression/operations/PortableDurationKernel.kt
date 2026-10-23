package com.typewritermc.expression.operations

import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** Realm's kernel of the duration operations: whole milliseconds within the portable duration range. */
internal object PortableDurationKernel : DurationKernel {
    override fun fromMilliseconds(milliseconds: BigInteger): Duration = portableDuration(milliseconds)

    override fun toMilliseconds(value: Duration): BigInteger = BigInteger.valueOf(value.inWholeMilliseconds)
}

/** The largest magnitude, in milliseconds, of a portable duration: every host holds it exactly. */
internal val MAX_DURATION_MILLISECONDS: BigInteger = BigInteger.valueOf(9_007_199_254_740_991L)

/** The duration of [milliseconds], or duration_range when it lies outside the portable range. */
internal fun portableDuration(milliseconds: BigInteger): Duration {
    if (milliseconds.abs() > MAX_DURATION_MILLISECONDS) {
        throw OperationFailure(KernelFailure.DurationRange, "The duration of $milliseconds milliseconds is outside the portable range.")
    }
    return milliseconds.toLong().milliseconds
}
