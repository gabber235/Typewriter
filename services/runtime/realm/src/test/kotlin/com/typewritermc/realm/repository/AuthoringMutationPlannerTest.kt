@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.repository

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.GeneratedSdkApi
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
import com.typewritermc.authoring.append
import com.typewritermc.authoring.item
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.capability
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.RuntimeOperationPreparation
import com.typewritermc.realm.authoring.WorkingViewEditContext
import com.typewritermc.types.ACYCLIC_RELATION_FAMILY_ID
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.integerScalar
import com.typewritermc.types.items
import com.typewritermc.types.link
import com.typewritermc.types.linkTarget
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.runBlocking
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

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
                            (definition.representation as RepresentationTemplate.RecordWrapper).let {
                                RepresentationTemplate.RecordWrapper(
                                    it.value.copy(
                                        fields =
                                            it.value.fields.filterNot { field ->
                                                field.owner.name ==
                                                    "manyFirst"
                                            },
                                    ),
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
                relations = listOf(manyContract()),
                endpointBindings = BINDINGS,
            )
        val resources = mapOf(id to record().let { it.copy(fields = it.fields - "manyFirst") })
        val baseline = AuthoringView(catalog, resources, emptyMap())
        try {
            val reads =
                com.typewritermc.realm.checking.CapturedAuthoringReads(
                    com.typewritermc.realm.authoring.AuthoredReadView
                        .Original(baseline),
                )
            val facts =
                com.typewritermc.realm.authoring
                    .RealmGraphFacts(
                        com.typewritermc.realm.authoring
                            .RelationReads(reads),
                    )
            facts.linkCapacityOf(id) shouldBe com.typewritermc.operations.LinkCapacity.None
        } finally {
            catalog.close()
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
                    DeclarationOwner(
                        source =
                            com.typewritermc.discovery.contributionKey(
                                com.typewritermc.imprint.ContributionSourceId("operation-test"),
                                "main",
                                com.typewritermc.imprint.ProducerId("test"),
                                com.typewritermc.imprint.ContributionName("inline"),
                            ),
                        localIdentity = "fixture.InlineOperations",
                    ),
                    com.typewritermc.imprint.ArtifactId("fixture:operations"),
                    "main",
                )
            val declaration =
                com.typewritermc.operations.collectOperation<com.typewritermc.authoring.ResourceDraft, Unit>(
                    origin,
                    "fixture.InlineOperations",
                    com.typewritermc.types.ResourceTarget
                        .Type(NODE.namedTemplate()),
                    com.typewritermc.operations.projectedSubjects(
                        com.typewritermc.authoring.draftViewProjection(NODE_USE, com.typewritermc.authoring.ResourceDrafts::bind),
                    ),
                    com.typewritermc.operations.OperationInput.None,
                    "Inline operations",
                ) { spec ->
                    with(spec) {
                        appearance { label("Add suffix") }
                        availableWhen {
                            val authoredValues =
                                drafts.map {
                                    read(
                                        com.typewritermc.authoring.boundPath<String>(
                                            location(it.id, "label"),
                                            ScalarKind.TEXT.use,
                                        ),
                                    )
                                }
                            val state = com.typewritermc.operations.authored(authoredValues)
                            if (state != skirout.editor.v1.operation.OperationAvailability.ENABLED) return@availableWhen state
                            val values = authoredValues.map { com.typewritermc.operations.requireAuthored(it) }
                            require(values.none { it == "availability-failure" }) { "Availability provider failed" }
                            skirout.editor.v1.operation.OperationAvailability.ENABLED
                        }
                        prepare {
                            for (subject in subjects) {
                                val previous =
                                    com.typewritermc.operations.requireAuthored(
                                        read(
                                            com.typewritermc.authoring.boundPath<String>(
                                                location(subject, "label"),
                                                ScalarKind.TEXT.use,
                                            ),
                                        ),
                                    )
                                require(previous != "reject") { "The complete selection cannot be changed" }
                                checkedSet(location(subject, "label"), DataValue.StringValueWrapper("$previous!"))
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
                resolved.operations.map { it.definition.presentation.label } shouldBe listOf("Add suffix")
                val partial = record().let { it.copy(fields = it.fields + ("label" to DataValue.UNFILLED)) }
                val partialResolution = runtime.resolve(invocation, GENERATION, token, mapOf(first to partial), emptySet())
                partialResolution.operations
                    .single()
                    .availability
                    .shouldBeInstanceOf<skirout.editor.v1.operation.OperationAvailability.DisabledWrapper>()
                val capability =
                    resolved.operations
                        .single()
                        .definition.id.capability
                val preview =
                    runtime
                        .prepare(
                            invocation,
                            GENERATION,
                            capability,
                            token,
                            overlay,
                            emptySet(),
                            null,
                            PreparationChoices(),
                        ).shouldBeInstanceOf<com.typewritermc.realm.authoring.OperationPreparationResult.Preview>()
                preview.edit.intents.any { it is EditIntent.SetValue && it.value == DataValue.StringValueWrapper("Draft!") } shouldBe true
                preview.edit.expectations.any {
                    it is com.typewritermc.authoring.EditExpectation.Value &&
                        it.at == location(first, "label") &&
                        it.expected == DataValue.StringValueWrapper("Draft")
                } shouldBe true
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
                (failed is com.typewritermc.realm.authoring.OperationPreparationResult.Failed) shouldBe true
                store.capture().use { it.root.resources } shouldBe resources
                var resolutionFailure: com.typewritermc.realm.authoring.OperationResolutionFailure? = null
                try {
                    runtime.resolve(invocation, GENERATION, token, mapOf(second to record(label = "availability-failure")), emptySet())
                } catch (
                    failure: com.typewritermc.realm.authoring.OperationResolutionFailure,
                ) {
                    resolutionFailure = failure
                }
                resolutionFailure?.origin shouldBe origin
                resolutionFailure?.cause?.message shouldBe "Availability provider failed"
                val routes =
                    com.typewritermc.realm.routes.ResourceOperationRoutes(
                        runtime,
                        com.typewritermc.protocol.transport
                            .RealmRouteScope("organization", "realm"),
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
                    routes
                        .resolve(
                            wire,
                        ).shouldBeInstanceOf<skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.FailedErrorWrapper>()
                wireFailure.value.diagnostics
                    .single()
                    .message
                    .contains("fixture.InlineOperations") shouldBe true
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
            planner
                .plan(
                    resources,
                    edit(EditIntent.DeleteResource(first), EditIntent.DeleteResource(second)),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        complete.removedResources shouldBe setOf(first, second)
        val separated =
            planner.plan(
                resources,
                edit(
                    EditIntent.DeleteResource(first),
                    EditIntent.SetValue(location(third, "label"), DataValue.StringValueWrapper("ordered boundary")),
                    EditIntent.DeleteResource(second),
                ),
            )
        (separated is MutationPlanningResult.Rejected) shouldBe true
    }

    fun deletionSelectionIncludesCascadeAndExplicitDescendantOnce() =
        runBlocking {
            val parent = ResourceId("delete_parent")
            val child = ResourceId("delete_child")
            val item = ItemId(value = "child")
            val resources =
                mapOf(
                    parent to
                        record(
                            children =
                                listOf(
                                    ListItem(id = item, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent"))),
                                ),
                        ),
                    child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, fieldPath("children").item(item))),
                )
            val baseline = operationBaseline(resources, listOf(parentContract(RelationDeletePolicy.CASCADE, RelationDeletePolicy.CLEAR)))
            try {
                val edit = WorkingViewEditContext(baseline, "delete-overlap")
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("delete-overlap", listOf(parent, child)),
                        PreparationChoices(),
                        edit,
                    )
                session.delete(listOf(parent, child))
                val result = edit.finish()
                edit.session.resources.isEmpty() shouldBe true
                result.intents.filterIsInstance<EditIntent.DeleteResource>().size shouldBe 2
            } finally {
                baseline.catalog.close()
            }
        }

    fun moveTransfersTheWholeSelectionThroughExactOwnershipInverses() =
        runBlocking {
            val root = ResourceId("move_root")
            val from = ResourceId("move_from")
            val to = ResourceId("move_to")
            val first = ResourceId("move_first")
            val second = ResourceId("move_second")
            val firstItem = ItemId(value = "first")
            val secondItem = ItemId(value = "second")
            val fromItem = ItemId(value = "from")
            val toItem = ItemId(value = "to")
            val resources =
                mapOf(
                    // Both owners are owned themselves, as every ownable resource must be.
                    root to
                        record(
                            children =
                                listOf(
                                    ListItem(id = fromItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, from, fieldPath("parent"))),
                                    ListItem(id = toItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, to, fieldPath("parent"))),
                                ),
                        ),
                    from to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, root, fieldPath("children").item(fromItem)),
                            children =
                                listOf(
                                    ListItem(id = firstItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, first, fieldPath("parent"))),
                                    ListItem(id = secondItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, second, fieldPath("parent"))),
                                ),
                        ),
                    to to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, root, fieldPath("children").item(toItem))),
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
                val edit = WorkingViewEditContext(baseline, "move-selection")
                val origin = OperationOrigin(from, baseline.links.values.filter { it.source == from })
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("move-selection", listOf(first, second), origin),
                        PreparationChoices(),
                        edit,
                    )
                session.move(listOf(first, second), to, null)
                val prepared = edit.finish()
                prepared.intents.filterIsInstance<EditIntent.ConnectRelation>().all {
                    it.intent.counterpart is CounterpartChoice.Existing
                } shouldBe true
                val final = ResourceValueMapper.discover(edit.session.resources)
                final.filter { it.source == to && it.target.resource != root }.map { it.target.resource }.toSet() shouldBe
                    setOf(first, second)
                final.filter { it.source == from }.map { it.target.resource } shouldBe listOf(root)
                (
                    edit.session.resources
                        .getValue(first)
                        .fields
                        .getValue("label") as DataValue.StringValueWrapper
                ).value shouldBe "first"
                baseline.resources shouldBe resources
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
                val edit = WorkingViewEditContext(baseline, "impossible-move")
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("impossible-move", listOf(childA, childB)),
                        PreparationChoices(),
                        edit,
                    )
                var rejected = false
                try {
                    session.move(listOf(childA, childB), destination, null)
                } catch (
                    _: IllegalArgumentException,
                ) {
                    rejected =
                        true
                }
                rejected shouldBe true
                edit.session.intents.isEmpty() shouldBe true
                edit.session.resources shouldBe resources
            } finally {
                baseline.catalog.close()
            }
        }

    fun cloneCopiesOwnedClosureAndDeduplicatesSelectedDescendants() =
        runBlocking {
            val root = ResourceId("clone_root")
            val book = ResourceId("clone_book")
            val page = ResourceId("clone_page")
            val element = ResourceId("clone_element")
            val outside = ResourceId("clone_shared")
            val rootItem = ItemId(value = "root")
            val bookItem = ItemId(value = "book")
            val outsideItem = ItemId(value = "outside")
            val pageItem = ItemId(value = "page")
            val elementItem = ItemId(value = "element")
            val resources =
                mapOf(
                    // Every node is ownable, so the top node owns itself; the cloned book and the outside resource
                    // are owned by it, as every ownable resource must be.
                    root to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, root, fieldPath("children").item(rootItem)),
                            children =
                                listOf(
                                    ListItem(id = rootItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, root, fieldPath("parent"))),
                                    ListItem(id = bookItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, book, fieldPath("parent"))),
                                    ListItem(id = outsideItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, outside, fieldPath("parent"))),
                                ),
                        ),
                    book to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, root, fieldPath("children").item(bookItem)),
                            children =
                                listOf(
                                    ListItem(id = pageItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, page, fieldPath("parent"))),
                                ),
                            manyFirst =
                                listOf(
                                    ListItem(
                                        id = pageItem,
                                        value =
                                            link(
                                                MANY_FIRST_TYPE,
                                                MANY_FIRST,
                                                outside,
                                                fieldPath("manySecond").item(ItemId(value = "outside")),
                                            ),
                                    ),
                                ),
                        ),
                    page to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, book, fieldPath("children").item(pageItem)),
                            children =
                                listOf(
                                    ListItem(id = elementItem, value = link(PARENT_FIRST_TYPE, PARENT_FIRST, element, fieldPath("parent"))),
                                ),
                        ),
                    element to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, page, fieldPath("children").item(elementItem))),
                    outside to
                        record(
                            parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, root, fieldPath("children").item(outsideItem)),
                            manySecond =
                                listOf(
                                    ListItem(
                                        id = ItemId(value = "outside"),
                                        value = link(MANY_SECOND_TYPE, MANY_SECOND, book, fieldPath("manyFirst").item(pageItem)),
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
                val edit = WorkingViewEditContext(baseline, "clone-closure")
                val session =
                    RuntimeOperationPreparation(
                        OperationInvocation("clone-closure", listOf(book, page)),
                        PreparationChoices(),
                        edit,
                    )
                val result = session.duplicate(listOf(book, page))
                val final = edit.finish()
                result.size shouldBe 2
                final.intents.filterIsInstance<EditIntent.CreateResource>().size shouldBe 3
                edit.session.resources.size shouldBe 8
                val copy = edit.session.resources.getValue(result[0])
                val copiedChildItem =
                    (
                        (
                            copy.fields.getValue(
                                "children",
                            ) as DataValue.NamedWrapper
                        ).payload as DataValue.ListValueWrapper
                    ).items.single().id
                val copiedOrdinaryItem =
                    (
                        (
                            copy.fields.getValue(
                                "manyFirst",
                            ) as DataValue.NamedWrapper
                        ).payload as DataValue.ListValueWrapper
                    ).items.single().id
                (copiedChildItem != copiedOrdinaryItem) shouldBe true
                baseline.resources shouldBe resources
                val copied =
                    ResourceValueMapper.project(
                        ResourceValueMapper.discover(edit.session.resources),
                        edit.session.resources,
                        baseline.catalog.relations,
                        baseline.catalog.checked,
                    )
                copied.problems.isEmpty() shouldBe true
                copied.projections.any { it.first == result[0] && it.second == result[1] } shouldBe true
            } finally {
                baseline.catalog.close()
            }
        }

    fun clonePreservesOutsideOutgoingAndLeavesIncomingOnOriginal() =
        runBlocking {
            val source = ResourceId("copy_source")
            val outside = ResourceId("copy_outside")
            val incoming = ResourceId("copy_incoming")
            val outgoingItem = ItemId(value = "outgoing")
            val outsideItem = ItemId(value = "outside_inverse")
            val incomingItem = ItemId(value = "incoming")
            val sourceInverse = ItemId(value = "source_inverse")
            val resources =
                mapOf(
                    source to
                        record(
                            manyFirst =
                                listOf(
                                    ListItem(
                                        id = outgoingItem,
                                        value = link(MANY_FIRST_TYPE, MANY_FIRST, outside, fieldPath("manySecond").item(outsideItem)),
                                    ),
                                ),
                            manySecond =
                                listOf(
                                    ListItem(
                                        id = sourceInverse,
                                        value = link(MANY_SECOND_TYPE, MANY_SECOND, incoming, fieldPath("manyFirst").item(incomingItem)),
                                    ),
                                ),
                        ),
                    outside to
                        record(
                            manySecond =
                                listOf(
                                    ListItem(
                                        id = outsideItem,
                                        value = link(MANY_SECOND_TYPE, MANY_SECOND, source, fieldPath("manyFirst").item(outgoingItem)),
                                    ),
                                ),
                        ),
                    incoming to
                        record(
                            manyFirst =
                                listOf(
                                    ListItem(
                                        id = incomingItem,
                                        value = link(MANY_FIRST_TYPE, MANY_FIRST, source, fieldPath("manySecond").item(sourceInverse)),
                                    ),
                                ),
                        ),
                )
            val baseline = operationBaseline(resources, listOf(manyContract()))
            try {
                val edit = WorkingViewEditContext(baseline, "clone-outside")
                val session =
                    RuntimeOperationPreparation(OperationInvocation("clone-outside", listOf(source)), PreparationChoices(), edit)
                val copy = session.duplicate(listOf(source)).single()
                edit.finish()
                val links = ResourceValueMapper.discover(edit.session.resources)
                links.any { it.source == copy && it.target.resource == outside } shouldBe true
                links.none { it.source == incoming && it.target.resource == copy } shouldBe true
                edit.session.resources.getValue(incoming) shouldBe resources.getValue(incoming)
                links.none { it.source == copy && it.target.resource == incoming } shouldBe true
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
                val edit = WorkingViewEditContext(baseline, "clone-scalar")
                val session =
                    RuntimeOperationPreparation(OperationInvocation("clone-scalar", listOf(source)), PreparationChoices(), edit)
                var rejected = false
                try {
                    session.duplicate(listOf(source))
                } catch (_: IllegalArgumentException) {
                    rejected = true
                }
                rejected shouldBe true
                baseline.resources shouldBe resources
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
                            RepresentationTemplate.createSequence(item = WRAPPER_USE.definition.template(), kind = CollectionKind.LIST),
                    )
                } else {
                    definition
                }
            }
        val catalog =
            com.typewritermc.realm.checking.TestCatalogLease(
                generation = GENERATION,
                definitions = definitions,
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
                                mapOf("inner" to DataValue.UNFILLED),
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
            inserts.size shouldBe 2
            (inserts[0].item.id != inserts[1].item.id) shouldBe true
            prepared.intents.filterIsInstance<EditIntent.ConnectRelation>().all {
                it.intent.counterpart is CounterpartChoice.Existing
            } shouldBe
                true
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
                relations = listOf(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR)),
                endpointBindings = BINDINGS,
            )
        val baseline =
            com.typewritermc.realm.authoring.AuthoringView(
                catalog,
                resources,
                emptyMap(),
            )
        try {
            val session = AuthoringPlanningSession(baseline, "normalization-test")
            session.append(
                EditIntent.ConnectRelation(ConnectIntent(occurrence(PARENT_SECOND, location(child, "parent"), parent, null), parent, null)),
            )
            val inverse = ResourceValueMapper.discover(session.resources).single { it.source == parent }
            ((session.intents.single() as EditIntent.ConnectRelation).intent.counterpart is CounterpartChoice.Existing) shouldBe true
            session.append(EditIntent.SetValue(location(child, "label"), DataValue.StringValueWrapper("later write")))
            val (prepared, plan) = session.finish()
            resources + plan.resources - plan.removedResources shouldBe session.resources
            val composed =
                prepared.copy(
                    intents =
                        listOf(EditIntent.SetValue(location(parent, "label"), DataValue.StringValueWrapper("earlier draft"))) +
                            prepared.intents,
                )
            val final =
                session.planner
                    .plan(resources, composed)
                    .shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                    .plan
            ResourceValueMapper.discover(resources + final.resources).any { it.id == inverse.id } shouldBe true
        } finally {
            catalog.close()
        }
    }

    fun counterpartClassificationPreservesBroaderServerCapabilities() {
        val resource = ResourceId("counterpart")
        ResourceValueMapper.counterpartBinding(PAIR_SECOND, resource, record(), CATALOG) shouldBe
            CounterpartBinding.Scalar(location(resource, "second"))
        ResourceValueMapper.counterpartBinding(PARENT_FIRST, resource, record(), CATALOG) shouldBe
            CounterpartBinding.Collection(location(resource, "children"))
        ResourceValueMapper.counterpartBinding(NESTED_FIRST, resource, record(), CATALOG) shouldBe
            CounterpartBinding.Scalar(ValueLocation(resource, ValuePath(listOf(PathSegment.Field("wrapper"), PathSegment.Field("inner")))))
        ResourceValueMapper.counterpartBinding(EndpointId(value = "absent"), resource, record(), CATALOG) shouldBe
            CounterpartBinding.Missing

        val node = DEFINITIONS.single { it.id == NODE }
        val shape = node.representation as RepresentationTemplate.RecordWrapper
        val ambiguous =
            node.copy(
                representation =
                    RepresentationTemplate.RecordWrapper(
                        shape.value.copy(
                            fields =
                                shape.value.fields + field("secondAlternative", PAIR_SECOND_TYPE.definition),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(GENERATION, DEFINITIONS.map { if (it.id == NODE) ambiguous else it })
        val target = record().copy(fields = record().fields + ("secondAlternative" to DataValue.UNFILLED))
        ResourceValueMapper.counterpartBinding(PAIR_SECOND, resource, target, catalog) shouldBe CounterpartBinding.ExplicitChoice
    }

    fun unknownConnectEndpointIsRejectedBeforeInferringACounterpart() {
        val source = ResourceId("source")
        val target = ResourceId("target")
        val result =
            planner(pairContract())
                .plan(
                    mapOf(source to record(), target to record()),
                    edit(
                        EditIntent.ConnectRelation(
                            ConnectIntent(occurrence(EndpointId(value = "absent"), location(source, "first"), target, null), target, null),
                        ),
                    ),
                ).shouldBeInstanceOf<MutationPlanningResult.Rejected>()
        result.problems.map { it.code } shouldBe listOf("unknown_endpoint")
    }

    fun insertMaterializesTheCheckedUnfilledSequenceShape() {
        listOf(CollectionKind.LIST to "list", CollectionKind.SET to "set").forEach { (kind, kindName) ->
            val rootType = id("insert_${kindName}_root")
            val collectionType = id("insert_${kindName}_collection")
            val rootUse = rootType.namedUse()
            val collectionUse = collectionType.namedUse()
            val catalog =
                DefaultCheckedCatalog(
                    GENERATION,
                    listOf(
                        TypeDefinition.partial(
                            id = rootType,
                            representation =
                                RepresentationTemplate.createRecord(
                                    fields =
                                        listOf(
                                            FieldDeclaration.partial(
                                                owner = FieldOwner(definition = rootType, name = "values"),
                                                type = collectionType.template(),
                                            ),
                                        ),
                                    abstract_ = false,
                                ),
                        ),
                        TypeDefinition.partial(
                            id = collectionType,
                            representation = RepresentationTemplate.createSequence(item = ScalarKind.TEXT.template, kind = kind),
                        ),
                    ),
                )
            val planner = AuthoringMutationPlanner(catalog, emptyList())
            val resource = ResourceId("insert_$kindName")
            val location = location(resource, "values")
            val before =
                mapOf(
                    resource to
                        AuthoringRecord(
                            TypeSelection.Complete(rootUse),
                            mapOf("values" to DataValue.UNFILLED),
                        ),
                )
            val item = ListItem(id = ItemId(value = "stable_item"), value = DataValue.StringValueWrapper("value"))
            val accepted =
                planner
                    .plan(
                        before,
                        edit(EditIntent.Insert(location, null, item)),
                    ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                    .plan
            val collection =
                before
                    .apply(accepted)
                    .getValue(resource)
                    .fields
                    .getValue("values")
                    .shouldBeInstanceOf<DataValue.NamedWrapper>()

            collection.actualType shouldBe collectionUse
            when (kind) {
                CollectionKind.LIST -> collection.payload.shouldBeInstanceOf<DataValue.ListValueWrapper>().items shouldBe listOf(item)
                CollectionKind.SET -> collection.payload.shouldBeInstanceOf<DataValue.SetValueWrapper>().items shouldBe listOf(item)
                else -> unknownVariant(kind)
            }
            planner
                .plan(
                    before,
                    edit(
                        EditIntent.Insert(
                            location,
                            null,
                            ListItem(id = ItemId(value = "invalid_item"), value = DataValue.BooleanWrapper(true)),
                        ),
                    ),
                ).shouldBeInstanceOf<MutationPlanningResult.Rejected>()
        }
    }

    fun pendingInheritedApplicationSubstitutesItsEndpointTarget() {
        val base = id("generic_base")
        val derived = id("generic_derived")
        val target = id("generic_target")
        val link = id("generic_link")
        val baseParameter = ParameterKey(owner = base, index = 0)
        val derivedParameter = ParameterKey(owner = derived, index = 0)
        val linkParameter = ParameterKey(owner = link, index = 0)
        val endpoint = EndpointId(value = "generic:target")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = base,
                        parameters = listOf(TypeParameter.partial(key = baseParameter, name = "T")),
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = base, name = "link"),
                                            type = link.template(listOf(baseParameter.template)),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                    ),
                    TypeDefinition(
                        id = derived,
                        parameters = listOf(TypeParameter.partial(key = derivedParameter, name = "T")),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(base.namedTemplate(listOf(derivedParameter.template))),
                    ),
                    TypeDefinition.partial(
                        id = target,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = link,
                        parameters = listOf(TypeParameter.partial(key = linkParameter, name = "T")),
                        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = linkParameter.template),
                    ),
                ),
            )
        val resource = ResourceId("source")
        val targetUse = target.use()
        val record =
            AuthoringRecord(
                TypeSelection.Pending(derived, listOf(ArgumentSelection.Chosen(targetUse))),
                mapOf("link" to DataValue.UNFILLED),
            )
        val occurrence =
            occurrence(
                endpoint,
                location(resource, "link"),
                ResourceId("target"),
                null,
            )
        ResourceValueMapper.expectedTarget(occurrence, record, catalog) shouldBe targetUse
    }

    fun pendingTargetsRequireProvableAppliedArguments() {
        val sourceType = id("partial_source")
        val config = id("partial_config")
        val linkType = id("partial_link")
        val first = ParameterKey(owner = config, index = 0)
        val second = ParameterKey(owner = config, index = 1)
        val linkParameter = ParameterKey(owner = linkType, index = 0)
        val endpoint = EndpointId(value = "partial:first")
        val opposite = EndpointId(value = "partial:second")
        val text = ScalarKind.TEXT.use
        val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
        val expected = config.use(listOf(text, integer))
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = sourceType,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = sourceType, name = "target"),
                                            type =
                                                linkType.template(
                                                    listOf(
                                                        config.template(
                                                            listOf(
                                                                ScalarKind.TEXT.template,
                                                                integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = config,
                        parameters =
                            listOf(
                                TypeParameter.partial(key = first, name = "T"),
                                TypeParameter.partial(key = second, name = "U"),
                            ),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = linkType,
                        parameters = listOf(TypeParameter.partial(key = linkParameter, name = "T")),
                        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = linkParameter.template),
                    ),
                ),
            )
        val contract =
            RelationContract(
                RelationId("partial:relation"),
                EndpointDefinition(
                    endpoint,
                    EndpointSlot.First,
                    sourceType.namedTemplate(),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
                EndpointDefinition(
                    opposite,
                    EndpointSlot.Second,
                    config.namedTemplate(
                        listOf(
                            ScalarKind.TEXT.template,
                            integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
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
                TypeSelection.Complete(sourceType.namedUse()),
                mapOf("target" to link(linkType.namedUse(listOf(expected)), endpoint, target, null)),
            )

        listOf(
            TypeSelection.Pending(config, listOf(ArgumentSelection.Chosen(integer), ArgumentSelection.Unfilled)),
            TypeSelection.Pending(config, listOf(ArgumentSelection.Chosen(text), ArgumentSelection.Unfilled)),
        ).forEach { selection ->
            val resources = mapOf(source to sourceRecord, target to AuthoringRecord(selection, emptyMap()))
            val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

            projection.projections.isEmpty() shouldBe true
            projection.problems.any { it.location == location(source, "target") && it.code == "target_resource_type_mismatch" } shouldBe
                true
        }
    }

    fun pendingTargetCanProveAnAncestorThatDoesNotUseEveryArgument() {
        val sourceType = id("partial_ancestor_source")
        val view = id("partial_view")
        val derived = id("partial_derived")
        val linkType = id("partial_ancestor_link")
        val viewParameter = ParameterKey(owner = view, index = 0)
        val first = ParameterKey(owner = derived, index = 0)
        val unused = ParameterKey(owner = derived, index = 1)
        val linkParameter = ParameterKey(owner = linkType, index = 0)
        val endpoint = EndpointId(value = "partial_ancestor:first")
        val opposite = EndpointId(value = "partial_ancestor:second")
        val text = ScalarKind.TEXT.use
        val expected = view.use(listOf(text))
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = sourceType,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = sourceType, name = "target"),
                                            type = linkType.template(listOf(view.template(listOf(ScalarKind.TEXT.template)))),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = view,
                        parameters = listOf(TypeParameter.partial(key = viewParameter, name = "T")),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition(
                        id = derived,
                        parameters =
                            listOf(
                                TypeParameter.partial(key = first, name = "T"),
                                TypeParameter.partial(key = unused, name = "Unused"),
                            ),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(view.namedTemplate(listOf(first.template))),
                    ),
                    TypeDefinition.partial(
                        id = linkType,
                        parameters = listOf(TypeParameter.partial(key = linkParameter, name = "T")),
                        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = linkParameter.template),
                    ),
                ),
            )
        val contract =
            RelationContract(
                RelationId("partial_ancestor:relation"),
                EndpointDefinition(
                    endpoint,
                    EndpointSlot.First,
                    sourceType.namedTemplate(),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
                EndpointDefinition(
                    opposite,
                    EndpointSlot.Second,
                    view.namedTemplate(listOf(ScalarKind.TEXT.template)),
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
                        TypeSelection.Complete(sourceType.namedUse()),
                        mapOf("target" to link(linkType.namedUse(listOf(expected)), endpoint, target, null)),
                    ),
                target to
                    AuthoringRecord(
                        TypeSelection.Pending(derived, listOf(ArgumentSelection.Chosen(text), ArgumentSelection.Unfilled)),
                        emptyMap(),
                    ),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        projection.projections.size shouldBe 1
        projection.problems.isEmpty() shouldBe true
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
            planner
                .plan(
                    before,
                    edit(
                        EditIntent.ConnectRelation(
                            ConnectIntent(sourceOccurrence, target, CounterpartChoice.Existing(targetOccurrence)),
                        ),
                    ),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val connectedResources = before.apply(connected)

        connectedResources.getValue(source).fields.getValue("first") shouldBe link(PAIR_FIRST_TYPE, PAIR_FIRST, target, targetLocation.path)
        connectedResources.getValue(target).fields.getValue("second") shouldBe
            link(PAIR_SECOND_TYPE, PAIR_SECOND, source, sourceLocation.path)
        connected.relations.created.size shouldBe 1

        val disconnected =
            planner
                .plan(
                    connectedResources,
                    edit(EditIntent.DisconnectRelation(sourceOccurrence.id)),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val disconnectedResources = connectedResources.apply(disconnected)

        disconnectedResources.getValue(source).fields.getValue("first") shouldBe DataValue.UNFILLED
        disconnectedResources.getValue(target).fields.getValue("second") shouldBe DataValue.UNFILLED
        disconnected.relations.removed.size shouldBe 1
    }

    fun scalarConnectAppendsItsDirectCollectionCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("page")
        val child = ResourceId("element")
        val sourceLocation = location(child, "parent")
        val source = occurrence(PARENT_SECOND, sourceLocation, parent, null)
        val before = mapOf(parent to record(), child to record())

        val plan =
            planner
                .plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, parent, null))),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val resources = before.apply(plan)
        val children =
            resources
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items

        children.size shouldBe 1
        val counterpartPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(children.single().id)))
        resources.getValue(child).fields.getValue("parent") shouldBe link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, counterpartPath)
        children.single().value shouldBe link(PARENT_FIRST_TYPE, PARENT_FIRST, child, sourceLocation.path)
    }

    fun scalarConnectMaterializesItsUnfilledDirectCollectionCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("page")
        val child = ResourceId("element")
        val sourceLocation = location(child, "parent")
        val source = occurrence(PARENT_SECOND, sourceLocation, parent, null)
        val parentRecord = record().copy(fields = record().fields + ("children" to DataValue.UNFILLED))
        val before = mapOf(parent to parentRecord, child to record())

        val plan =
            planner
                .plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, parent, null))),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val resources = before.apply(plan)
        val children =
            resources
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items

        children.size shouldBe 1
        children
            .single()
            .value
            .shouldBeInstanceOf<DataValue.NamedWrapper>()
            .payload
            .shouldBeInstanceOf<DataValue.LinkWrapper>()
            .linkTarget.resource shouldBe
            child
    }

    fun newCounterpartEvidenceProtectsPriorStateWithoutRequiringThePlannedLocation() {
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceLocation = location(source, "nestedSecond")
        val containing = location(target, "children")
        val generatedItem = ItemId(value = "relation:server_generated")
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
                                        mapOf("inner" to DataValue.UNFILLED),
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
        evidence.any { it is com.typewritermc.authoring.EditExpectation.Value && it.at == sourceLocation } shouldBe true
        evidence.any { it is com.typewritermc.authoring.EditExpectation.Configuration && it.at == containing } shouldBe true
        evidence.any { it is com.typewritermc.authoring.EditExpectation.Links && it.resource == source } shouldBe true
        evidence.any { it is com.typewritermc.authoring.EditExpectation.Links && it.resource == target } shouldBe true
    }

    fun proposedCollectionOccurrenceConnectsItsDirectScalarCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("book")
        val child = ResourceId("page")
        val item = ItemId(value = "page_occurrence")
        val sourceLocation =
            ValueLocation(parent, ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item))))
        val source = occurrence(PARENT_FIRST, sourceLocation, child, null)
        val before = mapOf(parent to record(), child to record())

        val plan =
            planner
                .plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, child, null))),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val resources = before.apply(plan)
        val children =
            resources
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items

        children.map(ListItem::id) shouldBe listOf(item)
        children.single().value shouldBe link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent"))
        resources.getValue(child).fields.getValue("parent") shouldBe link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, sourceLocation.path)
    }

    fun proposedCollectionOccurrenceMaterializesItsUnfilledCollection() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("book")
        val child = ResourceId("page")
        val item = ItemId(value = "page_occurrence")
        val sourceLocation =
            ValueLocation(parent, ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item))))
        val source = occurrence(PARENT_FIRST, sourceLocation, child, null)
        val parentRecord = record().copy(fields = record().fields + ("children" to DataValue.UNFILLED))
        val before = mapOf(parent to parentRecord, child to record())

        val plan =
            planner
                .plan(
                    before,
                    edit(EditIntent.ConnectRelation(ConnectIntent(source, child, null))),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val resources = before.apply(plan)
        val children =
            resources
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items

        children.map(ListItem::id) shouldBe listOf(item)
        resources.getValue(child).fields.getValue("parent") shouldBe link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, sourceLocation.path)
    }

    fun ordinaryLinkSetAndClearSynchronizeTheDirectCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("page")
        val child = ResourceId("element")
        val parentLocation = location(child, "parent")
        val before = mapOf(parent to record(), child to record())

        val connected =
            planner
                .plan(
                    before,
                    edit(
                        EditIntent.SetValue(
                            parentLocation,
                            link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, null),
                        ),
                    ),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val connectedResources = before.apply(connected)
        val children =
            connectedResources
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items

        children.size shouldBe 1
        val cleared =
            planner
                .plan(
                    connectedResources,
                    edit(EditIntent.SetValue(parentLocation, DataValue.UNFILLED)),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val clearedResources = connectedResources.apply(cleared)
        val remaining =
            clearedResources
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items

        remaining.isEmpty() shouldBe true
        clearedResources.getValue(child).fields.getValue("parent") shouldBe DataValue.UNFILLED
    }

    fun ordinaryCollectionRemoveClearsTheDirectScalarCounterpart() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("book")
        val child = ResourceId("page")
        val item = ItemId(value = "page_occurrence")
        val itemPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item)))
        val resources =
            mapOf(
                parent to
                    record(
                        children =
                            listOf(
                                ListItem(
                                    id = item,
                                    value = link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent")),
                                ),
                            ),
                    ),
                child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, itemPath)),
            )

        val plan =
            planner
                .plan(
                    resources,
                    edit(EditIntent.Remove(location(parent, "children"), item)),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val next = resources.apply(plan)

        next.getValue(child).fields.getValue("parent") shouldBe DataValue.UNFILLED
        val items =
            next
                .getValue(
                    parent,
                ).fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload
                .shouldBeInstanceOf<DataValue.ListValueWrapper>()
                .items
        items.isEmpty() shouldBe true
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
            planner
                .plan(
                    before,
                    edit(
                        EditIntent.SetValue(
                            location(source, "wrapper"),
                            wrapper(link(NESTED_FIRST_TYPE, NESTED_FIRST, target, null)),
                        ),
                    ),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val connectedResources = before.apply(connected)

        connectedResources
            .getValue(
                source,
            ).fields
            .getValue(
                "wrapper",
            ).shouldBeInstanceOf<DataValue.NamedWrapper>()
            .payload
            .shouldBeInstanceOf<DataValue.RecordWrapper>()
            .field("inner") shouldBe
            link(NESTED_FIRST_TYPE, NESTED_FIRST, target, oppositePath)
        connectedResources.getValue(target).fields.getValue("nestedSecond") shouldBe
            link(NESTED_SECOND_TYPE, NESTED_SECOND, source, nestedPath)

        val cleared =
            planner
                .plan(
                    connectedResources,
                    edit(EditIntent.SetValue(location(source, "wrapper"), wrapper(DataValue.UNFILLED))),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan
        val clearedResources = connectedResources.apply(cleared)

        clearedResources.getValue(target).fields.getValue("nestedSecond") shouldBe DataValue.UNFILLED
    }

    fun clearRemovesCollectionOccurrenceWithoutRetainingItsItemIdentity() {
        val planner = planner(parentContract(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("parent")
        val child = ResourceId("child")
        val item = ItemId(value = "child_occurrence")
        val itemPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item)))
        val parentPath = fieldPath("parent")
        val before =
            mapOf(
                parent to
                    record(
                        children =
                            listOf(
                                ListItem(
                                    id = item,
                                    value = link(PARENT_FIRST_TYPE, PARENT_FIRST, child, parentPath),
                                ),
                            ),
                    ),
                child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, itemPath)),
            )

        val deletedChild =
            planner.plan(before, edit(EditIntent.DeleteResource(child))).shouldBeInstanceOf<MutationPlanningResult.Accepted>().plan
        val retainedParent = before.apply(deletedChild).getValue(parent)
        val children =
            retainedParent.fields
                .getValue("children")
                .shouldBeInstanceOf<DataValue.NamedWrapper>()
                .payload

        children.shouldBeInstanceOf<DataValue.ListValueWrapper>().items.isEmpty() shouldBe true
        deletedChild.removedResources shouldBe setOf(child)

        val deletedParent =
            planner.plan(before, edit(EditIntent.DeleteResource(parent))).shouldBeInstanceOf<MutationPlanningResult.Accepted>().plan
        val retainedChild = before.apply(deletedParent).getValue(child)

        retainedChild.fields.getValue("parent") shouldBe DataValue.UNFILLED
        deletedParent.removedResources shouldBe setOf(parent)
    }

    fun cascadeComputesTheCompleteClosureBeforeRemovingResources() {
        val planner = planner(parentContract(RelationDeletePolicy.CASCADE, RelationDeletePolicy.CLEAR))
        val parent = ResourceId("parent")
        val child = ResourceId("child")
        val item = ItemId(value = "owned_child")
        val itemPath = ValuePath(listOf(PathSegment.Field("children"), PathSegment.Item(item)))
        val before =
            mapOf(
                parent to
                    record(
                        children =
                            listOf(
                                ListItem(
                                    id = item,
                                    value = link(PARENT_FIRST_TYPE, PARENT_FIRST, child, fieldPath("parent")),
                                ),
                            ),
                    ),
                child to record(parent = link(PARENT_SECOND_TYPE, PARENT_SECOND, parent, itemPath)),
            )

        val plan =
            planner.plan(before, edit(EditIntent.DeleteResource(parent))).shouldBeInstanceOf<MutationPlanningResult.Accepted>().plan

        plan.removedResources shouldBe setOf(parent, child)
        before.apply(plan).isEmpty() shouldBe true
    }

    fun repeatedManyOccurrencesKeepTheirExactLocations() {
        val target = ResourceId("target")
        val source = ResourceId("source")
        val first = ItemId(value = "first")
        val second = ItemId(value = "second")
        val resources =
            mapOf(
                source to
                    record(
                        manyFirst =
                            listOf(
                                ListItem(id = first, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                                ListItem(id = second, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
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

        projection.problems.isEmpty() shouldBe true
        projection.projections.mapNotNullTo(linkedSetOf()) { it.firstLocation } shouldBe
            setOf(
                ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(first))),
                ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(second))),
            )
    }

    fun shrinkingRepeatedPairRemovesOnlyTheExactOldOccurrence() {
        val planner = planner(manyContract())
        val source = ResourceId("source")
        val target = ResourceId("target")
        val removed = ItemId(value = "removed")
        val retained = ItemId(value = "retained")
        val before =
            mapOf(
                source to
                    record(
                        manyFirst =
                            listOf(
                                ListItem(id = removed, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                                ListItem(id = retained, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, null)),
                            ),
                    ),
                target to record(),
            )

        val plan =
            planner
                .plan(
                    before,
                    edit(EditIntent.Remove(location(source, "manyFirst"), removed)),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan

        plan.relations.removed.size shouldBe 1
        plan.relations.removed
            .single()
            .firstLocation shouldBe ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(removed)))
        plan.relations.created.isEmpty() shouldBe true
        plan.relations.metadataChanged.isEmpty() shouldBe true
    }

    fun pairingOneSidedOccurrencesReplacesTheirExactProjections() {
        val planner = planner(manyContract())
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceItem = ItemId(value = "source_occurrence")
        val targetItem = ItemId(value = "target_occurrence")
        val sourcePath = ValuePath(listOf(PathSegment.Field("manyFirst"), PathSegment.Item(sourceItem)))
        val targetPath = ValuePath(listOf(PathSegment.Field("manySecond"), PathSegment.Item(targetItem)))
        val sourceOccurrence = occurrence(MANY_FIRST, ValueLocation(source, sourcePath), target, null)
        val targetOccurrence = occurrence(MANY_SECOND, ValueLocation(target, targetPath), source, null)
        val before =
            mapOf(
                source to
                    record(
                        manyFirst = listOf(ListItem(id = sourceItem, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, null))),
                    ),
                target to
                    record(
                        manySecond = listOf(ListItem(id = targetItem, value = link(MANY_SECOND_TYPE, MANY_SECOND, source, null))),
                    ),
            )

        val plan =
            planner
                .plan(
                    before,
                    edit(
                        EditIntent.ConnectRelation(
                            ConnectIntent(sourceOccurrence, target, CounterpartChoice.Existing(targetOccurrence)),
                        ),
                    ),
                ).shouldBeInstanceOf<MutationPlanningResult.Accepted>()
                .plan

        plan.relations.removed.size shouldBe 2
        plan.relations.removed.mapTo(linkedSetOf()) { it.firstLocation to it.secondLocation } shouldBe
            setOf(sourcePath to null, null to targetPath)
        plan.relations.created.size shouldBe 1
        plan.relations.created
            .single()
            .firstLocation shouldBe sourcePath
        plan.relations.created
            .single()
            .secondLocation shouldBe targetPath
        plan.relations.metadataChanged.isEmpty() shouldBe true
    }

    fun manyOccurrencesRejectCrossedReciprocalLocations() {
        val source = ResourceId("source")
        val target = ResourceId("target")
        val sourceFirst = ItemId(value = "source_first")
        val sourceSecond = ItemId(value = "source_second")
        val targetFirst = ItemId(value = "target_first")
        val targetSecond = ItemId(value = "target_second")
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
                                ListItem(id = sourceFirst, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, targetFirstPath)),
                                ListItem(id = sourceSecond, value = link(MANY_FIRST_TYPE, MANY_FIRST, target, targetSecondPath)),
                            ),
                    ),
                target to
                    record(
                        manySecond =
                            listOf(
                                ListItem(id = targetFirst, value = link(MANY_SECOND_TYPE, MANY_SECOND, source, sourceSecondPath)),
                                ListItem(id = targetSecond, value = link(MANY_SECOND_TYPE, MANY_SECOND, source, sourceFirstPath)),
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

        projection.projections.isEmpty() shouldBe true
        projection.problems.mapTo(linkedSetOf()) { it.location } shouldBe
            setOf(
                ValueLocation(source, sourceFirstPath),
                ValueLocation(source, sourceSecondPath),
                ValueLocation(target, targetFirstPath),
                ValueLocation(target, targetSecondPath),
            )
        projection.problems.mapTo(linkedSetOf()) { it.code } shouldBe setOf("opposite_occurrence_mismatch")
    }

    fun concreteSubtypeLinkIsAuthorizedByItsActualTaggedSchema() {
        val host = id("polymorphic_host")
        val message = id("polymorphic_message")
        val linkedMessage = id("linked_message")
        val linkType = id("polymorphic_link")
        val endpoint = EndpointId(value = "polymorphic:first")
        val opposite = EndpointId(value = "polymorphic:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = host,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = host, name = "message"),
                                            type = message.template(),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = message,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = linkedMessage,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = linkedMessage, name = "target"),
                                            type = linkType.template(),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                        parents = listOf(message.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = linkType,
                        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = host.template()),
                    ),
                ),
            )
        val contract = relation(endpoint, opposite, host)
        val source = ResourceId("polymorphic_source")
        val target = ResourceId("polymorphic_target")
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(host.namedUse()),
                        mapOf(
                            "message" to
                                DataValue.named(
                                    linkedMessage.namedUse(),
                                    DataValue.record(
                                        mapOf(
                                            "target" to link(linkType.namedUse(), endpoint, target, null),
                                        ),
                                    ),
                                ),
                        ),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(host.namedUse()), mapOf("message" to DataValue.UNFILLED)),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        projection.problems.isEmpty() shouldBe true
        projection.projections.single().firstLocation shouldBe ValuePath(listOf(PathSegment.Field("message"), PathSegment.Field("target")))
    }

    fun recursiveLinkIsAuthorizedAtItsExactAuthoredDepth() {
        val host = id("recursive_host")
        val node = id("recursive_node")
        val linkType = id("recursive_link")
        val endpoint = EndpointId(value = "recursive:first")
        val opposite = EndpointId(value = "recursive:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = host,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = host, name = "tree"),
                                            type = node.template(),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = node,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = node, name = "next"),
                                            type = node.template().nullable(),
                                        ),
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = node, name = "target"),
                                            type = linkType.template(),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = linkType,
                        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = host.template()),
                    ),
                ),
            )
        val contract = relation(endpoint, opposite, host)
        val source = ResourceId("recursive_source")
        val target = ResourceId("recursive_target")
        val nested =
            DataValue.named(
                node.namedUse(),
                DataValue.record(
                    mapOf(
                        "next" to DataValue.NULL,
                        "target" to link(linkType.namedUse(), endpoint, target, null),
                    ),
                ),
            )
        val resources =
            mapOf(
                source to
                    AuthoringRecord(
                        TypeSelection.Complete(host.namedUse()),
                        mapOf(
                            "tree" to
                                DataValue.named(
                                    node.namedUse(),
                                    DataValue.record(
                                        mapOf(
                                            "next" to nested,
                                            "target" to DataValue.UNFILLED,
                                        ),
                                    ),
                                ),
                        ),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(host.namedUse()), mapOf("tree" to DataValue.UNFILLED)),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        projection.problems.isEmpty() shouldBe true
        projection.projections.single().firstLocation shouldBe
            ValuePath(
                listOf(
                    PathSegment.Field("tree"),
                    PathSegment.Field("next"),
                    PathSegment.Field("target"),
                ),
            )
    }

    fun appliedLinkTargetRejectsAResourceOutsideItsRefinedBound() {
        val resource = id("bounded_resource")
        val sourceType = id("bounded_source")
        val allowed = id("bounded_allowed")
        val disallowed = id("bounded_disallowed")
        val linkType = id("bounded_link")
        val parameter = ParameterKey(owner = linkType, index = 0)
        val endpoint = EndpointId(value = "bounded:first")
        val opposite = EndpointId(value = "bounded:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = resource,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = sourceType,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = sourceType, name = "target"),
                                            type = linkType.template(listOf(allowed.template())),
                                        ),
                                    ),
                                abstract_ = false,
                            ),
                        parents = listOf(resource.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = allowed,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(resource.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = disallowed,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(resource.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = linkType,
                        parameters = listOf(TypeParameter(key = parameter, name = "T", bounds = listOf(resource.template()))),
                        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = parameter.template),
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
                        TypeSelection.Complete(sourceType.namedUse()),
                        mapOf(
                            "target" to
                                link(
                                    linkType.namedUse(listOf(allowed.use())),
                                    endpoint,
                                    target,
                                    null,
                                ),
                        ),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(disallowed.namedUse()), emptyMap()),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        projection.problems.any { it.code == "binding_target_type_mismatch" } shouldBe true
        projection.projections.isEmpty() shouldBe true
    }

    fun unavailableSelectedFormCannotAuthorizeAnAuthoredLink() {
        val resource = id("unavailable_resource")
        val unavailable = id("unavailable_source")
        val missing = id("missing_parent")
        val endpoint = EndpointId(value = "unavailable:first")
        val opposite = EndpointId(value = "unavailable:second")
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    TypeDefinition.partial(
                        id = resource,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = unavailable,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(missing.namedTemplate()),
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
                        TypeSelection.Complete(unavailable.namedUse()),
                        mapOf("target" to DataValue.link(endpoint, LinkTarget(target, null))),
                    ),
                target to AuthoringRecord(TypeSelection.Complete(resource.namedUse()), emptyMap()),
            )

        val projection = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, listOf(contract), catalog)

        projection.problems.any { it.code == "source_resource_type_mismatch" } shouldBe true
        projection.projections.isEmpty() shouldBe true
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
            planner
                .plan(
                    resources,
                    edit(EditIntent.CreateResource(second, record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, target, null)))),
                ).shouldBeInstanceOf<MutationPlanningResult.Rejected>()

        rejected.problems.any { it.code == "multiple_immediate_owners" } shouldBe true
    }

    fun ownershipCycleIsRejected() {
        val planner = planner(pairContract(OWNING_FAMILIES))
        val first = ResourceId("cycle_first")
        val second = ResourceId("cycle_second")
        val resources =
            mapOf(
                first to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, second, null)),
                second to record(),
            )

        val rejected =
            planner
                .plan(
                    resources,
                    edit(EditIntent.SetValue(location(second, "first"), link(PAIR_FIRST_TYPE, PAIR_FIRST, first, null))),
                ).shouldBeInstanceOf<MutationPlanningResult.Rejected>()

        // Every affected resource on the cycle reports it.
        rejected.problems
            .filter { it.code == "relation_cycle" }
            .map { it.location.resource }
            .toSet() shouldBe setOf(first, second)
    }

    fun acyclicRelationAcceptsALongChainAndRejectsClosingIt() {
        val planner = planner(pairContract(setOf(RelationFamilyId(ACYCLIC_RELATION_FAMILY_ID))))
        val chain = (0 until 100_000).map { ResourceId("chain_$it") }
        val resources =
            chain.withIndex().associate { (index, id) ->
                val next = chain.getOrNull(index + 1)
                id to record(first = next?.let { link(PAIR_FIRST_TYPE, PAIR_FIRST, it, null) } ?: DataValue.UNFILLED)
            }
        val last = chain.last()

        planner
            .plan(resources, edit(EditIntent.SetValue(location(chain.first(), "label"), DataValue.StringValueWrapper("head"))))
            .shouldBeInstanceOf<MutationPlanningResult.Accepted>()
        val rejected =
            planner
                .plan(resources, edit(EditIntent.SetValue(location(last, "first"), link(PAIR_FIRST_TYPE, PAIR_FIRST, chain.first(), null))))
                .shouldBeInstanceOf<MutationPlanningResult.Rejected>()

        rejected.problems.map { it.code }.toSet() shouldBe setOf("relation_cycle")
    }

    fun nonAcyclicRelationAllowsACycle() {
        val planner = planner(pairContract())
        val first = ResourceId("loop_first")
        val second = ResourceId("loop_second")
        val resources =
            mapOf(
                first to record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, second, null)),
                second to record(),
            )

        planner
            .plan(resources, edit(EditIntent.SetValue(location(second, "first"), link(PAIR_FIRST_TYPE, PAIR_FIRST, first, null))))
            .shouldBeInstanceOf<MutationPlanningResult.Accepted>()
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
            planner
                .plan(
                    resources,
                    edit(EditIntent.CreateResource(second, record(first = link(PAIR_FIRST_TYPE, PAIR_FIRST, target, null)))),
                ).shouldBeInstanceOf<MutationPlanningResult.Rejected>()

        rejected.problems.any { it.code == "first_endpoint_cardinality_exceeded" } shouldBe true
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
                edit(EditIntent.SetValue(location(valid, "label"), DataValue.StringValueWrapper("changed"))),
            )

        result.shouldBeInstanceOf<MutationPlanningResult.Accepted>()
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
            relations = contracts,
            endpointBindings = BINDINGS,
        )
    return AuthoringView(
        catalog,
        resources,
        ResourceValueMapper.discover(resources).associateBy { it.id },
    )
}

