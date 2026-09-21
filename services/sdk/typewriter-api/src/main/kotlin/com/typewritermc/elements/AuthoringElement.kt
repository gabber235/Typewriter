package com.typewritermc.elements

import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.Serializable

fun DataValue.elementName(): String = requireElementField("name").also { require(it.isNotBlank()) { "Element names must not be blank." } }

fun DataValue.withElementName(name: String): DataValue {
    require(name.isNotBlank()) { "Element names must not be blank." }
    return withElementField("name", name)
}

private fun DataValue.requireElementField(field: String): String {
    val record = this as? DataValue.Record ?: error("Element values must be records.")
    return (record.fields[field] as? DataValue.StringValue)?.value
        ?: error("Element field '$field' must be a string.")
}

private fun DataValue.withElementField(
    field: String,
    value: String,
): DataValue {
    val record = this as? DataValue.Record ?: error("Element values must be records.")
    require(field in record.fields) { "Element field '$field' is required." }
    return record.copy(fields = record.fields + (field to DataValue.StringValue(value)))
}

/**
 * Separates an element value tree from its outgoing reference edges.
 *
 * [valueWithSlots] contains markers keyed by [references]. Slots must be unique, but construction does not verify
 * that every marker has a matching edge; [ReferenceAssembler] performs that check.
 */
@Serializable
data class StoredElementValue(
    val valueWithSlots: DataValue,
    val references: List<StoredReference>,
) {
    init {
        require(references.map(StoredReference::slot).distinct().size == references.size) {
            "Stored element reference slots must be unique."
        }
    }
}

/**
 * Identifies a reference occurrence within one stored element value.
 *
 * Slots distinguish multiple occurrences of the same target and survive mutations that preserve those occurrences.
 * Only nonblank values are accepted.
 */
@JvmInline
@Serializable
value class ReferenceSlotId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Reference slot ids must not be blank." }
    }
}

/**
 * Connects one stored slot to its resource target and expected structural type.
 *
 * The expected type is checked during assembly; recording an edge does not establish that its target exists.
 */
@Serializable
data class StoredReference(
    val slot: ReferenceSlotId,
    val target: ResourceId,
    val expectedType: TypeExpression,
    val sourcePath: DataPath = DataPath(),
)
