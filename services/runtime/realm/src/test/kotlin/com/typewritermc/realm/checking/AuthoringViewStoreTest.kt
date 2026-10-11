package com.typewritermc.realm.checking

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SelectionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.boundPath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
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
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointId
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import java.math.BigInteger
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

val AuthoringViewStoreTest by testSuite {
    test("retained views preserve original values while new reads see installed state") {
        val catalog = TestCatalogLease()
        val id = ResourceId("page")
        val original = record(name = "Quest", numbers = listOf("a" to 1, "b" to 2))
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to original)))
        val retained = store.capture()
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story", numbers = listOf("b" to 2, "a" to 1))))))
        assertEquals(original, retained.root.resources[id])
        assertEquals(
            "Story",
            store.capture().use {
                CapturedAuthoringReads(it.originalView()).read(boundPath<String>(location(id, "name"), TEXT_USE)).available()
            },
        )
        assertEquals(
            listOf(ItemId("a"), ItemId("b")),
            CapturedAuthoringReads(retained.originalView()).members(boundCollectionPath(location(id, "numbers"))),
        )
        retained.close()
        store.close()
        assertEquals(0, catalog.openCount)
    }
    test("read contexts belong to one retained original view") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(emptyMap()))
        val original = store.capture()
        val context = original.root.readContext
        store.install(store.prepare(AuthoringViewDelta()))
        store.retain(context).use { assertTrue(it.root === original.root) }
        original.close()
        assertFailsWith<IllegalArgumentException> { store.retain(context) }
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
        assertFailsWith<IllegalStateException> { store.capture() }
        assertEquals(original, retained.root.resources[id])
        fail = false
        assertEquals(record(name = "Story"), store.capture().use { it.root.resources[id] })
        assertEquals(2, loads)
        store.capture().close()
        assertEquals(2, loads)
        retained.close()
        store.close()
    }
    test("staged reads keep expectations from the original baseline") {
        val id = ResourceId("page")
        val original = record(name = "Quest")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to original)))
        store.capture().use { lease ->
            val reads = CapturedAuthoringReads(lease.stagedView(mapOf(id to record(name = "Story"))))
            assertEquals("Story", reads.read(boundPath<String>(location(id, "name"), TEXT_USE)).available())
            val expected =
                reads.observations().filterIsInstance<com.typewritermc.authoring.EditExpectation.Value>().single {
                    it.at ==
                        location(id, "name")
                }
            assertEquals(DataValue.StringValue("Quest"), expected.expected)
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
                "numbers" to DataValue.Named(TypeUse.Named(LIST_TYPE, rootArguments), DataValue.ListValue(rootItems)),
            )
        val seed = mutableMapOf(id to AuthoringRecord(TypeSelection.Complete(TypeUse.Named(TEST_TYPE)), rootFields))
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(seed))

        seed.clear()
        rootFields["name"] = DataValue.StringValue("Changed")
        rootArguments += TEXT_USE
        rootItems += ListItem(ItemId("late"), DataValue.Integer(BigInteger.TWO))

        store.capture().use { lease ->
            val retained = lease.root.resources.getValue(id)
            assertEquals(DataValue.StringValue("Quest"), retained.fields.getValue("name"))
            val retainedNumbers = retained.fields.getValue("numbers") as DataValue.Named
            assertEquals(listOf(INT_USE), retainedNumbers.actualType.arguments)
            assertEquals(listOf(ItemId("root")), (retainedNumbers.payload as DataValue.ListValue).items.map(ListItem::id))
            assertFailsWith<UnsupportedOperationException> {
                @Suppress("UNCHECKED_CAST")
                (lease.root.resources as MutableMap<ResourceId, AuthoringRecord>)[ResourceId("other")] = retained
            }
            assertFailsWith<UnsupportedOperationException> {
                @Suppress("UNCHECKED_CAST")
                (retainedNumbers.actualType.arguments as MutableList<TypeUse>) += TEXT_USE
            }

            val stagedItems = mutableListOf(ListItem(ItemId("staged"), DataValue.Integer(BigInteger.TWO)))
            val stagedFields =
                mutableMapOf<String, DataValue>(
                    "name" to DataValue.StringValue("Story"),
                    "count" to DataValue.Integer(BigInteger.TWO),
                    "numbers" to DataValue.Named(LIST_USE, DataValue.ListValue(stagedItems)),
                )
            val upserts = mutableMapOf(id to AuthoringRecord(TypeSelection.Complete(TypeUse.Named(TEST_TYPE)), stagedFields))
            val staged = lease.stagedView(upserts)
            upserts.clear()
            stagedFields["name"] = DataValue.StringValue("Changed")
            stagedItems.clear()

            val retainedStaged = staged.resources.getValue(id)
            assertEquals(DataValue.StringValue("Story"), retainedStaged.fields.getValue("name"))
            val stagedNumbers = retainedStaged.fields.getValue("numbers") as DataValue.Named
            assertEquals(listOf(ItemId("staged")), (stagedNumbers.payload as DataValue.ListValue).items.map(ListItem::id))
            assertFailsWith<UnsupportedOperationException> {
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
                        assertEquals(record(name = "Quest"), current.resources[id])
                    }
                }
            assertTrue(reading.await(2, TimeUnit.SECONDS))
            val write = executor.submit { store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story"))))) }
            assertFalse(write.isDone)
            release.countDown()
            read.get(2, TimeUnit.SECONDS)
            write.get(2, TimeUnit.SECONDS)
            assertEquals(record(name = "Story"), store.capture().use { it.root.resources[id] })
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
    private val resourceRoot: TypeDefinitionId,
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
        resourceRoot: TypeDefinitionId = TEST_TYPE,
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
        resourceRoot,
        relations,
        endpointBindings,
    )

    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, definitions)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, nativeBindingFactories)
    override val resources: List<AuthoringResourceDefinition> =
        listOf(AuthoringResourceDefinition(ResourceDefinitionId("test"), resourceRoot))
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
            resourceRoot,
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
        configuration = TypeSelection.Complete(TypeUse.Named(TEST_TYPE)),
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

