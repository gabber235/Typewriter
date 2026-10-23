package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.compare
import com.typewritermc.expression.eq
import com.typewritermc.expression.isNull
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.expression.numericLiteral
import kotlin.time.Duration
import kotlin.time.Instant

/*
 * Comparisons lower to value.compare tested with value.equals against -1 or 1, negated with boolean.not for the
 * inclusive forms. DefaultPredicateReasoner reads exactly these shapes to find contradictory bounds, and
 * ShortcutLoweringTest pins them.
 *
 *   a gt b   value.equals(value.compare(a, b), 1)
 *   a lt b   value.equals(value.compare(a, b), -1)
 *   a gte b  boolean.not(value.equals(value.compare(a, b), -1))
 *   a lte b  boolean.not(value.equals(value.compare(a, b), 1))
 *
 * Text orders by code point, numbers by value within one family, false before true, timestamps and durations
 * chronologically.
 */

/** Whether this value differs structurally from [other]. */
@JvmName("valueNotEquals")
infix fun <T, M : MissingPolicy> Expr<T, M>.neq(other: Expr<T, M>): Expr<Boolean, M> = (this eq other).not()

/** Whether this value is not the explicit null. Missing data is not null, so it stays missing. */
@JvmName("valueIsNotNull")
fun <T, M : MissingPolicy> Expr<T?, M>.isNotNull(): Expr<Boolean, M> = isNull().not()

/** Whether this value orders after [other]. */
@JvmName("orderedGreater")
infix fun <O, M : MissingPolicy> Expr<O, M>.gt(other: Expr<O, M>): Expr<Boolean, M> = compare(other) eq literal(1).lift()

/** Whether this value orders before [other]. */
@JvmName("orderedLess")
infix fun <O, M : MissingPolicy> Expr<O, M>.lt(other: Expr<O, M>): Expr<Boolean, M> = compare(other) eq literal(-1).lift()

/** Whether this value orders after or equal to [other]. */
@JvmName("orderedGreaterOrEqual")
infix fun <O, M : MissingPolicy> Expr<O, M>.gte(other: Expr<O, M>): Expr<Boolean, M> = (this lt other).not()

/** Whether this value orders before or equal to [other]. */
@JvmName("orderedLessOrEqual")
infix fun <O, M : MissingPolicy> Expr<O, M>.lte(other: Expr<O, M>): Expr<Boolean, M> = (this gt other).not()

/** Whether this number is greater than [other]. */
@JvmName("numberGreaterRaw")
infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gt(other: N): Expr<Boolean, M> = this gt numericLiteral(other).lift()

/** Whether this number is less than [other]. */
@JvmName("numberLessRaw")
infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lt(other: N): Expr<Boolean, M> = this lt numericLiteral(other).lift()

/** Whether this number is greater than or equal to [other]. */
@JvmName("numberGreaterOrEqualRaw")
infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gte(other: N): Expr<Boolean, M> = this gte numericLiteral(other).lift()

/** Whether this number is less than or equal to [other]. */
@JvmName("numberLessOrEqualRaw")
infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lte(other: N): Expr<Boolean, M> = this lte numericLiteral(other).lift()

