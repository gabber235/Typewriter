package com.typewritermc.authoring

import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.field
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.use
import skirout.editor.v1.authoring.UnsetValue
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/**
 * What an unset field reads as: the value of [field] in a record of [owner] whose stored fields are [stored]. The
 * contracts know no constructor, so whoever holds the native bindings answers, the declared default at first.
 */
fun interface UnsetFields {
    fun valueOf(
        owner: CheckedType,
        stored: DataValue.RecordWrapper,
        field: String,
    ): DataValue
}

/**
 * Whether a record may leave this field out, which makes it unset: it has a constructor default and holds no links. A
 * link is a relation fact the realm keeps on both sides, not a value a creator chooses or a layer above could give, so a
 * field of links is always stored, empty when nothing links.
 */
fun ResolvedField.mayBeUnset(catalog: CheckedCatalog): Boolean = hasConstructorDefault && !type.holdsLinks(catalog)

/** Whether a value of this type is a link or a collection of them, read through nullable and named wrappers. */
private fun TypeUse.holdsLinks(
    catalog: CheckedCatalog,
    depth: Int = 0,
): Boolean {
    if (depth > MAX_LINK_DEPTH) return false
    val inner = if (this is TypeUse.NullableWrapper) value.value else this
    val representation = (catalog.resolve(inner) as? Resolution.Ready)?.value?.schema?.representation ?: return false
    return when (representation) {
        is ResolvedRepresentation.LinkWrapper -> true
        is ResolvedRepresentation.SequenceWrapper -> representation.value.item.holdsLinks(catalog, depth + 1)
        is ResolvedRepresentation.MappingWrapper -> representation.value.value.holdsLinks(catalog, depth + 1)
        else -> false
    }
}

private const val MAX_LINK_DEPTH = 8

/**
 * This value with every unset field at any depth stored as it reads through [unset], for a reader that cannot ask, such
 * as an engine decoding a publication. Every stored value stays as it is, item and row identities included.
 */
fun CompleteValue.withUnsetFields(
    catalog: CheckedCatalog,
    unset: UnsetFields,
): CompleteValue = CompleteValue(schema, UnsetFill(catalog, unset).payload(value, schema, ValuePath.root, 0))

/**
 * Each field this record on [owner] leaves unset, at any depth below a stored value, at its path from the record root
 * with the value it reads as through [unset]. A partial type has no constructor to ask, so only fields below its stored
 * known fields are listed.
 */
fun AuthoringRecord.unsetValues(
    owner: ResourceId,
    catalog: CheckedCatalog,
    unset: UnsetFields,
): List<UnsetValue> {
    val type = catalog.typeOf(owner, configuration) as? Resolution.Ready ?: return emptyList()
    val found = mutableListOf<UnsetValue>()
    val fill = UnsetFill(catalog, unset) { path, value -> found += UnsetValue(path = path, value = value) }
    when (val resolved = type.value) {
        is ResourceType.Complete -> {
            fill.payload(DataValue.RecordWrapper(payload), resolved.checked, ValuePath.root, 0)
        }

        is ResourceType.Partial -> {
            resolved.knownFields.forEach { known -> field(known.key)?.let { fill.fill(it, ValuePath.root.field(known.key), 1) } }
        }
    }
    return found
}

/**
 * Fills unset fields while descending a value by the schema each stored named value names, telling [found] the path
 * and value of each.
 */
private class UnsetFill(
    private val catalog: CheckedCatalog,
    private val unset: UnsetFields,
    private val found: (ValuePath, DataValue) -> Unit = { _, _ -> },
) {
    /** [value] at [path], a position of any type: only a named value has fields below it. */
    fun fill(
        value: DataValue,
        path: ValuePath,
        depth: Int,
    ): DataValue {
        if (value !is DataValue.NamedWrapper || depth > MAX_FILL_DEPTH) return value
        val checked = (catalog.resolve(value.actualType.use) as? Resolution.Ready)?.value ?: return value
        return DataValue.named(value.actualType, payload(value.payload, checked, path, depth + 1))
    }

    /** [value] at [path], the payload of [checked], or a named value of it at the root of a complete value. */
    fun payload(
        value: DataValue,
        checked: CheckedType,
        path: ValuePath,
        depth: Int,
    ): DataValue {
        if (value is DataValue.NamedWrapper) return fill(value, path, depth)
        return when (val representation = checked.schema.representation) {
            is ResolvedRepresentation.RecordWrapper -> record(value, checked, representation.value.fields, path, depth)
            is ResolvedRepresentation.SequenceWrapper -> items(value, path, depth)
            is ResolvedRepresentation.MappingWrapper -> rows(value, path, depth)
            else -> value
        }
    }

    private fun record(
        value: DataValue,
        checked: CheckedType,
        fields: List<ResolvedField>,
        path: ValuePath,
        depth: Int,
    ): DataValue {
        val record = value as? DataValue.RecordWrapper ?: return value
        val filled =
            fields.mapNotNull { field ->
                val stored = record.field(field.key)
                val at = path.field(field.key)
                when {
                    stored != null -> field.key to fill(stored, at, depth)
                    field.mayBeUnset(catalog) -> field.key to unset.valueOf(checked, record, field.key).also { found(at, it) }
                    else -> null
                }
            }
        return DataValue.record(filled.toMap())
    }

    private fun items(
        value: DataValue,
        path: ValuePath,
        depth: Int,
    ): DataValue =
        when (value) {
            is DataValue.ListValueWrapper -> {
                DataValue.listValue(
                    value.items.map { it.copy(value = fill(it.value, path.item(it.id), depth)) },
                )
            }

            is DataValue.SetValueWrapper -> {
                DataValue.setValue(value.items.map { it.copy(value = fill(it.value, path.item(it.id), depth)) })
            }

            else -> {
                value
            }
        }

    private fun rows(
        value: DataValue,
        path: ValuePath,
        depth: Int,
    ): DataValue =
        (value as? DataValue.MapValueWrapper)
            ?.let { map ->
                DataValue.mapValue(
                    map.rows.map { row ->
                        val at = path.item(row.id)
                        row.copy(key = fill(row.key, at.mapKey(), depth), value = fill(row.value, at.mapValue(), depth))
                    },
                )
            }
            ?: value
}

private const val MAX_FILL_DEPTH = 64
