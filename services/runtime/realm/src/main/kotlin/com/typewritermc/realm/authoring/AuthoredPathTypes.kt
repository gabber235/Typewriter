package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValuePath
import com.typewritermc.types.DataValue
import com.typewritermc.types.MapRow
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation

internal fun AuthoringRecord.authoredTypeAt(
    path: ValuePath,
    catalog: CheckedCatalog,
): TypeUse? {
    if (path.segments.isEmpty()) return (configuration as? TypeSelection.Complete)?.use
    var type: TypeUse?
    var value: DataValue?
    var remaining: List<PathSegment>
    when (val selection = configuration) {
        is TypeSelection.Complete -> {
            type = selection.use
            value = DataValue.Record(fields)
            remaining = path.segments
        }

        is TypeSelection.Pending -> {
            val first = path.segments.first() as? PathSegment.Field ?: return null
            val partial = catalog.resolvePartial(selection) as? Resolution.Ready ?: return null
            type = partial.value.knownFields
                .singleOrNull { it.key == first.name }
                ?.type ?: return null
            value = fields[first.name]
            remaining = path.segments.drop(1)
            value.namedPayload()?.let { named ->
                type = named.first
                value = named.second
            }
        }
    }
    var mapRow: MapRow? = null
    var mapping: ResolvedRepresentation.Mapping? = null
    for (segment in remaining) {
        val pendingMapping = mapping
        if (pendingMapping != null) {
            type =
                when (segment) {
                    PathSegment.MapKey -> pendingMapping.key
                    PathSegment.MapValue -> pendingMapping.value
                    else -> return null
                }
            value =
                when (segment) {
                    PathSegment.MapKey -> mapRow?.key
                    PathSegment.MapValue -> mapRow?.value
                    is PathSegment.Field, is PathSegment.Item -> return null
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
            is PathSegment.Field -> {
                type = resolved.value.schema.fields
                    .singleOrNull { it.key == segment.name }
                    ?.type ?: return null
                value = value.unwrapNamed().recordField(segment.name)
            }

            is PathSegment.Item -> {
                when (val representation = resolved.value.schema.representation) {
                    is ResolvedRepresentation.Sequence -> {
                        type = representation.item
                        value = value.unwrapNamed().collectionItem(segment)
                    }

                    is ResolvedRepresentation.Mapping -> {
                        mapping = representation
                        mapRow = (value.unwrapNamed() as? DataValue.MapValue)?.rows?.singleOrNull { it.id == segment.id }
                    }

                    else -> {
                        return null
                    }
                }
            }

            PathSegment.MapKey, PathSegment.MapValue -> {
                return null
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

private fun TypeUse.traversable(): TypeUse = if (this is TypeUse.Nullable) value else this

private fun DataValue?.namedPayload(): Pair<TypeUse.Named, DataValue>? = (this as? DataValue.Named)?.let { it.actualType to it.payload }

private fun DataValue?.unwrapNamed(): DataValue? =
    when (this) {
        is DataValue.Named -> payload.unwrapNamed()
        else -> this
    }

private fun DataValue?.recordField(name: String): DataValue? = (this as? DataValue.Record)?.fields?.get(name)

private fun DataValue?.collectionItem(segment: PathSegment.Item): DataValue? =
    when (this) {
        is DataValue.ListValue -> items.singleOrNull { it.id == segment.id }?.value
        is DataValue.SetValue -> items.singleOrNull { it.id == segment.id }?.value
        else -> null
    }
