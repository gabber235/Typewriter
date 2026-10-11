package com.typewritermc.realm.search

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId

/** Derived search terms are stored beside the canonical resource in its write transaction. */
internal fun authoredSearchText(
    resource: ResourceId,
    definition: ResourceDefinitionId,
    record: AuthoringRecord,
): String {
    val terms = mutableListOf(resource.value, definition.value)
    record.fields.values.forEach { it.collectText(terms) }
    return terms.distinct().joinToString(" ")
}

private fun DataValue.collectText(target: MutableList<String>) {
    when (this) {
        is DataValue.StringValue -> {
            target += value
        }

        is DataValue.EnumCase -> {
            target += key
        }

        is DataValue.Named -> {
            payload.collectText(target)
        }

        is DataValue.Record -> {
            fields.values.forEach { it.collectText(target) }
        }

        is DataValue.ListValue -> {
            items.forEach { it.value.collectText(target) }
        }

        is DataValue.SetValue -> {
            items.forEach { it.value.collectText(target) }
        }

        is DataValue.MapValue -> {
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
