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

internal fun AuthoringRecord.authoredTypeAt(
    path: ValuePath,
    catalog: CheckedCatalog,
): TypeUse? {
    if (path.segments.isEmpty()) return (configuration as? TypeSelection.CompleteWrapper)?.use?.use
    var type: TypeUse?
    var value: DataValue?
    var remaining: List<PathSegment>
    when (val selection = configuration) {
        is TypeSelection.CompleteWrapper -> {
            type = selection.use.use
            value = DataValue.RecordWrapper(payload)
            remaining = path.segments
        }

        is TypeSelection.PendingWrapper -> {
            val first = path.segments.first() as? PathSegment.FieldWrapper ?: return null
            val partial = catalog.resolvePartial(selection) as? Resolution.Ready ?: return null
            type = partial.value.knownFields
                .singleOrNull { it.key == first.name }
                ?.type ?: return null
            value = field(first.name)
            remaining = path.segments.drop(1)
            value.namedPayload()?.let { named ->
                type = named.first
                value = named.second
            }
        }

        else -> {
            unknownVariant(selection)
        }
    }
    var mapRow: MapRow? = null
    var mapping: MappingResolvedRepresentation? = null
    for (segment in remaining) {
        val pendingMapping = mapping
        if (pendingMapping != null) {
            type =
                when (segment) {
                    PathSegment.MAP_KEY -> pendingMapping.key
                    PathSegment.MAP_VALUE -> pendingMapping.value
                    else -> return null
                }
            value =
                when (segment) {
                    PathSegment.MAP_KEY -> mapRow?.key
                    PathSegment.MAP_VALUE -> mapRow?.value
                    is PathSegment.FieldWrapper, is PathSegment.ItemWrapper -> return null
                }
            mapping = null
            mapRow = null
            value.namedPayload()?.let { named ->
                type = named.first
                value = named.second
            }
            continue
        }

        val traversed = type?.traversable() ?: return null
        val resolved = catalog.resolve(traversed) as? Resolution.Ready ?: return null
        when (segment) {
            is PathSegment.FieldWrapper -> {
                type = resolved.value.schema.fields
                    .singleOrNull { it.key == segment.name }
                    ?.type ?: return null
                value = value?.unwrapNamed().recordField(segment.name)
            }

            is PathSegment.ItemWrapper -> {
                when (val representation = resolved.value.schema.representation) {
                    is ResolvedRepresentation.SequenceWrapper -> {
                        type = representation.value.item
                        value = value?.unwrapNamed().collectionItem(segment)
                    }

                    is ResolvedRepresentation.MappingWrapper -> {
                        mapping = representation.value
                        mapRow = (value?.unwrapNamed() as? DataValue.MapValueWrapper)?.rows?.singleOrNull { it.id == segment.id }
                    }

                    else -> {
                        return null
                    }
                }
            }

            PathSegment.MAP_KEY, PathSegment.MAP_VALUE -> {
                return null
            }

            else -> {
                unknownVariant(segment)
            }
        }
        value.namedPayload()?.let { named ->
            type = named.first
            value = named.second
        }
    }
    if (mapping != null) return null
    return type
}

private fun TypeUse.traversable(): TypeUse = if (this is TypeUse.NullableWrapper) value.value else this

private fun DataValue?.namedPayload(): Pair<TypeUse, DataValue>? =
    (this as? DataValue.NamedWrapper)?.let {
        it.actualType.use to it.payload
    }

private fun DataValue?.recordField(name: String): DataValue? = (this as? DataValue.RecordWrapper)?.field(name)

private fun DataValue?.collectionItem(segment: PathSegment.ItemWrapper): DataValue? =
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
