package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftView
import com.typewritermc.authoring.EditPreparationId
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkInspectionQuery
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.ReachabilityQuery
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.ResourceDrafts
import com.typewritermc.authoring.RouteQuery
import com.typewritermc.authoring.TraversalBudget
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.UnresolvedLink
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite

class RealmGraphReadsTest {
    fun traversalUsesTheSelectedStagedGraphWithBoundedBreadthFirstSearch() {
        val catalog = GraphCatalogLease()
        val a = ResourceId("a")
        val b = ResourceId("b")
        val c = ResourceId("c")
        val d = ResourceId("d")
        val e = ResourceId("e")
        val unrelated = ResourceId("unrelated")
        val original =
            mapOf(
                a to graphRecord(a, listOf(b, c, ResourceId("missing_selected")), badTarget = ResourceId("missing_unrelated")),
                b to graphRecord(b, listOf(d)),
                c to graphRecord(c, listOf(d)),
                d to graphRecord(d, listOf(a, e)),
                e to graphRecord(e, emptyList()),
                unrelated to
                    graphRecord(unrelated, emptyList()).copy(
                        fields =
                            graphRecord(unrelated, emptyList()).fields +
                                (
                                    "bad" to
                                        DataValue.Named(
                                            BAD_LINK_USE,
                                            DataValue.Link(EDGE_SOURCE, LinkTarget(e, null)),
                                        )
                                ),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(original),
            )
        val lease = store.capture()
        val selection = RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.Forward)
        val reads = CapturedAuthoringReads(lease.originalView())

        val reachable =
            with(reads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(a), selection, ResourceDrafts, maxDepth = 3),
                )
            }
        assertEquals(listOf(a, b, c, d, e), reachable.resources.map { it.id })
        assertEquals(
            5,
            reachable.resources
                .map { it.id }
                .distinct()
                .size,
        )
        assertTrue(reachable.failures.isEmpty())
        val unavailable = assertIs<UnresolvedLink.UnavailableTarget>(reachable.unresolved.single())
        assertEquals(ResourceId("missing_selected"), unavailable.target)
        assertIs<InspectionCompletion.Interrupted>(reachable.completion)
        val dependencies = reads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        assertTrue(InputIdentity.Incoming(a, EDGE.id) in dependencies)
        assertTrue(
            InputIdentity.Value(
                ValueLocation(
                    a,
                    ValuePath(
                        listOf(
                            com.typewritermc.authoring.PathSegment
                                .Field("outgoing"),
                        ),
                    ),
                ),
            ) in dependencies,
        )
        assertFalse(InputIdentity.Incoming(a, BAD.id) in dependencies)
        assertFalse(InputIdentity.Incoming(a, null) in dependencies)

        val routes =
            with(reads) {
                RealmGraphReads.routes(RouteQuery(setOf(a), d, selection, maxDepth = 3))
            }
        assertEquals(2, routes.paths.size)
        assertTrue(routes.paths.all { it.size == 2 })

        val exactBudget = CapturedAuthoringReads(lease.originalView())
        val oneRoute =
            with(exactBudget) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(b),
                        d,
                        selection,
                        maxDepth = 1,
                        budget = TraversalBudget(maxRoutes = 1),
                    ),
                )
            }
        assertEquals(1, oneRoute.paths.size)
        assertIs<InspectionCompletion.Complete>(oneRoute.completion)

        val exactResourceBudget = CapturedAuthoringReads(lease.originalView())
        val exactResourceRoute =
            with(exactResourceBudget) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(b),
                        d,
                        selection,
                        maxDepth = 1,
                        budget = TraversalBudget(maxResources = 2),
                    ),
                )
            }
        assertEquals(1, exactResourceRoute.paths.size)
        assertIs<InspectionCompletion.Complete>(exactResourceRoute.completion)

        val truncatedResourceBudget = CapturedAuthoringReads(lease.originalView())
        val truncatedResourceRoute =
            with(truncatedResourceBudget) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(b),
                        d,
                        selection,
                        maxDepth = 1,
                        budget = TraversalBudget(maxResources = 1),
                    ),
                )
            }
        assertTrue(truncatedResourceRoute.paths.isEmpty())
        assertIs<InspectionCompletion.Interrupted>(truncatedResourceRoute.completion)

        val truncatedReads = CapturedAuthoringReads(lease.originalView())
        val truncatedRoutes =
            with(truncatedReads) {
                RealmGraphReads.routes(
                    RouteQuery(
                        setOf(a),
                        d,
                        selection,
                        maxDepth = 3,
                        budget = TraversalBudget(maxRoutes = 1),
                    ),
                )
            }
        assertEquals(1, truncatedRoutes.paths.size)
        assertIs<InspectionCompletion.Interrupted>(truncatedRoutes.completion)

        val reverse = CapturedAuthoringReads(lease.originalView())
        val incoming =
            with(reverse) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(
                        setOf(d),
                        RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.Reverse),
                        ResourceDrafts,
                        maxDepth = 1,
                    ),
                )
            }
        assertEquals(setOf(b, c, d), incoming.resources.mapTo(linkedSetOf()) { it.id })

        val bounded = CapturedAuthoringReads(lease.originalView())
        val interrupted =
            with(bounded) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(
                        setOf(a),
                        selection,
                        ResourceDrafts,
                        budget = TraversalBudget(maxResources = 2),
                    ),
                )
            }
        assertIs<InspectionCompletion.Interrupted>(interrupted.completion)

        val stagedRecord = graphRecord(a, listOf(c))
        val stagedReads = CapturedAuthoringReads(lease.stagedView(mapOf(a to stagedRecord)))
        val staged =
            with(stagedReads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(a), selection, ResourceDrafts, maxDepth = 1),
                )
            }
        assertEquals(setOf(a, c), staged.resources.mapTo(linkedSetOf()) { it.id })
        assertFalse(staged.resources.any { it.id == b })

        lease.close()
        store.close()
    }

    suspend fun editContextGraphReadsUseTheCurrentStagedSnapshot() {
        val catalog = GraphCatalogLease()
        val source = ResourceId("source")
        val originalTarget = ResourceId("original_target")
        val stagedTarget = ResourceId("staged_target")
        val original =
            mapOf(
                source to graphRecord(source, listOf(originalTarget)),
                originalTarget to graphRecord(originalTarget, emptyList()),
                stagedTarget to graphRecord(stagedTarget, emptyList()),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(original),
            )
        val edits = RealmDraftEdits(store, GraphRepository())
        val selection = RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.Forward)
        val outgoing =
            ValueLocation(
                source,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("outgoing"),
                    ),
                ),
            )
        val view =
            object : DraftView {
                override val catalog = GRAPH_GENERATION
                override val readContext = store.capture().use { it.root.readContext }
                override val location = ValueLocation(source, ValuePath())
                override val actualType = Availability.Available(NODE_USE)
            }

        val result =
            with(edits) {
                view.prepareEdit(EditPreparationId("test")) {
                    val originalReachable =
                        RealmGraphReads.reachable(
                            ReachabilityQuery(setOf(source), selection, ResourceDrafts, maxDepth = 1),
                        )
                    assertEquals(setOf(source, originalTarget), originalReachable.resources.mapTo(linkedSetOf()) { it.id })

                    val stagedValue =
                        DataValue.Named(
                            EDGE_LIST_USE,
                            DataValue.ListValue(
                                listOf(
                                    ListItem(
                                        ItemId("staged"),
                                        DataValue.Named(
                                            EDGE_LINK_USE,
                                            DataValue.Link(EDGE_SOURCE, LinkTarget(stagedTarget, null)),
                                        ),
                                    ),
                                ),
                            ),
                        )
                    assertIs<CheckedWriteResult.Applied>(checkedSet(outgoing, stagedValue))

                    val stagedReachable =
                        RealmGraphReads.reachable(
                            ReachabilityQuery(setOf(source), selection, ResourceDrafts, maxDepth = 1),
                        )
                    assertEquals(setOf(source, stagedTarget), stagedReachable.resources.mapTo(linkedSetOf()) { it.id })
                    val occurrence =
                        RealmGraphReads
                            .occurrences(LinkInspectionQuery(setOf(source), selection))
                            .occurrences
                            .single()
                    val followed = assertIs<Availability.Available<DraftBinding>>(RealmGraphReads.follow(occurrence))
                    assertEquals(stagedTarget, followed.value.location.resource)
                }
            }
        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertTrue(prepared.expectations.any { InputIdentity.Incoming(source, EDGE.id) in it.dependencies() })
        assertTrue(prepared.expectations.any { InputIdentity.Value(outgoing) in it.dependencies() })
        store.close()
    }

    fun pendingUnavailableTargetProducesAnUndecidedIncomingCandidate() {
        val catalog = GraphCatalogLease()
        val source = ResourceId("source")
        val target = ResourceId("pending_target")
        val pending = graphRecord(target, emptyList()).copy(configuration = TypeSelection.Pending(graphDefinition("missing"), emptyList()))
        val resources = mapOf(source to graphRecord(source, listOf(target)), target to pending)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources, resources.keys.associateWith { ResourceDefinitionId("node") }),
            )
        val lease = store.capture()
        val reads = CapturedAuthoringReads(lease.originalView())

        val selection =
            with(reads) {
                RealmGraphReads.incomingResources(target, RelationFamilyId("selected"))
            }

        assertTrue(selection.knownMatches.isEmpty())
        assertEquals(listOf(source), selection.undecided.map { it.resource })
        assertIs<InspectionCompletion.Complete>(selection.completion)
        val identities = reads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        assertTrue(InputIdentity.Form(ValueLocation(target, ValuePath())) in identities)
        lease.close()
        store.close()
    }

    fun unfilledLinkKeepsValidSiblingTraversalComplete() {
        val catalog = GraphCatalogLease()
        val source = ResourceId("source")
        val target = ResourceId("target")
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
                TraversalDirection.Forward,
            )

        val reachableReads = CapturedAuthoringReads(lease.originalView())
        val reachable =
            with(reachableReads) {
                RealmGraphReads.reachable(
                    ReachabilityQuery(setOf(source), selection, ResourceDrafts, maxDepth = 1),
                )
            }
        assertEquals(setOf(source, target), reachable.resources.mapTo(linkedSetOf()) { it.id })
        assertEquals(
            BAD_ENDPOINT,
            reachable.unresolved
                .filterIsInstance<UnresolvedLink.Unfilled>()
                .single { it.occurrence.location.resource == source }
                .occurrence.endpoint,
        )
        assertIs<InspectionCompletion.Complete>(reachable.completion)
        val dependencies = reachableReads.observations().flatMapTo(linkedSetOf()) { it.dependencies() }
        assertTrue(
            InputIdentity.Value(
                ValueLocation(
                    source,
                    ValuePath(
                        listOf(
                            com.typewritermc.authoring.PathSegment
                                .Field("bad"),
                        ),
                    ),
                ),
            ) in dependencies,
        )
        assertTrue(
            InputIdentity.Value(
                ValueLocation(
                    source,
                    ValuePath(
                        listOf(
                            com.typewritermc.authoring.PathSegment
                                .Field("outgoing"),
                        ),
                    ),
                ),
            ) in dependencies,
        )
        assertTrue(
            InputIdentity.Value(
                ValueLocation(
                    source,
                    ValuePath(
                        listOf(
                            com.typewritermc.authoring.PathSegment
                                .Field("buttons"),
                        ),
                    ),
                ),
            ) in dependencies,
        )
        assertTrue(
            InputIdentity.Form(
                ValueLocation(
                    source,
                    ValuePath(
                        listOf(
                            com.typewritermc.authoring.PathSegment
                                .Field("optional"),
                        ),
                    ),
                ),
            ) in dependencies,
        )
        listOf("message", "nested", "expanding").forEach { field ->
            assertTrue(
                InputIdentity.Form(
                    ValueLocation(
                        source,
                        ValuePath(
                            listOf(
                                com.typewritermc.authoring.PathSegment
                                    .Field(field),
                            ),
                        ),
                    ),
                ) in dependencies,
            )
        }

        val routes =
            with(CapturedAuthoringReads(lease.originalView())) {
                RealmGraphReads.routes(RouteQuery(setOf(source), target, selection, maxDepth = 1))
            }
        assertEquals(1, routes.paths.size)
        assertEquals(
            BAD_ENDPOINT,
            routes.unresolved
                .filterIsInstance<UnresolvedLink.Unfilled>()
                .single { it.occurrence.location.resource == source }
                .occurrence.endpoint,
        )
        assertIs<InspectionCompletion.Complete>(routes.completion)

        val occurrences =
            with(CapturedAuthoringReads(lease.originalView())) {
                RealmGraphReads.occurrences(LinkInspectionQuery(setOf(source), selection))
            }
        assertEquals(1, occurrences.occurrences.size)
        assertEquals(
            EDGE_SOURCE,
            occurrences.occurrences
                .single()
                .id.endpoint,
        )
        assertIs<UnresolvedLink.Unfilled>(occurrences.unresolved.single())
        assertIs<InspectionCompletion.Complete>(occurrences.completion)

        val changedSource =
            resources.getValue(source).copy(
                fields =
                    resources.getValue(source).fields +
                        (
                            "buttons" to
                                DataValue.Named(
                                    BUTTON_LIST_USE,
                                    DataValue.ListValue(
                                        listOf(
                                            ListItem(
                                                ItemId("button"),
                                                DataValue.Named(
                                                    BUTTON_USE,
                                                    DataValue.Record(mapOf("target" to DataValue.Unfilled)),
                                                ),
                                            ),
                                        ),
                                    ),
                                )
                        ) +
                        (
                            "optional" to
                                DataValue.Named(
                                    OPTIONAL_LINK_HOLDER_USE,
                                    DataValue.Record(mapOf("target" to DataValue.Unfilled)),
                                )
                        ),
            )
        val buttons =
            ValueLocation(
                source,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("buttons"),
                    ),
                ),
            )
        val optional =
            ValueLocation(
                source,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("optional"),
                    ),
                ),
            )
        val button =
            ValueLocation(
                source,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("buttons"),
                        com.typewritermc.authoring.PathSegment
                            .Item(ItemId("button")),
                    ),
                ),
            )
        val buttonTarget =
            ValueLocation(
                source,
                ValuePath(
                    button.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Field("target"),
                ),
            )
        val optionalTarget =
            ValueLocation(
                source,
                ValuePath(
                    optional.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Field("target"),
                ),
            )
        val expected =
            com.typewritermc.authoring.EditExpectation
                .Value(buttons, resources.getValue(source).valueAt(buttons.path))
        val actual =
            com.typewritermc.realm.repository
                .CapturedAuthoringValues(mapOf(source to changedSource), emptyList())
        assertEquals(1, actual.conflicts(listOf(expected)).size)
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
                            setOf(source),
                            RelationSelection.Contracts(setOf(BAD.id), TraversalDirection.Forward),
                            ResourceDrafts,
                            maxDepth = 0,
                        ),
                    ).unresolved
                    .filterIsInstance<UnresolvedLink.Unfilled>()
            }
        assertEquals(
            setOf(
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("bad"),
                    ),
                ),
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("buttons"),
                        com.typewritermc.authoring.PathSegment
                            .Item(ItemId("button")),
                        com.typewritermc.authoring.PathSegment
                            .Field("target"),
                    ),
                ),
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("optional"),
                        com.typewritermc.authoring.PathSegment
                            .Field("target"),
                    ),
                ),
            ),
            changedUnresolved.mapTo(linkedSetOf()) { it.occurrence.location.path },
        )
        changedLease.close()

        lease.close()
        store.close()
    }
}

