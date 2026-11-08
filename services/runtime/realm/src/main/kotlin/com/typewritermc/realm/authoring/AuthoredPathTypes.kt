package com.typewritermc.realm.authoring

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.field
import com.typewritermc.authoring.id
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.name
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.use
import com.typewritermc.configuration.name
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.rows
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.MappingResolvedRepresentation
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath

/**
 * The type a value at [path] of this record has: the stored named value's own type where one is stored, else the type
 * the schema declares. Null when no schema reaches it or the path stops at a map row.
 */
internal fun AuthoringRecord.authoredTypeAt(
    path: ValuePath,
    catalog: CheckedCatalog,
): TypeUse? = storedPositionAt(path, catalog)?.takeUnless { it.atMapRow }?.actual

/**
 * The position at [path] of this record, walking down from the root: each stored named value's own type decides the
 * fields below it, as the value walk decides them, so a field of a union case is found under the case its value
 * names. A pending selection starts at one of its known fields. Null when no schema reaches the position.
 */
internal fun AuthoringRecord.storedPositionAt(
    path: ValuePath,
    catalog: CheckedCatalog,
): StoredPosition? {
    var position: StoredPosition
    var remaining = path.segments
    when (val selection = configuration) {
        is TypeSelection.CompleteWrapper -> {
            position = StoredPosition(selection.use.use, DataValue.named(selection.use, DataValue.RecordWrapper(payload)))
        }

        is TypeSelection.PendingWrapper -> {
            val first = remaining.firstOrNull() as? PathSegment.FieldWrapper ?: return null
            val partial = catalog.resolvePartial(selection) as? Resolution.Ready ?: return null
            val type = partial.value.knownFields.singleOrNull { it.key == first.name }?.type ?: return null
            position = StoredPosition(type, field(first.name) ?: DataValue.UNFILLED)
            remaining = remaining.drop(1)
        }

        else -> {
            unknownVariant(selection)
        }
    }
    for (segment in remaining) position = position.step(segment, catalog) ?: return null
    return position
}

/**
 * One position on the way down a stored record: the type the schema [declared] there, the [value] stored there
 * (unfilled when nothing is), and the map whose row an item segment chose, until a key or value segment picks a part.
 */
internal class StoredPosition(
    val declared: TypeUse,
    val value: DataValue,
    private val row: Pair<MappingResolvedRepresentation, MapRow?>? = null,
) {
    /** The type the value here has: a stored named value's own type, else the declared one. */
    val actual: TypeUse get() = (value as? DataValue.NamedWrapper)?.value?.actualType?.use ?: declared

    /** Whether an item segment chose a map row and the key or value segment that picks its part is still to come. */
    val atMapRow: Boolean get() = row != null

    /** The position [segment] leads to, or null when the schema here has no such part. */
    fun step(
        segment: PathSegment,
        catalog: CheckedCatalog,
    ): StoredPosition? {
        row?.let { (mapping, chosen) ->
            return when (segment) {
                PathSegment.MAP_KEY -> StoredPosition(mapping.key, chosen?.key ?: DataValue.UNFILLED)
                PathSegment.MAP_VALUE -> StoredPosition(mapping.value, chosen?.value ?: DataValue.UNFILLED)
                else -> null
            }
        }
        val schema = (catalog.resolve(catalog.expand(actual.traversable())) as? Resolution.Ready)?.value?.schema ?: return null
        val payload = value.unwrapNamed()
        return when (segment) {
            is PathSegment.FieldWrapper -> {
                val field = schema.fields.singleOrNull { it.key == segment.name } ?: return null
                StoredPosition(field.type, (payload as? DataValue.RecordWrapper)?.field(segment.name) ?: DataValue.UNFILLED)
            }

            is PathSegment.ItemWrapper -> {
                when (val representation = schema.representation) {
                    is ResolvedRepresentation.SequenceWrapper -> {
                        StoredPosition(representation.value.item, payload.collectionItem(segment) ?: DataValue.UNFILLED)
                    }

                    is ResolvedRepresentation.MappingWrapper -> {
                        val chosen = (payload as? DataValue.MapValueWrapper)?.rows?.singleOrNull { it.id == segment.id }
                        StoredPosition(declared, value, representation.value to chosen)
                    }

                    else -> {
                        null
                    }
                }
            }

            PathSegment.MAP_KEY, PathSegment.MAP_VALUE -> {
                null
            }

            else -> {
                unknownVariant(segment)
            }
        }
    }
}

