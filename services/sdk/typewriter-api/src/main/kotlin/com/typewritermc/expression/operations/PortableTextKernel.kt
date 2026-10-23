@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.expression.operations

import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/**
 * Realm's kernel of the text operations. Indexes and lengths count Unicode code points; case, folding, normalization
 * and white space come from [PortableUnicode], never from the JVM. Parsers accept exactly the documented ASCII syntax.
 */
internal object PortableTextKernel : TextKernel {
    override fun codePoints(value: String): List<Int> = value.codePointArray().toList()

    override fun foldCase(value: String): String = PortableUnicode.foldCase(value)

    override fun fromCodePoints(points: List<Int>): String {
        points.forEach { point ->
            if (point !in 0..0x10FFFF || point in 0xD800..0xDFFF) {
                throw OperationFailure(KernelFailure.InvalidCodePoint, "The value $point is not a Unicode scalar value.")
            }
        }
        return points.toIntArray().codePointText()
    }

    /** A negative [from] searches from the start; an empty needle occurs at every index up to the length. */
    override fun indexOf(
        value: String,
        needle: String,
        from: Int,
    ): Int {
        val text = value.codePointArray()
        val pattern = needle.codePointArray()
        val start = maxOf(from, 0)
        if (pattern.isEmpty()) return if (start <= text.size) start else -1
        for (index in start..text.size - pattern.size) {
            if (text.occursAt(pattern, index)) return index
        }
        return -1
    }

    override fun join(
        parts: List<String>,
        separator: String,
    ): String = parts.joinToString(separator)

    /** A [from] beyond the length searches from the end; an empty needle occurs at every nonnegative index. */
    override fun lastIndexOf(
        value: String,
        needle: String,
        from: Int,
    ): Int {
        val text = value.codePointArray()
        val pattern = needle.codePointArray()
        val start = minOf(from, text.size)
        if (pattern.isEmpty()) return if (start >= 0) start else -1
        for (index in minOf(start, text.size - pattern.size) downTo 0) {
            if (text.occursAt(pattern, index)) return index
        }
        return -1
    }

    override fun length(value: String): Int = value.codePointCount(0, value.length)

    override fun lower(value: String): String = PortableUnicode.lower(value)

    override fun normalize(
        value: String,
        form: UnicodeForm,
    ): String =
        PortableUnicode.normalize(
            value,
            compatibility = form == UnicodeForm.Nfkc || form == UnicodeForm.Nfkd,
            compose = form == UnicodeForm.Nfc || form == UnicodeForm.Nfkc,
        )

    /** Exact; an exponent beyond the 32 bit range no host represents is not a number either. */
    override fun parseDecimal(value: String): BigDecimal =
        try {
            BigDecimal(requireNumberSyntax(value))
        } catch (_: NumberFormatException) {
            throw invalidNumber(value)
        }

    /** Rounds to the nearest double; text whose value overflows the double range is not a finite number. */
    override fun parseFloat(value: String): Double {
        val parsed = requireNumberSyntax(value).toDouble()
        if (!parsed.isFinite()) throw invalidNumber(value)
        return parsed
    }

    override fun parseInteger(
        value: String,
        radix: Int,
    ): BigInteger {
        if (radix !in 2..36) throw OperationFailure(KernelFailure.InvalidRadix, "The radix $radix is outside 2 to 36.")
        val digits = value.removePrefix("+").let { if (it.startsWith("-")) it.substring(1) else it }
        val valid = digits.isNotEmpty() && digits.length + 1 >= value.length && digits.all { asciiDigit(it) in 0 until radix }
        if (!valid) throw invalidNumber(value)
        return BigInteger(value.removePrefix("+"), radix)
    }

    /** Days are 24 hours; seconds take at most three fraction digits. */
    override fun parseDuration(value: String): Duration {
        val match = DURATION_SYNTAX.matchEntire(value)
        val groups = match?.groupValues
        val hasTime = groups != null && groups[3].isNotEmpty()
        val hasTimeComponent = groups != null && (groups[4].isNotEmpty() || groups[5].isNotEmpty() || groups[6].isNotEmpty())
        val hasComponent = groups != null && (groups[2].isNotEmpty() || hasTimeComponent)
        if (groups == null || !hasComponent || (hasTime && !hasTimeComponent)) {
            throw OperationFailure(
                KernelFailure.InvalidDurationText,
                "The text is not an ISO 8601 duration of days, hours, minutes and seconds.",
            )
        }

        fun component(
            digits: String,
            unit: Long,
        ): BigInteger = if (digits.isEmpty()) BigInteger.ZERO else BigInteger(digits) * BigInteger.valueOf(unit)
        val fraction = if (groups[7].isEmpty()) "" else groups[7].padEnd(3, '0')
        val milliseconds =
            component(groups[2], 86_400_000) + component(groups[4], 3_600_000) + component(groups[5], 60_000) +
                component(groups[6], 1_000) + component(fraction, 1)
        return portableDuration(if (groups[1].isEmpty()) milliseconds else milliseconds.negate())
    }

