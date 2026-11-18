package com.typewritermc.playtest

/**
 * A `within` window ended with a check that never held. [report] names each missed check, the window's
 * last tick and what the player perceived then; [at] is the requirement line that opened the window.
 */
class WindowMissed internal constructor(
    val report: String,
    val at: String?,
) : AssertionError(report)
