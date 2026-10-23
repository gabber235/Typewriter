package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.and
import com.typewritermc.expression.div
import com.typewritermc.expression.epochMillisecondsToTimestamp
import com.typewritermc.expression.eq
import com.typewritermc.expression.fields
import com.typewritermc.expression.literal
import com.typewritermc.expression.minus
import com.typewritermc.expression.monthName
import com.typewritermc.expression.operations.DateTimeFields
import com.typewritermc.expression.operations.NameStyle
import com.typewritermc.expression.or
import com.typewritermc.expression.plus
import com.typewritermc.expression.rem
import com.typewritermc.expression.times
import com.typewritermc.expression.toEpochMilliseconds
import com.typewritermc.expression.toMilliseconds
import com.typewritermc.expression.toTimestamp
import com.typewritermc.expression.weekdayName
import com.typewritermc.expression.withField
import com.typewritermc.expression.zoneOffset
import kotlin.time.Duration
import kotlin.time.Instant

/*
 * Timestamp shortcuts. Calendar shortcuts read timestamp.fields at a fixed offset from UTC (zero by default), in the
 * proleptic Gregorian calendar; a day is always 24 hours at a fixed offset. A result outside the portable range fails
 * with timestamp_range. Shortcuts that name an IANA zone use timestamp.zone_offset and run only in the panel.
 */

/** This timestamp moved by [duration]. */
@JvmName("timestampPlus")
operator fun <M : MissingPolicy> Expr<Instant, M>.plus(duration: Expr<Duration, M>): Expr<Instant, M> =
    (toEpochMilliseconds() + duration.toMilliseconds()).epochMillisecondsToTimestamp()

/** This timestamp moved by [duration]. */
@JvmName("timestampPlusRaw")
operator fun <M : MissingPolicy> Expr<Instant, M>.plus(duration: Duration): Expr<Instant, M> = this + literal(duration).lift()

/** This timestamp moved back by [duration]. */
@JvmName("timestampMinusDuration")
operator fun <M : MissingPolicy> Expr<Instant, M>.minus(duration: Expr<Duration, M>): Expr<Instant, M> =
    (toEpochMilliseconds() - duration.toMilliseconds()).epochMillisecondsToTimestamp()

/** This timestamp moved back by [duration]. */
@JvmName("timestampMinusDurationRaw")
operator fun <M : MissingPolicy> Expr<Instant, M>.minus(duration: Duration): Expr<Instant, M> = this - literal(duration).lift()

/** The duration from [other] to this timestamp; negative when [other] is later. */
@JvmName("timestampMinusTimestamp")
operator fun <M : MissingPolicy> Expr<Instant, M>.minus(other: Expr<Instant, M>): Expr<Duration, M> =
    (toEpochMilliseconds() - other.toEpochMilliseconds()).milliseconds

/** The duration from this timestamp to [other]; negative when [other] is earlier. */
fun <M : MissingPolicy> Expr<Instant, M>.durationUntil(other: Expr<Instant, M>): Expr<Duration, M> = other - this

/** Whether this timestamp is before [other]. */
fun <M : MissingPolicy> Expr<Instant, M>.isBefore(other: Expr<Instant, M>): Expr<Boolean, M> = this lt other

/** Whether this timestamp is before [other]. */
@JvmName("isBeforeRaw")
fun <M : MissingPolicy> Expr<Instant, M>.isBefore(other: Instant): Expr<Boolean, M> = this lt other

/** Whether this timestamp is after [other]. */
fun <M : MissingPolicy> Expr<Instant, M>.isAfter(other: Expr<Instant, M>): Expr<Boolean, M> = this gt other

/** Whether this timestamp is after [other]. */
@JvmName("isAfterRaw")
fun <M : MissingPolicy> Expr<Instant, M>.isAfter(other: Instant): Expr<Boolean, M> = this gt other

/** The calendar year at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.year(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).year

/** The month, 1 to 12, at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.month(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).month

/** The day of the month, from 1, at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.day(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).day

/** The hour, 0 to 23, at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.hour(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).hour

/** The minute, 0 to 59, at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.minute(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).minute

/** The second, 0 to 59, at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.second(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).second

/** The day of the week, 1 (Monday) to 7 (Sunday), at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.dayOfWeek(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).weekday

/** The day of the year, from 1, at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.dayOfYear(offset: Duration = Duration.ZERO): Expr<Int, M> = fields(offset).dayOfYear

/** This timestamp [days] days of 24 hours later; earlier when negative. */
fun <M : MissingPolicy> Expr<Instant, M>.plusDays(days: Expr<Int, M>): Expr<Instant, M> = this + days.days

