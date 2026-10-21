package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.LinkInspectionQuery
import com.typewritermc.authoring.ReachabilityQuery
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDrafts
import com.typewritermc.authoring.RouteQuery
import com.typewritermc.authoring.TraversalBudget
import com.typewritermc.authoring.UnresolvedLink
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.configuration.field
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.endpoint
import com.typewritermc.types.fields
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
import skirout.editor.v1.catalog.EndpointBindingTemplate
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
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

class RealmGraphReadsTest {
    fun traversalUsesTheSelectedStagedGraphWithBoundedBreadthFirstSearch() {
        val catalog = GraphCatalogLease()
        val a = ResourceId(value = "a")
        val b = ResourceId(value = "b")
        val c = ResourceId(value = "c")
        val d = ResourceId(value = "d")
        val e = ResourceId(value = "e")
        val unrelated = ResourceId(value = "unrelated")
        val original =
            mapOf(
                a to
                    graphRecord(
                        a,
                        listOf(b, c, ResourceId(value = "missing_selected")),
                        badTarget = ResourceId(value = "missing_unrelated"),
                    ),
                b to graphRecord(b, listOf(d)),
                c to graphRecord(c, listOf(d)),
                d to graphRecord(d, listOf(a, e)),
                e to graphRecord(e, emptyList()),
                unrelated to
                    graphRecord(unrelated, emptyList()).with(
                        "bad",
                        DataValue.named(
                            BAD_LINK_USE,
                            DataValue.createLink(
                                endpoint = EDGE_SOURCE,
                                target = LinkTarget(resource = e, opposite = null),
                            ),
                        ),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(original),
            )
        val lease = store.capture()
        val selection = RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.FORWARD)
        val reads = CapturedAuthoringReads(lease.originalView())

        val reachable =
            with(reads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(a.toResourceId()), selection, ResourceDrafts, maxDepth = 3),
                )
            }
        reachable.resources.map { it.id.toSkir() } shouldBe listOf(a, b, c, d, e)
        reachable.resources
            .map { it.id.toSkir() }
            .distinct()
            .size shouldBe 5
        reachable.failures.isEmpty() shouldBe true
        val unavailable = reachable.unresolved.single().shouldBeInstanceOf<UnresolvedLink.UnavailableTarget>()
        unavailable.target.toSkir() shouldBe ResourceId(value = "missing_selected")
        reachable.completion.shouldBeInstanceOf<InspectionCompletion.Interrupted>()
        val dependencies = reads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        (InputIdentity.Incoming(a, EDGE.id) in dependencies) shouldBe true
        (
            InputIdentity.Value(
                ValueLocation.of(
                    a,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "outgoing"),
                            ),
                    ),
                ),
            ) in dependencies
        ) shouldBe true
        (InputIdentity.Incoming(a, BAD.id) in dependencies) shouldBe false
        (InputIdentity.Incoming(a, null) in dependencies) shouldBe false

        val routes =
            with(reads) {
                RealmGraphReads.routes(RouteQuery(setOf(a.toResourceId()), d.toResourceId(), selection, maxDepth = 3))
            }
        routes.paths.size shouldBe 2
        routes.paths.all { it.size == 2 } shouldBe true

        val exactBudget = CapturedAuthoringReads(lease.originalView())
        val oneRoute =
            with(exactBudget) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(b.toResourceId()),
                        d.toResourceId(),
                        selection,
                        maxDepth = 1,
                        budget = TraversalBudget(maxRoutes = 1),
                    ),
                )
            }
        oneRoute.paths.size shouldBe 1
        oneRoute.completion.shouldBeInstanceOf<InspectionCompletion.Complete>()

        val exactResourceBudget = CapturedAuthoringReads(lease.originalView())
        val exactResourceRoute =
            with(exactResourceBudget) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(b.toResourceId()),
                        d.toResourceId(),
                        selection,
                        maxDepth = 1,
                        budget = TraversalBudget(maxResources = 2),
                    ),
                )
            }
        exactResourceRoute.paths.size shouldBe 1
        exactResourceRoute.completion.shouldBeInstanceOf<InspectionCompletion.Complete>()

        val truncatedResourceBudget = CapturedAuthoringReads(lease.originalView())
        val truncatedResourceRoute =
            with(truncatedResourceBudget) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(b.toResourceId()),
                        d.toResourceId(),
                        selection,
                        maxDepth = 1,
                        budget = TraversalBudget(maxResources = 1),
                    ),
                )
            }
        truncatedResourceRoute.paths.isEmpty() shouldBe true
        truncatedResourceRoute.completion.shouldBeInstanceOf<InspectionCompletion.Interrupted>()

        val truncatedReads = CapturedAuthoringReads(lease.originalView())
        val truncatedRoutes =
            with(truncatedReads) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(a.toResourceId()),
                        d.toResourceId(),
                        selection,
                        maxDepth = 3,
                        budget = TraversalBudget(maxRoutes = 1),
                    ),
                )
            }
        truncatedRoutes.paths.size shouldBe 1
        truncatedRoutes.completion.shouldBeInstanceOf<InspectionCompletion.Interrupted>()

        val reverse = CapturedAuthoringReads(lease.originalView())
        val incoming =
            with(reverse) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(
                        setOf(d.toResourceId()),
                        RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.REVERSE),
                        ResourceDrafts,
                        maxDepth = 1,
                    ),
                )
            }
        incoming.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(b, c, d)

        val bounded = CapturedAuthoringReads(lease.originalView())
        val interrupted =
            with(bounded) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(
                        setOf(a.toResourceId()),
                        selection,
                        ResourceDrafts,
                        budget = TraversalBudget(maxResources = 2),
                    ),
                )
            }
        interrupted.completion.shouldBeInstanceOf<InspectionCompletion.Interrupted>()

        val stagedRecord = graphRecord(a, listOf(c))
        val stagedReads = CapturedAuthoringReads(lease.stagedView(mapOf(a to stagedRecord)))
        val staged =
            with(stagedReads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(a.toResourceId()), selection, ResourceDrafts, maxDepth = 1),
                )
            }
        staged.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(a, c)
        staged.resources.any { it.id == b.toResourceId() } shouldBe false

        lease.close()
        store.close()
    }

    fun graphReadsUseTheCurrentStagedSnapshot() {
        val source = ResourceId(value = "source")
        val originalTarget = ResourceId(value = "original_target")
        val stagedTarget = ResourceId(value = "staged_target")
        val store =
            InMemoryAuthoringViewStore(
                GraphCatalogLease(),
                AuthoringSeed(
                    mapOf(
                        source to graphRecord(source, listOf(originalTarget)),
                        originalTarget to graphRecord(originalTarget, emptyList()),
                        stagedTarget to graphRecord(stagedTarget, emptyList()),
                    ),
                ),
            )
        val lease = store.capture()
        val selection = RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.FORWARD)
        val originalReads = CapturedAuthoringReads(lease.originalView())
        val originalReachable =
            with(originalReads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(source.toResourceId()), selection, ResourceDrafts, maxDepth = 1),
                )
            }
        originalReachable.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, originalTarget)

        val stagedReads =
            CapturedAuthoringReads(
                lease.stagedView(mapOf(source to graphRecord(source, listOf(stagedTarget)))),
            )
        with(stagedReads) {
            val stagedReachable =
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(source.toResourceId()), selection, ResourceDrafts, maxDepth = 1),
                )
            stagedReachable.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, stagedTarget)
            val occurrence = RealmGraphReads.occurrences(LinkInspectionQuery(setOf(source.toResourceId()), selection)).occurrences.single()
            val followed = RealmGraphReads.follow(occurrence).shouldBeInstanceOf<Availability.Available<DraftBinding>>()
            followed.value.location.resource shouldBe stagedTarget
        }
        val outgoing =
            ValueLocation.of(
                source,
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "outgoing"),
                        ),
                ),
            )
        val dependencies = stagedReads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        (InputIdentity.Incoming(source, EDGE.id) in dependencies) shouldBe true
        (InputIdentity.Value(outgoing) in dependencies) shouldBe true
        lease.close()
        store.close()
    }

    fun pendingUnavailableTargetProducesAnUndecidedIncomingCandidate() {
        val catalog = GraphCatalogLease()
        val source = ResourceId(value = "source")
        val target = ResourceId(value = "pending_target")
        val pending =
            graphRecord(
                target,
                emptyList(),
            ).copy(configuration = TypeSelection.createPending(definition = graphDefinition("missing"), arguments = emptyList()))
        val resources = mapOf(source to graphRecord(source, listOf(target)), target to pending)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val selection =
            with(reads) {
                RealmGraphReads.incomingResources(target, RelationFamilyId(value = "selected"))
            }

        selection.knownMatches.isEmpty() shouldBe true
        selection.undecided.map { it.resource.toSkir() } shouldBe listOf(source)
        selection.completion.shouldBeInstanceOf<InspectionCompletion.Complete>()
        val identities = reads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        (InputIdentity.Form(ValueLocation.of(target)) in identities) shouldBe true
        lease.close()
        store.close()
    }

    fun unfilledLinkKeepsValidSiblingTraversalComplete() {
        val catalog = GraphCatalogLease()
        val source = ResourceId(value = "source")
        val target = ResourceId(value = "target")
        val resources =
            mapOf(
                source to graphRecord(source, listOf(target)),
                target to graphRecord(target, emptyList()),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val lease = store.capture()
        val selection =
            RelationSelection.Contracts(
                setOf(EDGE.id, BAD.id),
                TraversalDirection.FORWARD,
            )

        val reachableReads = CapturedAuthoringReads(lease.originalView())
        val reachable =
            with(reachableReads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(source.toResourceId()), selection, ResourceDrafts, maxDepth = 1),
                )
            }
        reachable.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, target)
        reachable.unresolved
            .filterIsInstance<UnresolvedLink.Unfilled>()
            .single {
                it.occurrence.location.resource == source
            }.occurrence.endpoint shouldBe BAD_ENDPOINT
        reachable.completion.shouldBeInstanceOf<InspectionCompletion.Complete>()
        val dependencies = reachableReads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        (
            InputIdentity.Value(
                ValueLocation.of(
                    source,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "bad"),
                            ),
                    ),
                ),
            ) in dependencies
        ) shouldBe true
        (
            InputIdentity.Value(
                ValueLocation.of(
                    source,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "outgoing"),
                            ),
                    ),
                ),
            ) in dependencies
        ) shouldBe true
        (
            InputIdentity.Value(
                ValueLocation.of(
                    source,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "buttons"),
                            ),
                    ),
                ),
            ) in dependencies
        ) shouldBe true
        (
            InputIdentity.Form(
                ValueLocation.of(
                    source,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "optional"),
                            ),
                    ),
                ),
            ) in dependencies
        ) shouldBe true
        listOf("message", "nested", "expanding").forEach { field ->
            (
                InputIdentity.Form(
                    ValueLocation.of(
                        source,
                        ValuePath(
                            segments =
                                listOf(
                                    PathSegment.createField(name = field),
                                ),
                        ),
                    ),
                ) in dependencies
            ) shouldBe true
        }

        val routes =
            with(CapturedAuthoringReads(lease.originalView())) {
                RealmGraphReads.routes(RouteQuery(setOf(source.toResourceId()), target.toResourceId(), selection, maxDepth = 1))
            }
        routes.paths.size shouldBe 1
        routes.unresolved
            .filterIsInstance<UnresolvedLink.Unfilled>()
            .single {
                it.occurrence.location.resource == source
            }.occurrence.endpoint shouldBe BAD_ENDPOINT
        routes.completion.shouldBeInstanceOf<InspectionCompletion.Complete>()

        val occurrences =
            with(CapturedAuthoringReads(lease.originalView())) {
                RealmGraphReads.occurrences(LinkInspectionQuery(setOf(source.toResourceId()), selection))
            }
        occurrences.occurrences.size shouldBe 1
        occurrences.occurrences
            .single()
            .id.endpoint shouldBe EDGE_SOURCE
        occurrences.unresolved.single().shouldBeInstanceOf<UnresolvedLink.Unfilled>()
        occurrences.completion.shouldBeInstanceOf<InspectionCompletion.Complete>()

        val changedSource =
            resources
                .getValue(source)
                .with(
                    "buttons",
                    DataValue.named(
                        BUTTON_LIST_USE,
                        DataValue.listValue(
                            listOf(
                                ListItem(
                                    id = ItemId(value = "button"),
                                    value =
                                        DataValue.named(
                                            BUTTON_USE,
                                            DataValue.record(mapOf("target" to DataValue.UNFILLED)),
                                        ),
                                ),
                            ),
                        ),
                    ),
                ).with(
                    "optional",
                    DataValue.named(
                        OPTIONAL_LINK_HOLDER_USE,
                        DataValue.record(mapOf("target" to DataValue.UNFILLED)),
                    ),
                )
        val buttons =
            ValueLocation.of(
                source,
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "buttons"),
                        ),
                ),
            )
        val optional =
            ValueLocation.of(
                source,
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "optional"),
                        ),
                ),
            )
        val button =
            ValueLocation.of(
                source,
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "buttons"),
                            PathSegment.createItem(id = ItemId(value = "button")),
                        ),
                ),
            )
        val buttonTarget =
            ValueLocation.of(
                source,
                ValuePath(
                    segments =
                        button.path.segments +
                            PathSegment.createField(name = "target"),
                ),
            )
        val optionalTarget =
            ValueLocation.of(
                source,
                ValuePath(
                    segments =
                        optional.path.segments +
                            PathSegment.createField(name = "target"),
                ),
            )
        val expected =
            skirout.editor.v1.authoring_facts.EditExpectation
                .createValue(at = buttons, expected = resources.getValue(source).valueAt(buttons.path))
        val actual =
            com.typewritermc.realm.repository
                .CapturedAuthoringValues(mapOf(source to changedSource), emptyList())
        actual.conflicts(listOf(expected)).size shouldBe 1
        store.install(
            store.prepare(
                AuthoringViewDelta(upsertedResources = mapOf(source to changedSource)),
            ),
        )
        val changedLease = store.capture()
        val changedUnresolved =
            with(CapturedAuthoringReads(changedLease.originalView())) {
                RealmGraphReads
                    .reachable(
                        ReachabilityQuery(
                            setOf(source.toResourceId()),
                            RelationSelection.Contracts(setOf(BAD.id), TraversalDirection.FORWARD),
                            ResourceDrafts,
                            maxDepth = 0,
                        ),
                    ).unresolved
                    .filterIsInstance<UnresolvedLink.Unfilled>()
            }
        changedUnresolved.mapTo(linkedSetOf()) { it.occurrence.location.path } shouldBe
            setOf(
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "bad"),
                        ),
                ),
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "buttons"),
                            PathSegment.createItem(id = ItemId(value = "button")),
                            PathSegment.createField(name = "target"),
                        ),
                ),
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "optional"),
                            PathSegment.createField(name = "target"),
                        ),
                ),
            )
        changedLease.close()

        lease.close()
        store.close()
    }
}

