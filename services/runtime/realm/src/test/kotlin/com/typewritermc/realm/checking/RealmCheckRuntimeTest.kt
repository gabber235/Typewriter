@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.checking.RealmChecks
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.check
import com.typewritermc.configuration.field
import com.typewritermc.discovery.OwnedCheck
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.contributionKey
import com.typewritermc.expression.eq
import com.typewritermc.expression.isInstance
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.compiler.AuthoringAcceptance
import com.typewritermc.realm.compiler.CapturedAssessment
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
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

        shouldThrow<IllegalArgumentException> {
            kotlinx.coroutines.runBlocking {
                runtime.evaluateCapture(
                    CheckAdmissionTarget.CapturedAcceptance(
                        store.capture().use {
                            it.root.copy(catalog = TestCatalogLease(generation = CatalogGeneration(value = "wrong")))
                        },
                    ),
                )
            }
        }

        runtime.close()
        store.close()
        catalog.openCount shouldBe 0
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
                OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 8), provider),
                OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 9), provider),
            )
        val providers = TestCheckProviders(owned, failOnRetain = 2)
        val catalog = TestCatalogLease(providers = providers)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(emptyMap()),
            )
        val runtime = RealmCheckRuntime(store)

        shouldThrow<IllegalStateException> {
            kotlinx.coroutines.runBlocking { runtime.reloadCatalog() }
        }

        providers.openLeases.get() shouldBe 0
        runtime.close()
        store.close()
        catalog.openCount shouldBe 0
    }

    test("concurrentReloadRetainsTheCatalogUsedBySubjectDiscovery") {
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    realm { }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 10), provider)))
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
        store.entered.await(5, TimeUnit.SECONDS) shouldBe true

        val second = executor.submit { kotlinx.coroutines.runBlocking { runtime.reloadCatalog() } }
        second.get(5, TimeUnit.SECONDS)
        providers.openLeases.get() shouldBe 2

        store.release.countDown()
        first.get(5, TimeUnit.SECONDS)
        providers.openLeases.get() shouldBe 1

        runtime.close()
        providers.openLeases.get() shouldBe 0
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
                            executions
                                .computeIfAbsent(
                                    draft.binding.location.resource,
                                ) { AtomicInteger() }
                                .incrementAndGet()
                            check(
                                read(
                                    boundPath<String>(
                                        location(
                                            draft.binding.location.resource,
                                            "name",
                                        ),
                                        TEXT_USE,
                                    ),
                                ),
                            ) {
                                it ==
                                    "valid"
                            }.error("Name is invalid.", draft.binding.location)
                        }
                        realm {
                            check(Availability.Available(false)) { it }
                                .error("Realm is invalid.", ValueLocation.of(ResourceId(value = "realm")))
                        }
                    }
                }
            val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 5), provider)))
            val catalog = TestCatalogLease(providers = providers)
            val first = ResourceId(value = "first")
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

            runtime.findings().size shouldBe 2
            runtime.findings().map { it.ticket.instance.rule.localIndex }.toSet() shouldBe setOf(0, 1)
            executions.getValue(first).get() shouldBe 1

            val second = ResourceId(value = "second")
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
            runtime.findings().size shouldBe 3
            executions.getValue(first).get() shouldBe 1
            executions.getValue(second).get() shouldBe 1

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
            runtime.findings().size shouldBe 3
            executions.getValue(first).get() shouldBe 1
            executions.getValue(second).get() shouldBe 2

            val secondRoot = ValueLocation.of(second)
            val removal =
                store.install(
                    store.prepare(
                        AuthoringViewDelta(removedResources = setOf(second)),
                    ),
                )
            runtime.invalidateCurrent()
            advanceUntilIdle()
            runtime.drain()
            runtime.findings().size shouldBe 2

            runtime.close()
            providers.openLeases.get() shouldBe 0
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
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 6), provider)))
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
        started.await(5, TimeUnit.SECONDS) shouldBe true
        providers.openLeases.get() shouldBe 1

        val closed = closer.submit { runtime.close() }
        Thread.sleep(50)
        closed.isDone shouldBe false
        providers.openLeases.get() shouldBe 1

        release.countDown()
        closed.get(5, TimeUnit.SECONDS)
        providers.openLeases.get() shouldBe 0
        worker.close()
        closer.shutdownNow()
        store.close()
    }

    test("currentIncompleteResultPublishesPartialFindingsAndDrainCompletes") {
        runTest {
            val resource = ResourceId(value = "page")
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        realm {
                            select(
                                TypedSelection(
                                    TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)),
                                    ExpressionNode.LiteralWrapper(
                                        skirout.editor.v1.type_catalog.DataValue
                                            .BooleanWrapper(true),
                                    ),
                                ),
                            )
                            check(Availability.Available(false)) { it }
                                .error("Partial finding.", ValueLocation.of(resource))
                        }
                    }
                }
            val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 11), provider)))
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
            finding.outcome shouldBe
                CheckOutcome.IncompleteWrapper("graph traversal limit exceeded")
            finding.status shouldBe skirout.editor.v1.checking.FindingStatus.CURRENT
            finding.findings.map { it.message } shouldBe listOf("Partial finding.")

            runtime.close()
            store.close()
        }
    }

    test("portableConfigurationRuleRunsForCurrentAndCapturedChecks") {
        runTest { assertPortableRuleReportsAnEmptyName(nameIsNotEmpty()) }
    }

    test("portableRuleEvaluatesTypedOperationsAgainstTheSnapshotCatalog") {
        runTest { assertPortableRuleReportsAnEmptyName(nameIsNotText()) }
    }

    test("capturedNeedsInputBlocksOtherwiseCompleteAndNativeConstructibleResource") {
        runTest {
            val resource = ResourceId(value = "complete")
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
            val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 21), provider)))
            val catalog = TestCatalogLease(providers = providers, nativeBindingFactories = listOf(TestResourceNativeBindingFactory))
            val authored = record(name = "ready")
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))

            val blocked = capturedAcceptance(store, runtime, catalog.generation)

            blocked.evidence.getValue(blocked.findings.single().id).catalog shouldBe catalog.generation
            blocked.evidence.getValue(blocked.findings.single().id).expectations shouldBe
                blocked.checks.results
                    .single()
                    .expectations
            blocked.findings
                .map { it.code } shouldBe listOf("check_needs_input")
            blocked.findings
                .map { it.primary } shouldBe listOf(unavailable)

            runtime.close()
            store.close()
        }
    }

    test("capturedAcceptanceRejectsCanonicalDuplicateSetValuesAndMapKeysAtExactItems") {
        runTest {
            val resource = ResourceId(value = "duplicates")
            val repeated =
                DataValue.named(
                    DUPLICATE_VALUE_USE,
                    DataValue.record(
                        linkedMapOf(
                            "first" to DataValue.StringValueWrapper("same"),
                            "second" to DataValue.StringValueWrapper("value"),
                        ),
                    ),
                )
            val equivalent =
                DataValue.named(
                    DUPLICATE_VALUE_USE,
                    DataValue.record(
                        linkedMapOf(
                            "second" to DataValue.StringValueWrapper("value"),
                            "first" to DataValue.StringValueWrapper("same"),
                        ),
                    ),
                )
            val authored =
                AuthoringRecord.of(
                    TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                    mapOf(
                        "values" to
                            DataValue.named(
                                DUPLICATE_SET_USE,
                                DataValue.setValue(
                                    listOf(
                                        ListItem(id = ItemId(value = "set_first"), value = repeated),
                                        ListItem(id = ItemId(value = "set_duplicate"), value = equivalent),
                                    ),
                                ),
                            ),
                        "mapping" to
                            DataValue.named(
                                DUPLICATE_MAP_USE,
                                DataValue.mapValue(
                                    listOf(
                                        MapRow(
                                            id = ItemId(value = "map_first"),
                                            key = repeated,
                                            value = DataValue.StringValueWrapper("one"),
                                        ),
                                        MapRow(
                                            id = ItemId(value = "map_duplicate"),
                                            key = equivalent,
                                            value = DataValue.StringValueWrapper("two"),
                                        ),
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

            val blocked = capturedAcceptance(store, runtime, catalog.generation)
            val intrinsic =
                blocked.findings.filter {
                    it.code in
                        setOf(
                            "duplicate_set_value",
                            "duplicate_map_key",
                        )
                }

            intrinsic.map { it.code } shouldBe listOf("duplicate_map_key", "duplicate_set_value")
            intrinsic.map { it.primary } shouldBe
                listOf(
                    ValueLocation.of(
                        resource,
                        ValuePath(
                            segments =
                                listOf(
                                    PathSegment.createField(name = "mapping"),
                                    PathSegment.createItem(id = ItemId(value = "map_duplicate")),
                                    PathSegment.MAP_KEY,
                                ),
                        ),
                    ),
                    ValueLocation.of(
                        resource,
                        ValuePath(
                            segments =
                                listOf(
                                    PathSegment.createField(name = "values"),
                                    PathSegment.createItem(id = ItemId(value = "set_duplicate")),
                                ),
                        ),
                    ),
                )

            runtime.close()
            store.close()
        }
    }

    test("capturedAcceptanceBlocksAnOtherwiseValidResourceWithPendingConfiguration") {
        runTest {
            val resource = ResourceId(value = "pending")
            val catalog = TestCatalogLease(nativeBindingFactories = listOf(TestResourceNativeBindingFactory))
            val authored =
                record(name = "ready").copy(
                    configuration = TypeSelection.createPending(definition = TEST_TYPE, arguments = emptyList()),
                )
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))

            val blocked = capturedAcceptance(store, runtime, catalog.generation)

            blocked.evidence.getValue(blocked.findings.single().id).expectations shouldBe
                listOf(
                    skirout.editor.v1.authoring_facts.EditExpectation
                        .createResource(id = resource, expected = authored),
                )
            blocked.findings
                .map { it.code } shouldBe listOf("pending_type")
            blocked.findings
                .map { it.primary } shouldBe listOf(ValueLocation.of(resource))

            runtime.close()
            store.close()
        }
    }

    test("boundedSubjectDiscoveryPublishesFailureAndBlocksCapturedCoverageWithoutDroppingPartialSubjects") {
        runTest {
            val origin = RuleOrigin(owner = TEST_TYPE, ordinal = 22)
            val path = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("name")))
            val rule =
                OwnedRule(
                    id = RuleId(origin = origin, localIndex = 0),
                    descriptor =
                        RuleDescriptor(
                            predicate =
                                nameIsNotEmpty(),
                        ),
                    diagnostic =
                        DiagnosticTemplate(
                            code = "name_empty",
                            message = "Name must not be empty.",
                            severity = DiagnosticSeverity.ERROR,
                            targets = listOf(path),
                        ),
                )
            val catalog =
                TestCatalogLease(
                    configuration =
                        listOf(
                            ConfigurationRecipe(
                                origin = origin,
                                relativePath = path,
                                representationCondition = RepresentationKind.TEXT,
                                rules = listOf(rule),
                            ),
                        ),
                )
            val resource = ResourceId(value = "element")
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
                    readLimits = ViewReadLimits(maxOccurrenceValues = 1),
                )

            runtime.reloadCatalog()
            advanceUntilIdle()
            runtime.drain()

            val current = runtime.findings()
            current.any { it.ticket.instance.location == location(resource, "name") } shouldBe true
            val discovery = current.single { it.ticket.instance.location == DISCOVERY_LOCATION_FOR_TEST }
            discovery.outcome.shouldBeInstanceOf<CheckOutcome.IncompleteWrapper>()
            discovery.findings.map { it.code } shouldBe listOf("check_discovery_incomplete")

            val captured = runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(store.capture().use { it.root }))
            captured.complete shouldBe false
            captured.results.any { it.ticket.instance.location == location(resource, "name") } shouldBe true
            captured.results.any {
                it.ticket.instance.location == DISCOVERY_LOCATION_FOR_TEST &&
                    it.outcome is CheckOutcome.IncompleteWrapper
            } shouldBe true

            runtime.close()
            store.close()
        }
    }

    test("removedEachSubjectKeepsWorkerAndProviderLeaseUntilWorkerStops") {
        val started = CountDownLatch(1)
        val release = CountDownLatch(1)
        val resource = ResourceId(value = "page")
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
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 12), provider)))
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
        started.await(5, TimeUnit.SECONDS) shouldBe true

        val removal =
            store.install(
                store.prepare(
                    AuthoringViewDelta(removedResources = setOf(resource)),
                ),
            )
        runtime.invalidateCurrent()
        val drained = waiter.submit { kotlinx.coroutines.runBlocking { runtime.drain() } }
        Thread.sleep(50)

        drained.isDone shouldBe false
        providers.openLeases.get() shouldBe 1

        release.countDown()
        drained.get(5, TimeUnit.SECONDS)
        runtime.close()
        providers.openLeases.get() shouldBe 0
        worker.close()
        waiter.shutdownNow()
        store.close()
    }

    test("invalidatedReplacementKeepsTheCancelledWorkerTrackedUntilItStops") {
        val executions = AtomicInteger()
        val blocked = CountDownLatch(1)
        val replacement = CountDownLatch(1)
        val release = CountDownLatch(1)
        val resource = ResourceId(value = "page")
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                        val execution = executions.incrementAndGet()
                        read(
                            boundPath<String>(
                                location(
                                    draft.binding.location.resource,
                                    "name",
                                ),
                                TEXT_USE,
                            ),
                        )
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
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 13), provider)))
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
        blocked.await(5, TimeUnit.SECONDS) shouldBe true

        val secondEdit = record(name = "third")
        val secondChange =
            store.install(
                store.prepare(
                    AuthoringViewDelta(upsertedResources = mapOf(resource to secondEdit)),
                ),
            )
        runtime.invalidateCurrent()
        replacement.await(5, TimeUnit.SECONDS) shouldBe true
        val drained = waiter.submit { kotlinx.coroutines.runBlocking { runtime.drain() } }
        Thread.sleep(50)

        drained.isDone shouldBe false
        providers.openLeases.get() shouldBe 1

        release.countDown()
        drained.get(5, TimeUnit.SECONDS)
        runtime.close()
        providers.openLeases.get() shouldBe 0
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
                        read(
                            boundPath<String>(
                                location(
                                    draft.binding.location.resource,
                                    "name",
                                ),
                                TEXT_USE,
                            ),
                        )
                    }
                }
            }
        val providers = TestCheckProviders(listOf(OwnedCheck(PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 7), provider)))
        val catalog = TestCatalogLease(providers = providers)
        val resource = ResourceId(value = "page")
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
        dependencies.entered.await(5, TimeUnit.SECONDS) shouldBe true

        val invalidated =
            invalidator.submit {
                store.install(store.prepare(AuthoringViewDelta(upsertedResources = mapOf(resource to record(name = "new")))))
                runtime.invalidateCurrent()
            }
        invalidated.isDone shouldBe false

        dependencies.release.countDown()
        invalidated.get(5, TimeUnit.SECONDS)
        kotlinx.coroutines.runBlocking { runtime.drain() }

        (executions.get() >= 2) shouldBe true
        runtime.findings().all { finding ->
            store.capture().use {
                it.root.values
                    .conflicts(finding.expectations)
                    .isEmpty()
            }
        } shouldBe true
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

