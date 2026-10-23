package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.and
import com.typewritermc.expression.compare
import com.typewritermc.expression.contains
import com.typewritermc.expression.eq
import com.typewritermc.expression.listExpr
import com.typewritermc.expression.literal
import com.typewritermc.expression.minus
import com.typewritermc.expression.numericLiteral
import com.typewritermc.expression.rem
import com.typewritermc.expression.scale
import com.typewritermc.expression.size
import com.typewritermc.expression.toSet
import com.typewritermc.types.Color
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration

/*
 * Shortcuts for configuration rules that have no general counterpart. Rules otherwise use the general shortcuts:
 * isNotEmpty, isNotBlank, isSingleLine, isNotNull, gte, lte, matches, startsWith and endsWith. Bounds lower to the
 * comparison shapes of CompareShortcuts.kt, which DefaultPredicateReasoner reads; inRange binds its subject once with
 * value.let around both bounds.
 */

/** Whether this number is greater than zero. */
@JvmName("positiveByte")
fun <M : MissingPolicy> Expr<Byte, M>.positive(): Expr<Boolean, M> = this gt 0.toByte()

/** Whether this number is greater than zero. */
@JvmName("positiveShort")
fun <M : MissingPolicy> Expr<Short, M>.positive(): Expr<Boolean, M> = this gt 0.toShort()

/** Whether this number is greater than zero. */
@JvmName("positiveInt")
fun <M : MissingPolicy> Expr<Int, M>.positive(): Expr<Boolean, M> = this gt 0

/** Whether this number is greater than zero. */
@JvmName("positiveLong")
fun <M : MissingPolicy> Expr<Long, M>.positive(): Expr<Boolean, M> = this gt 0L

/** Whether this number is greater than zero. */
@JvmName("positiveBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.positive(): Expr<Boolean, M> = this gt BigInteger.ZERO

/** Whether this number is greater than zero. */
@JvmName("positiveFloat")
fun <M : MissingPolicy> Expr<Float, M>.positive(): Expr<Boolean, M> = this gt 0f

/** Whether this number is greater than zero. */
@JvmName("positiveDouble")
fun <M : MissingPolicy> Expr<Double, M>.positive(): Expr<Boolean, M> = this gt 0.0

/** Whether this number is greater than zero. */
@JvmName("positiveBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.positive(): Expr<Boolean, M> = this gt BigDecimal.ZERO

/** Whether this number is zero or greater. */
@JvmName("nonNegativeByte")
fun <M : MissingPolicy> Expr<Byte, M>.nonNegative(): Expr<Boolean, M> = this gte 0.toByte()

/** Whether this number is zero or greater. */
@JvmName("nonNegativeShort")
fun <M : MissingPolicy> Expr<Short, M>.nonNegative(): Expr<Boolean, M> = this gte 0.toShort()

/** Whether this number is zero or greater. */
@JvmName("nonNegativeInt")
fun <M : MissingPolicy> Expr<Int, M>.nonNegative(): Expr<Boolean, M> = this gte 0

/** Whether this number is zero or greater. */
@JvmName("nonNegativeLong")
fun <M : MissingPolicy> Expr<Long, M>.nonNegative(): Expr<Boolean, M> = this gte 0L

/** Whether this number is zero or greater. */
@JvmName("nonNegativeBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.nonNegative(): Expr<Boolean, M> = this gte BigInteger.ZERO

/** Whether this number is zero or greater. */
@JvmName("nonNegativeFloat")
fun <M : MissingPolicy> Expr<Float, M>.nonNegative(): Expr<Boolean, M> = this gte 0f

/** Whether this number is zero or greater. */
@JvmName("nonNegativeDouble")
fun <M : MissingPolicy> Expr<Double, M>.nonNegative(): Expr<Boolean, M> = this gte 0.0

/** Whether this number is zero or greater. */
@JvmName("nonNegativeBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.nonNegative(): Expr<Boolean, M> = this gte BigDecimal.ZERO

/** Whether this duration is zero or longer. */
@JvmName("nonNegativeDuration")
fun <M : MissingPolicy> Expr<Duration, M>.nonNegative(): Expr<Boolean, M> = this gte Duration.ZERO

/** Whether this value orders between [minimum] and [maximum], both included. */
fun <O, M : MissingPolicy> Expr<O, M>.inRange(
    minimum: Expr<O, M>,
    maximum: Expr<O, M>,
): Expr<Boolean, M> = shared(this) { value -> (value gte minimum) and (value lte maximum) }

/** Whether this number is between [minimum] and [maximum], both included. */
@JvmName("inRangeRaw")
fun <N : Number, M : MissingPolicy> Expr<N, M>.inRange(
    minimum: N,
    maximum: N,
): Expr<Boolean, M> = inRange(numericLiteral(minimum).lift(), numericLiteral(maximum).lift())

/**
 * Whether this number is a whole multiple of [divisor]; fails with division_by_zero when [divisor] is zero. The
 * remainder compares to zero by value, so a negative zero remainder (-4.0 % 2.0) counts.
 */
fun <N : Number, M : MissingPolicy> Expr<N, M>.multipleOf(divisor: Expr<N, M>): Expr<Boolean, M> =
    shared(divisor) { by -> (this % by).compare(by - by) eq literal(0).lift() }

/** Whether this number is a whole multiple of the nonzero [divisor]. */
@JvmName("multipleOfRaw")
fun <N : Number, M : MissingPolicy> Expr<N, M>.multipleOf(divisor: N): Expr<Boolean, M> {
    val nonzero =
        when (divisor) {
            is BigDecimal -> divisor.signum() != 0
            is BigInteger -> divisor.signum() != 0
            else -> divisor.toDouble() != 0.0
        }
    require(nonzero) { "A multiple needs a nonzero divisor." }
    return (this % divisor).compare(numericLiteral(zeroLike(divisor)).lift()) eq literal(0).lift()
}

/** Zero in the Kotlin number type of [sample], so that the literal has the sample's numeric family. */
@Suppress("UNCHECKED_CAST")
private fun <N : Number> zeroLike(sample: N): N =
    when (sample) {
        is Byte -> 0.toByte()
        is Short -> 0.toShort()
        is Int -> 0
        is Long -> 0L
        is BigInteger -> BigInteger.ZERO
        is Float -> 0f
        is Double -> 0.0
        is BigDecimal -> BigDecimal.ZERO
        else -> throw IllegalArgumentException("Unsupported portable number ${sample::class.qualifiedName}.")
    } as N

/** Whether this decimal has at most [digits] fraction digits once trailing zeros are dropped. */
fun <M : MissingPolicy> Expr<BigDecimal, M>.maximumScale(digits: Int): Expr<Boolean, M> = scale() lte digits

/** Whether this value equals one of [candidates]. */
fun <T, M : MissingPolicy> Expr<T, M>.oneOf(vararg candidates: Expr<T, M>): Expr<Boolean, M> {
    require(candidates.isNotEmpty()) { "An allowed value rule needs at least one candidate." }
    return listExpr(*candidates).contains(this)
}

/** Whether no two items of this collection are equal. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.unique(): Expr<Boolean, M> =
    shared(this) { items -> items.toSet().size eq items.size }

/** Whether this color is fully opaque. */
fun <M : MissingPolicy> Expr<Color, M>.opaque(): Expr<Boolean, M> = alpha eq literal(0xFFu).lift()
