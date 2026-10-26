package com.typewritermc.realm.edit

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.linkOrNull
import com.typewritermc.testkit.RecordFields
import com.typewritermc.testkit.definitions
import com.typewritermc.types.ACYCLIC_RELATION_FAMILY_ID
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import io.kotest.matchers.nulls.shouldBeNull
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/*
 * A synthetic node type for relation rules no real catalog reaches: one record with a link field for each side of four
 * node to node relations, so a suite picks the relations and delete policies it needs and authors both ends on nodes.
 *
 *   pair     first (scalar)            <-> second (scalar)
 *   parent   children (list of links)  <-> parent (scalar)
 *   many     manyFirst (list of links) <-> manySecond (list of links)
 *   nested   wrapper.inner (scalar)    <-> nestedSecond (scalar)
 */

internal val NODE = TypeDefinitionId.qualified("test", "node")
internal val WRAPPER = TypeDefinitionId.qualified("test", "wrapper")

internal val PAIR_FIRST = EndpointId(value = "pair:first")
internal val PAIR_SECOND = EndpointId(value = "pair:second")
internal val PARENT_FIRST = EndpointId(value = "parent:first")
internal val PARENT_SECOND = EndpointId(value = "parent:second")
internal val MANY_FIRST = EndpointId(value = "many:first")
internal val MANY_SECOND = EndpointId(value = "many:second")
internal val NESTED_FIRST = EndpointId(value = "nested:first")
internal val NESTED_SECOND = EndpointId(value = "nested:second")

internal val OWNERSHIP_FAMILY = setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID))
internal val ACYCLIC_FAMILY = setOf(RelationFamilyId(value = ACYCLIC_RELATION_FAMILY_ID))

private val CHILDREN = TypeDefinitionId.qualified("test", "children")
private val MANY_FIRST_LIST = TypeDefinitionId.qualified("test", "many_first_list")
private val MANY_SECOND_LIST = TypeDefinitionId.qualified("test", "many_second_list")
private val ENDPOINTS = listOf(PAIR_FIRST, PAIR_SECOND, PARENT_FIRST, PARENT_SECOND, MANY_FIRST, MANY_SECOND, NESTED_FIRST, NESTED_SECOND)

/** The link type each node field holds for [endpoint]. */
internal fun linkType(endpoint: EndpointId): TypeDefinitionId =
    TypeDefinitionId.qualified(
        "test",
        endpoint.value.replace(':', '_') + "_link",
    )

/**
 * The node catalog with [relations]. The `children` list holds [childItem] items, links of the parent relation unless a
 * suite embeds wrapper records there instead; [extraFields] adds node fields a single rule needs.
 */
internal fun nodeCatalog(
    vararg relations: RelationContract,
    childItem: TypeDefinitionId = linkType(PARENT_FIRST),
    extraFields: RecordFields.() -> Unit = {},
) = DefinitionCatalog(nodeDefinitions(childItem, extraFields), relations.toList())

/** The node type definitions [nodeCatalog] declares. */
internal fun nodeDefinitions(
    childItem: TypeDefinitionId = linkType(PARENT_FIRST),
    extraFields: RecordFields.() -> Unit = {},
): List<TypeDefinition> =
    definitions {
        record(NODE) {
            field("first", linkType(PAIR_FIRST).template())
            field("second", linkType(PAIR_SECOND).template())
            field("children", CHILDREN.template())
            field("parent", linkType(PARENT_SECOND).template())
            field("manyFirst", MANY_FIRST_LIST.template())
            field("manySecond", MANY_SECOND_LIST.template())
            field("wrapper", WRAPPER.template())
            field("nestedSecond", linkType(NESTED_SECOND).template())
            field("label", ScalarKind.TEXT.template)
            extraFields()
        }
        record(WRAPPER) { field("inner", linkType(NESTED_FIRST).template()) }
        ENDPOINTS.forEach { link(linkType(it), it, NODE.template()) }
        sequence(CHILDREN, childItem.template(), CollectionKind.LIST)
        sequence(MANY_FIRST_LIST, linkType(MANY_FIRST).template(), CollectionKind.LIST)
        sequence(MANY_SECOND_LIST, linkType(MANY_SECOND).template(), CollectionKind.LIST)
    }

/** One node to the other through `first` and `second`, each side holding at most one link. */
internal fun pairRelation(
    onDelete: RelationDeletePolicy = RelationDeletePolicy.CLEAR,
    families: Set<RelationFamilyId> = emptySet(),
) = relation("pair", PAIR_FIRST, EndpointCardinality.ONE, onDelete, PAIR_SECOND, EndpointCardinality.ONE, onDelete, families)

/** A parent's `children` to each child's `parent`; [parentDelete] applies when the parent is deleted. */
internal fun parentRelation(
    parentDelete: RelationDeletePolicy = RelationDeletePolicy.CLEAR,
    families: Set<RelationFamilyId> = emptySet(),
) = relation(
    "parent_child",
    PARENT_FIRST,
    EndpointCardinality.ONE,
    parentDelete,
    PARENT_SECOND,
    EndpointCardinality.MANY,
    RelationDeletePolicy.CLEAR,
    families,
)

/** `manyFirst` to `manySecond`; [second] limits how many targets one source may link. */
internal fun manyRelation(second: EndpointCardinality = EndpointCardinality.MANY) =
    relation("many", MANY_FIRST, EndpointCardinality.MANY, RelationDeletePolicy.CLEAR, MANY_SECOND, second, RelationDeletePolicy.CLEAR)

