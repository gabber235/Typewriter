package com.typewritermc.playtest

/**
 * Work counted for a player ended without its effect, such as an outbound operation of an engine that
 * failed. [report] names the work, the player, the tick after which it began and the cause. A requirement
 * that causes the fault on purpose expects this failure where it causes it.
 */
class WorkFailed internal constructor(
    val report: String,
) : AssertionError(report) {
    internal constructor(player: String, work: String, beganAfter: Int, cause: String) :
        this("$player's work \"$work\" began after tick $beganAfter and failed: $cause.")
}
