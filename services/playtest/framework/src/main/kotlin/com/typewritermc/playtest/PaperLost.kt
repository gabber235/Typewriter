package com.typewritermc.playtest

/**
 * The attempt's own Paper was lost: it exited or did not boot in time, while booting or while the body
 * ran. [report] says which Paper, why, and where its log lies; the shared Paper and every other attempt
 * never noticed.
 */
class PaperLost internal constructor(
    val report: String,
) : AssertionError(report)