/** The link inside `wrapper` to `nestedSecond`; [second] limits how many links one wrapper side may hold. */
internal fun nestedRelation(second: EndpointCardinality = EndpointCardinality.ONE) =
    relation("nested", NESTED_FIRST, EndpointCardinality.ONE, RelationDeletePolicy.CLEAR, NESTED_SECOND, second, RelationDeletePolicy.CLEAR)

private fun relation(
    id: String,
    first: EndpointId,
    firstCardinality: EndpointCardinality,
    firstDelete: RelationDeletePolicy,
    second: EndpointId,
    secondCardinality: EndpointCardinality,
    secondDelete: RelationDeletePolicy,
    families: Set<RelationFamilyId> = emptySet(),
) = RelationContract.of(
    RelationId(value = id),
    EndpointDefinition(
        id = first,
        slot = EndpointSlot.FIRST,
        resource = NODE.namedTemplate(),
        cardinality = firstCardinality,
        onDelete = firstDelete,
    ),
    EndpointDefinition(
        id = second,
        slot = EndpointSlot.SECOND,
        resource = NODE.namedTemplate(),
        cardinality = secondCardinality,
        onDelete = secondDelete,
    ),
    families,
)

/** A node record; every field not given is unfilled, collections empty. */
internal fun node(
    first: DataValue = DataValue.UNFILLED,
    second: DataValue = DataValue.UNFILLED,
    children: List<ListItem> = emptyList(),
    parent: DataValue = DataValue.UNFILLED,
    manyFirst: List<ListItem> = emptyList(),
    manySecond: List<ListItem> = emptyList(),
    wrapper: DataValue = wrapper(DataValue.UNFILLED),
    nestedSecond: DataValue = DataValue.UNFILLED,
    label: String = "",
) = AuthoringRecord.of(
    TypeSelection.CompleteWrapper(NODE.namedUse()),
    mapOf(
        "first" to first,
        "second" to second,
        "children" to DataValue.named(CHILDREN.namedUse(), DataValue.listValue(children)),
        "parent" to parent,
        "manyFirst" to DataValue.named(MANY_FIRST_LIST.namedUse(), DataValue.listValue(manyFirst)),
        "manySecond" to DataValue.named(MANY_SECOND_LIST.namedUse(), DataValue.listValue(manySecond)),
        "wrapper" to wrapper,
        "nestedSecond" to nestedSecond,
        "label" to DataValue.StringValueWrapper(label),
    ),
)

/** The link value a node field holds for [endpoint]: to [target], whose inverse occurrence sits at [opposite]. */
internal fun link(
    endpoint: EndpointId,
    target: ResourceId,
    opposite: ValuePath? = null,
): DataValue =
    DataValue.named(
        linkType(endpoint).namedUse(),
        DataValue.createLink(endpoint = endpoint, target = LinkTarget(resource = target, opposite = opposite)),
    )

/** A `wrapper` record value around [inner]. */
internal fun wrapper(inner: DataValue): DataValue = DataValue.named(WRAPPER.namedUse(), DataValue.record(mapOf("inner" to inner)))

/** The top level node field [field]. */
internal fun path(field: String): ValuePath = ValuePath.root.field(field)

/** The top level field [field] of [resource]. */
internal fun at(
    resource: ResourceId,
    field: String,
): ValueLocation = ValueLocation.of(resource, path(field))

/** The occurrence of [endpoint] at [location], linking to [target]. */
internal fun occurrence(
    endpoint: EndpointId,
    location: ValueLocation,
    target: ResourceId,
    opposite: ValuePath? = null,
) = LinkOccurrence(
    id = LinkOccurrenceId(endpoint = endpoint, location = location),
    source = location.resource,
    target = LinkTarget(resource = target, opposite = opposite),
)

/** Connects the occurrence of [endpoint] at [location] to [target], with the inverse [counterpart] or the inferred one. */
internal fun connection(
    endpoint: EndpointId,
    location: ValueLocation,
    target: ResourceId,
    counterpart: CounterpartChoice? = null,
) = ConnectIntent(source = occurrence(endpoint, location, target), target = target, counterpart = counterpart)

/** The [connection] as an edit intent. */
internal fun connect(
    endpoint: EndpointId,
    location: ValueLocation,
    target: ResourceId,
    counterpart: CounterpartChoice? = null,
): EditIntent = EditIntent.ConnectRelationWrapper(connection(endpoint, location, target, counterpart))

/** A new wrapper record embedded into [containing] to hold the inverse link. */
internal fun newWrapper(containing: ValueLocation) =
    CounterpartChoice.createNew(
        containing = containing,
        prepared =
            PreparedValue(
                content =
                    PreparedContent.RecordWrapper(
                        AuthoringRecord.of(TypeSelection.CompleteWrapper(WRAPPER.namedUse()), mapOf("inner" to DataValue.UNFILLED)),
                    ),
                findings = emptyList(),
            ),
    )

/** Asserts that neither side of a pair relation between [first] and [second] holds a link any more. */
internal fun Map<ResourceId, AuthoringRecord>.shouldHoldNoPairLink(
    first: ResourceId,
    second: ResourceId,
) {
    getValue(first).linkOrNull("first").shouldBeNull()
    getValue(second).linkOrNull("second").shouldBeNull()
}
