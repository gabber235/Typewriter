package com.typewritermc.region.entries.event

import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.entries.shouldCancel
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.region.data.CrossingCause
import org.bukkit.entity.Player

/**
 * Centralizes trigger dispatch for region event entries. Filters by cause, then triggers
 * the configured pipeline and reports whether the underlying Bukkit event should cancel.
 */
internal object RegionEventDispatch {
    fun fireEnter(entry: RegionEnterEventEntry, player: Player, cause: CrossingCause): Boolean =
        dispatch(entry, player, cause)

    fun fireExit(entry: RegionExitEventEntry, player: Player, cause: CrossingCause): Boolean =
        dispatch(entry, player, cause)

    fun fireProximity(entry: RegionProximityEventEntry, player: Player, cause: CrossingCause): Boolean =
        dispatch(entry, player, cause)

    private fun <E : RegionEventEntry> dispatch(entry: E, player: Player, cause: CrossingCause): Boolean {
        if (!entry.causes.matches(cause)) return false
        val list = listOf(entry)
        list.triggerAllFor(player, context())
        return list.shouldCancel(player)
    }
}
