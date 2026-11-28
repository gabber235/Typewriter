package com.typewritermc.playtest.pool

import skirout.harness.v1.test_run.LossCause

/**
 * Whether a loss of this kind loses the new client the pool started for a lost one, before it stepped
 * with its Paper. The new client's own losses do: its process exits or is killed for memory, its pool connection closes, or it
 * drops off or cannot join its Paper, each heard from that client or its process alone. A leave or a
 * stall Paper reports by the player's name tells of the lost client, which Paper may see go after the
 * new one started.
 */
internal val LossCause.losesNewClient: Boolean
    get() =
        when (this) {
            is LossCause.ExitedWrapper, is LossCause.KilledForMemoryWrapper, is LossCause.LeftWrapper, is LossCause.DroppedWrapper -> true
            else -> false
        }
