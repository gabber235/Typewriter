package com.typewritermc.playtest

import skirout.harness.v1.wire.ClientLoss
import skirout.harness.v1.wire.ClientLossKind

/**
 * A player's client was lost during the attempt: it crashed, froze until Paper timed its player out,
 * or its player left, as [kind] says. [report] names the player, why and the lost client's log; the
 * pool starts a new client for the player.
 */
class ClientLost private constructor(
    val kind: ClientLossKind,
    val report: String,
) : AssertionError(report) {
    internal constructor(player: String, loss: ClientLoss) :
        this(loss.kind, "$player's client was lost: ${loss.detail}; see ${loss.log}. The pool starts a new client for $player.")
}
