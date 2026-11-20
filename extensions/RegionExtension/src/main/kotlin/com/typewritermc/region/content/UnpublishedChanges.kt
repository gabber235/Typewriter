package com.typewritermc.region.content

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.stagedEntry
import com.typewritermc.region.data.RegionDefinition
import com.typewritermc.region.data.buildShapeOrNull
import com.typewritermc.region.data.RegionDefinitionEntry

/**
 * `true` when the region's staged geometry differs from the published one: someone
 * applied placement or shape changes, in game or on the web, that are not live yet.
 * Compares the constant placement values and the built shape, which are data classes,
 * so variable bound fields and a staged copy that fails to parse never read as a
 * difference.
 */
fun hasUnpublishedRegionChanges(entryId: String): Boolean {
    val ref = Ref(entryId, RegionDefinitionEntry::class)
    return differs(ref.get(), ref.stagedEntry())
}

/** [hasUnpublishedRegionChanges] for the region an editor writes to, inline or not. */
fun hasUnpublishedRegionChanges(target: RegionEditTarget): Boolean {
    val ref = Ref(target.entryId, Entry::class)
    return differs(ref.get()?.let(target::definitionOf), ref.stagedEntry()?.let(target::definitionOf))
}

private fun differs(published: RegionDefinition?, staged: RegionDefinition?): Boolean {
    if (published == null || staged == null) return false
    return staged.geometrySignature() != published.geometrySignature()
}

private fun RegionDefinition.geometrySignature(): List<Any?> = listOf(
    (origin as? ConstVar)?.value,
    (offset as? ConstVar)?.value,
    (yaw as? ConstVar)?.value,
    (pitch as? ConstVar)?.value,
    (roll as? ConstVar)?.value,
    buildShapeOrNull(),
)