/** This timestamp [days] days of 24 hours later; earlier when negative. */
@JvmName("plusDaysRaw")
fun <M : MissingPolicy> Expr<Instant, M>.plusDays(days: Int): Expr<Instant, M> = plusDays(literal(days).lift())

/**
 * The same time of day [months] months later at [offset] from UTC; earlier when negative. The day of the month is
 * clamped to the last day of a shorter month, so January 31 plus one month is February 28 or 29.
 */
fun <M : MissingPolicy> Expr<Instant, M>.plusMonths(
    months: Expr<Int, M>,
    offset: Duration = Duration.ZERO,
): Expr<Instant, M> =
    shared(fields(offset)) { date ->
        shared(date.year * 12 + date.month - 1 + months) { target ->
            shared(target / 12) { year ->
                shared(target % 12 + 1) { month ->
                    date
                        .withField("year", year)
                        .withField("month", month)
                        .withField("day", min(date.day, monthLength(year, month)))
                        .toTimestamp(offset)
                }
            }
        }
    }

/** The same time of day [months] months later at [offset] from UTC; see [plusMonths]. */
@JvmName("plusMonthsRaw")
fun <M : MissingPolicy> Expr<Instant, M>.plusMonths(
    months: Int,
    offset: Duration = Duration.ZERO,
): Expr<Instant, M> = plusMonths(literal(months).lift(), offset)

/** The same time of day [years] years later at [offset] from UTC; February 29 becomes February 28 in common years. */
fun <M : MissingPolicy> Expr<Instant, M>.plusYears(
    years: Expr<Int, M>,
    offset: Duration = Duration.ZERO,
): Expr<Instant, M> = plusMonths(years * 12, offset)

/** The same time of day [years] years later at [offset] from UTC; see [plusYears]. */
@JvmName("plusYearsRaw")
fun <M : MissingPolicy> Expr<Instant, M>.plusYears(
    years: Int,
    offset: Duration = Duration.ZERO,
): Expr<Instant, M> = plusYears(literal(years).lift(), offset)

/** Midnight at the start of this timestamp's day at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.startOfDay(offset: Duration = Duration.ZERO): Expr<Instant, M> =
    shared(toEpochMilliseconds()) { milliseconds ->
        (milliseconds - (milliseconds + offset.inWholeMilliseconds).mod(MILLISECONDS_PER_DAY)).epochMillisecondsToTimestamp()
    }

/** The number of days of this timestamp's month at [offset] from UTC. */
fun <M : MissingPolicy> Expr<Instant, M>.daysInMonth(offset: Duration = Duration.ZERO): Expr<Int, M> =
    shared(fields(offset)) { date -> monthLength(date.year, date.month) }

/** Whether this timestamp's year at [offset] from UTC is a Gregorian leap year. */
fun <M : MissingPolicy> Expr<Instant, M>.isLeapYear(offset: Duration = Duration.ZERO): Expr<Boolean, M> = isLeap(year(offset))

/** The calendar fields of this timestamp in the IANA [zone]. Runs only in the panel. */
fun <M : MissingPolicy> Expr<Instant, M>.inZone(zone: String): Expr<DateTimeFields, M> =
    shared(this) { timestamp -> timestamp.fields(timestamp.zoneOffset(zone)) }

/**
 * This timestamp as text in [pattern], at [zone] ("UTC" or an IANA zone) and with the names of [locale].
 *
 * Numeric tokens: yyyy (year, four digits), MM (month), dd (day), HH (hour, 0 to 23), mm (minute), ss (second), each
 * two digits, and SSS (millisecond, three digits). Name tokens: MMMM and MMM (wide and abbreviated month name), EEEE
 * and EEE (wide and abbreviated weekday name). Any other character that is not a letter or a quote is copied. The
 * pattern expands when the expression is built, so a UTC pattern without name tokens runs in rules; another zone or a
 * name token runs only in the panel.
 */
