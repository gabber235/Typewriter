package com.typewritermc.expression

import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/** Builds reusable portable value operations without evaluating them in the author process. */
private fun <V, M : MissingPolicy> expressionCall(
    id: String,
    vararg arguments: ExpressionNode,
): Expr<V, M> = Expr(ExpressionNode.Call(OperationId(id), arguments.toList()))

fun <M : MissingPolicy> Expr<String, M>.trim(): Expr<String, M> = expressionCall("typewriter.text.trim", node)

fun <M : MissingPolicy> Expr<String, M>.lowercase(): Expr<String, M> = expressionCall("typewriter.text.lower", node)

fun <M : MissingPolicy> Expr<String, M>.uppercase(): Expr<String, M> = expressionCall("typewriter.text.upper", node)

fun <M : MissingPolicy> Expr<String, M>.titlecase(): Expr<String, M> = expressionCall("typewriter.text.title", node)

fun <M : MissingPolicy> Expr<String, M>.replace(
    target: String,
    replacement: String,
): Expr<String, M> = expressionCall("typewriter.text.replace", node, literal(target).node, literal(replacement).node)

fun <M : MissingPolicy> Expr<String, M>.replaceRegex(
    pattern: String,
    replacement: String,
): Expr<String, M> = expressionCall("typewriter.regex.replace", node, literal(pattern).node, literal(replacement).node)

/** Rounds to a positive increment in the same numeric representation, without narrowing storage width. */
fun <N : Number, M : MissingPolicy> Expr<N, M>.roundTo(
    increment: N,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<N, M> =
    expressionCall("typewriter.number.round_to", node, ExpressionNode.Literal(portableNumber(increment)), literal(rounding.name).node)

/** Produces formatted text. Locale und is deterministic; localized grouping and symbols follow host locale data. */
fun <N : Number, M : MissingPolicy> Expr<N, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> = expressionCall("typewriter.number.format", node, literal(fractionDigits).node, literal(locale).node)

/** Displays exact milliseconds with optional truncated visible fractional seconds, never changing storage. */
fun <M : MissingPolicy> Expr<Duration, M>.formatDuration(
    units: DurationDisplayUnits = DurationDisplayUnits.MinutesAndSeconds,
    fractionalSecondDigits: Int = 3,
): Expr<String, M> = expressionCall("typewriter.duration.format", node, literal(units.name).node, literal(fractionalSecondDigits).node)

/** Supports portable numeric date tokens and UTC or local display zones. */
fun <M : MissingPolicy> Expr<Instant, M>.formatTimestamp(
    pattern: String,
    zone: String = "UTC",
    locale: String = "und",
): Expr<String, M> = expressionCall("typewriter.timestamp.format", node, literal(pattern).node, literal(zone).node, literal(locale).node)

private fun portableNumber(value: Number): DataValue =
    when (value) {
        is Byte, is Short, is Int, is Long -> DataValue.Integer(value.toLong().toBigInteger())
        is BigInteger -> DataValue.Integer(value)
        is BigDecimal -> DataValue.Decimal(value.toPlainString())
        is Float, is Double -> DataValue.Float(value.toDouble())
        else -> throw IllegalArgumentException("The numeric literal is not portable.")
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.plus(other: Expr<N, M>): Expr<N, M> =
    expressionCall("typewriter.number.add", node, other.node)

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.plus(other: N): Expr<N, M> =
    expressionCall("typewriter.number.add", node, ExpressionNode.Literal(portableNumber(other)))

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.minus(other: Expr<N, M>): Expr<N, M> =
    expressionCall("typewriter.number.subtract", node, other.node)

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.minus(other: N): Expr<N, M> =
    expressionCall("typewriter.number.subtract", node, ExpressionNode.Literal(portableNumber(other)))

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.times(other: Expr<N, M>): Expr<N, M> =
    expressionCall("typewriter.number.multiply", node, other.node)

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.times(other: N): Expr<N, M> =
    expressionCall("typewriter.number.multiply", node, ExpressionNode.Literal(portableNumber(other)))

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.div(other: Expr<N, M>): Expr<N, M> =
    expressionCall("typewriter.number.divide", node, other.node)

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.div(other: N): Expr<N, M> =
    expressionCall("typewriter.number.divide", node, ExpressionNode.Literal(portableNumber(other)))

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.rem(other: Expr<N, M>): Expr<N, M> =
    expressionCall("typewriter.number.remainder", node, other.node)

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.rem(other: N): Expr<N, M> =
    expressionCall("typewriter.number.remainder", node, ExpressionNode.Literal(portableNumber(other)))

@JvmName("literalUByte")
fun literal(value: UByte): Expr<UByte, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value.toString().toBigInteger())))