private class GraphCatalogLease(
    override val generation: CatalogGeneration = GRAPH_GENERATION,
) : AuthoringCatalogLease {
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, GRAPH_DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers: OwnedProviderRegistry = EmptyProviders
    override val checks: List<OwnedCheckRecipe> = emptyList()
    override val relations: List<RelationContract> = listOf(EDGE, BAD)
    override val endpointBindings: List<EndpointBindingTemplate> = listOf(EDGE_BINDING, BAD_BINDING)

    override val configuration: List<skirout.editor.v1.catalog.ConfigurationRecipe> = emptyList()
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, ValuePath>()

    override fun retain(): AuthoringCatalogLease = GraphCatalogLease(generation)

    override fun close() = Unit
}

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

private val GRAPH_GENERATION = CatalogGeneration(value = "graph_catalog")
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
private val EDGE_BINDING =
    EndpointBindingTemplate(
        endpoint = EDGE_SOURCE,
        containingResource = NODE.namedTemplate(),
        valueOwner = NODE,
        relativePath = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("outgoing"), FieldPatternSegment.ITEMS)),
        target = NODE.template(),
        containsCollection = true,
    )
private val BAD_BINDING =
    EndpointBindingTemplate(
        endpoint = BAD_ENDPOINT,
        containingResource = NODE.namedTemplate(),
        valueOwner = NODE,
        relativePath = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("bad"))),
        target = NODE.template(),
        containsCollection = false,
    )
