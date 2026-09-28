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

@Entry("region_exit_event", "When a player exits a region", Colors.YELLOW, "mdi:location-exit")
/**
 * Fires when a player stops being a member of the configured region. Cancellation and
 * teleport semantics are the same as [RegionEnterEventEntry], so a player can also be
 * blocked from exiting a region.
 *
 * Deleting the region, or pointing this entry at another one, does not fire an exit for the
 * players who were inside it. Their membership simply ends with the old region.
 *
 * ## How could this be used?
 *
 * Lock players inside the boss arena until the fight ends, using a criteria gated cancel
 * on this entry.
 */
class RegionExitEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The region whose exits to observe.")
    @Default(RegionDefaults.REGION_REFERENCE)
    override val region: RegionData = RegionReferenceData(),
    @Help("Restrict to these crossing causes. Empty list means all causes match.")
    override val causes: List<CrossingCause> = emptyList(),
    @Help("How far clear of the boundary a player must move before the exit fires. Raise it so someone pacing the edge does not fire it repeatedly.")
    override val boundaryInset: Var<Double> = ConstVar(0.0),
    override val cancel: Var<Boolean> = ConstVar(false),
) : RegionEventEntry
