package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.div
import com.typewritermc.expression.literal
import com.typewritermc.expression.millisecondsToDuration
import com.typewritermc.expression.minus
import com.typewritermc.expression.plus
import com.typewritermc.expression.rem
import com.typewritermc.expression.times
import com.typewritermc.expression.toMilliseconds
import com.typewritermc.expression.toText
import kotlin.time.Duration

/*
 * Duration shortcuts work on whole milliseconds through duration.to_milliseconds and duration.from_milliseconds, which
 * fails with duration_range outside the portable range. Integer division truncates toward zero, so whole units and
 * parts of a negative duration are negative, as in kotlin.time.
 */

/** The units a formatted duration shows. */
enum class DurationDisplayUnits {
    /** Minutes and seconds, such as 3:07; minutes grow past 59. */
    MinutesAndSeconds,

    /** Hours, minutes and seconds, such as 1:03:07; hours grow past 23. */
    HoursMinutesAndSeconds,
}

/** A duration of this many milliseconds. */
@get:JvmName("intMilliseconds")
val <M : MissingPolicy> Expr<Int, M>.milliseconds: Expr<Duration, M> get() = widened().millisecondsToDuration()

/** A duration of this many milliseconds. */
@get:JvmName("longMilliseconds")
val <M : MissingPolicy> Expr<Long, M>.milliseconds: Expr<Duration, M> get() = millisecondsToDuration()

/** A duration of this many seconds. */
@get:JvmName("intSeconds")
val <M : MissingPolicy> Expr<Int, M>.seconds: Expr<Duration, M> get() = widened().seconds

/** A duration of this many seconds. */
@get:JvmName("longSeconds")
val <M : MissingPolicy> Expr<Long, M>.seconds: Expr<Duration, M> get() = (this * MILLISECONDS_PER_SECOND).millisecondsToDuration()

/** A duration of this many minutes. */
@get:JvmName("intMinutes")
val <M : MissingPolicy> Expr<Int, M>.minutes: Expr<Duration, M> get() = widened().minutes

/** A duration of this many minutes. */
@get:JvmName("longMinutes")
val <M : MissingPolicy> Expr<Long, M>.minutes: Expr<Duration, M> get() = (this * MILLISECONDS_PER_MINUTE).millisecondsToDuration()

/** A duration of this many hours. */
@get:JvmName("intHours")
val <M : MissingPolicy> Expr<Int, M>.hours: Expr<Duration, M> get() = widened().hours

/** A duration of this many hours. */
@get:JvmName("longHours")
val <M : MissingPolicy> Expr<Long, M>.hours: Expr<Duration, M> get() = (this * MILLISECONDS_PER_HOUR).millisecondsToDuration()

/** A duration of this many days of 24 hours. */
@get:JvmName("intDays")
val <M : MissingPolicy> Expr<Int, M>.days: Expr<Duration, M> get() = widened().days

/** A duration of this many days of 24 hours. */
@get:JvmName("longDays")
val <M : MissingPolicy> Expr<Long, M>.days: Expr<Duration, M> get() = (this * MILLISECONDS_PER_DAY).millisecondsToDuration()

/** The sum of this duration and [other]. */
@JvmName("durationPlus")
operator fun <M : MissingPolicy> Expr<Duration, M>.plus(other: Expr<Duration, M>): Expr<Duration, M> =
    (toMilliseconds() + other.toMilliseconds()).millisecondsToDuration()

/** The sum of this duration and [other]. */
@JvmName("durationPlusRaw")
operator fun <M : MissingPolicy> Expr<Duration, M>.plus(other: Duration): Expr<Duration, M> = this + literal(other).lift()

/** This duration less [other]. */
@JvmName("durationMinus")
operator fun <M : MissingPolicy> Expr<Duration, M>.minus(other: Expr<Duration, M>): Expr<Duration, M> =
    (toMilliseconds() - other.toMilliseconds()).millisecondsToDuration()

