package com.typewritermc.region.data

import com.typewritermc.core.entries.PriorityEntry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.ManifestEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry

/**
 * The named, reusable form of a region definition. Users create one and reference it from
 * any number of region consumers via [RegionReferenceData].
 *
 * Concrete shape entries (sphere, cuboid, capsule, cone, ellipsoid, …) extend this and
 * build their own [com.typewritermc.region.shape.Shape] from the shape specific fields they
 * expose.
 *
 * A region's priority decides which of two overlapping regions gets its way. It is the page's
 * priority unless the entry overrides it, and the region's flags inherit it.
 */
@Tags("region_definition")
interface RegionDefinitionEntry : ManifestEntry, PriorityEntry, RegionDefinition {
    /** The rules this region carries about what may happen inside it. */
    val modifiers: List<Ref<out RegionModifierEntry>>
}
