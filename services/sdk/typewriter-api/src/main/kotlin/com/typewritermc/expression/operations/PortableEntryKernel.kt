package com.typewritermc.expression.operations

import skirout.editor.v1.type_catalog.DataValue

/** Realm's kernel of the map entry operations: an entry is a record of key and value. */
internal object PortableEntryKernel : EntryKernel {
    override fun of(
        key: DataValue,
        value: DataValue,
    ): DataValue = entryValue(key, value)
}
