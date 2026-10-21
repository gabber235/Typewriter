package com.typewritermc.expression

import com.typewritermc.types.integer
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.NumberArithmeticOperation
import skirout.editor.v1.expression.TextUnaryOperation
import skirout.editor.v1.type_catalog.DataValue
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/** Composes immutable builders while lowering children in their actual lexical environment. */
internal fun <V, M : MissingPolicy> composeExpressions(
    vararg arguments: Expr<*, *>,
    make: (List<ExpressionNode>) -> ExpressionNode,
): Expr<V, M> {
    val captured = arguments.toList()
    return Expr { environment -> make(captured.map { it.lower(environment) }) }
}

fun <M : MissingPolicy> Expr<String, M>.trim(): Expr<String, M> =
    composeExpressions(this) { nodes -> ExpressionNode.createTextUnary(operation = TextUnaryOperation.TRIM, source = nodes[0]) }

fun <M : MissingPolicy> Expr<String, M>.lowercase(): Expr<String, M> =
    composeExpressions(this) { nodes -> ExpressionNode.createTextUnary(operation = TextUnaryOperation.LOWER, source = nodes[0]) }

fun <M : MissingPolicy> Expr<String, M>.uppercase(): Expr<String, M> =
    composeExpressions(this) { nodes -> ExpressionNode.createTextUnary(operation = TextUnaryOperation.UPPER, source = nodes[0]) }

fun <M : MissingPolicy> Expr<String, M>.titlecase(): Expr<String, M> =
    composeExpressions(this) { nodes -> ExpressionNode.createTextUnary(operation = TextUnaryOperation.TITLE, source = nodes[0]) }

fun <M : MissingPolicy> Expr<String, M>.replace(
    target: String,
    replacement: String,
): Expr<String, M> =
    composeExpressions(
        this,
        literal(target),
        literal(replacement),
    ) { nodes -> ExpressionNode.createTextReplace(source = nodes[0], target = nodes[1], replacement = nodes[2]) }

fun <M : MissingPolicy> Expr<String, M>.replaceRegex(
    pattern: String,
    replacement: String,
): Expr<String, M> =
    composeExpressions(
        this,
        literal(pattern),
        literal(replacement),
    ) { nodes -> ExpressionNode.createRegexReplace(source = nodes[0], pattern = nodes[1], replacement = nodes[2]) }

/** Rounds to a positive increment in the same numeric representation, without narrowing storage width. */
fun <N : Number, M : MissingPolicy> Expr<N, M>.roundTo(
    increment: N,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<N, M> =
    composeExpressions(
        this,
        portableLiteral<Number>(portableNumber(increment)),
        literal(rounding.name),
    ) { nodes -> ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2]) }

/** Produces formatted text. Locale und is deterministic; localized grouping and symbols follow host locale data. */
fun <N : Number, M : MissingPolicy> Expr<N, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> =
    composeExpressions(
        this,
        literal(fractionDigits),
        literal(locale),
    ) { nodes -> ExpressionNode.createNumberFormat(source = nodes[0], fractionDigits = nodes[1], locale = nodes[2]) }

/** Displays exact milliseconds with optional truncated visible fractional seconds, never changing storage. */
fun <M : MissingPolicy> Expr<Duration, M>.formatDuration(
    units: DurationDisplayUnits = DurationDisplayUnits.MinutesAndSeconds,
    fractionalSecondDigits: Int = 3,
): Expr<String, M> =
    composeExpressions(
        this,
        literal(units.name),
        literal(fractionalSecondDigits),
    ) { nodes -> ExpressionNode.createDurationFormat(source = nodes[0], units = nodes[1], fractionDigits = nodes[2]) }

/** Supports portable numeric date tokens and UTC or local display zones. */
fun <M : MissingPolicy> Expr<Instant, M>.formatTimestamp(
    pattern: String,
    zone: String = "UTC",
    locale: String = "und",
): Expr<String, M> =
    composeExpressions(
        this,
        literal(pattern),
        literal(zone),
        literal(locale),
    ) { nodes -> ExpressionNode.createTimestampFormat(source = nodes[0], pattern = nodes[1], zone = nodes[2], locale = nodes[3]) }

