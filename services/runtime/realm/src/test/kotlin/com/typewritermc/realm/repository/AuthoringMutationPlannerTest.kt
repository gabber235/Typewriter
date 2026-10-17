package com.typewritermc.realm.repository

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.OperationLayoutPreparation
import com.typewritermc.realm.authoring.RuntimeOperationPreparation
import com.typewritermc.realm.authoring.SnapshotEditContext
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
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
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.coroutines.runBlocking

class AuthoringMutationPlannerTest {
    fun inverseOnlyReferencesDoNotOfferLinkedDuplication() {
        val id = ResourceId("inverse_only")
        val definitions =
            DEFINITIONS.map { definition ->
                if (definition.id ==
                    NODE
                ) {
                    definition.copy(
                        representation =
                            (definition.representation as RepresentationTemplate.Record).let {
                                it.copy(
                                    fields =
                                        it.fields.filterNot { field ->
                                            field.owner.name ==
                                                "manyFirst"
                                        },
                                )
                            },
                    )
                } else {
                    definition
                }
            }
        val catalog =
            com.typewritermc.realm.checking.TestCatalogLease(
                generation = GENERATION,
                definitions = definitions,
                resourceRoot = NODE,
                relations = listOf(manyContract()),
                endpointBindings = BINDINGS,
            )
        val resources = mapOf(id to record().let { it.copy(fields = it.fields - "manyFirst") })
        val baseline = AuthoringView(catalog, resources, mapOf(id to com.typewritermc.authoring.ResourceDefinitionId("test")), emptyMap())
        try {
            val reads =
                com.typewritermc.realm.checking.CapturedAuthoringReads(
                    com.typewritermc.realm.authoring.AuthoredReadView
                        .Original(baseline),
                )
            val result =
                com.typewritermc.realm.authoring
                    .BuiltinOperationAvailability(
                        baseline,
                        reads,
                    ).availability(com.typewritermc.operations.BuiltinResourceOperation.LinkWithDuplicate, listOf(id))
            assertEquals(com.typewritermc.operations.OperationAvailability.Hidden, result)
        } finally {
            catalog.close()
        }
    }