private class GraphRepository : AuthoringRepository {
    override suspend fun commit(edit: PreparedEdit): CommitResult = CommitResult.Committed
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
    override val resources: List<AuthoringResourceDefinition> =
        listOf(AuthoringResourceDefinition(ResourceDefinitionId("node"), NODE))

    override fun retain(): AuthoringCatalogLease = GraphCatalogLease(generation)

    override fun close() = Unit
}

private fun graphRecord(
    source: ResourceId,
    targets: List<ResourceId>,
    badTarget: ResourceId? = null,
): AuthoringRecord =
    AuthoringRecord(
        TypeSelection.Complete(NODE_USE),
        mapOf(
            "outgoing" to
                DataValue.Named(
                    EDGE_LIST_USE,
                    DataValue.ListValue(
                        targets.mapIndexed { index, target ->
                            ListItem(
                                ItemId("${source.value}_$index"),
                                DataValue.Named(EDGE_LINK_USE, DataValue.Link(EDGE_SOURCE, LinkTarget(target, null))),
                            )
                        },
                    ),
                ),
            "bad" to
                if (badTarget == null) {
                    DataValue.Unfilled
                } else {
                    DataValue.Named(BAD_LINK_USE, DataValue.Link(BAD_ENDPOINT, LinkTarget(badTarget, null)))
                },
            "buttons" to DataValue.Named(BUTTON_LIST_USE, DataValue.ListValue(emptyList())),
            "optional" to DataValue.Null,
            "message" to DataValue.Unfilled,
            "nested" to DataValue.Unfilled,
            "expanding" to DataValue.Unfilled,
        ),
    )

