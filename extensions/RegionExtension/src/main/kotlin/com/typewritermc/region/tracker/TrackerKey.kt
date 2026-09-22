package com.typewritermc.region.tracker

import com.typewritermc.region.data.RegionDefinition
import java.util.UUID

/**
 * Identifies a tracker in the engine's registry.
 *
 * Keys compare by the [definition] itself. [RegionDefinitionEntry][com.typewritermc.region.data.RegionDefinitionEntry]
 * instances are singletons, and inline
 * [RegionDefinitionData][com.typewritermc.region.data.RegionDefinitionData] is a data class
 * whose `Var` fields implement value equality, so two structurally identical inline
 * definitions share one tracker.
 *
 * [viewerId] is `null` for definitions whose placement is fully constant. Those resolve the
 * same for everyone and are shared by all subscribers. Definitions with any non const
 * placement `Var` get one tracker per viewer.
 */
data class TrackerKey(
    val definition: RegionDefinition,
    val viewerId: UUID?,
)
