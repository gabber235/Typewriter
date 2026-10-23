package com.typewritermc.realm.operation

import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.requireValid
import com.typewritermc.authoring.with
import com.typewritermc.checking.InputIdentity
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.EmptyProviders
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.edit.AuthoringMutationPlanner
import com.typewritermc.realm.edit.AuthoringRepository
import com.typewritermc.realm.edit.MutationPlanningResult
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.fields
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.LinkRepairIntent
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.TypeArgumentChangePreview
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

class TypeArgumentOperationsTest {
    fun previewRejectsDefinitionReplacementAndStructurallyInvalidRepairBatch() {
        val catalog = RepairCatalogLease()
        val resource = ResourceId(value = "container")
        val record = repairRecord(ItemId(value = "bundle"))
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to record)),
            )
        val operations = DefaultTypeArgumentOperations(store)

        store.capture().use { snapshot ->
            operations
                .preview(
                    resource,
                    TypeSelection.CompleteWrapper(BUNDLE_COIN),
                    snapshot,
                ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
        }
        store.close()

        val invalid = record.with("unknown", DataValue.StringValueWrapper("retained"))
        val invalidCatalog = RepairCatalogLease()
        val invalidStore =
            InMemoryAuthoringViewStore(
                invalidCatalog,
                AuthoringSeed(mapOf(resource to invalid)),
            )
        invalidStore.capture().use { snapshot ->
            DefaultTypeArgumentOperations(invalidStore)
                .preview(resource, TypeSelection.CompleteWrapper(CONTAINER_COIN), snapshot)
                .shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.RejectedErrorWrapper>()
        }
        invalidStore.close()
    }

    fun narrowingRetagsTaggedContainersAndClearsOnlyIncompatibleLeaves() {
        val catalog = RepairCatalogLease()
        val resource = ResourceId(value = "container")
        val item = ItemId(value = "bundle")
        val record = repairRecord(item)
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to record)),
            )
        val repository = RecordingRepository()
        val operations = DefaultTypeArgumentOperations(store)

        val preview =
            store.capture().use { snapshot ->
                operations
                    .preview(
                        resource,
                        TypeSelection.CompleteWrapper(CONTAINER_COIN),
                        snapshot,
                    ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>()
                    .value
            }

        val bundles = location(resource, "bundles")
        val bundle =
            ValueLocation.of(
                resource,
                ValuePath(
                    segments =
                        bundles.path.segments +
                            PathSegment.createItem(id = item),
                ),
            )
        val title =
            ValueLocation.of(
                resource,
                ValuePath(
                    segments =
                        bundle.path.segments +
                            PathSegment.createField(name = "title"),
                ),
            )
        val incompatible =
            ValueLocation.of(
                resource,
                ValuePath(
                    segments =
                        bundle.path.segments +
                            PathSegment.createField(name = "value"),
                ),
            )
        val compatible = location(resource, "reward")
        preview.edit.intents shouldBe
            listOf(
                EditIntent.createConfigureResource(resource = resource, configuration = TypeSelection.CompleteWrapper(CONTAINER_COIN)),
                EditIntent.createRetag(at = bundles, type = LIST_BUNDLE_COIN),
                EditIntent.createRetag(at = bundle, type = BUNDLE_COIN),
                EditIntent.createSetValue(at = incompatible, value = DataValue.UNFILLED),
            )
        preview.clearedLocations shouldBe listOf(incompatible)
        val observed = preview.edit.expectations.flatMapTo(linkedSetOf()) { it.dependencies() }
        (InputIdentity.Value(title) in observed) shouldBe true
        (InputIdentity.Value(compatible) in observed) shouldBe true
        (InputIdentity.Value(incompatible) in observed) shouldBe true
        (InputIdentity.Value(bundles) in observed) shouldBe true
        (InputIdentity.Value(bundles) in observed) shouldBe true
        preview.edit.intents.any { it == EditIntent.createSetValue(at = compatible, value = DataValue.UNFILLED) } shouldBe false

        store.close()
    }

    fun confirmationRetainsEvidenceForCompatibleValues() =
        runTest {
            val catalog = RepairCatalogLease()
            val resource = ResourceId(value = "container")
            val record = repairRecord(ItemId(value = "bundle"))
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to record)),
                )
            val repository = RecordingRepository()
            val operations = DefaultTypeArgumentOperations(store)
            val preview =
                store.capture().use { snapshot ->
                    operations
                        .preview(
                            resource,
                            TypeSelection.CompleteWrapper(CONTAINER_COIN),
                            snapshot,
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>()
                        .value
                }

            val edit =
                operations
                    .prepare(preview)
                    .shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.PreparedWrapper>()
                    .value.edit
            repository.commit(edit)
            edit.expectations.any { InputIdentity.Value(location(resource, "reward")) in it.dependencies() } shouldBe true
            repository.edit shouldBe edit
            store.close()
        }

    fun unfinishedSelectionPreservesIndependentAndCompatibleFieldsAndCanLaterComplete() =
        runTest {
            val catalog = RepairCatalogLease()
            val resource = ResourceId(value = "dual")
            val original = dualRecord(TypeSelection.CompleteWrapper(DUAL_COIN_GEM))
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to original)),
                )
            val repository = RecordingRepository()
            val operations = DefaultTypeArgumentOperations(store)
            val pending =
                TypeSelection.createPending(
                    definition = DUAL,
                    arguments = listOf(ArgumentSelection.ChosenWrapper(COIN_USE.use), ArgumentSelection.UNFILLED),
                )

            val pendingPreview =
                store.capture().use { snapshot ->
                    operations
                        .preview(
                            resource,
                            pending,
                            snapshot,
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>()
                        .value
                }

            pendingPreview.next shouldBe pending
            pendingPreview.edit.intents.contains(EditIntent.createConfigureResource(resource = resource, configuration = pending)) shouldBe
                true
            pendingPreview.edit.intents.contains(
                EditIntent.createSetValue(at = location(resource, "second"), value = DataValue.UNFILLED),
            ) shouldBe
                true
            pendingPreview.edit.intents.contains(
                EditIntent.createSetValue(at = location(resource, "name"), value = DataValue.UNFILLED),
            ) shouldBe
                false
            pendingPreview.edit.intents.contains(
                EditIntent.createSetValue(at = location(resource, "first"), value = DataValue.UNFILLED),
            ) shouldBe
                false

            val pendingEdit =
                operations
                    .prepare(
                        pendingPreview,
                    ).shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.PreparedWrapper>()
                    .value.edit
            val pendingPlan =
                AuthoringMutationPlanner(
                    catalog.checked,
                    emptyList(),
                ).plan(mapOf(resource to original), pendingEdit).shouldBeInstanceOf<MutationPlanningResult.Accepted>().plan
            val pendingRecord = pendingPlan.resources.getValue(resource)
            pendingRecord.configuration shouldBe pending
            pendingRecord.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("kept")
            pendingRecord.fieldMap.getValue("first") shouldBe original.fieldMap.getValue("first")
            pendingRecord.fieldMap.getValue("second") shouldBe DataValue.UNFILLED

            val pendingStore =
                InMemoryAuthoringViewStore(
                    catalog.retain(),
                    AuthoringSeed(mapOf(resource to pendingRecord)),
                )
            val complete = TypeSelection.CompleteWrapper(DUAL_COIN_COIN)
            val completePreview =
                pendingStore.capture().use { snapshot ->
                    operations
                        .preview(
                            resource,
                            complete,
                            snapshot,
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>()
                        .value
                }
            completePreview.next shouldBe complete
            completePreview.edit.intents.contains(
                EditIntent.createConfigureResource(resource = resource, configuration = complete),
            ) shouldBe
                true
            completePreview.edit.intents.contains(
                EditIntent.createSetValue(at = location(resource, "first"), value = DataValue.UNFILLED),
            ) shouldBe
                false

            pendingStore.close()
            store.close()
        }

    fun confirmationRejectsAlteredReceiptAndAcceptsAnExactRetry() =
        runTest {
            val catalog = RepairCatalogLease()
            val resource = ResourceId(value = "dual")
            val original = dualRecord(TypeSelection.CompleteWrapper(DUAL_COIN_GEM))
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to original)),
                )
            val repository = RecordingRepository()
            val operations = DefaultTypeArgumentOperations(store)
            val pending =
                TypeSelection.createPending(
                    definition = DUAL,
                    arguments = listOf(ArgumentSelection.ChosenWrapper(COIN_USE.use), ArgumentSelection.UNFILLED),
                )
            val preview =
                store.capture().use { snapshot ->
                    operations
                        .preview(
                            resource,
                            pending,
                            snapshot,
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>()
                        .value
                }

            operations
                .prepare(
                    preview.copy(
                        edit =
                            preview.edit
                                .copy(
                                    intents =
                                        listOf(
                                            EditIntent.createConfigureResource(
                                                resource = resource,
                                                configuration = TypeSelection.CompleteWrapper(DUAL_COIN_COIN),
                                            ),
                                        ),
                                ),
                    ),
                ).shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.RejectedErrorWrapper>()
            repository.edit shouldBe null
            operations
                .prepare(
                    preview.copy(edit = preview.edit.copy(expectations = preview.edit.expectations.dropLast(1))),
                ).shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.RejectedErrorWrapper>()
            repository.edit shouldBe null

            val prepared =
                operations
                    .prepare(preview)
                    .shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.PreparedWrapper>()
                    .value.edit
            repository.edit shouldBe null
            repository.commit(prepared).shouldBeInstanceOf<CommitPreparedEditResponse.COMMITTED>()
            repository.edit shouldBe prepared
            store.close()
        }

    fun unfinishedSelectionClearsLinksWhoseDependentTargetIsUnknown() {
        val catalog = RepairCatalogLease()
        val resource = ResourceId(value = "dual")
        val target = ResourceId(value = "target")
        val linkLocation = location(resource, "target")
        val linked =
            dualRecord(TypeSelection.CompleteWrapper(DUAL_COIN_GEM)).with(
                "target",
                DataValue.named(
                    LINK_GEM,
                    DataValue.createLink(
                        endpoint = SOURCE_ENDPOINT,
                        target = LinkTarget(resource = target, opposite = null),
                    ),
                ),
            )
        val resources =
            mapOf(
                resource to linked,
                target to AuthoringRecord.of(TypeSelection.CompleteWrapper(GEM_USE), emptyMap()),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val pending =
            TypeSelection.createPending(
                definition = DUAL,
                arguments = listOf(ArgumentSelection.ChosenWrapper(COIN_USE.use), ArgumentSelection.UNFILLED),
            )
        val preview =
            store.capture().use { snapshot ->
                DefaultTypeArgumentOperations(
                    store,
                ).preview(resource, pending, snapshot).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>().value
            }

        preview.clearedLocations.contains(linkLocation) shouldBe true
        preview.edit.intents.none { it == EditIntent.createSetValue(at = linkLocation, value = DataValue.UNFILLED) } shouldBe true
        preview.linkRepairs shouldBe
            listOf(
                LinkRepairIntent.ClearWrapper(
                    LinkOccurrenceId(endpoint = SOURCE_ENDPOINT, location = linkLocation),
                ),
            )
        preview.edit.expectations.any { InputIdentity.Incoming(resource, RELATION) in it.dependencies() } shouldBe true
        store.close()
    }
}

