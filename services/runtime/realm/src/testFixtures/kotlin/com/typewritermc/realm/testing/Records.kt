package com.typewritermc.realm.testing

import com.typewritermc.authoring.definition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.unwrapNamed
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** The saved value of the top level field [field], with its named type unwrapped; null when the field is absent. */
fun AuthoringRecord.value(field: String): DataValue? = valueAt(ValuePath.root.field(field))?.unwrapNamed()

/** The text in the top level field [field]. */
fun AuthoringRecord.text(field: String): String = (value(field) as DataValue.StringValueWrapper).value

/** The link at [path], or null when it is unfilled. */
fun AuthoringRecord.linkAt(path: ValuePath): LinkTarget? = (valueAt(path)?.unwrapNamed() as? DataValue.LinkWrapper)?.value?.target

/** The link in the top level field [field], or null when it is unfilled. */
fun AuthoringRecord.linkOrNull(field: String): LinkTarget? = (value(field) as? DataValue.LinkWrapper)?.value?.target

/** The resource the link in the top level field [field] points at. */
fun AuthoringRecord.link(field: String): ResourceId = requireNotNull(linkOrNull(field)) { "$field holds no link: ${value(field)}" }.resource

/** The resources the links in the list or set field [field] point at, in order. */
fun AuthoringRecord.links(field: String): List<ResourceId> = linkTargets(field).map { it.resource }

/** The link targets in the list or set field [field], in order; an unfilled collection has none. */
fun AuthoringRecord.linkTargets(field: String): List<LinkTarget> =
    when (val collection = value(field)) {
        is DataValue.ListValueWrapper -> collection.items.map { it.value }
        is DataValue.SetValueWrapper -> collection.items.map { it.value }
        DataValue.UNFILLED, null -> emptyList()
        else -> error("$field holds no collection: $collection")
    }.map { (it.unwrapNamed() as DataValue.LinkWrapper).value.target }

/** The item ids of the list or set field [field], in order; an unfilled collection has none. */
fun AuthoringRecord.itemIds(field: String): List<ItemId> =
    when (val collection = value(field)) {
        is DataValue.ListValueWrapper -> collection.items.map { it.id }
        is DataValue.SetValueWrapper -> collection.items.map { it.id }
        DataValue.UNFILLED, null -> emptyList()
        else -> error("$field holds no collection: $collection")
    }

/** The saved resources whose configured type is [type]. */
fun Map<ResourceId, AuthoringRecord>.typesOf(type: TypeDefinitionId): List<ResourceId> =
    filterValues { it.configuration.definition == type }.keys.toList()

/** The source and target resource of every link the Realm derives from saved authoring, in order. */
fun RealmFixture.linkedPairs(): Set<Pair<String, String>> =
    views.read { view ->
        view.links.values.mapTo(sortedSetOf(compareBy({ it.first }, { it.second }))) {
            it.source.value to
                it.target.resource.value
        }
    }

/** A saved record of the complete type [type] holding [fields]; a field not given stays absent. */
fun completeRecord(
    type: TypeDefinitionId,
    vararg fields: Pair<String, DataValue>,
): AuthoringRecord = AuthoringRecord.of(TypeSelection.CompleteWrapper(type.namedUse()), fields.toMap())

/** The record of [type] that [value] encodes to, with its top level field [field] left unfilled, as an author prepares it. */
fun RealmFixture.unfilledRecord(
    type: TypeUse,
    value: Any,
    field: String,
): AuthoringRecord = encoder.record(type, value).with(field, DataValue.UNFILLED)

/** A list or set item [id] holding the text [value], which is [id] when no value is given. */
fun textItem(
    id: String,
    value: String = id,
): ListItem = ListItem(id = ItemId(value = id), value = DataValue.StringValueWrapper(value))

/** A link value of [type] whose [endpoint] points at [target], with the inverse at [opposite] when one is given. */
fun linkValue(
    type: NamedTypeUse,
    endpoint: EndpointId,
    target: ResourceId,
    opposite: ValuePath? = null,
): DataValue = DataValue.named(type, DataValue.createLink(endpoint = endpoint, target = LinkTarget(resource = target, opposite = opposite)))