/**
 * The type the schema declares for the field at [path], before a stored value there names its own actual type: a
 * nullable slot stays nullable while it holds a value. Null when no schema reaches the field.
 */
internal fun AuthoringRecord.declaredFieldTypeAt(
    path: ValuePath,
    catalog: CheckedCatalog,
): TypeUse? {
    val field = path.segments.lastOrNull() as? PathSegment.FieldWrapper ?: return null
    val container = authoredTypeAt(ValuePath(segments = path.segments.dropLast(1)), catalog) ?: return null
    val resolved = catalog.resolve(container.traversable()) as? Resolution.Ready ?: return null
    return resolved.value.schema.fields
        .singleOrNull { it.key == field.name }
        ?.type
}

private fun TypeUse.traversable(): TypeUse = if (this is TypeUse.NullableWrapper) value.value else this

private fun DataValue.collectionItem(segment: PathSegment.ItemWrapper): DataValue? =
    when (this) {
        is DataValue.ListValueWrapper -> items.singleOrNull { it.id == segment.id }?.value
        is DataValue.SetValueWrapper -> items.singleOrNull { it.id == segment.id }?.value
        else -> null
    }

internal fun expectedType(
    subject: DraftBinding,
    path: RelativeFieldPattern,
    catalog: CheckedCatalog,
): TypeUse? {
    var cursor: TypeCursor =
        when (val expected = subject.expected) {
            is DraftExpectation.Complete -> TypeCursor.Checked(expected.type)
            is DraftExpectation.PartialRoot -> TypeCursor.Partial(expected.schema)
        }
    path.segments.forEach { segment ->
        cursor =
            when (segment) {
                is FieldPatternSegment.FieldWrapper -> cursor.field(segment.name, catalog) ?: return null
                FieldPatternSegment.ITEMS -> cursor.item(catalog) ?: return null
                FieldPatternSegment.KEYS -> cursor.key(catalog) ?: return null
                FieldPatternSegment.VALUES -> cursor.value(catalog) ?: return null
                else -> unknownVariant(segment)
            }
    }
    return cursor.use
}

private sealed interface TypeCursor {
    val use: TypeUse?

    data class Checked(
        val checked: CheckedType,
    ) : TypeCursor {
        override val use: TypeUse = checked.use
    }

    data class Applied(
        override val use: TypeUse,
    ) : TypeCursor

    data class Partial(
        val schema: PartialSchema,
    ) : TypeCursor {
        override val use: TypeUse? = null
    }
}

private fun TypeCursor.field(
    name: String,
    catalog: CheckedCatalog,
): TypeCursor? =
    when (this) {
        is TypeCursor.Partial -> {
            schema.knownFields
                .singleOrNull { it.key == name }
                ?.type
                ?.let(TypeCursor::Applied)
        }

        else -> {
            resolve(catalog)
                ?.schema
                ?.fields
                ?.singleOrNull { it.key == name }
                ?.type
                ?.let(TypeCursor::Applied)
        }
    }

private fun TypeCursor.item(catalog: CheckedCatalog): TypeCursor? =
    when (val representation = resolve(catalog)?.schema?.representation) {
        is ResolvedRepresentation.SequenceWrapper -> TypeCursor.Applied(representation.value.item)
        else -> null
    }

private fun TypeCursor.key(catalog: CheckedCatalog): TypeCursor? =
    (resolve(catalog)?.schema?.representation as? ResolvedRepresentation.MappingWrapper)?.value?.key?.let(TypeCursor::Applied)

private fun TypeCursor.value(catalog: CheckedCatalog): TypeCursor? =
    (resolve(catalog)?.schema?.representation as? ResolvedRepresentation.MappingWrapper)?.value?.value?.let(TypeCursor::Applied)

private fun TypeCursor.resolve(catalog: CheckedCatalog): CheckedType? =
    when (this) {
        is TypeCursor.Checked -> checked
        is TypeCursor.Applied -> (catalog.resolve(use) as? Resolution.Ready)?.value
        is TypeCursor.Partial -> null
    }

internal fun AuthoringRecord.valueAt(path: ValuePath): DataValue? =
    (DataValue.RecordWrapper(payload).locate(path) as? LocatedPortableValue.Value)?.value
