package com.typewritermc.authoring

import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.named
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.MappingResolvedRepresentation
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import skirout.editor.v1.type_catalog.MapRow as StoredMapRow

/**
 * A position in a stored value together with its schema, read by the value walk's rules: the schema below a position
 * comes from the stored named value's own type when one is stored there, else from the declared type, so a field of a
 * union case is found under the case its value names. The value side steps exactly as [locate] does.
 */
sealed interface TypedPosition {
    /** A value position: the type the schema [declared] there, and the [value] stored there, unfilled when nothing is. */
    data class Value(
        val declared: TypeUse,
        val value: DataValue,
    ) : TypedPosition {
        /** The type the value here has: a stored named value's own type, else the declared one. */
        val actual: TypeUse get() = (value as? DataValue.NamedWrapper)?.actualType?.use ?: declared
    }

    /** The row of [mapping] an item segment chose, [row] when one is stored, until a key or value segment picks its part. */
    data class MapRow(
        val mapping: MappingResolvedRepresentation,
        val row: StoredMapRow?,
    ) : TypedPosition
}

/** The position [segment] leads to from here, or null when the schema here has no such part. */
fun TypedPosition.step(
    segment: PathSegment,
    catalog: CheckedCatalog,
): TypedPosition? =
    when (this) {
        is TypedPosition.MapRow -> {
            when (segment) {
                PathSegment.MAP_KEY -> TypedPosition.Value(mapping.key, row?.key ?: DataValue.UNFILLED)
                PathSegment.MAP_VALUE -> TypedPosition.Value(mapping.value, row?.value ?: DataValue.UNFILLED)
                else -> null
            }
        }

        is TypedPosition.Value -> {
            stepValue(segment, catalog)
        }
    }

private fun TypedPosition.Value.stepValue(
    segment: PathSegment,
    catalog: CheckedCatalog,
): TypedPosition? {
    val schema = (catalog.resolve(actual.nonNullable()) as? Resolution.Ready)?.value?.schema ?: return null
    val child = LocatedPortableValue.Value(value).child(segment, ValuePath.root)
    val stored = (child as? LocatedPortableValue.Value)?.value ?: DataValue.UNFILLED
    return when (segment) {
        is PathSegment.FieldWrapper -> {
            schema.fields.singleOrNull { it.key == segment.name }?.let { TypedPosition.Value(it.type, stored) }
        }

        is PathSegment.ItemWrapper -> {
            when (val representation = schema.representation) {
                is ResolvedRepresentation.SequenceWrapper -> {
                    TypedPosition.Value(representation.value.item, stored)
                }

                is ResolvedRepresentation.MappingWrapper -> {
                    TypedPosition.MapRow(
                        representation.value,
                        (child as? LocatedPortableValue.Row)?.row,
                    )
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

/**
 * The position at [path] of this record on [owner], walking down from the root by [step]. A partial type starts at one
 * of its known fields. Null when no schema reaches the position.
 */
fun AuthoringRecord.typedAt(
    owner: ResourceId,
    path: ValuePath,
    catalog: CheckedCatalog,
): TypedPosition? {
    var remaining = path.segments
    val type = catalog.typeOf(owner, configuration) as? Resolution.Ready ?: return null
    var position: TypedPosition =
        when (val resolved = type.value) {
            is ResourceType.Complete -> {
                val use = checkNotNull(resolved.checked.use.named)
                TypedPosition.Value(use.use, DataValue.named(use, DataValue.RecordWrapper(payload)))
            }

            is ResourceType.Partial -> {
                val first = remaining.firstOrNull() as? PathSegment.FieldWrapper ?: return null
                val known = resolved.knownFields.singleOrNull { it.key == first.name }?.type ?: return null
                remaining = remaining.drop(1)
                TypedPosition.Value(known, field(first.name) ?: DataValue.UNFILLED)
            }
        }
    for (segment in remaining) position = position.step(segment, catalog) ?: return null
    return position
}

/** The type a value at [path] of this record on [owner] has; null when no schema reaches it or the path stops at a map row. */
fun AuthoringRecord.authoredTypeAt(
    owner: ResourceId,
    path: ValuePath,
    catalog: CheckedCatalog,
): TypeUse? = (typedAt(owner, path, catalog) as? TypedPosition.Value)?.actual

private fun TypeUse.nonNullable(): TypeUse = if (this is TypeUse.NullableWrapper) value.value else this
