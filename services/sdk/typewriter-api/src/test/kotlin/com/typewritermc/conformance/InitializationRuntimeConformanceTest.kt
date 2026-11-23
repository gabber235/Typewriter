package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.validateStructure
import com.typewritermc.testkit.record
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.runBlocking
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValuePath
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine
import skirout.kernel.v1.resource_id.ResourceId as SkirResourceId

val InitializationRuntimeConformanceTest by testSuite {
    val initializedUse = INITIALIZED_ID.namedUse(emptyList())

    val requiredOwner = FieldOwner(definition = INITIALIZED_ID, name = "required")

    /** A record with a required text field and a defaulted integer field whose default the constructor captures. */
    val initializedDefinition =
        TypeDefinition.partial(
            id = INITIALIZED_ID,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = requiredOwner, type = ScalarKind.TEXT.template),
                            FieldDeclaration.partial(
                                owner = DEFAULTED_OWNER,
                                type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                hasConstructorDefault = true,
                            ),
                        ),
                    form = RecordForm.CONCRETE,
                ),
        )

    val abstractId = TypeDefinitionId.qualified("test", "AbstractInput")

    val concreteId = TypeDefinitionId.qualified("test", "ConcreteInput")

    val concreteValueOwner = FieldOwner(definition = concreteId, name = "value")

    val abstractOwnerId = TypeDefinitionId.qualified("test", "AbstractOwner")

    val abstractInputOwner = FieldOwner(definition = abstractOwnerId, name = "input")

    val childId = TypeDefinitionId.qualified("test", "Child")

    val childRequiredOwner = FieldOwner(definition = childId, name = "required")

    val parentId = TypeDefinitionId.qualified("test", "Parent")

    val parentChildOwner = FieldOwner(definition = parentId, name = "child")

    test("complete supplied values pass through without record synthesis") {
        val generation = CatalogGeneration(value = "complete supplied value")
        val catalog = DefaultCheckedCatalog(generation, emptyList())
        val supplied = DataValue.StringValueWrapper("authored")
        val prepared =
            DefaultInitializationRuntime(catalog).prepareNow(
                ValuePreparationRequest(
                    catalog = generation,
                    target = PreparationTarget.ValueWrapper(ScalarKind.TEXT.use),
                    suppliedValue = supplied,
                ),
            )

        prepared.content shouldBe PreparedContent.ValueWrapper(supplied)
        prepared.findings shouldBe emptyList()
    }

    test("supplied record fields are kept and a defaulted field nobody supplied stays unset") {
        val generation = CatalogGeneration(value = "partial supplied record")
        val catalog = DefaultCheckedCatalog(generation, listOf(initializedDefinition))

        val prepared =
            DefaultInitializationRuntime(catalog).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.of(initializedUse),
                    mapOf("required" to DataValue.StringValueWrapper("authored")),
                ),
            )

        prepared.record.fieldMap shouldBe mapOf("required" to DataValue.StringValueWrapper("authored"))
        prepared.findings shouldBe emptyList()
    }

    val pendingId = TypeDefinitionId.qualified("test", "PendingConfiguration")
    val pendingParameter = ParameterKey(owner = pendingId, index = 0)
    val pendingDefaulted = FieldOwner(definition = pendingId, name = "defaulted")
    val pendingGeneration = CatalogGeneration(value = "pending initialization catalog")
    val pendingCatalog =
        DefaultCheckedCatalog(
            pendingGeneration,
            listOf(
                TypeDefinition.partial(
                    id = pendingId,
                    parameters = listOf(TypeParameter.partial(key = pendingParameter, name = "T")),
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = pendingId, name = "independent"),
                                        type = ScalarKind.TEXT.template,
                                    ),
                                    FieldDeclaration.partial(
                                        owner = pendingDefaulted,
                                        type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                        hasConstructorDefault = true,
                                    ),
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = pendingId, name = "dependent"),
                                        type = pendingParameter.template,
                                    ),
                                ),
                            form = RecordForm.CONCRETE,
                        ),
                ),
            ),
        )
    val pendingSelection = TypeSelection.of(pendingId)
    val pendingRuntime = DefaultInitializationRuntime(pendingCatalog)

    test("pending generic creation fills every field it knows without its type argument, leaves defaulted fields unset and the rest unfilled") {
        val prepared = pendingRuntime.prepareNow(recordRequest(pendingGeneration, pendingSelection, emptyMap()))

        prepared.record shouldBe
            AuthoringRecord.of(
                pendingSelection,
                mapOf(
                    "independent" to DataValue.StringValueWrapper(""),
                    "dependent" to DataValue.UNFILLED,
                ),
            )
        prepared.record.validateStructure(SkirResourceId(value = "prepared"), pendingCatalog) shouldBe StructuralResult.VALID
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("incomplete_type_selection")
    }

    test("pending generic creation keeps a supplied field whose type depends on the missing argument and reports it") {
        val prepared =
            pendingRuntime.prepareNow(
                recordRequest(
                    pendingGeneration,
                    pendingSelection,
                    mapOf("dependent" to DataValue.StringValueWrapper("unchecked")),
                ),
            )

        prepared.record.fieldMap shouldBe mapOf("dependent" to DataValue.StringValueWrapper("unchecked"))
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("dependent_field_type_unavailable")
    }

    test("creation keeps a supplied field the type does not declare and reports it as unknown") {
        val prepared =
            pendingRuntime.prepareNow(
                recordRequest(
                    pendingGeneration,
                    pendingSelection,
                    mapOf("unknown" to DataValue.BooleanWrapper(true)),
                ),
            )

        prepared.record.fieldMap shouldBe mapOf("unknown" to DataValue.BooleanWrapper(true))
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("unknown_field")
    }

    test("a preparation request for another catalog generation is unavailable") {
        val prepared =
            DefaultInitializationRuntime(pendingCatalog).prepareNow(recordRequest(CatalogGeneration(value = "other"), pendingSelection, emptyMap()))

        prepared.findings.map { it.code to it.message } shouldBe
            listOf("catalog_generation_mismatch" to "The initialization request uses a different catalog generation.")
    }

    test("record preparation refuses a supplied value that is not a record") {
        val prepared =
            DefaultInitializationRuntime(pendingCatalog).prepareNow(
                recordRequest(
                    pendingGeneration,
                    pendingSelection,
                    emptyMap(),
                ).copy(suppliedValue = DataValue.StringValueWrapper("text")),
            )

        prepared.findings.map { it.code to it.message } shouldBe
            listOf("invalid_supplied_value" to "Record preparation requires a record value.")
    }

    test("record preparation refuses a selection of an undeclared type") {
        val prepared =
            DefaultInitializationRuntime(pendingCatalog).prepareNow(
                recordRequest(
                    pendingGeneration,
                    TypeSelection.of(TypeDefinitionId.qualified("test", "Undeclared").namedUse()),
                    emptyMap(),
                ),
            )

        prepared.findings.map { it.code to it.message } shouldBe listOf("invalid_type_selection" to "unknown_definition")
    }

    test("an ordinary default nested deeper than the supported depth stops with a finding instead of overflowing") {
        val generation = CatalogGeneration(value = "deep defaults")
        val levels = (0..520).map { TypeDefinitionId.qualified("test", "Level$it") }
        val catalog =
            DefaultCheckedCatalog(
                generation,
                levels.mapIndexed { index, id ->
                    val type = levels.getOrNull(index + 1)?.template() ?: ScalarKind.TEXT.template
                    TypeDefinition.partial(
                        id = id,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields = listOf(FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "next"), type = type)),
                                form = RecordForm.CONCRETE,
                            ),
                    )
                },
            )

        val prepared =
            DefaultInitializationRuntime(catalog)
                .prepareNow(recordRequest(generation, TypeSelection.of(levels.first().namedUse()), emptyMap()))

        prepared.findings.map { it.code to it.message } shouldBe
            listOf("default_depth_limit" to "The ordinary default exceeds the supported nesting depth.")
    }

    test("complete creation gives required fields their ordinary default and leaves defaulted fields unset") {
        val generation = CatalogGeneration(value = "initialization catalog")
        val catalog = DefaultCheckedCatalog(generation, listOf(initializedDefinition))

        val prepared =
            runBlocking {
                DefaultInitializationRuntime(catalog).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.of(initializedUse),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fieldMap shouldBe mapOf("required" to DataValue.StringValueWrapper(""))
        prepared.findings shouldBe emptyList()
    }

    test("an abstract input stays unfinished and a defaulted field beside it stays unset") {
        val generation = CatalogGeneration(value = "abstract sample catalog")
        val abstractDefinition =
            TypeDefinition.partial(
                id = abstractId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val concreteDefinition =
            TypeDefinition.partial(
                id = concreteId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = concreteValueOwner, type = ScalarKind.TEXT.template),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
                parents = listOf(abstractId.namedTemplate()),
            )
        val ownerDefinition =
            TypeDefinition.partial(
                id = abstractOwnerId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = abstractInputOwner, type = abstractId.template()),
                                FieldDeclaration.partial(
                                    owner = ABSTRACT_DEFAULT_OWNER,
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                    hasConstructorDefault = true,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(abstractDefinition, concreteDefinition, ownerDefinition))

        val prepared =
            runBlocking {
                DefaultInitializationRuntime(catalog).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.of(abstractOwnerId.namedUse()),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fieldMap shouldBe mapOf("input" to DataValue.UNFILLED)
        prepared.findings shouldBe emptyList()
    }

    test("nested records leave their defaulted fields unset") {
        val generation = CatalogGeneration(value = "nested default catalog")
        val childDefinition =
            TypeDefinition.partial(
                id = childId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = childRequiredOwner, type = ScalarKind.TEXT.template),
                                FieldDeclaration.partial(
                                    owner = CHILD_DEFAULT_OWNER,
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                    hasConstructorDefault = true,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val parentDefinition =
            TypeDefinition.partial(
                id = parentId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = parentChildOwner, type = childId.template()),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(childDefinition, parentDefinition))

        val prepared =
            runBlocking {
                DefaultInitializationRuntime(catalog).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.of(parentId.namedUse()),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fieldMap.getValue("child") shouldBe
            DataValue.named(
                childId.namedUse(),
                DataValue.record(
                    mapOf(
                        "required" to DataValue.StringValueWrapper(""),
                    ),
                ),
            )
    }

    test("required recursive defaults terminate with located findings") {
        val generation = CatalogGeneration(value = "recursive initialization")
        val directId = TypeDefinitionId.qualified("test", "RequiredRecursive")
        val direct =
            TypeDefinition.partial(
                id = directId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = directId, name = "next"),
                                    type = directId.template(),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(direct))

        val prepared =
            DefaultInitializationRuntime(catalog).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.of(directId.namedUse()),
                    emptyMap(),
                ),
            )

        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("recursive_default_unavailable")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe
            listOf(PathSegment.createField(name = "next"), PathSegment.createField(name = "next"))
    }

    test("nonregular recursive defaults reject expanding applications") {
        val generation = CatalogGeneration(value = "nonregular recursive initialization")
        val growId = TypeDefinitionId.qualified("test", "Grow")
        val parameter = ParameterKey(owner = growId, index = 0)
        val grow =
            TypeDefinition.partial(
                id = growId,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = growId, name = "next"),
                                    type =
                                        growId.template(
                                            listOf(
                                                StandardTypes.list.template(listOf(parameter.template)),
                                            ),
                                        ),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + grow)

        val prepared =
            DefaultInitializationRuntime(catalog).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.of(growId.namedUse(listOf(ScalarKind.TEXT.use))),
                    emptyMap(),
                ),
            )

        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("recursive_default_unavailable")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe
            listOf(PathSegment.createField(name = "next"), PathSegment.createField(name = "next"))
    }

    test("abstract recursive input remains unselected without evaluating concrete forms") {
        val generation = CatalogGeneration(value = "abstract recursive initialization")
        val nodeId = TypeDefinitionId.qualified("test", "RecursiveNode")
        val branchId = TypeDefinitionId.qualified("test", "RecursiveBranch")
        val ownerId = TypeDefinitionId.qualified("test", "RecursiveOwner")
        val node =
            TypeDefinition.partial(
                id = nodeId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val branch =
            TypeDefinition.partial(
                id = branchId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = branchId, name = "child"),
                                    type = nodeId.template(),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
                parents = listOf(nodeId.namedTemplate()),
            )
        val owner =
            TypeDefinition.partial(
                id = ownerId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = FieldOwner(definition = ownerId, name = "node"), type = nodeId.template()),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(node, branch, owner))

        val prepared =
            DefaultInitializationRuntime(catalog).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.of(ownerId.namedUse()),
                    emptyMap(),
                ),
            )

        prepared.record.fieldMap.getValue("node") shouldBe DataValue.UNFILLED
        prepared.findings shouldBe emptyList()
    }

    test("finite nested applications and recursive collections keep ordinary defaults") {
        val generation = CatalogGeneration(value = "finite recursive initialization")
        val boxId = TypeDefinitionId.qualified("test", "DefaultBox")
        val boxParameter = ParameterKey(owner = boxId, index = 0)
        val box =
            TypeDefinition.partial(
                id = boxId,
                parameters = listOf(TypeParameter.partial(key = boxParameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = boxId, name = "value"),
                                    type = boxParameter.template,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val treeId = TypeDefinitionId.qualified("test", "DefaultTree")
        val treeParameter = ParameterKey(owner = treeId, index = 0)
        val tree =
            TypeDefinition.partial(
                id = treeId,
                parameters = listOf(TypeParameter.partial(key = treeParameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = treeId, name = "value"),
                                    type = treeParameter.template,
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = treeId, name = "children"),
                                    type = StandardTypes.list.template(listOf(treeId.template(listOf(treeParameter.template)))),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + listOf(box, tree))
        val runtime = DefaultInitializationRuntime(catalog)
        val text = ScalarKind.TEXT.use
        val innerBox = boxId.namedUse(listOf(text))

        val boxed =
            runtime.prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.of(boxId.namedUse(listOf(innerBox.use))),
                    emptyMap(),
                ),
            )
        boxed.findings shouldBe emptyList()
        boxed.record.fieldMap.getValue("value") shouldBe
            DataValue.named(innerBox, DataValue.record(mapOf("value" to DataValue.StringValueWrapper(""))))

        val treeUse = treeId.namedUse(listOf(text))
        val preparedTree =
            runtime.prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.of(treeUse),
                    emptyMap(),
                ),
            )
        preparedTree.findings shouldBe emptyList()
        preparedTree.record.fieldMap shouldBe
            mapOf(
                "value" to DataValue.StringValueWrapper(""),
                "children" to
                    DataValue.named(
                        StandardTypes.list.namedUse(listOf(treeUse.use)),
                        DataValue.listValue(emptyList()),
                    ),
            )
    }
}