private fun graphDefinition(name: String) = TypeDefinitionId(TypeId.Qualified("graph", name), 1)

private val GRAPH_GENERATION = CatalogGeneration("graph_catalog")
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
private val BOX_PARAMETER = ParameterKey(BOX, 0)
private val EXPANDING_PARAMETER = ParameterKey(EXPANDING, 0)
private val WRAPPER_PARAMETER = ParameterKey(WRAPPER, 0)
private val NODE_USE = TypeUse.Named(NODE)
private val EDGE_LINK_USE = TypeUse.Named(EDGE_LINK)
private val EDGE_LIST_USE = TypeUse.Named(EDGE_LIST)
private val BAD_LINK_USE = TypeUse.Named(BAD_LINK)
private val BUTTON_LIST_USE = TypeUse.Named(BUTTON_LIST)
private val BUTTON_USE = TypeUse.Named(BUTTON)
private val OPTIONAL_LINK_HOLDER_USE = TypeUse.Named(OPTIONAL_LINK_HOLDER)
private val EDGE_SOURCE = EndpointId("edge:source")
private val EDGE_TARGET = EndpointId("edge:target")
private val BAD_ENDPOINT = EndpointId("bad:source")
private val BAD_TARGET = EndpointId("bad:target")
private val EDGE =
    RelationContract(
        RelationId("edge"),
        EndpointDefinition(
            EDGE_SOURCE,
            EndpointSlot.First,
            TypeTemplate.Named(NODE),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            EDGE_TARGET,
            EndpointSlot.Second,
            TypeTemplate.Named(NODE),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
        families = setOf(RelationFamilyId("selected")),
    )
private val BAD =
    RelationContract(
        RelationId("bad"),
        EndpointDefinition(
            BAD_ENDPOINT,
            EndpointSlot.First,
            TypeTemplate.Named(NODE),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            BAD_TARGET,
            EndpointSlot.Second,
            TypeTemplate.Named(NODE),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
    )
private val EDGE_BINDING =
    EndpointBindingTemplate(
        EDGE_SOURCE,
        TypeTemplate.Named(NODE),
        NODE,
        RelativeFieldPattern(listOf(FieldPatternSegment.Field("outgoing"), FieldPatternSegment.Items)),
        TypeTemplate.Named(NODE),
        containsCollection = true,
    )
private val BAD_BINDING =
    EndpointBindingTemplate(
        BAD_ENDPOINT,
        TypeTemplate.Named(NODE),
        NODE,
        RelativeFieldPattern(listOf(FieldPatternSegment.Field("bad"))),
        TypeTemplate.Named(NODE),
        containsCollection = false,
    )
private val GRAPH_DEFINITIONS =
    listOf(
        TypeDefinition(
            NODE,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(FieldOwner(NODE, "outgoing"), TypeTemplate.Named(EDGE_LIST)),
                        FieldDeclaration(FieldOwner(NODE, "bad"), TypeTemplate.Named(BAD_LINK)),
                        FieldDeclaration(FieldOwner(NODE, "buttons"), TypeTemplate.Named(BUTTON_LIST)),
                        FieldDeclaration(
                            FieldOwner(NODE, "optional"),
                            TypeTemplate.Nullable(TypeTemplate.Named(OPTIONAL_LINK_HOLDER)),
                        ),
                        FieldDeclaration(FieldOwner(NODE, "message"), TypeTemplate.Named(ABSTRACT_MESSAGE)),
                        FieldDeclaration(
                            FieldOwner(NODE, "nested"),
                            TypeTemplate.Named(
                                BOX,
                                listOf(TypeTemplate.Named(BOX, listOf(TypeTemplate.Named(BAD_LINK)))),
                            ),
                        ),
                        FieldDeclaration(
                            FieldOwner(NODE, "expanding"),
                            TypeTemplate.Named(EXPANDING, listOf(TypeTemplate.Scalar(ScalarKind.Text))),
                        ),
                    ),
                ),
        ),
        TypeDefinition(
            EDGE_LINK,
            representation = RepresentationTemplate.Link(EDGE_SOURCE, TypeTemplate.Named(NODE)),
        ),
        TypeDefinition(
            EDGE_LIST,
            representation = RepresentationTemplate.Sequence(TypeTemplate.Named(EDGE_LINK), CollectionKind.List),
        ),
        TypeDefinition(
            BAD_LINK,
            representation = RepresentationTemplate.Link(BAD_ENDPOINT, TypeTemplate.Named(NODE)),
        ),
        TypeDefinition(
            BUTTON,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(BUTTON, "target"), TypeTemplate.Named(BAD_LINK))),
                ),
        ),
        TypeDefinition(
            BUTTON_LIST,
            representation = RepresentationTemplate.Sequence(TypeTemplate.Named(BUTTON), CollectionKind.List),
        ),
        TypeDefinition(
            OPTIONAL_LINK_HOLDER,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(OPTIONAL_LINK_HOLDER, "target"), TypeTemplate.Named(BAD_LINK))),
                ),
        ),
        TypeDefinition(
            ABSTRACT_MESSAGE,
            representation = RepresentationTemplate.Record(emptyList(), abstract = true),
        ),
        TypeDefinition(
            LINK_MESSAGE,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(LINK_MESSAGE, "target"), TypeTemplate.Named(BAD_LINK))),
                ),
            parents = listOf(TypeTemplate.Named(ABSTRACT_MESSAGE)),
        ),
        TypeDefinition(
            BOX,
            parameters = listOf(TypeParameter(BOX_PARAMETER, "T")),
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(BOX, "value"), TypeTemplate.Parameter(BOX_PARAMETER))),
                ),
        ),
        TypeDefinition(
            WRAPPER,
            parameters = listOf(TypeParameter(WRAPPER_PARAMETER, "T")),
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(WRAPPER, "value"), TypeTemplate.Parameter(WRAPPER_PARAMETER))),
                ),
        ),
        TypeDefinition(
            EXPANDING,
            parameters = listOf(TypeParameter(EXPANDING_PARAMETER, "T")),
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(
                            FieldOwner(EXPANDING, "next"),
                            TypeTemplate.Named(
                                EXPANDING,
                                listOf(
                                    TypeTemplate.Named(
                                        WRAPPER,
                                        listOf(TypeTemplate.Parameter(EXPANDING_PARAMETER)),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
        ),
    )

val RealmGraphReadsTestSuite by testSuite {
    test("traversalUsesTheSelectedStagedGraphWithBoundedBreadthFirstSearch") {
        RealmGraphReadsTest().traversalUsesTheSelectedStagedGraphWithBoundedBreadthFirstSearch()
    }
    test("editContextGraphReadsUseTheCurrentStagedSnapshot") {
        RealmGraphReadsTest().editContextGraphReadsUseTheCurrentStagedSnapshot()
    }
    test("pendingUnavailableTargetProducesAnUndecidedIncomingCandidate") {
        RealmGraphReadsTest().pendingUnavailableTargetProducesAnUndecidedIncomingCandidate()
    }
    test("unfilledLinkKeepsValidSiblingTraversalComplete") {
        RealmGraphReadsTest().unfilledLinkKeepsValidSiblingTraversalComplete()
    }
}
