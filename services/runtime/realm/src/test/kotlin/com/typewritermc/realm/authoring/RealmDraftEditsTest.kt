package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftView
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.EditPreparationId
import com.typewritermc.authoring.GeneratedEditApi
import com.typewritermc.authoring.InitializationDescriptor
import com.typewritermc.authoring.InitializationDiagnostic
import com.typewritermc.authoring.InitializationMode
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.exactEditablePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.configuration.CapturedDefault
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.checking.dependencies
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.repository.AuthoringRepository
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
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.MapRow
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

class RealmDraftEditsTest {
    suspend fun cascadeDeleteCapturesEveryRemovedResourceRoot() {
        val node = definition("cascade_node")
        val linkType = definition("cascade_link")
        val endpoint = EndpointId("cascade:first")
        val opposite = EndpointId("cascade:second")
        val definitions =
            listOf(
                TypeDefinition(
                    node,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(node, "child"), TypeTemplate.Named(linkType))),
                        ),
                ),
                TypeDefinition(
                    linkType,
                    representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Named(node)),
                ),
            )
        val relation =
            RelationContract(
                RelationId("cascade"),
                EndpointDefinition(
                    endpoint,
                    EndpointSlot.First,
                    TypeTemplate.Named(node),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CASCADE,
                ),
                EndpointDefinition(
                    opposite,
                    EndpointSlot.Second,
                    TypeTemplate.Named(node),
                    EndpointCardinality.One,
                    RelationDeletePolicy.CLEAR,
                ),
            )
        val bindings =
            listOf(
                EndpointBindingTemplate(
                    endpoint,
                    TypeTemplate.Named(node),
                    linkType,
                    RelativeFieldPattern(listOf(FieldPatternSegment.Field("child"))),
                    TypeTemplate.Named(node),
                    false,
                ),
            )
        val catalog =
            DraftCatalogLease(
                definitions = definitions,
                resourceRoot = node,
                relationDefinitions = listOf(relation),
                bindingDefinitions = bindings,
            )
        val parent = ResourceId("cascade_parent")
        val child = ResourceId("cascade_child")
        val resources =
            mapOf(
                parent to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(node)),
                        mapOf(
                            "child" to
                                DataValue.Named(
                                    TypeUse.Named(linkType),
                                    DataValue.Link(endpoint, LinkTarget(child, null)),
                                ),
                        ),
                    ),
                child to
                    AuthoringRecord(
                        TypeSelection.Complete(TypeUse.Named(node)),
                        mapOf("child" to DataValue.Unfilled),
                    ),
            )
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(resources),
            )
        val edits = RealmDraftEdits(store, RecordingDraftRepository())

        val result =
            with(edits) {
                draftView(parent, store).prepareEdit(EditPreparationId("cascade_delete")) {
                    delete(parent)
                }
            }

        val observations =
            assertIs<PreparedEditResult.Prepared>(result).edit.expectations.flatMapTo(hashSetOf()) { it.dependencies() }
        assertTrue(InputIdentity.Existence(child) in observations)
        assertTrue(InputIdentity.Form(ValueLocation(child, ValuePath())) in observations)
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathRecordsBindingFormAndWrites() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val record = draftRecord()
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository(), capturedParentMaterializer())
        val root = ValueLocation(resource, ValuePath())
        val value = childValuePath()

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, ROOT_USE)),
                        ).value
                    set(binding.exactEditablePath(value, TEXT_USE), "edited")
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(
            DataValue.StringValue("edited"),
            assertIs<EditIntent.SetValue>(prepared.intents.last()).value,
        )
        assertTrue(prepared.expectations.any { InputIdentity.Form(root) in it.dependencies() })
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathClearRecordsBindingFormAndWritesUnfilled() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val store = draftStore(catalog, resource, draftRecord())
        val edits = RealmDraftEdits(store, RecordingDraftRepository(), capturedParentMaterializer())
        val root = ValueLocation(resource, ValuePath())

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, ROOT_USE)),
                        ).value
                    clear(binding.exactEditablePath<String>(childValuePath(), TEXT_USE))
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(
            DataValue.Unfilled,
            assertIs<EditIntent.SetValue>(prepared.intents.last()).value,
        )
        assertTrue(prepared.expectations.any { InputIdentity.Form(root) in it.dependencies() })
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathRejectsAnotherReadContext() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val store = draftStore(catalog, resource, draftRecord())
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val root = ValueLocation(resource, ValuePath())

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, ROOT_USE)),
                        ).value
                    val foreign = binding.copy(readContext = ReadContext(catalog.generation))
                    set(foreign.exactEditablePath(childValuePath(), TEXT_USE), "edited")
                }
            }

        val rejected = assertIs<PreparedEditResult.Rejected>(result)
        assertTrue(rejected.problems.any { it.code == "edit_context_mismatch" })
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathRejectsAStagedTypeChange() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val record =
            draftRecord().copy(
                fields =
                    draftRecord().fields +
                        (
                            "child" to
                                DataValue.Named(
                                    CHILD_USE,
                                    DataValue.Record(
                                        mapOf(
                                            "value" to DataValue.StringValue("before"),
                                            "repetitions" to DataValue.Unfilled,
                                        ),
                                    ),
                                )
                        ),
            )
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val root = ValueLocation(resource, ValuePath())

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, ROOT_USE)),
                        ).value
                    val path = binding.exactEditablePath<String>(childValuePath(), TEXT_USE)
                    retag(location(resource, "child"), ROOT_USE)
                    set(path, "edited")
                }
            }

        val rejected = assertIs<PreparedEditResult.Rejected>(result)
        assertTrue(rejected.problems.any { it.code == "write_type_mismatch" })
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathWritesAnIndependentFieldOfAPendingGenericResource() {
        val generic = definition("generic")
        val parameter = ParameterKey(generic, 0)
        val genericUse = TypeUse.Named(generic, listOf(TEXT_USE))
        val definition =
            TypeDefinition(
                generic,
                parameters = listOf(TypeParameter(parameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(generic, "name"), TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(FieldOwner(generic, "value"), TypeTemplate.Parameter(parameter)),
                        ),
                    ),
            )
        val catalog = DraftCatalogLease(definitions = listOf(definition), resourceRoot = generic)
        val resource = ResourceId("pending")
        val record =
            AuthoringRecord(
                TypeSelection.Pending(generic, listOf(ArgumentSelection.Unfilled)),
                mapOf("name" to DataValue.StringValue("before"), "value" to DataValue.Unfilled),
            )
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val root = ValueLocation(resource, ValuePath())
        val name =
            ValuePath(
                listOf(
                    com.typewritermc.authoring.PathSegment
                        .Field("name"),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, genericUse)),
                        ).value
                    set(binding.exactEditablePath(name, TEXT_USE), "after")
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(
            DataValue.StringValue("after"),
            assertIs<EditIntent.SetValue>(prepared.intents.single()).value,
        )
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathMaterializesAnIndependentNestedFieldOfAPendingGenericResource() {
        val generic = definition("pending_nested")
        val style = definition("pending_style")
        val parameter = ParameterKey(generic, 0)
        val genericUse = TypeUse.Named(generic, listOf(TEXT_USE))
        val integer = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
        val definitions =
            listOf(
                TypeDefinition(
                    generic,
                    parameters = listOf(TypeParameter(parameter, "T")),
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(FieldOwner(generic, "style"), TypeTemplate.Named(style)),
                                FieldDeclaration(FieldOwner(generic, "value"), TypeTemplate.Parameter(parameter)),
                            ),
                        ),
                ),
                TypeDefinition(
                    style,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(style, "repetitions"), TypeTemplate.Scalar(integer.kind))),
                        ),
                ),
            )
        val catalog = DraftCatalogLease(definitions = definitions, resourceRoot = generic)
        val resource = ResourceId("pending_nested")
        val record =
            AuthoringRecord(
                TypeSelection.Pending(generic, listOf(ArgumentSelection.Unfilled)),
                mapOf("style" to DataValue.Unfilled, "value" to DataValue.Unfilled),
            )
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val root = ValueLocation(resource, ValuePath())
        val repetitions =
            ValuePath(
                listOf(
                    com.typewritermc.authoring.PathSegment
                        .Field("style"),
                    com.typewritermc.authoring.PathSegment
                        .Field("repetitions"),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, genericUse)),
                        ).value
                    set(binding.exactEditablePath(repetitions, integer), 2)
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(2, prepared.intents.size)
        assertEquals(
            DataValue.Integer(java.math.BigInteger.valueOf(2)),
            assertIs<EditIntent.SetValue>(prepared.intents.last()).value,
        )
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathTraversesMultipleMissingConcreteParents() {
        val deepRoot = definition("deep_root")
        val middle = definition("middle")
        val leaf = definition("leaf")
        val deepRootUse = TypeUse.Named(deepRoot)
        val definitions =
            listOf(
                TypeDefinition(
                    deepRoot,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(deepRoot, "middle"), TypeTemplate.Named(middle))),
                        ),
                ),
                TypeDefinition(
                    middle,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(middle, "leaf"), TypeTemplate.Named(leaf))),
                        ),
                ),
                TypeDefinition(
                    leaf,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(leaf, "value"), TypeTemplate.Scalar(ScalarKind.Text))),
                        ),
                ),
            )
        val catalog = DraftCatalogLease(definitions = definitions, resourceRoot = deepRoot)
        val resource = ResourceId("deep")
        val record = AuthoringRecord(TypeSelection.Complete(deepRootUse), mapOf("middle" to DataValue.Unfilled))
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val root = ValueLocation(resource, ValuePath())
        val value =
            ValuePath(
                listOf(
                    com.typewritermc.authoring.PathSegment
                        .Field("middle"),
                    com.typewritermc.authoring.PathSegment
                        .Field("leaf"),
                    com.typewritermc.authoring.PathSegment
                        .Field("value"),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, deepRootUse)),
                        ).value
                    set(binding.exactEditablePath(value, TEXT_USE), "written")
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(
            DataValue.StringValue("written"),
            assertIs<EditIntent.SetValue>(prepared.intents.last()).value,
        )
        assertEquals(2, prepared.intents.size)
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun exactEditablePathsResolveMapRowKeysAndValues() {
        val mapRoot = definition("map_root")
        val map = definition("map")
        val keyParameter = ParameterKey(map, 0)
        val valueParameter = ParameterKey(map, 1)
        val integer = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
        val mapUse = TypeUse.Named(map, listOf(TEXT_USE, integer))
        val mapRootUse = TypeUse.Named(mapRoot)
        val definitions =
            listOf(
                TypeDefinition(
                    mapRoot,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(
                                    FieldOwner(mapRoot, "entries"),
                                    TypeTemplate.Named(
                                        map,
                                        listOf(
                                            TypeTemplate.Scalar(ScalarKind.Text),
                                            TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                ),
                TypeDefinition(
                    map,
                    parameters = listOf(TypeParameter(keyParameter, "K"), TypeParameter(valueParameter, "V")),
                    representation =
                        RepresentationTemplate.Mapping(
                            TypeTemplate.Parameter(keyParameter),
                            TypeTemplate.Parameter(valueParameter),
                        ),
                ),
            )
        val catalog = DraftCatalogLease(definitions = definitions, resourceRoot = mapRoot)
        val resource = ResourceId("map")
        val row = ItemId("row")
        val record =
            AuthoringRecord(
                TypeSelection.Complete(mapRootUse),
                mapOf(
                    "entries" to
                        DataValue.Named(
                            mapUse,
                            DataValue.MapValue(
                                listOf(MapRow(row, DataValue.StringValue("before"), DataValue.Integer(java.math.BigInteger.ONE))),
                            ),
                        ),
                ),
            )
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val root = ValueLocation(resource, ValuePath())
        val rowPath =
            listOf(
                com.typewritermc.authoring.PathSegment
                    .Field("entries"),
                com.typewritermc.authoring.PathSegment
                    .Item(row),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, mapRootUse)),
                        ).value
                    set(
                        binding.exactEditablePath(ValuePath(rowPath + com.typewritermc.authoring.PathSegment.MapKey), TEXT_USE),
                        "after",
                    )
                    set(
                        binding.exactEditablePath(ValuePath(rowPath + com.typewritermc.authoring.PathSegment.MapValue), integer),
                        2,
                    )
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(2, prepared.intents.size)
        assertEquals(DataValue.StringValue("after"), assertIs<EditIntent.SetValue>(prepared.intents[0]).value)
        assertEquals(
            DataValue.Integer(java.math.BigInteger.valueOf(2)),
            assertIs<EditIntent.SetValue>(prepared.intents[1]).value,
        )
        store.close()
    }

    suspend fun materializesParentBeforeChildAndReadsTheOrderedStagedValue() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val record = draftRecord()
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to record)),
            )
        val edits =
            RealmDraftEdits(
                store,
                RecordingDraftRepository(),
                ParentMaterializer { _, _, _, expected, _ ->
                    ParentMaterialization.Ready(
                        DataValue.Named(
                            expected,
                            DataValue.Record(
                                mapOf(
                                    "value" to DataValue.StringValue("captured"),
                                    "repetitions" to DataValue.Unfilled,
                                ),
                            ),
                        ),
                    )
                },
            )
        val child = location(resource, "child")
        val value =
            ValueLocation(
                resource,
                ValuePath(
                    child.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                ),
            )
        val view = draftView(resource, store)

        val result =
            with(edits) {
                view.prepareEdit(EditPreparationId("test")) {
                    assertIs<com.typewritermc.authoring.CheckedWriteResult.Applied>(
                        checkedSet(value, DataValue.StringValue("edited")),
                    )
                    assertEquals(
                        Availability.Available("edited"),
                        read(boundPath<String>(value, TypeUse.Scalar(ScalarKind.Text))),
                    )
                }
            }
        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit

        assertEquals(
            listOf(
                EditIntent.SetValue(
                    child,
                    DataValue.Named(
                        CHILD_USE,
                        DataValue.Record(
                            mapOf(
                                "value" to DataValue.StringValue("captured"),
                                "repetitions" to DataValue.Unfilled,
                            ),
                        ),
                    ),
                ),
                EditIntent.SetValue(value, DataValue.StringValue("edited")),
            ),
            prepared.intents,
        )
        assertTrue(
            prepared.expectations.any {
                com.typewritermc.authoring.EditExpectation
                    .Value(value, null) == it
            },
        )
        store.close()
    }

    suspend fun missingCollectionItemRequiresExplicitInsertion() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val record = draftRecord()
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to record)),
            )
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val value =
            ValueLocation(
                resource,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("items"),
                        com.typewritermc.authoring.PathSegment
                            .Item(ItemId("missing")),
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                    ),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val rejected = assertIs<CheckedWriteResult.Rejected>(checkedSet(value, DataValue.StringValue("edited")))
                    assertTrue(rejected.problems.any { it.code == "item_missing" })
                    assertIs<CheckedWriteResult.Applied>(
                        checkedSet(childValueLocation(resource), DataValue.StringValue("valid")),
                    )
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(2, prepared.intents.size)
        assertEquals(DataValue.StringValue("valid"), assertIs<EditIntent.SetValue>(prepared.intents.last()).value)
        store.close()
    }

    suspend fun checkedSetRollsBackPartialParentMaterializationAndNeedsInput() {
        val deepRoot = definition("rollback_root")
        val middle = definition("rollback_middle")
        val leaf = definition("rollback_leaf")
        val definitions =
            listOf(
                TypeDefinition(
                    deepRoot,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(FieldOwner(deepRoot, "middle"), TypeTemplate.Named(middle)),
                                FieldDeclaration(FieldOwner(deepRoot, "name"), TypeTemplate.Scalar(ScalarKind.Text)),
                            ),
                        ),
                ),
                TypeDefinition(
                    middle,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(middle, "leaf"), TypeTemplate.Named(leaf))),
                        ),
                ),
                TypeDefinition(
                    leaf,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(leaf, "value"), TypeTemplate.Scalar(ScalarKind.Text))),
                        ),
                ),
            )
        val catalog = DraftCatalogLease(definitions = definitions, resourceRoot = deepRoot)
        val resource = ResourceId("rollback")
        val record = AuthoringRecord(TypeSelection.Complete(TypeUse.Named(deepRoot)), mapOf("middle" to DataValue.Unfilled))
        val store = draftStore(catalog, resource, record)
        val edits =
            RealmDraftEdits(
                store,
                RecordingDraftRepository(),
                ParentMaterializer { _, _, _, expected, at ->
                    if (expected.definition == middle) {
                        ParentMaterialization.Ready(
                            DataValue.Named(expected, DataValue.Record(mapOf("leaf" to DataValue.Unfilled))),
                        )
                    } else {
                        ParentMaterialization.NeedsInput(at)
                    }
                },
            )
        val nested =
            ValueLocation(
                resource,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("middle"),
                        com.typewritermc.authoring.PathSegment
                            .Field("leaf"),
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                    ),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    val rejected = assertIs<CheckedWriteResult.Rejected>(checkedSet(nested, DataValue.StringValue("rejected")))
                    assertTrue(rejected.problems.any { it.code == "parent_needs_input" })
                    assertIs<CheckedWriteResult.Applied>(
                        checkedSet(location(resource, "name"), DataValue.StringValue("valid")),
                    )
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        assertEquals(listOf(EditIntent.SetValue(location(resource, "name"), DataValue.StringValue("valid"))), prepared.intents)
        store.close()
    }

    suspend fun uncapturedConstructorDefaultRemainsUnfilledDuringParentMaterialization() {
        val catalog = DraftCatalogLease()
        val resource = ResourceId("draft")
        val record = draftRecord()
        val store =
            InMemoryAuthoringViewStore(
                catalog,
                AuthoringSeed(mapOf(resource to record)),
            )
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val child = location(resource, "child")
        val value =
            ValueLocation(
                resource,
                ValuePath(
                    child.path.segments +
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    checkedSet(value, DataValue.StringValue("edited"))
                }
            }
        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        val parent = assertIs<EditIntent.SetValue>(prepared.intents.first()).value
        val fields = assertIs<DataValue.Record>(assertIs<DataValue.Named>(parent).payload).fields

        assertEquals(DataValue.Unfilled, fields.getValue("repetitions"))
        assertEquals(DataValue.StringValue("edited"), assertIs<EditIntent.SetValue>(prepared.intents.last()).value)
        store.close()
    }

    suspend fun nestedCapturedDefaultsSurviveParentMaterialization() {
        val outerRoot = definition("default_root")
        val outer = definition("default_outer")
        val inner = definition("default_inner")
        val definitions =
            listOf(
                TypeDefinition(
                    outerRoot,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(outerRoot, "outer"), TypeTemplate.Named(outer))),
                        ),
                ),
                TypeDefinition(
                    outer,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(outer, "inner"), TypeTemplate.Named(inner))),
                        ),
                ),
                TypeDefinition(
                    inner,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(
                                    FieldOwner(inner, "n"),
                                    TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                    hasConstructorDefault = true,
                                ),
                                FieldDeclaration(FieldOwner(inner, "value"), TypeTemplate.Scalar(ScalarKind.Text)),
                            ),
                        ),
                ),
            )
        val initialization =
            listOf(
                InitializationDescriptor(
                    inner,
                    InitializationMode.Startup,
                    listOf(CapturedDefault(FieldOwner(inner, "n"), DataValue.Integer(java.math.BigInteger.valueOf(3)))),
                    emptyList(),
                ),
            )
        val catalog =
            DraftCatalogLease(
                definitions = definitions,
                resourceRoot = outerRoot,
                initializationDescriptors = initialization,
            )
        val resource = ResourceId("defaults")
        val record = AuthoringRecord(TypeSelection.Complete(TypeUse.Named(outerRoot)), mapOf("outer" to DataValue.Unfilled))
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val value =
            ValueLocation(
                resource,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("outer"),
                        com.typewritermc.authoring.PathSegment
                            .Field("inner"),
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                    ),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    assertIs<CheckedWriteResult.Applied>(checkedSet(value, DataValue.StringValue("edited")))
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        val outerValue = assertIs<DataValue.Named>(assertIs<EditIntent.SetValue>(prepared.intents.first()).value)
        val outerFields = assertIs<DataValue.Record>(outerValue.payload).fields
        val innerValue = assertIs<DataValue.Named>(outerFields.getValue("inner"))
        val innerFields = assertIs<DataValue.Record>(innerValue.payload).fields
        assertEquals(DataValue.Integer(java.math.BigInteger.valueOf(3)), innerFields.getValue("n"))
        assertEquals(DataValue.StringValue("edited"), assertIs<EditIntent.SetValue>(prepared.intents.last()).value)
        store.close()
    }

    suspend fun parentMaterializationUsesCanonicalAuthoredScalarDefaults() {
        val scalarRoot = definition("scalar_root")
        val scalarChild = definition("scalar_child")
        val definitions =
            listOf(
                TypeDefinition(
                    scalarRoot,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(FieldDeclaration(FieldOwner(scalarRoot, "child"), TypeTemplate.Named(scalarChild))),
                        ),
                ),
                TypeDefinition(
                    scalarChild,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(FieldOwner(scalarChild, "timestamp"), TypeTemplate.Scalar(ScalarKind.Timestamp)),
                                FieldDeclaration(FieldOwner(scalarChild, "bytes"), TypeTemplate.Scalar(ScalarKind.Bytes)),
                                FieldDeclaration(FieldOwner(scalarChild, "value"), TypeTemplate.Scalar(ScalarKind.Text)),
                            ),
                        ),
                ),
            )
        val catalog = DraftCatalogLease(definitions = definitions, resourceRoot = scalarRoot)
        val resource = ResourceId("scalar_defaults")
        val record = AuthoringRecord(TypeSelection.Complete(TypeUse.Named(scalarRoot)), mapOf("child" to DataValue.Unfilled))
        val store = draftStore(catalog, resource, record)
        val edits = RealmDraftEdits(store, RecordingDraftRepository())
        val value =
            ValueLocation(
                resource,
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("child"),
                        com.typewritermc.authoring.PathSegment
                            .Field("value"),
                    ),
                ),
            )

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("test")) {
                    assertIs<CheckedWriteResult.Applied>(checkedSet(value, DataValue.StringValue("edited")))
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result).edit
        val child = assertIs<DataValue.Named>(assertIs<EditIntent.SetValue>(prepared.intents.first()).value)
        val fields = assertIs<DataValue.Record>(child.payload).fields
        assertEquals(DataValue.Unfilled, fields.getValue("timestamp"))
        assertEquals(DataValue.Bytes(emptyList()), fields.getValue("bytes"))
        store.close()
    }

    suspend fun dynamicParentMaterializationIsOrderedAndReadable() {
        val initialization =
            listOf(
                InitializationDescriptor(ROOT, InitializationMode.Creation, emptyList(), emptyList()),
                InitializationDescriptor(CHILD, InitializationMode.Creation, emptyList(), emptyList()),
            )
        val catalog = DraftCatalogLease(initializationDescriptors = initialization)
        val resource = ResourceId("dynamic")
        val record = draftRecord()
        val store = draftStore(catalog, resource, record)
        val evaluated = mutableListOf<InitializationRequest>()
        val creation =
            PreparationCoordinator(
                catalog = catalog::retain,
                evaluator =
                    PreparationEvaluator { request, _ ->
                        evaluated += request
                        val target = request.target as PreparationTarget.Record
                        val supplied = (request.supplied as DataValue.Record).fields
                        val selection = assertIs<TypeSelection.Complete>(target.selection)
                        when (selection.use.definition) {
                            ROOT -> {
                                assertTrue(supplied.containsKey("items"))
                                PreparedValue(
                                    PreparedContent.Record(
                                        AuthoringRecord(
                                            target.selection,
                                            supplied +
                                                (
                                                    "child" to
                                                        DataValue.Named(
                                                            CHILD_USE,
                                                            DataValue.Record(
                                                                mapOf(
                                                                    "value" to DataValue.StringValue("field_default"),
                                                                    "repetitions" to DataValue.Unfilled,
                                                                ),
                                                            ),
                                                        )
                                                ),
                                        ),
                                    ),
                                    listOf(
                                        InitializationDiagnostic(
                                            FieldOwner(CHILD, "value"),
                                            "native_default_capture_failed",
                                            "The default capture failed.",
                                            childValuePath(),
                                        ),
                                    ),
                                )
                            }

                            else -> {
                                error("The containing default must be prepared first")
                            }
                        }
                    },
            )
        val edits = RealmDraftEdits(store, RecordingDraftRepository(), creation = creation)
        val child = location(resource, "child")
        val value = childValueLocation(resource)
        val view = draftView(resource, store)

        suspend fun prepare(): PreparedEditResult.Prepared =
            assertIs<PreparedEditResult.Prepared>(
                with(edits) {
                    view.prepareEdit(EditPreparationId("dynamic_edit")) {
                        assertIs<CheckedWriteResult.Applied>(
                            checkedSet(value, DataValue.StringValue("first")),
                        )
                        assertEquals(
                            Availability.Available("first"),
                            read(boundPath<String>(value, TEXT_USE)),
                        )
                        assertIs<CheckedWriteResult.Applied>(checkedSet(child, DataValue.Unfilled))
                        assertIs<CheckedWriteResult.Applied>(
                            checkedSet(value, DataValue.StringValue("second")),
                        )
                        assertEquals(
                            Availability.Available("second"),
                            read(boundPath<String>(value, TEXT_USE)),
                        )
                    }
                },
            )

        val first = prepare()
        val retried = prepare()

        assertEquals(first.edit.intents, retried.edit.intents)
        assertEquals(first.initializationFindings, retried.initializationFindings)
        assertEquals(2, first.initializationFindings.size)
        assertTrue(
            first.initializationFindings.all {
                it.location == childValueLocation(resource) && it.diagnostic.code == "native_default_capture_failed"
            },
        )
        assertEquals(4, evaluated.size)
        assertTrue(evaluated[0].id.value.endsWith(":containing:0"))
        assertTrue(evaluated[1].id.value.endsWith(":containing:1"))
        assertTrue(first.edit.expectations.any { InputIdentity.Value(ValueLocation(resource, ValuePath())) in it.dependencies() })
        val firstParent = assertIs<DataValue.Named>(assertIs<EditIntent.SetValue>(first.edit.intents[0]).value)
        val firstParentFields = assertIs<DataValue.Record>(firstParent.payload).fields
        assertEquals(DataValue.StringValue("field_default"), firstParentFields.getValue("value"))
        store.close()
    }

    suspend fun dynamicParentFindingsRemainVisibleAtTheirPreciseField() {
        val initialization = listOf(InitializationDescriptor(ROOT, InitializationMode.Creation, emptyList(), emptyList()))
        val catalog = DraftCatalogLease(initializationDescriptors = initialization)
        val resource = ResourceId("dynamic_finding")
        val store = draftStore(catalog, resource, draftRecord())
        val creation =
            object : InitializationRuntime {
                override suspend fun prepare(request: InitializationRequest): PreparedValue =
                    PreparedValue(
                        PreparedContent.Record(
                            AuthoringRecord(
                                (request.target as PreparationTarget.Record).selection,
                                (request.supplied as DataValue.Record).fields +
                                    (
                                        "child" to
                                            DataValue.Named(
                                                CHILD_USE,
                                                DataValue.Record(
                                                    mapOf(
                                                        "value" to DataValue.StringValue("captured"),
                                                        "repetitions" to DataValue.Unfilled,
                                                    ),
                                                ),
                                            )
                                    ),
                            ),
                        ),
                        listOf(
                            InitializationDiagnostic(
                                FieldOwner(CHILD, "value"),
                                "default_dependency_unavailable",
                                "The field default dependency is unavailable.",
                                childValuePath(),
                            ),
                        ),
                    )
            }
        val edits = RealmDraftEdits(store, RecordingDraftRepository(), creation = creation)

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("dynamic_finding")) {
                    checkedSet(childValueLocation(resource), DataValue.StringValue("edited"))
                }
            }

        val prepared = assertIs<PreparedEditResult.Prepared>(result)
        assertEquals(
            childValueLocation(resource),
            prepared.initializationFindings.single { it.diagnostic.code == "default_dependency_unavailable" }.location,
        )
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun uncapturedDynamicParentDefaultReturnsNeedsInputWithLocatedFinding() {
        val initialization = listOf(InitializationDescriptor(ROOT, InitializationMode.Creation, emptyList(), emptyList()))
        val catalog = DraftCatalogLease(initializationDescriptors = initialization)
        val resource = ResourceId("dynamic_unfilled")
        val store = draftStore(catalog, resource, draftRecord())
        val diagnostic =
            InitializationDiagnostic(
                FieldOwner(ROOT, "child"),
                "native_default_capture_failed",
                "The child default could not be captured.",
                ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("child"),
                    ),
                ),
            )
        val creation =
            object : InitializationRuntime {
                override suspend fun prepare(request: InitializationRequest): PreparedValue =
                    PreparedValue(
                        PreparedContent.Record(
                            AuthoringRecord(
                                (request.target as PreparationTarget.Record).selection,
                                (request.supplied as DataValue.Record).fields + ("child" to DataValue.Unfilled),
                            ),
                        ),
                        listOf(diagnostic),
                    )
            }
        val edits = RealmDraftEdits(store, RecordingDraftRepository(), creation = creation)
        val root = ValueLocation(resource, ValuePath())
        val child = location(resource, "child")

        val result =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId("dynamic_unfilled")) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, ROOT_USE)),
                        ).value
                    set(binding.exactEditablePath(childValuePath(), TEXT_USE), "edited")
                }
            }

        val needsInput = assertIs<PreparedEditResult.NeedsInput>(result)
        assertEquals(listOf(child), needsInput.locations)
        assertEquals(child, needsInput.initializationFindings.single().location)
        assertEquals(diagnostic, needsInput.initializationFindings.single().diagnostic)
        store.close()
    }

    @OptIn(GeneratedEditApi::class)
    suspend fun dynamicParentRequiresExactConfigurationAndValidStructure() {
        val initialization = listOf(InitializationDescriptor(ROOT, InitializationMode.Creation, emptyList(), emptyList()))
        val catalog = DraftCatalogLease(initializationDescriptors = initialization)
        val resource = ResourceId("dynamic_admission")
        val store = draftStore(catalog, resource, draftRecord())
        val creation =
            object : InitializationRuntime {
                override suspend fun prepare(request: InitializationRequest): PreparedValue =
                    if (request.id.value.startsWith("wrong_configuration")) {
                        PreparedValue(
                            PreparedContent.Record(AuthoringRecord(TypeSelection.Complete(CHILD_USE), emptyMap())),
                            emptyList(),
                        )
                    } else {
                        PreparedValue(
                            PreparedContent.Record(
                                AuthoringRecord(
                                    (request.target as PreparationTarget.Record).selection,
                                    (request.supplied as DataValue.Record).fields,
                                ),
                            ),
                            emptyList(),
                        )
                    }
            }
        val edits = RealmDraftEdits(store, RecordingDraftRepository(), creation = creation)
        val root = ValueLocation(resource, ValuePath())

        suspend fun prepare(id: String): PreparedEditResult =
            with(edits) {
                draftView(resource, store).prepareEdit(EditPreparationId(id)) {
                    val binding =
                        assertIs<Availability.Available<DraftBinding>>(
                            binding(boundPath<Any>(root, ROOT_USE)),
                        ).value
                    set(binding.exactEditablePath(childValuePath(), TEXT_USE), "edited")
                }
            }

        val wrongConfiguration = assertIs<PreparedEditResult.Rejected>(prepare("wrong_configuration"))
        assertEquals(
            listOf(ValueProblem(root, "initialization_configuration_mismatch")),
            wrongConfiguration.problems,
        )

        val invalidStructure = assertIs<PreparedEditResult.Rejected>(prepare("invalid_structure"))
        assertTrue(
            invalidStructure.problems.any {
                it.location == location(resource, "child") && it.code == "missing_field"
            },
        )
        store.close()
    }
}