private val DUPLICATE_VALUE_TYPE = TypeDefinitionId.qualified("test", "canonical_value")
private val DUPLICATE_SET_TYPE = TypeDefinitionId.qualified("test", "canonical_set")
private val DUPLICATE_MAP_TYPE = TypeDefinitionId.qualified("test", "canonical_map")
private val DUPLICATE_SET_PARAMETER = ParameterKey(owner = DUPLICATE_SET_TYPE, index = 0)
private val DUPLICATE_MAP_KEY_PARAMETER = ParameterKey(owner = DUPLICATE_MAP_TYPE, index = 0)
private val DUPLICATE_MAP_VALUE_PARAMETER = ParameterKey(owner = DUPLICATE_MAP_TYPE, index = 1)
private val DUPLICATE_VALUE_USE = DUPLICATE_VALUE_TYPE.namedUse()
private val DUPLICATE_SET_USE = DUPLICATE_SET_TYPE.namedUse(listOf(DUPLICATE_VALUE_USE.use))
private val DUPLICATE_MAP_USE =
    DUPLICATE_MAP_TYPE.namedUse(listOf(DUPLICATE_VALUE_USE.use, ScalarKind.TEXT.use))
private val DUPLICATE_DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = TEST_TYPE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_TYPE, name = "values"),
                                type = DUPLICATE_SET_TYPE.template(listOf(DUPLICATE_VALUE_TYPE.template())),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_TYPE, name = "mapping"),
                                type = DUPLICATE_MAP_TYPE.template(listOf(DUPLICATE_VALUE_TYPE.template(), ScalarKind.TEXT.template)),
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = DUPLICATE_VALUE_TYPE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUPLICATE_VALUE_TYPE, name = "first"),
                                type = ScalarKind.TEXT.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUPLICATE_VALUE_TYPE, name = "second"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = DUPLICATE_SET_TYPE,
            parameters = listOf(TypeParameter.partial(key = DUPLICATE_SET_PARAMETER, name = "T")),
            representation = RepresentationTemplate.createSequence(item = DUPLICATE_SET_PARAMETER.template, kind = CollectionKind.SET),
        ),
        TypeDefinition.partial(
            id = DUPLICATE_MAP_TYPE,
            parameters =
                listOf(
                    TypeParameter.partial(key = DUPLICATE_MAP_KEY_PARAMETER, name = "K"),
                    TypeParameter.partial(key = DUPLICATE_MAP_VALUE_PARAMETER, name = "V"),
                ),
            representation =
                RepresentationTemplate.createMapping(
                    key = DUPLICATE_MAP_KEY_PARAMETER.template,
                    value = DUPLICATE_MAP_VALUE_PARAMETER.template,
                ),
        ),
    )

