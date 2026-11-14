@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.append
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.discovery.CollectedDynamics
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import com.typewritermc.realm.catalog.CollectedExtensions
import com.typewritermc.realm.catalog.ExtensionCatalog
import com.typewritermc.realm.catalog.collectExtensions
import com.typewritermc.testkit.definitions
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.rows
import com.typewritermc.types.template
import com.typewritermc.types.use
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
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
import java.math.BigInteger
import java.util.concurrent.atomic.AtomicInteger

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
    override val configuration: List<skirout.editor.v1.catalog.ConfigurationRecipe>,
    private val definitions: List<TypeDefinition>,
    private val nativeBindingFactories: List<NativeBindingFactory>,
    override val relations: List<RelationContract>,
) : AuthoringCatalogLease {
    constructor(
        generation: CatalogGeneration = CatalogGeneration(value = "catalog"),
        providers: OwnedProviderRegistry = EmptyProviders,
        checks: List<OwnedCheckRecipe> = emptyList(),
        configuration: List<skirout.editor.v1.catalog.ConfigurationRecipe> = emptyList(),
        definitions: List<TypeDefinition> = TEST_DEFINITIONS,
        nativeBindingFactories: List<NativeBindingFactory> = emptyList(),
        relations: List<RelationContract> = emptyList(),
    ) : this(
        State(),
        generation,
        providers,
        checks,
        configuration,
        definitions,
        nativeBindingFactories,
        relations,
    )

    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, definitions)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, nativeBindingFactories)
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, ValuePath>()
    internal val openCount: Int get() = state.open.get()
    override val extensions: ExtensionCatalog get() = state.extensions(checks, configuration, providers)

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
        )
    }

    override fun close() {
        if (state.open.decrementAndGet() == 0) state.close()
    }

    /** What every lease of one catalog shares: how many are open, and the extensions collected on first read. */
    private class State {
        val open = AtomicInteger(1)
        private var collected: CollectedExtensions? = null

        @Synchronized
        fun extensions(
            checks: List<OwnedCheckRecipe>,
            configuration: List<skirout.editor.v1.catalog.ConfigurationRecipe>,
            providers: OwnedProviderRegistry,
        ): ExtensionCatalog =
            (
                collected
                    ?: CollectedExtensions { collectExtensions(checks, configuration, CollectedDynamics.NONE, providers) }.also {
                        collected =
                            it
                    }
            ).value

        @Synchronized
        fun close() {
            collected?.close()
        }
    }
}

internal data object EmptyProviders : OwnedProviderRegistry {
    override fun retain(origin: ProviderOrigin): ProviderLease = error("No providers are registered.")

    override fun configurations(): List<OwnedConfiguration> = emptyList()

    override fun presentations(): List<OwnedPresentation> = emptyList()

    override fun nativeBindings(): List<OwnedNativeBinding> = emptyList()

    override fun checks(): List<com.typewritermc.discovery.OwnedCheck> = emptyList()

    override fun dynamics(): List<com.typewritermc.discovery.OwnedDynamic> = emptyList()

    override fun formulas(): List<com.typewritermc.discovery.OwnedFormulaFunction> = emptyList()
}

