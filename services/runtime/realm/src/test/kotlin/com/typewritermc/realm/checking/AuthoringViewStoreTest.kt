@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.append
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.boundPath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.operationObservation
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.integerScalar
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigInteger
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

val AuthoringViewStoreTest by testSuite {
    test("operation overlays require the exact saved observation and preserve saved state") {
        val id = ResourceId("operation-page")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to record(name = "Saved"))))
        try {
            val token =
                store.capture().use { saved ->
                    val working = saved.operationObservation(saved.root.observationId, mapOf(id to record(name = "Draft")), emptySet())
                    (
                        working.resources
                            .getValue(id)
                            .fields
                            .getValue("name") as DataValue.StringValue
                    ).value shouldBe "Draft"
                    (
                        saved.root.resources
                            .getValue(id)
                            .fields
                            .getValue("name") as DataValue.StringValue
                    ).value shouldBe "Saved"
                    saved.root.observationId
                }
            store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Other panel")))))
            store.capture().use { next ->
                (next.root.observationId != token) shouldBe true
                shouldThrow<com.typewritermc.realm.authoring.StaleOperationObservation> {
                    next.operationObservation(token, mapOf(id to record(name = "Draft")), emptySet())
                }
            }
        } finally {
            store.close()
        }
    }
    test("retained views preserve original values while new reads see installed state") {
        val catalog = TestCatalogLease()
        val id = ResourceId("page")
        val original = record(name = "Quest", numbers = listOf("a" to 1, "b" to 2))
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to original)))
        val retained = store.capture()
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story", numbers = listOf("b" to 2, "a" to 1))))))
        retained.root.resources[id] shouldBe original
        store.capture().use {
            CapturedAuthoringReads(it.originalView()).read(boundPath<String>(location(id, "name"), TEXT_USE)).available()
        } shouldBe "Story"
        CapturedAuthoringReads(retained.originalView()).members(boundCollectionPath(location(id, "numbers"))) shouldBe
            listOf(ItemId("a"), ItemId("b"))
        retained.close()
        store.close()
        catalog.openCount shouldBe 0
    }
    test("read contexts belong to one retained original view") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(emptyMap()))
        val original = store.capture()
        val context = original.root.readContext
        store.install(store.prepare(AuthoringViewDelta()))
        store.retain(context).use { (it.root === original.root) shouldBe true }
        original.close()
        shouldThrow<IllegalArgumentException> { store.retain(context) }
        store.close()
    }
    test("reload failure prevents serving old current state but preserves retained reads") {
        val id = ResourceId("page")
        val original = record(name = "Quest")
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to original)))
        val retained = store.capture()
        var fail = true
        var loads = 0
        store.invalidate {
            loads++
            if (fail) error("storage unavailable")
            AuthoringSeed(mapOf(id to record(name = "Story")))
        }
        shouldThrow<IllegalStateException> { store.capture() }
        retained.root.resources[id] shouldBe original
        fail = false
        store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
        loads shouldBe 2
        store.capture().close()
        loads shouldBe 2
        retained.close()
        store.close()
    }
    test("staged reads keep expectations from the original baseline") {
        val id = ResourceId("page")
        val original = record(name = "Quest")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to original)))
        store.capture().use { lease ->
            val reads = CapturedAuthoringReads(lease.stagedView(mapOf(id to record(name = "Story"))))
            reads.read(boundPath<String>(location(id, "name"), TEXT_USE)).available() shouldBe "Story"
            val expected =
                reads.observations().filterIsInstance<com.typewritermc.authoring.EditExpectation.Value>().single {
                    it.at ==
                        location(id, "name")
                }
            expected.expected shouldBe DataValue.StringValue("Quest")
        }
        store.close()
    }
    test("root and staged views reject caller and exposed collection mutation") {
        val id = ResourceId("page")
        val rootArguments = mutableListOf<TypeUse>(INT_USE)
        val rootItems = mutableListOf(ListItem(ItemId("root"), DataValue.Integer(BigInteger.ONE)))
        val rootFields =
            mutableMapOf<String, DataValue>(
                "name" to DataValue.StringValue("Quest"),
                "count" to DataValue.Integer(BigInteger.ONE),
                "numbers" to DataValue.Named(LIST_TYPE.namedUse(rootArguments), DataValue.ListValue(rootItems)),
            )
        val seed = mutableMapOf(id to AuthoringRecord(TypeSelection.Complete(TEST_TYPE.namedUse()), rootFields))
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(seed))

        seed.clear()
        rootFields["name"] = DataValue.StringValue("Changed")
        rootArguments += TEXT_USE
        rootItems += ListItem(ItemId("late"), DataValue.Integer(BigInteger.TWO))

        store.capture().use { lease ->
            val retained = lease.root.resources.getValue(id)
            retained.fields.getValue("name") shouldBe DataValue.StringValue("Quest")
            val retainedNumbers = retained.fields.getValue("numbers") as DataValue.Named
            retainedNumbers.actualType.arguments shouldBe listOf(INT_USE)
            (retainedNumbers.payload as DataValue.ListValue).items.map(ListItem::id) shouldBe listOf(ItemId("root"))
            shouldThrow<UnsupportedOperationException> {
                @Suppress("UNCHECKED_CAST")
                (lease.root.resources as MutableMap<ResourceId, AuthoringRecord>)[ResourceId("other")] = retained
            }
            // Skir type values are deeply immutable: their lists are not mutable lists at all.
            (retainedNumbers.actualType.arguments is MutableList<*>) shouldBe false

            val stagedItems = mutableListOf(ListItem(ItemId("staged"), DataValue.Integer(BigInteger.TWO)))
            val stagedFields =
                mutableMapOf<String, DataValue>(
                    "name" to DataValue.StringValue("Story"),
                    "count" to DataValue.Integer(BigInteger.TWO),
                    "numbers" to DataValue.Named(LIST_USE, DataValue.ListValue(stagedItems)),
                )
            val upserts = mutableMapOf(id to AuthoringRecord(TypeSelection.Complete(TEST_TYPE.namedUse()), stagedFields))
            val staged = lease.stagedView(upserts)
            upserts.clear()
            stagedFields["name"] = DataValue.StringValue("Changed")
            stagedItems.clear()

            val retainedStaged = staged.resources.getValue(id)
            retainedStaged.fields.getValue("name") shouldBe DataValue.StringValue("Story")
            val stagedNumbers = retainedStaged.fields.getValue("numbers") as DataValue.Named
            (stagedNumbers.payload as DataValue.ListValue).items.map(ListItem::id) shouldBe listOf(ItemId("staged"))
            shouldThrow<UnsupportedOperationException> {
                @Suppress("UNCHECKED_CAST")
                ((stagedNumbers.payload as DataValue.ListValue).items as MutableList<ListItem>).clear()
            }
        }
        store.close()
    }
    test("installation and current reads share one lock") {
        val id = ResourceId("page")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to record(name = "Quest"))))
        val executor = Executors.newFixedThreadPool(2)
        val reading = CountDownLatch(1)
        val release = CountDownLatch(1)
        try {
            val read =
                executor.submit {
                    store.read { current ->
                        reading.countDown()
                        release.await()
                        current.resources[id] shouldBe record(name = "Quest")
                    }
                }
            reading.await(2, TimeUnit.SECONDS) shouldBe true
            val write = executor.submit { store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story"))))) }
            write.isDone shouldBe false
            release.countDown()
            read.get(2, TimeUnit.SECONDS)
            write.get(2, TimeUnit.SECONDS)
            store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
        } finally {
            release.countDown()
            executor.shutdownNow()
            store.close()
        }
    }
}

