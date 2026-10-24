package com.typewritermc.expression.operations

import com.typewritermc.types.bits
import com.typewritermc.types.signed
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigDecimal
import java.math.BigInteger
import java.math.MathContext
import java.math.RoundingMode as JavaRoundingMode

/**
 * Realm's kernel of the numeric operations. Every operand of one call belongs to one family: integers are exact and
 * unbounded, decimals are exact except where division and square roots round to 34 significant digits half even,
 * and floats follow IEEE 754 binary64 but never produce an infinite or undefined value.
 */
internal object PortableNumberKernel : NumberKernel {
    override fun add(
        first: PortableNumber,
        second: PortableNumber,
        rest: List<PortableNumber>,
    ): PortableNumber =
        (listOf(second) + rest).fold(first) { sum, operand -> sum.combine(operand, BigInteger::add, BigDecimal::add, Double::plus) }

    override fun subtract(
        first: PortableNumber,
        second: PortableNumber,
    ): PortableNumber = first.combine(second, BigInteger::subtract, BigDecimal::subtract, Double::minus)

    override fun multiply(
        first: PortableNumber,
        second: PortableNumber,
        rest: List<PortableNumber>,
    ): PortableNumber =
        (listOf(second) + rest).fold(first) { product, operand ->
            product.combine(
                operand,
                { left, right -> left.multiply(right).requireMagnitude() },
                { left, right -> left.multiply(right).requireMagnitude() },
                Double::times,
            )
        }

    override fun divide(
        dividend: PortableNumber,
        divisor: PortableNumber,
    ): PortableNumber {
        requireNonzero(divisor)
        return dividend.combine(divisor, BigInteger::divide, { left, right -> left.divide(right, MathContext.DECIMAL128) }, Double::div)
    }

    override fun remainder(
        dividend: PortableNumber,
        divisor: PortableNumber,
    ): PortableNumber {
        requireNonzero(divisor)
        return dividend.combine(divisor, BigInteger::rem, BigDecimal::remainder, Double::rem)
    }

    /** `increment * R(value / increment)`, with the quotient rounded exactly; floats take their exact binary value. */
    override fun round(
        value: PortableNumber,
        increment: PortableNumber,
        mode: RoundingMode,
    ): PortableNumber {
        family(value, increment)
        val step = increment.exact()
        if (step.signum() <= 0) throw OperationFailure(KernelFailure.InvalidRoundingIncrement, "The rounding increment must be positive.")
        val rounded = value.exact().divide(step, 0, mode.java()).multiply(step)
        return when (value) {
            is PortableNumber.Integer -> PortableNumber.Integer(rounded.toBigIntegerExact())
            is PortableNumber.Decimal -> PortableNumber.Decimal(rounded)
            is PortableNumber.Float -> PortableNumber.Float(finite(rounded.toDouble()))
        }
    }

    /** Exact for integers and decimals; floats square and multiply over the exponent bits from the least significant. */
    override fun power(
        value: PortableNumber,
        exponent: Int,
    ): PortableNumber {
        if (exponent < 0) throw OperationFailure(KernelFailure.NegativeExponent, "The exponent $exponent is negative.")
        return when (value) {
            is PortableNumber.Integer -> {
                val base = value.value
                if (base.abs() > BigInteger.ONE && (base.bitLength() - 1).toLong() * exponent > MAX_RESULT_BITS) throw magnitudeLimit()
                PortableNumber.Integer(base.pow(exponent).requireMagnitude())
            }

            is PortableNumber.Decimal -> {
                val base = value.value.stripTrailingZeros()
                val unscaled = base.unscaledValue()
                val growing = unscaled.abs() > BigInteger.ONE && (unscaled.bitLength() - 1).toLong() * exponent > MAX_RESULT_BITS
                if (growing || Math.abs(base.scale().toLong()) * exponent > MAX_RESULT_DIGITS) throw magnitudeLimit()
                // BigDecimal.pow stops at 999999999; -1, 0 and 1 stay small for any exponent.
                val trivial = base.scale() == 0 && unscaled.abs() <= BigInteger.ONE
                val power = if (trivial) BigDecimal(unscaled.pow(exponent)) else base.pow(exponent)
                PortableNumber.Decimal(power.requireMagnitude())
            }

            is PortableNumber.Float -> {
                var result = 1.0
                var base = value.value
                var remaining = exponent
                while (remaining > 0) {
                    if (remaining and 1 == 1) result *= base
                    base *= base
                    remaining = remaining shr 1
                }
                PortableNumber.Float(finite(result))
            }
        }
    }

    override fun sqrt(value: PortableNumber): PortableNumber {
        if (value.signum() < 0) throw OperationFailure(KernelFailure.NegativeSquareRoot, "The value is negative.")
        return when (value) {
            is PortableNumber.Integer -> PortableNumber.Integer(value.value.sqrt())
            is PortableNumber.Decimal -> PortableNumber.Decimal(decimalSquareRoot(value.value))
            is PortableNumber.Float -> PortableNumber.Float(kotlin.math.sqrt(value.value))
        }
    }