private object TestResourceNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TYPE
    override val provider = NativeBindingId(value = "test.resource")

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
                    GeneratedNativeField("name", { arguments.resolver.bind(TEXT_USE) }, TestNativeResource::name),
                    GeneratedNativeField("count", { arguments.resolver.bind(INT_USE) }, TestNativeResource::count),
                    GeneratedNativeField("numbers", { arguments.resolver.bind(LIST_USE.use) }, TestNativeResource::numbers),
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
        observations: List<skirout.editor.v1.authoring_facts.EditExpectation>,
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
): CapturedAssessment {
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
                source =
                    contributionKey(
                        source = ContributionSourceId("test:checks"),
                        sourcePart = "checks",
                        producer = ProducerId("tests"),
                        name = ContributionName("realm"),
                    ),
                localIdentity = "checks",
            ),
        artifact = ArtifactId("test:checks"),
        sourcePart = "checks",
    )

private val DISCOVERY_LOCATION_FOR_TEST =
    ValueLocation.of(
        ResourceId(value = "typewriter.discovery"),
        ValuePath(
            segments =
                listOf(
                    PathSegment.createField(name = "subjects"),
                ),
        ),
    )

/**
 * Runs a portable configuration rule over an authored record whose name is empty and expects the current and captured
 * checks to report the rule's finding, so the rule evaluated to false on Realm.
 */
