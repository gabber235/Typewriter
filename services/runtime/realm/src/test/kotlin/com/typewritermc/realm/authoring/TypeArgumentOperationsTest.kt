package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

class TypeArgumentOperationsTest {
    fun previewRejectsDefinitionReplacementAndStructurallyInvalidRepairBatch() {
        val catalog = RepairCatalogLease()
        val resource = ResourceId("container")
        val record = repairRecord(ItemId("bundle"))
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
                    TypeSelection.Complete(BUNDLE_COIN),
                    snapshot,
                ).shouldBeInstanceOf<TypePreviewResult.InvalidArguments>()
        }
        store.close()

        val invalid = record.copy(fields = record.fields + ("unknown" to DataValue.StringValue("retained")))
        val invalidCatalog = RepairCatalogLease()
        val invalidStore =
            InMemoryAuthoringViewStore(
                invalidCatalog,
                AuthoringSeed(mapOf(resource to invalid)),
            )
        invalidStore.capture().use { snapshot ->
            DefaultTypeArgumentOperations(invalidStore)
                .preview(resource, TypeSelection.Complete(CONTAINER_COIN), snapshot)
                .shouldBeInstanceOf<TypePreviewResult.Rejected>()
        }
        invalidStore.close()
    }

    fun narrowingRetagsTaggedContainersAndClearsOnlyIncompatibleLeaves() {
        val catalog = RepairCatalogLease()
        val resource = ResourceId("container")
        val item = ItemId("bundle")
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
                        TypeSelection.Complete(CONTAINER_COIN),
                        snapshot,
                    ).shouldBeInstanceOf<TypePreviewResult.Ready>()
                    .preview
            }

        val bundles = location(resource, "bundles")
        val bundle =
            ValueLocation(
                resource,
                ValuePath(
                    bundles.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Item(item),
                ),
            )
        val title =
            ValueLocation(
                resource,
                ValuePath(
                    bundle.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Field("title"),
                ),
            )
        val incompatible =
            ValueLocation(
                resource,
                ValuePath(
                    bundle.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                ),
            )
        val compatible = location(resource, "reward")
        preview.edit.intents shouldBe
            listOf(
                EditIntent.ConfigureResource(resource, TypeSelection.Complete(CONTAINER_COIN)),
                EditIntent.Retag(bundles, LIST_BUNDLE_COIN),
                EditIntent.Retag(bundle, BUNDLE_COIN),
                EditIntent.SetValue(incompatible, DataValue.Unfilled),
            )
        preview.clearedLocations shouldBe listOf(incompatible)
        val observed = preview.edit.expectations.flatMapTo(linkedSetOf()) { it.dependencies() }
        (InputIdentity.Value(title) in observed) shouldBe true
        (InputIdentity.Value(compatible) in observed) shouldBe true
        (InputIdentity.Value(incompatible) in observed) shouldBe true
        (InputIdentity.Value(bundles) in observed) shouldBe true
        (InputIdentity.Value(bundles) in observed) shouldBe true
        preview.edit.intents.any { it == EditIntent.SetValue(compatible, DataValue.Unfilled) } shouldBe false

        store.close()
    }

    fun confirmationRetainsEvidenceForCompatibleValues() =
        runTest {
            val catalog = RepairCatalogLease()
            val resource = ResourceId("container")
            val record = repairRecord(ItemId("bundle"))
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
                            TypeSelection.Complete(CONTAINER_COIN),
                            snapshot,
                        ).shouldBeInstanceOf<TypePreviewResult.Ready>()
                        .preview
                }

            val edit = operations.prepare(preview).shouldBeInstanceOf<PreparedEditResult.Prepared>().edit
            repository.commit(edit)
            edit.expectations.any { InputIdentity.Value(location(resource, "reward")) in it.dependencies() } shouldBe true
            repository.edit shouldBe edit
            store.close()
        }

    fun unfinishedSelectionPreservesIndependentAndCompatibleFieldsAndCanLaterComplete() =
        runTest {
            val catalog = RepairCatalogLease()
            val resource = ResourceId("dual")
            val original = dualRecord(TypeSelection.Complete(DUAL_COIN_GEM))
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to original)),
                )
            val repository = RecordingRepository()
            val operations = DefaultTypeArgumentOperations(store)
            val pending =
                TypeSelection.Pending(
                    DUAL,
                    listOf(ArgumentSelection.Chosen(COIN_USE.use), ArgumentSelection.Unfilled),
                )

            val pendingPreview =
                store.capture().use { snapshot ->
                    operations.preview(resource, pending, snapshot).shouldBeInstanceOf<TypePreviewResult.Ready>().preview
                }

            pendingPreview.next shouldBe pending
            pendingPreview.edit.intents.contains(EditIntent.ConfigureResource(resource, pending)) shouldBe true
            pendingPreview.edit.intents.contains(EditIntent.SetValue(location(resource, "second"), DataValue.Unfilled)) shouldBe true
            pendingPreview.edit.intents.contains(EditIntent.SetValue(location(resource, "name"), DataValue.Unfilled)) shouldBe false
            pendingPreview.edit.intents.contains(EditIntent.SetValue(location(resource, "first"), DataValue.Unfilled)) shouldBe false

            val pendingEdit = operations.prepare(pendingPreview).shouldBeInstanceOf<PreparedEditResult.Prepared>().edit
            val pendingPlan =
                AuthoringMutationPlanner(
                    catalog.checked,
                    emptyList(),
                ).plan(mapOf(resource to original), pendingEdit).shouldBeInstanceOf<MutationPlanningResult.Accepted>().plan
            val pendingRecord = pendingPlan.resources.getValue(resource)
            pendingRecord.configuration shouldBe pending
            pendingRecord.fields.getValue("name") shouldBe DataValue.StringValue("kept")
            pendingRecord.fields.getValue("first") shouldBe original.fields.getValue("first")
            pendingRecord.fields.getValue("second") shouldBe DataValue.Unfilled

            val pendingStore =
                InMemoryAuthoringViewStore(
                    catalog.retain(),
                    AuthoringSeed(mapOf(resource to pendingRecord)),
                )
            val complete = TypeSelection.Complete(DUAL_COIN_COIN)
            val completePreview =
                pendingStore.capture().use { snapshot ->
                    operations.preview(resource, complete, snapshot).shouldBeInstanceOf<TypePreviewResult.Ready>().preview
                }
            completePreview.next shouldBe complete
            completePreview.edit.intents.contains(EditIntent.ConfigureResource(resource, complete)) shouldBe true
            completePreview.edit.intents.contains(EditIntent.SetValue(location(resource, "first"), DataValue.Unfilled)) shouldBe false

            pendingStore.close()
            store.close()
        }

    fun confirmationRejectsAlteredReceiptAndAcceptsAnExactRetry() =
        runTest {
            val catalog = RepairCatalogLease()
            val resource = ResourceId("dual")
            val original = dualRecord(TypeSelection.Complete(DUAL_COIN_GEM))
            val store =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to original)),
                )
            val repository = RecordingRepository()
            val operations = DefaultTypeArgumentOperations(store)
            val pending =
                TypeSelection.Pending(
                    DUAL,
                    listOf(ArgumentSelection.Chosen(COIN_USE.use), ArgumentSelection.Unfilled),
                )
            val preview =
                store.capture().use { snapshot ->
                    operations.preview(resource, pending, snapshot).shouldBeInstanceOf<TypePreviewResult.Ready>().preview
                }

            operations
                .prepare(
                    preview.copy(
                        edit =
                            preview.edit.copy(
                                intents = listOf(EditIntent.ConfigureResource(resource, TypeSelection.Complete(DUAL_COIN_COIN))),
                            ),
                    ),
                ).shouldBeInstanceOf<PreparedEditResult.Rejected>()
            repository.edit shouldBe null
            operations
                .prepare(
                    preview.copy(edit = preview.edit.copy(expectations = preview.edit.expectations.dropLast(1))),
                ).shouldBeInstanceOf<PreparedEditResult.Rejected>()
            repository.edit shouldBe null

            val prepared = operations.prepare(preview).shouldBeInstanceOf<PreparedEditResult.Prepared>().edit
            repository.edit shouldBe null
            repository.commit(prepared).shouldBeInstanceOf<CommitResult.Committed>()
            repository.edit shouldBe prepared
            store.close()
        }

    fun unfinishedSelectionClearsLinksWhoseDependentTargetIsUnknown() {
        val catalog = RepairCatalogLease()
        val resource = ResourceId("dual")
        val target = ResourceId("target")
        val linkLocation = location(resource, "target")
        val linked =
            dualRecord(TypeSelection.Complete(DUAL_COIN_GEM)).copy(
                fields =
                    dualRecord(TypeSelection.Complete(DUAL_COIN_GEM)).fields +
                        (
                            "target" to
                                DataValue.Named(
                                    LINK_GEM,
                                    DataValue.Link(SOURCE_ENDPOINT, LinkTarget(target, null)),
                                )
                        ),
            )
        val resources =
            mapOf(
                resource to linked,
                target to AuthoringRecord(TypeSelection.Complete(GEM_USE), emptyMap()),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val pending =
            TypeSelection.Pending(
                DUAL,
                listOf(ArgumentSelection.Chosen(COIN_USE.use), ArgumentSelection.Unfilled),
            )
        val preview =
            store.capture().use { snapshot ->
                DefaultTypeArgumentOperations(
                    store,
                ).preview(resource, pending, snapshot).shouldBeInstanceOf<TypePreviewResult.Ready>().preview
            }

        preview.clearedLocations.contains(linkLocation) shouldBe true
        preview.edit.intents.none { it == EditIntent.SetValue(linkLocation, DataValue.Unfilled) } shouldBe true
        preview.linkRepairs shouldBe
            listOf(
                LinkRepairIntent.Clear(
                    com.typewritermc.authoring.LinkOccurrenceId(SOURCE_ENDPOINT, linkLocation),
                ),
            )
        preview.edit.expectations.any { InputIdentity.Incoming(resource, RELATION) in it.dependencies() } shouldBe true
        store.close()
    }
}