    fun placementPoliciesMatchExactOwnershipCollections() =
        runBlocking {
            val owner = ResourceId("layout-owner")
            val first = ResourceId("layout-first")
            val second = ResourceId("layout-second")
            val firstItem = ItemId("layout-first-item")
            val secondItem = ItemId("layout-second-item")
            val inverseItem = ItemId("layout-inverse-item")
            val resources =
                mapOf(
                    owner to
                        record(
                            children = listOf(ListItem(firstItem, link(PARENT_FIRST_TYPE, PARENT_FIRST, first, fieldPath("parent")))),
                            manyFirst =
                                listOf(
                                    ListItem(
                                        secondItem,
                                        link(MANY_FIRST_TYPE, MANY_FIRST, second, fieldPath("manySecond").item(inverseItem)),
                                    ),
                                ),
                        ),
                    first to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, owner, fieldPath("children").item(firstItem))),
                    second to
                        record(
                            manySecond =
                                listOf(
                                    ListItem(
                                        inverseItem,
                                        link(MANY_SECOND_TYPE, MANY_SECOND, owner, fieldPath("manyFirst").item(secondItem)),
                                    ),
                                ),
                        ),
                )
            val ownership = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID))
            val baseline =
                operationBaseline(
                    resources,
                    listOf(
                        parentContract(RelationDeletePolicy.CASCADE, RelationDeletePolicy.CLEAR).copy(families = ownership),
                        manyContract().copy(families = ownership),
                    ),
                )
            val origin =
                com.typewritermc.discovery.ProviderOrigin(
                    com.typewritermc.types.DeclarationOwner(
                        com.typewritermc.discovery.ContributionKey(
                            com.typewritermc.imprint.ContributionSourceId("layout-test"),
                            "main",
                            com.typewritermc.imprint.ProducerId("test"),
                            com.typewritermc.imprint.ContributionName("layout"),
                        ),
                        "fixture.LayoutOperations",
                    ),
                    com.typewritermc.imprint.ArtifactId("fixture:layout"),
                    "main",
                )
            val requests = mutableListOf<com.typewritermc.operations.DestinationPlacementRequest>()

            fun policy(
                field: String,
                use: TypeUse,
            ) = com.typewritermc.operations.DestinationPlacementDeclaration(
                origin,
                TypeTemplate.Named(NODE),
                com.typewritermc.authoring.typedPath<Any, Any>(NODE, fieldPath(field), use),
                com.typewritermc.operations.DestinationPlacementPolicy { request ->
                    requests += request
                    com.typewritermc.operations.PlacementPreparation { }
                },
            )
            val operations =
                com.typewritermc.operations.OperationCatalog(
                    placements =
                        listOf(
                            policy("children", CHILDREN_USE),
                            policy("manyFirst", MANY_FIRST_LIST_USE),
                        ),
                )
            val catalog =
                object : com.typewritermc.realm.authoring.AuthoringCatalogLease by baseline.catalog {
                    override val operations = operations

                    override fun retain(): com.typewritermc.realm.authoring.AuthoringCatalogLease = this

                    override fun close() = Unit
                }
            try {
                val working = baseline.copy(catalog = catalog)
                val edit = SnapshotEditContext(working, "exact-layout")
                val layouts = OperationLayoutPreparation(edit, working)
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("exact-layout", listOf(first, second)),
                        PreparationChoices(),
                        edit,
                        working,
                    )
                with(session) { layouts.prepareMove(listOf(layouts.draft(first), layouts.draft(second)), owner, null).apply() }
                assertEquals(listOf(fieldPath("children"), fieldPath("manyFirst")), requests.map { it.collection.path })
                assertEquals(listOf(listOf(first), listOf(second)), requests.map { it.subjects.map { draft -> draft.id } })
                assertEquals(listOf(listOf(first), listOf(second)), requests.map { it.occupants.map { draft -> draft.id } })
                assertEquals(resources, baseline.resources)
            } finally {
                baseline.catalog.close()
            }
        }

    fun runtimeResolvesInlineCallbacksAndPreparesAgainstWorkingValues() =
        runBlocking {
            val first = ResourceId("callback_first")
            val second = ResourceId("callback_second")
            val resources = mapOf(first to record(label = "Saved"), second to record(label = "Second"))
            val baseline = operationBaseline(resources, emptyList())
            val origin =
                com.typewritermc.discovery.ProviderOrigin(
                    com.typewritermc.types.DeclarationOwner(
                        com.typewritermc.discovery.ContributionKey(
                            com.typewritermc.imprint.ContributionSourceId("operation-test"),
                            "main",
                            com.typewritermc.imprint.ProducerId("test"),
                            com.typewritermc.imprint.ContributionName("inline"),
                        ),
                        "fixture.InlineOperations",
                    ),
                    com.typewritermc.imprint.ArtifactId("fixture:operations"),
                    "main",
                )
            val declaration =
                com.typewritermc.operations.collectOperations(
                    origin,
                    "fixture.InlineOperations",
                    TypeTemplate.Named(NODE),
                    com.typewritermc.authoring.draftViewProjection(NODE_USE, com.typewritermc.authoring.ResourceDrafts::bind),
                ) { build ->
                    build.operation("suffix", com.typewritermc.operations.noInput()) {
                        label("Add suffix")
                        availability {
                            val authoredValues =
                                subjects.map {
                                    read(
                                        com.typewritermc.authoring.boundPath<String>(
                                            location(it.id, "label"),
                                            TypeUse.Scalar(ScalarKind.Text),
                                        ),
                                    )
                                }
                            val state = com.typewritermc.operations.authored(authoredValues)
                            if (state != com.typewritermc.operations.OperationAvailability.Enabled) return@availability state
                            val values = authoredValues.map { com.typewritermc.operations.requireAuthored(it) }
                            require(values.none { it == "availability-failure" }) { "Availability provider failed" }
                            com.typewritermc.operations.OperationAvailability.Enabled
                        }
                        prepare {
                            for (subject in subjects) {
                                val previous =
                                    com.typewritermc.operations.requireAuthored(
                                        read(
                                            com.typewritermc.authoring.boundPath<String>(
                                                location(subject.id, "label"),
                                                TypeUse.Scalar(ScalarKind.Text),
                                            ),
                                        ),
                                    )
                                require(previous != "reject") { "The complete selection cannot be changed" }
                                checkedSet(location(subject.id, "label"), DataValue.StringValue("$previous!"))
                            }
                        }
                    }
                }
            val operations =
                com.typewritermc.operations.bindOperations(
                    listOf(declaration),
                    baseline.catalog.checked,
                    baseline.catalog.nativeBindings,
                    emptyList(),
                    emptyList(),
                )
            check(operations.failures.isEmpty()) { operations.failures.joinToString { it.cause.toString() } }
            val lease =
                object : com.typewritermc.realm.authoring.AuthoringCatalogLease by baseline.catalog {
                    override val operations = operations

                    override fun retain(): com.typewritermc.realm.authoring.AuthoringCatalogLease = this

                    override fun close() = Unit
                }
            val store =
                com.typewritermc.realm.authoring.InMemoryAuthoringViewStore(
                    lease,
                    com.typewritermc.realm.authoring
                        .AuthoringSeed(resources),
                )
            try {
                val runtime =
                    com.typewritermc.realm.authoring
                        .ResourceOperationRuntime(store)
                val invocation = OperationInvocation("callback-operation", listOf(first, second))
                val token = store.capture().use { it.root.observationId }
                val overlay = mapOf(first to record(label = "Draft"))
                val resolved = runtime.resolve(invocation, GENERATION, token, overlay, emptySet())
                assertEquals(listOf("Add suffix"), resolved.operations.map { it.definition.presentation.label })
                val partial = record().let { it.copy(fields = it.fields + ("label" to DataValue.Unfilled)) }
                val partialResolution = runtime.resolve(invocation, GENERATION, token, mapOf(first to partial), emptySet())
                assertIs<com.typewritermc.operations.OperationAvailability.Disabled>(partialResolution.operations.single().availability)
                val capability =
                    resolved.operations
                        .single()
                        .definition.id.capability
                val preview =
                    assertIs<com.typewritermc.realm.authoring.OperationPreparationResult.Preview>(
                        runtime.prepare(invocation, GENERATION, capability, token, overlay, emptySet(), null, PreparationChoices()),
                    )
                assertTrue(preview.edit.intents.any { it is EditIntent.SetValue && it.value == DataValue.StringValue("Draft!") })
                assertTrue(
                    preview.edit.expectations.any {
                        it is com.typewritermc.authoring.EditExpectation.Value &&
                            it.at == location(first, "label") &&
                            it.expected == DataValue.StringValue("Draft")
                    },
                )
                val failed =
                    runtime.prepare(
                        invocation,
                        GENERATION,
                        capability,
                        token,
                        mapOf(second to record(label = "reject")),
                        emptySet(),
                        null,
                        PreparationChoices(),
                    )
                assertTrue(failed is com.typewritermc.realm.authoring.OperationPreparationResult.Failed)
                assertEquals(resources, store.capture().use { it.root.resources })
                var resolutionFailure: com.typewritermc.realm.authoring.OperationResolutionFailure? = null
                try {
                    runtime.resolve(invocation, GENERATION, token, mapOf(second to record(label = "availability-failure")), emptySet())
                } catch (
                    failure: com.typewritermc.realm.authoring.OperationResolutionFailure,
                ) {
                    resolutionFailure = failure
                }
                assertEquals(origin, resolutionFailure?.origin)
                assertEquals("Availability provider failed", resolutionFailure?.cause?.message)
                val routes =
                    com.typewritermc.realm.routes.ResourceOperationRoutes(
                        runtime,
                        com.typewritermc.realm.routes.EditorContracts(
                            com.typewritermc.protocol.transport.generated
                                .RealmRouteScope("organization", "realm"),
                        ),
                    )
                val wire =
                    skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest(
                        invocation =
                            skirout.editor.v1.resource_operations.OperationInvocation(
                                invocationId =
                                    skirout.editor.v1.capability
                                        .InvocationId(value = invocation.invocationId),
                                catalog =
                                    skirout.editor.v1.type_catalog
                                        .CatalogGeneration(value = GENERATION.value),
                                targets =
                                    invocation.targets.map {
                                        skirout.editor.v1.type_catalog
                                            .ResourceId(value = it.value)
                                    },
                                origin =
                                    skirout.editor.v1.resource_operations
                                        .OperationOrigin(container = null, occurrences = emptyList()),
                            ),
                        context =
                            skirout.editor.v1.resource_operations.OperationWorkingContext(
                                confirmedObservation =
                                    skirout.editor.v1.authoring
                                        .AuthoringObservationId(value = token),
                                overlay =
                                    skirout.editor.v1.resource_operations.OperationWorkingOverlay(
                                        upserts =
                                            listOf(
                                                skirout.editor.v1.resource_operations.OperationResourceUpsert(
                                                    resource =
                                                        skirout.editor.v1.type_catalog
                                                            .ResourceId(value = second.value),
                                                    content =
                                                        com.typewritermc.types.skir.SkirAuthoringValueCodec
                                                            .encode(
                                                                record(label = "availability-failure"),
                                                            ).getOrThrow(),
                                                ),
                                            ),
                                        removals = emptyList(),
                                    ),
                            ),
                    )
                val wireFailure =
                    assertIs<skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.FailedWrapper>(routes.resolve(wire))
                assertTrue(
                    wireFailure.value.diagnostics
                        .single()
                        .message
                        .contains("fixture.InlineOperations"),
                )
            } finally {
                store.close()
                baseline.catalog.close()
            }
        }

    fun adjacentDeletesValidateRestrictionAgainstTheWholeSet() {
        val first = ResourceId("restricted_first")
        val second = ResourceId("restricted_second")
        val third = ResourceId("unrelated_write")
        val resources =
            mapOf(
                first to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, second, fieldPath("second"))),
                second to record(second = link(PAIR_SECOND_TYPE, PAIR_SECOND, first, fieldPath("first"))),
                third to record(),
            )
        val contract =
            pairContract().let {
                it.copy(
                    first = it.first.copy(onDelete = RelationDeletePolicy.RESTRICT),
                    second = it.second.copy(onDelete = RelationDeletePolicy.RESTRICT),
                )
            }
        val planner = planner(contract)
        val complete =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(resources, edit(EditIntent.DeleteResource(first), EditIntent.DeleteResource(second))),
            ).plan
        assertEquals(setOf(first, second), complete.removedResources)
        val separated =
            planner.plan(
                resources,
                edit(
                    EditIntent.DeleteResource(first),
                    EditIntent.SetValue(location(third, "label"), DataValue.StringValue("ordered boundary")),
                    EditIntent.DeleteResource(second),
                ),
            )
        assertTrue(separated is MutationPlanningResult.Rejected)
    }

    fun deletionSelectionIncludesCascadeAndExplicitDescendantOnce() =
        runBlocking {
            val parent = ResourceId("delete_parent")
            val child = ResourceId("delete_child")
            val item = ItemId("child")
            val resources =
                mapOf(
                    parent to record(children = listOf(ListItem(item, link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent"))))),
                    child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, fieldPath("children").item(item))),
                )
            val baseline = operationBaseline(resources, listOf(parentContract(RelationDeletePolicy.CASCADE, RelationDeletePolicy.CLEAR)))
            try {
                val edit = SnapshotEditContext(baseline, "delete-overlap")
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("delete-overlap", listOf(parent, child)),
                        PreparationChoices(),
                        edit,
                        baseline,
                    )
                session.deleteSelection(listOf(parent, child))
                val result = edit.finish()
                assertTrue(edit.session.resources.isEmpty())
                assertEquals(2, result.intents.filterIsInstance<EditIntent.DeleteResource>().size)
            } finally {
                baseline.catalog.close()
            }
        }

    fun moveTransfersTheWholeSelectionThroughExactOwnershipInverses() =
        runBlocking {
            val from = ResourceId("move_from")
            val to = ResourceId("move_to")
            val first = ResourceId("move_first")
            val second = ResourceId("move_second")
            val firstItem = ItemId("first")
            val secondItem = ItemId("second")
            val resources =
                mapOf(
                    from to
                        record(
                            children =
                                listOf(
                                    ListItem(firstItem, link(PARENT_FIRST_TYPE, PARENT_FIRST, first, fieldPath("parent"))),
                                    ListItem(secondItem, link(PARENT_FIRST_TYPE, PARENT_FIRST, second, fieldPath("parent"))),
                                ),
                        ),
                    to to record(),
                    first to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, from, fieldPath("children").item(firstItem)),
                            label = "first",
                        ),
                    second to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, from, fieldPath("children").item(secondItem)),
                            label = "second",
                        ),
                )
            val baseline =
                operationBaseline(
                    resources,
                    listOf(
                        parentContract(
                            RelationDeletePolicy.CASCADE,
                            RelationDeletePolicy.CLEAR,
                        ).copy(families = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID))),
                    ),
                )
            try {
                val edit = SnapshotEditContext(baseline, "move-selection")
                val origin = OperationOrigin(from, baseline.links.values.filter { it.source == from })
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("move-selection", listOf(first, second), origin),
                        PreparationChoices(),
                        edit,
                        baseline,
                    )
                val subjects = listOf(first, second).map(OperationLayoutPreparation(edit, baseline)::draft)
                with(session) { relations.requireMove(subjects, to, origin, choices).apply() }
                val prepared = edit.finish()
                assertTrue(
                    prepared.intents.filterIsInstance<EditIntent.ConnectRelation>().all {
                        it.intent.counterpart is CounterpartChoice.Existing
                    },
                )
                val final = ResourceValueMapper.discover(edit.session.resources)
                assertEquals(setOf(first, second), final.filter { it.source == to }.map { it.target.resource }.toSet())
                assertTrue(final.none { it.source == from })
                assertEquals(
                    "first",
                    (
                        edit.session.resources
                            .getValue(first)
                            .fields
                            .getValue("label") as DataValue.StringValue
                    ).value,
                )
                assertEquals(resources, baseline.resources)
            } finally {
                baseline.catalog.close()
            }
        }

    fun impossibleBatchMoveRejectsBeforeChangingAnyResource() =
        runBlocking {
            val ownerA = ResourceId("owner_a")
            val ownerB = ResourceId("owner_b")
            val destination = ResourceId("single_owner")
            val childA = ResourceId("child_a")
            val childB = ResourceId("child_b")
            val resources =
                mapOf(
                    ownerA to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, childA, fieldPath("second"))),
                    ownerB to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, childB, fieldPath("second"))),
                    destination to record(),
                    childA to record(second = link(PAIR_SECOND_TYPE, PAIR_SECOND, ownerA, fieldPath("first"))),
                    childB to record(second = link(PAIR_SECOND_TYPE, PAIR_SECOND, ownerB, fieldPath("first"))),
                )
            val baseline = operationBaseline(resources, listOf(pairContract(setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)))))
            try {
                val edit = SnapshotEditContext(baseline, "impossible-move")
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("impossible-move", listOf(childA, childB)),
                        PreparationChoices(),
                        edit,
                        baseline,
                    )
                val subjects = listOf(childA, childB).map(OperationLayoutPreparation(edit, baseline)::draft)
                var rejected = false
                try {
                    with(session) { relations.requireMove(subjects, destination, invocation.origin, choices).apply() }
                } catch (
                    _: IllegalArgumentException,
                ) {
                    rejected =
                        true
                }
                assertTrue(rejected)
                assertTrue(edit.session.intents.isEmpty())
                assertEquals(resources, edit.session.resources)
            } finally {
                baseline.catalog.close()
            }
        }

    fun cloneCopiesOwnedClosureAndDeduplicatesSelectedDescendants() =
        runBlocking {
            val book = ResourceId("clone_book")
            val page = ResourceId("clone_page")
            val element = ResourceId("clone_element")
            val outside = ResourceId("clone_shared")
            val pageItem = ItemId("page")
            val elementItem = ItemId("element")
            val resources =
                mapOf(
                    book to
                        record(
                            children = listOf(ListItem(pageItem, link(PARENT_FIRST_TYPE, PARENT_FIRST, page, fieldPath("parent")))),
                            manyFirst =
                                listOf(
                                    ListItem(
                                        pageItem,
                                        link(MANY_FIRST_TYPE, MANY_FIRST, outside, fieldPath("manySecond").item(ItemId("outside"))),
                                    ),
                                ),
                        ),
                    page to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, book, fieldPath("children").item(pageItem)),
                            children = listOf(ListItem(elementItem, link(PARENT_FIRST_TYPE, PARENT_FIRST, element, fieldPath("parent")))),
                        ),
                    element to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, page, fieldPath("children").item(elementItem))),
                    outside to
                        record(
                            manySecond =
                                listOf(
                                    ListItem(
                                        ItemId("outside"),
                                        link(MANY_SECOND_TYPE, MANY_SECOND, book, fieldPath("manyFirst").item(pageItem)),
                                    ),
                                ),
                        ),
                )
            val baseline =
                operationBaseline(
                    resources,
                    listOf(
                        parentContract(
                            RelationDeletePolicy.CASCADE,
                            RelationDeletePolicy.CLEAR,
                        ).copy(families = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID))),
                        manyContract(),
                    ),
                )
            try {
                val edit = SnapshotEditContext(baseline, "clone-closure")
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("clone-closure", listOf(book, page)),
                        PreparationChoices(),
                        edit,
                        baseline,
                    )
                val result = with(session) { cloner.duplicateOwned(listOf(book, page)) }
                val final = edit.finish()
                assertEquals(2, result.selectedCopies.size)
                assertEquals(3, final.intents.filterIsInstance<EditIntent.CreateResource>().size)
                assertEquals(7, edit.session.resources.size)
                val copy = edit.session.resources.getValue(result.selectedCopies[0])
                val copiedChildItem =
                    (
                        (
                            copy.fields.getValue(
                                "children",
                            ) as DataValue.Named
                        ).payload as DataValue.ListValue
                    ).items.single().id
                val copiedOrdinaryItem =
                    (
                        (
                            copy.fields.getValue(
                                "manyFirst",
                            ) as DataValue.Named
                        ).payload as DataValue.ListValue
                    ).items.single().id
                assertTrue(copiedChildItem != copiedOrdinaryItem)
                assertEquals(resources, baseline.resources)
                val copied =
                    ResourceValueMapper.project(
                        ResourceValueMapper.discover(edit.session.resources),
                        edit.session.resources,
                        baseline.catalog.relations,
                        baseline.catalog.checked,
                    )
                assertTrue(copied.problems.isEmpty())
                assertTrue(copied.projections.any { it.first == result.selectedCopies[0] && it.second == result.selectedCopies[1] })
            } finally {
                baseline.catalog.close()
            }
        }

    fun clonePreservesOutsideOutgoingAndLeavesIncomingOnOriginal() =
        runBlocking {
            val source = ResourceId("copy_source")
            val outside = ResourceId("copy_outside")
            val incoming = ResourceId("copy_incoming")
            val outgoingItem = ItemId("outgoing")
            val outsideItem = ItemId("outside_inverse")
            val incomingItem = ItemId("incoming")
            val sourceInverse = ItemId("source_inverse")
            val resources =
                mapOf(
                    source to
                        record(
                            manyFirst =
                                listOf(
                                    ListItem(
                                        outgoingItem,
                                        link(MANY_FIRST_TYPE, MANY_FIRST, outside, fieldPath("manySecond").item(outsideItem)),
                                    ),
                                ),
                            manySecond =
                                listOf(
                                    ListItem(
                                        sourceInverse,
                                        link(MANY_SECOND_TYPE, MANY_SECOND, incoming, fieldPath("manyFirst").item(incomingItem)),
                                    ),
                                ),
                        ),
                    outside to
                        record(
                            manySecond =
                                listOf(
                                    ListItem(
                                        outsideItem,
                                        link(MANY_SECOND_TYPE, MANY_SECOND, source, fieldPath("manyFirst").item(outgoingItem)),
                                    ),
                                ),
                        ),
                    incoming to
                        record(
                            manyFirst =
                                listOf(
                                    ListItem(
                                        incomingItem,
                                        link(MANY_FIRST_TYPE, MANY_FIRST, source, fieldPath("manySecond").item(sourceInverse)),
                                    ),
                                ),
                        ),
                )
            val baseline = operationBaseline(resources, listOf(manyContract()))
            try {
                val edit = SnapshotEditContext(baseline, "clone-outside")
                val session =
                    RuntimeOperationPreparation(OperationInvocation("clone-outside", listOf(source)), PreparationChoices(), edit, baseline)
                val copy = with(session) { cloner.duplicateOwned(listOf(source)).selectedCopies.single() }
                edit.finish()
                val links = ResourceValueMapper.discover(edit.session.resources)
                assertTrue(links.any { it.source == copy && it.target.resource == outside })
                assertTrue(links.none { it.source == incoming && it.target.resource == copy })
                assertEquals(resources.getValue(incoming), edit.session.resources.getValue(incoming))
                assertTrue(links.none { it.source == copy && it.target.resource == incoming })
            } finally {
                baseline.catalog.close()
            }
        }

    fun cloneRejectsOccupiedExternalScalarWithoutChangingSavedState() =
        runBlocking {
            val source = ResourceId("scalar_copy_source")
            val outside = ResourceId("scalar_copy_outside")
            val resources =
                mapOf(
                    source to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, outside, fieldPath("second"))),
                    outside to record(second = link(PAIR_SECOND_TYPE, PAIR_SECOND, source, fieldPath("first"))),
                )
            val baseline = operationBaseline(resources, listOf(pairContract()))
            try {
                val edit = SnapshotEditContext(baseline, "clone-scalar")
                val session =
                    RuntimeOperationPreparation(OperationInvocation("clone-scalar", listOf(source)), PreparationChoices(), edit, baseline)
                var rejected = false
                try {
                    with(session) { cloner.duplicateOwned(listOf(source)) }
                } catch (_: IllegalArgumentException) {
                    rejected = true
                }
                assertTrue(rejected)
                assertEquals(resources, baseline.resources)
            } finally {
                baseline.catalog.close()
            }
        }

    fun repeatedEmbeddedCounterpartsRetainDistinctExplicitIdentities() {
        val source = ResourceId("embedded_source")
        val target = ResourceId("embedded_target")
        val definitions =
            DEFINITIONS.map { definition ->
                if (definition.id ==
                    CHILDREN_USE.definition
                ) {
                    definition.copy(
                        representation =
                            RepresentationTemplate.Sequence(
                                item = TypeTemplate.Named(WRAPPER_USE.definition),
                                kind = CollectionKind.List,
                            ),
                    )
                } else {
                    definition
                }
            }
        val catalog =
            com.typewritermc.realm.checking.TestCatalogLease(
                generation = GENERATION,
                definitions = definitions,
                resourceRoot = NODE,
                relations =
                    listOf(
                        nestedContract().let {
                            it.copy(second = it.second.copy(cardinality = EndpointCardinality.Many))
                        },
                    ),
                endpointBindings = BINDINGS,
            )
        val resources = mapOf(source to record(), target to record())
        val baseline =
            com.typewritermc.realm.authoring.AuthoringView(
                catalog,
                resources,
                resources.mapValues {
                    com.typewritermc.authoring.ResourceDefinitionId("test")
                },
                emptyMap(),
            )
        try {
            val session = AuthoringPlanningSession(baseline, "embedded-normalization")
            val occurrence = occurrence(NESTED_SECOND, location(source, "nestedSecond"), target, null)
            val choice =
                CounterpartChoice.New(
                    location(target, "children"),
                    PreparedValue(
                        PreparedContent.Record(
                            AuthoringRecord(
                                TypeSelection.Complete(WRAPPER_USE),
                                mapOf("inner" to DataValue.Unfilled),
                            ),
                        ),
                        emptyList(),
                    ),
                )
            session.append(EditIntent.ConnectRelation(ConnectIntent(occurrence, target, choice)))
            session.append(EditIntent.DisconnectRelation(occurrence.id))
            session.append(EditIntent.ConnectRelation(ConnectIntent(occurrence, target, choice)))
            val (prepared, _) = session.finish()
            val inserts = prepared.intents.filterIsInstance<EditIntent.Insert>()
            assertEquals(2, inserts.size)
            assertTrue(inserts[0].item.id != inserts[1].item.id)
            assertTrue(
                prepared.intents.filterIsInstance<EditIntent.ConnectRelation>().all { it.intent.counterpart is CounterpartChoice.Existing },
            )
        } finally {
            catalog.close()
        }
    }

    fun normalizedInverseIdentitySurvivesLaterWritesAndComposition() {
        val parent = ResourceId("normalized_parent")
        val child = ResourceId("normalized_child")
        val resources = mapOf(parent to record(), child to record())
        val catalog =
            com.typewritermc.realm.checking.TestCatalogLease(
                generation = GENERATION,
                definitions = DEFINITIONS,
                resourceRoot = NODE,
                relations = listOf(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR)),
                endpointBindings = BINDINGS,
            )
        val baseline =
            com.typewritermc.realm.authoring.AuthoringView(
                catalog,
                resources,
                resources.mapValues { com.typewritermc.authoring.ResourceDefinitionId("test") },
                emptyMap(),
            )
        try {
            val session = AuthoringPlanningSession(baseline, "normalization-test")
            session.append(
                EditIntent.ConnectRelation(ConnectIntent(occurrence(PARENT_SECOND, location(child, "parent"), parent, null), parent, null)),
            )
            val inverse = ResourceValueMapper.discover(session.resources).single { it.source == parent }
            assertTrue((session.intents.single() as EditIntent.ConnectRelation).intent.counterpart is CounterpartChoice.Existing)
            session.append(EditIntent.SetValue(location(child, "label"), DataValue.StringValue("later write")))
            val (prepared, plan) = session.finish()
            assertEquals(session.resources, resources + plan.resources - plan.removedResources)
            val composed =
                prepared.copy(
                    intents =
                        listOf(EditIntent.SetValue(location(parent, "label"), DataValue.StringValue("earlier draft"))) + prepared.intents,
                )
            val final = assertIs<MutationPlanningResult.Accepted>(session.planner.plan(resources, composed)).plan
            assertTrue(ResourceValueMapper.discover(resources + final.resources).any { it.id == inverse.id })
        } finally {
            catalog.close()
        }
    }

    fun counterpartClassificationPreservesBroaderServerCapabilities() {
        val resource = ResourceId("counterpart")
        assertEquals(
            CounterpartBinding.Scalar(location(resource, "second")),
            ResourceValueMapper.counterpartBinding(PAIR_SECOND, resource, record(), CATALOG),
        )
        assertEquals(
            CounterpartBinding.Collection(location(resource, "children")),
            ResourceValueMapper.counterpartBinding(PARENT_FIRST, resource, record(), CATALOG),
        )
        assertEquals(
            CounterpartBinding.Scalar(ValueLocation(resource, ValuePath(listOf(PathSegment.Field("wrapper"), PathSegment.Field("inner"))))),
            ResourceValueMapper.counterpartBinding(NESTED_FIRST, resource, record(), CATALOG),
        )
        assertEquals(
            CounterpartBinding.Missing,
            ResourceValueMapper.counterpartBinding(EndpointId("absent"), resource, record(), CATALOG),
        )

        val node = DEFINITIONS.single { it.id == NODE }
        val shape = node.representation as RepresentationTemplate.Record
        val ambiguous =
            node.copy(
                representation =
                    shape.copy(
                        fields =
                            shape.fields + field("secondAlternative", PAIR_SECOND_TYPE.definition),
                    ),
            )
        val catalog = DefaultCheckedCatalog(GENERATION, DEFINITIONS.map { if (it.id == NODE) ambiguous else it })
        val target = record().copy(fields = record().fields + ("secondAlternative" to DataValue.Unfilled))
        assertEquals(
            CounterpartBinding.ExplicitChoice,
            ResourceValueMapper.counterpartBinding(PAIR_SECOND, resource, target, catalog),
        )
    }

    fun unknownConnectEndpointIsRejectedBeforeInferringACounterpart() {
        val source = ResourceId("source")
        val target = ResourceId("target")
        val result =
            assertIs<MutationPlanningResult.Rejected>(
                planner(pairContract()).plan(
                    mapOf(source to record(), target to record()),
                    edit(
                        EditIntent.ConnectRelation(
                            ConnectIntent(occurrence(EndpointId("absent"), location(source, "first"), target, null), target, null),
                        ),
                    ),
                ),
            )
        assertEquals(listOf("unknown_endpoint"), result.problems.map { it.code })
    }

    fun insertMaterializesTheCheckedUnfilledSequenceShape() {
        listOf(CollectionKind.List, CollectionKind.Set).forEach { kind ->
            val rootType = id("insert_${kind.name.lowercase()}_root")
            val collectionType = id("insert_${kind.name.lowercase()}_collection")
            val rootUse = TypeUse.Named(rootType)
            val collectionUse = TypeUse.Named(collectionType)
            val catalog =
                DefaultCheckedCatalog(
                    GENERATION,
                    listOf(
                        TypeDefinition(
                            rootType,
                            representation =
                                RepresentationTemplate.Record(
                                    listOf(
                                        FieldDeclaration(
                                            FieldOwner(rootType, "values"),
                                            TypeTemplate.Named(collectionType),
                                        ),
                                    ),
                                ),
                        ),
                        TypeDefinition(
                            collectionType,
                            representation = RepresentationTemplate.Sequence(TypeTemplate.Scalar(ScalarKind.Text), kind),
                        ),
                    ),
                )
            val planner = AuthoringMutationPlanner(catalog, emptyList())
            val resource = ResourceId("insert_${kind.name.lowercase()}")
            val location = location(resource, "values")
            val before =
                mapOf(
                    resource to
                        AuthoringRecord(
                            TypeSelection.Complete(rootUse),
                            mapOf("values" to DataValue.Unfilled),
                        ),
                )
            val item = ListItem(ItemId("stable_item"), DataValue.StringValue("value"))
            val accepted =
                assertIs<MutationPlanningResult.Accepted>(
                    planner.plan(before, edit(EditIntent.Insert(location, null, item))),
                ).plan
            val collection =
                assertIs<DataValue.Named>(
                    before
                        .apply(accepted)
                        .getValue(resource)
                        .fields
                        .getValue("values"),
                )

            assertEquals(collectionUse, collection.actualType)
            when (kind) {
                CollectionKind.List -> assertEquals(listOf(item), assertIs<DataValue.ListValue>(collection.payload).items)
                CollectionKind.Set -> assertEquals(listOf(item), assertIs<DataValue.SetValue>(collection.payload).items)
            }
            assertIs<MutationPlanningResult.Rejected>(
                planner.plan(
                    before,
                    edit(
                        EditIntent.Insert(
                            location,
                            null,
                            ListItem(ItemId("invalid_item"), DataValue.Boolean(true)),
                        ),
                    ),
                ),
            )
        }
    }

    fun pendingInheritedApplicationSubstitutesItsEndpointTarget() {
        val base = id("generic_base")
        val derived = id("generic_derived")
        val target = id("generic_target")
        val link = id("generic_link")
        val baseParameter = ParameterKey(base, 0)
        val derivedParameter = ParameterKey(derived, 0)
        val linkParameter = ParameterKey(link, 0)
        val endpoint = EndpointId("generic:target")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(
                        base,
                        parameters = listOf(TypeParameter(baseParameter, "T")),
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(
                                        FieldOwner(base, "link"),
                                        TypeTemplate.Named(link, listOf(TypeTemplate.Parameter(baseParameter))),
                                    ),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        derived,
                        parameters = listOf(TypeParameter(derivedParameter, "T")),
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents =
                            listOf(
                                TypeTemplate.Named(
                                    base,
                                    listOf(TypeTemplate.Parameter(derivedParameter)),
                                ),
                            ),
                    ),
                    TypeDefinition(target, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(
                        link,
                        parameters = listOf(TypeParameter(linkParameter, "T")),
                        representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(linkParameter)),
                    ),
                ),
            )
        val resource = ResourceId("source")
        val targetUse = TypeUse.Named(target)
        val record =
            AuthoringRecord(
                TypeSelection.Pending(derived, listOf(ArgumentSelection.Chosen(targetUse))),
                mapOf("link" to DataValue.Unfilled),
            )
        val occurrence =
            occurrence(
                endpoint,
                location(resource, "link"),
                ResourceId("target"),
                null,
            )
        assertEquals(
            targetUse,
            ResourceValueMapper.expectedTarget(occurrence, record, catalog),
        )
    }

    fun pendingTargetsRequireProvableAppliedArguments() {
        val sourceType = id("partial_source")
        val config = id("partial_config")
        val linkType = id("partial_link")
        val first = ParameterKey(config, 0)
        val second = ParameterKey(config, 1)
        val linkParameter = ParameterKey(linkType, 0)
        val endpoint = EndpointId("partial:first")
        val opposite = EndpointId("partial:second")
        val text = TypeUse.Scalar(ScalarKind.Text)
        val integer = TypeUse.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32))
        val expected = TypeUse.Named(config, listOf(text, integer))
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(
                        sourceType,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(
                                        FieldOwner(sourceType, "target"),
                                        TypeTemplate.Named(
                                            linkType,
                                            listOf(
                                                TypeTemplate.Named(
                                                    config,
                                                    listOf(
                                                        TypeTemplate.Scalar(ScalarKind.Text),
                                                        TypeTemplate.Scalar(
                                                            ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        config,
                        parameters = listOf(TypeParameter(first, "T"), TypeParameter(second, "U")),
                        representation = RepresentationTemplate.Record(emptyList()),
                    ),
                    TypeDefinition(
                        linkType,
                        parameters = listOf(TypeParameter(linkParameter, "T")),
                        representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(linkParameter)),
                    ),
                ),
            )
        val contract =
            RelationContract(
                RelationId("partial:relation"),
                EndpointDefinition(
                    endpoint,
                    EndpointSlot.First,
                    TypeTemplate.Named(sourceType),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
                EndpointDefinition(
                    opposite,
                    EndpointSlot.Second,
                    TypeTemplate.Named(
                        config,
                        listOf(
                            TypeTemplate.Scalar(ScalarKind.Text),
                            TypeTemplate.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32)),
                        ),
                    ),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
            )
        val source = ResourceId("partial_source")
        val target = ResourceId("partial_target")
        val sourceRecord =
            AuthoringRecord(
                TypeSelection.Complete(TypeUse.Named(sourceType)),
                mapOf("target" to link(TypeUse.Named(linkType, listOf(expected)), endpoint, target, null)),
            )

        listOf(
            TypeSelection.Pending(config, listOf(ArgumentSelection.Chosen(integer), ArgumentSelection.Unfilled)),
            TypeSelection.Pending(config, listOf(ArgumentSelection.Chosen(text), ArgumentSelection.Unfilled)),
        ).forEach { selection ->
            val resources = mapOf(source to sourceRecord, target to AuthoringRecord(selection, emptyMap()))
            val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

            assertTrue(projection.projections.isEmpty())
            assertTrue(projection.problems.any { it.location == location(source, "target") && it.code == "target_resource_type_mismatch" })
        }
    }

    fun pendingTargetCanProveAnAncestorThatDoesNotUseEveryArgument() {
        val sourceType = id("partial_ancestor_source")
        val view = id("partial_view")
        val derived = id("partial_derived")
        val linkType = id("partial_ancestor_link")
        val viewParameter = ParameterKey(view, 0)
        val first = ParameterKey(derived, 0)
        val unused = ParameterKey(derived, 1)
        val linkParameter = ParameterKey(linkType, 0)
        val endpoint = EndpointId("partial_ancestor:first")
        val opposite = EndpointId("partial_ancestor:second")
        val text = TypeUse.Scalar(ScalarKind.Text)
        val expected = TypeUse.Named(view, listOf(text))
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(
                        sourceType,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(
                                        FieldOwner(sourceType, "target"),
                                        TypeTemplate.Named(
                                            linkType,
                                            listOf(TypeTemplate.Named(view, listOf(TypeTemplate.Scalar(ScalarKind.Text)))),
                                        ),
                                    ),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        view,
                        parameters = listOf(TypeParameter(viewParameter, "T")),
                        representation = RepresentationTemplate.Record(emptyList()),
                    ),
                    TypeDefinition(
                        derived,
                        parameters = listOf(TypeParameter(first, "T"), TypeParameter(unused, "Unused")),
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(view, listOf(TypeTemplate.Parameter(first)))),
                    ),
                    TypeDefinition(
                        linkType,
                        parameters = listOf(TypeParameter(linkParameter, "T")),
                        representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(linkParameter)),
                    ),
                ),
            )
        val contract =
            RelationContract(
                RelationId("partial_ancestor:relation"),
                EndpointDefinition(
                    endpoint,
                    EndpointSlot.First,
                    TypeTemplate.Named(sourceType),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
                EndpointDefinition(
                    opposite,
                    EndpointSlot.Second,
                    TypeTemplate.Named(view, listOf(TypeTemplate.Scalar(ScalarKind.Text))),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
            )
        val source = ResourceId("partial_ancestor_source")
        val target = ResourceId("partial_ancestor_target")
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(sourceType)),
                        mapOf("target" to link(TypeUse.Named(linkType, listOf(expected)), endpoint, target, null)),
                    ),
                target to
                    AuthoringRecord(
                        TypeSelection.Pending(derived, listOf(ArgumentSelection.Chosen(text), ArgumentSelection.Unfilled)),
                        emptyMap(),
                    ),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        assertEquals(1, projection.projections.size)
        assertTrue(projection.problems.isEmpty())
    }

    fun connectAndDisconnectSynchronizeBothDirectSides() {
        val planner = planner(pairContract())
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceLocation = location(source, "first")
        val targetLocation = location(target, "second")
        val sourceOccurrence = occurrence(PAIR_FIRST, sourceLocation, target, targetLocation.path)
        val targetOccurrence = occurrence(PAIR_SECOND, targetLocation, source, sourceLocation.path)
        val before = mapOf(source to record(), target to record())

        val connected =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(
                        EditIntent.ConnectRelation(
                            ConnectIntent(sourceOccurrence, target, CounterpartChoice.Existing(targetOccurrence)),
                        ),
                    ),
                ),
            ).plan
        val connectedResources = before.apply(connected)

        assertEquals(
            link(PAIR_FIRST_TYPE, PAIR_FIRST, target, targetLocation.path),
            connectedResources.getValue(source).fields.getValue("first"),
        )
        assertEquals(
            link(PAIR_SECOND_TYPE, PAIR_SECOND, source, sourceLocation.path),
            connectedResources.getValue(target).fields.getValue("second"),
        )
        assertEquals(1, connected.relations.created.size)

        val disconnected =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    connectedResources,
                    edit(EditIntent.DisconnectRelation(sourceOccurrence.id)),
                ),
            ).plan
        val disconnectedResources = connectedResources.apply(disconnected)

        assertEquals(DataValue.Unfilled, disconnectedResources.getValue(source).fields.getValue("first"))
        assertEquals(DataValue.Unfilled, disconnectedResources.getValue(target).fields.getValue("second"))
        assertEquals(1, disconnected.relations.removed.size)
    }

    fun scalarConnectAppendsItsDirectCollectionCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("page")
        val child = ResourceId("element")
        val sourceLocation = location(child, "parent")
        val source = occurrence(PARENT_SECOND, sourceLocation, parent, null)
        val before = mapOf(parent to record(), child to record())

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, parent, null))),
                ),
            ).plan
        val resources = before.apply(plan)
        val children =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(resources.getValue(parent).fields.getValue("children")).payload,
            ).items

        assertEquals(1, children.size)
        val counterpartPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(children.single().id)))
        assertEquals(
            link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, counterpartPath),
            resources.getValue(child).fields.getValue("parent"),
        )
        assertEquals(
            link(PARENT_FIRST_TYPE, PARENT_FIRST, child, sourceLocation.path),
            children.single().value,
        )
    }

    fun scalarConnectMaterializesItsUnfilledDirectCollectionCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("page")
        val child = ResourceId("element")
        val sourceLocation = location(child, "parent")
        val source = occurrence(PARENT_SECOND, sourceLocation, parent, null)
        val parentRecord = record().copy(fields = record().fields + ("children" to DataValue.Unfilled))
        val before = mapOf(parent to parentRecord, child to record())

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, parent, null))),
                ),
            ).plan
        val resources = before.apply(plan)
        val children =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(resources.getValue(parent).fields.getValue("children")).payload,
            ).items

        assertEquals(1, children.size)
        assertEquals(child, assertIs<DataValue.Link>(assertIs<DataValue.Named>(children.single().value).payload).target.resource)
    }

    fun newCounterpartEvidenceProtectsPriorStateWithoutRequiringThePlannedLocation() {
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceLocation = location(source, "nestedSecond")
        val containing = location(target, "children")
        val generatedItem = ItemId("relation:server_generated")
        val generatedLink =
            ValueLocation(
                target,
                ValuePath(
                    listOf(
                        PathSegment.Field("children"),
                        PathSegment.Item(generatedItem),
                        PathSegment.Field("inner"),
                    ),
                ),
            )
        val before = mapOf(source to record(), target to record())
        val edit =
            edit(
                EditIntent.ConnectRelation(
                    ConnectIntent(
                        occurrence(NESTED_SECOND, sourceLocation, target, null),
                        target,
                        CounterpartChoice.New(
                            containing,
                            PreparedValue(
                                PreparedContent.Record(
                                    AuthoringRecord(
                                        TypeSelection.Complete(WRAPPER_USE),
                                        mapOf("inner" to DataValue.Unfilled),
                                    ),
                                ),
                                emptyList(),
                            ),
                        ),
                    ),
                ),
            )
        val plan =
            AuthoringMutationPlan(
                resources = emptyMap(),
                removedResources = emptySet(),
                relations =
                    RelationProjectionDelta(
                        removed = emptyList(),
                        created =
                            listOf(
                                LinkProjection(
                                    contract = nestedContract().id,
                                    first = source,
                                    second = target,
                                    firstLocation = sourceLocation.path,
                                    secondLocation = generatedLink.path,
                                ),
                            ),
                        metadataChanged = emptyList(),
                    ),
            )

        val values = CapturedAuthoringValues(before, emptyList())
        val evidence = values.requiredExpectations(edit, before, setOf(nestedContract().id), plan)
        assertTrue(evidence.any { it is com.typewritermc.authoring.EditExpectation.Value && it.at == sourceLocation })
        assertTrue(evidence.any { it is com.typewritermc.authoring.EditExpectation.Configuration && it.at == containing })
        assertTrue(evidence.any { it is com.typewritermc.authoring.EditExpectation.Links && it.resource == source })
        assertTrue(evidence.any { it is com.typewritermc.authoring.EditExpectation.Links && it.resource == target })
    }

    fun proposedCollectionOccurrenceConnectsItsDirectScalarCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("book")
        val child = ResourceId("page")
        val item = ItemId("page_occurrence")
        val sourceLocation =
            ValueLocation(parent, ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item))))
        val source = occurrence(PARENT_FIRST, sourceLocation, child, null)
        val before = mapOf(parent to record(), child to record())

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, child, null))),
                ),
            ).plan
        val resources = before.apply(plan)
        val children =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(resources.getValue(parent).fields.getValue("children")).payload,
            ).items

        assertEquals(listOf(item), children.map(ListItem::id))
        assertEquals(
            link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent")),
            children.single().value,
        )
        assertEquals(
            link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, sourceLocation.path),
            resources.getValue(child).fields.getValue("parent"),
        )
    }

    fun proposedCollectionOccurrenceMaterializesItsUnfilledCollection() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("book")
        val child = ResourceId("page")
        val item = ItemId("page_occurrence")
        val sourceLocation =
            ValueLocation(parent, ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item))))
        val source = occurrence(PARENT_FIRST, sourceLocation, child, null)
        val parentRecord = record().copy(fields = record().fields + ("children" to DataValue.Unfilled))
        val before = mapOf(parent to parentRecord, child to record())

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, child, null))),
                ),
            ).plan
        val resources = before.apply(plan)
        val children =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(resources.getValue(parent).fields.getValue("children")).payload,
            ).items

        assertEquals(listOf(item), children.map(ListItem::id))
        assertEquals(
            link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, sourceLocation.path),
            resources.getValue(child).fields.getValue("parent"),
        )
    }

    fun ordinaryLinkSetAndClearSynchronizeTheDirectCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("page")
        val child = ResourceId("element")
        val parentLocation = location(child, "parent")
        val before = mapOf(parent to record(), child to record())

        val connected =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(
                        EditIntent.SetValue(
                            parentLocation,
                            link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, null),
                        ),
                    ),
                ),
            ).plan
        val connectedResources = before.apply(connected)
        val children =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(connectedResources.getValue(parent).fields.getValue("children")).payload,
            ).items

        assertEquals(1, children.size)
        val cleared =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    connectedResources,
                    edit(EditIntent.SetValue(parentLocation, DataValue.Unfilled)),
                ),
            ).plan
        val clearedResources = connectedResources.apply(cleared)
        val remaining =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(clearedResources.getValue(parent).fields.getValue("children")).payload,
            ).items

        assertTrue(remaining.isEmpty())
        assertEquals(DataValue.Unfilled, clearedResources.getValue(child).fields.getValue("parent"))
    }

    fun ordinaryCollectionRemoveClearsTheDirectScalarCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("book")
        val child = ResourceId("page")
        val item = ItemId("page_occurrence")
        val itemPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item)))
        val resources =
            mapOf(
                parent to
                    record(
                        children =
                            listOf(
                                ListItem(
                                    item,
                                    link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent")),
                                ),
                            ),
                    ),
                child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, itemPath)),
            )

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    resources,
                    edit(EditIntent.Remove(location(parent, "children"), item)),
                ),
            ).plan
        val next = resources.apply(plan)

        assertEquals(DataValue.Unfilled, next.getValue(child).fields.getValue("parent"))
        val items =
            assertIs<DataValue.ListValue>(
                assertIs<DataValue.Named>(next.getValue(parent).fields.getValue("children")).payload,
            ).items
        assertTrue(items.isEmpty())
    }

    fun ordinaryContainingRecordSetAndClearSynchronizeNestedLinks() {
        val contract = nestedContract()
        val planner = AuthoringMutationPlanner(CATALOG, listOf(contract), NESTED_BINDINGS)
        val source = ResourceId("source")
        val target = ResourceId("target")
        val nestedPath = ValuePath(listOf(PathSegment.Field("wrapper"), PathSegment.Field("inner")))
        val oppositePath = fieldPath("nestedSecond")
        val before = mapOf(source to record(), target to record())

        val connected =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(
                        EditIntent.SetValue(
                            location(source, "wrapper"),
                            wrapper(link(NESTED_FIRST_TYPE, NESTED_FIRST, target, null)),
                        ),
                    ),
                ),
            ).plan
        val connectedResources = before.apply(connected)

        assertEquals(
            link(NESTED_FIRST_TYPE, NESTED_FIRST, target, oppositePath),
            assertIs<DataValue.Record>(
                assertIs<DataValue.Named>(connectedResources.getValue(source).fields.getValue("wrapper")).payload,
            ).fields.getValue("inner"),
        )
        assertEquals(
            link(NESTED_SECOND_TYPE, NESTED_SECOND, source, nestedPath),
            connectedResources.getValue(target).fields.getValue("nestedSecond"),
        )

        val cleared =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    connectedResources,
                    edit(EditIntent.SetValue(location(source, "wrapper"), wrapper(DataValue.Unfilled))),
                ),
            ).plan
        val clearedResources = connectedResources.apply(cleared)

        assertEquals(DataValue.Unfilled, clearedResources.getValue(target).fields.getValue("nestedSecond"))
    }

    fun clearRemovesCollectionOccurrenceWithoutRetainingItsItemIdentity() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("parent")
        val child = ResourceId("child")
        val item = ItemId("child_occurrence")
        val itemPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item)))
        val parentPath = fieldPath("parent")
        val before =
            mapOf(
                parent to
                    record(
                        children =
                            listOf(
                                ListItem(
                                    item,
                                    link(PARENT_FIRST_TYPE, PARENT_FIRST, child, parentPath),
                                ),
                            ),
                    ),
                child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, itemPath)),
            )

        val deletedChild =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(before, edit(EditIntent.DeleteResource(child))),
            ).plan
        val retainedParent = before.apply(deletedChild).getValue(parent)
        val children = assertIs<DataValue.Named>(retainedParent.fields.getValue("children")).payload

        assertTrue(assertIs<DataValue.ListValue>(children).items.isEmpty())
        assertEquals(setOf(child), deletedChild.removedResources)

        val deletedParent =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(before, edit(EditIntent.DeleteResource(parent))),
            ).plan
        val retainedChild = before.apply(deletedParent).getValue(child)

        assertEquals(DataValue.Unfilled, retainedChild.fields.getValue("parent"))
        assertEquals(setOf(parent), deletedParent.removedResources)
    }

    fun cascadeComputesTheCompleteClosureBeforeRemovingResources() {
        val planner = planner(parentContract(RelationDeletePolicy.CASCADE, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("parent")
        val child = ResourceId("child")
        val item = ItemId("owned_child")
        val itemPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item)))
        val before =
            mapOf(
                parent to
                    record(
                        children =
                            listOf(
                                ListItem(
                                    item,
                                    link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent")),
                                ),
                            ),
                    ),
                child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, itemPath)),
            )

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(before, edit(EditIntent.DeleteResource(parent))),
            ).plan

        assertEquals(setOf(parent, child), plan.removedResources)
        assertTrue(before.apply(plan).isEmpty())
    }

    fun repeatedManyOccurrencesKeepTheirExactLocations() {
        val target = ResourceId("target")
        val source = ResourceId("source")
        val first = ItemId("first")
        val second = ItemId("second")
        val resources =
            mapOf(
                source to
                    record(
                        manyFirst =
                            listOf(
                                ListItem(first, link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                                ListItem(second, link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                            ),
                    ),
                target to record(),
            )

        val projection =
            ResourceValueMapper.project(
                ResourceValueMapper.discover(resources),
                resources,
                listOf(manyContract()),
                CATALOG,
            )

        assertTrue(projection.problems.isEmpty())
        assertEquals(
            setOf(
                ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(first))),
                ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(second))),
            ),
            projection.projections.mapNotNullTo(linkedSetOf()) { it.firstLocation },
        )
    }

    fun shrinkingRepeatedPairRemovesOnlyTheExactOldOccurrence() {
        val planner = planner(manyContract())
        val source = ResourceId("source")
        val target = ResourceId("target")
        val removed = ItemId("removed")
        val retained = ItemId("retained")
        val before =
            mapOf(
                source to
                    record(
                        manyFirst =
                            listOf(
                                ListItem(removed, link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                                ListItem(retained, link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                            ),
                    ),
                target to record(),
            )

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(before, edit(EditIntent.Remove(location(source, "manyFirst"), removed))),
            ).plan

        assertEquals(1, plan.relations.removed.size)
        assertEquals(
            ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(removed))),
            plan.relations.removed
                .single()
                .firstLocation,
        )
        assertTrue(plan.relations.created.isEmpty())
        assertTrue(plan.relations.metadataChanged.isEmpty())
    }

    fun pairingOneSidedOccurrencesReplacesTheirExactProjections() {
        val planner = planner(manyContract())
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceItem = ItemId("source_occurrence")
        val targetItem = ItemId("target_occurrence")
        val sourcePath = ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(sourceItem)))
        val targetPath = ValuePath(listOf(PathSegment.Field("manySecond"), PathSegment.Item(targetItem)))
        val sourceOccurrence = occurrence(MANY_FIRST, ValueLocation(source, sourcePath), target, null)
        val targetOccurrence = occurrence(MANY_SECOND, ValueLocation(target, targetPath), source, null)
        val before =
            mapOf(
                source to
                    record(
                        manyFirst = listOf(ListItem(sourceItem, link(MANY_FIRST_TYPE, MANY_FIRST, target, null))),
                    ),
                target to
                    record(
                        manySecond = listOf(ListItem(targetItem, link(MANY_SECOND_TYPE, MANY_SECOND, source, null))),
                    ),
            )

        val plan =
            assertIs<MutationPlanningResult.Accepted>(
                planner.plan(
                    before,
                    edit(
                        EditIntent.ConnectRelation(
                            ConnectIntent(sourceOccurrence, target, CounterpartChoice.Existing(targetOccurrence)),
                        ),
                    ),
                ),
            ).plan

        assertEquals(2, plan.relations.removed.size)
        assertEquals(
            setOf(sourcePath to null, null to targetPath),
            plan.relations.removed.mapTo(linkedSetOf()) { it.firstLocation to it.secondLocation },
        )
        assertEquals(1, plan.relations.created.size)
        assertEquals(
            sourcePath,
            plan.relations.created
                .single()
                .firstLocation,
        )
        assertEquals(
            targetPath,
            plan.relations.created
                .single()
                .secondLocation,
        )
        assertTrue(plan.relations.metadataChanged.isEmpty())
    }

    fun manyOccurrencesRejectCrossedReciprocalLocations() {
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceFirst = ItemId("source_first")
        val sourceSecond = ItemId("source_second")
        val targetFirst = ItemId("target_first")
        val targetSecond = ItemId("target_second")
        val sourceFirstPath = ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(sourceFirst)))
        val sourceSecondPath = ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(sourceSecond)))
        val targetFirstPath = ValuePath(listOf(PathSegment.Field("manySecond"), PathSegment.Item(targetFirst)))
        val targetSecondPath = ValuePath(listOf(PathSegment.Field("manySecond"), PathSegment.Item(targetSecond)))
        val resources =
            mapOf(
                source to
                    record(
                        manyFirst =
                            listOf(
                                ListItem(sourceFirst, link(MANY_FIRST_TYPE, MANY_FIRST, target, targetFirstPath)),
                                ListItem(sourceSecond, link(MANY_FIRST_TYPE, MANY_FIRST, target, targetSecondPath)),
                            ),
                    ),
                target to
                    record(
                        manySecond =
                            listOf(
                                ListItem(targetFirst, link(MANY_SECOND_TYPE, MANY_SECOND, source, sourceSecondPath)),
                                ListItem(targetSecond, link(MANY_SECOND_TYPE, MANY_SECOND, source, sourceFirstPath)),
                            ),
                    ),
            )

        val projection =
            ResourceValueMapper.project(
                ResourceValueMapper.discover(resources),
                resources,
                listOf(manyContract()),
                CATALOG,
            )

        assertTrue(projection.projections.isEmpty())
        assertEquals(
            setOf(
                ValueLocation(source, sourceFirstPath),
                ValueLocation(source, sourceSecondPath),
                ValueLocation(target, targetFirstPath),
                ValueLocation(target, targetSecondPath),
            ),
            projection.problems.mapTo(linkedSetOf()) { it.location },
        )
        assertEquals(setOf("opposite_occurrence_mismatch"), projection.problems.mapTo(linkedSetOf()) { it.code })
    }

    fun concreteSubtypeLinkIsAuthorizedByItsActualTaggedSchema() {
        val host = id("polymorphic_host")
        val message = id("polymorphic_message")
        val linkedMessage = id("linked_message")
        val linkType = id("polymorphic_link")
        val endpoint = EndpointId("polymorphic:first")
        val opposite = EndpointId("polymorphic:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(
                        host,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(FieldDeclaration(FieldOwner(host, "message"), TypeTemplate.Named(message))),
                            ),
                    ),
                    TypeDefinition(message, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(
                        linkedMessage,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(FieldDeclaration(FieldOwner(linkedMessage, "target"), TypeTemplate.Named(linkType))),
                            ),
                        parents = listOf(TypeTemplate.Named(message)),
                    ),
                    TypeDefinition(linkType, representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Named(host))),
                ),
            )
        val contract = relation(endpoint, opposite, host)
        val source = ResourceId("polymorphic_source")
        val target = ResourceId("polymorphic_target")
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(host)),
                        mapOf(
                            "message" to
                                DataValue.Named(
                                    TypeUse.Named(linkedMessage),
                                    DataValue.Record(
                                        mapOf(
                                            "target" to link(TypeUse.Named(linkType), endpoint, target, null),
                                        ),
                                    ),
                                ),
                        ),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(TypeUse.Named(host)), mapOf("message" to DataValue.Unfilled)),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        assertTrue(projection.problems.isEmpty())
        assertEquals(
            ValuePath(listOf(PathSegment.Field("message"), PathSegment.Field("target"))),
            projection.projections.single().firstLocation,
        )
    }

    fun recursiveLinkIsAuthorizedAtItsExactAuthoredDepth() {
        val host = id("recursive_host")
        val node = id("recursive_node")
        val linkType = id("recursive_link")
        val endpoint = EndpointId("recursive:first")
        val opposite = EndpointId("recursive:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(
                        host,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(FieldDeclaration(FieldOwner(host, "tree"), TypeTemplate.Named(node))),
                            ),
                    ),
                    TypeDefinition(
                        node,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(node, "next"), TypeTemplate.Nullable(TypeTemplate.Named(node))),
                                    FieldDeclaration(FieldOwner(node, "target"), TypeTemplate.Named(linkType)),
                                ),
                            ),
                    ),
                    TypeDefinition(linkType, representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Named(host))),
                ),
            )
        val contract = relation(endpoint, opposite, host)
        val source = ResourceId("recursive_source")
        val target = ResourceId("recursive_target")
        val nested =
            DataValue.Named(
                TypeUse.Named(node),
                DataValue.Record(
                    mapOf(
                        "next" to DataValue.Null,
                        "target" to link(TypeUse.Named(linkType), endpoint, target, null),
                    ),
                ),
            )
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(host)),
                        mapOf(
                            "tree" to
                                DataValue.Named(
                                    TypeUse.Named(node),
                                    DataValue.Record(
                                        mapOf(
                                            "next" to nested,
                                            "target" to DataValue.Unfilled,
                                        ),
                                    ),
                                ),
                        ),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(TypeUse.Named(host)), mapOf("tree" to DataValue.Unfilled)),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        assertTrue(projection.problems.isEmpty())
        assertEquals(
            ValuePath(
                listOf(
                    PathSegment.Field("tree"),
                    PathSegment.Field("next"),
                    PathSegment.Field("target"),
                ),
            ),
            projection.projections.single().firstLocation,
        )
    }

    fun appliedLinkTargetRejectsAResourceOutsideItsRefinedBound() {
        val resource = id("bounded_resource")
        val sourceType = id("bounded_source")
        val allowed = id("bounded_allowed")
        val disallowed = id("bounded_disallowed")
        val linkType = id("bounded_link")
        val parameter = ParameterKey(linkType, 0)
        val endpoint = EndpointId("bounded:first")
        val opposite = EndpointId("bounded:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(resource, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(
                        sourceType,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(
                                        FieldOwner(sourceType, "target"),
                                        TypeTemplate.Named(linkType, listOf(TypeTemplate.Named(allowed))),
                                    ),
                                ),
                            ),
                        parents = listOf(TypeTemplate.Named(resource)),
                    ),
                    TypeDefinition(
                        allowed,
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(resource)),
                    ),
                    TypeDefinition(
                        disallowed,
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(resource)),
                    ),
                    TypeDefinition(
                        linkType,
                        parameters = listOf(TypeParameter(parameter, "T", listOf(TypeTemplate.Named(resource)))),
                        representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(parameter)),
                    ),
                ),
            )
        val contract = relation(endpoint, opposite, resource)
        val source = ResourceId("bounded_source")
        val target = ResourceId("bounded_target")
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(sourceType)),
                        mapOf(
                            "target" to
                                link(
                                    TypeUse.Named(linkType, listOf(TypeUse.Named(allowed))),
                                    endpoint,
                                    target,
                                    null,
                                ),
                        ),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(TypeUse.Named(disallowed)), emptyMap()),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        assertTrue(projection.problems.any { it.code == "binding_target_type_mismatch" })
        assertTrue(projection.projections.isEmpty())
    }

    fun unavailableSelectedFormCannotAuthorizeAnAuthoredLink() {
        val resource = id("unavailable_resource")
        val unavailable = id("unavailable_source")
        val missing = id("missing_parent")
        val endpoint = EndpointId("unavailable:first")
        val opposite = EndpointId("unavailable:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition(resource, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(
                        unavailable,
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(missing)),
                    ),
                ),
            )
        val contract = relation(endpoint, opposite, resource)
        val source = ResourceId("unavailable_source")
        val target = ResourceId("unavailable_target")
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(unavailable)),
                        mapOf("target" to DataValue.Link(endpoint, LinkTarget(target, null))),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(TypeUse.Named(resource)), emptyMap()),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        assertTrue(projection.problems.any { it.code == "source_resource_type_mismatch" })
        assertTrue(projection.projections.isEmpty())
    }

    fun ownershipRejectsTwoImmediateOwners() {
        val contract = pairContract(setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)))
        val planner = planner(contract)
        val target = ResourceId("target")
        val first = ResourceId("first_owner")
        val second = ResourceId("second_owner")
        val resources =
            mapOf(
                first to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, target, null)),
                target to record(),
            )

        val rejected =
            assertIs<MutationPlanningResult.Rejected>(
                planner.plan(
                    resources,
                    edit(EditIntent.CreateResource(second, record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, target, null)))),
                ),
            )

        assertTrue(rejected.problems.any { it.code == "multiple_immediate_owners" })
    }

    fun oneEndpointRejectsASecondResourceRelation() {
        val planner = planner(pairContract())
        val target = ResourceId("target")
        val first = ResourceId("first_source")
        val second = ResourceId("second_source")
        val resources =
            mapOf(
                first to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, target, null)),
                target to record(),
            )

        val rejected =
            assertIs<MutationPlanningResult.Rejected>(
                planner.plan(
                    resources,
                    edit(EditIntent.CreateResource(second, record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, target, null)))),
                ),
            )

        assertTrue(rejected.problems.any { it.code == "first_endpoint_cardinality_exceeded" })
    }

    fun unrelatedInvalidResourceDoesNotBlockAValidEdit() {
        val planner = planner(pairContract())
        val invalid = ResourceId("invalid")
        val valid = ResourceId("valid")
        val invalidRecord = record().copy(fields = record().fields - "label")
        val resources = mapOf(invalid to invalidRecord, valid to record())

        val result =
            planner.plan(
                resources,
                edit(EditIntent.SetValue(location(valid, "label"), DataValue.StringValue("changed"))),
            )

        assertIs<MutationPlanningResult.Accepted>(result)
    }
}