private class RecordingRepository : AuthoringRepository {
    var edit: PreparedEdit? = null

    override suspend fun commit(edit: PreparedEdit): CommitPreparedEditResponse {
        this.edit = edit
        return CommitPreparedEditResponse.COMMITTED
    }
}

private class RepairCatalogLease(
    override val generation: CatalogGeneration = CatalogGeneration(value = "catalog"),
) : AuthoringCatalogLease {
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, REPAIR_DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers: OwnedProviderRegistry = EmptyProviders
    override val checks: List<OwnedCheckRecipe> = emptyList()
    override val relations: List<RelationContract> = listOf(DUAL_RELATION)
    override val endpointBindings: List<EndpointBindingTemplate> = emptyList()
    override val configuration: List<skirout.editor.v1.catalog.ConfigurationRecipe> = emptyList()
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, ValuePath>()

    override fun retain(): AuthoringCatalogLease = RepairCatalogLease(generation)

    override fun close() = Unit
}

private fun repairRecord(item: ItemId): AuthoringRecord =
    AuthoringRecord.of(
        configuration = TypeSelection.CompleteWrapper(CONTAINER_REWARD),
        fields =
            mapOf(
                "bundles" to
                    DataValue.named(
                        LIST_BUNDLE_REWARD,
                        DataValue.listValue(
                            listOf(
                                ListItem(
                                    id = item,
                                    value =
                                        DataValue.named(
                                            BUNDLE_REWARD,
                                            DataValue.record(
                                                mapOf(
                                                    "title" to DataValue.StringValueWrapper("kept"),
                                                    "value" to DataValue.named(GEM_USE, DataValue.record(emptyMap())),
                                                ),
                                            ),
                                        ),
                                ),
                            ),
                        ),
                    ),
                "reward" to DataValue.named(COIN_USE, DataValue.record(emptyMap())),
            ),
    )

