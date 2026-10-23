@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.append
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.realm.catalog.AuthoringCatalogLease
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
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
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
        definitions: List<TypeDefinition> = listOf(TEST_DEFINITION, LIST_DEFINITION),
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
    AuthoringRecord.of(
        configuration = TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
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
