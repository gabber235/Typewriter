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
import com.typewritermc.expression.eq
import com.typewritermc.expression.isInstance
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.INT_USE
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.LIST_USE
import com.typewritermc.realm.authoring.SelectionPredicateEvaluator
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TEXT_USE
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.TestDraftType
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.conflicts
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.publication.CapturedAssessment
import com.typewritermc.realm.publication.ResourceReadiness
import com.typewritermc.realm.testing.CHECK_PROVIDER_ORIGIN
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.TestCheckProviders
import com.typewritermc.realm.testing.checksOf
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.integerScalar
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
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.concurrent.thread

@OptIn(ExperimentalCoroutinesApi::class)
val RealmCheckRuntimeTest by testSuite {
    test("a capture against another catalog generation is refused and releases its retained snapshot") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(emptyMap()))
        val runtime = RealmCheckRuntime(store)

        shouldThrow<IllegalArgumentException> {
            runBlocking {
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

    test("a catalog reload that fails to retain a provider releases every provider lease it took") {
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    realm { }
                }
            }
        val owned =
            listOf(
                OwnedCheck(CHECK_PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 8), provider),
                OwnedCheck(CHECK_PROVIDER_ORIGIN, RuleOrigin(owner = TEST_TYPE, ordinal = 9), provider),
            )
        val providers = TestCheckProviders(owned, failOnRetain = 2)
        val catalog = TestCatalogLease(providers = providers)
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(emptyMap()))
        val runtime = RealmCheckRuntime(store)

        shouldThrow<IllegalStateException> {
            runBlocking { runtime.reloadCatalog() }
        }

        providers.openLeases.get() shouldBe 0
        runtime.close()
        store.close()
        catalog.openCount shouldBe 0
    }

    test("a reload racing another reload publishes findings of the latest catalog and releases every provider lease on close") {
        val providers = checksOf(10, InvalidRealm)
        val latest = CatalogGeneration(value = "latest")
        InMemoryAuthoringViewStore(TestCatalogLease(CatalogGeneration(value = "first"), providers), AuthoringSeed(emptyMap())).use { base ->
            // The first reload stops while it discovers subjects, after it retained its catalog.
            val store = BlockingCaptureStore(base, blockedCall = 2)
            val runtime = RealmCheckRuntime(store)
            val executor = Executors.newSingleThreadExecutor()
            val first = executor.submit { runBlocking { runtime.reloadCatalog() } }
            store.entered.await(5, TimeUnit.SECONDS) shouldBe true

            base.install(base.prepare(AuthoringViewDelta(catalog = TestCatalogLease(latest, providers))))
            runBlocking { runtime.reloadCatalog() }
            store.release.countDown()
            first.get(5, TimeUnit.SECONDS)
            runBlocking { runtime.drain() }

            runtime.findings().map { it.ticket.catalog } shouldBe listOf(latest)
            runtime.reported() shouldBe setOf(REALM to "Realm is invalid.")
            runtime.close()
            providers.openLeases.get() shouldBe 0
            executor.shutdownNow()
        }
    }

    test("checks of one provider publish under distinct rule ids, an each check once per resource of its type") {
        runTest {
            membership(mapOf(FIRST to record(name = "bad"))) { _, runtime ->
                runtime.reported() shouldBe setOf(FIRST to "Name is invalid.", REALM to "Realm is invalid.")
                runtime
                    .findings()
                    .map { it.ticket.instance.rule }
                    .distinct()
                    .size shouldBe 2
            }
        }
    }

    test("an each check reports a resource added after the catalog loaded") {
        runTest {
            membership(mapOf(FIRST to record(name = "bad"))) { realm, runtime ->
                realm.commitChecked(runtime, EditIntent.createCreateResource(id = SECOND, record = record(name = "bad")))
                settle(runtime)

                runtime.reported() shouldBe setOf(FIRST to "Name is invalid.", SECOND to "Name is invalid.", REALM to "Realm is invalid.")
            }
        }
    }

    test("an each check clears the finding of a resource once it is fixed") {
        runTest {
            membership(mapOf(FIRST to record(name = "bad"), SECOND to record(name = "bad"))) { realm, runtime ->
                realm.commitChecked(runtime, rename(SECOND, "valid"))
                settle(runtime)

                runtime.reported() shouldBe setOf(FIRST to "Name is invalid.", REALM to "Realm is invalid.")
            }
        }
    }

    test("an each check drops the finding of a deleted resource") {
        runTest {
            membership(mapOf(FIRST to record(name = "bad"), SECOND to record(name = "bad"))) { realm, runtime ->
                realm.commitChecked(runtime, EditIntent.createDeleteResource(id = SECOND))
                settle(runtime)

                runtime.reported() shouldBe setOf(FIRST to "Name is invalid.", REALM to "Realm is invalid.")
            }
        }
    }

    test("a throwing check callback fails its check with check_callback_failed at the subject") {
        runTest {
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { error("Callback exploded.") }
                    }
                }
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(14, provider))
            checking(catalog, mapOf(FIRST to record()), StandardTestDispatcher(testScheduler)) { _, runtime ->
                settle(runtime)

                val failed = runtime.findings().single()
                val outcome = failed.outcome.shouldBeInstanceOf<CheckOutcome.FailedWrapper>()
                outcome.value.map { it.code to it.primary } shouldBe listOf("check_callback_failed" to ValueLocation.of(FIRST))
            }
        }
    }

    // A worker runs provider code that ignores cancellation, so whoever stops the runtime has to wait for it.
    listOf(
        WorkerCancellation("closing the runtime", seed = "blocked", cancel = { _, _ -> }, stop = { it.close() }),
        WorkerCancellation(
            "deleting its subject",
            seed = "blocked",
            cancel = { realm, runtime -> realm.commitChecked(runtime, EditIntent.createDeleteResource(id = FIRST)) },
        ),
        WorkerCancellation(
            "editing its subject again",
            seed = "ready",
            cancel = { realm, runtime ->
                runtime.drain()
                realm.commitChecked(runtime, rename(FIRST, "blocked"))
            },
            afterStart = { realm, runtime ->
                realm.commitChecked(runtime, rename(FIRST, "after"))
            },
        ),
    ).forEach { case ->
        test("a worker cancelled by ${case.name} keeps the runtime waiting and its provider lease open until it stops") {
            val check = BlockingCheck()
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = check.providers)
            Executors.newFixedThreadPool(2).asCoroutineDispatcher().use { worker ->
                runBlocking {
                    checking(catalog, mapOf(FIRST to record(name = case.seed)), worker) { realm, runtime ->
                        runtime.reloadCatalog()
                        case.cancel(realm, runtime)
                        check.started.await(5, TimeUnit.SECONDS) shouldBe true
                        case.afterStart(realm, runtime)

                        val stopped = AtomicBoolean()
                        val stopper = waitingOn { case.stop(runtime).also { stopped.set(true) } }

                        stopped.get() shouldBe false
                        check.providers.openLeases.get() shouldBe 1
                        check.release.countDown()
                        stopper()
                        check.providers.openLeases.get() shouldBe 0
                    }
                }
            }
        }
    }

    test("an edit committed while a check runs is reflected in the findings it settles on") {
        val running = CountDownLatch(1)
        val edited = CountDownLatch(1)
        val first = AtomicBoolean(true)
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                        val name = read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
                        if (first.compareAndSet(true, false)) {
                            running.countDown()
                            edited.await(5, TimeUnit.SECONDS)
                        }
                        check(name) { it == "valid" }.error("Name is invalid.", draft.binding.location)
                    }
                }
            }
        val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(7, provider))
        Executors.newSingleThreadExecutor().asCoroutineDispatcher().use { worker ->
            runBlocking {
                checking(catalog, mapOf(FIRST to record(name = "invalid")), worker) { realm, runtime ->
                    runtime.reloadCatalog()
                    running.await(5, TimeUnit.SECONDS) shouldBe true

                    realm.commitChecked(runtime, rename(FIRST, "valid"))
                    edited.countDown()
                    runtime.drain()

                    runtime.findings().map { it.status } shouldBe listOf(FindingStatus.CURRENT)
                    runtime.reported() shouldBe emptySet()
                }
            }
        }
    }

    test("an incomplete current result publishes its partial findings and drain completes") {
        runTest {
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        realm {
                            select(
                                TypedSelection(
                                    TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)),
                                    ExpressionNode.LiteralWrapper(DataValue.BooleanWrapper(true)),
                                ),
                            )
                            check(Availability.Available(false)) { it }
                                .error("Partial finding.", ValueLocation.of(FIRST))
                        }
                    }
                }
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(11, provider))
            val evaluator =
                SelectionPredicateEvaluator { _, _, reads ->
                    (reads as CapturedAuthoringReads).recordIncomplete("graph traversal limit exceeded")
                    Availability.Available(true)
                }
            checking(
                catalog,
                mapOf(FIRST to record(name = "valid")),
                StandardTestDispatcher(testScheduler),
                selectionPredicates = evaluator,
            ) { _, runtime ->
                settle(runtime)

                val finding = runtime.findings().single()
                finding.outcome shouldBe CheckOutcome.IncompleteWrapper("graph traversal limit exceeded")
                finding.status shouldBe FindingStatus.CURRENT
                finding.findings.map { it.message } shouldBe listOf("Partial finding.")
            }
        }
    }

    test("a portable configuration rule reports an empty name in current and captured checks") {
        runTest {
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, configuration = portableNameRule(nameIsNotEmpty()))
            checking(catalog, mapOf(FIRST to record(name = "")), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                settle(runtime)

                val current = runtime.findings().single()
                current.ticket.instance.location shouldBe location(FIRST, "name")
                current.findings.map { it.code } shouldBe listOf("name_rule")

                val captured = realm.views.capture().use { runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(it.root)) }
                captured.complete shouldBe true
                captured.results.flatMap { result -> result.findings.map { it.code } } shouldBe listOf("name_rule")
            }
        }
    }

    test("a captured portable rule evaluates type facts with the snapshot catalog after the catalog is replaced") {
        runTest {
            val rule = portableNameRule(nameIsNotText())
            val snapshot = DefinitionCatalog(TEST_DEFINITIONS, configuration = rule).lease(CatalogGeneration(value = "snapshot"))
            // The replacement declares the name as a number, so the same rule no longer reports a text name.
            val replacement =
                DefinitionCatalog(
                    definitions { record(TEST_TYPE) { field("name", integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template) } },
                    configuration = rule,
                ).lease(CatalogGeneration(value = "replacement"))
            InMemoryAuthoringViewStore(snapshot, AuthoringSeed(mapOf(FIRST to record(name = "")))).use { store ->
                val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))
                store.capture().use { captured ->
                    store.install(store.prepare(AuthoringViewDelta(catalog = replacement)))

                    val report = runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(captured.root))
                    val current = store.capture().use { runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(it.root)) }

                    report.catalog shouldBe CatalogGeneration(value = "snapshot")
                    report.results.flatMap { result -> result.findings.map { it.code } } shouldBe listOf("name_rule")
                    current.results.flatMap { result -> result.findings.map { it.code } } shouldBe emptyList()
                }
                runtime.close()
            }
        }
    }

    test("a captured check input that is unavailable blocks publication of an otherwise complete, constructible resource") {
        runTest {
            val unavailable = location(FIRST, "computed")
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        realm {
                            check(read(boundPath<String>(unavailable, TEXT_USE))) { value -> value.isNotBlank() }
                                .error("Computed value is required.", unavailable)
                        }
                    }
                }
            val catalog =
                DefinitionCatalog(
                    TEST_DEFINITIONS,
                    providers = checksOf(21, provider),
                    nativeBindingFactories = listOf(TestResourceNativeBindingFactory),
                )
            checking(catalog, mapOf(FIRST to record(name = "ready")), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)

                assessment.resources.getValue(FIRST).shouldBeInstanceOf<ResourceReadiness.Ready>()
                assessment.findings.map { it.code to it.primary } shouldBe listOf("check_needs_input" to unavailable)
            }
        }
    }

    test("captured acceptance rejects canonically duplicate set values and map keys at the exact items") {
        runTest {
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
            val catalog = DefinitionCatalog(DUPLICATE_DEFINITIONS)
            checking(catalog, mapOf(FIRST to authored), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)

                assessment.findings
                    .filter { it.code in setOf("duplicate_set_value", "duplicate_map_key") }
                    .map { it.code to it.primary } shouldBe
                    listOf(
                        "duplicate_map_key" to
                            ValueLocation.of(
                                FIRST,
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createField(name = "mapping"),
                                            PathSegment.createItem(id = ItemId(value = "map_duplicate")),
                                            PathSegment.MAP_KEY,
                                        ),
                                ),
                            ),
                        "duplicate_set_value" to
                            ValueLocation.of(
                                FIRST,
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createField(name = "values"),
                                            PathSegment.createItem(id = ItemId(value = "set_duplicate")),
                                        ),
                                ),
                            ),
                    )
            }
        }
    }

    test("a resource with a pending type selection blocks captured acceptance until it is edited") {
        runTest {
            val pending =
                record(name = "ready").copy(configuration = TypeSelection.createPending(definition = TEST_TYPE, arguments = emptyList()))
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, nativeBindingFactories = listOf(TestResourceNativeBindingFactory))
            checking(catalog, mapOf(FIRST to pending), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)
                val blocker = assessment.findings.single()

                (blocker.code to blocker.primary) shouldBe ("pending_type" to ValueLocation.of(FIRST))
                val evidence = assessment.evidence.getValue(blocker.id).expectations
                realm.views.read { it.values.conflicts(evidence) }.isEmpty() shouldBe true
                realm.commit(rename(FIRST, "renamed")).shouldBeCommitted()
                realm.views.read { it.values.conflicts(evidence) }.isNotEmpty() shouldBe true
            }
        }
    }

    test("bounded subject discovery publishes a failure and blocks captured coverage without dropping partial subjects") {
        runTest {
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, configuration = portableNameRule(nameIsNotEmpty()))
            checking(
                catalog,
                mapOf(FIRST to record(name = "valid")),
                StandardTestDispatcher(testScheduler),
                readLimits = ViewReadLimits(maxOccurrenceValues = 1),
            ) { realm, runtime ->
                settle(runtime)

                val current = runtime.findings()
                current.any { it.ticket.instance.location == location(FIRST, "name") } shouldBe true
                val discovery = current.single { it.ticket.instance.location == DISCOVERY_LOCATION_FOR_TEST }
                discovery.outcome.shouldBeInstanceOf<CheckOutcome.IncompleteWrapper>()
                discovery.findings.map { it.code } shouldBe listOf("check_discovery_incomplete")

                val captured = realm.views.capture().use { runtime.evaluateCapture(CheckAdmissionTarget.CapturedAcceptance(it.root)) }
                captured.complete shouldBe false
                captured.results.any { it.ticket.instance.location == location(FIRST, "name") } shouldBe true
                captured.results.any {
                    it.ticket.instance.location == DISCOVERY_LOCATION_FOR_TEST && it.outcome is CheckOutcome.IncompleteWrapper
                } shouldBe true
            }
        }
    }
}