private fun dualRecord(selection: TypeSelection): AuthoringRecord =
    AuthoringRecord.of(
        configuration = selection,
        fields =
            mapOf(
                "name" to DataValue.StringValueWrapper("kept"),
                "first" to DataValue.named(COIN_USE, DataValue.record(emptyMap())),
                "second" to DataValue.named(GEM_USE, DataValue.record(emptyMap())),
            ),
    )

private fun location(
    resource: ResourceId,
    field: String,
) = ValueLocation.of(
    resource,
    ValuePath(
        segments =
            listOf(
                PathSegment.createField(name = field),
            ),
    ),
)

private val REWARD = definition("reward")
private val COIN = definition("coin")
private val GEM = definition("gem")
private val BUNDLE = definition("bundle")
private val LIST = definition("list")
private val CONTAINER = definition("container")
private val DUAL = definition("dual")
private val LINK = definition("link")
private val BUNDLE_PARAMETER = ParameterKey(owner = BUNDLE, index = 0)
private val LIST_PARAMETER = ParameterKey(owner = LIST, index = 0)
private val CONTAINER_PARAMETER = ParameterKey(owner = CONTAINER, index = 0)
private val DUAL_FIRST_PARAMETER = ParameterKey(owner = DUAL, index = 0)
private val DUAL_SECOND_PARAMETER = ParameterKey(owner = DUAL, index = 1)
private val LINK_PARAMETER = ParameterKey(owner = LINK, index = 0)
private val REWARD_USE = REWARD.use()
private val COIN_USE = COIN.namedUse()
private val GEM_USE = GEM.namedUse()
private val BUNDLE_REWARD = BUNDLE.namedUse(listOf(REWARD_USE))
private val BUNDLE_COIN = BUNDLE.namedUse(listOf(COIN_USE.use))
private val LIST_BUNDLE_REWARD = LIST.namedUse(listOf(BUNDLE_REWARD.use))
private val LIST_BUNDLE_COIN = LIST.namedUse(listOf(BUNDLE_COIN.use))
private val CONTAINER_REWARD = CONTAINER.namedUse(listOf(REWARD_USE))
private val CONTAINER_COIN = CONTAINER.namedUse(listOf(COIN_USE.use))
private val DUAL_COIN_GEM = DUAL.namedUse(listOf(COIN_USE.use, GEM_USE.use))
private val DUAL_COIN_COIN = DUAL.namedUse(listOf(COIN_USE.use, COIN_USE.use))
private val LINK_GEM = LINK.namedUse(listOf(GEM_USE.use))
private val SOURCE_ENDPOINT = EndpointId(value = "dual:source")
private val TARGET_ENDPOINT = EndpointId(value = "dual:target")
private val RELATION = RelationId(value = "dual:relation")
private val DUAL_RELATION =
    RelationContract.of(
        RELATION,
        EndpointDefinition(
            id = SOURCE_ENDPOINT,
            slot = EndpointSlot.FIRST,
            resource = DUAL.namedTemplate(listOf(DUAL_FIRST_PARAMETER.template, DUAL_SECOND_PARAMETER.template)),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            id = TARGET_ENDPOINT,
            slot = EndpointSlot.SECOND,
            resource = REWARD.namedTemplate(),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
    )

private val REPAIR_DEFINITIONS =
    listOf(
        TypeDefinition.partial(id = REWARD, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true)),
        TypeDefinition.partial(
            id = COIN,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            parents = listOf(REWARD.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = GEM,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            parents = listOf(REWARD.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = BUNDLE,
            parameters = listOf(TypeParameter.partial(key = BUNDLE_PARAMETER, name = "value")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = BUNDLE, name = "title"),
                                type = ScalarKind.TEXT.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = BUNDLE, name = "value"),
                                type = BUNDLE_PARAMETER.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = LIST,
            parameters = listOf(TypeParameter.partial(key = LIST_PARAMETER, name = "item")),
            representation = RepresentationTemplate.createSequence(item = LIST_PARAMETER.template, kind = CollectionKind.LIST),
        ),
        TypeDefinition.partial(
            id = CONTAINER,
            parameters = listOf(TypeParameter.partial(key = CONTAINER_PARAMETER, name = "reward")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = CONTAINER, name = "bundles"),
                                type = LIST.template(listOf(BUNDLE.template(listOf(CONTAINER_PARAMETER.template)))),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = CONTAINER, name = "reward"),
                                type = CONTAINER_PARAMETER.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = LINK,
            parameters = listOf(TypeParameter.partial(key = LINK_PARAMETER, name = "target")),
            representation = RepresentationTemplate.createLink(endpoint = SOURCE_ENDPOINT, target = LINK_PARAMETER.template),
        ),
        TypeDefinition.partial(
            id = DUAL,
            parameters =
                listOf(
                    TypeParameter.partial(key = DUAL_FIRST_PARAMETER, name = "first"),
                    TypeParameter.partial(key = DUAL_SECOND_PARAMETER, name = "second"),
                ),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = DUAL, name = "name"), type = ScalarKind.TEXT.template),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUAL, name = "first"),
                                type = DUAL_FIRST_PARAMETER.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUAL, name = "second"),
                                type = DUAL_SECOND_PARAMETER.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUAL, name = "target"),
                                type = LINK.template(listOf(DUAL_SECOND_PARAMETER.template)),
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
    )

