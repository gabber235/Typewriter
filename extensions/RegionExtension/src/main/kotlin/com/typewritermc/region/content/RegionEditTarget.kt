package com.typewritermc.region.content

import com.typewritermc.core.entries.Entry
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefinition
import com.typewritermc.region.data.RegionDefinitionData
import kotlin.reflect.KClass
import kotlin.reflect.KProperty1
import kotlin.reflect.full.isSubclassOf
import kotlin.reflect.full.memberProperties

/**
 * Where the geometry an editor writes to lives inside its entry.
 *
 * A definition entry *is* the region: its placement and shape fields sit at the top level. A
 * consumer entry holds an inline definition inside one of its own fields, so the same fields
 * sit behind a prefix, and the shape sits one algebraic hop deeper again.
 *
 * The paths are the ones the staging manager writes with, so they carry the `value` hops the
 * panel serializes algebraic types with and the Kotlin object graph does not have.
 */
class RegionEditTarget(
    val entryId: String,
    private val inlineField: String?,
) {
    /** Prefix of the placement fields: `origin`, `offset`, `yaw` and `pitch`. */
    val placementPath: String = inlineField?.let { "$it.$VALUE." } ?: ""

    /** Prefix of the shape's own fields, like a sphere's `radius` or a cuboid's `halfX`. */
    val shapePath: String = inlineField?.let { "$it.$VALUE.$SHAPE.$VALUE." } ?: ""

    /**
     * The definition [entry] holds, or `null` when the field that should hold it points at a
     * definition entry instead of inlining one. Those are edited on the entry they live on.
     */
    fun definitionOf(entry: Entry): RegionDefinition? {
        val field = inlineField ?: return entry as? RegionDefinition
        return entry.regionData(field) as? RegionDefinition
    }

    private companion object {
        const val VALUE = "value"
        const val SHAPE = "shape"
    }
}

/**
 * The target the content mode requested for [fieldPath] on [entry] edits, or `null` when the
 * path names no region geometry.
 */
fun regionEditTarget(entry: Entry, fieldPath: String): RegionEditTarget? {
    if (entry is RegionDefinition) return RegionEditTarget(entry.id, null)

    val field = fieldPath.substringBefore('.').takeIf { it != fieldPath } ?: return null
    if (entry.regionData(field) == null) return null
    return RegionEditTarget(entry.id, field)
}

private fun Entry.regionData(field: String): RegionData? {
    val property = regionProperties().firstOrNull { it.name == field } ?: return null
    // An entry's getter is arbitrary user code called once a second from the workspace scan;
    // one that throws must not take the scan down with it.
    return runCatching { property.getter.call(this) }.getOrNull() as? RegionData
}

/**
 * The properties whose declared type can hold a region.
 *
 * The workspace scans every entry in the library for inline definitions once a second, so
 * filtering by declared type keeps it from invoking getters that cannot return one.
 *
 * There is deliberately no cache here: `memberProperties` is already memoized per class by
 * `kotlin-reflect`, and a cache keyed by entry class would pin the old class loader across a
 * reload.
 */
private fun Entry.regionProperties(): List<KProperty1<out Entry, *>> =
    this::class.memberProperties.filter { property ->
        val declared = property.returnType.classifier as? KClass<*> ?: return@filter false
        declared.isSubclassOf(RegionData::class)
    }

/**
 * Every field on the entry holding an inline region definition, as field name to data
 * pairs. References to definition entries are not listed; those regions are edited on the
 * definition entry itself.
 */
fun Entry.inlineRegionFields(): List<Pair<String, RegionDefinitionData>> =
    regionProperties().mapNotNull { property ->
        val data = runCatching { property.getter.call(this) }.getOrNull() as? RegionDefinitionData
            ?: return@mapNotNull null
        property.name to data
    }