private class RecordingDraftRepository : AuthoringRepository {
    override suspend fun commit(edit: PreparedEdit): CommitResult = CommitResult.Committed
}

private class DraftCatalogLease(
    override val generation: CatalogGeneration = GENERATION,
    private val definitions: List<TypeDefinition> = DRAFT_DEFINITIONS,
    private val resourceRoot: TypeDefinitionId = ROOT,
    private val initializationDescriptors: List<InitializationDescriptor> = defaultInitializationDescriptors,
    private val relationDefinitions: List<RelationContract> = emptyList(),
    private val bindingDefinitions: List<EndpointBindingTemplate> = emptyList(),
) : AuthoringCatalogLease {
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, definitions)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers: OwnedProviderRegistry = EmptyProviders
    override val checks: List<OwnedCheckRecipe> = emptyList()
    override val relations: List<RelationContract> = relationDefinitions
    override val endpointBindings: List<EndpointBindingTemplate> = bindingDefinitions
    override val initialization: List<InitializationDescriptor> = initializationDescriptors
    override val resources: List<AuthoringResourceDefinition> =
        listOf(AuthoringResourceDefinition(ResourceDefinitionId("draft"), resourceRoot))

    override fun retain(): AuthoringCatalogLease =
        DraftCatalogLease(
            generation,
            definitions,
            resourceRoot,
            initializationDescriptors,
            relationDefinitions,
            bindingDefinitions,
        )

    override fun close() = Unit
}

