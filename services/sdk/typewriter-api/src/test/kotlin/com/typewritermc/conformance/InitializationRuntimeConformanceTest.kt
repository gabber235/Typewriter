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
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
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

val InitializationRuntimeConformanceTest by testSuite {
    test("complete supplied values pass through without record synthesis") {
        val generation = CatalogGeneration(value = "complete supplied value")
        val catalog = DefaultCheckedCatalog(generation, emptyList())
        val supplied = DataValue.StringValueWrapper("authored")
        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                ValuePreparationRequest(
                    catalog = generation,
                    target = PreparationTarget.ValueWrapper(ScalarKind.TEXT.use),
                    suppliedValue = supplied,
                ),
            )

        prepared.content shouldBe PreparedContent.ValueWrapper(supplied)
        prepared.findings shouldBe emptyList()
    }

    test("partial supplied record fields merge with captured constructor defaults") {
        val generation = CatalogGeneration(value = "partial supplied record")
        val catalog = DefaultCheckedCatalog(generation, listOf(INITIALIZED_DEFINITION))
        val plan = CapturingPlan()
        val runtime =
            DefaultInitializationRuntime(
                catalog,
                FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan))),
            )

        val prepared =
            runtime.prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.CompleteWrapper(INITIALIZED_USE),
                    mapOf("required" to DataValue.StringValueWrapper("authored")),
                ),
            )

        plan.sampled.getValue(REQUIRED_OWNER).value shouldBe DataValue.StringValueWrapper("authored")
        prepared.record.fieldMap shouldBe
            mapOf(
                "required" to DataValue.StringValueWrapper("authored"),
                "defaulted" to DataValue.integer(java.math.BigInteger.valueOf(3)),
            )
        prepared.findings shouldBe emptyList()
    }

    val pending =
        object {
            val generation = CatalogGeneration(value = "pending initialization catalog")
            val definitionId = TypeDefinitionId.qualified("test", "PendingConfiguration")
            val parameter = ParameterKey(owner = definitionId, index = 0)
            val defaulted = FieldOwner(definition = definitionId, name = "defaulted")
            val catalog =
                DefaultCheckedCatalog(
                    generation,
                    listOf(
                        TypeDefinition.partial(
                            id = definitionId,
                            parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                            representation =
                                RepresentationTemplate.createRecord(
                                    fields =
                                        listOf(
                                            FieldDeclaration.partial(
                                                owner = FieldOwner(definition = definitionId, name = "independent"),
                                                type = ScalarKind.TEXT.template,
                                            ),
                                            FieldDeclaration.partial(
                                                owner = defaulted,
                                                type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                                hasConstructorDefault = true,
                                            ),
                                            FieldDeclaration.partial(
                                                owner = FieldOwner(definition = definitionId, name = "dependent"),
                                                type = parameter.template,
                                            ),
                                        ),
                                    abstract_ = false,
                                ),
                        ),
                    ),
                )
            val construction =
                object : NativeConstructionPlan {
                    override val defaultedFields = setOf(defaulted)

                    override fun sample(
                        arguments: AppliedNativeArguments,
                        supplied: Map<FieldOwner, CompleteValue>,
                    ): CaptureResult = error("Pending creation must not sample a native constructor.")
                }
            val selection = TypeSelection.createPending(definition = definitionId, arguments = listOf(ArgumentSelection.UNFILLED))

            fun prepare(supplied: Map<String, DataValue>) =
                DefaultInitializationRuntime(
                    catalog,
                    FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(construction, definitionId))),
                ).prepareNow(recordRequest(generation, selection, supplied))
        }

    test("pending generic creation fills every field it knows without its type argument and leaves the rest unfilled") {
        val prepared = pending.prepare(emptyMap())

        prepared.record shouldBe
            AuthoringRecord.of(
                pending.selection,
                mapOf(
                    "independent" to DataValue.StringValueWrapper(""),
                    "defaulted" to DataValue.UNFILLED,
                    "dependent" to DataValue.UNFILLED,
                ),
            )
        prepared.record.validateStructure(pending.catalog) shouldBe StructuralResult.VALID
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("incomplete_type_selection")
    }

    test("pending generic creation keeps a supplied field whose type depends on the missing argument and reports it") {
        val prepared = pending.prepare(mapOf("dependent" to DataValue.StringValueWrapper("unchecked")))

        prepared.record.fieldMap shouldBe mapOf("dependent" to DataValue.StringValueWrapper("unchecked"))
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("dependent_field_type_unavailable")
    }

    test("creation keeps a supplied field the type does not declare and reports it as unknown") {
        val prepared = pending.prepare(mapOf("unknown" to DataValue.BooleanWrapper(true)))

        prepared.record.fieldMap shouldBe mapOf("unknown" to DataValue.BooleanWrapper(true))
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("unknown_field")
    }

    test("a preparation request for another catalog generation is unavailable") {
        val prepared =
            DefaultInitializationRuntime(pending.catalog, FactoryNativeBindingRegistry(pending.catalog, emptyList()))
                .prepareNow(recordRequest(CatalogGeneration(value = "other"), pending.selection, emptyMap()))

        prepared.findings.map { it.code to it.message } shouldBe
            listOf("catalog_generation_mismatch" to "The initialization request uses a different catalog generation.")
    }

    test("record preparation refuses a supplied value that is not a record") {
        val prepared =
            DefaultInitializationRuntime(pending.catalog, FactoryNativeBindingRegistry(pending.catalog, emptyList()))
                .prepareNow(
                    recordRequest(
                        pending.generation,
                        pending.selection,
                        emptyMap(),
                    ).copy(suppliedValue = DataValue.StringValueWrapper("text")),
                )

        prepared.findings.map { it.code to it.message } shouldBe
            listOf("invalid_supplied_value" to "Record preparation requires a record value.")
    }

    test("record preparation refuses a selection of an undeclared type") {
        val prepared =
            DefaultInitializationRuntime(pending.catalog, FactoryNativeBindingRegistry(pending.catalog, emptyList()))
                .prepareNow(
                    recordRequest(
                        pending.generation,
                        TypeSelection.CompleteWrapper(TypeDefinitionId.qualified("test", "Undeclared").namedUse()),
                        emptyMap(),
                    ),
                )

        prepared.findings.map { it.code to it.message } shouldBe listOf("invalid_type_selection" to "unknown_definition")
    }

    test("an invalid supplied constructor input blocks sampling and is reported at its field") {
        val generation = CatalogGeneration(value = "mismatched input catalog")
        val catalog = DefaultCheckedCatalog(generation, listOf(INITIALIZED_DEFINITION))
        val plan = CapturingPlan()
        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan))))
                .prepareNow(
                    recordRequest(
                        generation,
                        TypeSelection.CompleteWrapper(INITIALIZED_USE),
                        mapOf("required" to DataValue.BooleanWrapper(true)),
                    ),
                )

        plan.sampled shouldBe emptyMap()
        prepared.findings.map { Triple(it.code, it.field, it.relativePath) } shouldBe
            listOf(Triple("wrong_scalar", REQUIRED_OWNER, ValuePath.root.field("required")))
        prepared.findings.single().message shouldBe "A constructor input is invalid, so omitted defaults cannot be evaluated."
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
                                abstract_ = false,
                            ),
                    )
                },
            )

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList()))
                .prepareNow(recordRequest(generation, TypeSelection.CompleteWrapper(levels.first().namedUse()), emptyMap()))

        prepared.findings.map { it.code to it.message } shouldBe
            listOf("default_depth_limit" to "The ordinary default exceeds the supported nesting depth.")
    }

    test("complete creation samples the constructor with authored defaults and keeps only the defaults it captured") {
        val generation = CatalogGeneration(value = "initialization catalog")
        val catalog = DefaultCheckedCatalog(generation, listOf(INITIALIZED_DEFINITION))
        val plan = CapturingPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan)))
        val runtime = DefaultInitializationRuntime(catalog, bindings)

        val prepared =
            runSuspend {
                runtime.prepare(
                    recordRequest(
                        generation,
                        TypeSelection.CompleteWrapper(INITIALIZED_USE),
                        emptyMap(),
                    ),
                )
            }

        plan.sampled.getValue(REQUIRED_OWNER).value shouldBe DataValue.StringValueWrapper("")
        prepared.record.fieldMap shouldBe
            mapOf(
                "required" to DataValue.StringValueWrapper(""),
                "defaulted" to DataValue.integer(java.math.BigInteger.valueOf(3)),
            )
        prepared.findings shouldBe emptyList()
    }

    test("failed constructor sampling keeps declared defaults unfinished") {
        val generation = CatalogGeneration(value = "failed initialization catalog")
        val catalog = DefaultCheckedCatalog(generation, listOf(INITIALIZED_DEFINITION))
        val diagnostic =
            InitializationDiagnostic(
                field = DEFAULTED_OWNER,
                code = "constructor_failed",
                message = "The constructor failed.",
                relativePath = null,
            )
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(FailingPlan(diagnostic))))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.CompleteWrapper(INITIALIZED_USE),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fieldMap.getValue("required") shouldBe DataValue.StringValueWrapper("")
        prepared.record.fieldMap.getValue("defaulted") shouldBe DataValue.UNFILLED
        prepared.findings shouldBe
            listOf(
                diagnostic.copy(relativePath = ValuePath.root.field("defaulted")),
            )
    }

    test("missing abstract constructor inputs stay unfinished and block dependent defaults") {
        val generation = CatalogGeneration(value = "abstract sample catalog")
        val abstractDefinition =
            TypeDefinition.partial(
                id = ABSTRACT_ID,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
            )
        val concreteDefinition =
            TypeDefinition.partial(
                id = CONCRETE_ID,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = CONCRETE_VALUE_OWNER, type = ScalarKind.TEXT.template),
                            ),
                        abstract_ = false,
                    ),
                parents = listOf(ABSTRACT_ID.namedTemplate()),
            )
        val ownerDefinition =
            TypeDefinition.partial(
                id = ABSTRACT_OWNER_ID,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = ABSTRACT_INPUT_OWNER, type = ABSTRACT_ID.template()),
                                FieldDeclaration.partial(
                                    owner = ABSTRACT_DEFAULT_OWNER,
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                    hasConstructorDefault = true,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(abstractDefinition, concreteDefinition, ownerDefinition))
        val plan = AbstractInputPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, ABSTRACT_OWNER_ID)))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.CompleteWrapper(ABSTRACT_OWNER_ID.namedUse()),
                        emptyMap(),
                    ),
                )
            }

        plan.sampled shouldBe emptyMap()
        prepared.record.fieldMap.getValue("input") shouldBe DataValue.UNFILLED
        prepared.record.fieldMap.getValue("defaulted") shouldBe DataValue.UNFILLED
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("unfinished_constructor_input")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe listOf(PathSegment.createField(name = "input"))
    }

    test("nested records include captured Kotlin defaults") {
        val generation = CatalogGeneration(value = "nested default catalog")
        val childDefinition =
            TypeDefinition.partial(
                id = CHILD_ID,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = CHILD_REQUIRED_OWNER, type = ScalarKind.TEXT.template),
                                FieldDeclaration.partial(
                                    owner = CHILD_DEFAULT_OWNER,
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                    hasConstructorDefault = true,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val parentDefinition =
            TypeDefinition.partial(
                id = PARENT_ID,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = PARENT_CHILD_OWNER, type = CHILD_ID.template()),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(childDefinition, parentDefinition))
        val plan = ChildPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, CHILD_ID)))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.CompleteWrapper(PARENT_ID.namedUse()),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fieldMap.getValue("child") shouldBe
            DataValue.named(
                CHILD_ID.namedUse(),
                DataValue.record(
                    mapOf(
                        "required" to DataValue.StringValueWrapper(""),
                        "defaulted" to DataValue.integer(java.math.BigInteger.valueOf(7)),
                    ),
                ),
            )
    }

    test("nested initialization findings retain each occurrence path") {
        val generation = CatalogGeneration(value = "nested finding paths")
        val styleId = TypeDefinitionId.qualified("test", "DiagnosticStyle")
        val themeId = TypeDefinitionId.qualified("test", "DiagnosticTheme")
        val seed = FieldOwner(definition = styleId, name = "seed")
        val style =
            TypeDefinition.partial(
                id = styleId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = seed, type = ScalarKind.TEXT.template, hasConstructorDefault = true),
                            ),
                        abstract_ = false,
                    ),
            )
        val theme =
            TypeDefinition.partial(
                id = themeId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = themeId, name = "styleA"),
                                    type = styleId.template(),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = themeId, name = "styleB"),
                                    type = styleId.template(),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = themeId, name = "label"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(style, theme))
        val diagnostic =
            InitializationDiagnostic(
                field = seed,
                code = "native_default_capture_failed",
                message = "Seed capture failed.",
                relativePath = null,
            )
        val plan = FieldFailingPlan(seed, diagnostic)
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, styleId)))

        val prepared =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.CompleteWrapper(themeId.namedUse()),
                    mapOf("label" to DataValue.StringValueWrapper("supplied")),
                ),
            )

        prepared.record.fieldMap.getValue("label") shouldBe DataValue.StringValueWrapper("supplied")
        prepared.findings shouldBe
            listOf(
                diagnostic.copy(relativePath = ValuePath.root.field("styleA").field("seed")),
                diagnostic.copy(relativePath = ValuePath.root.field("styleB").field("seed")),
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
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(direct))

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.CompleteWrapper(directId.namedUse()),
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
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + grow)

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.CompleteWrapper(growId.namedUse(listOf(ScalarKind.TEXT.use))),
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
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
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
                        abstract_ = false,
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
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(node, branch, owner))

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.CompleteWrapper(ownerId.namedUse()),
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
                        abstract_ = false,
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
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + listOf(box, tree))
        val runtime = DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList()))
        val text = ScalarKind.TEXT.use
        val innerBox = boxId.namedUse(listOf(text))

        val boxed =
            runtime.prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.CompleteWrapper(boxId.namedUse(listOf(innerBox.use))),
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
                    TypeSelection.CompleteWrapper(treeUse),
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

