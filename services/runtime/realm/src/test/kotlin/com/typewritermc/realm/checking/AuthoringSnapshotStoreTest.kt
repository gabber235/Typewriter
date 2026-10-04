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
import com.typewritermc.checking.SnapshotId
import com.typewritermc.checking.TypedSelection
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.AuthoringSnapshotDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.SnapshotCatalogLease
import com.typewritermc.realm.authoring.SnapshotCommit
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

val AuthoringSnapshotStoreTest by testSuite {
    test("retainedSnapshotIsImmutableAndCollectionOrderHasIndependentEvidence") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val list = location(resource, "numbers")
        val first = record(numbers = listOf("a" to 1, "b" to 2))
        val seedTokens = tokensFor(mapOf(resource to first), catalog.generation)
        val store = InMemoryAuthoringSnapshotStore(catalog, AuthoredSnapshotSeed(SnapshotId("s0"), mapOf(resource to first), seedTokens))
        val retained = store.capture()
        val reordered = record(numbers = listOf("b" to 2, "a" to 1))
        val deltaTokens =
            mapOf(
                InputIdentity.Value(ValueLocation(resource, ValuePath())) to InputToken("v1"),
                InputIdentity.Value(list) to InputToken("v2"),
                InputIdentity.Order(list) to InputToken("order1"),
            )

        store.install(AuthoringSnapshotDelta(SnapshotId("s1"), mapOf(resource to reordered), inputTokens = deltaTokens))

        val oldReads = SnapshotReads(retained.originalView())
        val newLease = store.capture()
        val newReads = SnapshotReads(newLease.originalView())
        assertEquals(listOf(ItemId("a"), ItemId("b")), oldReads.members(boundCollectionPath(list)))
        assertEquals(listOf(ItemId("b"), ItemId("a")), newReads.members(boundCollectionPath(list)))
        assertNotEquals(
            retained.root.inputs.getValue(InputIdentity.Order(list)),
            newLease.root.inputs.getValue(InputIdentity.Order(list)),
        )
        assertEquals(
            retained.root.inputs.getValue(InputIdentity.Membership(list)),
            newLease.root.inputs.getValue(InputIdentity.Membership(list)),
        )

        retained.close()
        newLease.close()
        store.close()
    }

    test("actualReadRemainsCurrentAcrossUnrelatedEditAndBecomesStaleAfterRestore") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val name = location(resource, "name")
        val count = location(resource, "count")
        val initial = record(name = "alpha", count = 1)
        val store =
            InMemoryAuthoringSnapshotStore(
                catalog,
                AuthoredSnapshotSeed(
                    SnapshotId("s0"),
                    mapOf(resource to initial),
                    tokensFor(mapOf(resource to initial), catalog.generation),
                ),
            )
        val firstLease = store.capture()
        val reads = SnapshotReads(firstLease.originalView())
        assertEquals("alpha", reads.read(boundPath<String>(name, TEXT_USE)).available())
        val nameObservation = reads.observations().single { it.identity == InputIdentity.Value(name) }

        val unrelated = record(name = "alpha", count = 2)
        store.install(
            AuthoringSnapshotDelta(
                snapshot = SnapshotId("s1"),
                upsertedResources = mapOf(resource to unrelated),
                inputTokens =
                    mapOf(
                        InputIdentity.Value(ValueLocation(resource, ValuePath())) to InputToken("root1"),
                        InputIdentity.Value(count) to InputToken("count1"),
                    ),
            ),
        )
        assertEquals(nameObservation.token, store.currentToken(nameObservation.identity))

        val changed = record(name = "beta", count = 2)
        store.install(
            AuthoringSnapshotDelta(
                snapshot = SnapshotId("s2"),
                upsertedResources = mapOf(resource to changed),
                inputTokens =
                    mapOf(
                        InputIdentity.Value(ValueLocation(resource, ValuePath())) to InputToken("root2"),
                        InputIdentity.Value(name) to InputToken("name1"),
                    ),
            ),
        )
        store.install(
            AuthoringSnapshotDelta(
                snapshot = SnapshotId("s3"),
                upsertedResources = mapOf(resource to unrelated),
                inputTokens =
                    mapOf(
                        InputIdentity.Value(ValueLocation(resource, ValuePath())) to InputToken("root3"),
                        InputIdentity.Value(name) to InputToken("name2"),
                    ),
            ),
        )
        assertNotEquals(nameObservation.token, store.currentToken(nameObservation.identity))

        firstLease.close()
        store.close()
    }

    test("emptySelectionObservesMembershipBeforeFirstMatchExists") {
        val catalog = TestCatalogLease()
        val seedTokens =
            mapOf(
                RESOURCE_SELECTION_INPUT to InputToken("selection0"),
                InputIdentity.Catalog(catalog.generation) to InputToken("catalog0"),
            )
        val store = InMemoryAuthoringSnapshotStore(catalog, AuthoredSnapshotSeed(SnapshotId("s0"), emptyMap(), seedTokens))
        val emptyLease = store.capture()
        val reads = SnapshotReads(emptyLease.originalView())
        val selection = reads.select(TypedSelection(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE))))
        assertTrue(selection.knownMatches.isEmpty())
        val observation = reads.observations().single { it.identity == RESOURCE_SELECTION_INPUT }
        val added = record(name = "alpha")
        val resource = ResourceId("page")
        val addedTokens = tokensFor(mapOf(resource to added), catalog.generation, "added").toMutableMap()
        addedTokens[RESOURCE_SELECTION_INPUT] = InputToken("selection1")
        store.install(
            AuthoringSnapshotDelta(
                snapshot = SnapshotId("s1"),
                upsertedResources = mapOf(resource to added),
                inputTokens = addedTokens,
            ),
        )

        assertNotEquals(observation.token, store.currentToken(observation.identity))
        val currentLease = store.capture()
        assertEquals(
            1,
            SnapshotReads(
                currentLease.originalView(),
            ).select(TypedSelection(TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)))).knownMatches.size,
        )

        emptyLease.close()
        currentLease.close()
        store.close()
    }

    test("closingStoreDefersCatalogReleaseUntilRetainedSnapshotCloses") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val authored = record(name = "retained")
        val store =
            InMemoryAuthoringSnapshotStore(
                catalog,
                AuthoredSnapshotSeed(
                    SnapshotId("s0"),
                    mapOf(resource to authored),
                    tokensFor(mapOf(resource to authored), catalog.generation),
                ),
            )
        val retained = store.capture()

        store.close()

        assertEquals(1, catalog.openCount)
        assertEquals(
            "retained",
            SnapshotReads(retained.originalView()).read(boundPath<String>(location(resource, "name"), TEXT_USE)).available(),
        )
        assertFailsWith<IllegalStateException> { store.capture() }

        retained.close()
        assertEquals(0, catalog.openCount)
    }

    test("snapshot freezes nested type and link metadata from source mutation") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val pendingTypeArguments = mutableListOf<TypeUse>(TEXT_USE)
        val pendingArguments =
            mutableListOf<ArgumentSelection>(
                ArgumentSelection.Chosen(TypeUse.Named(TEST_TYPE, pendingTypeArguments)),
            )
        val namedArguments = mutableListOf<TypeUse>(TEXT_USE)
        val oppositeSegments = mutableListOf<PathSegment>(PathSegment.Field("owner"))
        val fields =
            mutableMapOf<String, DataValue>(
                "named" to DataValue.Named(TypeUse.Named(TEST_TYPE, namedArguments), DataValue.Record(emptyMap())),
                "link" to
                    DataValue.Link(
                        EndpointId("page.owner"),
                        LinkTarget(ResourceId("owner"), ValuePath(oppositeSegments)),
                    ),
            )
        val authored = AuthoringRecord(TypeSelection.Pending(TEST_TYPE, pendingArguments), fields)
        val store =
            InMemoryAuthoringSnapshotStore(
                catalog,
                AuthoredSnapshotSeed(
                    SnapshotId("s0"),
                    mapOf(resource to authored),
                    tokensFor(mapOf(resource to authored), catalog.generation),
                ),
            )

        pendingTypeArguments.clear()
        pendingArguments.clear()
        namedArguments.clear()
        oppositeSegments.clear()
        fields.clear()

        store.capture().use { captured ->
            val record = captured.root.resources.getValue(resource)
            val pending = record.configuration as TypeSelection.Pending
            val chosen = pending.arguments.single() as ArgumentSelection.Chosen
            assertEquals(listOf(TEXT_USE), (chosen.type as TypeUse.Named).arguments)
            assertEquals(
                listOf(TEXT_USE),
                (record.fields.getValue("named") as DataValue.Named).actualType.arguments,
            )
            assertEquals(
                listOf(PathSegment.Field("owner")),
                ((record.fields.getValue("link") as DataValue.Link).target.opposite ?: error("Missing opposite path")).segments,
            )
        }
        store.close()
    }

    test("commitGatePublishesSnapshotBeforeLaterCaptureCanProceed") {
        val catalog = TestCatalogLease()
        val resource = ResourceId("page")
        val initial = record(name = "before")
        val store =
            InMemoryAuthoringSnapshotStore(
                catalog,
                AuthoredSnapshotSeed(
                    SnapshotId("s0"),
                    mapOf(resource to initial),
                    tokensFor(mapOf(resource to initial), catalog.generation),
                ),
            )
        val committed = CountDownLatch(1)
        val release = CountDownLatch(1)
        val executor = Executors.newFixedThreadPool(2)
        val write =
            executor.submit<String> {
                store.commitAndInstall {
                    committed.countDown()
                    release.await()
                    SnapshotCommit(
                        result = "accepted",
                        delta =
                            AuthoringSnapshotDelta(
                                snapshot = SnapshotId("s1"),
                                upsertedResources = mapOf(resource to record(name = "after")),
                                inputTokens =
                                    mapOf(
                                        InputIdentity.Value(ValueLocation(resource, ValuePath())) to InputToken("after:root"),
                                        InputIdentity.Value(location(resource, "name")) to InputToken("after:name"),
                                    ),
                            ),
                    )
                }
            }
        assertTrue(committed.await(5, TimeUnit.SECONDS))
        val capture = executor.submit<SnapshotId> { store.capture().use { it.root.id } }
        Thread.sleep(50)
        assertTrue(!capture.isDone)

        release.countDown()

        assertEquals("accepted", write.get(5, TimeUnit.SECONDS))
        assertEquals(SnapshotId("s1"), capture.get(5, TimeUnit.SECONDS))
        executor.shutdownNow()
        store.close()
    }

    test("unavailableResourceKeepsItsCapturedDefinitionAndValueAcrossAnUnrelatedEdit") {
        val catalog = TestCatalogLease()
        val unavailable = ResourceId("unavailable")
        val available = ResourceId("available")
        val unavailableType = TypeDefinitionId(TypeId.Qualified("removed", "resource"), 1)
        val unavailableRecord =
            AuthoringRecord(
                configuration = TypeSelection.Complete(TypeUse.Named(unavailableType)),
                fields = mapOf("legacy" to DataValue.StringValue("preserved")),
            )
        val availableRecord = record(name = "before")
        val resources = mapOf(unavailable to unavailableRecord, available to availableRecord)
        val definitions =
            mapOf(
                unavailable to ResourceDefinitionId("removed_definition"),
                available to ResourceDefinitionId("test"),
            )
        val store =
            InMemoryAuthoringSnapshotStore(
                catalog,
                AuthoredSnapshotSeed(
                    SnapshotId("s0"),
                    resources,
                    tokensFor(resources, catalog.generation),
                    definitions,
                ),
            )

        val edited = record(name = "after")
        val change: Map<InputIdentity, InputToken> =
            mapOf(
                InputIdentity.Value(ValueLocation(available, ValuePath())) to InputToken("edited:root"),
                InputIdentity.Value(location(available, "name")) to InputToken("edited:name"),
            )
        store.install(
            AuthoringSnapshotDelta(
                snapshot = SnapshotId("s1"),
                upsertedResources = mapOf(available to edited),
                resourceDefinitions = mapOf(available to ResourceDefinitionId("replacement")),
                inputTokens = change,
            ),
        )

        store.capture().use { captured ->
            assertEquals(unavailableRecord, captured.root.resources[unavailable])
            assertEquals(ResourceDefinitionId("removed_definition"), captured.root.resourceDefinitions[unavailable])
            assertEquals(ResourceDefinitionId("test"), captured.root.resourceDefinitions[available])
        }
        store.close()
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
) : SnapshotCatalogLease {
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

    override fun retain(): SnapshotCatalogLease {
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
