package com.typewritermc.services.libs.communicator.nats

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * Converts a positive finite timeout to whole milliseconds, rounding upward.
 *
 * Submillisecond durations remain nonzero. Values beyond Long millisecond capacity are rejected rather than
 * overflowing.
 */
internal fun Duration.toPositiveMilliseconds(name: String): Long {
    require(isFinite() && isPositive()) { "$name must be positive and finite" }
    require(this <= Long.MAX_VALUE.milliseconds) { "$name is too large" }
    val whole = inWholeMilliseconds
    return if (this > whole.milliseconds) whole + 1 else whole
}
