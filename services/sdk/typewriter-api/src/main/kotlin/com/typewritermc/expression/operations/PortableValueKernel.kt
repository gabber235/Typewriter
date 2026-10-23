package com.typewritermc.expression.operations

import build.skir.JsonFlavor
import build.skir.UnrecognizedValuesPolicy
import com.typewritermc.types.bigInteger
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.duration
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.requirePortable
import com.typewritermc.types.unwrapNamed
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigDecimal
import java.math.MathContext
import java.math.RoundingMode
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import kotlin.math.abs

/** Realm's kernel of the operations over values of any type. */
internal object PortableValueKernel : ValueKernel {
    override fun cast(
        value: DataValue,
        xType: TypeUse,
        types: PortableTypes,
    ): DataValue = if (types.isInstance(value, xType)) value else DataValue.NULL

    override fun compare(
        first: DataValue,
        second: DataValue,
    ): Int = portableCompare(first, second).coerceIn(-1, 1)

    override fun equals(
        first: DataValue,
        second: DataValue,
    ): Boolean = first.canonicalValueKey() == second.canonicalValueKey()

    /** Accepts readable or dense JSON; the decoded value must be portable and admitted as [xType]. */
    override fun fromJson(
        json: String,
        xType: TypeUse,
        types: PortableTypes,
    ): DataValue {
        val value =
            try {
                DataValue.serializer.fromJsonCode(json, UnrecognizedValuesPolicy.DROP).requirePortable()
            } catch (failure: IllegalArgumentException) {
                throw invalidJson(failure)
            } catch (failure: IllegalStateException) {
                throw invalidJson(failure)
            }
        if (!types.admits(
                value,
                xType,
            )
        ) {
            throw OperationFailure(KernelFailure.IncompatibleValue, "The value does not have the requested type.")
        }
        return value
    }

    override fun instanceOf(
        value: DataValue,
        xType: TypeUse,
        types: PortableTypes,
    ): Boolean = types.isInstance(value, xType)

    /** Looks through named wrappers, so a named value whose payload is null is null. */
    override fun isNull(value: DataValue): Boolean = value.unwrapNamed() == DataValue.NULL

    override fun let(
        value: DataValue,
        body: PortableApply,
    ): DataValue = body.invoke(value)

    override fun toJson(value: DataValue): String = canonicalJson(value)

    override fun toText(value: DataValue): String =
        when (val scalar = value.unwrapNamed()) {
            DataValue.NULL -> "null"
            DataValue.UNIT -> "unit"
            is DataValue.BooleanWrapper -> scalar.value.toString()
            is DataValue.IntegerWrapper -> scalar.bigInteger.toString()
            is DataValue.DecimalWrapper -> scalar.value.toBigDecimal().canonicalDecimal()
            is DataValue.FloatWrapper -> ecmaScriptNumber(scalar.value)
            is DataValue.StringValueWrapper -> scalar.value
            is DataValue.TimestampWrapper -> timestampText(scalar.value)
            is DataValue.DurationWrapper -> durationText(scalar.duration.inWholeMilliseconds)
            is DataValue.EnumCaseWrapper -> scalar.value
            else -> canonicalJson(scalar)
        }

    override fun unwrap(value: DataValue): DataValue =
        (value as? DataValue.NamedWrapper)?.payload ?: throw illTyped("Expected a named value.")

    override fun wrap(
        payload: DataValue,
        xType: TypeUse,
    ): DataValue =
        DataValue.named((xType as? TypeUse.NamedWrapper)?.value ?: throw illTyped("Only named types wrap a representation."), payload)

    private fun invalidJson(failure: Exception) =
        OperationFailure(
            KernelFailure.InvalidJson,
            failure.message ?: "The text is not canonical value JSON.",
        )
}

/**
 * The portable order: text by code point sequence, numbers by value within one family, false before true, timestamps
 * and durations chronologically, after removing nominal wrappers. Any other pair is ill typed.
 */
internal fun portableCompare(
    left: DataValue,
    right: DataValue,
): Int {
    val first = left.unwrapNamed()
    val second = right.unwrapNamed()
    return when {
        first is DataValue.StringValueWrapper && second is DataValue.StringValueWrapper -> {
            compareCodePoints(first.value, second.value)
        }

        first is DataValue.IntegerWrapper && second is DataValue.IntegerWrapper -> {
            first.bigInteger.compareTo(second.bigInteger)
        }

        first is DataValue.DecimalWrapper && second is DataValue.DecimalWrapper -> {
            first.value.toBigDecimal().compareTo(
                second.value.toBigDecimal(),
            )
        }

        first is DataValue.FloatWrapper && second is DataValue.FloatWrapper -> {
            compareFloats(first.value, second.value)
        }

        first is DataValue.BooleanWrapper && second is DataValue.BooleanWrapper -> {
            first.value.compareTo(second.value)
        }

        first is DataValue.TimestampWrapper && second is DataValue.TimestampWrapper -> {
            first.value.compareTo(second.value)
        }

        first is DataValue.DurationWrapper && second is DataValue.DurationWrapper -> {
            first.duration.compareTo(second.duration)
        }

        else -> {
            throw illTyped("The values have no portable order.")
        }
    }.coerceIn(-1, 1)
}