@JvmName("roundUByteTo")
fun <M : MissingPolicy> Expr<UByte, M>.roundTo(
    increment: UByte,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<UByte, M> = expressionCall("typewriter.number.round_to", node, literal(increment).node, literal(rounding.name).node)

@JvmName("formatUByteNumber")
fun <M : MissingPolicy> Expr<UByte, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> = expressionCall("typewriter.number.format", node, literal(fractionDigits).node, literal(locale).node)

@JvmName("UByteplusExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.plus(other: Expr<UByte, M>): Expr<UByte, M> =
    expressionCall("typewriter.number.add", node, other.node)

@JvmName("UByteplusLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.plus(other: UByte): Expr<UByte, M> =
    expressionCall("typewriter.number.add", node, literal(other).node)

@JvmName("UByteminusExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.minus(other: Expr<UByte, M>): Expr<UByte, M> =
    expressionCall("typewriter.number.subtract", node, other.node)

@JvmName("UByteminusLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.minus(other: UByte): Expr<UByte, M> =
    expressionCall("typewriter.number.subtract", node, literal(other).node)

@JvmName("UBytetimesExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.times(other: Expr<UByte, M>): Expr<UByte, M> =
    expressionCall("typewriter.number.multiply", node, other.node)

@JvmName("UBytetimesLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.times(other: UByte): Expr<UByte, M> =
    expressionCall("typewriter.number.multiply", node, literal(other).node)

@JvmName("UBytedivExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.div(other: Expr<UByte, M>): Expr<UByte, M> =
    expressionCall("typewriter.number.divide", node, other.node)

@JvmName("UBytedivLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.div(other: UByte): Expr<UByte, M> =
    expressionCall("typewriter.number.divide", node, literal(other).node)

@JvmName("UByteremExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.rem(other: Expr<UByte, M>): Expr<UByte, M> =
    expressionCall("typewriter.number.remainder", node, other.node)

@JvmName("UByteremLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.rem(other: UByte): Expr<UByte, M> =
    expressionCall("typewriter.number.remainder", node, literal(other).node)

@JvmName("literalUShort")
fun literal(value: UShort): Expr<UShort, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value.toString().toBigInteger())))

@JvmName("roundUShortTo")
fun <M : MissingPolicy> Expr<UShort, M>.roundTo(
    increment: UShort,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<UShort, M> = expressionCall("typewriter.number.round_to", node, literal(increment).node, literal(rounding.name).node)

@JvmName("formatUShortNumber")
fun <M : MissingPolicy> Expr<UShort, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> = expressionCall("typewriter.number.format", node, literal(fractionDigits).node, literal(locale).node)

@JvmName("UShortplusExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.plus(other: Expr<UShort, M>): Expr<UShort, M> =
    expressionCall("typewriter.number.add", node, other.node)

@JvmName("UShortplusLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.plus(other: UShort): Expr<UShort, M> =
    expressionCall("typewriter.number.add", node, literal(other).node)

@JvmName("UShortminusExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.minus(other: Expr<UShort, M>): Expr<UShort, M> =
    expressionCall("typewriter.number.subtract", node, other.node)

@JvmName("UShortminusLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.minus(other: UShort): Expr<UShort, M> =
    expressionCall("typewriter.number.subtract", node, literal(other).node)

@JvmName("UShorttimesExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.times(other: Expr<UShort, M>): Expr<UShort, M> =
    expressionCall("typewriter.number.multiply", node, other.node)

@JvmName("UShorttimesLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.times(other: UShort): Expr<UShort, M> =
    expressionCall("typewriter.number.multiply", node, literal(other).node)

@JvmName("UShortdivExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.div(other: Expr<UShort, M>): Expr<UShort, M> =
    expressionCall("typewriter.number.divide", node, other.node)

@JvmName("UShortdivLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.div(other: UShort): Expr<UShort, M> =
    expressionCall("typewriter.number.divide", node, literal(other).node)

@JvmName("UShortremExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.rem(other: Expr<UShort, M>): Expr<UShort, M> =
    expressionCall("typewriter.number.remainder", node, other.node)

@JvmName("UShortremLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.rem(other: UShort): Expr<UShort, M> =
    expressionCall("typewriter.number.remainder", node, literal(other).node)

@JvmName("literalUInt")
fun literal(value: UInt): Expr<UInt, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value.toString().toBigInteger())))

@JvmName("roundUIntTo")
fun <M : MissingPolicy> Expr<UInt, M>.roundTo(
    increment: UInt,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<UInt, M> = expressionCall("typewriter.number.round_to", node, literal(increment).node, literal(rounding.name).node)

@JvmName("formatUIntNumber")
fun <M : MissingPolicy> Expr<UInt, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> = expressionCall("typewriter.number.format", node, literal(fractionDigits).node, literal(locale).node)

@JvmName("UIntplusExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.plus(other: Expr<UInt, M>): Expr<UInt, M> =
    expressionCall("typewriter.number.add", node, other.node)

@JvmName("UIntplusLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.plus(other: UInt): Expr<UInt, M> =
    expressionCall("typewriter.number.add", node, literal(other).node)

@JvmName("UIntminusExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.minus(other: Expr<UInt, M>): Expr<UInt, M> =
    expressionCall("typewriter.number.subtract", node, other.node)

@JvmName("UIntminusLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.minus(other: UInt): Expr<UInt, M> =
    expressionCall("typewriter.number.subtract", node, literal(other).node)

@JvmName("UInttimesExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.times(other: Expr<UInt, M>): Expr<UInt, M> =
    expressionCall("typewriter.number.multiply", node, other.node)

@JvmName("UInttimesLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.times(other: UInt): Expr<UInt, M> =
    expressionCall("typewriter.number.multiply", node, literal(other).node)

@JvmName("UIntdivExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.div(other: Expr<UInt, M>): Expr<UInt, M> =
    expressionCall("typewriter.number.divide", node, other.node)

@JvmName("UIntdivLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.div(other: UInt): Expr<UInt, M> =
    expressionCall("typewriter.number.divide", node, literal(other).node)

@JvmName("UIntremExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.rem(other: Expr<UInt, M>): Expr<UInt, M> =
    expressionCall("typewriter.number.remainder", node, other.node)

@JvmName("UIntremLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.rem(other: UInt): Expr<UInt, M> =
    expressionCall("typewriter.number.remainder", node, literal(other).node)

@JvmName("literalULong")
fun literal(value: ULong): Expr<ULong, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value.toString().toBigInteger())))

@JvmName("roundULongTo")
fun <M : MissingPolicy> Expr<ULong, M>.roundTo(
    increment: ULong,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<ULong, M> = expressionCall("typewriter.number.round_to", node, literal(increment).node, literal(rounding.name).node)

@JvmName("formatULongNumber")
fun <M : MissingPolicy> Expr<ULong, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> = expressionCall("typewriter.number.format", node, literal(fractionDigits).node, literal(locale).node)

@JvmName("ULongplusExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.plus(other: Expr<ULong, M>): Expr<ULong, M> =
    expressionCall("typewriter.number.add", node, other.node)

@JvmName("ULongplusLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.plus(other: ULong): Expr<ULong, M> =
    expressionCall("typewriter.number.add", node, literal(other).node)

@JvmName("ULongminusExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.minus(other: Expr<ULong, M>): Expr<ULong, M> =
    expressionCall("typewriter.number.subtract", node, other.node)

@JvmName("ULongminusLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.minus(other: ULong): Expr<ULong, M> =
    expressionCall("typewriter.number.subtract", node, literal(other).node)

@JvmName("ULongtimesExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.times(other: Expr<ULong, M>): Expr<ULong, M> =
    expressionCall("typewriter.number.multiply", node, other.node)

@JvmName("ULongtimesLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.times(other: ULong): Expr<ULong, M> =
    expressionCall("typewriter.number.multiply", node, literal(other).node)

@JvmName("ULongdivExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.div(other: Expr<ULong, M>): Expr<ULong, M> =
    expressionCall("typewriter.number.divide", node, other.node)

@JvmName("ULongdivLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.div(other: ULong): Expr<ULong, M> =
    expressionCall("typewriter.number.divide", node, literal(other).node)

@JvmName("ULongremExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.rem(other: Expr<ULong, M>): Expr<ULong, M> =
    expressionCall("typewriter.number.remainder", node, other.node)

@JvmName("ULongremLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.rem(other: ULong): Expr<ULong, M> =
    expressionCall("typewriter.number.remainder", node, literal(other).node)