private val FIRST = ResourceId(value = "first")
private val SECOND = ResourceId(value = "second")
private val REALM = ResourceId(value = "realm")

/**
 * Runs [test] on a Realm of [catalog] that starts with [seed] saved, and a check runtime over its views that runs
 * checks on [dispatcher]. The runtime is closed before the Realm.
 */
private suspend fun checking(
    catalog: DefinitionCatalog,
    seed: Map<ResourceId, AuthoringRecord>,
    dispatcher: CoroutineDispatcher,
    readLimits: ViewReadLimits = ViewReadLimits(),
    selectionPredicates: SelectionPredicateEvaluator = RealmSelectionPredicateEvaluator(),
    test: suspend (RealmFixture, RealmCheckRuntime) -> Unit,
) {
    RealmFixture.of(catalog, seed).use { realm ->
        val runtime = RealmCheckRuntime(realm.views, dispatcher, selectionPredicates = selectionPredicates, readLimits = readLimits)
        runtime.use { test(realm, it) }
    }
}

/** Loads the catalog and runs every scheduled check to its end. */
@OptIn(ExperimentalCoroutinesApi::class)
private suspend fun TestScope.settle(runtime: RealmCheckRuntime) {
    runtime.reloadCatalog()
    advanceUntilIdle()
    runtime.drain()
}