internal fun ValueLocation.append(vararg segments: PathSegment): ValueLocation = copy(path = ValuePath(path.segments + segments))

internal fun location(
    resource: ResourceId,
    field: String,
): ValueLocation = ValueLocation(resource, ValuePath(listOf(PathSegment.Field(field))))

internal fun <T> com.typewritermc.authoring.Availability<T>.available(): T =
    (this as com.typewritermc.authoring.Availability.Available).value

internal val TEST_TYPE = TypeDefinitionId(TypeId.Qualified("test", "resource"), 1)
internal val LIST_TYPE = TypeDefinitionId(TypeId.Qualified("typewriter", "list"), 1)
internal val TEXT_USE = TypeUse.Scalar(ScalarKind.Text)
internal val INT_USE = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
internal val LIST_USE = TypeUse.Named(LIST_TYPE, listOf(INT_USE))
internal val TEST_DEFINITION =
    TypeDefinition(
        id = TEST_TYPE,
        representation =
            RepresentationTemplate.Record(
                fields =
                    listOf(
                        FieldDeclaration(FieldOwner(TEST_TYPE, "name"), TypeTemplate.Scalar(ScalarKind.Text)),
                        FieldDeclaration(FieldOwner(TEST_TYPE, "count"), TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))),
                        FieldDeclaration(
                            FieldOwner(TEST_TYPE, "numbers"),
                            TypeTemplate.Named(LIST_TYPE, listOf(TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)))),
                        ),
                    ),
            ),
    )
internal val LIST_PARAMETER = com.typewritermc.types.ParameterKey(LIST_TYPE, 0)
internal val LIST_DEFINITION =
    TypeDefinition(
        id = LIST_TYPE,
        parameters = listOf(com.typewritermc.types.TypeParameter(LIST_PARAMETER, "T")),
        representation = RepresentationTemplate.Sequence(TypeTemplate.Parameter(LIST_PARAMETER), CollectionKind.List),
    )