private fun draftView(
    resource: ResourceId,
    store: InMemoryAuthoringViewStore,
): DraftView =
    object : DraftView {
        override val readContext = store.capture().use { it.root.readContext }
        override val catalog = readContext.catalog
        override val location = ValueLocation(resource, ValuePath())
        override val actualType = Availability.Available(ROOT_USE)
    }

private fun draftRecord(): AuthoringRecord =
    AuthoringRecord(
        TypeSelection.Complete(ROOT_USE),
        mapOf(
            "child" to DataValue.Unfilled,
            "items" to DataValue.Named(LIST_USE, DataValue.ListValue(emptyList())),
        ),
    )

private fun draftStore(
    catalog: AuthoringCatalogLease,
    resource: ResourceId,
    record: AuthoringRecord,
): InMemoryAuthoringViewStore =
    InMemoryAuthoringViewStore(
        catalog,
        AuthoringSeed(mapOf(resource to record)),
    )

private fun capturedParentMaterializer(): ParentMaterializer =
    ParentMaterializer { _, _, _, expected, _ ->
        ParentMaterialization.Ready(
            DataValue.Named(
                expected,
                DataValue.Record(
                    mapOf(
                        "value" to DataValue.StringValue("captured"),
                        "repetitions" to DataValue.Unfilled,
                    ),
                ),
            ),
        )
    }

