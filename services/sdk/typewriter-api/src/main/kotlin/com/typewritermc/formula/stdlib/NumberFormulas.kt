package com.typewritermc.formula.stdlib

import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFailureException
import com.typewritermc.formula.FormulaLimits
import com.typewritermc.formula.TypewriterFormulaName
import com.typewritermc.formula.TypewriterFormulaProvider

/**
 * Arithmetic, comparison and conversion of numbers. Arithmetic is checked: overflow, division by zero, a result that
 * is not finite and a narrowing conversion that does not fit fail the evaluation instead of wrapping. Kotlin's own
 * members of these names would wrap, so each function has another Kotlin name.
 */
@TypewriterFormulaProvider
object NumberFormulas {
    @TypewriterFormulaName("plus")
    fun Int.add(other: Int): Int = Math.addExact(this, other)

    @TypewriterFormulaName("minus")
    fun Int.subtract(other: Int): Int = Math.subtractExact(this, other)

    @TypewriterFormulaName("times")
    fun Int.multiply(other: Int): Int = Math.multiplyExact(this, other)

    @TypewriterFormulaName("div")
    fun Int.divide(other: Int): Int = Math.divideExact(this, other)

    @TypewriterFormulaName("rem")
    fun Int.remainder(other: Int): Int = this % other

    @TypewriterFormulaName("unaryMinus")
    fun Int.negate(): Int = Math.negateExact(this)

    @TypewriterFormulaName("compareTo")
    fun Int.compare(other: Int): Int = compareTo(other)

    /**
     * `1..4` is every Int from this to [last], both included; empty when [last] is smaller. Each item costs a step, so
     * a range longer than the step limit fails with StepLimit before it is built.
     */
    @TypewriterFormulaName("rangeTo")
    fun Int.upTo(last: Int): List<Int> {
        if (last.toLong() - this >= FormulaLimits.MAX_STEPS) throw FormulaFailureException(FormulaFailure.StepLimit)
        return (this..last).toList()
    }

    @TypewriterFormulaName("toLong")
    fun Int.widen(): Long = toLong()

    @TypewriterFormulaName("toDouble")
    fun Int.asDouble(): Double = toDouble()

    @TypewriterFormulaName("plus")
    fun Long.add(other: Long): Long = Math.addExact(this, other)

    @TypewriterFormulaName("minus")
    fun Long.subtract(other: Long): Long = Math.subtractExact(this, other)

    @TypewriterFormulaName("times")
    fun Long.multiply(other: Long): Long = Math.multiplyExact(this, other)

    @TypewriterFormulaName("div")
    fun Long.divide(other: Long): Long = Math.divideExact(this, other)

    @TypewriterFormulaName("rem")
    fun Long.remainder(other: Long): Long = this % other

    @TypewriterFormulaName("unaryMinus")
    fun Long.negate(): Long = Math.negateExact(this)

    @TypewriterFormulaName("compareTo")
    fun Long.compare(other: Long): Int = compareTo(other)

    @TypewriterFormulaName("toInt")
    fun Long.narrow(): Int = Math.toIntExact(this)

    @TypewriterFormulaName("toDouble")
    fun Long.asDouble(): Double = toDouble()

    @TypewriterFormulaName("plus")
    fun Double.add(other: Double): Double = finite(this + other)

    @TypewriterFormulaName("minus")
    fun Double.subtract(other: Double): Double = finite(this - other)

    @TypewriterFormulaName("times")
    fun Double.multiply(other: Double): Double = finite(this * other)

    @TypewriterFormulaName("div")
    fun Double.divide(other: Double): Double = finite(this / other)

    @TypewriterFormulaName("rem")
    fun Double.remainder(other: Double): Double = finite(this % other)

    @TypewriterFormulaName("unaryMinus")
    fun Double.negate(): Double = -this

    @TypewriterFormulaName("compareTo")
    fun Double.compare(other: Double): Int = compareTo(other)

    /** The whole part of this number, toward zero; fails when it does not fit an Int. */
    @TypewriterFormulaName("toInt")
    fun Double.truncate(): Int {
        if (isNaN() || this <= Int.MIN_VALUE - 1.0 || this >= Int.MAX_VALUE + 1.0) throw ArithmeticException("$this does not fit an Int.")
        return toInt()
    }

    private fun finite(value: Double): Double {
        if (!value.isFinite()) throw FormulaFailureException(FormulaFailure.NotFinite)
        return value
    }
}
