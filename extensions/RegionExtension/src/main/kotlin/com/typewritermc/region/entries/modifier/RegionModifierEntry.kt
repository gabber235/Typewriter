package com.typewritermc.region.entries.modifier

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.ManifestEntry
import com.typewritermc.engine.paper.entry.entries.Var

/**
 * A rule a region carries about what may happen inside it: who may break its blocks, whether
 * pistons may push into it, whether mobs may spawn there.
 *
 * A region either carries a flag of a given kind, and then it decides, or it does not, and then
 * the next region down in priority decides. Flags have no priority of their own: they inherit the
 * priority of the region that lists them, so a region's rules always move together.
 */
@Tags("region_modifier")
interface RegionModifierEntry : ManifestEntry

/**
 * A flag whose whole rule is one allowance, which a variable may drive.
 *
 * A variable needs a player to resolve. Events with no player behind them, like a crop growing or
 * sand coming to rest, have none, and [allowed] answers `null` for them. Such a flag has nothing to
 * say about those events and abstains, rather than reading as a denial.
 */
interface AllowanceModifierEntry : RegionModifierEntry {
    val allowed: Var<Boolean>
}