internal data class TestDraft(
    val binding: com.typewritermc.authoring.DraftBinding,
)

internal data class TestDraftType(
    override val match: ResourceTypeMatch,
) : com.typewritermc.checking.DraftType<TestDraft> {
    override fun bind(binding: com.typewritermc.authoring.DraftBinding): TestDraft = TestDraft(binding)
}

internal class TestCatalogLease private constructor(
    private val state: State,
    override val generation: CatalogGeneration,
    override val providers: OwnedProviderRegistry,
    override val checks: List<OwnedCheckRecipe>,
    override val configuration: List<com.typewritermc.configuration.ConfigurationRecipe>,
    private val definitions: List<TypeDefinition>,
    private val nativeBindingFactories: List<NativeBindingFactory>,
    override val relations: List<RelationContract>,
    override val endpointBindings: List<EndpointBindingTemplate>,
) : AuthoringCatalogLease {
    constructor(
        generation: CatalogGeneration = CatalogGeneration("catalog"),
        providers: OwnedProviderRegistry = EmptyProviders,
        checks: List<OwnedCheckRecipe> = emptyList(),
        configuration: List<com.typewritermc.configuration.ConfigurationRecipe> = emptyList(),
        definitions: List<TypeDefinition> = listOf(TEST_DEFINITION, LIST_DEFINITION),
        nativeBindingFactories: List<NativeBindingFactory> = emptyList(),
        relations: List<RelationContract> = emptyList(),
        endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    ) : this(
        State(),
        generation,
        providers,
        checks,
        configuration,
        definitions,
        nativeBindingFactories,
        relations,
        endpointBindings,
    )

    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, definitions)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, nativeBindingFactories)
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, com.typewritermc.authoring.ValuePath>()
    internal val openCount: Int get() = state.open.get()

    override fun retain(): AuthoringCatalogLease {
        state.open.incrementAndGet()
        return TestCatalogLease(
            state,
            generation,
            providers,
            checks,
            configuration,
            definitions,
            nativeBindingFactories,
            relations,
            endpointBindings,
        )
    }

    override fun close() {
        state.open.decrementAndGet()
    }

    private class State {
        val open = AtomicInteger(1)
    }
}

