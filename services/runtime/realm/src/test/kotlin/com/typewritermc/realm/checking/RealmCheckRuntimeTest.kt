@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.checking.RealmChecks
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.check
import com.typewritermc.configuration.field
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.INT_USE
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.SelectionPredicateEvaluator
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TEXT_USE
import com.typewritermc.realm.authoring.TestDraft
import com.typewritermc.realm.authoring.TestDraftType
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.conflicts
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.catalog.CONTENT_RULE
import com.typewritermc.realm.publication.ResourceReadiness
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.checksOf
import com.typewritermc.realm.testing.openCatalogLeases
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
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
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.util.concurrent.CompletableFuture
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.ThreadFactory
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

@OptIn(ExperimentalCoroutinesApi::class)
val RealmCheckRuntimeTest by testSuite {
    val firstResource = ResourceId(value = "first")

    val secondResource = ResourceId(value = "second")

    val duplicateValueType = TypeDefinitionId.qualified("test", "canonical_value")

    val duplicateSetType = TypeDefinitionId.qualified("test", "canonical_set")

    val duplicateMapType = TypeDefinitionId.qualified("test", "canonical_map")

    val duplicateSetParameter = ParameterKey(owner = duplicateSetType, index = 0)

    val duplicateMapKeyParameter = ParameterKey(owner = duplicateMapType, index = 0)

    val duplicateMapValueParameter = ParameterKey(owner = duplicateMapType, index = 1)

    val duplicateValueUse = duplicateValueType.namedUse()

    val duplicateSetUse = duplicateSetType.namedUse(listOf(duplicateValueUse.use))

    val duplicateMapUse =
        duplicateMapType.namedUse(listOf(duplicateValueUse.use, ScalarKind.TEXT.use))

    val duplicateDefinitions =
        listOf(
            TypeDefinition.partial(
                id = TEST_TYPE,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = TEST_TYPE, name = "values"),
                                    type = duplicateSetType.template(listOf(duplicateValueType.template())),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = TEST_TYPE, name = "mapping"),
                                    type = duplicateMapType.template(listOf(duplicateValueType.template(), ScalarKind.TEXT.template)),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            ),
            TypeDefinition.partial(
                id = duplicateValueType,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = duplicateValueType, name = "first"),
                                    type = ScalarKind.TEXT.template,
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = duplicateValueType, name = "second"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            ),
            TypeDefinition.partial(
                id = duplicateSetType,
                parameters = listOf(TypeParameter.partial(key = duplicateSetParameter, name = "T")),
                representation = RepresentationTemplate.createSequence(item = duplicateSetParameter.template, kind = CollectionKind.SET),
            ),
            TypeDefinition.partial(
                id = duplicateMapType,
                parameters =
                    listOf(
                        TypeParameter.partial(key = duplicateMapKeyParameter, name = "K"),
                        TypeParameter.partial(key = duplicateMapValueParameter, name = "V"),
                    ),
                representation =
                    RepresentationTemplate.createMapping(
                        key = duplicateMapKeyParameter.template,
                        value = duplicateMapValueParameter.template,
                    ),
            ),
        )

    val discoveryLocationForTest =
        ValueLocation.of(
            ResourceId(value = "typewriter.discovery"),
            ValuePath(
                segments =
                    listOf(
                        PathSegment.createField(name = "subjects"),
                    ),
            ),
        )

    test("a capture against another catalog generation is refused and releases its retained snapshot") {
        val realm = RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS))
        val openLeases = realm.openCatalogLeases()
        val wrong = DefinitionCatalog(TEST_DEFINITIONS).lease(CatalogGeneration(value = "wrong"))
        realm.use {
            RealmCheckRuntime(realm.views).use { runtime ->
                shouldThrow<IllegalArgumentException> {
                    runtime.evaluateCapture(realm.views.capture().use { it.root.copy(catalog = wrong) })
                }
            }
        }
        openLeases() shouldBe 0
    }

    test("checks of one provider publish under distinct rule ids, an each check once per resource of its type") {
        runTest {
            membership(
                mapOf(firstResource to record(name = "bad")),
            ) { _, runtime ->
                runtime.reported() shouldBe setOf(firstResource to "Name is invalid.", REALM to "Realm is invalid.")
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
            membership(mapOf(firstResource to record(name = "bad"))) { realm, runtime ->
                realm.commitChecked(EditIntent.createCreateResource(id = secondResource, record = record(name = "bad")))
                runtime.settle()

                runtime.reported() shouldBe
                    setOf(firstResource to "Name is invalid.", secondResource to "Name is invalid.", REALM to "Realm is invalid.")
            }
        }
    }

    test("an each check clears the finding of a resource once it is fixed") {
        runTest {
            membership(
                mapOf(
                    firstResource to record(name = "bad"),
                    secondResource to record(name = "bad"),
                ),
            ) { realm, runtime ->
                realm.commitChecked(rename(secondResource, "valid"))
                runtime.settle()

                runtime.reported() shouldBe setOf(firstResource to "Name is invalid.", REALM to "Realm is invalid.")
            }
        }
    }

    test("an each check drops the finding of a deleted resource") {
        runTest {
            membership(
                mapOf(
                    firstResource to record(name = "bad"),
                    secondResource to record(name = "bad"),
                ),
            ) { realm, runtime ->
                realm.commitChecked(EditIntent.createDeleteResource(id = secondResource))
                runtime.settle()

                runtime.reported() shouldBe setOf(firstResource to "Name is invalid.", REALM to "Realm is invalid.")
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
            checking(catalog, mapOf(firstResource to record()), StandardTestDispatcher(testScheduler)) { _, runtime ->
                runtime.settle()

                val failed = runtime.findings().single()
                val outcome = failed.outcome.shouldBeInstanceOf<CheckOutcome.FailedWrapper>()
                outcome.value.map { it.code to it.primary } shouldBe listOf("check_callback_failed" to ValueLocation.of(firstResource))
            }
        }
    }

    // A worker runs provider code that ignores cancellation, so whoever stops the runtime has to wait for it.
    listOf(
        WorkerCancellation("closing the runtime", seed = "blocked", cancel = { _, _ -> }, stop = { it.close() }),
        WorkerCancellation(
            "deleting its subject",
            seed = "blocked",
            cancel = { realm, runtime -> realm.commitChecked(EditIntent.createDeleteResource(id = firstResource)) },
        ),
        WorkerCancellation(
            "editing its subject again",
            seed = "ready",
            cancel = { realm, runtime ->
                runtime.drain()
                realm.commitChecked(rename(firstResource, "blocked"))
            },
            afterStart = { realm, runtime ->
                realm.commitChecked(rename(firstResource, "after"))
            },
        ),
    ).forEach { case ->
        test("a worker cancelled by ${case.name} keeps the runtime waiting and its provider lease open until it stops") {
            val check = BlockingCheck()
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = check.providers)
            Executors.newFixedThreadPool(2).asCoroutineDispatcher().use { worker ->
                runBlocking {
                    checking(catalog, mapOf(firstResource to record(name = case.seed)), worker) { realm, runtime ->
                        runtime.start()
                        // A subject seeded blocked must be running before it is cancelled; a later pass would never start it.
                        if (case.startsBlocked) check.started.await(5, TimeUnit.SECONDS) shouldBe true
                        case.cancel(realm, runtime)
                        check.started.await(5, TimeUnit.SECONDS) shouldBe true
                        case.afterStart(realm, runtime)
                        // A generation without the check lets the old catalog go, so only the blocked run still holds its provider.
                        realm.owner.activateCatalog(DefinitionCatalog(TEST_DEFINITIONS).lease(CatalogGeneration(value = "next")), {}, {})

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
                checking(catalog, mapOf(firstResource to record(name = "invalid")), worker) { realm, runtime ->
                    runtime.start()
                    running.await(5, TimeUnit.SECONDS) shouldBe true

                    realm.commitChecked(rename(firstResource, "valid"))
                    edited.countDown()
                    runtime.drain()

                    runtime.findings().map { it.status } shouldBe listOf(FindingStatus.CURRENT)
                    runtime.reported() shouldBe emptySet()
                }
            }
        }
    }

    test("commits keep answering while checks reschedule for the commits before them") {
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))) { draft ->
                        val name = read(boundPath<String>(location(draft.binding.location.resource, "name"), TEXT_USE))
                        check(name) { it == "valid" }.error("Name is invalid.", draft.binding.location)
                    }
                }
            }
        val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(13, provider))
        val seed = mapOf(firstResource to record(name = "a"), secondResource to record(name = "a"))
        val daemons = ThreadFactory { task -> Thread(task).apply { isDaemon = true } }
        Executors.newFixedThreadPool(4, daemons).asCoroutineDispatcher().use { worker ->
            // Runs apart from the test thread, so commits that deadlock against the check runtime fail by timeout.
            val answered = CompletableFuture<Unit>()
            thread(isDaemon = true) {
                runCatching {
                    runBlocking {
                        checking(catalog, seed, worker) { realm, runtime ->
                            runtime.start()
                            coroutineScope {
                                seed.keys.forEach { resource ->
                                    launch(worker) { repeat(200) { realm.commitChecked(rename(resource, "name $it")) } }
                                }
                            }
                            runtime.drain()
                        }
                    }
                }.fold(answered::complete, answered::completeExceptionally)
            }
            answered.get(60, TimeUnit.SECONDS)
        }
    }

    test("closing waits for a rediscovery in progress, so none of it outlives the view store") {
        val rediscovering = AtomicBoolean()
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val blockedInRediscovery =
            object : DraftType<TestDraft> {
                override val match: ResourceTypeMatch
                    get() {
                        if (rediscovering.get()) {
                            entered.countDown()
                            release.await(30, TimeUnit.SECONDS)
                        }
                        return ResourceTypeMatch.Definition(TEST_TYPE)
                    }

                override fun bind(binding: DraftBinding) = TestDraft(binding)
            }
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    each(blockedInRediscovery) {}
                }
            }
        val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(14, provider))
        val daemons = ThreadFactory { task -> Thread(task).apply { isDaemon = true } }
        Executors.newFixedThreadPool(2, daemons).asCoroutineDispatcher().use { worker ->
            checking(catalog, mapOf(firstResource to record(name = "a")), worker) { realm, runtime ->
                runtime.start()
                runtime.drain()
                rediscovering.set(true)
                realm.commitChecked(EditIntent.createCreateResource(id = secondResource, record = record(name = "b")))
                entered.await(30, TimeUnit.SECONDS) shouldBe true

                val closing = thread(isDaemon = true) { runtime.close() }
                closing.join(500)
                val closedDuringRediscovery = !closing.isAlive
                release.countDown()
                closing.join(30_000)

                closedDuringRediscovery shouldBe false
                closing.isAlive shouldBe false
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
                                .error("Partial finding.", ValueLocation.of(firstResource))
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
                mapOf(firstResource to record(name = "valid")),
                StandardTestDispatcher(testScheduler),
                selectionPredicates = evaluator,
            ) { _, runtime ->
                runtime.settle()

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
            checking(catalog, mapOf(firstResource to record(name = "")), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                runtime.settle()

                val current = runtime.findings().single()
                current.ticket.instance.location shouldBe location(firstResource, "name")
                current.findings.map { it.code } shouldBe listOf("name_rule")

                val captured = realm.views.capture().use { runtime.evaluateCapture(it.root) }
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
            InMemoryAuthoringViewStore(snapshot, AuthoringSeed(mapOf(firstResource to record(name = "")))).use { store ->
                val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))
                store.capture().use { captured ->
                    store.install(store.prepare(AuthoringViewDelta(catalog = replacement)))

                    val report = runtime.evaluateCapture(captured.root)
                    val current = store.capture().use { runtime.evaluateCapture(it.root) }

                    report.catalog shouldBe CatalogGeneration(value = "snapshot")
                    report.results.flatMap { result -> result.findings.map { it.code } } shouldBe listOf("name_rule")
                    // The replacement no longer fits the saved record, which the content rule reports on its own.
                    current.results
                        .filter { it.ticket.instance.rule != CONTENT_RULE }
                        .flatMap { result -> result.findings.map { it.code } } shouldBe emptyList()
                }
                runtime.close()
            }
        }
    }

    test("a captured check input that is unavailable blocks publication of an otherwise complete, constructible resource") {
        runTest {
            val unavailable = location(firstResource, "computed")
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
            checking(catalog, mapOf(firstResource to record(name = "ready")), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)

                assessment.resources.getValue(firstResource).shouldBeInstanceOf<ResourceReadiness.Ready>()
                assessment.findings.map { it.code to it.primary } shouldBe listOf("check_needs_input" to unavailable)
            }
        }
    }

    test("two rules failing on the same read each keep their failure in publication") {
        runTest {
            val name = location(firstResource, "name")
            val provider =
                object : RealmCheckProvider {
                    override fun RealmChecks.register() {
                        repeat(2) {
                            realm {
                                check(read(boundPath<Int>(name, INT_USE))) { value -> value > 0 }
                                    .error("Name is not a number.", name)
                            }
                        }
                    }
                }
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, providers = checksOf(22, provider))
            checking(catalog, mapOf(firstResource to record(name = "text")), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)

                val failures = assessment.findings.filter { it.primary == name }
                failures.map { it.code }.distinct().size shouldBe 1
                failures.map { it.id }.distinct().size shouldBe 2
            }
        }
    }

    test("captured acceptance blocks canonically duplicate set values and map keys with one fit finding at each exact item") {
        runTest {
            val repeated =
                DataValue.named(
                    duplicateValueUse,
                    DataValue.record(
                        linkedMapOf(
                            "first" to DataValue.StringValueWrapper("same"),
                            "second" to DataValue.StringValueWrapper("value"),
                        ),
                    ),
                )
            val equivalent =
                DataValue.named(
                    duplicateValueUse,
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
                                duplicateSetUse,
                                DataValue.setValue(
                                    listOf(
                                        ListItem(id = ItemId(value = "set_first"), value = repeated),
                                        ListItem(id = ItemId(value = "set_duplicate"), value = equivalent),
                                    ),
                                ),
                            ),
                        "mapping" to
                            DataValue.named(
                                duplicateMapUse,
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
            val catalog = DefinitionCatalog(duplicateDefinitions)
            checking(catalog, mapOf(firstResource to authored), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)

                assessment.findings
                    .filter { it.code == "value_mismatch" }
                    .map { it.message.substringAfter('(').substringBefore(')') to it.primary } shouldContainExactlyInAnyOrder
                    listOf(
                        "duplicate_map_key" to
                            ValueLocation.of(
                                firstResource,
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
                                firstResource,
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
            checking(catalog, mapOf(firstResource to pending), StandardTestDispatcher(testScheduler)) { realm, runtime ->
                val assessment = capturedAcceptance(realm.views, runtime)
                val blocker = assessment.findings.single()

                (blocker.code to blocker.primary) shouldBe ("pending_type" to ValueLocation.of(firstResource))
                val evidence = assessment.evidence.getValue(blocker.id).expectations
                realm.views.read { it.values.conflicts(evidence) }.isEmpty() shouldBe true
                realm.commit(rename(firstResource, "renamed")).shouldBeCommitted()
                realm.views.read { it.values.conflicts(evidence) }.isNotEmpty() shouldBe true
            }
        }
    }

    test("bounded subject discovery publishes a failure and blocks captured coverage without dropping partial subjects") {
        runTest {
            val catalog = DefinitionCatalog(TEST_DEFINITIONS, configuration = portableNameRule(nameIsNotEmpty()))
            checking(
                catalog,
                mapOf(firstResource to record(name = "valid")),
                StandardTestDispatcher(testScheduler),
                readLimits = ViewReadLimits(maxOccurrenceValues = 1),
            ) { realm, runtime ->
                runtime.settle()

                val current = runtime.findings()
                current.any { it.ticket.instance.location == location(firstResource, "name") } shouldBe true
                val discovery = current.single { it.ticket.instance.location == discoveryLocationForTest }
                discovery.outcome.shouldBeInstanceOf<CheckOutcome.IncompleteWrapper>()
                discovery.findings.map { it.code } shouldBe listOf("check_discovery_incomplete")

                val captured = realm.views.capture().use { runtime.evaluateCapture(it.root) }
                captured.complete shouldBe false
                captured.results.any { it.ticket.instance.location == location(firstResource, "name") } shouldBe true
                captured.results.any {
                    it.ticket.instance.location == discoveryLocationForTest && it.outcome is CheckOutcome.IncompleteWrapper
                } shouldBe true
            }
        }
    }
}
