package com.typewritermc.realm.checking

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundPath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckContext
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.checking.RealmChecks
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.check
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.configuration.RuleDescriptor
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.OwnedCheck
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.OperationId
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.compiler.AcceptanceResult
import com.typewritermc.realm.compiler.AuthoringAcceptance
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ParameterKey
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
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

@OptIn(ExperimentalCoroutinesApi::class)
val RealmCheckRuntimeTest by testSuite {
    test("capturedSetupFailureReleasesTheRetainedSnapshot") {
        val catalog = TestCatalogLease()
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(emptyMap()),
            )
        val runtime = RealmCheckRuntime(store)

        assertFailsWith<IllegalArgumentException> {
            kotlinx.coroutines.runBlocking {
                runtime.evaluateCapture(
                    CheckAdmissionTarget.CapturedAcceptance(
                        store.capture().use {
                            it.root.copy(catalog = TestCatalogLease(generation = CatalogGeneration("wrong")))
                        },
                    ),
                )
            }
        }

        runtime.close()
        store.close()
        assertEquals(0, catalog.openCount)
    }

    test("partialCatalogCollectionReleasesEveryAcquiredProviderLease") {
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    realm { }
                }
            }
        val owned =
            listOf(
                OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 8), provider),
                OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 9), provider),
            )
        val providers = TestCheckProviders(owned, failOnRetain = 2)
        val catalog = TestCatalogLease(providers = providers)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(emptyMap()),
            )
        val runtime = RealmCheckRuntime(store)

        assertFailsWith<IllegalStateException> {
            kotlinx.coroutines.runBlocking { runtime.reloadCatalog() }
        }

        assertEquals(0, providers.openLeases.get())
        runtime.close()
        store.close()
        assertEquals(0, catalog.openCount)
    }

    test("concurrentReloadRetainsTheCatalogUsedBySubjectDiscovery") {
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    realm { }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 10), provider)))
        val catalog = TestCatalogLease(providers = providers)
        val base =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(emptyMap()),
            )
        val store = BlockingCaptureStore(base, blockedCall = 2)
        val runtime = RealmCheckRuntime(store)
        val executor = Executors.newFixedThreadPool(2)
        val first = executor.submit { kotlinx.coroutines.runBlocking { runtime.reloadCatalog() } }
        assertTrue(store.entered.await(5, TimeUnit.SECONDS))

        val second = executor.submit { kotlinx.coroutines.runBlocking { runtime.reloadCatalog() } }
        second.get(5, TimeUnit.SECONDS)
        assertEquals(2, providers.openLeases.get())

        store.release.countDown()
        first.get(5, TimeUnit.SECONDS)
        assertEquals(1, providers.openLeases.get())

        runtime.close()
        assertEquals(0, providers.openLeases.get())
        executor.shutdownNow()
        base.close()
    }

    test("eachSubjectsFollowMembershipAndRegistrationsKeepDistinctRuleIds") {
        runTest {
            val executions = ConcurrentHashMap<ResourceId, AtomicInteger>()
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                            executions.computeIfAbsent(draft.binding.location.resource) { AtomicInteger() }.incrementAndGet()
                            check(read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))) { it == "valid" }
                                .error("Name is invalid.", draft.binding.location)
                        }
                        realm {
                            check(Availability.Available(false)) { it }
                                .error("Realm is invalid.", ValueLocation(ResourceId("realm"), ValuePath()))
                        }
                    }
                }
            val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 5), provider)))
            val catalog = TestCatalogLease(providers = providers)
            val first = ResourceId("first")
            val initial = record(name = "bad")
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(first to initial)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))
            runtime.reloadCatalog()
            advanceUntilIdle()
            runtime.drain()

            assertEquals(2, runtime.findings().size)
            assertEquals(setOf(0, 1), runtime.findings().map { it.ticket.instance.rule.localIndex }.toSet())
            assertEquals(1, executions.getValue(first).get())

            val second = ResourceId("second")
            val added = record(name = "bad")
            val addedTokens =
                tokensFor(mapOf(second to added), catalog.generation, "added")
                    .filterKeys { it !is com.typewritermc.checking.InputIdentity.Catalog }
            val addition =
                store.install(
                    store.prepare(
                        AuthoringViewDelta(upsertedResources = mapOf(second to added)),
                    ),
                )
            runtime.invalidateCurrent()
            advanceUntilIdle()
            runtime.drain()
            assertEquals(3, runtime.findings().size)
            assertEquals(1, executions.getValue(first).get())
            assertEquals(1, executions.getValue(second).get())

            val edited = record(name = "valid")
            val edit =
                store.install(
                    store.prepare(
                        AuthoringViewDelta(upsertedResources = mapOf(second to edited)),
                    ),
                )
            runtime.invalidateCurrent()
            advanceUntilIdle()
            runtime.drain()
            assertEquals(3, runtime.findings().size)
            assertEquals(1, executions.getValue(first).get())
            assertEquals(2, executions.getValue(second).get())

            val secondRoot = ValueLocation(second, ValuePath())
            val removal =
                store.install(
                    store.prepare(
                        AuthoringViewDelta(removedResources = setOf(second)),
                    ),
                )
            runtime.invalidateCurrent()
            advanceUntilIdle()
            runtime.drain()
            assertEquals(2, runtime.findings().size)

            runtime.close()
            assertEquals(0, providers.openLeases.get())
            store.close()
        }
    }

    test("providerLeaseStaysOpenUntilCancelledWorkerActuallyStops") {
        val started = CountDownLatch(1)
        val release = CountDownLatch(1)
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    realm {
                        started.countDown()
                        release.await()
                    }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 6), provider)))
        val catalog = TestCatalogLease(providers = providers)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(emptyMap()),
            )
        val worker = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
        val closer = Executors.newSingleThreadExecutor()
        val runtime = RealmCheckRuntime(store, worker)
        kotlinx.coroutines.runBlocking { runtime.reloadCatalog() }
        assertTrue(started.await(5, TimeUnit.SECONDS))
        assertEquals(1, providers.openLeases.get())

        val closed = closer.submit { runtime.close() }
        Thread.sleep(50)
        assertFalse(closed.isDone)
        assertEquals(1, providers.openLeases.get())

        release.countDown()
        closed.get(5, TimeUnit.SECONDS)
        assertEquals(0, providers.openLeases.get())
        worker.close()
        closer.shutdownNow()
        store.close()
    }

    test("currentIncompleteResultPublishesPartialFindingsAndDrainCompletes") {
        runTest {
            val resource = ResourceId("page")
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        realm {
                            select(
                                TypedSelection(
                                    TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)),
                                    ExpressionNode.Literal(DataValue.Boolean(true)),
                                ),
                            )
                            check(Availability.Available(false)) { it }
                                .error("Partial finding.", ValueLocation(resource, ValuePath()))
                        }
                    }
                }
            val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 11), provider)))
            val catalog = TestCatalogLease(providers = providers)
            val authored = record(name = "valid")
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val evaluator =
                SelectionPredicateEvaluator { _, _, reads ->
                    (reads as CapturedAuthoringReads).recordIncomplete("graph traversal limit exceeded")
                    Availability.Available(true)
                }
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler), selectionPredicates = evaluator)

            runtime.reloadCatalog()
            advanceUntilIdle()
            runtime.drain()

            val finding = runtime.findings().single()
            assertEquals(
                com.typewritermc.checking.CheckOutcome
                    .Incomplete("graph traversal limit exceeded"),
                finding.outcome,
            )
            assertEquals(com.typewritermc.checking.FindingStatus.Current, finding.status)
            assertEquals(listOf("Partial finding."), finding.findings.map { it.message })

            runtime.close()
            store.close()
        }
    }

    test("portableConfigurationRuleRunsForCurrentAndCapturedChecks") {
        runTest {
            val origin = RuleOrigin(TEST_TYPE, 20)
            val path = RelativeFieldPattern(listOf(FieldPatternSegment.Field("name")))
            val rule =
                OwnedRule(
                    id = RuleId(origin, 0),
                    descriptor =
                        RuleDescriptor(
                            ExpressionNode.Call(
                                OperationId("typewriter.rule.nonEmpty"),
                                listOf(ExpressionNode.Read(ExpressionBindingId("configured_value"), ValuePath())),
                            ),
                        ),
                    diagnostic = DiagnosticTemplate("name_empty", "Name must not be empty.", DiagnosticSeverity.Error, listOf(path)),
                )
            val catalog =
                TestCatalogLease(
                    configuration = listOf(ConfigurationRecipe(origin, path, RepresentationKind.Text, listOf(rule))),
                )
            val resource = ResourceId("element")
            val authored = record(name = "")
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))

            runtime.reloadCatalog()
            advanceUntilIdle()
            runtime.drain()

            val current = runtime.findings().single()
            assertEquals(RuleId(origin, 0), current.ticket.instance.rule)
            assertEquals(location(resource, "name"), current.ticket.instance.location)
            assertEquals(listOf("name_empty"), current.findings.map { it.code })

            val captured = runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(store.capture().use { it.root }))
            assertTrue(captured.complete)
            assertEquals(
                listOf("name_empty"),
                captured.results
                    .single()
                    .findings
                    .map { it.code },
            )

            runtime.close()
            store.close()
        }
    }

    test("capturedNeedsInputBlocksOtherwiseCompleteAndNativeConstructibleResource") {
        runTest {
            val resource = ResourceId("complete")
            val unavailable = location(resource, "computed")
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        realm {
                            check(read(boundPath<String>(unavailable, TEXT_USE))) { value -> value.isNotBlank() }
                                .error("Computed value is required.", unavailable)
                        }
                    }
                }
            val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 21), provider)))
            val catalog = TestCatalogLease(providers = providers, nativeBindingFactories = listOf(TestResourceNativeBindingFactory))
            val authored = record(name = "ready")
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))

            val blocked =
                assertIs<AcceptanceResult.Blocked>(
                    capturedAcceptance(store, runtime, catalog.generation),
                )

            assertEquals(listOf("check_needs_input"), blocked.findings.map { it.code })
            assertEquals(listOf(unavailable), blocked.findings.map { it.primary })

            runtime.close()
            store.close()
        }
    }

    test("capturedAcceptanceRejectsCanonicalDuplicateSetValuesAndMapKeysAtExactItems") {
        runTest {
            val resource = ResourceId("duplicates")
            val repeated =
                DataValue.Named(
                    DUPLICATE_VALUE_USE,
                    DataValue.Record(
                        linkedMapOf(
                            "first" to DataValue.StringValue("same"),
                            "second" to DataValue.StringValue("value"),
                        ),
                    ),
                )
            val equivalent =
                DataValue.Named(
                    DUPLICATE_VALUE_USE,
                    DataValue.Record(
                        linkedMapOf(
                            "second" to DataValue.StringValue("value"),
                            "first" to DataValue.StringValue("same"),
                        ),
                    ),
                )
            val authored =
                AuthoringRecord(
                    TypeSelection.Complete(TypeUse.Named(TEST_TYPE)),
                    mapOf(
                        "values" to
                            DataValue.Named(
                                DUPLICATE_SET_USE,
                                DataValue.SetValue(
                                    listOf(
                                        ListItem(ItemId("set_first"), repeated),
                                        ListItem(ItemId("set_duplicate"), equivalent),
                                    ),
                                ),
                            ),
                        "mapping" to
                            DataValue.Named(
                                DUPLICATE_MAP_USE,
                                DataValue.MapValue(
                                    listOf(
                                        MapRow(ItemId("map_first"), repeated, DataValue.StringValue("one")),
                                        MapRow(ItemId("map_duplicate"), equivalent, DataValue.StringValue("two")),
                                    ),
                                ),
                            ),
                    ),
                )
            val catalog = TestCatalogLease(definitions = DUPLICATE_DEFINITIONS)
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))

            val blocked =
                assertIs<AcceptanceResult.Blocked>(
                    capturedAcceptance(store, runtime, catalog.generation),
                )
            val intrinsic = blocked.findings.filter { it.code in setOf("duplicate_set_value", "duplicate_map_key") }

            assertEquals(listOf("duplicate_set_value", "duplicate_map_key"), intrinsic.map { it.code })
            assertEquals(
                listOf(
                    ValueLocation(
                        resource,
                        ValuePath(listOf(PathSegment.Field("values"), PathSegment.Item(ItemId("set_duplicate")))),
                    ),
                    ValueLocation(
                        resource,
                        ValuePath(
                            listOf(
                                PathSegment.Field("mapping"),
                                PathSegment.Item(ItemId("map_duplicate")),
                                PathSegment.MapKey,
                            ),
                        ),
                    ),
                ),
                intrinsic.map { it.primary },
            )

            runtime.close()
            store.close()
        }
    }

    test("capturedAcceptanceBlocksAnOtherwiseValidResourceWithPendingConfiguration") {
        runTest {
            val resource = ResourceId("pending")
            val catalog = TestCatalogLease(nativeBindingFactories = listOf(TestResourceNativeBindingFactory))
            val authored =
                record(name = "ready").copy(
                    configuration = TypeSelection.Pending(TEST_TYPE, emptyList()),
                )
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))

            val blocked =
                assertIs<AcceptanceResult.Blocked>(
                    capturedAcceptance(store, runtime, catalog.generation),
                )

            assertEquals(listOf("pending_type"), blocked.findings.map { it.code })
            assertEquals(listOf(ValueLocation(resource, ValuePath())), blocked.findings.map { it.primary })

            runtime.close()
            store.close()
        }
    }

    test("boundedSubjectDiscoveryPublishesFailureAndBlocksCapturedCoverageWithoutDroppingPartialSubjects") {
        runTest {
            val origin = RuleOrigin(TEST_TYPE, 22)
            val path = RelativeFieldPattern(listOf(FieldPatternSegment.Field("name")))
            val rule =
                OwnedRule(
                    id = RuleId(origin, 0),
                    descriptor =
                        RuleDescriptor(
                            ExpressionNode.Call(
                                OperationId("typewriter.rule.nonEmpty"),
                                listOf(ExpressionNode.Read(ExpressionBindingId("configured_value"), ValuePath())),
                            ),
                        ),
                    diagnostic = DiagnosticTemplate("name_empty", "Name must not be empty.", DiagnosticSeverity.Error, listOf(path)),
                )
            val catalog =
                TestCatalogLease(
                    configuration = listOf(ConfigurationRecipe(origin, path, RepresentationKind.Text, listOf(rule))),
                )
            val resource = ResourceId("element")
            val authored = record(name = "valid")
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime =
                RealmCheckRuntime(
                    store,
                    StandardTestDispatcher(testScheduler),
                    readLimits = SnapshotReadLimits(maxOccurrenceValues = 1),
                )

            runtime.reloadCatalog()
            advanceUntilIdle()
            runtime.drain()

            val current = runtime.findings()
            assertTrue(current.any { it.ticket.instance.location == location(resource, "name") })
            val discovery = current.single { it.ticket.instance.location == DISCOVERY_LOCATION_FOR_TEST }
            assertIs<com.typewritermc.checking.CheckOutcome.Incomplete>(discovery.outcome)
            assertEquals(listOf("check_discovery_incomplete"), discovery.findings.map { it.code })

            val captured = runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(store.capture().use { it.root }))
            assertFalse(captured.complete)
            assertTrue(captured.results.any { it.ticket.instance.location == location(resource, "name") })
            assertTrue(
                captured.results.any {
                    it.ticket.instance.location == DISCOVERY_LOCATION_FOR_TEST &&
                        it.outcome is com.typewritermc.checking.CheckOutcome.Incomplete
                },
            )

            runtime.close()
            store.close()
        }
    }

    test("removedEachSubjectKeepsWorkerAndProviderLeaseUntilWorkerStops") {
        val started = CountDownLatch(1)
        val release = CountDownLatch(1)
        val resource = ResourceId("page")
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) {
                        started.countDown()
                        while (release.count > 0) {
                            try {
                                release.await()
                            } catch (_: InterruptedException) {
                                Unit
                            }
                        }
                    }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 12), provider)))
        val catalog = TestCatalogLease(providers = providers)
        val authored = record(name = "valid")
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to authored)),
            )
        val worker = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
        val waiter = Executors.newSingleThreadExecutor()
        val runtime = RealmCheckRuntime(store, worker)
        kotlinx.coroutines.runBlocking { runtime.reloadCatalog() }
        assertTrue(started.await(5, TimeUnit.SECONDS))

        val removal =
            store.install(
                store.prepare(
                    AuthoringViewDelta(removedResources = setOf(resource)),
                ),
            )
        runtime.invalidateCurrent()
        val drained = waiter.submit { kotlinx.coroutines.runBlocking { runtime.drain() } }
        Thread.sleep(50)

        assertFalse(drained.isDone)
        assertEquals(1, providers.openLeases.get())

        release.countDown()
        drained.get(5, TimeUnit.SECONDS)
        runtime.close()
        assertEquals(0, providers.openLeases.get())
        worker.close()
        waiter.shutdownNow()
        store.close()
    }

    test("invalidatedReplacementKeepsTheCancelledWorkerTrackedUntilItStops") {
        val executions = AtomicInteger()
        val blocked = CountDownLatch(1)
        val replacement = CountDownLatch(1)
        val release = CountDownLatch(1)
        val resource = ResourceId("page")
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                        val execution = executions.incrementAndGet()
                        read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
                        if (execution == 2) {
                            blocked.countDown()
                            while (release.count > 0) {
                                try {
                                    release.await()
                                } catch (_: InterruptedException) {
                                    Unit
                                }
                            }
                        } else if (execution >= 3) {
                            replacement.countDown()
                        }
                    }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 13), provider)))
        val catalog = TestCatalogLease(providers = providers)
        val initial = record(name = "first")
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to initial)),
            )
        val worker = Executors.newFixedThreadPool(2).asCoroutineDispatcher()
        val waiter = Executors.newSingleThreadExecutor()
        val runtime = RealmCheckRuntime(store, worker)
        kotlinx.coroutines.runBlocking {
            runtime.reloadCatalog()
            runtime.drain()
        }

        val firstEdit = record(name = "second")
        val firstChange =
            store.install(
                store.prepare(
                    AuthoringViewDelta(upsertedResources = mapOf(resource to firstEdit)),
                ),
            )
        runtime.invalidateCurrent()
        assertTrue(blocked.await(5, TimeUnit.SECONDS))

        val secondEdit = record(name = "third")
        val secondChange =
            store.install(
                store.prepare(
                    AuthoringViewDelta(upsertedResources = mapOf(resource to secondEdit)),
                ),
            )
        runtime.invalidateCurrent()
        assertTrue(replacement.await(5, TimeUnit.SECONDS))
        val drained = waiter.submit { kotlinx.coroutines.runBlocking { runtime.drain() } }
        Thread.sleep(50)

        assertFalse(drained.isDone)
        assertEquals(1, providers.openLeases.get())

        release.countDown()
        drained.get(5, TimeUnit.SECONDS)
        runtime.close()
        assertEquals(0, providers.openLeases.get())
        worker.close()
        waiter.shutdownNow()
        store.close()
    }

    test("invalidationWaitsForFirstDependencyInsertionBeforeLookingUpAffectedChecks") {
        val executions = AtomicInteger()
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                        executions.incrementAndGet()
                        read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
                    }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(TEST_TYPE, 7), provider)))
        val catalog = TestCatalogLease(providers = providers)
        val resource = ResourceId("page")
        val initial = record(name = "old")
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to initial)),
            )
        val dependencies = BlockingFirstReplaceIndex()
        val worker = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
        val invalidator = Executors.newSingleThreadExecutor()
        val runtime = RealmCheckRuntime(store, worker, dependencies)
        kotlinx.coroutines.runBlocking { runtime.reloadCatalog() }
        assertTrue(dependencies.entered.await(5, TimeUnit.SECONDS))

        val invalidated =
            invalidator.submit {
                store.install(store.prepare(AuthoringViewDelta(upsertedResources = mapOf(resource to record(name = "new")))))
                runtime.invalidateCurrent()
            }
        assertFalse(invalidated.isDone)

        dependencies.release.countDown()
        invalidated.get(5, TimeUnit.SECONDS)
        kotlinx.coroutines.runBlocking { runtime.drain() }

        assertTrue(executions.get() >= 2)
        assertTrue(
            runtime.findings().all { finding ->
                store.capture().use {
                    it.root.values
                        .conflicts(finding.expectations)
                        .isEmpty()
                }
            },
        )
        runtime.close()
        worker.close()
        invalidator.shutdownNow()
        store.close()
    }
}

