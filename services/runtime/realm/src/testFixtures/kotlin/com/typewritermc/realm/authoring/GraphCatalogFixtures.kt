package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ReachabilityQuery
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDrafts
import com.typewritermc.authoring.RouteQuery
import com.typewritermc.authoring.RouteResult
import com.typewritermc.authoring.TraversalBudget
import com.typewritermc.authoring.UnresolvedLink
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.testkit.definitions
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

internal fun graphRecord(
    source: ResourceId,
    targets: List<ResourceId>,
    badTarget: ResourceId? = null,
): AuthoringRecord =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(NODE_USE),
        mapOf(
            "outgoing" to
                DataValue.named(
                    EDGE_LIST_USE,
                    DataValue.listValue(
                        targets.mapIndexed { index, target ->
                            ListItem(
                                id = ItemId(value = "${source.value}_$index"),
                                value =
                                    DataValue.named(
                                        EDGE_LINK_USE,
                                        DataValue.createLink(
                                            endpoint = EDGE_SOURCE,
                                            target = LinkTarget(resource = target, opposite = null),
                                        ),
                                    ),
                            )
                        },
                    ),
                ),
            "bad" to
                if (badTarget == null) {
                    DataValue.UNFILLED
                } else {
                    DataValue.named(
                        BAD_LINK_USE,
                        DataValue.createLink(endpoint = BAD_ENDPOINT, target = LinkTarget(resource = badTarget, opposite = null)),
                    )
                },
            "buttons" to DataValue.named(BUTTON_LIST_USE, DataValue.listValue(emptyList())),
            "optional" to DataValue.NULL,
            "message" to DataValue.UNFILLED,
            "nested" to DataValue.UNFILLED,
            "expanding" to DataValue.UNFILLED,
        ),
    )

internal fun graphDefinition(name: String) = TypeDefinitionId.qualified("graph", name)