private fun pairContract(families: Set<RelationFamilyId> = emptySet()) =
    RelationContract(
        RelationId("pair"),
        EndpointDefinition(
            PAIR_FIRST,
            EndpointSlot.First,
            NODE.namedTemplate(),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            PAIR_SECOND,
            EndpointSlot.Second,
            NODE.namedTemplate(),
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
        NODE.namedTemplate(),
        EndpointCardinality.One,
        firstDelete,
    ),
    EndpointDefinition(
        PARENT_SECOND,
        EndpointSlot.Second,
        NODE.namedTemplate(),
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
            NODE.namedTemplate(),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            MANY_SECOND,
            EndpointSlot.Second,
            NODE.namedTemplate(),
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
            NODE.namedTemplate(),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            NESTED_SECOND,
            EndpointSlot.Second,
            NODE.namedTemplate(),
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
        resource.namedTemplate(),
        EndpointCardinality.One,
        RelationDeletePolicy.CLEAR,
    ),
    EndpointDefinition(
        second,
        EndpointSlot.Second,
        resource.namedTemplate(),
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
    type: NamedTypeUse,
    endpoint: EndpointId,
    target: ResourceId,
    opposite: ValuePath?,
) = DataValue.named(type, DataValue.link(endpoint, LinkTarget(target, opposite)))

private fun record(
    first: DataValue = DataValue.UNFILLED,
    second: DataValue = DataValue.UNFILLED,
    children: List<ListItem> = emptyList(),
    parent: DataValue = DataValue.UNFILLED,
    manyFirst: List<ListItem> = emptyList(),
    manySecond: List<ListItem> = emptyList(),
    wrapper: DataValue = wrapper(DataValue.UNFILLED),
    nestedSecond: DataValue = DataValue.UNFILLED,
    label: String = "",
) = AuthoringRecord(
    TypeSelection.Complete(NODE_USE),
    mapOf(
        "first" to first,
        "second" to second,
        "children" to DataValue.named(CHILDREN_USE, DataValue.listValue(children)),
        "parent" to parent,
        "manyFirst" to DataValue.named(MANY_FIRST_LIST_USE, DataValue.listValue(manyFirst)),
        "manySecond" to DataValue.named(MANY_SECOND_LIST_USE, DataValue.listValue(manySecond)),
        "wrapper" to wrapper,
        "nestedSecond" to nestedSecond,
        "label" to DataValue.StringValueWrapper(label),
    ),
)

private fun Map<ResourceId, AuthoringRecord>.apply(plan: AuthoringMutationPlan): Map<ResourceId, AuthoringRecord> =
    (this + plan.resources) - plan.removedResources

private fun location(
    resource: ResourceId,
    field: String,
) = ValueLocation(resource, fieldPath(field))

private fun fieldPath(field: String) = ValuePath(listOf(PathSegment.Field(field)))

private fun id(name: String) = TypeDefinitionId.qualified("test", name)

private fun linkDefinition(
    id: TypeDefinitionId,
    endpoint: EndpointId,
) = TypeDefinition.partial(id = id, representation = RepresentationTemplate.createLink(endpoint = endpoint, target = NODE.template()))

private fun listDefinition(
    id: TypeDefinitionId,
    item: TypeDefinitionId,
) = TypeDefinition.partial(
    id = id,
    representation = RepresentationTemplate.createSequence(item = item.template(), kind = CollectionKind.LIST),
)

private fun wrapper(value: DataValue): DataValue = DataValue.named(WRAPPER_USE, DataValue.record(mapOf("inner" to value)))

private fun field(
    name: String,
    type: TypeDefinitionId,
) = FieldDeclaration.partial(owner = FieldOwner(definition = NODE, name = name), type = type.template())

private fun binding(
    endpoint: EndpointId,
    owner: TypeDefinitionId,
    field: String,
    containsCollection: Boolean,
) = EndpointBindingTemplate(
    endpoint,
    NODE.namedTemplate(),
    owner,
    RelativeFieldPattern(
        buildList {
            add(FieldPatternSegment.Field(field))
            if (containsCollection) add(FieldPatternSegment.Items)
        },
    ),
    NODE.template(),
    containsCollection,
)

private val GENERATION = CatalogGeneration("catalog")
private val NODE = id("node")
private val OWNING_FAMILIES = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID), RelationFamilyId(ACYCLIC_RELATION_FAMILY_ID))
private val PAIR_FIRST = EndpointId(value = "pair:first")
private val PAIR_SECOND = EndpointId(value = "pair:second")
private val PARENT_FIRST = EndpointId(value = "parent:first")
private val PARENT_SECOND = EndpointId(value = "parent:second")
private val MANY_FIRST = EndpointId(value = "many:first")
private val MANY_SECOND = EndpointId(value = "many:second")
private val NESTED_FIRST = EndpointId(value = "nested:first")
private val NESTED_SECOND = EndpointId(value = "nested:second")
private val PAIR_FIRST_TYPE = id("pair_first_link").namedUse()
private val PAIR_SECOND_TYPE = id("pair_second_link").namedUse()
private val PARENT_FIRST_TYPE = id("parent_first_link").namedUse()
private val PARENT_SECOND_TYPE = id("parent_second_link").namedUse()
private val MANY_FIRST_TYPE = id("many_first_link").namedUse()
private val MANY_SECOND_TYPE = id("many_second_link").namedUse()
private val NESTED_FIRST_TYPE = id("nested_first_link").namedUse()
private val NESTED_SECOND_TYPE = id("nested_second_link").namedUse()
private val WRAPPER_USE = id("wrapper").namedUse()
private val CHILDREN_USE = id("children").namedUse()
private val MANY_FIRST_LIST_USE = id("many_first_list").namedUse()
private val MANY_SECOND_LIST_USE = id("many_second_list").namedUse()
private val NODE_USE = NODE.namedUse()
private val DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = NODE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            field("first", PAIR_FIRST_TYPE.definition),
                            field("second", PAIR_SECOND_TYPE.definition),
                            field("children", CHILDREN_USE.definition),
                            field("parent", PARENT_SECOND_TYPE.definition),
                            field("manyFirst", MANY_FIRST_LIST_USE.definition),
                            field("manySecond", MANY_SECOND_LIST_USE.definition),
                            field("wrapper", WRAPPER_USE.definition),
                            field("nestedSecond", NESTED_SECOND_TYPE.definition),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NODE, name = "label"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = false,
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
        TypeDefinition.partial(
            id = WRAPPER_USE.definition,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = WRAPPER_USE.definition, name = "inner"),
                                type = NESTED_FIRST_TYPE.definition.template(),
                            ),
                        ),
                    abstract_ = false,
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
            NODE.namedTemplate(),
            NESTED_FIRST_TYPE.definition,
            RelativeFieldPattern(
                listOf(
                    FieldPatternSegment.Field("wrapper"),
                    FieldPatternSegment.Field("inner"),
                ),
            ),
            NODE.template(),
            false,
        ),
        binding(NESTED_SECOND, NESTED_SECOND_TYPE.definition, "nestedSecond", false),
    )

val AuthoringMutationPlannerTestSuite by testSuite {
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
    test("ownershipCycleIsRejected") { AuthoringMutationPlannerTest().ownershipCycleIsRejected() }
    test("acyclicRelationAcceptsALongChainAndRejectsClosingIt") {
        AuthoringMutationPlannerTest().acyclicRelationAcceptsALongChainAndRejectsClosingIt()
    }
    test("nonAcyclicRelationAllowsACycle") { AuthoringMutationPlannerTest().nonAcyclicRelationAllowsACycle() }
    test("oneEndpointRejectsASecondResourceRelation") { AuthoringMutationPlannerTest().oneEndpointRejectsASecondResourceRelation() }
    test(
        "unrelatedInvalidResourceDoesNotBlockAValidEdit",
    ) { AuthoringMutationPlannerTest().unrelatedInvalidResourceDoesNotBlockAValidEdit() }
}
