package com.typewritermc.region.entries.event

import com.typewritermc.engine.paper.entry.entries.CancelableEventEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.data.CrossingCause
import com.typewritermc.region.data.RegionData

/**
 * Base interface for the region event entries. Each carries a [region], a [causes] filter
 * limiting which crossing kinds fire, and a [boundaryInset] hysteresis.
 *
 * Concrete entries also extend [CancelableEventEntry] so users can halt the underlying
 * Bukkit event when the crossing is player driven.
 */
interface RegionEventEntry : CancelableEventEntry {
    val region: RegionData

    /**
     * The crossing causes this entry reacts to. An empty list reacts to any cause. To
     * split behavior across causes, use two entries with different cause filters on the
     * same region.
     */
    val causes: List<CrossingCause>

    /**
     * Hysteresis distance in blocks. The enter fires the moment the boundary is crossed;
     * a member must then move more than this distance clear of the region before the
     * leave fires. This prevents repeat fires from a player walking along the boundary
     * without ever delaying the enter. A value of `0.0` fires the leave on the exact
     * boundary.
     *
     * The inset belongs to the entry rather than the region, so two entries on the same
     * region can use different values.
     */
    val boundaryInset: Var<Double>
}

/**
 * An empty cause list matches any cause.
 */
internal fun List<CrossingCause>.matches(cause: CrossingCause): Boolean =
    isEmpty() || contains(cause)
