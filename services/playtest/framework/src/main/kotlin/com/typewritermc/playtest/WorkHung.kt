package com.typewritermc.playtest

/**
 * Work a plugin counted for a player still ran 1 s of wall clock after it began. [report] names the
 * work, the player and the tick after which it began. The framework never cancels the work; it holds
 * no more ticks, and the attempt fails.
 */
class WorkHung internal constructor(
    val report: String,
) : AssertionError(report) {
    internal constructor(player: String, work: String, beganAfter: Int) :
        this("$player's work \"$work\" began after tick $beganAfter and still ran 1 s later; it was not cancelled.")
}
