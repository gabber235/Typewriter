package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.LinkInspectionQuery
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
import com.typewritermc.authoring.with
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.realm.checking.dependencies
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
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring_facts.TraversalDirection
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
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

private fun graphRecord(
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

private fun graphDefinition(name: String) = TypeDefinitionId.qualified("graph", name)

private val NODE = graphDefinition("node")
private val EDGE_LINK = graphDefinition("edge_link")
private val EDGE_LIST = graphDefinition("edge_list")
private val BAD_LINK = graphDefinition("bad_link")
private val BUTTON = graphDefinition("button")
private val BUTTON_LIST = graphDefinition("button_list")
private val OPTIONAL_LINK_HOLDER = graphDefinition("optional_link_holder")
private val ABSTRACT_MESSAGE = graphDefinition("abstract_message")
private val LINK_MESSAGE = graphDefinition("link_message")
private val BOX = graphDefinition("box")
private val EXPANDING = graphDefinition("expanding")
private val WRAPPER = graphDefinition("wrapper")
private val BOX_PARAMETER = ParameterKey(owner = BOX, index = 0)
private val EXPANDING_PARAMETER = ParameterKey(owner = EXPANDING, index = 0)
private val WRAPPER_PARAMETER = ParameterKey(owner = WRAPPER, index = 0)
private val NODE_USE = NODE.namedUse()
private val EDGE_LINK_USE = EDGE_LINK.namedUse()
private val EDGE_LIST_USE = EDGE_LIST.namedUse()
private val BAD_LINK_USE = BAD_LINK.namedUse()
private val BUTTON_LIST_USE = BUTTON_LIST.namedUse()
private val BUTTON_USE = BUTTON.namedUse()
private val OPTIONAL_LINK_HOLDER_USE = OPTIONAL_LINK_HOLDER.namedUse()
private val EDGE_SOURCE = EndpointId(value = "edge:source")
private val EDGE_TARGET = EndpointId(value = "edge:target")
private val BAD_ENDPOINT = EndpointId(value = "bad:source")
private val BAD_TARGET = EndpointId(value = "bad:target")
private val EDGE =
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
private val BAD =
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
private val GRAPH_CATALOG =
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

private val a = ResourceId(value = "a")
private val b = ResourceId(value = "b")
private val c = ResourceId(value = "c")
private val d = ResourceId(value = "d")
private val e = ResourceId(value = "e")
private val missingSelected = ResourceId(value = "missing_selected")
private val selected = RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.FORWARD)

/**
 * Through the selected edge relation, a links to b, c and a missing resource, b and c link to d, and d links back to a
 * and on to e. a also links to a missing resource and `unrelated` to e only through the other relation.
 */
private val diamond =
    mapOf(
        a to graphRecord(a, listOf(b, c, missingSelected), badTarget = ResourceId(value = "missing_unrelated")),
        b to graphRecord(b, listOf(d)),
        c to graphRecord(c, listOf(d)),
        d to graphRecord(d, listOf(a, e)),
        e to graphRecord(e, emptyList()),
        ResourceId(value = "unrelated") to graphRecord(ResourceId(value = "unrelated"), emptyList(), badTarget = e),
    )

private val SOURCE = ResourceId(value = "source")
private val TARGET = ResourceId(value = "target")
private val bothRelations = RelationSelection.Contracts(setOf(EDGE.id, BAD.id), TraversalDirection.FORWARD)

/** A source linking to a target through the edge relation, with its link of the other relation left unfilled. */
private val sourceAndTarget = mapOf(SOURCE to graphRecord(SOURCE, listOf(TARGET)), TARGET to graphRecord(TARGET, emptyList()))

