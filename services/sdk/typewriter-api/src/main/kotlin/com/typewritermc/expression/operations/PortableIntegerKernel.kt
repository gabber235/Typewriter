package com.typewritermc.expression.operations

import java.math.BigInteger

/** Realm's kernel of the integer operations: unbounded integers with two's complement bit semantics. */
internal object PortableIntegerKernel : IntegerKernel {
    override fun bitAnd(
        first: BigInteger,
        second: BigInteger,
        rest: List<BigInteger>,
    ): BigInteger = rest.fold(first.and(second), BigInteger::and)

    override fun bitNot(value: BigInteger): BigInteger = value.not()

    override fun bitOr(
        first: BigInteger,
        second: BigInteger,
        rest: List<BigInteger>,
    ): BigInteger = rest.fold(first.or(second), BigInteger::or)

    override fun bitXor(
        first: BigInteger,
        second: BigInteger,
        rest: List<BigInteger>,
    ): BigInteger = rest.fold(first.xor(second), BigInteger::xor)

    override fun gcd(
        first: BigInteger,
        second: BigInteger,
    ): BigInteger = first.gcd(second)

    override fun shiftLeft(
        value: BigInteger,
        bits: Int,
    ): BigInteger {
        val distance = requireShift(bits)
        if (value.signum() != 0 && value.bitLength().toLong() + distance > MAX_RESULT_BITS) throw magnitudeLimit()
        return value.shiftLeft(distance).requireMagnitude()
    }

    /** Arithmetic: the result rounds toward negative infinity. */
    override fun shiftRight(
        value: BigInteger,
        bits: Int,
    ): BigInteger = value.shiftRight(requireShift(bits))

    private fun requireShift(bits: Int): Int {
        if (bits < 0) throw OperationFailure(KernelFailure.NegativeShift, "The shift distance $bits is negative.")
        return bits
    }
}
