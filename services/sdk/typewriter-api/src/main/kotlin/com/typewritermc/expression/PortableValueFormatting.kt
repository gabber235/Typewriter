package com.typewritermc.expression

import com.typewritermc.types.DataValue
import com.typewritermc.types.isPortableDuration
import com.typewritermc.types.unwrapNamed
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.DecimalFormat
import java.text.NumberFormat
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Shared rounding modes retain the numeric representation of their operand. */
enum class Rounding { NearestTiesToEven, TowardZero, Floor, Ceiling }

enum class DurationDisplayUnits { MinutesAndSeconds, HoursMinutesAndSeconds }

internal fun roundPortableNumber(values: List<DataValue>): DataValue {
    val value = values[0].unwrapNamed()
    val increment = values[1].unwrapNamed()
    if (value::class !=
        increment::class
    ) {
        throw OperationFailure("numeric_family_mismatch", "Rounding operands must use one numeric representation.")
    }
    val step = increment.displayDecimal()
    if (step.signum() <= 0) throw OperationFailure("invalid_rounding_increment", "The rounding increment must be positive.")
    val mode =
        when (values[2].formatText()) {
            "NearestTiesToEven" -> RoundingMode.HALF_EVEN
            "TowardZero" -> RoundingMode.DOWN
            "Floor" -> RoundingMode.FLOOR
            "Ceiling" -> RoundingMode.CEILING
            else -> throw OperationFailure("invalid_rounding_mode", "The rounding mode is unavailable.")
        }
    val result = value.displayDecimal().divide(step, 0, mode).multiply(step)
    return when (value) {
        is DataValue.Integer -> {
            DataValue.Integer(result.toBigIntegerExact())
        }

        is DataValue.Decimal -> {
            DataValue.Decimal(result.stripTrailingZeros().toPlainString())
        }

        is DataValue.Float -> {
            val number = result.toDouble()
            if (!number.isFinite()) throw OperationFailure("non_finite_number", "The numeric result must be finite.")
            DataValue.Float(number)
        }

        else -> {
            throw OperationFailure("expected_number", "The expression value is not numeric.")
        }
    }
}

internal fun formatPortableNumber(values: List<DataValue>): DataValue {
    val digits = values[1].formatDigits(20)
    val source = values[0].displayDecimal()
    if (source.precision().toLong() + kotlin.math.abs(source.scale().toLong()) > 4096) {
        throw OperationFailure("format_size_limit", "The formatted value exceeds its size limit.")
    }
    val locale = values[2].formatText()
    val result =
        if (locale == "und") {
            source.setScale(digits, RoundingMode.HALF_EVEN).toPlainString()
        } else {
            val formatter = NumberFormat.getNumberInstance(portableLocale(locale)) as DecimalFormat
            formatter.minimumFractionDigits = digits
            formatter.maximumFractionDigits = digits
            formatter.roundingMode = RoundingMode.HALF_EVEN
            formatter.format(source)
        }
    return DataValue.StringValue(result)
}

internal fun formatPortableDuration(values: List<DataValue>): DataValue {
    val duration =
        values[0].unwrapNamed() as? DataValue.Duration
            ?: throw OperationFailure("expected_duration", "The expression value is not a duration.")
    if (!duration.value.isPortableDuration()) {
        throw OperationFailure(
            "duration_range",
            "Duration millisecond count exceeds the finite portable range.",
        )
    }
    val units = values[1].formatText()
    if (units !in setOf("MinutesAndSeconds", "HoursMinutesAndSeconds")) {
        throw OperationFailure("invalid_duration_units", "The duration display units are unavailable.")
    }
    val digits = values[2].formatDigits(3)
    val milliseconds = java.math.BigInteger.valueOf(duration.value.inWholeMilliseconds)
    val magnitude = milliseconds.abs()
    val seconds = magnitude / java.math.BigInteger.valueOf(1000)
    val minutes = seconds / java.math.BigInteger.valueOf(60)
    val secondsPart = seconds.remainder(java.math.BigInteger.valueOf(60)).toString().padStart(2, '0')
    val whole =
        if (units == "MinutesAndSeconds") {
            "$minutes:$secondsPart"
        } else {
            val hours = minutes / java.math.BigInteger.valueOf(60)
            val minutePart = minutes.remainder(java.math.BigInteger.valueOf(60)).toString().padStart(2, '0')
            "$hours:$minutePart:$secondsPart"
        }
    val fraction =
        if (digits ==
            0
        ) {
            ""
        } else {
            "." +
                magnitude
                    .remainder(java.math.BigInteger.valueOf(1000))
                    .toString()
                    .padStart(3, '0')
                    .take(digits)
        }
    return DataValue.StringValue((if (milliseconds.signum() < 0) "-" else "") + whole + fraction)
}

