package com.typewritermc.expression.operations

import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.listValue
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow

/**
 * Realm's kernel of the operations over any collection: a list, a set, or a map's entries. Items keep their
 * identities; equality is the canonical structural equality of [canonicalValueKey].
 */
internal object PortableCollectionKernel : CollectionKernel {
    override fun contains(
        source: List<ListItem>,
        value: DataValue,
    ): Boolean {
        val key = value.canonicalValueKey()
        return source.any { it.value.canonicalValueKey() == key }
    }

    override fun filter(
        source: List<ListItem>,
        predicate: List<Boolean>,
    ): List<ListItem> = source.filterIndexed { index, _ -> predicate[index] }

    override fun fold(
        source: List<ListItem>,
        initial: DataValue,
        step: PortableStep,
    ): DataValue = source.fold(initial) { accumulator, item -> step.invoke(accumulator, item) }

    /** One row per distinct key, in order of first occurrence; a row takes its first member's identity. */
    override fun groupBy(
        source: List<ListItem>,
        key: List<DataValue>,
    ): List<MapRow> {
        val groups = linkedMapOf<String, Pair<DataValue, MutableList<ListItem>>>()
        source.forEachIndexed { index, item ->
            groups.getOrPut(key[index].canonicalValueKey()) { key[index] to mutableListOf() }.second += item
        }
        return groups.values.map { (groupKey, members) ->
            MapRow(id = members.first().id, key = groupKey, value = DataValue.listValue(members))
        }
    }

    override fun map(
        source: List<ListItem>,
        body: List<DataValue>,
    ): List<ListItem> = source.mapIndexed { index, item -> ListItem(id = item.id, value = body[index]) }

    override fun size(source: List<ListItem>): Int = source.size

    /** A stable sort by [portableCompare] of the keys; descending reverses the comparison and stays stable. */
    override fun sortBy(
        source: List<ListItem>,
        key: List<DataValue>,
        direction: SortDirection,
    ): List<ListItem> {
        val sign = if (direction == SortDirection.Descending) -1 else 1
        return source.indices
            .sortedWith { left, right -> sign * portableCompare(key[left], key[right]) }
            .map(source::get)
    }

    /**
     * Insertion sort that calls the comparator exactly as the panel does: each item walks left past every sorted item
     * that orders after it, charging two collection items per comparison.
     */
    override fun sortWith(
        source: List<ListItem>,
        comparator: PortableComparator,
        meter: PortableMeter,
    ): List<ListItem> {
        val sorted = ArrayList<ListItem>(source.size)
        source.forEach { item ->
            var index = sorted.size
            while (index > 0) {
                meter.items(2)
                if (comparator.compare(sorted[index - 1], item) <= 0) break
                index--
            }
            sorted.add(index, item)
        }
        return sorted
    }

    override fun toList(source: List<ListItem>): List<ListItem> = source

    override fun toSet(source: List<ListItem>): List<ListItem> = source.distinctItems()
}

/** The items whose values are first occurrences under canonical equality, keeping their identities. */
internal fun List<ListItem>.distinctItems(): List<ListItem> {
    val seen = hashSetOf<String>()
    return filter { seen.add(it.value.canonicalValueKey()) }
}
