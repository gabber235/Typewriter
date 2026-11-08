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
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.formula.graph.TrackedGraph
import com.typewritermc.realm.checking.checkingServices
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
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
import io.kotest.property.Arb
import io.kotest.property.arbitrary.arbitrary
import io.kotest.property.arbitrary.boolean
import io.kotest.property.arbitrary.int
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.checking.CheckEvidence
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
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
            record(ABSTRACT_MESSAGE, form = RecordForm.OPEN)
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

/** Whether these reads observed what [location] holds: its value, or which members a collection there has. */
internal fun CapturedAuthoringReads.observedContentAt(location: ValueLocation): Boolean =
    observedInputs().any { it == InputIdentity.Value(location) || it == InputIdentity.Membership(location) }

/** A graph read as a check runs it: the resources [seed] reaches forward over the edge relation, read through the graph. */
internal data class Reach(
    val seed: ResourceId,
) : RealmQuery<Set<ResourceId>> {
    context(reads: RealmReads)
    override fun compute(): Set<ResourceId> =
        tracked()
            .reachable(seed, RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.FORWARD), maxDepth = 5)
            .resources
            .mapTo(linkedSetOf()) { it.id.toSkir() }
}

/** Reads [query] at the realm's current revision, as a check pass does. */
internal fun <T> RealmFixture.readNow(query: RealmQuery<T>): T = views.pin().use { it.reads.read(query) }

/** The evidence of [query] at the realm's current revision, as a check records it: every fact and name it read. */
internal fun RealmFixture.evidenceNow(query: RealmQuery<*>): List<CheckEvidence> =
    views.pin().use { pinned ->
        with(pinned.reads) {
            read(query)
            query.evidence { false }
        }
    }

/** Points [source]'s edges at [targets] instead, as one value edit. */
internal fun relink(
    source: ResourceId,
    targets: List<ResourceId>,
): EditIntent {
    val outgoing = ValuePath.root.field("outgoing")
    return EditIntent.createSetValue(
        at = ValueLocation.of(source, outgoing),
        value = checkNotNull(graphRecord(source, targets).valueAt(outgoing)),
    )
}

/** The nodes a generated graph edit touches. */
internal val GRAPH_NODES = (0 until 5).map { ResourceId(value = "n$it") }

/** One drawn edit of a graph of [GRAPH_NODES]: which node, and the bit set of nodes it links to. */
internal data class GraphEdit(
    val delete: Boolean,
    val node: Int,
    val targets: Int,
)

internal val graphEdits: Arb<GraphEdit> =
    arbitrary { GraphEdit(Arb.boolean().bind(), Arb.int(GRAPH_NODES.indices).bind(), Arb.int(0 until (1 shl GRAPH_NODES.size)).bind()) }

/**
 * Commits [edit] as it fits the realm: a missing node is created with its links to present nodes, a present one is
 * deleted or relinked. A refused edit changes nothing, which is a valid step too.
 */
internal suspend fun RealmFixture.apply(edit: GraphEdit) {
    val node = GRAPH_NODES[edit.node]
    val present = resources.keys
    val targets = GRAPH_NODES.filterIndexed { index, target -> edit.targets and (1 shl index) != 0 && target in present }
    commit(
        when {
            node !in present -> EditIntent.createCreateResource(id = node, record = graphRecord(node, targets))
            edit.delete -> EditIntent.createDeleteResource(id = node)
            else -> relink(node, targets)
        },
    )
}

/** [query]'s answer and evidence from the realm's live graph at its current revision. */
internal fun <T> RealmFixture.liveNow(query: RealmQuery<T>): Pair<T, Set<EditExpectation>> =
    views.pin().use { pinned -> with(pinned.reads) { read(query) to query.factsRead { false }.toSet() } }

/** [query]'s answer and evidence from a new graph over the current view, which remembers nothing. */
internal fun <T> RealmFixture.freshNow(query: RealmQuery<T>): Pair<T, Set<EditExpectation>> =
    views.pin().use { pinned ->
        with(TrackedGraph(RealmEnvironment(pinned.view, checkingServices())).pin()) { read(query) to query.factsRead { false }.toSet() }
    }