private val GRAPH_DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = NODE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = NODE, name = "outgoing"), type = EDGE_LIST.template()),
                            FieldDeclaration.partial(owner = FieldOwner(definition = NODE, name = "bad"), type = BAD_LINK.template()),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NODE, name = "buttons"),
                                type = BUTTON_LIST.template(),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NODE, name = "optional"),
                                type = OPTIONAL_LINK_HOLDER.template().nullable(),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NODE, name = "message"),
                                type = ABSTRACT_MESSAGE.template(),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NODE, name = "nested"),
                                type = BOX.template(listOf(BOX.template(listOf(BAD_LINK.template())))),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NODE, name = "expanding"),
                                type = EXPANDING.template(listOf(ScalarKind.TEXT.template)),
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = EDGE_LINK,
            representation = RepresentationTemplate.createLink(endpoint = EDGE_SOURCE, target = NODE.template()),
        ),
        TypeDefinition.partial(
            id = EDGE_LIST,
            representation = RepresentationTemplate.createSequence(item = EDGE_LINK.template(), kind = CollectionKind.LIST),
        ),
        TypeDefinition.partial(
            id = BAD_LINK,
            representation = RepresentationTemplate.createLink(endpoint = BAD_ENDPOINT, target = NODE.template()),
        ),
        TypeDefinition.partial(
            id = BUTTON,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = BUTTON, name = "target"), type = BAD_LINK.template()),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = BUTTON_LIST,
            representation = RepresentationTemplate.createSequence(item = BUTTON.template(), kind = CollectionKind.LIST),
        ),
        TypeDefinition.partial(
            id = OPTIONAL_LINK_HOLDER,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = OPTIONAL_LINK_HOLDER, name = "target"),
                                type = BAD_LINK.template(),
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = ABSTRACT_MESSAGE,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
        ),
        TypeDefinition.partial(
            id = LINK_MESSAGE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = LINK_MESSAGE, name = "target"),
                                type = BAD_LINK.template(),
                            ),
                        ),
                    abstract_ = false,
                ),
            parents = listOf(ABSTRACT_MESSAGE.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = BOX,
            parameters = listOf(TypeParameter.partial(key = BOX_PARAMETER, name = "T")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = BOX, name = "value"), type = BOX_PARAMETER.template),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = WRAPPER,
            parameters = listOf(TypeParameter.partial(key = WRAPPER_PARAMETER, name = "T")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = WRAPPER, name = "value"),
                                type = WRAPPER_PARAMETER.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = EXPANDING,
            parameters = listOf(TypeParameter.partial(key = EXPANDING_PARAMETER, name = "T")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = EXPANDING, name = "next"),
                                type =
                                    EXPANDING.template(
                                        listOf(
                                            WRAPPER.template(listOf(EXPANDING_PARAMETER.template)),
                                        ),
                                    ),
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
    )

val RealmGraphReadsTestSuite by testSuite {
    test("traversalUsesTheSelectedStagedGraphWithBoundedBreadthFirstSearch") {
        RealmGraphReadsTest().traversalUsesTheSelectedStagedGraphWithBoundedBreadthFirstSearch()
    }
    test("graphReadsUseTheCurrentStagedSnapshot") {
        RealmGraphReadsTest().graphReadsUseTheCurrentStagedSnapshot()
    }
    test("pendingUnavailableTargetProducesAnUndecidedIncomingCandidate") {
        RealmGraphReadsTest().pendingUnavailableTargetProducesAnUndecidedIncomingCandidate()
    }
    test("unfilledLinkKeepsValidSiblingTraversalComplete") {
        RealmGraphReadsTest().unfilledLinkKeepsValidSiblingTraversalComplete()
    }
}