/** Commits [intent] and tells [runtime] about it, as the Realm does after every committed edit. */
private suspend fun RealmFixture.commitChecked(
    runtime: RealmCheckRuntime,
    intent: EditIntent,
) {
    commit(intent).shouldBeCommitted()
    runtime.invalidateCurrent()
}

/** Renames [resource]. */
private fun rename(
    resource: ResourceId,
    name: String,
) = EditIntent.createSetValue(at = location(resource, "name"), value = DataValue.StringValueWrapper(name))

/** Every published finding as the resource it points at and its message. */
private fun RealmCheckRuntime.reported(): Set<Pair<ResourceId?, String>> =
    findings().flatMapTo(linkedSetOf()) { set -> set.findings.map { it.primary?.resource to it.message } }

/** Runs [test] with an each check that reports test resources not named "valid" and a realm check that always reports. */
@OptIn(ExperimentalCoroutinesApi::class)
private suspend fun TestScope.membership(
    seed: Map<ResourceId, AuthoringRecord>,
    test: suspend (RealmFixture, RealmCheckRuntime) -> Unit,
) {
    val provider =
        object : RealmCheckProvider {
            override fun RealmChecks.register() {
                each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                    check(read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))) { it == "valid" }
                        .error("Name is invalid.", draft.binding.location)
                }
                realm {
                    check(Availability.Available(false)) { it }.error("Realm is invalid.", ValueLocation.of(REALM))
                }
            }
        }
    val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(5, provider))
    checking(catalog, seed, StandardTestDispatcher(testScheduler)) { realm, runtime ->
        settle(runtime)
        test(realm, runtime)
    }
}