private fun childValuePath(): ValuePath =
    ValuePath(
        listOf(
            com.typewritermc.authoring.PathSegment
                .Field("child"),
            com.typewritermc.authoring.PathSegment
                .Field("value"),
        ),
    )

private fun childValueLocation(resource: ResourceId): ValueLocation = ValueLocation(resource, childValuePath())

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

private fun definition(name: String) = TypeDefinitionId(TypeId.Qualified("draft", name), 1)

private val GENERATION = CatalogGeneration("draft_catalog")
private val ROOT = definition("root")
private val CHILD = definition("child")
private val LIST = definition("list")
private val ROOT_USE = TypeUse.Named(ROOT)
private val CHILD_USE = TypeUse.Named(CHILD)
private val LIST_USE = TypeUse.Named(LIST)
private val TEXT_USE = TypeUse.Scalar(ScalarKind.Text)
private val defaultInitializationDescriptors =
    listOf(
        InitializationDescriptor(
            CHILD,
            InitializationMode.Startup,
            emptyList(),
            listOf(
                InitializationDiagnostic(
                    FieldOwner(CHILD, "repetitions"),
                    "default_capture_failed",
                    "The constructor default could not be captured.",
                ),
            ),
        ),
    )
private val DRAFT_DEFINITIONS =
    listOf(
        TypeDefinition(
            ROOT,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(FieldOwner(ROOT, "child"), TypeTemplate.Named(CHILD)),
                        FieldDeclaration(FieldOwner(ROOT, "items"), TypeTemplate.Named(LIST)),
                    ),
                ),
        ),
        TypeDefinition(
            CHILD,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(FieldOwner(CHILD, "value"), TypeTemplate.Scalar(ScalarKind.Text)),
                        FieldDeclaration(
                            FieldOwner(CHILD, "repetitions"),
                            TypeTemplate.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32)),
                            hasConstructorDefault = true,
                        ),
                    ),
                ),
        ),
        TypeDefinition(
            LIST,
            representation = RepresentationTemplate.Sequence(TypeTemplate.Named(CHILD), CollectionKind.List),
        ),
    )