/** This duration less [other]. */
@JvmName("durationMinusRaw")
operator fun <M : MissingPolicy> Expr<Duration, M>.minus(other: Duration): Expr<Duration, M> = this - literal(other).lift()

/** This duration [factor] times. */
@JvmName("durationTimes")
operator fun <M : MissingPolicy> Expr<Duration, M>.times(factor: Expr<Long, M>): Expr<Duration, M> =
    (toMilliseconds() * factor).millisecondsToDuration()

/** This duration [factor] times. */
@JvmName("durationTimesRaw")
operator fun <M : MissingPolicy> Expr<Duration, M>.times(factor: Long): Expr<Duration, M> =
    (toMilliseconds() * factor).millisecondsToDuration()

/** This duration divided by [divisor], truncated to whole milliseconds toward zero. */
@JvmName("durationDiv")
operator fun <M : MissingPolicy> Expr<Duration, M>.div(divisor: Expr<Long, M>): Expr<Duration, M> =
    (toMilliseconds() / divisor).millisecondsToDuration()

/** This duration divided by [divisor], truncated to whole milliseconds toward zero. */
@JvmName("durationDivRaw")
operator fun <M : MissingPolicy> Expr<Duration, M>.div(divisor: Long): Expr<Duration, M> =
    (toMilliseconds() / divisor).millisecondsToDuration()

/** The negation of this duration. */
@JvmName("durationNegate")
operator fun <M : MissingPolicy> Expr<Duration, M>.unaryMinus(): Expr<Duration, M> = (-toMilliseconds()).millisecondsToDuration()

/** The length of this duration without its sign, like Kotlin's absoluteValue. */
@get:JvmName("durationAbsoluteValue")
val <M : MissingPolicy> Expr<Duration, M>.absoluteValue: Expr<Duration, M> get() = toMilliseconds().abs().millisecondsToDuration()

/** Whether this duration is shorter than zero. */
@JvmName("durationIsNegative")
fun <M : MissingPolicy> Expr<Duration, M>.isNegative(): Expr<Boolean, M> = toMilliseconds() lt 0L

/** Whether this duration is longer than zero. */
@JvmName("durationIsPositive")
fun <M : MissingPolicy> Expr<Duration, M>.isPositive(): Expr<Boolean, M> = toMilliseconds() gt 0L

/** The whole milliseconds of this duration, truncated toward zero. */
@get:JvmName("durationInWholeMilliseconds")
val <M : MissingPolicy> Expr<Duration, M>.inWholeMilliseconds: Expr<Long, M> get() = toMilliseconds()

/** The whole seconds of this duration, truncated toward zero. */
@get:JvmName("durationInWholeSeconds")
val <M : MissingPolicy> Expr<Duration, M>.inWholeSeconds: Expr<Long, M> get() = toMilliseconds() / MILLISECONDS_PER_SECOND

/** The whole minutes of this duration, truncated toward zero. */
@get:JvmName("durationInWholeMinutes")
val <M : MissingPolicy> Expr<Duration, M>.inWholeMinutes: Expr<Long, M> get() = toMilliseconds() / MILLISECONDS_PER_MINUTE

/** The whole hours of this duration, truncated toward zero. */
@get:JvmName("durationInWholeHours")
val <M : MissingPolicy> Expr<Duration, M>.inWholeHours: Expr<Long, M> get() = toMilliseconds() / MILLISECONDS_PER_HOUR

/** The whole days of 24 hours of this duration, truncated toward zero. */
@get:JvmName("durationInWholeDays")
val <M : MissingPolicy> Expr<Duration, M>.inWholeDays: Expr<Long, M> get() = toMilliseconds() / MILLISECONDS_PER_DAY

/** The hours past the whole days, from -23 to 23 with the sign of the duration. */
@get:JvmName("durationHoursPart")
val <M : MissingPolicy> Expr<Duration, M>.hoursPart: Expr<Long, M> get() = inWholeHours % 24L