@OptIn(ExperimentalCoroutinesApi::class)
private suspend fun TestScope.assertPortableRuleReportsAnEmptyName(predicate: ExpressionNode) {
    val origin = RuleOrigin(owner = TEST_TYPE, ordinal = 20)
    val path = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("name")))
    val rule =
        OwnedRule(
            id = RuleId(origin = origin, localIndex = 0),
            descriptor =
                RuleDescriptor(
                    predicate =
                    predicate,
                ),
            diagnostic =
                DiagnosticTemplate(
                    code = "name_empty",
                    message = "Name must not be empty.",
                    severity = DiagnosticSeverity.ERROR,
                    targets = listOf(path),
                ),
        )
    val catalog =
        TestCatalogLease(
            configuration =
                listOf(
                    ConfigurationRecipe(
                        origin = origin,
                        relativePath = path,
                        representationCondition = RepresentationKind.TEXT,
                        rules = listOf(rule),
                    ),
                ),
        )
    val resource = ResourceId(value = "element")
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
    current.ticket.instance.rule shouldBe RuleId(origin = origin, localIndex = 0)
    current.ticket.instance.location shouldBe location(resource, "name")
    current.findings.map { it.code } shouldBe listOf("name_empty")

    val captured = runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(store.capture().use { it.root }))
    captured.complete shouldBe true
    captured.results
        .single()
        .findings
        .map { it.code } shouldBe listOf("name_empty")

    runtime.close()
    store.close()
}

/** The rule predicate "the configured text is not empty", built from portable primitives. */
private fun nameIsNotEmpty(): ExpressionNode =
    (
        com.typewritermc.expression
            .input<String>(ExpressionBindingId(value = "configured_value"))
            .length eq literal(0)
    ).not().toNode()

/** The rule predicate "the configured value is not text", which needs the catalog's type facts to evaluate. */
private fun nameIsNotText(): ExpressionNode =
    com.typewritermc.expression
        .input<String>(ExpressionBindingId(value = "configured_value"))
        .isInstance(ScalarKind.TEXT.use)
        .not()
        .toNode()
