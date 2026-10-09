package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationId
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.coroutines.test.runTest

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
            assertIs<TypePreviewResult.InvalidArguments>(
                operations.preview(resource, TypeSelection.Complete(BUNDLE_COIN), snapshot),
            )
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
            assertIs<TypePreviewResult.Rejected>(
                DefaultTypeArgumentOperations(invalidStore)
                    .preview(resource, TypeSelection.Complete(CONTAINER_COIN), snapshot),
            )
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
                assertIs<TypePreviewResult.Ready>(
                    operations.preview(resource, TypeSelection.Complete(CONTAINER_COIN), snapshot),
                ).preview
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
        assertEquals(
            listOf(
                EditIntent.ConfigureResource(resource, TypeSelection.Complete(CONTAINER_COIN)),
                EditIntent.Retag(bundles, LIST_BUNDLE_COIN),
                EditIntent.Retag(bundle, BUNDLE_COIN),
                EditIntent.SetValue(incompatible, DataValue.Unfilled),
            ),
            preview.edit.intents,
        )
        assertEquals(listOf(incompatible), preview.clearedLocations)
        val observed = preview.edit.expectations.flatMapTo(linkedSetOf()) { it.dependencies() }
        assertTrue(InputIdentity.Value(title) in observed)
        assertTrue(InputIdentity.Value(compatible) in observed)
        assertTrue(InputIdentity.Value(incompatible) in observed)
        assertTrue(InputIdentity.Value(bundles) in observed)
        assertTrue(InputIdentity.Value(bundles) in observed)
        assertFalse(preview.edit.intents.any { it == EditIntent.SetValue(compatible, DataValue.Unfilled) })

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
                    assertIs<TypePreviewResult.Ready>(
                        operations.preview(resource, TypeSelection.Complete(CONTAINER_COIN), snapshot),
                    ).preview
                }

            val edit = assertIs<PreparedEditResult.Prepared>(operations.prepare(preview)).edit
            repository.commit(edit)
            assertTrue(edit.expectations.any { InputIdentity.Value(location(resource, "reward")) in it.dependencies() })
            assertEquals(edit, repository.edit)
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
                    listOf(ArgumentSelection.Chosen(COIN_USE), ArgumentSelection.Unfilled),
                )

            val pendingPreview =
                store.capture().use { snapshot ->
                    assertIs<TypePreviewResult.Ready>(operations.preview(resource, pending, snapshot)).preview
                }

            assertEquals(pending, pendingPreview.next)
            assertTrue(pendingPreview.edit.intents.contains(EditIntent.ConfigureResource(resource, pending)))
            assertTrue(pendingPreview.edit.intents.contains(EditIntent.SetValue(location(resource, "second"), DataValue.Unfilled)))
            assertFalse(pendingPreview.edit.intents.contains(EditIntent.SetValue(location(resource, "name"), DataValue.Unfilled)))
            assertFalse(pendingPreview.edit.intents.contains(EditIntent.SetValue(location(resource, "first"), DataValue.Unfilled)))

            val pendingEdit = assertIs<PreparedEditResult.Prepared>(operations.prepare(pendingPreview)).edit
            val pendingPlan =
                assertIs<MutationPlanningResult.Accepted>(
                    AuthoringMutationPlanner(catalog.checked, emptyList()).plan(mapOf(resource to original), pendingEdit),
                ).plan
            val pendingRecord = pendingPlan.resources.getValue(resource)
            assertEquals(pending, pendingRecord.configuration)
            assertEquals(DataValue.StringValue("kept"), pendingRecord.fields.getValue("name"))
            assertEquals(original.fields.getValue("first"), pendingRecord.fields.getValue("first"))
            assertEquals(DataValue.Unfilled, pendingRecord.fields.getValue("second"))

            val pendingStore =
                InMemoryAuthoringViewStore(
                    catalog.retain(),
                    AuthoringSeed(mapOf(resource to pendingRecord)),
                )
            val complete = TypeSelection.Complete(DUAL_COIN_COIN)
            val completePreview =
                pendingStore.capture().use { snapshot ->
                    assertIs<TypePreviewResult.Ready>(operations.preview(resource, complete, snapshot)).preview
                }
            assertEquals(complete, completePreview.next)
            assertTrue(completePreview.edit.intents.contains(EditIntent.ConfigureResource(resource, complete)))
            assertFalse(completePreview.edit.intents.contains(EditIntent.SetValue(location(resource, "first"), DataValue.Unfilled)))

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
                    listOf(ArgumentSelection.Chosen(COIN_USE), ArgumentSelection.Unfilled),
                )
            val preview =
                store.capture().use { snapshot ->
                    assertIs<TypePreviewResult.Ready>(operations.preview(resource, pending, snapshot)).preview
                }

            assertIs<PreparedEditResult.Rejected>(
                operations.prepare(
                    preview.copy(
                        edit =
                            preview.edit.copy(
                                intents = listOf(EditIntent.ConfigureResource(resource, TypeSelection.Complete(DUAL_COIN_COIN))),
                            ),
                    ),
                ),
            )
            assertEquals(null, repository.edit)
            assertIs<PreparedEditResult.Rejected>(
                operations.prepare(
                    preview.copy(edit = preview.edit.copy(expectations = preview.edit.expectations.dropLast(1))),
                ),
            )
            assertEquals(null, repository.edit)

            val prepared = assertIs<PreparedEditResult.Prepared>(operations.prepare(preview)).edit
            assertEquals(null, repository.edit)
            assertIs<CommitResult.Committed>(repository.commit(prepared))
            assertEquals(prepared, repository.edit)
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
                listOf(ArgumentSelection.Chosen(COIN_USE), ArgumentSelection.Unfilled),
            )
        val preview =
            store.capture().use { snapshot ->
                assertIs<TypePreviewResult.Ready>(
                    DefaultTypeArgumentOperations(store).preview(resource, pending, snapshot),
                ).preview
            }

        assertTrue(preview.clearedLocations.contains(linkLocation))
        assertTrue(preview.edit.intents.none { it == EditIntent.SetValue(linkLocation, DataValue.Unfilled) })
        assertEquals(
            listOf(
                LinkRepairIntent.Clear(
                    com.typewritermc.authoring.LinkOccurrenceId(SOURCE_ENDPOINT, linkLocation),
                ),
            ),
            preview.linkRepairs,
        )
        assertTrue(preview.edit.expectations.any { InputIdentity.Incoming(resource, RELATION) in it.dependencies() })
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
    override val resources: List<AuthoringResourceDefinition> =
        listOf(
            AuthoringResourceDefinition(ResourceDefinitionId("container"), CONTAINER),
            AuthoringResourceDefinition(ResourceDefinitionId("dual"), DUAL),
            AuthoringResourceDefinition(ResourceDefinitionId("reward"), REWARD),
        )

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
private val BUNDLE_PARAMETER = ParameterKey(BUNDLE, 0)
private val LIST_PARAMETER = ParameterKey(LIST, 0)
private val CONTAINER_PARAMETER = ParameterKey(CONTAINER, 0)
private val DUAL_FIRST_PARAMETER = ParameterKey(DUAL, 0)
private val DUAL_SECOND_PARAMETER = ParameterKey(DUAL, 1)
private val LINK_PARAMETER = ParameterKey(LINK, 0)
private val REWARD_USE = TypeUse.Named(REWARD)
private val COIN_USE = TypeUse.Named(COIN)
private val GEM_USE = TypeUse.Named(GEM)
private val BUNDLE_REWARD = TypeUse.Named(BUNDLE, listOf(REWARD_USE))
private val BUNDLE_COIN = TypeUse.Named(BUNDLE, listOf(COIN_USE))
private val LIST_BUNDLE_REWARD = TypeUse.Named(LIST, listOf(BUNDLE_REWARD))
private val LIST_BUNDLE_COIN = TypeUse.Named(LIST, listOf(BUNDLE_COIN))
private val CONTAINER_REWARD = TypeUse.Named(CONTAINER, listOf(REWARD_USE))
private val CONTAINER_COIN = TypeUse.Named(CONTAINER, listOf(COIN_USE))
private val DUAL_COIN_GEM = TypeUse.Named(DUAL, listOf(COIN_USE, GEM_USE))
private val DUAL_COIN_COIN = TypeUse.Named(DUAL, listOf(COIN_USE, COIN_USE))
private val LINK_GEM = TypeUse.Named(LINK, listOf(GEM_USE))
private val SOURCE_ENDPOINT = EndpointId("dual:source")
private val TARGET_ENDPOINT = EndpointId("dual:target")
private val RELATION = RelationId("dual:relation")
private val DUAL_RELATION =
    RelationContract(
        RELATION,
        EndpointDefinition(
            SOURCE_ENDPOINT,
            EndpointSlot.First,
            TypeTemplate.Named(
                DUAL,
                listOf(TypeTemplate.Parameter(DUAL_FIRST_PARAMETER), TypeTemplate.Parameter(DUAL_SECOND_PARAMETER)),
            ),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            TARGET_ENDPOINT,
            EndpointSlot.Second,
            TypeTemplate.Named(REWARD),
            EndpointCardinality.One,
            RelationDeletePolicy.CLEAR,
        ),
    )

