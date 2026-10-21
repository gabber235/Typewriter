package com.typewritermc.realm.search

import com.typewritermc.types.ResourceId
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.payload
import com.typewritermc.types.rows
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue

/** Derived search terms are stored beside the canonical resource in its write transaction. */
internal fun authoredSearchText(
    resource: ResourceId,
    record: AuthoringRecord,
): String {
    val terms = mutableListOf(resource.value)
    record.fields.forEach { it.value.collectText(terms) }
    return terms.distinct().joinToString(" ")
}

private fun DataValue.collectText(target: MutableList<String>) {
    when (this) {
        is DataValue.StringValueWrapper -> {
            target += value
        }

        is DataValue.EnumCaseWrapper -> {
            target += value
        }

        is DataValue.NamedWrapper -> {
            payload.collectText(target)
        }

        is DataValue.RecordWrapper -> {
            fields.forEach { it.value.collectText(target) }
        }

        is DataValue.ListValueWrapper -> {
            items.forEach { it.value.collectText(target) }
        }

        is DataValue.SetValueWrapper -> {
            items.forEach { it.value.collectText(target) }
        }

        is DataValue.MapValueWrapper -> {
            rows.forEach { row ->
                row.key.collectText(target)
                row.value.collectText(target)
            }
        }

        else -> {
            Unit
        }
    }
}