internal fun formatPortableTimestamp(values: List<DataValue>): DataValue {
    val timestamp =
        values[0].unwrapNamed() as? DataValue.Timestamp
            ?: throw OperationFailure("expected_timestamp", "The expression value is not a timestamp.")
    val pattern = values[1].formatText()
    if (!Regex("(?:yyyy|MM|dd|HH|mm|ss|SSS|[^A-Za-z])+").matches(pattern) || pattern.length > 128) {
        throw OperationFailure("invalid_timestamp_pattern", "The timestamp pattern is not portable.")
    }
    val zone =
        when (values[2].formatText()) {
            "UTC", "utc" -> ZoneId.of("UTC")
            "local" -> ZoneId.systemDefault()
            else -> throw OperationFailure("invalid_timestamp_zone", "The timestamp zone is unavailable.")
        }
    val locale = values[3].formatText()
    val formatter = DateTimeFormatter.ofPattern(pattern, if (locale == "und") Locale.ROOT else portableLocale(locale)).withZone(zone)
    return DataValue.StringValue(formatter.format(java.time.Instant.parse(timestamp.value.toString())))
}

internal fun DataValue.displayDecimal(): BigDecimal {
    val source =
        when (val value = unwrapNamed()) {
            is DataValue.Integer -> {
                value.value.toString()
            }

            is DataValue.Decimal -> {
                value.value
            }

            is DataValue.Float -> {
                if (value.value.isFinite()) {
                    value.value.toString()
                } else {
                    throw OperationFailure(
                        "non_finite_number",
                        "The numeric value must be finite.",
                    )
                }
            }

            else -> {
                throw OperationFailure("expected_number", "The expression value is not numeric.")
            }
        }
    if (source.length > 4096) throw OperationFailure("format_size_limit", "The formatted value exceeds its size limit.")
    val result = source.toBigDecimalOrNull() ?: throw OperationFailure("expected_number", "The expression value is not numeric.")
    if (result.precision().toLong() + kotlin.math.abs(result.scale().toLong()) >
        4096
    ) {
        throw OperationFailure("format_size_limit", "The formatted value exceeds its size limit.")
    }
    return result
}

private fun DataValue.formatText(): String =
    (unwrapNamed() as? DataValue.StringValue)?.value
        ?: throw OperationFailure("expected_text", "The expression value is not text.")

private fun DataValue.formatDigits(maximum: Int): Int {
    val value =
        (unwrapNamed() as? DataValue.Integer)?.value
            ?: throw OperationFailure("expected_integer", "Display precision must be an integer.")
    if (value.signum() < 0 ||
        value > maximum.toBigInteger()
    ) {
        throw OperationFailure("invalid_format_precision", "Display precision is outside its supported range.")
    }
    return value.toInt()
}

private fun portableLocale(value: String): Locale {
    val locale = Locale.forLanguageTag(value.replace('_', '-'))
    if (locale.language.isEmpty() || locale.language !in Locale.getAvailableLocales().map(Locale::getLanguage)) {
        throw OperationFailure("invalid_format_locale", "The display locale is unavailable.")
    }
    return locale
}