private data class TestNativeResource(
    val name: String,
    val count: Int,
    val numbers: List<*>,
)

private val DUPLICATE_VALUE_TYPE = TypeDefinitionId(TypeId.Qualified("test", "canonical_value"), 1)
private val DUPLICATE_SET_TYPE = TypeDefinitionId(TypeId.Qualified("test", "canonical_set"), 1)
private val DUPLICATE_MAP_TYPE = TypeDefinitionId(TypeId.Qualified("test", "canonical_map"), 1)
private val DUPLICATE_SET_PARAMETER = ParameterKey(DUPLICATE_SET_TYPE, 0)
private val DUPLICATE_MAP_KEY_PARAMETER = ParameterKey(DUPLICATE_MAP_TYPE, 0)
private val DUPLICATE_MAP_VALUE_PARAMETER = ParameterKey(DUPLICATE_MAP_TYPE, 1)
private val DUPLICATE_VALUE_USE = TypeUse.Named(DUPLICATE_VALUE_TYPE)
private val DUPLICATE_SET_USE = TypeUse.Named(DUPLICATE_SET_TYPE, listOf(DUPLICATE_VALUE_USE))
private val DUPLICATE_MAP_USE =
    TypeUse.Named(
        DUPLICATE_MAP_TYPE,
        listOf(DUPLICATE_VALUE_USE, TypeUse.Scalar(ScalarKind.Text)),
    )
