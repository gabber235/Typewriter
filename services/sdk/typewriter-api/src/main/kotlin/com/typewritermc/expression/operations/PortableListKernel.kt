package com.typewritermc.expression.operations

import com.typewritermc.types.canonicalValueKey
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem

/** Realm's kernel of the list operations. Indexes count items from zero. */
internal object PortableListKernel : ListKernel {
    /** An item that holds unfilled entries anywhere inside is missing at the item's location. */
    override fun at(
        source: Located<List<ListItem>>,
        index: Int,
    ): PortableMaybe<DataValue> {
        val item =
            source.value.getOrNull(index)
                ?: throw OperationFailure(
                    KernelFailure.CollectionKeyAbsent,
                    "The index $index is outside the list of ${source.value.size} items.",
                )
        if (item.value.containsUnfilled()) return PortableMaybe.Missing(listOfNotNull(source.item(item.id)))
        return PortableMaybe.Value(item.value)
    }

    /** Items are named by their argument position and their identity there, so equal identities stay distinct. */
    override fun concat(
        first: List<ListItem>,
        second: List<ListItem>,
        rest: List<List<ListItem>>,
    ): List<ListItem> =
        (listOf(first, second) + rest).flatMapIndexed { position, items ->
            items.map { item -> ListItem(id = nestedItemId(ItemId(value = position.toString()), item.id), value = item.value) }
        }

    override fun flatten(source: List<ListItem>): List<ListItem> =
        source.flatMap { outer ->
            outer.value.asItems().map { inner -> ListItem(id = nestedItemId(outer.id, inner.id), value = inner.value) }
        }

    override fun indexOf(
        source: List<ListItem>,
        value: DataValue,
    ): Int {
        val key = value.canonicalValueKey()
        return source.indexOfFirst { it.value.canonicalValueKey() == key }
    }

    override fun lastIndexOf(
        source: List<ListItem>,
        value: DataValue,
    ): Int {
        val key = value.canonicalValueKey()
        return source.indexOfLast { it.value.canonicalValueKey() == key }
    }

    override fun of(values: List<DataValue>): List<ListItem> = positionalItems(values)

    /** Charges every produced integer as a collection item before producing any. */
    override fun range(
        start: Int,
        end: Int,
        step: Int,
        meter: PortableMeter,
    ): List<Int> {
        if (step == 0) throw OperationFailure(KernelFailure.InvalidRangeStep, "The range step is zero.")
        val span = end.toLong() - start.toLong()
        val count = if (span == 0L || (span > 0) != (step > 0)) 0L else (span + step - (if (step > 0) 1 else -1)) / step
        meter.items(count.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
        return List(count.toInt()) { index -> (start + index.toLong() * step).toInt() }
    }

    override fun reverse(source: List<ListItem>): List<ListItem> = source.asReversed().toList()

    override fun scan(
        source: List<ListItem>,
        initial: DataValue,
        step: PortableStep,
    ): List<ListItem> = positionalItems(source.runningFold(initial) { accumulator, item -> step.invoke(accumulator, item) })

    override fun slice(
        source: List<ListItem>,
        start: Int,
        end: Int,
    ): List<ListItem> {
        if (start < 0 || end < start || end > source.size) {
            throw OperationFailure(KernelFailure.SliceRange, "The slice $start to $end is outside the list of ${source.size} items.")
        }
        return source.subList(start, end).toList()
    }

    /** Pairs are named by the first list's identities. */
    override fun zip(
        first: List<ListItem>,
        second: List<ListItem>,
    ): List<ListItem> = first.zip(second) { left, right -> ListItem(id = left.id, value = entryValue(left.value, right.value)) }
}