/** Whether this number is greater than [other]. */
@JvmName("uByteGreaterRaw")
infix fun <M : MissingPolicy> Expr<UByte, M>.gt(other: UByte): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this number is less than [other]. */
@JvmName("uByteLessRaw")
infix fun <M : MissingPolicy> Expr<UByte, M>.lt(other: UByte): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this number is greater than or equal to [other]. */
@JvmName("uByteGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<UByte, M>.gte(other: UByte): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this number is less than or equal to [other]. */
@JvmName("uByteLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<UByte, M>.lte(other: UByte): Expr<Boolean, M> = this lte literal(other).lift()

/** Whether this number is greater than [other]. */
@JvmName("uShortGreaterRaw")
infix fun <M : MissingPolicy> Expr<UShort, M>.gt(other: UShort): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this number is less than [other]. */
@JvmName("uShortLessRaw")
infix fun <M : MissingPolicy> Expr<UShort, M>.lt(other: UShort): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this number is greater than or equal to [other]. */
@JvmName("uShortGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<UShort, M>.gte(other: UShort): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this number is less than or equal to [other]. */
@JvmName("uShortLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<UShort, M>.lte(other: UShort): Expr<Boolean, M> = this lte literal(other).lift()

/** Whether this number is greater than [other]. */
@JvmName("uIntGreaterRaw")
infix fun <M : MissingPolicy> Expr<UInt, M>.gt(other: UInt): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this number is less than [other]. */
@JvmName("uIntLessRaw")
infix fun <M : MissingPolicy> Expr<UInt, M>.lt(other: UInt): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this number is greater than or equal to [other]. */
@JvmName("uIntGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<UInt, M>.gte(other: UInt): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this number is less than or equal to [other]. */
@JvmName("uIntLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<UInt, M>.lte(other: UInt): Expr<Boolean, M> = this lte literal(other).lift()

/** Whether this number is greater than [other]. */
@JvmName("uLongGreaterRaw")
infix fun <M : MissingPolicy> Expr<ULong, M>.gt(other: ULong): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this number is less than [other]. */
@JvmName("uLongLessRaw")
infix fun <M : MissingPolicy> Expr<ULong, M>.lt(other: ULong): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this number is greater than or equal to [other]. */
@JvmName("uLongGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<ULong, M>.gte(other: ULong): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this number is less than or equal to [other]. */
@JvmName("uLongLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<ULong, M>.lte(other: ULong): Expr<Boolean, M> = this lte literal(other).lift()

/** Whether this duration is longer than [other]. */
@JvmName("durationGreaterRaw")
infix fun <M : MissingPolicy> Expr<Duration, M>.gt(other: Duration): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this duration is shorter than [other]. */
@JvmName("durationLessRaw")
infix fun <M : MissingPolicy> Expr<Duration, M>.lt(other: Duration): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this duration is at least [other]. */
@JvmName("durationGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<Duration, M>.gte(other: Duration): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this duration is at most [other]. */
@JvmName("durationLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<Duration, M>.lte(other: Duration): Expr<Boolean, M> = this lte literal(other).lift()

/** Whether this timestamp is after [other]. */
@JvmName("timestampGreaterRaw")
infix fun <M : MissingPolicy> Expr<Instant, M>.gt(other: Instant): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this timestamp is before [other]. */
@JvmName("timestampLessRaw")
infix fun <M : MissingPolicy> Expr<Instant, M>.lt(other: Instant): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this timestamp is at or after [other]. */
@JvmName("timestampGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<Instant, M>.gte(other: Instant): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this timestamp is at or before [other]. */
@JvmName("timestampLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<Instant, M>.lte(other: Instant): Expr<Boolean, M> = this lte literal(other).lift()

/** Whether this text orders after [other] by code point. */
@JvmName("textGreaterRaw")
infix fun <M : MissingPolicy> Expr<String, M>.gt(other: String): Expr<Boolean, M> = this gt literal(other).lift()

/** Whether this text orders before [other] by code point. */
@JvmName("textLessRaw")
infix fun <M : MissingPolicy> Expr<String, M>.lt(other: String): Expr<Boolean, M> = this lt literal(other).lift()

/** Whether this text orders after or equal to [other] by code point. */
@JvmName("textGreaterOrEqualRaw")
infix fun <M : MissingPolicy> Expr<String, M>.gte(other: String): Expr<Boolean, M> = this gte literal(other).lift()

/** Whether this text orders before or equal to [other] by code point. */
@JvmName("textLessOrEqualRaw")
infix fun <M : MissingPolicy> Expr<String, M>.lte(other: String): Expr<Boolean, M> = this lte literal(other).lift()

/** The smaller of [first] and [second]; [first] when they are equal. */
fun <O, M : MissingPolicy> min(
    first: Expr<O, M>,
    second: Expr<O, M>,
): Expr<O, M> = shared(first) { a -> shared(second) { b -> choose(a lte b, a, b) } }

/** The larger of [first] and [second]; [first] when they are equal. */
fun <O, M : MissingPolicy> max(
    first: Expr<O, M>,
    second: Expr<O, M>,
): Expr<O, M> = shared(first) { a -> shared(second) { b -> choose(a gte b, a, b) } }

/** The smaller of [first] and the number [second]. */
@JvmName("minRaw")
fun <N : Number, M : MissingPolicy> min(
    first: Expr<N, M>,
    second: N,
): Expr<N, M> = min(first, numericLiteral(second).lift())

/** The larger of [first] and the number [second]. */
@JvmName("maxRaw")
fun <N : Number, M : MissingPolicy> max(
    first: Expr<N, M>,
    second: N,
): Expr<N, M> = max(first, numericLiteral(second).lift())

/** This value limited to the range from [minimum] to [maximum]; like Kotlin's coerceIn when the range is ordered. */
fun <O, M : MissingPolicy> Expr<O, M>.clamp(
    minimum: Expr<O, M>,
    maximum: Expr<O, M>,
): Expr<O, M> = min(max(this, minimum), maximum)

/** This number limited to the range from [minimum] to [maximum]. */
@JvmName("clampRaw")
fun <N : Number, M : MissingPolicy> Expr<N, M>.clamp(
    minimum: N,
    maximum: N,
): Expr<N, M> = clamp(numericLiteral(minimum).lift(), numericLiteral(maximum).lift())