/** A realm check that always reports the Realm as invalid. */
private object InvalidRealm : RealmCheckProvider {
    override fun RealmChecks.register() {
        realm {
            check(Availability.Available(false)) { it }.error("Realm is invalid.", ValueLocation.of(REALM))
        }
    }
}

/**
 * An each check over test resources that, while a resource is named "blocked", keeps running until [release] opens,
 * ignoring cancellation as provider code may.
 */
private class BlockingCheck {
    val started = CountDownLatch(1)
    val release = CountDownLatch(1)
    private val provider =
        object : RealmCheckProvider {
            override fun RealmChecks.register() {
                each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                    val name = read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
                    if ((name as? Availability.Available)?.value == "blocked") {
                        started.countDown()
                        release.await(10, TimeUnit.SECONDS)
                    }
                }
            }
        }
    val providers = checksOf(12, provider)
}

/**
 * One way a running worker gets cancelled: the subject starts named [seed], [cancel] runs after the catalog loaded,
 * [afterStart] once the blocked worker runs, and [stop] is what has to wait for the worker.
 */
private class WorkerCancellation(
    val name: String,
    val seed: String,
    val cancel: suspend (RealmFixture, RealmCheckRuntime) -> Unit,
    val afterStart: suspend (RealmFixture, RealmCheckRuntime) -> Unit = { _, _ -> },
    val stop: (RealmCheckRuntime) -> Unit = { runtime ->
        runBlocking { runtime.drain() }
        runtime.close()
    },
)