internal val NODE = graphDefinition("node")
internal val EDGE_LINK = graphDefinition("edge_link")
internal val EDGE_LIST = graphDefinition("edge_list")
internal val BAD_LINK = graphDefinition("bad_link")
internal val BUTTON = graphDefinition("button")
internal val BUTTON_LIST = graphDefinition("button_list")
internal val OPTIONAL_LINK_HOLDER = graphDefinition("optional_link_holder")
internal val ABSTRACT_MESSAGE = graphDefinition("abstract_message")
internal val LINK_MESSAGE = graphDefinition("link_message")
internal val BOX = graphDefinition("box")
internal val EXPANDING = graphDefinition("expanding")
internal val WRAPPER = graphDefinition("wrapper")
internal val BOX_PARAMETER = ParameterKey(owner = BOX, index = 0)
internal val EXPANDING_PARAMETER = ParameterKey(owner = EXPANDING, index = 0)
internal val WRAPPER_PARAMETER = ParameterKey(owner = WRAPPER, index = 0)
internal val NODE_USE = NODE.namedUse()
internal val EDGE_LINK_USE = EDGE_LINK.namedUse()
internal val EDGE_LIST_USE = EDGE_LIST.namedUse()
internal val BAD_LINK_USE = BAD_LINK.namedUse()
internal val BUTTON_LIST_USE = BUTTON_LIST.namedUse()
internal val BUTTON_USE = BUTTON.namedUse()
internal val OPTIONAL_LINK_HOLDER_USE = OPTIONAL_LINK_HOLDER.namedUse()
internal val EDGE_SOURCE = EndpointId(value = "edge:source")
internal val EDGE_TARGET = EndpointId(value = "edge:target")
internal val BAD_ENDPOINT = EndpointId(value = "bad:source")
internal val BAD_TARGET = EndpointId(value = "bad:target")
internal val EDGE =
    RelationContract.of(
        RelationId(value = "edge"),
        EndpointDefinition(
            id = EDGE_SOURCE,
            slot = EndpointSlot.FIRST,
            resource = NODE.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            id = EDGE_TARGET,
            slot = EndpointSlot.SECOND,
            resource = NODE.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        families = setOf(RelationFamilyId(value = "selected")),
    )
internal val BAD =
    RelationContract.of(
        RelationId(value = "bad"),
        EndpointDefinition(
            id = BAD_ENDPOINT,
            slot = EndpointSlot.FIRST,
            resource = NODE.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            id = BAD_TARGET,
            slot = EndpointSlot.SECOND,
            resource = NODE.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
    )
internal val GRAPH_CATALOG =
    DefinitionCatalog(
        definitions {
            record(NODE) {
                field("outgoing", EDGE_LIST.template())
                field("bad", BAD_LINK.template())
                field("buttons", BUTTON_LIST.template())
                field("optional", OPTIONAL_LINK_HOLDER.template().nullable())
                field("message", ABSTRACT_MESSAGE.template())
                field("nested", BOX.template(listOf(BOX.template(listOf(BAD_LINK.template())))))
                field("expanding", EXPANDING.template(listOf(ScalarKind.TEXT.template)))
            }
            link(EDGE_LINK, endpoint = EDGE_SOURCE, target = NODE.template())
            sequence(EDGE_LIST, item = EDGE_LINK.template(), kind = CollectionKind.LIST)
            link(BAD_LINK, endpoint = BAD_ENDPOINT, target = NODE.template())
            record(BUTTON) { field("target", BAD_LINK.template()) }
            sequence(BUTTON_LIST, item = BUTTON.template(), kind = CollectionKind.LIST)
            record(OPTIONAL_LINK_HOLDER) { field("target", BAD_LINK.template()) }
            record(ABSTRACT_MESSAGE, abstract = true)
            record(LINK_MESSAGE, parents = listOf(ABSTRACT_MESSAGE.namedTemplate())) { field("target", BAD_LINK.template()) }
            record(
                BOX,
                parameters = listOf(TypeParameter.partial(key = BOX_PARAMETER, name = "T")),
            ) { field("value", BOX_PARAMETER.template) }
            record(WRAPPER, parameters = listOf(TypeParameter.partial(key = WRAPPER_PARAMETER, name = "T"))) {
                field("value", WRAPPER_PARAMETER.template)
            }
            record(EXPANDING, parameters = listOf(TypeParameter.partial(key = EXPANDING_PARAMETER, name = "T"))) {
                field("next", EXPANDING.template(listOf(WRAPPER.template(listOf(EXPANDING_PARAMETER.template)))))
            }
        },
        relations = listOf(EDGE, BAD),
    )

/** Runs [block] on fresh reads of [resources], or of [staged] edits over them, through the graph catalog. */
internal fun <T> graphReads(
    resources: Map<ResourceId, AuthoringRecord>,
    staged: Map<ResourceId, AuthoringRecord>? = null,
    block: CapturedAuthoringReads.() -> T,
): T {
    val store = InMemoryAuthoringViewStore(GRAPH_CATALOG.lease(CatalogGeneration(value = "graph_catalog")), AuthoringSeed(resources))
    return try {
        store.capture().use { lease ->
            CapturedAuthoringReads(if (staged == null) lease.originalView() else lease.stagedView(staged)).block()
        }
    } finally {
        store.close()
    }
}

internal fun CapturedAuthoringReads.reachable(
    seed: ResourceId,
    links: RelationSelection,
    maxDepth: Int? = null,
    budget: TraversalBudget = TraversalBudget(),
) = RealmGraphReads.reachable(ReachabilityQuery(setOf(seed.toResourceId()), links, ResourceDrafts, maxDepth, budget))

internal fun CapturedAuthoringReads.route(
    seed: ResourceId,
    target: ResourceId,
    links: RelationSelection,
    maxDepth: Int,
    budget: TraversalBudget = TraversalBudget(),
) = RealmGraphReads.routes(RouteQuery(setOf(seed.toResourceId()), target.toResourceId(), links, maxDepth, budget))

/** Each route as the resources it passes, from its seed to the target. */
internal fun RouteResult.resourcePaths(): List<List<ResourceId>> =
    paths.map { steps ->
        listOf(
            steps
                .first()
                .from.resource
                .toSkir(),
        ) + steps.map { it.to.resource.toSkir() }
    }

/** Each unfilled link as the resource holding it and its endpoint. */
internal fun List<UnresolvedLink>.unfilled(): List<Pair<ResourceId, EndpointId>> =
    map {
        it.shouldBeInstanceOf<UnresolvedLink.Unfilled>().occurrence.let { occurrence ->
            occurrence.location.resource to
                occurrence.endpoint
        }
    }