/** The minutes past the whole hours, from -59 to 59 with the sign of the duration. */
@get:JvmName("durationMinutesPart")
val <M : MissingPolicy> Expr<Duration, M>.minutesPart: Expr<Long, M> get() = inWholeMinutes % 60L

/** The seconds past the whole minutes, from -59 to 59 with the sign of the duration. */
@get:JvmName("durationSecondsPart")
val <M : MissingPolicy> Expr<Duration, M>.secondsPart: Expr<Long, M> get() = inWholeSeconds % 60L

/** The milliseconds past the whole seconds, from -999 to 999 with the sign of the duration. */
@get:JvmName("durationMillisecondsPart")
val <M : MissingPolicy> Expr<Duration, M>.millisecondsPart: Expr<Long, M> get() = toMilliseconds() % MILLISECONDS_PER_SECOND

/**
 * This duration as clock text, such as 3:07.250 or -1:03:07: a minus sign when negative, then [units] with two digit
 * minutes and seconds after the leading unit, then [fractionalSecondDigits] (0 to 3) digits of the second, truncated.
 */
fun <M : MissingPolicy> Expr<Duration, M>.formatDuration(
    units: DurationDisplayUnits = DurationDisplayUnits.MinutesAndSeconds,
    fractionalSecondDigits: Int = 3,
): Expr<String, M> {
    require(fractionalSecondDigits in 0..3) { "A duration shows 0 to 3 fractional second digits." }
    return shared(toMilliseconds()) { milliseconds ->
        shared(milliseconds.abs()) { magnitude ->
            shared(magnitude / MILLISECONDS_PER_SECOND) { seconds ->
                shared(seconds / 60L) { minutes ->
                    val whole =
                        when (units) {
                            DurationDisplayUnits.MinutesAndSeconds -> {
                                concat(minutes.toText(), literal(":").lift(), zeroPadded(seconds % 60L, 2))
                            }

                            DurationDisplayUnits.HoursMinutesAndSeconds -> {
                                concat(
                                    (minutes / 60L).toText(),
                                    literal(":").lift(),
                                    zeroPadded(minutes % 60L, 2),
                                    literal(":").lift(),
                                    zeroPadded(seconds % 60L, 2),
                                )
                            }
                        }
                    val millisecondsOfSecond = magnitude % MILLISECONDS_PER_SECOND
                    val fraction =
                        when (fractionalSecondDigits) {
                            0 -> literal("").lift()
                            1 -> literal(".").lift<String, M>() + (millisecondsOfSecond / 100L).toText()
                            2 -> literal(".").lift<String, M>() + zeroPadded(millisecondsOfSecond / 10L, 2)
                            else -> literal(".").lift<String, M>() + zeroPadded(millisecondsOfSecond, 3)
                        }
                    concat(choose(milliseconds lt 0L, literal("-").lift(), literal("").lift()), whole, fraction)
                }
            }
        }
    }
}

/** The decimal text of the nonnegative [value] with leading zeros up to [width] digits. */
internal fun <M : MissingPolicy> zeroPadded(
    value: Expr<Long, M>,
    width: Int,
): Expr<String, M> =
    shared(value) { number ->
        val zeros =
            (width - 1 downTo 1).fold(literal("").lift<String, M>()) { longer, digits ->
                choose(number lt TEN_POWERS[digits], literal("0".repeat(width - digits)).lift(), longer)
            }
        zeros + number.toText()
    }

/** Reinterprets an int32 expression as an integer one; integer parameters accept every width. */
@Suppress("UNCHECKED_CAST")
internal fun <M : MissingPolicy> Expr<Int, M>.widened(): Expr<Long, M> = this as Expr<Long, M>

private val TEN_POWERS = List(19) { exponent -> (1..exponent).fold(1L) { power, _ -> power * 10 } }

private const val MILLISECONDS_PER_SECOND = 1_000L

private const val MILLISECONDS_PER_MINUTE = 60_000L

private const val MILLISECONDS_PER_HOUR = 3_600_000L

private const val MILLISECONDS_PER_DAY = 86_400_000L