/**
 * Runs [action] on its own thread and returns once that thread waits or ends, so everything [action] does before it
 * waits has happened. The returned function joins the thread and rethrows what [action] threw.
 */
private fun waitingOn(action: () -> Unit): () -> Unit {
    val failure = AtomicReference<Throwable>()
    val waiting = setOf(Thread.State.WAITING, Thread.State.TIMED_WAITING, Thread.State.TERMINATED)
    val worker = thread(name = "check-runtime-stopper") { runCatching(action).onFailure(failure::set) }
    val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5)
    while (worker.state !in waiting) {
        check(System.nanoTime() < deadline) { "The stopping thread never waited." }
        Thread.onSpinWait()
    }
    return {
        worker.join(TimeUnit.SECONDS.toMillis(10))
        failure.get()?.let { throw it }
    }
}

/** Captures the saved authoring and assesses it for publication. */
private suspend fun capturedAcceptance(
    store: AuthoringViewStore,
    runtime: RealmCheckRuntime,
): CapturedAssessment {
    val acceptance = AuthoringAcceptance(store, runtime)
    return acceptance.capture().use { acceptance.evaluate(it) }
}

/** A portable rule on the test resource's name that reports `name_rule` where [predicate] is false. */
private fun portableNameRule(predicate: ExpressionNode): List<ConfigurationRecipe> {
    val origin = RuleOrigin(owner = TEST_TYPE, ordinal = 20)
    val path = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("name")))
    return listOf(
        ConfigurationRecipe(
            origin = origin,
            relativePath = path,
            representationCondition = RepresentationKind.TEXT,
            rules =
                listOf(
                    OwnedRule(
                        id = RuleId(origin = origin, localIndex = 0),
                        descriptor = RuleDescriptor(predicate = predicate),
                        diagnostic =
                            DiagnosticTemplate(
                                code = "name_rule",
                                message = "Name breaks the rule.",
                                severity = DiagnosticSeverity.ERROR,
                                targets = listOf(path),
                            ),
                    ),
                ),
        ),
    )
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
