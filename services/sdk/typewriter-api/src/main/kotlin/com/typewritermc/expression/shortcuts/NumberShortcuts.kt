package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.compare
import com.typewritermc.expression.div
import com.typewritermc.expression.eq
import com.typewritermc.expression.gcd
import com.typewritermc.expression.minus
import com.typewritermc.expression.not
import com.typewritermc.expression.numericLiteral
import com.typewritermc.expression.operations.RoundingMode
import com.typewritermc.expression.plus
import com.typewritermc.expression.rem
import com.typewritermc.expression.round
import com.typewritermc.expression.times
import java.math.BigDecimal
import java.math.BigInteger

/*
 * Number shortcuts. A primitive call takes one numeric family (integer, float or decimal), so a shortcut that needs a
 * constant such as zero has one overload per Kotlin number type and writes the constant in that type's family.
 * Shortcuts without constants are generic over every number type.
 */

/** The negation of this number. */
@JvmName("negateByte")
operator fun <M : MissingPolicy> Expr<Byte, M>.unaryMinus(): Expr<Byte, M> = numericLiteral(0.toByte()).lift<Byte, M>() - this

/** The negation of this number. */
@JvmName("negateShort")
operator fun <M : MissingPolicy> Expr<Short, M>.unaryMinus(): Expr<Short, M> = numericLiteral(0.toShort()).lift<Short, M>() - this

/** The negation of this number. */
@JvmName("negateInt")
operator fun <M : MissingPolicy> Expr<Int, M>.unaryMinus(): Expr<Int, M> = numericLiteral(0).lift<Int, M>() - this

/** The negation of this number. */
@JvmName("negateLong")
operator fun <M : MissingPolicy> Expr<Long, M>.unaryMinus(): Expr<Long, M> = numericLiteral(0L).lift<Long, M>() - this

/** The negation of this number. */
@JvmName("negateBigInteger")
operator fun <M : MissingPolicy> Expr<BigInteger, M>.unaryMinus(): Expr<BigInteger, M> = numericLiteral(BigInteger.ZERO).lift<BigInteger, M>() - this

/** The negation of this number. */
@JvmName("negateFloat")
operator fun <M : MissingPolicy> Expr<Float, M>.unaryMinus(): Expr<Float, M> = numericLiteral(0f).lift<Float, M>() - this

/** The negation of this number. */
@JvmName("negateDouble")
operator fun <M : MissingPolicy> Expr<Double, M>.unaryMinus(): Expr<Double, M> = numericLiteral(0.0).lift<Double, M>() - this

/** The negation of this number. */
@JvmName("negateBigDecimal")
operator fun <M : MissingPolicy> Expr<BigDecimal, M>.unaryMinus(): Expr<BigDecimal, M> = numericLiteral(BigDecimal.ZERO).lift<BigDecimal, M>() - this

/** The absolute value of this number. */
@JvmName("absByte")
fun <M : MissingPolicy> Expr<Byte, M>.abs(): Expr<Byte, M> = absolute(numericLiteral(0.toByte()).lift())

/** The absolute value of this number. */
@JvmName("absShort")
fun <M : MissingPolicy> Expr<Short, M>.abs(): Expr<Short, M> = absolute(numericLiteral(0.toShort()).lift())

/** The absolute value of this number. */
@JvmName("absInt")
fun <M : MissingPolicy> Expr<Int, M>.abs(): Expr<Int, M> = absolute(numericLiteral(0).lift())

/** The absolute value of this number. */
@JvmName("absLong")
fun <M : MissingPolicy> Expr<Long, M>.abs(): Expr<Long, M> = absolute(numericLiteral(0L).lift())