private fun planner(contract: RelationContract) = AuthoringMutationPlanner(CATALOG, listOf(contract), BINDINGS)

private fun operationBaseline(
    resources: Map<ResourceId, AuthoringRecord>,
    contracts: List<RelationContract>,
): AuthoringView {
    val catalog =
        com.typewritermc.realm.checking.TestCatalogLease(
            generation = GENERATION,
            definitions =
                DEFINITIONS + com.typewritermc.types.StandardTypes.definitions + com.typewritermc.types.ResourceIdDefinition.definition,
            resourceRoot = NODE,
            relations = contracts,
            endpointBindings = BINDINGS,
        )
    return AuthoringView(
        catalog,
        resources,
        resources.mapValues {
            com.typewritermc.authoring.ResourceDefinitionId("test")
        },
        ResourceValueMapper.discover(resources).associateBy { it.id },
    )
}

private fun ValuePath.item(id: ItemId) = ValuePath(segments + PathSegment.Item(id))

private fun pairContract(families: Set<RelationFamilyId> = emptySet()) =
    RelationContract(
        RelationId("pair"),
        EndpointDefinition(
            PAIR_FIRST,
            EndpointSlot.First,
            TypeTemplate.Named(NODE),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            PAIR_SECOND,
            EndpointSlot.Second,
            TypeTemplate.Named(NODE),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        families,
    )

private fun parentContract(
    firstDelete: RelationDeletePolicy,
    secondDelete: RelationDeletePolicy,
) = RelationContract(
    RelationId("parent_child"),
    EndpointDefinition(
        PARENT_FIRST,
        EndpointSlot.First,
        TypeTemplate.Named(NODE),
        EndpointCardinality.One,
        firstDelete,
    ),
    EndpointDefinition(
        PARENT_SECOND,
        EndpointSlot.Second,
        TypeTemplate.Named(NODE),
        EndpointCardinality.Many,
        secondDelete,
    ),
)

private fun manyContract() =
    RelationContract(
        RelationId("many"),
        EndpointDefinition(
            MANY_FIRST,
            EndpointSlot.First,
            TypeTemplate.Named(NODE),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            MANY_SECOND,
            EndpointSlot.Second,
            TypeTemplate.Named(NODE),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
    )

private fun nestedContract() =
    RelationContract(
        RelationId("nested"),
        EndpointDefinition(
            NESTED_FIRST,
            EndpointSlot.First,
            TypeTemplate.Named(NODE),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            NESTED_SECOND,
            EndpointSlot.Second,
            TypeTemplate.Named(NODE),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
    )

private fun relation(
    first: EndpointId,
    second: EndpointId,
    resource: TypeDefinitionId,
) = RelationContract(
    RelationId("${first.value}:relation"),
    EndpointDefinition(
        first,
        EndpointSlot.First,
        TypeTemplate.Named(resource),
        EndpointCardinality.One,
        RelationDeletePolicy.CLEAR,
    ),
    EndpointDefinition(
        second,
        EndpointSlot.Second,
        TypeTemplate.Named(resource),
        EndpointCardinality.One,
        RelationDeletePolicy.CLEAR,
    ),
)

private fun edit(vararg intents: EditIntent) = PreparedEdit(GENERATION, emptyList(), intents.toList())

private fun occurrence(
    endpoint: EndpointId,
    location: ValueLocation,
    target: ResourceId,
    opposite: ValuePath?,
) = LinkOccurrence(LinkOccurrenceId(endpoint, location), location.resource, LinkTarget(target, opposite))

private fun link(
    type: TypeUse.Named,
    endpoint: EndpointId,
    target: ResourceId,
    opposite: ValuePath?,
) = DataValue.Named(type, DataValue.Link(endpoint, LinkTarget(target, opposite)))

private fun record(
    first: DataValue = DataValue.Unfilled,
    second: DataValue = DataValue.Unfilled,
    children: List<ListItem> = emptyList(),
    parent: DataValue = DataValue.Unfilled,
    manyFirst: List<ListItem> = emptyList(),
    manySecond: List<ListItem> = emptyList(),
    wrapper: DataValue = wrapper(DataValue.Unfilled),
    nestedSecond: DataValue = DataValue.Unfilled,
    label: String = "",
) = AuthoringRecord(
    TypeSelection.Complete(NODE_USE),
    mapOf(
        "first" to first,
        "second" to second,
        "children" to DataValue.Named(CHILDREN_USE, DataValue.ListValue(children)),
        "parent" to parent,
        "manyFirst" to DataValue.Named(MANY_FIRST_LIST_USE, DataValue.ListValue(manyFirst)),
        "manySecond" to DataValue.Named(MANY_SECOND_LIST_USE, DataValue.ListValue(manySecond)),
        "wrapper" to wrapper,
        "nestedSecond" to nestedSecond,
        "label" to DataValue.StringValue(label),
    ),
)

private fun Map<ResourceId, AuthoringRecord>.apply(plan: AuthoringMutationPlan): Map<ResourceId, AuthoringRecord> =
    (this + plan.resources) - plan.removedResources

private fun location(
    resource: ResourceId,
    field: String,
) = ValueLocation(resource, fieldPath(field))

private fun fieldPath(field: String) = ValuePath(listOf(PathSegment.Field(field)))

private fun id(name: String) = TypeDefinitionId(TypeId.Qualified("test", name), 1)

private fun linkDefinition(
    id: TypeDefinitionId,
    endpoint: EndpointId,
) = TypeDefinition(id, representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Named(NODE)))

private fun listDefinition(
    id: TypeDefinitionId,
    item: TypeDefinitionId,
) = TypeDefinition(
    id,
    representation = RepresentationTemplate.Sequence(TypeTemplate.Named(item), CollectionKind.List),
)

private fun wrapper(value: DataValue): DataValue = DataValue.Named(WRAPPER_USE, DataValue.Record(mapOf("inner" to value)))

private fun field(
    name: String,
    type: TypeDefinitionId,
) = FieldDeclaration(FieldOwner(NODE, name), TypeTemplate.Named(type))

private fun binding(
    endpoint: EndpointId,
    owner: TypeDefinitionId,
    field: String,
    containsCollection: Boolean,
) = EndpointBindingTemplate(
    endpoint,
    TypeTemplate.Named(NODE),
    owner,
    RelativeFieldPattern(
        buildList {
            add(FieldPatternSegment.Field(field))
            if (containsCollection) add(FieldPatternSegment.Items)
        },
    ),
    TypeTemplate.Named(NODE),
    containsCollection,
)

private val GENERATION = CatalogGeneration("catalog")
private val NODE = id("node")
private val PAIR_FIRST = EndpointId("pair:first")
private val PAIR_SECOND = EndpointId("pair:second")
private val PARENT_FIRST = EndpointId("parent:first")
private val PARENT_SECOND = EndpointId("parent:second")
private val MANY_FIRST = EndpointId("many:first")
private val MANY_SECOND = EndpointId("many:second")
private val NESTED_FIRST = EndpointId("nested:first")
private val NESTED_SECOND = EndpointId("nested:second")
private val PAIR_FIRST_TYPE = TypeUse.Named(id("pair_first_link"))
private val PAIR_SECOND_TYPE = TypeUse.Named(id("pair_second_link"))
private val PARENT_FIRST_TYPE = TypeUse.Named(id("parent_first_link"))
private val PARENT_SECOND_TYPE = TypeUse.Named(id("parent_second_link"))
private val MANY_FIRST_TYPE = TypeUse.Named(id("many_first_link"))
private val MANY_SECOND_TYPE = TypeUse.Named(id("many_second_link"))
private val NESTED_FIRST_TYPE = TypeUse.Named(id("nested_first_link"))
private val NESTED_SECOND_TYPE = TypeUse.Named(id("nested_second_link"))
private val WRAPPER_USE = TypeUse.Named(id("wrapper"))
private val CHILDREN_USE = TypeUse.Named(id("children"))
private val MANY_FIRST_LIST_USE = TypeUse.Named(id("many_first_list"))
private val MANY_SECOND_LIST_USE = TypeUse.Named(id("many_second_list"))
private val NODE_USE = TypeUse.Named(NODE)
private val DEFINITIONS =
    listOf(
        TypeDefinition(
            NODE,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        field("first", PAIR_FIRST_TYPE.definition),
                        field("second", PAIR_SECOND_TYPE.definition),
                        field("children", CHILDREN_USE.definition),
                        field("parent", PARENT_SECOND_TYPE.definition),
                        field("manyFirst", MANY_FIRST_LIST_USE.definition),
                        field("manySecond", MANY_SECOND_LIST_USE.definition),
                        field("wrapper", WRAPPER_USE.definition),
                        field("nestedSecond", NESTED_SECOND_TYPE.definition),
                        FieldDeclaration(FieldOwner(NODE, "label"), TypeTemplate.Scalar(ScalarKind.Text)),
                    ),
                ),
        ),
        linkDefinition(PAIR_FIRST_TYPE.definition, PAIR_FIRST),
        linkDefinition(PAIR_SECOND_TYPE.definition, PAIR_SECOND),
        linkDefinition(PARENT_FIRST_TYPE.definition, PARENT_FIRST),
        linkDefinition(PARENT_SECOND_TYPE.definition, PARENT_SECOND),
        linkDefinition(MANY_FIRST_TYPE.definition, MANY_FIRST),
        linkDefinition(MANY_SECOND_TYPE.definition, MANY_SECOND),
        linkDefinition(NESTED_FIRST_TYPE.definition, NESTED_FIRST),
        linkDefinition(NESTED_SECOND_TYPE.definition, NESTED_SECOND),
        TypeDefinition(
            WRAPPER_USE.definition,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(WRAPPER_USE.definition, "inner"), TypeTemplate.Named(NESTED_FIRST_TYPE.definition))),
                ),
        ),
        listDefinition(CHILDREN_USE.definition, PARENT_FIRST_TYPE.definition),
        listDefinition(MANY_FIRST_LIST_USE.definition, MANY_FIRST_TYPE.definition),
        listDefinition(MANY_SECOND_LIST_USE.definition, MANY_SECOND_TYPE.definition),
    )