/** Floats order by value, so negative and positive zero are equal. */
private fun compareFloats(
    first: Double,
    second: Double,
): Int =
    when {
        first < second -> -1
        first > second -> 1
        else -> 0
    }

private fun compareCodePoints(
    left: String,
    right: String,
): Int {
    val first = left.codePoints().iterator()
    val second = right.codePoints().iterator()
    while (first.hasNext() && second.hasNext()) {
        val comparison = first.nextInt().compareTo(second.nextInt())
        if (comparison != 0) return comparison
    }
    return first.hasNext().compareTo(second.hasNext())
}

/** The Skir readable JSON of the value, without insignificant whitespace. */
private fun canonicalJson(value: DataValue): String {
    val readable = DataValue.serializer.toJsonCode(value, JsonFlavor.READABLE)
    return buildString(readable.length) {
        var inString = false
        var escaped = false
        readable.forEach { character ->
            when {
                inString -> {
                    append(character)
                    if (escaped) {
                        escaped = false
                    } else if (character == '\\') {
                        escaped = true
                    } else if (character == '"') {
                        inString = false
                    }
                }

                character == '"' -> {
                    inString = true
                    append(character)
                }

                character !in JSON_WHITESPACE -> {
                    append(character)
                }
            }
        }
    }
}

/**
 * ECMAScript Number::toString: the shortest digits that round trip (the JDK's [Double.toString] digits), in plain
 * notation for magnitudes from 1e-6 (included) up to 1e21 (excluded) and exponent notation such as `1e-7` or `1.5e+21`
 * otherwise. Zero prints `0`.
 */
internal fun ecmaScriptNumber(value: Double): String {
    if (value == 0.0) return "0"
    if (value < 0) return "-" + ecmaScriptNumber(-value)
    val shortest = shortestDecimal(value)
    val digits = shortest.unscaledValue().toString()
    val count = digits.length
    val exponent = count - shortest.scale()
    return when {
        exponent in count..21 -> {
            digits + "0".repeat(exponent - count)
        }

        exponent in 1..21 -> {
            digits.substring(0, exponent) + "." + digits.substring(exponent)
        }

        exponent in -5..0 -> {
            "0." + "0".repeat(-exponent) + digits
        }

        else -> {
            val power = exponent - 1
            val sign = if (power < 0) "-" else "+"
            val mantissa = if (count == 1) digits else digits.substring(0, 1) + "." + digits.substring(1)
            "${mantissa}e$sign${abs(power)}"
        }
    }
}

/**
 * The shortest decimal that reads back as [value], closest to it among equally short ones. [Double.toString] gives
 * that, except that it always prints two significant digits, where it may prefer `4.9E-324` over a one digit
 * decimal that also reads back.
 */
private fun shortestDecimal(value: Double): BigDecimal {
    val printed = BigDecimal(value.toString()).stripTrailingZeros()
    if (printed.precision() != 2) return printed
    val single = BigDecimal(value).round(MathContext(1, RoundingMode.HALF_EVEN))
    return if (single.toDouble() == value) single.stripTrailingZeros() else printed
}

/** `YYYY-MM-DDTHH:MM:SS.sssZ` in UTC with exactly three fraction digits. */
private fun timestampText(value: java.time.Instant): String = TIMESTAMP_FORMAT.format(value)

private val TIMESTAMP_FORMAT: DateTimeFormatter = DateTimeFormatter.ofPattern("uuuu-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)

/** ISO 8601 with hours, minutes and seconds only: `PT0S`, `PT25H`, `PT1M30.5S`, `-PT1.5S`. */
private fun durationText(milliseconds: Long): String {
    if (milliseconds == 0L) return "PT0S"
    val magnitude = kotlin.math.abs(milliseconds)
    val hours = magnitude / 3_600_000
    val minutes = magnitude / 60_000 % 60
    val seconds = magnitude / 1_000 % 60
    val fraction = magnitude % 1_000
    return buildString {
        if (milliseconds < 0) append('-')
        append("PT")
        if (hours > 0) append(hours).append('H')
        if (minutes > 0) append(minutes).append('M')
        if (seconds > 0 || fraction > 0) {
            append(seconds)
            if (fraction > 0) append('.').append(fraction.toString().padStart(3, '0').trimEnd('0'))
            append('S')
        }
    }
}

/** The insignificant whitespace JSON allows between tokens. */
private const val JSON_WHITESPACE = " \n\r\t"