private class RecordingRepository : AuthoringRepository {
    var edit: PreparedEdit? = null

    override suspend fun commit(edit: PreparedEdit): CommitResult {
        this.edit = edit
        return CommitResult.Committed
    }
}

private class RepairCatalogLease(
    override val generation: CatalogGeneration = CatalogGeneration("catalog"),
) : AuthoringCatalogLease {
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, REPAIR_DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers: OwnedProviderRegistry = EmptyProviders
    override val checks: List<OwnedCheckRecipe> = emptyList()
    override val relations: List<RelationContract> = listOf(DUAL_RELATION)
    override val endpointBindings: List<EndpointBindingTemplate> = emptyList()
    override val configuration: List<com.typewritermc.configuration.ConfigurationRecipe> = emptyList()
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, com.typewritermc.authoring.ValuePath>()

    override fun retain(): AuthoringCatalogLease = RepairCatalogLease(generation)

    override fun close() = Unit
}

private fun repairRecord(item: ItemId): AuthoringRecord =
    AuthoringRecord(
        configuration = TypeSelection.Complete(CONTAINER_REWARD),
        fields =
            mapOf(
                "bundles" to
                    DataValue.Named(
                        LIST_BUNDLE_REWARD,
                        DataValue.ListValue(
                            listOf(
                                ListItem(
                                    item,
                                    DataValue.Named(
                                        BUNDLE_REWARD,
                                        DataValue.Record(
                                            mapOf(
                                                "title" to DataValue.StringValue("kept"),
                                                "value" to DataValue.Named(GEM_USE, DataValue.Record(emptyMap())),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                "reward" to DataValue.Named(COIN_USE, DataValue.Record(emptyMap())),
            ),
    )

private fun dualRecord(selection: TypeSelection): AuthoringRecord =
    AuthoringRecord(
        configuration = selection,
        fields =
            mapOf(
                "name" to DataValue.StringValue("kept"),
                "first" to DataValue.Named(COIN_USE, DataValue.Record(emptyMap())),
                "second" to DataValue.Named(GEM_USE, DataValue.Record(emptyMap())),
            ),
    )

private fun location(
    resource: ResourceId,
    field: String,
) = ValueLocation(
    resource,
    ValuePath(
        listOf(
            com.typewritermc.authoring.PathSegment
                .Field(field),
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
private val RELATION = RelationId("dual:relation")
private val DUAL_RELATION =
    RelationContract(
        RELATION,
        EndpointDefinition(
            SOURCE_ENDPOINT,
            EndpointSlot.First,
            DUAL.namedTemplate(listOf(DUAL_FIRST_PARAMETER.template, DUAL_SECOND_PARAMETER.template)),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            TARGET_ENDPOINT,
            EndpointSlot.Second,
            REWARD.namedTemplate(),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
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
