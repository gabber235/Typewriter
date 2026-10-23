package com.typewritermc.realm.edit

import com.typewritermc.authoring.ValueReplacement
import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.authoring.use
import com.typewritermc.authoring.writeField
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.SequenceResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

internal data class AuthoredCollection(
    val type: NamedTypeUse,
    val representation: SequenceResolvedRepresentation,
)

internal fun update(
    resources: MutableMap<ResourceId, AuthoringRecord>,
    location: ValueLocation,
    value: DataValue,
    problems: MutableList<ValueProblem>,
) {
    val record = resources[location.resource]
    if (record == null) {
        problems += ValueProblem(location = location, code = "resource_missing")
        return
    }
    val updated = record.set(location.path, value)
    if (updated == null) {
        problems += ValueProblem(location = location, code = "location_missing")
    } else {
        resources[location.resource] = updated
    }
}

internal fun insert(
    resources: MutableMap<ResourceId, AuthoringRecord>,
    intent: EditIntent.InsertWrapper,
    catalog: CheckedCatalog,
    problems: MutableList<ValueProblem>,
) {
    val record = resources[intent.value.at.resource]
    if (record == null) {
        problems += ValueProblem(location = intent.value.at, code = "expected_collection")
        return
    }
    val current = record.collectionValue(intent.value.at, catalog, problems) ?: return
    val items = current.itemsOrNull() ?: return
    if (items.any { it.id == intent.value.item.id }) {
        problems += ValueProblem(location = intent.value.at, code = "duplicate_item_id")
        return
    }
    val index = insertionIndex(items, intent.value.after)
    if (index == null) {
        problems += ValueProblem(location = intent.value.at, code = "anchor_missing")
        return
    }
    val next = items.toMutableList().also { it.add(index, intent.value.item) }
    update(resources, intent.value.at, current.withItems(next), problems)
}

internal fun remove(
    resources: MutableMap<ResourceId, AuthoringRecord>,
    intent: EditIntent.RemoveWrapper,
    problems: MutableList<ValueProblem>,
) {
    val current = resources[intent.value.at.resource]?.valueAt(intent.value.at.path)
    if (current == null) {
        problems += ValueProblem(location = intent.value.at, code = "expected_collection")
        return
    }
    val items = current.itemsOrNull()
    if (items == null) {
        problems += ValueProblem(location = intent.value.at, code = "expected_collection")
        return
    }
    if (items.none { it.id == intent.value.item }) {
        problems += ValueProblem(location = intent.value.at, code = "item_missing")
        return
    }
    update(resources, intent.value.at, current.withItems(items.filterNot { it.id == intent.value.item }), problems)
}

internal fun AuthoringRecord.collectionValue(
    location: ValueLocation,
    catalog: CheckedCatalog,
    problems: MutableList<ValueProblem>,
): DataValue? {
    val current = valueAt(location.path)
    if (current == null) {
        problems += ValueProblem(location = location, code = "expected_collection")
        return null
    }
    if (current.itemsOrNull() != null) return current
    if (current != DataValue.UNFILLED) {
        problems += ValueProblem(location = location, code = "expected_collection")
        return null
    }
    val collection = declaredCollection(location, catalog)
    if (collection == null) {
        problems += ValueProblem(location = location, code = "expected_collection")
        return null
    }
    val payload =
        when (collection.representation.kind) {
            CollectionKind.LIST -> DataValue.listValue(emptyList())
            CollectionKind.SET -> DataValue.setValue(emptyList())
            else -> unknownVariant(collection.representation.kind)
        }
    return DataValue.named(collection.type, payload)
}

internal fun AuthoringRecord.declaredCollection(
    location: ValueLocation,
    catalog: CheckedCatalog,
): AuthoredCollection? {
    val type = authoredTypeAt(location.path, catalog).namedType() ?: return null
    val checked = (catalog.resolve(type.use) as? Resolution.Ready)?.value ?: return null
    val representation = checked.schema.representation as? ResolvedRepresentation.SequenceWrapper ?: return null
    return AuthoredCollection(type, representation.value)
}

private fun AuthoringRecord.set(
    path: ValuePath,
    value: DataValue,
): AuthoringRecord? {
    if (path.segments.isEmpty()) return (value as? DataValue.RecordWrapper)?.let { copy(fields = it.value.fields) }
    val updated =
        (DataValue.RecordWrapper(payload).writeField(path, value) as? ValueReplacement.Replaced)
            ?.value as? DataValue.RecordWrapper
            ?: return null
    return copy(fields = updated.value.fields)
}

internal fun DataValue?.itemsOrNull(): List<ListItem>? =
    when (this) {
        is DataValue.NamedWrapper -> payload.itemsOrNull()
        is DataValue.ListValueWrapper -> items
        is DataValue.SetValueWrapper -> items
        else -> null
    }

internal fun DataValue.withItems(items: List<ListItem>): DataValue =
    when (this) {
        is DataValue.NamedWrapper -> DataValue.named(actualType, payload.withItems(items))
        is DataValue.ListValueWrapper -> DataValue.listValue(items)
        is DataValue.SetValueWrapper -> DataValue.setValue(items)
        else -> error("Expected a collection value.")
    }

internal fun DataValue.namedType(): NamedTypeUse? = (this as? DataValue.NamedWrapper)?.actualType

internal fun TypeUse?.namedType(): NamedTypeUse? =
    when (this) {
        is TypeUse.NamedWrapper -> value
        is TypeUse.NullableWrapper -> value.value.namedType()
        else -> null
    }

internal fun deterministicItem(
    batch: String,
    ordinal: Int,
    containing: ValueLocation,
): ItemId {
    val content = "$batch:$ordinal:${containing.resource.value}:${ValuePath.serializer.toJsonCode(containing.path)}"
    return ItemId(value = "relation:${content.sha256Hex()}")
}

internal fun ValuePath.startsWith(prefix: ValuePath): Boolean =
    segments.size >= prefix.segments.size && segments.take(prefix.segments.size) == prefix.segments

internal fun insertionIndex(
    items: List<ListItem>,
    after: ItemId?,
): Int? = if (after == null) 0 else items.indexOfFirst { it.id == after }.takeIf { it >= 0 }?.plus(1)

internal fun ValueProblem.on(resource: ResourceId): ValueProblem = copy(location = location.copy(resource = resource))

internal fun problem(
    resource: ResourceId,
    code: String,
): ValueProblem = ValueProblem(location = ValueLocation.of(resource), code = code)

internal fun resourceLinks(
    resources: Map<ResourceId, AuthoringRecord>,
    resource: ResourceId,
): List<LinkOccurrence> = resources[resource]?.let { ResourceValueMapper.discover(mapOf(resource to it)) }.orEmpty()