private class CapturingPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)
    var sampled: Map<FieldOwner, CompleteValue> = emptyMap()

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        sampled = supplied
        return CaptureResult.Captured(mapOf(DEFAULTED_OWNER to DataValue.integer(java.math.BigInteger.valueOf(3))))
    }
}

private class FailingPlan(
    private val diagnostic: InitializationDiagnostic,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult = CaptureResult.Unavailable(listOf(diagnostic))
}

private class FieldFailingPlan(
    field: FieldOwner,
    private val diagnostic: InitializationDiagnostic,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(field)

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult = CaptureResult.Unavailable(listOf(diagnostic))
}

private class AbstractInputPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(ABSTRACT_DEFAULT_OWNER)
    var sampled: Map<FieldOwner, CompleteValue> = emptyMap()

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        sampled = supplied
        return CaptureResult.Captured(
            mapOf(ABSTRACT_DEFAULT_OWNER to DataValue.integer(java.math.BigInteger.valueOf(11))),
        )
    }
}

private class ChildPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(CHILD_DEFAULT_OWNER)

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult =
        CaptureResult.Captured(
            mapOf(CHILD_DEFAULT_OWNER to DataValue.integer(java.math.BigInteger.valueOf(7))),
        )
}

private class PlanFactory(
    override val constructionPlan: NativeConstructionPlan,
    override val definition: TypeDefinitionId = INITIALIZED_ID,
) : NativeBindingFactory {
    override val provider = NativeBindingId(value = "test.initialization")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> = error("Initialization sampling does not bind a complete native record.")
}