private fun portableNumber(value: Number): DataValue =
    when (value) {
        is Byte, is Short, is Int, is Long -> DataValue.integer(value.toLong().toBigInteger())
        is BigInteger -> DataValue.integer(value)
        is BigDecimal -> DataValue.DecimalWrapper(value.toPlainString())
        is Float, is Double -> DataValue.FloatWrapper(value.toDouble())
        else -> throw IllegalArgumentException("The numeric literal is not portable.")
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.plus(other: Expr<N, M>): Expr<N, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.plus(other: N): Expr<N, M> =
    composeExpressions(
        this,
        portableLiteral<Number>(portableNumber(other)),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.minus(other: Expr<N, M>): Expr<N, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.minus(other: N): Expr<N, M> =
    composeExpressions(
        this,
        portableLiteral<Number>(portableNumber(other)),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.times(other: Expr<N, M>): Expr<N, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.times(other: N): Expr<N, M> =
    composeExpressions(
        this,
        portableLiteral<Number>(portableNumber(other)),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.div(other: Expr<N, M>): Expr<N, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.div(other: N): Expr<N, M> =
    composeExpressions(
        this,
        portableLiteral<Number>(portableNumber(other)),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.rem(other: Expr<N, M>): Expr<N, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

operator fun <N : Number, M : MissingPolicy> Expr<N, M>.rem(other: N): Expr<N, M> =
    composeExpressions(
        this,
        portableLiteral<Number>(portableNumber(other)),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("literalUByte")
fun literal(value: UByte): Expr<UByte, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

@JvmName("roundUByteTo")
fun <M : MissingPolicy> Expr<UByte, M>.roundTo(
    increment: UByte,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<UByte, M> =
    composeExpressions(
        this,
        literal(increment),
        literal(rounding.name),
    ) { nodes -> ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2]) }

@JvmName("formatUByteNumber")
fun <M : MissingPolicy> Expr<UByte, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> =
    composeExpressions(
        this,
        literal(fractionDigits),
        literal(locale),
    ) { nodes -> ExpressionNode.createNumberFormat(source = nodes[0], fractionDigits = nodes[1], locale = nodes[2]) }

@JvmName("UByteplusExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.plus(other: Expr<UByte, M>): Expr<UByte, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UByteplusLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.plus(other: UByte): Expr<UByte, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UByteminusExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.minus(other: Expr<UByte, M>): Expr<UByte, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UByteminusLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.minus(other: UByte): Expr<UByte, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UBytetimesExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.times(other: Expr<UByte, M>): Expr<UByte, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UBytetimesLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.times(other: UByte): Expr<UByte, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UBytedivExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.div(other: Expr<UByte, M>): Expr<UByte, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UBytedivLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.div(other: UByte): Expr<UByte, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UByteremExpression")
operator fun <M : MissingPolicy> Expr<UByte, M>.rem(other: Expr<UByte, M>): Expr<UByte, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UByteremLiteral")
operator fun <M : MissingPolicy> Expr<UByte, M>.rem(other: UByte): Expr<UByte, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("literalUShort")
fun literal(value: UShort): Expr<UShort, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

@JvmName("roundUShortTo")
fun <M : MissingPolicy> Expr<UShort, M>.roundTo(
    increment: UShort,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<UShort, M> =
    composeExpressions(
        this,
        literal(increment),
        literal(rounding.name),
    ) { nodes -> ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2]) }

@JvmName("formatUShortNumber")
fun <M : MissingPolicy> Expr<UShort, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> =
    composeExpressions(
        this,
        literal(fractionDigits),
        literal(locale),
    ) { nodes -> ExpressionNode.createNumberFormat(source = nodes[0], fractionDigits = nodes[1], locale = nodes[2]) }

@JvmName("UShortplusExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.plus(other: Expr<UShort, M>): Expr<UShort, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortplusLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.plus(other: UShort): Expr<UShort, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortminusExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.minus(other: Expr<UShort, M>): Expr<UShort, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortminusLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.minus(other: UShort): Expr<UShort, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShorttimesExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.times(other: Expr<UShort, M>): Expr<UShort, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShorttimesLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.times(other: UShort): Expr<UShort, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortdivExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.div(other: Expr<UShort, M>): Expr<UShort, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortdivLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.div(other: UShort): Expr<UShort, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortremExpression")
operator fun <M : MissingPolicy> Expr<UShort, M>.rem(other: Expr<UShort, M>): Expr<UShort, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UShortremLiteral")
operator fun <M : MissingPolicy> Expr<UShort, M>.rem(other: UShort): Expr<UShort, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("literalUInt")
fun literal(value: UInt): Expr<UInt, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

@JvmName("roundUIntTo")
fun <M : MissingPolicy> Expr<UInt, M>.roundTo(
    increment: UInt,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<UInt, M> =
    composeExpressions(
        this,
        literal(increment),
        literal(rounding.name),
    ) { nodes -> ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2]) }

@JvmName("formatUIntNumber")
fun <M : MissingPolicy> Expr<UInt, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> =
    composeExpressions(
        this,
        literal(fractionDigits),
        literal(locale),
    ) { nodes -> ExpressionNode.createNumberFormat(source = nodes[0], fractionDigits = nodes[1], locale = nodes[2]) }

@JvmName("UIntplusExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.plus(other: Expr<UInt, M>): Expr<UInt, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntplusLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.plus(other: UInt): Expr<UInt, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntminusExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.minus(other: Expr<UInt, M>): Expr<UInt, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntminusLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.minus(other: UInt): Expr<UInt, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UInttimesExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.times(other: Expr<UInt, M>): Expr<UInt, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UInttimesLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.times(other: UInt): Expr<UInt, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntdivExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.div(other: Expr<UInt, M>): Expr<UInt, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntdivLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.div(other: UInt): Expr<UInt, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntremExpression")
operator fun <M : MissingPolicy> Expr<UInt, M>.rem(other: Expr<UInt, M>): Expr<UInt, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("UIntremLiteral")
operator fun <M : MissingPolicy> Expr<UInt, M>.rem(other: UInt): Expr<UInt, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("literalULong")
fun literal(value: ULong): Expr<ULong, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

@JvmName("roundULongTo")
fun <M : MissingPolicy> Expr<ULong, M>.roundTo(
    increment: ULong,
    rounding: Rounding = Rounding.NearestTiesToEven,
): Expr<ULong, M> =
    composeExpressions(
        this,
        literal(increment),
        literal(rounding.name),
    ) { nodes -> ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2]) }

@JvmName("formatULongNumber")
fun <M : MissingPolicy> Expr<ULong, M>.formatNumber(
    fractionDigits: Int,
    locale: String = "und",
): Expr<String, M> =
    composeExpressions(
        this,
        literal(fractionDigits),
        literal(locale),
    ) { nodes -> ExpressionNode.createNumberFormat(source = nodes[0], fractionDigits = nodes[1], locale = nodes[2]) }

@JvmName("ULongplusExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.plus(other: Expr<ULong, M>): Expr<ULong, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongplusLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.plus(other: ULong): Expr<ULong, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.ADD,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongminusExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.minus(other: Expr<ULong, M>): Expr<ULong, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongminusLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.minus(other: ULong): Expr<ULong, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.SUBTRACT,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongtimesExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.times(other: Expr<ULong, M>): Expr<ULong, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongtimesLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.times(other: ULong): Expr<ULong, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.MULTIPLY,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongdivExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.div(other: Expr<ULong, M>): Expr<ULong, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongdivLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.div(other: ULong): Expr<ULong, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.DIVIDE,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongremExpression")
operator fun <M : MissingPolicy> Expr<ULong, M>.rem(other: Expr<ULong, M>): Expr<ULong, M> =
    composeExpressions(
        this,
        other,
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }

@JvmName("ULongremLiteral")
operator fun <M : MissingPolicy> Expr<ULong, M>.rem(other: ULong): Expr<ULong, M> =
    composeExpressions(
        this,
        literal(other),
    ) { nodes ->
        ExpressionNode.createNumberArithmetic(
            operation = NumberArithmeticOperation.REMAINDER,
            first = nodes[0],
            second = nodes[1],
            remaining = emptyList(),
        )
    }