private fun definition(name: String) = TypeDefinitionId.qualified("repair", name)

val TypeArgumentOperationsTestSuite by testSuite {
    test("previewRejectsDefinitionReplacementAndStructurallyInvalidRepairBatch") {
        TypeArgumentOperationsTest().previewRejectsDefinitionReplacementAndStructurallyInvalidRepairBatch()
    }
    test("narrowingRetagsTaggedContainersAndClearsOnlyIncompatibleLeaves") {
        TypeArgumentOperationsTest().narrowingRetagsTaggedContainersAndClearsOnlyIncompatibleLeaves()
    }
    test("confirmationRetainsEvidenceForCompatibleValues") { TypeArgumentOperationsTest().confirmationRetainsEvidenceForCompatibleValues() }
    test("unfinishedSelectionPreservesIndependentAndCompatibleFieldsAndCanLaterComplete") {
        TypeArgumentOperationsTest().unfinishedSelectionPreservesIndependentAndCompatibleFieldsAndCanLaterComplete()
    }
    test("confirmationRejectsAlteredReceiptAndAcceptsAnExactRetry") {
        TypeArgumentOperationsTest().confirmationRejectsAlteredReceiptAndAcceptsAnExactRetry()
    }
    test("unfinishedSelectionClearsLinksWhoseDependentTargetIsUnknown") {
        TypeArgumentOperationsTest().unfinishedSelectionClearsLinksWhoseDependentTargetIsUnknown()
    }
}
