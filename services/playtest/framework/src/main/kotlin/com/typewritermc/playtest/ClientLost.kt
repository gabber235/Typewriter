package com.typewritermc.playtest

/**
 * A player's client was lost during the attempt: it crashed, froze until Paper timed its player out,
 * or its player left. [report] names the player and why; the pool starts a new client for the player.
 */
class ClientLost internal constructor(
    val report: String,
) : AssertionError(report) {
    internal constructor(player: String, reason: String) :
        this("$player's client was lost: $reason. The pool starts a new client for $player.")
}
