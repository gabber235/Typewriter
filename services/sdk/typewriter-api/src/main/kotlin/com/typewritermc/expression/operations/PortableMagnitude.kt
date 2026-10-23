package com.typewritermc.expression.operations

import java.math.BigDecimal
import java.math.BigInteger

/*
 * Integers and decimals are arbitrary precision, so operations whose result size grows with their input (products,
 * powers, shifts, parsed text) are capped: a result with more than MAX_RESULT_DIGITS digits fails magnitude_limit.
 * Digits count the decimal digits of an integer's magnitude, and of a decimal's canonical plain notation without
 * sign and point. Operations whose size bound is visible before computing check that bound first, so an oversized
 * result is never materialized.
 */

/** The most decimal digits an integer or decimal result may have. */
internal const val MAX_RESULT_DIGITS = 20_000

/** A magnitude of more bits always has more than [MAX_RESULT_DIGITS] decimal digits: ceil(20000 * log2(10)). */
internal const val MAX_RESULT_BITS = 66_439L

internal fun magnitudeLimit(): OperationFailure =
    OperationFailure(KernelFailure.MagnitudeLimit, "The result would have more than $MAX_RESULT_DIGITS digits.")

/** This integer when it has at most [MAX_RESULT_DIGITS] digits. */
internal fun BigInteger.requireMagnitude(): BigInteger {
    if (bitLength() > MAX_RESULT_BITS || abs().toString().length > MAX_RESULT_DIGITS) throw magnitudeLimit()
    return this
}

/** This decimal when its canonical plain notation has at most [MAX_RESULT_DIGITS] digits. */
internal fun BigDecimal.requireMagnitude(): BigDecimal {
    if (plainDigits() > MAX_RESULT_DIGITS) throw magnitudeLimit()
    return this
}

/** The digits of this decimal's canonical plain notation, computed without rendering it. */
internal fun BigDecimal.plainDigits(): Long {
    val canonical = stripTrailingZeros()
    val precision = canonical.precision().toLong()
    val scale = canonical.scale().toLong()
    return when {
        scale < 0 -> precision - scale
        scale >= precision -> scale + 1
        else -> precision
    }
}
