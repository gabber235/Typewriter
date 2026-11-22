package com.typewritermc.engine.reading

import com.typewritermc.authoring.text
import com.typewritermc.engine.runtime.CompiledResourceGraph
import com.typewritermc.types.field
import com.typewritermc.types.unwrapNamed
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValuePath

/** Where an entry stores a value: the published resource compilation and the path from its root. */
data class EntryLocation(
    val resource: CompiledResourceKey,
    val path: ValuePath,
) {
    /** Whether this location lies inside [other]'s value: the same resource, at [other]'s path or below it. */
    fun isWithin(other: EntryLocation): Boolean =
        resource == other.resource && path.segments.size >= other.path.segments.size &&
            path.segments.subList(0, other.path.segments.size) == other.path.segments

    /** Where this location sits inside the value at [ancestor], which it must lie [within][isWithin]. */
    fun below(ancestor: EntryLocation): ValuePath = ValuePath(segments = path.segments.drop(ancestor.path.segments.size))

    override fun toString(): String = "${resource.source.value}.${path.text}"
}

/** What the entry reader finds stored at a location. */
sealed interface Stored {
    /** The stored [value], or null where nothing is stored. */
    data class Loaded(
        val value: DataValue?,
    ) : Stored

    /** Not loaded on this engine yet: a read fails with [ValueNotLoaded] until it is. */
    data object NotLoaded : Stored
}

/**
 * What the entry reader finds at each location: the published values, or for tracked reads a snapshot that says which
 * values are loaded yet. An instance is one immutable snapshot: a change is a new instance, so a tracked read can tell
 * what changed.
 */
fun interface StoredValues {
    fun at(location: EntryLocation): Stored
}

/** What is stored at [path] inside this stored value: nothing below nothing, and not loaded below a value not loaded. */
fun Stored.below(path: ValuePath): Stored =
    when (this) {
        is Stored.Loaded -> Stored.Loaded(value?.at(path))
        Stored.NotLoaded -> Stored.NotLoaded
    }

/** A read of a value that is not loaded on this engine yet. A tracked read records it, and the derive reruns once it loads. */
class ValueNotLoaded(
    val location: EntryLocation,
) : RuntimeException("The value at $location is not loaded yet.")

/** The value at [location] in [values], or a [ValueNotLoaded] failure while it is not loaded. */
fun StoredValues.loaded(location: EntryLocation): DataValue? =
    when (val stored = at(location)) {
        is Stored.Loaded -> stored.value
        Stored.NotLoaded -> throw ValueNotLoaded(location)
    }

/** Whether [location] in [values] stores a value: anything but nothing or an explicit null. Fails while not loaded. */
fun StoredValues.has(location: EntryLocation): Boolean = loaded(location)?.unwrapNamed().let { it != null && it != DataValue.NULL }

/** The values of a publication as it was compiled: everything published is loaded. */
class PublishedValues(
    private val graph: CompiledResourceGraph,
) : StoredValues {
    override fun at(location: EntryLocation): Stored = Stored.Loaded(graph.stored[location.resource]?.value?.at(location.path))
}

/** The item identities of the list, set or map [value], in stored order; none for any other value. */
fun DataValue.itemIds(): List<ItemId> =
    when (val value = unwrapNamed()) {
        is DataValue.ListValueWrapper -> value.value.items.map { it.id }
        is DataValue.SetValueWrapper -> value.value.items.map { it.id }
        is DataValue.MapValueWrapper -> value.value.rows.map { it.id }
        else -> emptyList()
    }

/**
 * The value at [path] through nominal wrappers, or null where nothing is stored. An item of a map selects its row, and
 * a following key or value segment selects that row's key or value.
 */
private fun DataValue.at(path: ValuePath): DataValue? {
    var current: Any = this
    for (segment in path.segments) {
        current =
            when (segment) {
                is PathSegment.FieldWrapper -> {
                    ((current as? DataValue)?.unwrapNamed() as? DataValue.RecordWrapper)?.field(
                        segment.value.name,
                    )
                }

                is PathSegment.ItemWrapper -> {
                    (current as? DataValue)?.item(segment.value.id)
                }

                PathSegment.MAP_KEY -> {
                    (current as? MapRowValue)?.key
                }

                PathSegment.MAP_VALUE -> {
                    (current as? MapRowValue)?.value
                }

                else -> {
                    null
                }
            } ?: return null
    }
    return (current as? DataValue)?.takeUnless { it.unwrapNamed() == DataValue.UNFILLED }
}

/** The item [id] of this list or set, or the row [id] of this map. */
private fun DataValue.item(id: ItemId): Any? =
    when (val value = unwrapNamed()) {
        is DataValue.ListValueWrapper -> {
            value.value.items
                .firstOrNull { it.id == id }
                ?.value
        }

        is DataValue.SetValueWrapper -> {
            value.value.items
                .firstOrNull { it.id == id }
                ?.value
        }

        is DataValue.MapValueWrapper -> {
            value.value.rows
                .firstOrNull { it.id == id }
                ?.let { MapRowValue(it.key, it.value) }
        }

        else -> {
            null
        }
    }

/** A row of a stored map, between its item segment and its key or value segment. */
private class MapRowValue(
    val key: DataValue,
    val value: DataValue,
)
