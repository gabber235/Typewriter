package com.typewritermc.region.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.data.CrossingCause
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData

@Entry("region_enter_event", "When a player enters a region", Colors.YELLOW, "mdi:location-enter")
/**
 * Fires when a player becomes a member of the configured region. The cause is `Teleported`
 * when the player teleported across the boundary. When [cancel] evaluates true, the
 * underlying [org.bukkit.event.player.PlayerMoveEvent] or
 * [org.bukkit.event.player.PlayerTeleportEvent] is halted. Engulf crossings, where the
 * region moves into a stationary player, have no event to cancel. The flag does nothing
 * there, but the other actions still run.
 *
 * ## How could this be used?
 *
 * Welcome a player into a town with a chat message and a sound. Or block low rank players
 * from approaching the king by pairing the cancel flag with a criteria gate.
 */
class RegionEnterEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The region whose entries to observe.")
    @Default(RegionDefaults.REGION_REFERENCE)
    override val region: RegionData = RegionReferenceData(),
    @Help("Restrict to these crossing causes. Empty list means all causes match.")
    override val causes: List<CrossingCause> = emptyList(),
    @Help("How far clear of the region a player must move before this can fire again. The enter itself always fires the moment the boundary is crossed.")
    override val boundaryInset: Var<Double> = ConstVar(0.0),
    override val cancel: Var<Boolean> = ConstVar(false),
) : RegionEventEntry