private val CATALOG = DefaultCheckedCatalog(GENERATION, DEFINITIONS)
private val BINDINGS =
    listOf(
        binding(PAIR_FIRST, PAIR_FIRST_TYPE.definition, "first", false),
        binding(PAIR_SECOND, PAIR_SECOND_TYPE.definition, "second", false),
        binding(PARENT_FIRST, PARENT_FIRST_TYPE.definition, "children", true),
        binding(PARENT_SECOND, PARENT_SECOND_TYPE.definition, "parent", false),
        binding(MANY_FIRST, MANY_FIRST_TYPE.definition, "manyFirst", true),
        binding(MANY_SECOND, MANY_SECOND_TYPE.definition, "manySecond", true),
    )
private val NESTED_BINDINGS =
    listOf(
        EndpointBindingTemplate(
            NESTED_FIRST,
            TypeTemplate.Named(NODE),
            NESTED_FIRST_TYPE.definition,
            RelativeFieldPattern(
                listOf(
                    FieldPatternSegment.Field("wrapper"),
                    FieldPatternSegment.Field("inner"),
                ),
            ),
            TypeTemplate.Named(NODE),
            false,
        ),
        binding(NESTED_SECOND, NESTED_SECOND_TYPE.definition, "nestedSecond", false),
    )

