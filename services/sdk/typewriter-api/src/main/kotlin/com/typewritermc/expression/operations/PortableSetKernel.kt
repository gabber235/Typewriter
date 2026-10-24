package com.typewritermc.expression.operations

import com.typewritermc.types.canonicalValueKey
import skirout.editor.v1.type_catalog.ListItem

/** Realm's kernel of the set operations: the first occurrence of equal items is kept, with its identity. */
internal object PortableSetKernel : SetKernel {
    override fun difference(
        first: List<ListItem>,
        second: List<ListItem>,
    ): List<ListItem> {
        val excluded = second.mapTo(hashSetOf()) { it.value.canonicalValueKey() }
        return first.distinctItems().filter { it.value.canonicalValueKey() !in excluded }
    }

    override fun intersect(
        first: List<ListItem>,
        second: List<ListItem>,
    ): List<ListItem> {
        val included = second.mapTo(hashSetOf()) { it.value.canonicalValueKey() }
        return first.distinctItems().filter { it.value.canonicalValueKey() in included }
    }
}