fun <M : MissingPolicy> Expr<Instant, M>.formatTimestamp(
    pattern: String,
    zone: String = "UTC",
    locale: String = "und",
): Expr<String, M> {
    val pieces = TimestampPiece.parse(pattern)
    val calendar = if (zone.equals("UTC", ignoreCase = true)) fields(Duration.ZERO) else inZone(zone)
    return shared(calendar) { date -> concat(*pieces.map { it.render(date, locale) }.toTypedArray()) }
}

private sealed interface TimestampPiece {
    fun <M : MissingPolicy> render(
        date: Expr<DateTimeFields, M>,
        locale: String,
    ): Expr<String, M>

    data class Text(
        val text: String,
    ) : TimestampPiece {
        override fun <M : MissingPolicy> render(
            date: Expr<DateTimeFields, M>,
            locale: String,
        ): Expr<String, M> = literal(text).lift()
    }

    enum class Token(
        val pattern: String,
    ) : TimestampPiece {
        MONTH_WIDE("MMMM") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = date.month.monthName(locale, NameStyle.Wide)
        },
        MONTH_ABBREVIATED("MMM") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = date.month.monthName(locale, NameStyle.Abbreviated)
        },
        WEEKDAY_WIDE("EEEE") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = date.weekday.weekdayName(locale, NameStyle.Wide)
        },
        WEEKDAY_ABBREVIATED("EEE") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = date.weekday.weekdayName(locale, NameStyle.Abbreviated)
        },
        YEAR("yyyy") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.year.widened(), 4)
        },
        MONTH("MM") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.month.widened(), 2)
        },
        DAY("dd") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.day.widened(), 2)
        },
        HOUR("HH") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.hour.widened(), 2)
        },
        MINUTE("mm") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.minute.widened(), 2)
        },
        SECOND("ss") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.second.widened(), 2)
        },
        MILLISECOND("SSS") {
            override fun <M : MissingPolicy> render(
                date: Expr<DateTimeFields, M>,
                locale: String,
            ): Expr<String, M> = zeroPadded(date.millisecond.widened(), 3)
        },
    }

    companion object {
        /** Splits [pattern] into tokens, longest first, and copied text. */
        fun parse(pattern: String): List<TimestampPiece> =
            buildList {
                val text = StringBuilder()
                var index = 0
                while (index < pattern.length) {
                    val token = Token.entries.firstOrNull { pattern.startsWith(it.pattern, index) }
                    if (token != null) {
                        if (text.isNotEmpty()) add(Text(text.toString())).also { text.clear() }
                        add(token)
                        index += token.pattern.length
                    } else {
                        val character = pattern[index]
                        require(!character.isLetter() && character != '\'') {
                            "Timestamp pattern \"$pattern\" has the unsupported character '$character' at $index."
                        }
                        text.append(character)
                        index += 1
                    }
                }
                if (text.isNotEmpty()) add(Text(text.toString()))
            }
    }
}

private val <M : MissingPolicy> Expr<DateTimeFields, M>.year: Expr<Int, M> get() = member("year")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.month: Expr<Int, M> get() = member("month")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.day: Expr<Int, M> get() = member("day")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.hour: Expr<Int, M> get() = member("hour")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.minute: Expr<Int, M> get() = member("minute")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.second: Expr<Int, M> get() = member("second")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.millisecond: Expr<Int, M> get() = member("millisecond")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.weekday: Expr<Int, M> get() = member("weekday")

private val <M : MissingPolicy> Expr<DateTimeFields, M>.dayOfYear: Expr<Int, M> get() = member("dayOfYear")

private fun <M : MissingPolicy> isLeap(year: Expr<Int, M>): Expr<Boolean, M> =
    shared(year) { value ->
        ((value % 4 eq literal(0).lift()) and (value % 100 neq literal(0).lift())) or (value % 400 eq literal(0).lift())
    }

private fun <M : MissingPolicy> monthLength(
    year: Expr<Int, M>,
    month: Expr<Int, M>,
): Expr<Int, M> =
    shared(month) { value ->
        choose(
            value eq literal(2).lift(),
            choose(isLeap(year), literal(29).lift(), literal(28).lift()),
            choose(anyOf(*THIRTY_DAY_MONTHS.map { value eq literal(it).lift() }.toTypedArray()), literal(30).lift(), literal(31).lift()),
        )
    }

private val THIRTY_DAY_MONTHS = listOf(4, 6, 9, 11)

private const val MILLISECONDS_PER_DAY = 86_400_000L