val AuthoringMutationPlannerTestSuite by testSuite {
    test("placementPoliciesMatchExactOwnershipCollections") {
        AuthoringMutationPlannerTest().placementPoliciesMatchExactOwnershipCollections()
    }
    test("inverseOnlyReferencesDoNotOfferLinkedDuplication") {
        AuthoringMutationPlannerTest().inverseOnlyReferencesDoNotOfferLinkedDuplication()
    }
    test("runtimeResolvesInlineCallbacksAndPreparesAgainstWorkingValues") {
        AuthoringMutationPlannerTest().runtimeResolvesInlineCallbacksAndPreparesAgainstWorkingValues()
    }
    test("adjacentDeletesValidateRestrictionAgainstTheWholeSet") {
        AuthoringMutationPlannerTest().adjacentDeletesValidateRestrictionAgainstTheWholeSet()
    }
    test("deletionSelectionIncludesCascadeAndExplicitDescendantOnce") {
        AuthoringMutationPlannerTest().deletionSelectionIncludesCascadeAndExplicitDescendantOnce()
    }
    test("moveTransfersTheWholeSelectionThroughExactOwnershipInverses") {
        AuthoringMutationPlannerTest().moveTransfersTheWholeSelectionThroughExactOwnershipInverses()
    }
    test("impossibleBatchMoveRejectsBeforeChangingAnyResource") {
        AuthoringMutationPlannerTest().impossibleBatchMoveRejectsBeforeChangingAnyResource()
    }
    test("cloneCopiesOwnedClosureAndDeduplicatesSelectedDescendants") {
        AuthoringMutationPlannerTest().cloneCopiesOwnedClosureAndDeduplicatesSelectedDescendants()
    }
    test("clonePreservesOutsideOutgoingAndLeavesIncomingOnOriginal") {
        AuthoringMutationPlannerTest().clonePreservesOutsideOutgoingAndLeavesIncomingOnOriginal()
    }
    test("cloneRejectsOccupiedExternalScalarWithoutChangingSavedState") {
        AuthoringMutationPlannerTest().cloneRejectsOccupiedExternalScalarWithoutChangingSavedState()
    }
    test("repeatedEmbeddedCounterpartsRetainDistinctExplicitIdentities") {
        AuthoringMutationPlannerTest().repeatedEmbeddedCounterpartsRetainDistinctExplicitIdentities()
    }
    test("normalizedInverseIdentitySurvivesLaterWritesAndComposition") {
        AuthoringMutationPlannerTest().normalizedInverseIdentitySurvivesLaterWritesAndComposition()
    }
    test("counterpartClassificationPreservesBroaderServerCapabilities") {
        AuthoringMutationPlannerTest().counterpartClassificationPreservesBroaderServerCapabilities()
    }
    test("unknownConnectEndpointIsRejectedBeforeInferringACounterpart") {
        AuthoringMutationPlannerTest().unknownConnectEndpointIsRejectedBeforeInferringACounterpart()
    }
    test("insertMaterializesTheCheckedUnfilledSequenceShape") {
        AuthoringMutationPlannerTest().insertMaterializesTheCheckedUnfilledSequenceShape()
    }
    test("pendingInheritedApplicationSubstitutesItsEndpointTarget") {
        AuthoringMutationPlannerTest().pendingInheritedApplicationSubstitutesItsEndpointTarget()
    }
    test("pendingTargetsRequireProvableAppliedArguments") {
        AuthoringMutationPlannerTest().pendingTargetsRequireProvableAppliedArguments()
    }
    test("pendingTargetCanProveAnAncestorThatDoesNotUseEveryArgument") {
        AuthoringMutationPlannerTest().pendingTargetCanProveAnAncestorThatDoesNotUseEveryArgument()
    }
    test(
        "connectAndDisconnectSynchronizeBothDirectSides",
    ) { AuthoringMutationPlannerTest().connectAndDisconnectSynchronizeBothDirectSides() }
    test("scalarConnectAppendsItsDirectCollectionCounterpart") {
        AuthoringMutationPlannerTest().scalarConnectAppendsItsDirectCollectionCounterpart()
    }
    test("scalarConnectMaterializesItsUnfilledDirectCollectionCounterpart") {
        AuthoringMutationPlannerTest().scalarConnectMaterializesItsUnfilledDirectCollectionCounterpart()
    }
    test("newCounterpartEvidenceProtectsPriorStateWithoutRequiringThePlannedLocation") {
        AuthoringMutationPlannerTest().newCounterpartEvidenceProtectsPriorStateWithoutRequiringThePlannedLocation()
    }
    test("proposedCollectionOccurrenceConnectsItsDirectScalarCounterpart") {
        AuthoringMutationPlannerTest().proposedCollectionOccurrenceConnectsItsDirectScalarCounterpart()
    }
    test("proposedCollectionOccurrenceMaterializesItsUnfilledCollection") {
        AuthoringMutationPlannerTest().proposedCollectionOccurrenceMaterializesItsUnfilledCollection()
    }
    test("ordinaryLinkSetAndClearSynchronizeTheDirectCounterpart") {
        AuthoringMutationPlannerTest().ordinaryLinkSetAndClearSynchronizeTheDirectCounterpart()
    }
    test("ordinaryCollectionRemoveClearsTheDirectScalarCounterpart") {
        AuthoringMutationPlannerTest().ordinaryCollectionRemoveClearsTheDirectScalarCounterpart()
    }
    test("ordinaryContainingRecordSetAndClearSynchronizeNestedLinks") {
        AuthoringMutationPlannerTest().ordinaryContainingRecordSetAndClearSynchronizeNestedLinks()
    }
    test("clearRemovesCollectionOccurrenceWithoutRetainingItsItemIdentity") {
        AuthoringMutationPlannerTest().clearRemovesCollectionOccurrenceWithoutRetainingItsItemIdentity()
    }
    test("cascadeComputesTheCompleteClosureBeforeRemovingResources") {
        AuthoringMutationPlannerTest().cascadeComputesTheCompleteClosureBeforeRemovingResources()
    }
    test(
        "repeatedManyOccurrencesKeepTheirExactLocations",
    ) { AuthoringMutationPlannerTest().repeatedManyOccurrencesKeepTheirExactLocations() }
    test("shrinkingRepeatedPairRemovesOnlyTheExactOldOccurrence") {
        AuthoringMutationPlannerTest().shrinkingRepeatedPairRemovesOnlyTheExactOldOccurrence()
    }
    test("pairingOneSidedOccurrencesReplacesTheirExactProjections") {
        AuthoringMutationPlannerTest().pairingOneSidedOccurrencesReplacesTheirExactProjections()
    }
    test("manyOccurrencesRejectCrossedReciprocalLocations") {
        AuthoringMutationPlannerTest().manyOccurrencesRejectCrossedReciprocalLocations()
    }
    test("concreteSubtypeLinkIsAuthorizedByItsActualTaggedSchema") {
        AuthoringMutationPlannerTest().concreteSubtypeLinkIsAuthorizedByItsActualTaggedSchema()
    }
    test("recursiveLinkIsAuthorizedAtItsExactAuthoredDepth") {
        AuthoringMutationPlannerTest().recursiveLinkIsAuthorizedAtItsExactAuthoredDepth()
    }
    test("appliedLinkTargetRejectsAResourceOutsideItsRefinedBound") {
        AuthoringMutationPlannerTest().appliedLinkTargetRejectsAResourceOutsideItsRefinedBound()
    }
    test("unavailableSelectedFormCannotAuthorizeAnAuthoredLink") {
        AuthoringMutationPlannerTest().unavailableSelectedFormCannotAuthorizeAnAuthoredLink()
    }
    test("ownershipRejectsTwoImmediateOwners") { AuthoringMutationPlannerTest().ownershipRejectsTwoImmediateOwners() }
    test("oneEndpointRejectsASecondResourceRelation") { AuthoringMutationPlannerTest().oneEndpointRejectsASecondResourceRelation() }
    test(
        "unrelatedInvalidResourceDoesNotBlockAValidEdit",
    ) { AuthoringMutationPlannerTest().unrelatedInvalidResourceDoesNotBlockAValidEdit() }
}
