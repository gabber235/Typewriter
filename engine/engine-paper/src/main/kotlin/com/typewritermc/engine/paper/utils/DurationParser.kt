package com.typewritermc.engine.paper.utils

import java.util.*
import java.util.regex.Pattern
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

object DurationParser {
	private val durationRE =
		Pattern.compile("(-?(?:\\d+\\.?\\d*|\\d*\\.?\\d+)(?:e[-+]?\\d+)?)\\s*(\\p{L}*)", Pattern.CASE_INSENSITIVE)

	private const val millisecond = 1L
	private const val second = 1000 * millisecond
	private const val minute = 60 * second
	private const val hour = 60 * minute
	private const val day = 24 * hour
	private const val week = 7 * day
	private const val month = 30 * day
	private const val year = 365 * day

	private fun unitRatio(str: String): Long? {
		return when (str) {
			"millisecond", "ms"  -> millisecond
			"second", "sec", "s" -> second
			"minute", "min", "m" -> minute
			"hour", "hr", "h"    -> hour
			"day", "d"           -> day
			"week", "wk", "w"    -> week
			"month", "b"         -> month
			"year", "yr", "y"    -> year
			else                 -> null
		}
	}

        /**
         * Parses a duration string into a [Duration] object.
         *
         * Examples:
         * ```
         * parse("1 hr 20 mins") // => 1 * h + 20 * m
         * parse("1.5 hours") // => 1.5 * h
         * parse("1h20m0s") // => 1 * h + 20 * m
         * parse("2hr -40mins") // => 1 * h + 20 * m
         * parse("27,681 ms") // => 27681 * ms
         * ```
         */
	fun parse(string: String): Duration {
		var result: Long = 0
		val parsable = string.replace(Regex("(\\d)[,_](\\d)"), "\$1\$2")
		val matcher = durationRE.matcher(parsable)
		while (matcher.find()) {
			val n = matcher.group(1)
			val units = unitRatio(matcher.group(2)) ?: unitRatio(
				matcher.group(2).lowercase(Locale.getDefault()).replace(Regex("s\$"), "")
			)
			if (units != null) {
				result += n.toLong() * units
			}
		}
		return result.milliseconds
	}

}