private val DUPLICATE_DEFINITIONS =
    listOf(
        TypeDefinition(
            TEST_TYPE,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(
                            FieldOwner(TEST_TYPE, "values"),
                            TypeTemplate.Named(DUPLICATE_SET_TYPE, listOf(TypeTemplate.Named(DUPLICATE_VALUE_TYPE))),
                        ),
                        FieldDeclaration(
                            FieldOwner(TEST_TYPE, "mapping"),
                            TypeTemplate.Named(
                                DUPLICATE_MAP_TYPE,
                                listOf(TypeTemplate.Named(DUPLICATE_VALUE_TYPE), TypeTemplate.Scalar(ScalarKind.Text)),
                            ),
                        ),
                    ),
                ),
        ),
        TypeDefinition(
            DUPLICATE_VALUE_TYPE,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(FieldOwner(DUPLICATE_VALUE_TYPE, "first"), TypeTemplate.Scalar(ScalarKind.Text)),
                        FieldDeclaration(FieldOwner(DUPLICATE_VALUE_TYPE, "second"), TypeTemplate.Scalar(ScalarKind.Text)),
                    ),
                ),
        ),
        TypeDefinition(
            DUPLICATE_SET_TYPE,
            parameters = listOf(TypeParameter(DUPLICATE_SET_PARAMETER, "T")),
            representation =
                RepresentationTemplate.Sequence(TypeTemplate.Parameter(DUPLICATE_SET_PARAMETER), CollectionKind.Set),
        ),
        TypeDefinition(
            DUPLICATE_MAP_TYPE,
            parameters =
                listOf(
                    TypeParameter(DUPLICATE_MAP_KEY_PARAMETER, "K"),
                    TypeParameter(DUPLICATE_MAP_VALUE_PARAMETER, "V"),
                ),
            representation =
                RepresentationTemplate.Mapping(
                    TypeTemplate.Parameter(DUPLICATE_MAP_KEY_PARAMETER),
                    TypeTemplate.Parameter(DUPLICATE_MAP_VALUE_PARAMETER),
                ),
        ),
    )

