package com.typewritermc.realm.authoring

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.name
import com.typewritermc.authoring.payload
import com.typewritermc.configuration.name
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath

internal fun expectedType(
    subject: DraftBinding,
    path: RelativeFieldPattern,
    catalog: CheckedCatalog,
): TypeUse? {
    var cursor: TypeCursor =
        when (val type = subject.type) {
            is ResourceType.Complete -> TypeCursor.Checked(type.checked)
            is ResourceType.Partial -> TypeCursor.Partial(type.schema)
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