    /** Fraction digits beyond milliseconds are truncated; the offset is subtracted to reach UTC. */
    override fun parseTimestamp(value: String): Instant {
        val groups =
            TIMESTAMP_SYNTAX.matchEntire(value)?.groupValues
                ?: throw invalidTimestamp()
        val year = groups[1].toLong()
        val month = groups[2].toInt()
        val day = groups[3].toInt()
        val hour = groups[4].toInt()
        val minute = groups[5].toInt()
        val second = groups[6].toInt()
        val millisecond = groups[7].take(3).padEnd(3, '0').toInt()
        val zone = groups[8]
        val offsetMinutes =
            if (zone == "Z") {
                0
            } else {
                val offsetHour = zone.substring(1, 3).toInt()
                val offsetMinute = zone.substring(4, 6).toInt()
                if (offsetHour > 23 || offsetMinute > 59) throw invalidTimestamp()
                (offsetHour * 60 + offsetMinute) * (if (zone[0] == '-') -1 else 1)
            }
        val valid = month in 1..12 && day in 1..daysInMonth(year, month) && hour <= 23 && minute <= 59 && second <= 59
        if (!valid) throw invalidTimestamp()
        return portableInstant(
            localMilliseconds(year, month, day, hour, minute, second, millisecond) - BigInteger.valueOf(offsetMinutes * 60_000L),
        )
    }

    /** Empty parts are kept, so empty text splits into one empty part. */
    override fun split(
        value: String,
        separator: String,
    ): List<String> {
        if (separator.isEmpty()) throw OperationFailure(KernelFailure.EmptySeparator, "The separator is empty.")
        return value.split(separator)
    }

    override fun substring(
        value: String,
        start: Int,
        end: Int,
    ): String {
        val text = value.codePointArray()
        if (start < 0 || end < start || end > text.size) {
            throw OperationFailure(
                KernelFailure.SubstringRange,
                "The range $start to $end is outside the text of ${text.size} code points.",
            )
        }
        return text.codePointText(start, end)
    }

    override fun title(value: String): String = PortableUnicode.title(value)

    override fun trimEnd(value: String): String = PortableUnicode.trimEnd(value)

    override fun trimStart(value: String): String = PortableUnicode.trimStart(value)

    override fun upper(value: String): String = PortableUnicode.upper(value)
}

/** The decimal and float syntax: an optional sign, digits with an optional fraction, and an optional exponent. */
private val NUMBER_SYNTAX = Regex("[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][+-]?[0-9]+)?")

private val DURATION_SYNTAX = Regex("(-?)P(?:([0-9]+)D)?(T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)(?:\\.([0-9]{1,3}))?S)?)?")

private val TIMESTAMP_SYNTAX =
    Regex("([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(?:\\.([0-9]+))?(Z|[+-][0-9]{2}:[0-9]{2})")

/** The text when it has the number syntax. */
private fun requireNumberSyntax(value: String): String {
    if (!NUMBER_SYNTAX.matches(value)) throw invalidNumber(value)
    return value
}

private fun invalidNumber(value: String) =
    OperationFailure(KernelFailure.InvalidNumberText, "The text \"$value\" is not a number in the expected syntax.")

private fun invalidTimestamp() = OperationFailure(KernelFailure.InvalidTimestampText, "The text is not an RFC 3339 timestamp.")

/** The value of an ASCII digit or letter in radix 36, or -1. */
private fun asciiDigit(character: Char): Int =
    when (character) {
        in '0'..'9' -> character - '0'
        in 'a'..'z' -> character - 'a' + 10
        in 'A'..'Z' -> character - 'A' + 10
        else -> -1
    }

private fun IntArray.occursAt(
    pattern: IntArray,
    index: Int,
): Boolean = pattern.indices.all { offset -> this[index + offset] == pattern[offset] }