private object TestResourceNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TYPE
    override val provider = NativeBindingId("test.resource")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.resource",
            nativeClass = TestNativeResource::class,
            fields =
                listOf(
                    GeneratedNativeField("name", arguments.resolver.bind(TEXT_USE), TestNativeResource::name),
                    GeneratedNativeField("count", arguments.resolver.bind(INT_USE), TestNativeResource::count),
                    GeneratedNativeField("numbers", arguments.resolver.bind(LIST_USE), TestNativeResource::numbers),
                ),
            construct = { fields ->
                TestNativeResource(
                    name = fields.getValue("name") as String,
                    count = fields.getValue("count") as Int,
                    numbers = fields.getValue("numbers") as List<*>,
                )
            },
        )
}

private class BlockingFirstReplaceIndex : ReverseDependencyIndex {
    private val delegate = DefaultReverseDependencyIndex()
    private val first = AtomicBoolean(true)
    val entered = CountDownLatch(1)
    val release = CountDownLatch(1)

    override fun replace(
        instance: CheckInstanceId,
        observations: List<com.typewritermc.authoring.EditExpectation>,
    ) {
        if (first.compareAndSet(true, false)) {
            entered.countDown()
            release.await()
        }
        delegate.replace(instance, observations)
    }

    override fun affectedBy(changed: Set<com.typewritermc.checking.InputIdentity>): Set<CheckInstanceId> = delegate.affectedBy(changed)

