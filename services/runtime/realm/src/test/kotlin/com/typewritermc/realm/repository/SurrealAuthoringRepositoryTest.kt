package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.BatchId
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkInspectionQuery
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedCreation
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.CreationCoordinator
import com.typewritermc.realm.authoring.CreationEvaluator
import com.typewritermc.realm.authoring.DefaultTypeArgumentOperations
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.RealmGraphReads
import com.typewritermc.realm.authoring.SnapshotCommit
import com.typewritermc.realm.authoring.SurrealCreationReceiptStore
import com.typewritermc.realm.authoring.TypeArgumentChangePreview
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.authoring.TypeRepairIntent
import com.typewritermc.realm.authoring.absentInputToken
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.authoring.requiredAuthoringInputs
import com.typewritermc.realm.checking.SnapshotReads
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.repository.SurrealAuthoringSeedLoader
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.realm.schema.DatabaseEndpoint
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.realm.search.AuthoringSearchIndexer
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
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
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
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
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.encodeToString
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

class SurrealAuthoringRepositoryTest {
    fun preparedIntentDigestFramesMoveIdsAndRetainsCollectionSemantics() {
        val at = location(ResourceId("page"), "items")
        val catalog = CatalogGeneration("catalog")
        val snapshot = SnapshotId("snapshot")
        val firstObservation = InputObservation(InputIdentity.Existence(ResourceId("first")), com.typewritermc.checking.InputToken("one"))
        val secondObservation = InputObservation(InputIdentity.Existence(ResourceId("second")), com.typewritermc.checking.InputToken("two"))

        fun prepared(
            item: String,
            after: String,
            observations: List<InputObservation> = listOf(firstObservation, secondObservation),
            intents: List<EditIntent> = listOf(EditIntent.Move(at, ItemId(item), ItemId(after))),
        ) = PreparedEdit(BatchId("batch"), catalog, snapshot, observations, intents)

        val first = prepared(item = "a:b", after = "c")
        val collidedBeforeFraming = prepared(item = "a", after = "b:c")
        val reorderedObservations = prepared(item = "a:b", after = "c", observations = listOf(secondObservation, firstObservation))
        val reorderedIntents =
            prepared(
                item = "a:b",
                after = "c",
                intents =
                    listOf(
                        EditIntent.Move(at, ItemId("a:b"), ItemId("c")),
                        EditIntent.Remove(at, ItemId("removed")),
                    ),
            )
        val reverseIntents = reorderedIntents.copy(intents = reorderedIntents.intents.reversed())

        assertTrue(canonicalPreparedIntentDigest(first) != canonicalPreparedIntentDigest(collidedBeforeFraming))
        assertEquals(canonicalPreparedIntentDigest(first), canonicalPreparedIntentDigest(reorderedObservations))
        assertTrue(canonicalPreparedIntentDigest(reorderedIntents) != canonicalPreparedIntentDigest(reverseIntents))
    }