    /** Exact conversion to the scalar numeric type [mType], or inexact_conversion. */
    override fun convert(
        value: PortableNumber,
        mType: TypeUse,
    ): PortableNumber {
        val kind = (mType as? TypeUse.ScalarWrapper)?.value ?: throw illTyped("A numeric conversion targets a scalar numeric type.")
        val exact = value.exact()
        return when (kind) {
            is ScalarKind.IntegerWrapper -> {
                val whole = exact.toBigIntegerExactOrNull() ?: inexact(value, mType)
                val width = kind.value.width
                val minimum = if (width.signed) BigInteger.ONE.shiftLeft(width.bits - 1).negate() else BigInteger.ZERO
                val maximum =
                    (if (width.signed) BigInteger.ONE.shiftLeft(width.bits - 1) else BigInteger.ONE.shiftLeft(width.bits)) - BigInteger.ONE
                if (whole !in minimum..maximum) inexact(value, mType)
                PortableNumber.Integer(whole)
            }

            is ScalarKind.FloatWrapper -> {
                val double = exact.toDouble()
                val representable =
                    double.isFinite() && BigDecimal(double).compareTo(exact) == 0 &&
                        (kind.value.width != FloatWidth.THIRTY_TWO || double.toFloat().toDouble() == double)
                if (!representable) inexact(value, mType)
                PortableNumber.Float(double)
            }

            ScalarKind.DECIMAL -> {
                PortableNumber.Decimal(exact)
            }

            else -> {
                throw illTyped("A numeric conversion targets a scalar numeric type.")
            }
        }
    }

    private fun inexact(
        value: PortableNumber,
        target: TypeUse,
    ): Nothing = throw OperationFailure(KernelFailure.InexactConversion, "The value $value has no exact representation in $target.")
}

/** Combines two numbers of one family; a float result must be finite. */
private fun PortableNumber.combine(
    other: PortableNumber,
    integer: (BigInteger, BigInteger) -> BigInteger,
    decimal: (BigDecimal, BigDecimal) -> BigDecimal,
    float: (Double, Double) -> Double,
): PortableNumber =
    when (this) {
        is PortableNumber.Integer -> PortableNumber.Integer(integer(value, (other as? PortableNumber.Integer ?: mixed()).value))
        is PortableNumber.Decimal -> PortableNumber.Decimal(decimal(value, (other as? PortableNumber.Decimal ?: mixed()).value))
        is PortableNumber.Float -> PortableNumber.Float(finite(float(value, (other as? PortableNumber.Float ?: mixed()).value)))
    }

private fun family(
    first: PortableNumber,
    second: PortableNumber,
) {
    if (first::class != second::class) mixed()
}

private fun mixed(): Nothing = throw illTyped("Numeric operands mix integer, float and decimal.")

private fun requireNonzero(divisor: PortableNumber) {
    if (divisor.signum() == 0) throw OperationFailure(KernelFailure.DivisionByZero, "The divisor is zero.")
}

private fun PortableNumber.signum(): Int =
    when (this) {
        is PortableNumber.Integer -> {
            value.signum()
        }

        is PortableNumber.Decimal -> {
            value.signum()
        }

        is PortableNumber.Float -> {
            when {
                value > 0.0 -> 1
                value < 0.0 -> -1
                else -> 0
            }
        }
    }

/** The exact value; a float contributes its exact binary value. */
private fun PortableNumber.exact(): BigDecimal =
    when (this) {
        is PortableNumber.Integer -> BigDecimal(value)
        is PortableNumber.Decimal -> value
        is PortableNumber.Float -> BigDecimal(value)
    }

private fun BigDecimal.toBigIntegerExactOrNull(): BigInteger? =
    if (signum() == 0 ||
        stripTrailingZeros().scale() <= 0
    ) {
        toBigInteger()
    } else {
        null
    }

/** A float result, or non_finite_number when IEEE arithmetic produced an infinite or undefined value. */
internal fun finite(value: Double): Double {
    if (!value.isFinite()) throw OperationFailure(KernelFailure.NonFiniteNumber, "Floating point arithmetic produced $value.")
    return value
}

private fun RoundingMode.java(): JavaRoundingMode =
    when (this) {
        RoundingMode.NearestTiesToEven -> JavaRoundingMode.HALF_EVEN
        RoundingMode.NearestTiesAway -> JavaRoundingMode.HALF_UP
        RoundingMode.TowardZero -> JavaRoundingMode.DOWN
        RoundingMode.Floor -> JavaRoundingMode.FLOOR
        RoundingMode.Ceiling -> JavaRoundingMode.CEILING
    }

/**
 * The square root rounded to 34 significant digits, half even, from an exact integer square root: the value is
 * scaled to an integer of at least 70 digits, whose floor root has at least 35, and the exactness of that root breaks
 * apparent ties.
 */
private fun decimalSquareRoot(value: BigDecimal): BigDecimal {
    if (value.signum() == 0) return BigDecimal.ZERO
    val unscaled = value.unscaledValue()
    val scale = value.scale()
    val digits = unscaled.toString().length
    val half = maxOf(Math.floorDiv(scale + 1, 2), Math.floorDiv(SQUARE_DIGITS - digits + scale + 1, 2))
    val scaled = unscaled.multiply(BigInteger.TEN.pow(2 * half - scale))
    val root = scaled.sqrt()
    val exact = root.multiply(root) == scaled
    val extra = root.toString().length - DECIMAL_DIGITS
    val unit = BigInteger.TEN.pow(extra)
    val (kept, dropped) = root.divideAndRemainder(unit)
    val midpoint = unit.shiftRight(1)
    val roundUp =
        when (dropped.compareTo(midpoint)) {
            1 -> true
            -1 -> false
            else -> !exact || kept.testBit(0)
        }
    return BigDecimal(if (roundUp) kept + BigInteger.ONE else kept, half - extra)
}

private const val DECIMAL_DIGITS = 34
private const val SQUARE_DIGITS = 70