val RealmGraphReadsTest by testSuite {
    test("reachability visits the resources linked through the selected relation in breadth first order") {
        graphReads(diamond) {
            reachable(a, selected, maxDepth = 3).resources.map { it.id.toSkir() } shouldBe listOf(a, b, c, d, e)
        }
    }

    test("a selected link to a missing resource is reported and interrupts reachability") {
        graphReads(diamond) {
            val reachable = reachable(a, selected, maxDepth = 3)

            reachable.unresolved.map { it.shouldBeInstanceOf<UnresolvedLink.UnavailableTarget>().target.toSkir() } shouldBe
                listOf(missingSelected)
            reachable.completion shouldBe InspectionCompletion.Interrupted("selected link target unavailable")
        }
    }

    test("reachability depends on the seed's selected incoming links and followed field and not on other relations") {
        graphReads(diamond) {
            reachable(a, selected, maxDepth = 3)

            val dependencies = observations().flatMapTo(linkedSetOf()) { it.dependencies() }
            (InputIdentity.Incoming(a, EDGE.id) in dependencies) shouldBe true
            (InputIdentity.Value(ValueLocation.of(a, ValuePath.root.field("outgoing"))) in dependencies) shouldBe true
            (InputIdentity.Incoming(a, BAD.id) in dependencies) shouldBe false
            (InputIdentity.Incoming(a, null) in dependencies) shouldBe false
        }
    }

    test("reverse reachability reaches the resources that link to the seed") {
        graphReads(diamond) {
            reachable(d, RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.REVERSE), maxDepth = 1)
                .resources
                .mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(b, c, d)
        }
    }

    test("a resource budget below the reachable graph interrupts reachability") {
        graphReads(diamond) {
            val reachable = reachable(a, selected, budget = TraversalBudget(maxResources = 2))

            reachable.resources.map { it.id.toSkir() } shouldBe listOf(a, b)
            reachable.completion shouldBe InspectionCompletion.Interrupted("resource budget exceeded")
        }
    }

    test("routes list every path to the target within the depth limit") {
        graphReads(diamond) {
            route(a, d, maxDepth = 3).resourcePaths() shouldBe listOf(listOf(a, b, d), listOf(a, c, d))
        }
    }

    test("a route budget that admits exactly the routes found completes the search") {
        graphReads(diamond) {
            val routes = route(b, d, maxDepth = 1, budget = TraversalBudget(maxRoutes = 1))

            routes.resourcePaths() shouldBe listOf(listOf(b, d))
            routes.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("a route budget below the routes found interrupts the search with the routes found first") {
        graphReads(diamond) {
            val routes = route(a, d, maxDepth = 3, budget = TraversalBudget(maxRoutes = 1))

            routes.resourcePaths() shouldBe listOf(listOf(a, b, d))
            routes.completion shouldBe InspectionCompletion.Interrupted("route budget exceeded")
        }
    }

    test("a resource budget that admits exactly the resources on the route completes the search") {
        graphReads(diamond) {
            val routes = route(b, d, maxDepth = 1, budget = TraversalBudget(maxResources = 2))

            routes.resourcePaths() shouldBe listOf(listOf(b, d))
            routes.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("a resource budget below the resources on the route interrupts the search without a route") {
        graphReads(diamond) {
            val routes = route(b, d, maxDepth = 1, budget = TraversalBudget(maxResources = 1))

            routes.paths shouldBe emptyList()
            routes.completion shouldBe InspectionCompletion.Interrupted("resource budget exceeded")
        }
    }

    test("graph reads of a staged view follow the staged links instead of the saved ones") {
        val source = ResourceId(value = "source")
        val savedTarget = ResourceId(value = "saved_target")
        val stagedTarget = ResourceId(value = "staged_target")
        val saved =
            mapOf(
                source to graphRecord(source, listOf(savedTarget)),
                savedTarget to graphRecord(savedTarget, emptyList()),
                stagedTarget to graphRecord(stagedTarget, emptyList()),
            )
        graphReads(saved) {
            reachable(source, selected, maxDepth = 1).resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, savedTarget)
        }
        graphReads(saved, staged = mapOf(source to graphRecord(source, listOf(stagedTarget)))) {
            reachable(source, selected, maxDepth = 1).resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, stagedTarget)
            val occurrence = RealmGraphReads.occurrences(LinkInspectionQuery(setOf(source.toResourceId()), selected)).occurrences.single()
            RealmGraphReads
                .follow(occurrence)
                .shouldBeInstanceOf<Availability.Available<DraftBinding>>()
                .value.location.resource shouldBe stagedTarget

            val dependencies = observations().flatMapTo(linkedSetOf()) { it.dependencies() }
            (InputIdentity.Incoming(source, EDGE.id) in dependencies) shouldBe true
            (InputIdentity.Value(ValueLocation.of(source, ValuePath.root.field("outgoing"))) in dependencies) shouldBe true
        }
    }

    test("a resource linking to a target whose type is unavailable stays an undecided incoming candidate") {
        val source = ResourceId(value = "source")
        val target = ResourceId(value = "pending_target")
        val pending =
            graphRecord(target, emptyList())
                .copy(configuration = TypeSelection.createPending(definition = graphDefinition("missing"), arguments = emptyList()))
        graphReads(mapOf(source to graphRecord(source, listOf(target)), target to pending)) {
            val incoming = RealmGraphReads.incomingResources(target, RelationFamilyId(value = "selected"))

            incoming.knownMatches shouldBe emptyList()
            incoming.undecided.map { it.resource.toSkir() } shouldBe listOf(source)
            incoming.completion shouldBe InspectionCompletion.Complete
            (InputIdentity.Form(ValueLocation.of(target)) in observations().flatMapTo(linkedSetOf()) { it.dependencies() }) shouldBe true
        }
    }

    test("an unfilled link of a selected relation is reported while reachability through its sibling completes") {
        graphReads(sourceAndTarget) {
            val reachable = reachable(SOURCE, bothRelations, maxDepth = 1)

            reachable.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(SOURCE, TARGET)
            reachable.unresolved.unfilled() shouldBe listOf(SOURCE to BAD_ENDPOINT, TARGET to BAD_ENDPOINT)
            reachable.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("an unfilled link of a selected relation is reported while the route through its sibling completes") {
        graphReads(sourceAndTarget) {
            val routes =
                RealmGraphReads.routes(
                    RouteQuery(setOf(SOURCE.toResourceId()), TARGET.toResourceId(), bothRelations, maxDepth = 1),
                )

            routes.resourcePaths() shouldBe listOf(listOf(SOURCE, TARGET))
            routes.unresolved.unfilled() shouldBe listOf(SOURCE to BAD_ENDPOINT, TARGET to BAD_ENDPOINT)
            routes.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("link inspection lists the filled occurrence and reports the unfilled one") {
        graphReads(sourceAndTarget) {
            val occurrences = RealmGraphReads.occurrences(LinkInspectionQuery(setOf(SOURCE.toResourceId()), bothRelations))

            occurrences.occurrences.map { it.id.endpoint } shouldBe listOf(EDGE_SOURCE)
            occurrences.unresolved.unfilled() shouldBe listOf(SOURCE to BAD_ENDPOINT)
            occurrences.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("traversal depends on every field of the source that can hold a selected link") {
        graphReads(sourceAndTarget) {
            reachable(SOURCE, bothRelations, maxDepth = 1)

            val dependencies = observations().flatMapTo(linkedSetOf()) { it.dependencies() }
            listOf("bad", "outgoing", "buttons").forEach { field ->
                (InputIdentity.Value(ValueLocation.of(SOURCE, ValuePath.root.field(field))) in dependencies) shouldBe true
            }
            listOf("optional", "message", "nested", "expanding").forEach { field ->
                (InputIdentity.Form(ValueLocation.of(SOURCE, ValuePath.root.field(field))) in dependencies) shouldBe true
            }
        }
    }

    test("unfilled links inside list items and optional records are reported at their paths") {
        val source =
            sourceAndTarget
                .getValue(SOURCE)
                .with(
                    "buttons",
                    DataValue.named(
                        BUTTON_LIST_USE,
                        DataValue.listValue(
                            listOf(
                                ListItem(
                                    id = ItemId(value = "button"),
                                    value = DataValue.named(BUTTON_USE, DataValue.record(mapOf("target" to DataValue.UNFILLED))),
                                ),
                            ),
                        ),
                    ),
                ).with("optional", DataValue.named(OPTIONAL_LINK_HOLDER_USE, DataValue.record(mapOf("target" to DataValue.UNFILLED))))
        graphReads(sourceAndTarget + (SOURCE to source)) {
            reachable(SOURCE, RelationSelection.Contracts(setOf(BAD.id), TraversalDirection.FORWARD), maxDepth = 0)
                .unresolved
                .mapTo(linkedSetOf()) {
                    it
                        .shouldBeInstanceOf<UnresolvedLink.Unfilled>()
                        .occurrence.location.path
                } shouldBe
                setOf(
                    ValuePath.root.field("bad"),
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "buttons"),
                                PathSegment.createItem(id = ItemId(value = "button")),
                                PathSegment.createField(name = "target"),
                            ),
                    ),
                    ValuePath.root.field("optional").field("target"),
                )
        }
    }
}

/** Runs [block] on fresh reads of [resources], or of [staged] edits over them, through the graph catalog. */
private fun <T> graphReads(
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

private fun CapturedAuthoringReads.reachable(
    seed: ResourceId,
    links: RelationSelection,
    maxDepth: Int? = null,
    budget: TraversalBudget = TraversalBudget(),
) = RealmGraphReads.reachable(ReachabilityQuery(setOf(seed.toResourceId()), links, ResourceDrafts, maxDepth, budget))

private fun CapturedAuthoringReads.route(
    seed: ResourceId,
    target: ResourceId,
    maxDepth: Int,
    budget: TraversalBudget = TraversalBudget(),
) = RealmGraphReads.routes(RouteQuery(setOf(seed.toResourceId()), target.toResourceId(), selected, maxDepth, budget))

/** Each route as the resources it passes, from its seed to the target. */
private fun RouteResult.resourcePaths(): List<List<ResourceId>> =
    paths.map { steps ->
        listOf(
            steps
                .first()
                .from.resource
                .toSkir(),
        ) + steps.map { it.to.resource.toSkir() }
    }

/** Each unfilled link as the resource holding it and its endpoint. */
private fun List<UnresolvedLink>.unfilled(): List<Pair<ResourceId, EndpointId>> =
    map {
        it.shouldBeInstanceOf<UnresolvedLink.Unfilled>().occurrence.let { occurrence ->
            occurrence.location.resource to
                occurrence.endpoint
        }
    }