internal data object EmptyProviders : OwnedProviderRegistry {
    override fun retain(origin: ProviderOrigin): ProviderLease = error("No providers are registered.")

    override fun configurations(): List<OwnedConfiguration> = emptyList()

    override fun presentations(): List<OwnedPresentation> = emptyList()

    override fun nativeBindings(): List<OwnedNativeBinding> = emptyList()

    override fun checks(): List<com.typewritermc.discovery.OwnedCheck> = emptyList()
}

internal fun record(
    name: String = "name",
    count: Int = 1,
    numbers: List<Pair<String, Int>> = emptyList(),
): AuthoringRecord =
    AuthoringRecord(
        configuration = TypeSelection.Complete(TEST_TYPE.namedUse()),
        fields =
            mapOf(
                "name" to DataValue.StringValue(name),
                "count" to DataValue.Integer(BigInteger.valueOf(count.toLong())),
                "numbers" to
                    DataValue.Named(
                        LIST_USE,
                        DataValue.ListValue(
                            numbers.map { (id, value) ->
                                ListItem(ItemId(id), DataValue.Integer(BigInteger.valueOf(value.toLong())))
                            },
                        ),
                    ),
            ),
    )

internal fun tokensFor(
    resources: Map<ResourceId, AuthoringRecord>,
    generation: CatalogGeneration,
    prefix: String = "seed",
): Map<InputIdentity, InputToken> {
    val identities = linkedSetOf<InputIdentity>(RESOURCE_SELECTION_INPUT, InputIdentity.Catalog(generation))
    resources.forEach { (resource, record) ->
        val root = ValueLocation(resource, ValuePath())
        identities += InputIdentity.Existence(resource)
        identities += InputIdentity.Form(root)
        identities += InputIdentity.Value(root)
        record.fields.forEach { (name, value) -> collectTokens(value, root.append(PathSegment.Field(name)), identities) }
    }
    return identities.withIndex().associate { (index, identity) -> identity to InputToken("$prefix:$index") }
}

internal fun collectTokens(
    value: DataValue,
    at: ValueLocation,
    identities: MutableSet<InputIdentity>,
) {
    identities += InputIdentity.Value(at)
    when (value) {
        is DataValue.ListValue -> {
            identities += InputIdentity.Membership(at)
            identities += InputIdentity.Order(at)
            value.items.forEach { collectTokens(it.value, at.append(PathSegment.Item(it.id)), identities) }
        }

        is DataValue.SetValue -> {
            identities += InputIdentity.Membership(at)
            identities += InputIdentity.Order(at)
            value.items.forEach { collectTokens(it.value, at.append(PathSegment.Item(it.id)), identities) }
        }

        is DataValue.Record -> {
            value.fields.forEach { (name, field) -> collectTokens(field, at.append(PathSegment.Field(name)), identities) }
        }

        is DataValue.Named -> {
            identities += InputIdentity.Form(at)
            collectTokens(value.payload, at, identities)
        }

        is DataValue.MapValue -> {
            identities += InputIdentity.Membership(at)
            identities += InputIdentity.Order(at)
            value.rows.forEach { row ->
                collectTokens(row.key, at.append(PathSegment.Item(row.id), PathSegment.MapKey), identities)
                collectTokens(row.value, at.append(PathSegment.Item(row.id), PathSegment.MapValue), identities)
            }
        }

        else -> {
            Unit
        }
    }
}

internal fun location(
    resource: ResourceId,
    field: String,
): ValueLocation = ValueLocation(resource, ValuePath(listOf(PathSegment.Field(field))))

internal fun <T> com.typewritermc.authoring.Availability<T>.available(): T =
    (this as com.typewritermc.authoring.Availability.Available).value

internal val TEST_TYPE = TypeDefinitionId.qualified("test", "resource")
internal val LIST_TYPE = TypeDefinitionId.qualified("typewriter", "list")
internal val TEXT_USE = ScalarKind.TEXT.use
internal val INT_USE = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
internal val LIST_USE = LIST_TYPE.namedUse(listOf(INT_USE))
internal val TEST_DEFINITION =
    TypeDefinition.partial(
        id = TEST_TYPE,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TYPE, name = "name"),
                            type = ScalarKind.TEXT.template,
                        ),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TYPE, name = "count"),
                            type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                        ),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TYPE, name = "numbers"),
                            type = LIST_TYPE.template(listOf(integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)),
                        ),
                    ),
                abstract_ = false,
            ),
    )
internal val LIST_PARAMETER = ParameterKey(owner = LIST_TYPE, index = 0)
internal val LIST_DEFINITION =
    TypeDefinition.partial(
        id = LIST_TYPE,
        parameters = listOf(TypeParameter.partial(key = LIST_PARAMETER, name = "T")),
        representation = RepresentationTemplate.createSequence(item = LIST_PARAMETER.template, kind = CollectionKind.LIST),
    )
