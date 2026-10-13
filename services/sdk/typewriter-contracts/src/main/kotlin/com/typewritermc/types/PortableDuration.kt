package com.typewritermc.types

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** Bounds whole milliseconds to counts exactly representable by all supported runtimes. */
const val MAX_PORTABLE_DURATION_MILLISECONDS: Long = 9_007_199_254_740_991L

fun Long.isPortableDurationMilliseconds(): Boolean = this in -MAX_PORTABLE_DURATION_MILLISECONDS..MAX_PORTABLE_DURATION_MILLISECONDS

fun Duration.isPortableDuration(): Boolean = isFinite() && inWholeMilliseconds.isPortableDurationMilliseconds() && inWholeMilliseconds.milliseconds == this