val RealmDraftEditsTestSuite by testSuite {
    test("cascadeDeleteCapturesEveryRemovedResourceRoot") {
        RealmDraftEditsTest().cascadeDeleteCapturesEveryRemovedResourceRoot()
    }
    test("exactEditablePathRecordsBindingFormAndWrites") {
        RealmDraftEditsTest().exactEditablePathRecordsBindingFormAndWrites()
    }
    test("exactEditablePathClearRecordsBindingFormAndWritesUnfilled") {
        RealmDraftEditsTest().exactEditablePathClearRecordsBindingFormAndWritesUnfilled()
    }
    test("exactEditablePathRejectsAnotherReadContext") {
        RealmDraftEditsTest().exactEditablePathRejectsAnotherReadContext()
    }
    test("exactEditablePathRejectsAStagedTypeChange") {
        RealmDraftEditsTest().exactEditablePathRejectsAStagedTypeChange()
    }
    test("exactEditablePathWritesAnIndependentFieldOfAPendingGenericResource") {
        RealmDraftEditsTest().exactEditablePathWritesAnIndependentFieldOfAPendingGenericResource()
    }
    test("exactEditablePathMaterializesAnIndependentNestedFieldOfAPendingGenericResource") {
        RealmDraftEditsTest().exactEditablePathMaterializesAnIndependentNestedFieldOfAPendingGenericResource()
    }
    test("exactEditablePathTraversesMultipleMissingConcreteParents") {
        RealmDraftEditsTest().exactEditablePathTraversesMultipleMissingConcreteParents()
    }
    test("exactEditablePathsResolveMapRowKeysAndValues") {
        RealmDraftEditsTest().exactEditablePathsResolveMapRowKeysAndValues()
    }
    test("materializesParentBeforeChildAndReadsTheOrderedStagedValue") {
        RealmDraftEditsTest().materializesParentBeforeChildAndReadsTheOrderedStagedValue()
    }
    test("missingCollectionItemRequiresExplicitInsertion") { RealmDraftEditsTest().missingCollectionItemRequiresExplicitInsertion() }
    test("checkedSetRollsBackPartialParentMaterializationAndNeedsInput") {
        RealmDraftEditsTest().checkedSetRollsBackPartialParentMaterializationAndNeedsInput()
    }
    test("uncapturedConstructorDefaultRemainsUnfilledDuringParentMaterialization") {
        RealmDraftEditsTest().uncapturedConstructorDefaultRemainsUnfilledDuringParentMaterialization()
    }
    test("nestedCapturedDefaultsSurviveParentMaterialization") {
        RealmDraftEditsTest().nestedCapturedDefaultsSurviveParentMaterialization()
    }
    test("parentMaterializationUsesCanonicalAuthoredScalarDefaults") {
        RealmDraftEditsTest().parentMaterializationUsesCanonicalAuthoredScalarDefaults()
    }
    test("dynamicParentMaterializationIsOrderedAndReadable") {
        RealmDraftEditsTest().dynamicParentMaterializationIsOrderedAndReadable()
    }
    test("dynamicParentFindingsRemainVisibleAtTheirPreciseField") {
        RealmDraftEditsTest().dynamicParentFindingsRemainVisibleAtTheirPreciseField()
    }
    test("uncapturedDynamicParentDefaultReturnsNeedsInputWithLocatedFinding") {
        RealmDraftEditsTest().uncapturedDynamicParentDefaultReturnsNeedsInputWithLocatedFinding()
    }
    test("dynamicParentRequiresExactConfigurationAndValidStructure") {
        RealmDraftEditsTest().dynamicParentRequiresExactConfigurationAndValidStructure()
    }
}