private fun <T> runSuspend(block: suspend () -> T): T {
    var result: Result<T>? = null
    block.startCoroutine(
        object : Continuation<T> {
            override val context = EmptyCoroutineContext

            override fun resumeWith(value: Result<T>) {
                result = value
            }
        },
    )
    return result!!.getOrThrow()
}

private val INITIALIZED_ID = TypeDefinitionId.qualified("test", "Initialized")
private val INITIALIZED_USE = INITIALIZED_ID.namedUse(emptyList())
private val REQUIRED_OWNER = FieldOwner(definition = INITIALIZED_ID, name = "required")
private val DEFAULTED_OWNER = FieldOwner(definition = INITIALIZED_ID, name = "defaulted")

/** A record with a required text field and a defaulted integer field whose default the constructor captures. */
private val INITIALIZED_DEFINITION =
    TypeDefinition.partial(
        id = INITIALIZED_ID,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = REQUIRED_OWNER, type = ScalarKind.TEXT.template),
                        FieldDeclaration.partial(
                            owner = DEFAULTED_OWNER,
                            type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                            hasConstructorDefault = true,
                        ),
                    ),
                abstract_ = false,
            ),
    )
private val ABSTRACT_ID = TypeDefinitionId.qualified("test", "AbstractInput")
private val CONCRETE_ID = TypeDefinitionId.qualified("test", "ConcreteInput")
private val CONCRETE_VALUE_OWNER = FieldOwner(definition = CONCRETE_ID, name = "value")
private val ABSTRACT_OWNER_ID = TypeDefinitionId.qualified("test", "AbstractOwner")
private val ABSTRACT_INPUT_OWNER = FieldOwner(definition = ABSTRACT_OWNER_ID, name = "input")
private val ABSTRACT_DEFAULT_OWNER = FieldOwner(definition = ABSTRACT_OWNER_ID, name = "defaulted")
private val CHILD_ID = TypeDefinitionId.qualified("test", "Child")
private val CHILD_REQUIRED_OWNER = FieldOwner(definition = CHILD_ID, name = "required")
private val CHILD_DEFAULT_OWNER = FieldOwner(definition = CHILD_ID, name = "defaulted")
private val PARENT_ID = TypeDefinitionId.qualified("test", "Parent")
private val PARENT_CHILD_OWNER = FieldOwner(definition = PARENT_ID, name = "child")

private val PreparedValue.record
    get() = (content as PreparedContent.RecordWrapper).value

private fun recordRequest(
    generation: CatalogGeneration,
    selection: TypeSelection,
    supplied: Map<String, DataValue>,
) = ValuePreparationRequest(
    catalog = generation,
    target = PreparationTarget.RecordWrapper(selection),
    suppliedValue = DataValue.record(supplied),
)
