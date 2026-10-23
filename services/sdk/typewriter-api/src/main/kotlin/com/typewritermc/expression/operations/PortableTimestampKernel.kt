@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.expression.operations

import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/**
 * Realm's kernel of the timestamp operations: milliseconds since 1970-01-01T00:00:00Z on the proleptic Gregorian
 * calendar, within the portable range from 0001-01-01T00:00:00.000Z through 9999-12-31T23:59:59.999Z. Calendar
 * arithmetic is done here rather than in java.time, so arbitrary 32 bit years and offsets never escape as host errors.
 */
internal object PortableTimestampKernel : TimestampKernel {
    override fun fields(
        value: Instant,
        offset: Duration,
    ): DateTimeFields {
        val local =
            portableEpochMilliseconds(BigInteger.valueOf(value.toEpochMilliseconds()) + BigInteger.valueOf(offset.inWholeMilliseconds))
        val days = Math.floorDiv(local, MILLISECONDS_PER_DAY)
        val time = Math.floorMod(local, MILLISECONDS_PER_DAY)
        val date = civilDate(days)
        return DateTimeFields(
            year = date.year.toInt(),
            month = date.month,
            day = date.day,
            hour = (time / 3_600_000).toInt(),
            minute = (time / 60_000 % 60).toInt(),
            second = (time / 1_000 % 60).toInt(),
            millisecond = (time % 1_000).toInt(),
            weekday = (Math.floorMod(days + 3, 7L) + 1).toInt(),
            dayOfYear = (days - epochDay(date.year, 1, 1) + 1).toInt(),
        )
    }

    override fun fromEpochMilliseconds(milliseconds: BigInteger): Instant = portableInstant(milliseconds)

    override fun fromFields(
        fields: DateTimeFields,
        offset: Duration,
    ): Instant {
        val valid =
            fields.month in 1..12 &&
                fields.day in 1..daysInMonth(fields.year.toLong(), fields.month) &&
                fields.hour in 0..23 &&
                fields.minute in 0..59 &&
                fields.second in 0..59 &&
                fields.millisecond in 0..999
        if (!valid) throw OperationFailure(KernelFailure.InvalidCalendarDate, "The fields do not name a valid date and time.")
        return portableInstant(
            localMilliseconds(
                fields.year.toLong(),
                fields.month,
                fields.day,
                fields.hour,
                fields.minute,
                fields.second,
                fields.millisecond,
            ) -
                BigInteger.valueOf(offset.inWholeMilliseconds),
        )
    }

    override fun toEpochMilliseconds(value: Instant): BigInteger = BigInteger.valueOf(value.toEpochMilliseconds())
}

/** The earliest portable timestamp, 0001-01-01T00:00:00.000Z, in milliseconds since the epoch. */
private const val MIN_TIMESTAMP_MILLISECONDS = -62_135_596_800_000L

/** The latest portable timestamp, 9999-12-31T23:59:59.999Z, in milliseconds since the epoch. */
private const val MAX_TIMESTAMP_MILLISECONDS = 253_402_300_799_999L

private const val MILLISECONDS_PER_DAY = 86_400_000L

/** The milliseconds, or timestamp_range when they lie outside the portable range. */
private fun portableEpochMilliseconds(milliseconds: BigInteger): Long {
    if (milliseconds < BigInteger.valueOf(MIN_TIMESTAMP_MILLISECONDS) || milliseconds > BigInteger.valueOf(MAX_TIMESTAMP_MILLISECONDS)) {
        throw OperationFailure(KernelFailure.TimestampRange, "The timestamp is outside 0001-01-01 through 9999-12-31.")
    }
    return milliseconds.toLong()
}

/** The timestamp [milliseconds] after the epoch, or timestamp_range outside the portable range. */
internal fun portableInstant(milliseconds: BigInteger): Instant = Instant.fromEpochMilliseconds(portableEpochMilliseconds(milliseconds))

/** The milliseconds since the epoch of a local date and time read as UTC; fields must already be valid. */
internal fun localMilliseconds(
    year: Long,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    millisecond: Int,
): BigInteger =
    BigInteger.valueOf(epochDay(year, month, day)) * BigInteger.valueOf(MILLISECONDS_PER_DAY) +
        BigInteger.valueOf(((hour * 60L + minute) * 60L + second) * 1_000L + millisecond)

/** The number of days of [month] in [year] of the proleptic Gregorian calendar. */
internal fun daysInMonth(
    year: Long,
    month: Int,
): Int =
    when (month) {
        2 -> if (Math.floorMod(year, 4L) == 0L && (Math.floorMod(year, 100L) != 0L || Math.floorMod(year, 400L) == 0L)) 29 else 28
        4, 6, 9, 11 -> 30
        else -> 31
    }

/** Days since 1970-01-01 of a proleptic Gregorian date (Howard Hinnant's days_from_civil). */
private fun epochDay(
    year: Long,
    month: Int,
    day: Int,
): Long {
    val shifted = if (month <= 2) year - 1 else year
    val era = Math.floorDiv(shifted, 400L)
    val yearOfEra = shifted - era * 400
    val monthIndex = (month + 9) % 12
    val dayOfYear = (153 * monthIndex + 2) / 5 + day - 1
    val dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146_097 + dayOfEra - 719_468
}

private class CivilDate(
    val year: Long,
    val month: Int,
    val day: Int,
)

/** The proleptic Gregorian date [days] after 1970-01-01 (Howard Hinnant's civil_from_days). */
private fun civilDate(days: Long): CivilDate {
    val shifted = days + 719_468
    val era = Math.floorDiv(shifted, 146_097L)
    val dayOfEra = shifted - era * 146_097
    val yearOfEra = (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
    val dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
    val monthIndex = (5 * dayOfYear + 2) / 153
    val day = (dayOfYear - (153 * monthIndex + 2) / 5 + 1).toInt()
    val month = (if (monthIndex < 10) monthIndex + 3 else monthIndex - 9).toInt()
    return CivilDate(year = yearOfEra + era * 400 + (if (month <= 2) 1 else 0), month = month, day = day)
}