internal fun record(
    name: String = "name",
    count: Int = 1,
    numbers: List<Pair<String, Int>> = emptyList(),
): AuthoringRecord =
    AuthoringRecord.of(
        configuration = TypeSelection.of(TEST_TYPE.namedUse()),
        fields =
            mapOf(
                "name" to DataValue.StringValueWrapper(name),
                "count" to DataValue.integer(BigInteger.valueOf(count.toLong())),
                "numbers" to
                    DataValue.named(
                        LIST_USE,
                        DataValue.listValue(
                            numbers.map { (id, value) ->
                                ListItem(id = ItemId(value = id), value = DataValue.integer(BigInteger.valueOf(value.toLong())))
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
        val root = ValueLocation.of(resource)
        identities += InputIdentity.Existence(resource)
        identities += InputIdentity.Form(root)
        identities += InputIdentity.Value(root)
        record.fields.forEach { field -> collectTokens(field.value, root.field(field.name), identities) }
    }
    return identities.withIndex().associate { (index, identity) -> identity to InputToken(value = "$prefix:$index") }
}

internal fun collectTokens(
    value: DataValue,
    at: ValueLocation,
    identities: MutableSet<InputIdentity>,
) {
    identities += InputIdentity.Value(at)
    when (value) {
        is DataValue.ListValueWrapper -> {
            identities += InputIdentity.Membership(at)
            identities += InputIdentity.Order(at)
            value.items.forEach { collectTokens(it.value, at.append(PathSegment.createItem(id = it.id)), identities) }
        }

        is DataValue.SetValueWrapper -> {
            identities += InputIdentity.Membership(at)
            identities += InputIdentity.Order(at)
            value.items.forEach { collectTokens(it.value, at.append(PathSegment.createItem(id = it.id)), identities) }
        }

        is DataValue.RecordWrapper -> {
            value.fields.forEach { field -> collectTokens(field.value, at.append(PathSegment.createField(name = field.name)), identities) }
        }

        is DataValue.NamedWrapper -> {
            identities += InputIdentity.Form(at)
            collectTokens(value.payload, at, identities)
        }

        is DataValue.MapValueWrapper -> {
            identities += InputIdentity.Membership(at)
            identities += InputIdentity.Order(at)
            value.rows.forEach { row ->
                collectTokens(row.key, at.append(PathSegment.createItem(id = row.id), PathSegment.MAP_KEY), identities)
                collectTokens(row.value, at.append(PathSegment.createItem(id = row.id), PathSegment.MAP_VALUE), identities)
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
): ValueLocation = ValueLocation.of(resource, ValuePath.root.field(field))

/** The location of the item [item] in the list or set field [field] of [resource]. */
internal fun listItemAt(
    resource: ResourceId,
    field: String,
    item: String,
): ValueLocation =
    ValueLocation.of(
        resource,
        ValuePath(segments = listOf(PathSegment.createField(name = field), PathSegment.createItem(id = ItemId(value = item)))),
    )

/**
 * Renames the resource [id], saved as [initial], to [next]. The edit is guarded as an editor guards it: the resource
 * exists with [initial]'s configuration, and its `name` reads [expected] when the edit is committed.
 */
internal fun renameEdit(
    catalog: CatalogGeneration,
    id: ResourceId,
    initial: AuthoringRecord,
    expected: String = "Quest",
    next: String = "Story",
): PreparedEdit {
    val title = location(id, "name")
    return PreparedEdit(
        catalog = catalog,
        expectations =
            listOf(
                EditExpectation.createResourceExists(id = id, expected = true),
                EditExpectation.createConfiguration(at = ValueLocation.of(id), expected = initial.configuration),
                EditExpectation.createConfiguration(at = title, expected = null),
                EditExpectation.createValue(at = title, expected = DataValue.StringValueWrapper(expected)),
            ),
        intents = listOf(EditIntent.createSetValue(at = title, value = DataValue.StringValueWrapper(next))),
    )
}

internal fun <T> com.typewritermc.authoring.Availability<T>.available(): T =
    (this as com.typewritermc.authoring.Availability.Available).value

internal val TEST_TYPE = TypeDefinitionId.qualified("test", "resource")
internal val LIST_TYPE = TypeDefinitionId.qualified("typewriter", "list")
internal val TEXT_USE = ScalarKind.TEXT.use
internal val INT_USE = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
internal val LIST_USE = LIST_TYPE.namedUse(listOf(INT_USE))
internal val LIST_PARAMETER = ParameterKey(owner = LIST_TYPE, index = 0)

/** The test resource with a name, a count and a list of numbers, and the generic list it uses. */
internal val TEST_DEFINITIONS =
    definitions {
        record(TEST_TYPE) {
            field("name", ScalarKind.TEXT.template)
            field("count", integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)
            field("numbers", LIST_TYPE.template(listOf(integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)))
        }
        sequence(
            LIST_TYPE,
            item = LIST_PARAMETER.template,
            kind = CollectionKind.LIST,
            parameters = listOf(TypeParameter.partial(key = LIST_PARAMETER, name = "T")),
        )
    }

/** A generic record type with one parameter and no fields: a selection that leaves its parameter unchosen is a partial type. */
internal val PENDING_GENERIC = TypeDefinitionId.qualified("test", "pending_generic")
internal val PENDING_GENERIC_DEFINITION =
    TypeDefinition.partial(
        id = PENDING_GENERIC,
        parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = PENDING_GENERIC, index = 0), name = "T")),
        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
    )
