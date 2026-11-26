package com.typewritermc.playtest

import skirout.harness.v1.test_run.LossCause
import skirout.harness.v1.wire.ClientLoss

/**
 * A player's client was lost during the attempt: it crashed, froze until Paper timed its player out,
 * or its player left, as [loss] says. [report] names the player, why and the lost client's log; the
 * pool starts a new client for the player.
 */
class ClientLost private constructor(
    val loss: LossCause,
    val report: String,
) : AssertionError(report) {
    internal constructor(player: String, loss: ClientLoss) :
        this(loss.cause, "$player's client was lost: ${loss.detail}; see ${loss.log}. The pool starts a new client for $player.")
}