    fun emptyDurableStateProducesAnExactCatalogSeed() =
        runTest {
            val directory = Files.createTempDirectory("realm_empty_seed")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val catalog = TestCatalogLease(CatalogGeneration("catalog"))
                    val seed = SurrealAuthoringSeedLoader(database).loadFor(catalog)

                    assertEquals(SnapshotId("realm:0"), seed.snapshot)
                    assertTrue(seed.resources.isEmpty())
                    assertEquals(
                        setOf(RESOURCE_SELECTION_INPUT, InputIdentity.Catalog(catalog.generation)),
                        seed.inputTokens.keys,
                    )
                    assertEquals(
                        catalogInputToken(catalog.generation),
                        seed.inputTokens[InputIdentity.Catalog(catalog.generation)],
                    )
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun nativeOneSidedRelationsPersistMissingLocationsAndClearMetadata() =
        runTest {
            val directory = Files.createTempDirectory("realm_one_sided_relation")
            val telemetry = TelemetryTestHarness.create()
            val first = ResourceId("one_sided_first")
            val second = ResourceId("one_sided_second")
            val presentFirst = ValuePath(listOf(PathSegment.Field("outgoing")))
            val presentSecond = ValuePath(listOf(PathSegment.Field("incoming")))
            val missingFirst = RelationId("missing_first")
            val missingSecond = RelationId("missing_second")
            val relationStore = SurrealDeclaredRelationStore()
            lateinit var storedMissingFirst: StoredDeclaredEdge

            fun readLocations(database: Surreal): Map<String, Pair<com.surrealdb.Value, com.surrealdb.Value>> =
                database
                    .query("SELECT contract, first_location, second_location FROM resource_relation ORDER BY contract;")
                    .take(0)
                    .getArray()
                    .associate { row ->
                        val value = row.getObject()
                        value.get("contract").getString() to (value.get("first_location") to value.get("second_location"))
                    }

            try {
                openDatabase(directory, telemetry).use { database ->
                    database.inTransaction { transaction ->
                        listOf(first, second).forEach { resource ->
                            transaction
                                .query(
                                    "CREATE ONLY \$resource CONTENT { definition: 'test', content: '{}', snapshot: 0 };",
                                    mapOf("resource" to resource.unifiedSurrealId()),
                                ).take(0)
                        }
                        val prepared =
                            relationStore.prepare(
                                RelationProjectionDelta(
                                    removed = emptyList(),
                                    created =
                                        listOf(
                                            LinkProjection(missingFirst, first, second, null, presentSecond),
                                            LinkProjection(missingSecond, first, second, presentFirst, null),
                                        ),
                                    metadataChanged = emptyList(),
                                ),
                                transaction,
                            )
                        storedMissingFirst = prepared.created.single { it.relation == missingFirst }
                        relationStore.apply(prepared, snapshot = 1, transaction)
                    }
                }

                openDatabase(directory, telemetry).use { database ->
                    val created = readLocations(database)
                    val firstLocations = created.getValue(missingFirst.value)
                    assertTrue(firstLocations.first.isNone)
                    assertTrue(!firstLocations.first.isNull)
                    assertTrue(firstLocations.second.isString)
                    val secondLocations = created.getValue(missingSecond.value)
                    assertTrue(secondLocations.first.isString)
                    assertTrue(secondLocations.second.isNone)
                    assertTrue(!secondLocations.second.isNull)

                    database.inTransaction { transaction ->
                        relationStore.apply(
                            StoredRelationDelta(
                                removed = emptyList(),
                                created = emptyList(),
                                metadataChanged = listOf(storedMissingFirst.copy(targetLocation = null)),
                            ),
                            snapshot = 2,
                            transaction,
                        )
                    }
                    val updated = readLocations(database).getValue(missingFirst.value)
                    assertTrue(updated.first.isNone)
                    assertTrue(!updated.first.isNull)
                    assertTrue(updated.second.isNone)
                    assertTrue(!updated.second.isNull)
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun cascadeDeletionRequiresEvidenceForEveryRemovedResource() =
        runTest {
            val directory = Files.createTempDirectory("realm_cascade_evidence")
            val telemetry = TelemetryTestHarness.create()
            val generation = CatalogGeneration("cascade_evidence_catalog")
            val node = TypeDefinitionId(TypeId.Qualified("test", "cascade_node"), 1)
            val linkType = TypeDefinitionId(TypeId.Qualified("test", "cascade_link"), 1)
            val firstEndpoint = EndpointId("cascade:first")
            val secondEndpoint = EndpointId("cascade:second")
            val contract =
                RelationContract(
                    RelationId("cascade"),
                    EndpointDefinition(
                        firstEndpoint,
                        EndpointSlot.First,
                        TypeTemplate.Named(node),
                        EndpointCardinality.One,
                        RelationDeletePolicy.CASCADE,
                    ),
                    EndpointDefinition(
                        secondEndpoint,
                        EndpointSlot.Second,
                        TypeTemplate.Named(node),
                        EndpointCardinality.One,
                        RelationDeletePolicy.CLEAR,
                    ),
                )
            val definitions =
                listOf(
                    TypeDefinition(
                        node,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(FieldDeclaration(FieldOwner(node, "child"), TypeTemplate.Named(linkType))),
                            ),
                    ),
                    TypeDefinition(
                        linkType,
                        representation = RepresentationTemplate.Link(firstEndpoint, TypeTemplate.Named(node)),
                    ),
                )
            val bindings =
                listOf(
                    EndpointBindingTemplate(
                        firstEndpoint,
                        TypeTemplate.Named(node),
                        linkType,
                        RelativeFieldPattern(listOf(FieldPatternSegment.Field("child"))),
                        TypeTemplate.Named(node),
                        false,
                    ),
                )
            val catalog =
                TestCatalogLease(
                    generation = generation,
                    definitions = definitions,
                    resourceRoot = node,
                    relations = listOf(contract),
                    endpointBindings = bindings,
                )
            val parent = ResourceId("cascade_parent")
            val child = ResourceId("cascade_child")

            fun resource(childValue: DataValue = DataValue.Unfilled) =
                AuthoringRecord(
                    TypeSelection.Complete(TypeUse.Named(node)),
                    mapOf("child" to childValue),
                )

            val resources =
                mapOf(
                    parent to
                        resource(
                            DataValue.Named(
                                TypeUse.Named(linkType),
                                DataValue.Link(firstEndpoint, LinkTarget(child, null)),
                            ),
                        ),
                    child to resource(),
                )
            val seed = AuthoredSnapshotSeed(SnapshotId("realm:0"), resources, tokensFor(resources, generation))
            val store = InMemoryAuthoringSnapshotStore(catalog, seed)
            try {
                openDatabase(directory, telemetry).use { database ->
                    val repository = repository(database, store, catalog)
                    val edit =
                        PreparedEdit(
                            BatchId("cascade_without_closure_evidence"),
                            generation,
                            seed.snapshot,
                            emptyList(),
                            listOf(EditIntent.DeleteResource(parent)),
                        )
                    val plan =
                        assertIs<MutationPlanningResult.Accepted>(
                            AuthoringMutationPlanner(catalog.checked, catalog.relations, catalog.endpointBindings)
                                .plan(resources, edit),
                        ).plan
                    assertEquals(setOf(parent, child), plan.removedResources)
                    assertTrue(
                        plan.relations.removed
                            .single()
                            .secondLocation == null,
                    )

                    val incompleteEvidence = mandatoryWriteInputs(edit, resources) + relationWriteInputs(plan.relations, resources)
                    val childRoot = ValueLocation(child, ValuePath())
                    assertTrue(InputIdentity.Existence(child) !in incompleteEvidence)
                    assertTrue(InputIdentity.Form(childRoot) !in incompleteEvidence)
                    val rejected =
                        assertIs<CommitResult.Rejected>(
                            repository.commit(
                                edit.copy(
                                    observations =
                                        incompleteEvidence.map { identity ->
                                            InputObservation(identity, store.currentToken(identity))
                                        },
                                ),
                            ),
                        )
                    assertTrue(
                        rejected.problems.any { problem ->
                            problem.location == childRoot && problem.code == "missing_input_observation"
                        },
                    )
                    store.capture().use { current -> assertEquals(resources, current.root.resources) }

                    val completeEvidence = mandatoryWriteInputs(edit, resources) + mutationPlanWriteInputs(plan, resources)
                    assertIs<CommitResult.Committed>(
                        repository.commit(
                            edit.copy(
                                id = BatchId("cascade_with_closure_evidence"),
                                observations =
                                    completeEvidence.map { identity ->
                                        InputObservation(identity, store.currentToken(identity))
                                    },
                            ),
                        ),
                    )
                    store.capture().use { current -> assertTrue(current.root.resources.isEmpty()) }
                    assertTrue(requireNotNull(SurrealAuthoringSeedLoader(database).load()).resources.isEmpty())
                }
            } finally {
                store.close()
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun createdResourceCommitReplaysAfterInstallFailureAndRepairsMissingDerivedTokens() =
        runTest {
            val directory = Files.createTempDirectory("realm_create_install_retry")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val catalog = TestCatalogLease(CatalogGeneration("catalog"))
                    val seed = SurrealAuthoringSeedLoader(database).loadFor(catalog)
                    val delegate = InMemoryAuthoringSnapshotStore(catalog, seed)
                    val store = FailFirstInstallSnapshotStore(delegate)
                    val repository = repository(database, store, catalog)
                    val resource = ResourceId("created")
                    val authored = record(name = "Created", numbers = listOf("first" to 7))
                    val root = ValueLocation(resource, ValuePath())
                    val catalogIdentity = InputIdentity.Catalog(catalog.generation)
                    val edit =
                        PreparedEdit(
                            id = BatchId("create_with_install_retry"),
                            catalog = catalog.generation,
                            snapshot = SnapshotId("realm:0"),
                            observations =
                                listOf(
                                    InputObservation(catalogIdentity, store.currentToken(catalogIdentity)),
                                    InputObservation(InputIdentity.Existence(resource), absentInputToken()),
                                    InputObservation(RESOURCE_SELECTION_INPUT, store.currentToken(RESOURCE_SELECTION_INPUT)),
                                ),
                            intents = listOf(EditIntent.CreateResource(resource, authored)),
                        )

                    val firstFailure = runCatching { repository.commit(edit) }.exceptionOrNull()
                    assertEquals("simulated snapshot install failure", firstFailure?.message)
                    delegate.capture().use { current ->
                        assertEquals(SnapshotId("realm:0"), current.root.id)
                        assertTrue(resource !in current.root.resources)
                    }

                    val replayed = assertIs<CommitResult.Committed>(repository.commit(edit))
                    assertEquals(SnapshotId("realm:1"), replayed.snapshot)
                    val required = requiredAuthoringInputs(mapOf(resource to authored)) + catalogIdentity
                    delegate.capture().use { current ->
                        assertEquals(authored, current.root.resources[resource])
                        assertTrue(
                            current.root.inputs.keys
                                .containsAll(required),
                        )
                        required.forEach { identity ->
                            assertTrue(current.root.inputs.getValue(identity) != absentInputToken())
                        }
                    }
                    delegate.close()

                    val retainedRootInputs =
                        setOf(
                            RESOURCE_SELECTION_INPUT,
                            InputIdentity.Existence(resource),
                            InputIdentity.Form(root),
                            InputIdentity.Value(root),
                        )
                    val missing = requiredAuthoringInputs(mapOf(resource to authored)) - retainedRootInputs
                    missing.forEach { identity ->
                        database
                            .query(
                                "DELETE authoring_input WHERE identity = \$identity;",
                                mapOf("identity" to authoringStorageJson.encodeToString(InputIdentity.serializer(), identity)),
                            ).take(0)
                    }

                    val recovered = SurrealAuthoringSeedLoader(database).loadFor(catalog)
                    assertEquals(authored, recovered.resources[resource])
                    missing.forEach { identity ->
                        val expected = authoredInputToken(1, identity)
                        assertEquals(expected, recovered.inputTokens[identity])
                        val stored =
                            database
                                .query(
                                    "SELECT VALUE token FROM authoring_input WHERE identity = \$identity;",
                                    mapOf("identity" to authoringStorageJson.encodeToString(InputIdentity.serializer(), identity)),
                                ).take(0)
                                .getArray()
                        assertEquals(1, stored.len())
                        assertEquals(expected.value, stored.get(0).getString())
                    }
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun changedCatalogRestartStagesAbsentEvidenceUntilDurableActivation() =
        runTest {
            val directory = Files.createTempDirectory("realm_catalog_restart")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val oldCatalog = TestCatalogLease(CatalogGeneration("old"))
                    val initialSeed = SurrealAuthoringSeedLoader(database).loadFor(oldCatalog)
                    val oldStore = InMemoryAuthoringSnapshotStore(oldCatalog, initialSeed)
                    repository(database, oldStore, oldCatalog)
                    oldStore.close()

                    val newCatalog = TestCatalogLease(CatalogGeneration("new"))
                    val restartedSeed = SurrealAuthoringSeedLoader(database).loadFor(newCatalog)
                    assertEquals(
                        absentInputToken(),
                        restartedSeed.inputTokens[InputIdentity.Catalog(newCatalog.generation)],
                    )

                    val restartedStore = InMemoryAuthoringSnapshotStore(newCatalog, restartedSeed)
                    val restartedRepository = repository(database, restartedStore, newCatalog)
                    restartedRepository.activateCatalog(newCatalog, install = {}, publish = {})

                    restartedStore.capture().use { current ->
                        assertEquals(SnapshotId("realm:1"), current.root.id)
                        assertEquals(newCatalog.generation, current.root.catalog.generation)
                        assertEquals(
                            catalogInputToken(newCatalog.generation),
                            current.root.inputs[InputIdentity.Catalog(newCatalog.generation)],
                        )
                    }
                    restartedStore.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun failedCatalogSwapRollsBackTheDurableGeneration() =
        runTest {
            val directory = Files.createTempDirectory("realm_catalog_activation_failure")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val catalog = TestCatalogLease(CatalogGeneration("old"))
                    val resource = ResourceId("page")
                    val initial = record(name = "initial")
                    val seed =
                        AuthoredSnapshotSeed(
                            SnapshotId("realm:0"),
                            mapOf(resource to initial),
                            tokensFor(mapOf(resource to initial), catalog.generation),
                        )
                    val store = InMemoryAuthoringSnapshotStore(catalog, seed)
                    val repository = repository(database, store, catalog)

                    val failure =
                        runCatching {
                            repository.activateCatalog(
                                TestCatalogLease(CatalogGeneration("new")),
                                install = { error("swap failed") },
                                publish = {},
                            )
                        }.exceptionOrNull()
                    assertEquals("swap failed", failure?.message)

                    val name = location(resource, "name")
                    assertIs<CommitResult.Committed>(
                        repository.commit(
                            edit(
                                "after_failed_swap",
                                seed.snapshot,
                                catalog,
                                evidence(seed.inputTokens, name),
                                EditIntent.SetValue(name, DataValue.StringValue("accepted")),
                            ),
                        ),
                    )
                    store.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun catalogActivationFenceExcludesAcceptanceUntilTheSynchronousSwapCompletes() =
        runTest {
            val directory = Files.createTempDirectory("realm_catalog_activation")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val oldCatalog = TestCatalogLease(CatalogGeneration("old"))
                    val newCatalog = TestCatalogLease(CatalogGeneration("new"))
                    val active = AtomicReference(oldCatalog)
                    val resource = ResourceId("page")
                    val initial = record(name = "initial")
                    val seed =
                        AuthoredSnapshotSeed(
                            SnapshotId("realm:0"),
                            mapOf(resource to initial),
                            tokensFor(mapOf(resource to initial), oldCatalog.generation),
                        )
                    val store = InMemoryAuthoringSnapshotStore(oldCatalog, seed)
                    val repository =
                        SurrealAuthoringRepository(
                            database,
                            store,
                            catalog = { active.get().retain() },
                            searchIndexer = AuthoringSearchIndexer(),
                        )
                    val secondCatalog = TestCatalogLease(CatalogGeneration("old"))
                    val secondActive = AtomicReference(secondCatalog)
                    val secondStore = InMemoryAuthoringSnapshotStore(secondCatalog, seed)
                    val secondRepository =
                        SurrealAuthoringRepository(
                            database,
                            secondStore,
                            catalog = { secondActive.get().retain() },
                            searchIndexer = AuthoringSearchIndexer(),
                        )
                    val entered = CountDownLatch(1)
                    val release = CountDownLatch(1)
                    val activation =
                        async(Dispatchers.Default) {
                            repository.activateCatalog(
                                newCatalog,
                                install = {
                                    entered.countDown()
                                    check(release.await(5, TimeUnit.SECONDS))
                                    active.set(newCatalog)
                                },
                                publish = {},
                            )
                        }
                    assertTrue(entered.await(5, TimeUnit.SECONDS))
                    val name = location(resource, "name")
                    val crossActorResult = AtomicReference<CommitResult>()
                    val crossActorDone = CountDownLatch(1)
                    val crossActorThread =
                        Thread {
                            runBlocking {
                                crossActorResult.set(
                                    secondRepository.commit(
                                        edit(
                                            "cross_actor_commit",
                                            seed.snapshot,
                                            secondCatalog,
                                            evidence(seed.inputTokens, name),
                                            EditIntent.SetValue(name, DataValue.StringValue("stale")),
                                        ),
                                    ),
                                )
                                crossActorDone.countDown()
                            }
                        }.apply { start() }
                    assertTrue(crossActorDone.await(5, TimeUnit.SECONDS))
                    val transition = assertIs<CommitResult.Rejected>(crossActorResult.get())
                    assertTrue(transition.problems.any { it.code == "catalog_transition" })
                    val commit =
                        async(Dispatchers.Default) {
                            repository.commit(
                                edit(
                                    "blocked_commit",
                                    seed.snapshot,
                                    oldCatalog,
                                    evidence(seed.inputTokens, name),
                                    EditIntent.SetValue(name, DataValue.StringValue("stale")),
                                ),
                            )
                        }
                    kotlinx.coroutines.yield()
                    assertFalse(commit.isCompleted)

                    release.countDown()
                    activation.await()
                    store.capture().use { captured ->
                        assertEquals(SnapshotId("realm:1"), captured.root.id)
                        assertEquals(newCatalog.generation, captured.root.catalog.generation)
                        assertTrue(InputIdentity.Catalog(newCatalog.generation) in captured.root.inputs)
                    }
                    var repeatedInstall = false
                    repository.activateCatalog(newCatalog, install = { repeatedInstall = true }, publish = {})
                    assertFalse(repeatedInstall)
                    store.capture().use { captured -> assertEquals(SnapshotId("realm:1"), captured.root.id) }
                    var secondInstall = false
                    secondRepository.activateCatalog(
                        newCatalog,
                        install = {
                            secondInstall = true
                            secondActive.set(newCatalog)
                        },
                        publish = {},
                    )
                    assertTrue(secondInstall)
                    secondStore.capture().use { captured ->
                        assertEquals(SnapshotId("realm:1"), captured.root.id)
                        assertEquals(newCatalog.generation, captured.root.catalog.generation)
                        assertEquals(
                            catalogInputToken(newCatalog.generation),
                            captured.root.inputs[InputIdentity.Catalog(newCatalog.generation)],
                        )
                    }
                    val changed = assertIs<CommitResult.CatalogChanged>(commit.await())
                    assertEquals(newCatalog.generation, changed.actual)
                    crossActorThread.join()
                    secondStore.close()
                    store.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun preparedCatalogActivationRecoversAndKeepsAcceptanceClosedUntilFinalization() =
        runTest {
            val directory = Files.createTempDirectory("realm_catalog_activation_recovery")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val oldCatalog = TestCatalogLease(CatalogGeneration("old"))
                    val newCatalog = TestCatalogLease(CatalogGeneration("new"))
                    val active = AtomicReference(oldCatalog)
                    val resource = ResourceId("page")
                    val initial = record(name = "initial")
                    val seed =
                        AuthoredSnapshotSeed(
                            SnapshotId("realm:0"),
                            mapOf(resource to initial),
                            tokensFor(mapOf(resource to initial), oldCatalog.generation),
                        )
                    val store = InMemoryAuthoringSnapshotStore(oldCatalog, seed)
                    val repository =
                        SurrealAuthoringRepository(
                            database,
                            store,
                            catalog = { active.get().retain() },
                            searchIndexer = AuthoringSearchIndexer(),
                        )
                    database
                        .query(
                            "UPDATE ONLY authoring_acceptance_fence:current " +
                                "SET pending_catalog_generation = \$generation;",
                            mapOf("generation" to newCatalog.generation.value),
                        ).take(0)

                    val name = location(resource, "name")
                    val rejected =
                        assertIs<CommitResult.Rejected>(
                            repository.commit(
                                edit(
                                    "during_recovery",
                                    seed.snapshot,
                                    oldCatalog,
                                    evidence(seed.inputTokens, name),
                                    EditIntent.SetValue(name, DataValue.StringValue("stale")),
                                ),
                            ),
                        )
                    assertTrue(rejected.problems.any { it.code == "catalog_transition" })

                    var installs = 0
                    var publications = 0
                    repository.activateCatalog(
                        newCatalog,
                        install = {
                            installs++
                            active.set(newCatalog)
                        },
                        publish = { publications++ },
                    )

                    assertEquals(1, installs)
                    assertEquals(1, publications)
                    store.capture().use { captured ->
                        assertEquals(SnapshotId("realm:1"), captured.root.id)
                        assertEquals(newCatalog.generation, captured.root.catalog.generation)
                        assertEquals(
                            catalogInputToken(newCatalog.generation),
                            captured.root.inputs[InputIdentity.Catalog(newCatalog.generation)],
                        )
                    }
                    store.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun sharedFenceMergesIndependentChangesAndRejectsChangedEvidence() =
        runTest {
            val directory = Files.createTempDirectory("realm_authoring_fence")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val resource = ResourceId("page")
                    val initial = record(name = "initial", count = 1)
                    val firstCatalog = TestCatalogLease()
                    val secondCatalog = TestCatalogLease()
                    val seed =
                        AuthoredSnapshotSeed(
                            SnapshotId("realm:0"),
                            mapOf(resource to initial),
                            tokensFor(mapOf(resource to initial), firstCatalog.generation),
                        )
                    val firstStore = InMemoryAuthoringSnapshotStore(firstCatalog, seed)
                    val secondStore = InMemoryAuthoringSnapshotStore(secondCatalog, seed)
                    val firstRepository = repository(database, firstStore, firstCatalog)
                    val secondRepository = repository(database, secondStore, secondCatalog)
                    val name = location(resource, "name")
                    val count = location(resource, "count")
                    val nameEdit =
                        edit(
                            "name",
                            seed.snapshot,
                            firstCatalog,
                            evidence(seed.inputTokens, name),
                            EditIntent.SetValue(name, DataValue.StringValue("changed")),
                        )
                    val countEdit =
                        edit(
                            "count",
                            seed.snapshot,
                            secondCatalog,
                            evidence(seed.inputTokens, count),
                            EditIntent.SetValue(count, DataValue.Integer(java.math.BigInteger.TWO)),
                        )
                    val ready = CompletableDeferred<Unit>()
                    val first =
                        async(Dispatchers.Default) {
                            ready.await()
                            firstRepository.commit(nameEdit)
                        }
                    val second =
                        async(Dispatchers.Default) {
                            ready.await()
                            secondRepository.commit(countEdit)
                        }
                    ready.complete(Unit)
                    val firstResult = assertIs<CommitResult.Committed>(first.await())
                    val secondResult = assertIs<CommitResult.Committed>(second.await())
                    listOf(firstStore, secondStore).forEach { actorStore ->
                        actorStore.capture().use { captured ->
                            val capturedRecord = captured.root.resources.getValue(resource)
                            val changedName = capturedRecord.fields.getValue("name") == DataValue.StringValue("changed")
                            val changedCount = capturedRecord.fields.getValue("count") == DataValue.Integer(java.math.BigInteger.TWO)
                            when (captured.root.id) {
                                SnapshotId("realm:1") -> assertTrue(changedName xor changedCount)
                                SnapshotId("realm:2") -> assertTrue(changedName && changedCount)
                                else -> error("Unexpected concurrent snapshot ${captured.root.id.value}.")
                            }
                        }
                    }
                    val realmOneEdit = if (firstResult.snapshot == SnapshotId("realm:1")) nameEdit else countEdit
                    assertEquals(
                        setOf(SnapshotId("realm:1"), SnapshotId("realm:2")),
                        setOf(firstResult.snapshot, secondResult.snapshot),
                    )
                    val replayCatalog = TestCatalogLease()
                    val replayStore = InMemoryAuthoringSnapshotStore(replayCatalog, seed)
                    val replayRepository = repository(database, replayStore, replayCatalog)
                    assertEquals(SnapshotId("realm:1"), assertIs<CommitResult.Committed>(replayRepository.commit(realmOneEdit)).snapshot)
                    replayStore.capture().use { captured ->
                        assertEquals(SnapshotId("realm:2"), captured.root.id)
                        assertEquals(
                            DataValue.StringValue("changed"),
                            captured.root.resources
                                .getValue(resource)
                                .fields
                                .getValue("name"),
                        )
                        assertEquals(
                            DataValue.Integer(java.math.BigInteger.TWO),
                            captured.root.resources
                                .getValue(resource)
                                .fields
                                .getValue("count"),
                        )
                    }
                    replayStore.close()
                    val merged = requireNotNull(SurrealAuthoringSeedLoader(database).load())
                    assertEquals(
                        DataValue.StringValue("changed"),
                        merged.resources
                            .getValue(resource)
                            .fields
                            .getValue("name"),
                    )
                    assertEquals(
                        DataValue.Integer(java.math.BigInteger.TWO),
                        merged.resources
                            .getValue(resource)
                            .fields
                            .getValue("count"),
                    )
                    firstStore.close()
                    secondStore.close()

                    val thirdCatalog = TestCatalogLease()
                    val fourthCatalog = TestCatalogLease()
                    val thirdStore = InMemoryAuthoringSnapshotStore(thirdCatalog, merged)
                    val fourthStore = InMemoryAuthoringSnapshotStore(fourthCatalog, merged)
                    val thirdRepository = repository(database, thirdStore, thirdCatalog)
                    val fourthRepository = repository(database, fourthStore, fourthCatalog)
                    val observations = evidence(merged.inputTokens, name)
                    assertIs<CommitResult.Committed>(
                        thirdRepository.commit(
                            edit(
                                "same_first",
                                merged.snapshot,
                                thirdCatalog,
                                observations,
                                EditIntent.SetValue(name, DataValue.StringValue("first")),
                            ),
                        ),
                    )
                    assertIs<CommitResult.Conflict>(
                        fourthRepository.commit(
                            edit(
                                "same_second",
                                merged.snapshot,
                                fourthCatalog,
                                observations,
                                EditIntent.SetValue(name, DataValue.StringValue("second")),
                            ),
                        ),
                    )
                    thirdStore.close()
                    fourthStore.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun persistentAcceptanceRollsBackReplaysAndRestoresInSequenceOrder() =
        runTest {
            val directory = Files.createTempDirectory("realm_authoring_acceptance")
            val telemetry = TelemetryTestHarness.create()
            try {
                var firstEdit: PreparedEdit? = null
                openDatabase(directory, telemetry).use { database ->
                    val catalog = TestCatalogLease()
                    val resource = ResourceId("page")
                    val initial = record(name = "initial")
                    val store =
                        InMemoryAuthoringSnapshotStore(
                            catalog,
                            AuthoredSnapshotSeed(
                                SnapshotId("realm:0"),
                                mapOf(resource to initial),
                                tokensFor(mapOf(resource to initial), catalog.generation),
                            ),
                        )
                    val repository = repository(database, store, catalog)
                    val invalid =
                        edit(
                            id = "invalid",
                            snapshot = SnapshotId("realm:0"),
                            catalog = catalog,
                            observations = emptyList(),
                            intent =
                                EditIntent.SetValue(
                                    ValueLocation(
                                        resource,
                                        ValuePath(
                                            listOf(
                                                com.typewritermc.authoring.PathSegment
                                                    .Field("missing"),
                                            ),
                                        ),
                                    ),
                                    DataValue.StringValue("rejected"),
                                ),
                        )
                    assertIs<CommitResult.Rejected>(repository.commit(invalid))

                    repeat(11) { index ->
                        val name = location(resource, "name")
                        val prepared =
                            edit(
                                id = "batch_${index + 1}",
                                snapshot = SnapshotId("realm:$index"),
                                catalog = catalog,
                                observations = evidence(store, name),
                                intent = EditIntent.SetValue(name, DataValue.StringValue("value_${index + 1}")),
                            )
                        if (index == 0) firstEdit = prepared
                        assertEquals(
                            SnapshotId("realm:${index + 1}"),
                            assertIs<CommitResult.Committed>(repository.commit(prepared)).snapshot,
                        )
                    }
                    assertEquals(
                        (1L..11L).map { "realm:$it" },
                        repository.pending().map { it.delta.snapshot.value },
                    )
                    store.close()
                }

                openDatabase(directory, telemetry).use { database ->
                    val seed = requireNotNull(SurrealAuthoringSeedLoader(database).load())
                    assertEquals(SnapshotId("realm:11"), seed.snapshot)
                    assertEquals(
                        DataValue.StringValue("value_11"),
                        seed.resources
                            .getValue(ResourceId("page"))
                            .fields
                            .getValue("name"),
                    )
                    val catalog = TestCatalogLease()
                    val activeCatalog = TestCatalogLease(generation = CatalogGeneration("catalog_changed"))
                    val store = InMemoryAuthoringSnapshotStore(catalog, seed)
                    val repository = repository(database, store, catalog, activeCatalog)
                    val replay = repository.commit(requireNotNull(firstEdit))
                    assertEquals(SnapshotId("realm:1"), assertIs<CommitResult.Committed>(replay).snapshot)
                    val name = location(ResourceId("page"), "name")
                    val fresh =
                        edit(
                            id = "fresh_after_catalog_change",
                            snapshot = seed.snapshot,
                            catalog = catalog,
                            observations = evidence(store, name),
                            intent = EditIntent.SetValue(name, DataValue.StringValue("fresh")),
                        )
                    val catalogChanged = assertIs<CommitResult.CatalogChanged>(repository.commit(fresh))
                    assertEquals(activeCatalog.generation, catalogChanged.actual)
                    val forged =
                        requireNotNull(firstEdit).copy(
                            intents =
                                listOf(
                                    EditIntent.SetValue(
                                        location(ResourceId("page"), "name"),
                                        DataValue.StringValue("forged"),
                                    ),
                                ),
                        )
                    assertIs<CommitResult.Rejected>(repository.commit(forged))
                    assertEquals(11, repository.pending().size)
                    store.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun creationReceiptSurvivesDatabaseRestartAndRejectsForgedReuse() =
        runTest {
            val directory = Files.createTempDirectory("realm_creation_receipt")
            val telemetry = TelemetryTestHarness.create()
            val evaluations = AtomicInteger()
            val request =
                InitializationRequest(
                    id = InitializationRequestId("request"),
                    catalog = CatalogGeneration("catalog"),
                    type =
                        TypeSelection.Complete(
                            com.typewritermc.types.TypeUse
                                .Named(TEST_TYPE),
                        ),
                    supplied = mapOf("seed" to DataValue.StringValue("one")),
                    intentHash = "declared",
                )
            val expected = PreparedCreation(record(name = "captured"), emptyList())
            try {
                openDatabase(directory, telemetry).use { database ->
                    val coordinator =
                        CreationCoordinator(
                            catalog = { TestCatalogLease(request.catalog) },
                            receipts = SurrealCreationReceiptStore(database),
                            evaluator =
                                CreationEvaluator { _, _ ->
                                    evaluations.incrementAndGet()
                                    expected
                                },
                        )
                    assertEquals(expected, coordinator.prepare(request))
                }
                openDatabase(directory, telemetry).use { database ->
                    val coordinator =
                        CreationCoordinator(
                            catalog = { TestCatalogLease(request.catalog) },
                            receipts = SurrealCreationReceiptStore(database),
                            evaluator =
                                CreationEvaluator { _, _ ->
                                    evaluations.incrementAndGet()
                                    record(name = "wrong").let { PreparedCreation(it, emptyList()) }
                                },
                        )
                    assertEquals(expected, coordinator.prepare(request))
                    val forged = request.copy(supplied = mapOf("seed" to DataValue.StringValue("two")))
                    val failure = runCatching { coordinator.prepare(forged) }.exceptionOrNull()
                    assertTrue(failure is IllegalArgumentException)
                }
                assertEquals(1, evaluations.get())
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun unavailableResourceKeepsDurableDefinitionAndDoesNotBlockUnrelatedSearchDocuments() =
        runTest {
            val directory = Files.createTempDirectory("realm_unavailable_resource")
            val telemetry = TelemetryTestHarness.create()
            try {
                openDatabase(directory, telemetry).use { database ->
                    val catalog = TestCatalogLease(CatalogGeneration("catalog"))
                    val unavailable = ResourceId("unavailable")
                    val book = ResourceId("book")
                    val tag = ResourceId("tag")
                    val unavailableType = TypeDefinitionId(TypeId.Qualified("removed", "resource"), 1)
                    val unavailableRecord =
                        AuthoringRecord(
                            configuration = TypeSelection.Complete(TypeUse.Named(unavailableType)),
                            fields = mapOf("legacy" to DataValue.StringValue("preserved")),
                        )
                    val resources =
                        mapOf(
                            unavailable to unavailableRecord,
                            book to record(name = "Book"),
                            tag to record(name = "Tag"),
                        )
                    val definitions =
                        mapOf(
                            unavailable to ResourceDefinitionId("removed_definition"),
                            book to ResourceDefinitionId("test"),
                            tag to ResourceDefinitionId("test"),
                        )
                    val store =
                        InMemoryAuthoringSnapshotStore(
                            catalog,
                            AuthoredSnapshotSeed(
                                SnapshotId("realm:0"),
                                resources,
                                tokensFor(resources, catalog.generation),
                                definitions,
                            ),
                        )

                    repository(database, store, catalog)

                    val indexedDefinitions =
                        database
                            .query("SELECT VALUE definition FROM authoring_search ORDER BY definition;")
                            .take(0)
                            .getArray()
                            .map { it.getString() }
                    assertEquals(listOf("removed_definition", "test", "test"), indexedDefinitions)
                    val loaded = requireNotNull(SurrealAuthoringSeedLoader(database).load())
                    assertEquals(unavailableRecord, loaded.resources[unavailable])
                    assertEquals(ResourceDefinitionId("removed_definition"), loaded.resourceDefinitions[unavailable])

                    store.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun unfinishedResourceConfigurationSurvivesDatabaseRestart() =
        runTest {
            val directory = Files.createTempDirectory("realm_pending_configuration")
            val telemetry = TelemetryTestHarness.create()
            val resource = ResourceId("page")
            val unrelated = ResourceId("unrelated")
            val generic = TypeDefinitionId(TypeId.Qualified("persistence", "dual"), 1)
            val coin = TypeDefinitionId(TypeId.Qualified("persistence", "coin"), 1)
            val gem = TypeDefinitionId(TypeId.Qualified("persistence", "gem"), 1)
            val first = ParameterKey(generic, 0)
            val second = ParameterKey(generic, 1)
            val coinUse = TypeUse.Named(coin)
            val gemUse = TypeUse.Named(gem)
            val definitions =
                listOf(
                    TypeDefinition(coin, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(gem, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(
                        generic,
                        parameters = listOf(TypeParameter(first, "first"), TypeParameter(second, "second")),
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(generic, "name"), TypeTemplate.Scalar(ScalarKind.Text)),
                                    FieldDeclaration(FieldOwner(generic, "first"), TypeTemplate.Parameter(first)),
                                    FieldDeclaration(FieldOwner(generic, "second"), TypeTemplate.Parameter(second)),
                                ),
                            ),
                    ),
                )
            val complete = TypeSelection.Complete(TypeUse.Named(generic, listOf(coinUse, gemUse)))
            val pending =
                TypeSelection.Pending(
                    generic,
                    listOf(ArgumentSelection.Chosen(coinUse), ArgumentSelection.Unfilled),
                )
            var accepted: TypeArgumentChangePreview? = null
            try {
                openDatabase(directory, telemetry).use { database ->
                    val catalog =
                        TestCatalogLease(
                            generation = CatalogGeneration("catalog"),
                            definitions = definitions,
                            resourceRoot = generic,
                        )
                    val initial =
                        AuthoringRecord(
                            configuration = complete,
                            fields =
                                mapOf(
                                    "name" to DataValue.StringValue("kept"),
                                    "first" to DataValue.Named(coinUse, DataValue.Record(emptyMap())),
                                    "second" to DataValue.Named(gemUse, DataValue.Record(emptyMap())),
                                ),
                        )
                    val seed =
                        AuthoredSnapshotSeed(
                            SnapshotId("realm:0"),
                            mapOf(resource to initial, unrelated to initial),
                            tokensFor(mapOf(resource to initial, unrelated to initial), catalog.generation),
                        )
                    val store = InMemoryAuthoringSnapshotStore(catalog, seed)
                    val repository = repository(database, store, catalog)
                    val operations = DefaultTypeArgumentOperations(repository, store)
                    val preview =
                        store.capture().use { snapshot ->
                            assertIs<TypePreviewResult.Ready>(operations.preview(resource, pending, snapshot)).preview
                        }
                    accepted = preview
                    val unrelatedName = location(unrelated, "name")
                    assertIs<CommitResult.Committed>(
                        repository.commit(
                            edit(
                                "unrelated_change",
                                seed.snapshot,
                                catalog,
                                evidence(store, unrelatedName),
                                EditIntent.SetValue(unrelatedName, DataValue.StringValue("changed")),
                            ),
                        ),
                    )
                    val result = operations.confirm(preview)
                    assertIs<CommitResult.Committed>(result)
                    assertEquals(result, operations.confirm(preview))
                    val conflictPreview =
                        store.capture().use { snapshot ->
                            assertIs<TypePreviewResult.Ready>(operations.preview(unrelated, pending, snapshot)).preview
                        }
                    assertIs<CommitResult.Committed>(
                        repository.commit(
                            edit(
                                "relevant_change",
                                assertIs<CommitResult.Committed>(result).snapshot,
                                catalog,
                                evidence(store, unrelatedName),
                                EditIntent.SetValue(unrelatedName, DataValue.StringValue("conflict")),
                            ),
                        ),
                    )
                    assertIs<CommitResult.Conflict>(operations.confirm(conflictPreview))
                    store.close()
                }

                openDatabase(directory, telemetry).use { reopened ->
                    val loaded = requireNotNull(SurrealAuthoringSeedLoader(reopened).load())
                    assertEquals(pending, loaded.resources.getValue(resource).configuration)
                    assertEquals(
                        DataValue.StringValue("kept"),
                        loaded.resources
                            .getValue(resource)
                            .fields
                            .getValue("name"),
                    )
                    assertEquals(
                        DataValue.Named(coinUse, DataValue.Record(emptyMap())),
                        loaded.resources
                            .getValue(resource)
                            .fields
                            .getValue("first"),
                    )
                    assertEquals(
                        DataValue.Unfilled,
                        loaded.resources
                            .getValue(resource)
                            .fields
                            .getValue("second"),
                    )
                    val replayCatalog =
                        TestCatalogLease(
                            definitions = definitions,
                            resourceRoot = generic,
                        )
                    val activeCatalog =
                        TestCatalogLease(
                            generation = CatalogGeneration("catalog_changed"),
                            definitions = definitions,
                            resourceRoot = generic,
                        )
                    val replayStore = InMemoryAuthoringSnapshotStore(replayCatalog, loaded)
                    val replayRepository = repository(reopened, replayStore, replayCatalog, activeCatalog)
                    val replayOperations = DefaultTypeArgumentOperations(replayRepository, replayStore)
                    assertEquals(
                        SnapshotId("realm:2"),
                        assertIs<CommitResult.Committed>(replayOperations.confirm(requireNotNull(accepted))).snapshot,
                    )
                    assertIs<CommitResult.Rejected>(
                        replayOperations.confirm(requireNotNull(accepted).copy(next = complete)),
                    )
                    assertIs<CommitResult.Rejected>(
                        replayOperations.confirm(requireNotNull(accepted).copy(clearedLocations = emptyList())),
                    )
                    assertIs<CommitResult.Rejected>(
                        replayOperations.confirm(
                            requireNotNull(accepted).copy(catalog = CatalogGeneration("other_catalog")),
                        ),
                    )
                    val forged =
                        requireNotNull(accepted).copy(
                            intents =
                                listOf(
                                    TypeRepairIntent.ConfigureResource(resource, complete),
                                ),
                        )
                    assertIs<CommitResult.Rejected>(replayOperations.confirm(forged))
                    replayStore.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }

    fun nestedReciprocalProjectionPersistsAndRemovesAtomically() =
        runTest {
            val directory = Files.createTempDirectory("realm_nested_relation")
            val telemetry = TelemetryTestHarness.create()
            val generation = CatalogGeneration("nested_relation_catalog")
            val node = TypeDefinitionId(TypeId.Qualified("test", "nested_node"), 1)
            val wrapperType = TypeDefinitionId(TypeId.Qualified("test", "nested_wrapper"), 1)
            val firstLink = TypeDefinitionId(TypeId.Qualified("test", "nested_first_link"), 1)
            val secondLink = TypeDefinitionId(TypeId.Qualified("test", "nested_second_link"), 1)
            val firstEndpoint = EndpointId("nested:first")
            val secondEndpoint = EndpointId("nested:second")
            val relation =
                RelationContract(
                    RelationId("nested"),
                    EndpointDefinition(
                        firstEndpoint,
                        EndpointSlot.First,
                        TypeTemplate.Named(node),
                        EndpointCardinality.One,
                        RelationDeletePolicy.CLEAR,
                    ),
                    EndpointDefinition(
                        secondEndpoint,
                        EndpointSlot.Second,
                        TypeTemplate.Named(node),
                        EndpointCardinality.One,
                        RelationDeletePolicy.CLEAR,
                    ),
                )
            val definitions =
                listOf(
                    TypeDefinition(
                        node,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(node, "wrapper"), TypeTemplate.Named(wrapperType)),
                                    FieldDeclaration(FieldOwner(node, "nestedSecond"), TypeTemplate.Named(secondLink)),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        wrapperType,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(FieldDeclaration(FieldOwner(wrapperType, "inner"), TypeTemplate.Named(firstLink))),
                            ),
                    ),
                    TypeDefinition(firstLink, representation = RepresentationTemplate.Link(firstEndpoint, TypeTemplate.Named(node))),
                    TypeDefinition(secondLink, representation = RepresentationTemplate.Link(secondEndpoint, TypeTemplate.Named(node))),
                )
            val bindings =
                listOf(
                    EndpointBindingTemplate(
                        firstEndpoint,
                        TypeTemplate.Named(node),
                        firstLink,
                        RelativeFieldPattern(
                            listOf(
                                FieldPatternSegment.Field("wrapper"),
                                FieldPatternSegment.Field("inner"),
                            ),
                        ),
                        TypeTemplate.Named(node),
                        false,
                    ),
                    EndpointBindingTemplate(
                        secondEndpoint,
                        TypeTemplate.Named(node),
                        secondLink,
                        RelativeFieldPattern(listOf(FieldPatternSegment.Field("nestedSecond"))),
                        TypeTemplate.Named(node),
                        false,
                    ),
                )
            val source = ResourceId("source")
            val target = ResourceId("target")
            val sourcePath = ValuePath(listOf(PathSegment.Field("wrapper"), PathSegment.Field("inner")))
            val targetPath = ValuePath(listOf(PathSegment.Field("nestedSecond")))

            fun catalog() =
                TestCatalogLease(
                    generation = generation,
                    definitions = definitions,
                    resourceRoot = node,
                    relations = listOf(relation),
                    endpointBindings = bindings,
                )

            fun wrapper(value: DataValue) =
                DataValue.Named(
                    TypeUse.Named(wrapperType),
                    DataValue.Record(mapOf("inner" to value)),
                )

            fun resource(
                inner: DataValue = DataValue.Unfilled,
                opposite: DataValue = DataValue.Unfilled,
            ) = AuthoringRecord(
                TypeSelection.Complete(TypeUse.Named(node)),
                mapOf("wrapper" to wrapper(inner), "nestedSecond" to opposite),
            )

            fun link(
                type: TypeDefinitionId,
                endpoint: EndpointId,
                resource: ResourceId,
                opposite: ValuePath?,
            ) = DataValue.Named(
                TypeUse.Named(type),
                DataValue.Link(endpoint, LinkTarget(resource, opposite)),
            )

            fun prepared(
                id: String,
                snapshot: SnapshotId,
                store: InMemoryAuthoringSnapshotStore,
                catalog: TestCatalogLease,
                resources: Map<ResourceId, AuthoringRecord>,
                intent: EditIntent.SetValue,
            ): PreparedEdit {
                val draft =
                    PreparedEdit(
                        BatchId(id),
                        generation,
                        snapshot,
                        emptyList(),
                        listOf(intent),
                    )
                val plan =
                    assertIs<MutationPlanningResult.Accepted>(
                        AuthoringMutationPlanner(catalog.checked, catalog.relations, catalog.endpointBindings).plan(resources, draft),
                    ).plan
                val identities = writeInputs(intent.at) + relationWriteInputs(plan.relations, resources)
                return draft.copy(
                    observations = identities.map { identity -> InputObservation(identity, store.currentToken(identity)) },
                )
            }

            try {
                val firstCatalog = catalog()
                val initial = mapOf(source to resource(), target to resource())
                val seed =
                    AuthoredSnapshotSeed(
                        SnapshotId("realm:0"),
                        initial,
                        tokensFor(initial, generation),
                    )
                openDatabase(directory, telemetry).use { database ->
                    val store = InMemoryAuthoringSnapshotStore(firstCatalog, seed)
                    val repository = repository(database, store, firstCatalog)
                    val intent =
                        EditIntent.SetValue(
                            ValueLocation(source, ValuePath(listOf(PathSegment.Field("wrapper")))),
                            wrapper(link(firstLink, firstEndpoint, target, null)),
                        )

                    assertIs<CommitResult.Committed>(
                        repository.commit(prepared("connect_nested", seed.snapshot, store, firstCatalog, initial, intent)),
                    )
                    assertEquals(
                        1,
                        database
                            .query("SELECT id FROM resource_relation;")
                            .take(0)
                            .getArray()
                            .len(),
                    )
                    store.close()
                }

                val secondCatalog = catalog()
                openDatabase(directory, telemetry).use { database ->
                    val loaded = requireNotNull(SurrealAuthoringSeedLoader(database).loadFor(secondCatalog))
                    val store = InMemoryAuthoringSnapshotStore(secondCatalog, loaded)
                    val repository = repository(database, store, secondCatalog)
                    val lease = store.capture()
                    val connectedResources = lease.root.resources
                    val sourceOccurrence =
                        lease.root.links.values
                            .single { occurrence -> occurrence.id.endpoint == firstEndpoint }
                    val targetOccurrence =
                        lease.root.links.values
                            .single { occurrence -> occurrence.id.endpoint == secondEndpoint }
                    assertEquals(sourcePath, sourceOccurrence.id.location.path)
                    assertEquals(LinkTarget(target, targetPath), sourceOccurrence.target)
                    assertEquals(targetPath, targetOccurrence.id.location.path)
                    assertEquals(LinkTarget(source, sourcePath), targetOccurrence.target)
                    val query =
                        with(SnapshotReads(lease.originalView())) {
                            RealmGraphReads.occurrences(
                                LinkInspectionQuery(
                                    setOf(source),
                                    RelationSelection.Contracts(setOf(relation.id), TraversalDirection.Forward),
                                ),
                            )
                        }
                    assertEquals(listOf(sourceOccurrence), query.occurrences)
                    assertTrue(query.failures.isEmpty())
                    lease.close()

                    val clear =
                        EditIntent.SetValue(
                            ValueLocation(source, ValuePath(listOf(PathSegment.Field("wrapper")))),
                            wrapper(DataValue.Unfilled),
                        )
                    assertIs<CommitResult.Committed>(
                        repository.commit(
                            prepared("clear_nested", loaded.snapshot, store, secondCatalog, connectedResources, clear),
                        ),
                    )
                    assertEquals(
                        0,
                        database
                            .query("SELECT id FROM resource_relation;")
                            .take(0)
                            .getArray()
                            .len(),
                    )
                    store.capture().use { current ->
                        val sourceRecord = current.root.resources.getValue(source)
                        val targetRecord = current.root.resources.getValue(target)
                        val sourceInner =
                            assertIs<DataValue.Record>(
                                assertIs<DataValue.Named>(sourceRecord.fields.getValue("wrapper")).payload,
                            ).fields.getValue("inner")
                        assertEquals(DataValue.Unfilled, sourceInner)
                        assertEquals(DataValue.Unfilled, targetRecord.fields.getValue("nestedSecond"))
                        assertTrue(current.root.links.isEmpty())
                    }
                    store.close()
                }

                val thirdCatalog = catalog()
                openDatabase(directory, telemetry).use { database ->
                    val loaded = requireNotNull(SurrealAuthoringSeedLoader(database).loadFor(thirdCatalog))
                    val store = InMemoryAuthoringSnapshotStore(thirdCatalog, loaded)
                    store.capture().use { current -> assertTrue(current.root.links.isEmpty()) }
                    assertEquals(
                        0,
                        database
                            .query("SELECT id FROM resource_relation;")
                            .take(0)
                            .getArray()
                            .len(),
                    )
                    store.close()
                }
            } finally {
                telemetry.close()
                directory.toFile().deleteRecursively()
            }
        }
}

private fun repository(
    database: Surreal,
    store: AuthoringSnapshotStore,
    catalog: TestCatalogLease,
    activeCatalog: TestCatalogLease = catalog,
) = SurrealAuthoringRepository(
    database = database,
    snapshots = store,
    catalog = { activeCatalog.retain() },
    searchIndexer = AuthoringSearchIndexer(),
)

private class FailFirstInstallSnapshotStore(
    private val delegate: AuthoringSnapshotStore,
) : AuthoringSnapshotStore by delegate {
    private var fail = true

    override fun <T> commitAndInstall(commit: () -> SnapshotCommit<T>): T {
        val committed = commit()
        val delta = committed.delta
        if (delta != null && fail) {
            fail = false
            error("simulated snapshot install failure")
        }
        if (delta != null) delegate.install(delta)
        return committed.result
    }
}

private fun edit(
    id: String,
    snapshot: SnapshotId,
    catalog: TestCatalogLease,
    observations: List<InputObservation>,
    intent: EditIntent,
) = PreparedEdit(
    id = BatchId(id),
    catalog = catalog.generation,
    snapshot = snapshot,
    observations = observations,
    intents = listOf(intent),
)

private fun location(
    resource: ResourceId,
    field: String,
) = ValueLocation(
    resource,
    ValuePath(
        listOf(
            com.typewritermc.authoring.PathSegment
                .Field(field),
        ),
    ),
)

private fun evidence(
    tokens: Map<InputIdentity, com.typewritermc.checking.InputToken>,
    location: ValueLocation,
): List<InputObservation> = writeInputs(location).map { identity -> InputObservation(identity, tokens.getValue(identity)) }

private fun evidence(
    store: InMemoryAuthoringSnapshotStore,
    location: ValueLocation,
): List<InputObservation> = writeInputs(location).map { identity -> InputObservation(identity, store.currentToken(identity)) }

private fun writeInputs(location: ValueLocation): List<InputIdentity> =
    listOf(
        InputIdentity.Existence(location.resource),
        InputIdentity.Form(ValueLocation(location.resource, ValuePath())),
        InputIdentity.Value(location),
    )

private fun openDatabase(
    directory: Path,
    telemetry: TelemetryTestHarness,
): Surreal {
    var latest: Throwable? = null
    repeat(100) {
        val database = Surreal()
        try {
            database.connect(DatabaseEndpoint.Embedded.SurrealKv(directory).connectionString)
            database.useNs("authoring_acceptance").useDb("authoring_acceptance")
            telemetry.telemetry.mainSpanBlocking(
                name = "test.realm.start",
                unhandledFailureSlug = ErrorSlug.of("test-realm-start-failed"),
            ) {
                SchemaMigrator(database).migrate()
            }
            return database
        } catch (failure: Throwable) {
            runCatching(database::close).exceptionOrNull()?.let(failure::addSuppressed)
            if (!failure.message.orEmpty().contains("already locked")) throw failure
            latest = failure
            Thread.sleep(20)
        }
    }
    throw requireNotNull(latest)
}

val SurrealAuthoringRepositoryTestSuite by testSuite {
    test("preparedIntentDigestFramesMoveIdsAndRetainsCollectionSemantics") {
        SurrealAuthoringRepositoryTest().preparedIntentDigestFramesMoveIdsAndRetainsCollectionSemantics()
    }
    test("emptyDurableStateProducesAnExactCatalogSeed") { SurrealAuthoringRepositoryTest().emptyDurableStateProducesAnExactCatalogSeed() }
    test("nativeOneSidedRelationsPersistMissingLocationsAndClearMetadata") {
        SurrealAuthoringRepositoryTest().nativeOneSidedRelationsPersistMissingLocationsAndClearMetadata()
    }
    test("cascadeDeletionRequiresEvidenceForEveryRemovedResource") {
        SurrealAuthoringRepositoryTest().cascadeDeletionRequiresEvidenceForEveryRemovedResource()
    }
    test("createdResourceCommitReplaysAfterInstallFailureAndRepairsMissingDerivedTokens") {
        SurrealAuthoringRepositoryTest().createdResourceCommitReplaysAfterInstallFailureAndRepairsMissingDerivedTokens()
    }
    test("changedCatalogRestartStagesAbsentEvidenceUntilDurableActivation") {
        SurrealAuthoringRepositoryTest().changedCatalogRestartStagesAbsentEvidenceUntilDurableActivation()
    }
    test(
        "failedCatalogSwapRollsBackTheDurableGeneration",
    ) { SurrealAuthoringRepositoryTest().failedCatalogSwapRollsBackTheDurableGeneration() }
    test("catalogActivationFenceExcludesAcceptanceUntilTheSynchronousSwapCompletes") {
        SurrealAuthoringRepositoryTest().catalogActivationFenceExcludesAcceptanceUntilTheSynchronousSwapCompletes()
    }
    test("preparedCatalogActivationRecoversAndKeepsAcceptanceClosedUntilFinalization") {
        SurrealAuthoringRepositoryTest().preparedCatalogActivationRecoversAndKeepsAcceptanceClosedUntilFinalization()
    }
    test("sharedFenceMergesIndependentChangesAndRejectsChangedEvidence") {
        SurrealAuthoringRepositoryTest().sharedFenceMergesIndependentChangesAndRejectsChangedEvidence()
    }
    test("persistentAcceptanceRollsBackReplaysAndRestoresInSequenceOrder") {
        SurrealAuthoringRepositoryTest().persistentAcceptanceRollsBackReplaysAndRestoresInSequenceOrder()
    }
    test("creationReceiptSurvivesDatabaseRestartAndRejectsForgedReuse") {
        SurrealAuthoringRepositoryTest().creationReceiptSurvivesDatabaseRestartAndRejectsForgedReuse()
    }
    test("unfinishedResourceConfigurationSurvivesDatabaseRestart") {
        SurrealAuthoringRepositoryTest().unfinishedResourceConfigurationSurvivesDatabaseRestart()
    }
    test("nestedReciprocalProjectionPersistsAndRemovesAtomically") {
        SurrealAuthoringRepositoryTest().nestedReciprocalProjectionPersistsAndRemovesAtomically()
    }
}