    override fun retire(instance: CheckInstanceId) = delegate.retire(instance)
}

private class BlockingCaptureStore(
    private val delegate: com.typewritermc.realm.authoring.AuthoringViewStore,
    private val blockedCall: Int,
) : com.typewritermc.realm.authoring.AuthoringViewStore by delegate {
    private val calls = AtomicInteger()
    val entered = CountDownLatch(1)
    val release = CountDownLatch(1)

    override fun capture(): com.typewritermc.realm.authoring.AuthoringLease {
        if (calls.incrementAndGet() == blockedCall) {
            entered.countDown()
            release.await()
        }
        return delegate.capture()
    }
}

private class TestCheckProviders(
    private val ownedChecks: List<OwnedCheck>,
    private val failOnRetain: Int? = null,
) : OwnedProviderRegistry {
    val openLeases = AtomicInteger()
    private val retainCalls = AtomicInteger()

    override fun retain(origin: ProviderOrigin): ProviderLease {
        check(retainCalls.incrementAndGet() != failOnRetain) { "provider retain failed" }
        openLeases.incrementAndGet()
        return object : ProviderLease {
            private var open = true

            override fun close() {
                if (open) {
                    open = false
                    openLeases.decrementAndGet()
                }
            }
        }
    }

    override fun configurations(): List<OwnedConfiguration> = emptyList()

    override fun presentations(): List<OwnedPresentation> = emptyList()

    override fun nativeBindings(): List<OwnedNativeBinding> = emptyList()

    override fun checks(): List<OwnedCheck> = ownedChecks
}

private suspend fun capturedAcceptance(
    store: com.typewritermc.realm.authoring.AuthoringViewStore,
    runtime: RealmCheckRuntime,
    generation: CatalogGeneration,
): AcceptanceResult {
    val acceptance = AuthoringAcceptance(store, runtime)
    val capture = acceptance.capture()
    return try {
        acceptance.evaluate(capture)
    } finally {
        capture.close()
    }
}

private val PROVIDER_ORIGIN =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                ContributionKey(
                    source = ContributionSourceId("test:checks"),
                    sourcePart = "checks",
                    producer = ProducerId("tests"),
                    name = ContributionName("realm"),
                ),
                "checks",
            ),
        artifact = ArtifactId("test:checks"),
        sourcePart = "checks",
    )

private val DISCOVERY_LOCATION_FOR_TEST =
    ValueLocation(
        ResourceId("typewriter.discovery"),
        ValuePath(
            listOf(
                com.typewritermc.authoring.PathSegment
                    .Field("subjects"),
            ),
        ),
    )