private val REPAIR_DEFINITIONS =
    listOf(
        TypeDefinition(REWARD, emptyList(), RepresentationTemplate.Record(emptyList(), abstract = true)),
        TypeDefinition(COIN, emptyList(), RepresentationTemplate.Record(emptyList()), parents = listOf(TypeTemplate.Named(REWARD))),
        TypeDefinition(GEM, emptyList(), RepresentationTemplate.Record(emptyList()), parents = listOf(TypeTemplate.Named(REWARD))),
        TypeDefinition(
            BUNDLE,
            listOf(TypeParameter(BUNDLE_PARAMETER, "value")),
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(FieldOwner(BUNDLE, "title"), TypeTemplate.Scalar(ScalarKind.Text)),
                    FieldDeclaration(FieldOwner(BUNDLE, "value"), TypeTemplate.Parameter(BUNDLE_PARAMETER)),
                ),
            ),
        ),
        TypeDefinition(
            LIST,
            listOf(TypeParameter(LIST_PARAMETER, "item")),
            RepresentationTemplate.Sequence(TypeTemplate.Parameter(LIST_PARAMETER), CollectionKind.List),
        ),
        TypeDefinition(
            CONTAINER,
            listOf(TypeParameter(CONTAINER_PARAMETER, "reward")),
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(
                        FieldOwner(CONTAINER, "bundles"),
                        TypeTemplate.Named(
                            LIST,
                            listOf(TypeTemplate.Named(BUNDLE, listOf(TypeTemplate.Parameter(CONTAINER_PARAMETER)))),
                        ),
                    ),
                    FieldDeclaration(FieldOwner(CONTAINER, "reward"), TypeTemplate.Parameter(CONTAINER_PARAMETER)),
                ),
            ),
        ),
        TypeDefinition(
            LINK,
            listOf(TypeParameter(LINK_PARAMETER, "target")),
            RepresentationTemplate.Link(SOURCE_ENDPOINT, TypeTemplate.Parameter(LINK_PARAMETER)),
        ),
        TypeDefinition(
            DUAL,
            listOf(
                TypeParameter(DUAL_FIRST_PARAMETER, "first"),
                TypeParameter(DUAL_SECOND_PARAMETER, "second"),
            ),
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(FieldOwner(DUAL, "name"), TypeTemplate.Scalar(ScalarKind.Text)),
                    FieldDeclaration(FieldOwner(DUAL, "first"), TypeTemplate.Parameter(DUAL_FIRST_PARAMETER)),
                    FieldDeclaration(FieldOwner(DUAL, "second"), TypeTemplate.Parameter(DUAL_SECOND_PARAMETER)),
                    FieldDeclaration(
                        FieldOwner(DUAL, "target"),
                        TypeTemplate.Named(LINK, listOf(TypeTemplate.Parameter(DUAL_SECOND_PARAMETER))),
                    ),
                ),
            ),
        ),
    )

private fun definition(name: String) = TypeDefinitionId(TypeId.Qualified("repair", name), 1)

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