/** The absolute value of this number. */
@JvmName("absBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.abs(): Expr<BigInteger, M> = absolute(numericLiteral(BigInteger.ZERO).lift())

/** The absolute value of this number. */
@JvmName("absFloat")
fun <M : MissingPolicy> Expr<Float, M>.abs(): Expr<Float, M> = absolute(numericLiteral(0f).lift())

/** The absolute value of this number. */
@JvmName("absDouble")
fun <M : MissingPolicy> Expr<Double, M>.abs(): Expr<Double, M> = absolute(numericLiteral(0.0).lift())

/** The absolute value of this number. */
@JvmName("absBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.abs(): Expr<BigDecimal, M> = absolute(numericLiteral(BigDecimal.ZERO).lift())

private fun <N : Number, M : MissingPolicy> Expr<N, M>.absolute(zero: Expr<N, M>): Expr<N, M> =
    shared(this) { value -> choose(value lt zero, zero - value, value) }

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signByte")
fun <M : MissingPolicy> Expr<Byte, M>.sign(): Expr<Int, M> = compare(numericLiteral(0.toByte()).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signShort")
fun <M : MissingPolicy> Expr<Short, M>.sign(): Expr<Int, M> = compare(numericLiteral(0.toShort()).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signInt")
fun <M : MissingPolicy> Expr<Int, M>.sign(): Expr<Int, M> = compare(numericLiteral(0).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signLong")
fun <M : MissingPolicy> Expr<Long, M>.sign(): Expr<Int, M> = compare(numericLiteral(0L).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.sign(): Expr<Int, M> = compare(numericLiteral(BigInteger.ZERO).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signFloat")
fun <M : MissingPolicy> Expr<Float, M>.sign(): Expr<Int, M> = compare(numericLiteral(0f).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signDouble")
fun <M : MissingPolicy> Expr<Double, M>.sign(): Expr<Int, M> = compare(numericLiteral(0.0).lift())

/** -1, 0 or 1 as this number is negative, zero or positive. */
@JvmName("signBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.sign(): Expr<Int, M> = compare(numericLiteral(BigDecimal.ZERO).lift())

/** The largest whole number not above this one. */
@JvmName("floorFloat")
fun <M : MissingPolicy> Expr<Float, M>.floor(): Expr<Float, M> = round(1f, RoundingMode.Floor)

/** The largest whole number not above this one. */
@JvmName("floorDouble")
fun <M : MissingPolicy> Expr<Double, M>.floor(): Expr<Double, M> = round(1.0, RoundingMode.Floor)

/** The largest whole number not above this one. */
@JvmName("floorBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.floor(): Expr<BigDecimal, M> = round(BigDecimal.ONE, RoundingMode.Floor)

/** The smallest whole number not below this one. */
@JvmName("ceilFloat")
fun <M : MissingPolicy> Expr<Float, M>.ceil(): Expr<Float, M> = round(1f, RoundingMode.Ceiling)

/** The smallest whole number not below this one. */
@JvmName("ceilDouble")
fun <M : MissingPolicy> Expr<Double, M>.ceil(): Expr<Double, M> = round(1.0, RoundingMode.Ceiling)

/** The smallest whole number not below this one. */
@JvmName("ceilBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.ceil(): Expr<BigDecimal, M> = round(BigDecimal.ONE, RoundingMode.Ceiling)

/** This number without its fraction, rounded toward zero. */
@JvmName("truncateFloat")
fun <M : MissingPolicy> Expr<Float, M>.truncate(): Expr<Float, M> = round(1f, RoundingMode.TowardZero)

/** This number without its fraction, rounded toward zero. */
@JvmName("truncateDouble")
fun <M : MissingPolicy> Expr<Double, M>.truncate(): Expr<Double, M> = round(1.0, RoundingMode.TowardZero)

/** This number without its fraction, rounded toward zero. */
@JvmName("truncateBigDecimal")
fun <M : MissingPolicy> Expr<BigDecimal, M>.truncate(): Expr<BigDecimal, M> = round(BigDecimal.ONE, RoundingMode.TowardZero)

/** The remainder of floored division: it has the sign of [divisor], like Kotlin's mod. */
fun <N : Number, M : MissingPolicy> Expr<N, M>.mod(divisor: Expr<N, M>): Expr<N, M> =
    shared(divisor) { by -> (this % by + by) % by }

/** The remainder of floored division: it has the sign of [divisor], like Kotlin's mod. */
@JvmName("modRaw")
fun <N : Number, M : MissingPolicy> Expr<N, M>.mod(divisor: N): Expr<N, M> = mod(numericLiteral(divisor).lift())

/** Whether this integer is divisible by two. */
@JvmName("isEvenInt")
fun <M : MissingPolicy> Expr<Int, M>.isEven(): Expr<Boolean, M> = this % 2 eq numericLiteral(0).lift()

/** Whether this integer is divisible by two. */
@JvmName("isEvenLong")
fun <M : MissingPolicy> Expr<Long, M>.isEven(): Expr<Boolean, M> = this % 2L eq numericLiteral(0L).lift()

/** Whether this integer is divisible by two. */
@JvmName("isEvenBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.isEven(): Expr<Boolean, M> = this % BigInteger.TWO eq numericLiteral(BigInteger.ZERO).lift()

/** Whether this integer is not divisible by two. */
@JvmName("isOddInt")
fun <M : MissingPolicy> Expr<Int, M>.isOdd(): Expr<Boolean, M> = isEven().not()

/** Whether this integer is not divisible by two. */
@JvmName("isOddLong")
fun <M : MissingPolicy> Expr<Long, M>.isOdd(): Expr<Boolean, M> = isEven().not()

/** Whether this integer is not divisible by two. */
@JvmName("isOddBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.isOdd(): Expr<Boolean, M> = isEven().not()

/** The least common multiple of the absolute values; zero when either is zero. */
@JvmName("lcmInt")
fun <M : MissingPolicy> Expr<Int, M>.lcm(other: Expr<Int, M>): Expr<Int, M> =
    leastCommonMultiple(other, numericLiteral(0).lift()) { first, second -> first.gcd(second) }.abs()

/** The least common multiple of the absolute values; zero when either is zero. */
@JvmName("lcmLong")
fun <M : MissingPolicy> Expr<Long, M>.lcm(other: Expr<Long, M>): Expr<Long, M> =
    leastCommonMultiple(other, numericLiteral(0L).lift()) { first, second -> first.gcd(second) }.abs()

/** The least common multiple of the absolute values; zero when either is zero. */
@JvmName("lcmBigInteger")
fun <M : MissingPolicy> Expr<BigInteger, M>.lcm(other: Expr<BigInteger, M>): Expr<BigInteger, M> =
    leastCommonMultiple(other, numericLiteral(BigInteger.ZERO).lift()) { first, second -> first.gcd(second) }.abs()

private fun <N : Number, M : MissingPolicy> Expr<N, M>.leastCommonMultiple(
    other: Expr<N, M>,
    zero: Expr<N, M>,
    gcd: (Expr<N, M>, Expr<N, M>) -> Expr<N, M>,
): Expr<N, M> =
    shared(this) { first ->
        shared(other) { second ->
            shared(gcd(first, second)) { divisor -> choose(divisor eq zero, zero, first / divisor * second) }
        }
    }

/** The value [fraction] of the way from [start] to [end]: start + (end - start) * fraction. */
fun <N : Number, M : MissingPolicy> lerp(
    start: Expr<N, M>,
    end: Expr<N, M>,
    fraction: Expr<N, M>,
): Expr<N, M> = shared(start) { from -> from + (end - from) * fraction }
