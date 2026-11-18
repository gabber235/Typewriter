package com.typewritermc.playtest.plugin

import com.typewritermc.playtest.wire.entries
import org.bukkit.entity.Player
import skirout.harness.v1.wire.StateKind

/**
 * The vanilla and Paper state of a player, which Paper wipes before every attempt so each attempt finds
 * its players as players who never played: every [kind][PaperState] Paper itself keeps, then the
 * inventory. State a plugin keeps is that plugin's to reset on the [PlayerWipeEvent]. Marks and
 * their check serve the framework's own test kit, which proves the wipe clears each kind. Main thread
 * only.
 */
internal class Wipe {
    /** Clears every kind Paper keeps, then the inventory, as closing a container can return items to it. */
    fun wipe(player: Player) {
        for (state in PaperState.entries) state.wipe(player)
        player.inventory.clear()
        player.setItemOnCursor(null)
    }

    /** Leaves a mark of [kind] on the player, as an earlier attempt could. */
    fun mark(
        player: Player,
        kind: StateKind,
    ) {
        state(kind).mark(player)
    }

    /** Whether the player carries a mark of [kind], whoever left it. */
    fun marked(
        player: Player,
        kind: StateKind,
    ): Boolean = state(kind).marked(player)

    companion object {
        /** The kinds Paper keeps, which this wipe clears. */
        val KINDS: Set<StateKind> = StateKind.entries.filter { PaperState.of(it) != null }.toSet()
    }
}

private fun state(kind: StateKind): PaperState = requireNotNull(PaperState.of(kind)) { "$kind is a kind a plugin keeps, not Paper" }
