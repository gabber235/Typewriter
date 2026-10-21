package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationDiagnostic
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.authoredDefault
import com.typewritermc.authoring.validateStructure
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.integerScalar
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine

val InitializationRuntimeConformanceTest by testSuite {
    test("shared scalar defaults preserve the authored representation") {
        ScalarKind.BYTES.authoredDefault() shouldBe DataValue.Bytes(emptyList())
        ScalarKind.TIMESTAMP.authoredDefault() shouldBe DataValue.Unfilled
    }

    test("complete supplied values pass through without record synthesis") {
        val generation = CatalogGeneration("complete supplied value")
        val catalog = DefaultCheckedCatalog(generation, emptyList())
        val supplied = DataValue.StringValue("authored")
        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                InitializationRequest(
                    catalog = generation,
                    target = PreparationTarget.Value(ScalarKind.TEXT.use),
                    supplied = supplied,
                ),
            )

        prepared.content shouldBe PreparedContent.Value(supplied)
        prepared.findings shouldBe emptyList()
    }

    test("partial supplied record fields merge with captured constructor defaults") {
        val generation = CatalogGeneration("partial supplied record")
        val definition =
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
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
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
                    TypeSelection.Complete(INITIALIZED_USE),
                    mapOf("required" to DataValue.StringValue("authored")),
                ),
            )

        plan.sampled.getValue(REQUIRED_OWNER).value shouldBe DataValue.StringValue("authored")
        prepared.record.fields shouldBe
            mapOf(
                "required" to DataValue.StringValue("authored"),
                "defaulted" to DataValue.Integer(java.math.BigInteger.valueOf(3)),
            )
        prepared.findings shouldBe emptyList()
    }

    test("pending generic creation materializes every independently known field") {
        val generation = CatalogGeneration("pending initialization catalog")
        val definitionId = TypeDefinitionId.qualified("test", "PendingConfiguration")
        val parameter = ParameterKey(owner = definitionId, index = 0)
        val independent = FieldOwner(definition = definitionId, name = "independent")
        val defaulted = FieldOwner(definition = definitionId, name = "defaulted")
        val dependent = FieldOwner(definition = definitionId, name = "dependent")
        val definition =
            TypeDefinition.partial(
                id = definitionId,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = independent, type = ScalarKind.TEXT.template),
                                FieldDeclaration.partial(
                                    owner = defaulted,
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                    hasConstructorDefault = true,
                                ),
                                FieldDeclaration.partial(owner = dependent, type = parameter.template),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
        val construction =
            object : NativeConstructionPlan {
                override val defaultedFields = setOf(defaulted)

                override fun sample(
                    arguments: AppliedNativeArguments,
                    supplied: Map<FieldOwner, CompleteValue>,
                ): CaptureResult = error("Pending creation must not sample a native constructor.")
            }
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(construction, definitionId)))
        val selection =
            TypeSelection.Pending(
                definitionId,
                listOf(com.typewritermc.authoring.ArgumentSelection.Unfilled),
            )

        val prepared =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    generation,
                    selection,
                    emptyMap(),
                ),
            )

        prepared.record shouldBe
            com.typewritermc.authoring.AuthoringRecord(
                selection,
                mapOf(
                    "independent" to DataValue.StringValue(""),
                    "defaulted" to DataValue.Unfilled,
                    "dependent" to DataValue.Unfilled,
                ),
            )
        prepared.record.validateStructure(catalog) shouldBe StructuralResult.Valid
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("incomplete_type_selection")

        val unknown =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    generation,
                    selection,
                    mapOf("unknown" to DataValue.Boolean(true)),
                ),
            )
        unknown.record.fields shouldBe mapOf("unknown" to DataValue.Boolean(true))
        unknown.findings.map(InitializationDiagnostic::code) shouldBe listOf("unknown_field")

        val dependentSupplied =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    generation,
                    selection,
                    mapOf("dependent" to DataValue.StringValue("unchecked")),
                ),
            )
        dependentSupplied.record.fields shouldBe mapOf("dependent" to DataValue.StringValue("unchecked"))
        dependentSupplied.findings.map(InitializationDiagnostic::code) shouldBe listOf("dependent_field_type_unavailable")
    }

    test("ordinary defaults feed required sampling without becoming captured Kotlin defaults") {
        val generation = CatalogGeneration("initialization catalog")
        val definition =
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
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
        val plan = CapturingPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan)))
        val runtime = DefaultInitializationRuntime(catalog, bindings)

        val prepared =
            runSuspend {
                runtime.prepare(
                    recordRequest(
                        generation,
                        TypeSelection.Complete(INITIALIZED_USE),
                        emptyMap(),
                    ),
                )
            }

        plan.sampled.getValue(REQUIRED_OWNER).value shouldBe DataValue.StringValue("")
        prepared.record.fields shouldBe
            mapOf(
                "required" to DataValue.StringValue(""),
                "defaulted" to DataValue.Integer(java.math.BigInteger.valueOf(3)),
            )
        prepared.findings shouldBe emptyList()

        val unknown =
            runtime.prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.Complete(INITIALIZED_USE),
                    mapOf("unknown" to DataValue.Boolean(true)),
                ),
            )
        unknown.record.fields shouldBe mapOf("unknown" to DataValue.Boolean(true))
        unknown.findings.map(InitializationDiagnostic::code) shouldBe listOf("unknown_field")
    }

    test("failed constructor sampling keeps declared defaults unfinished") {
        val generation = CatalogGeneration("failed initialization catalog")
        val definition =
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
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
        val diagnostic = InitializationDiagnostic(DEFAULTED_OWNER, "constructor_failed", "The constructor failed.")
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(FailingPlan(diagnostic))))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        generation,
                        TypeSelection.Complete(INITIALIZED_USE),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fields.getValue("required") shouldBe DataValue.StringValue("")
        prepared.record.fields.getValue("defaulted") shouldBe DataValue.Unfilled
        prepared.findings shouldBe
            listOf(
                diagnostic.copy(relativePath = com.typewritermc.authoring.ValuePath(listOf(PathSegment.Field("defaulted")))),
            )
    }

    test("missing abstract constructor inputs stay unfinished and block dependent defaults") {
        val generation = CatalogGeneration("abstract sample catalog")
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
                        TypeSelection.Complete(ABSTRACT_OWNER_ID.namedUse()),
                        emptyMap(),
                    ),
                )
            }

        plan.sampled shouldBe emptyMap()
        prepared.record.fields.getValue("input") shouldBe DataValue.Unfilled
        prepared.record.fields.getValue("defaulted") shouldBe DataValue.Unfilled
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("unfinished_constructor_input")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe listOf(PathSegment.Field("input"))
    }

    test("nested records include captured Kotlin defaults") {
        val generation = CatalogGeneration("nested default catalog")
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
                        TypeSelection.Complete(PARENT_ID.namedUse()),
                        emptyMap(),
                    ),
                )
            }

        prepared.record.fields.getValue("child") shouldBe
            DataValue.Named(
                CHILD_ID.namedUse(),
                DataValue.Record(
                    mapOf(
                        "required" to DataValue.StringValue(""),
                        "defaulted" to DataValue.Integer(java.math.BigInteger.valueOf(7)),
                    ),
                ),
            )
        plan.samples shouldBe 1
    }

    test("nested initialization findings retain each occurrence path") {
        val generation = CatalogGeneration("nested finding paths")
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
        val diagnostic = InitializationDiagnostic(seed, "native_default_capture_failed", "Seed capture failed.")
        val plan = FieldFailingPlan(seed, diagnostic)
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, styleId)))

        val prepared =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.Complete(themeId.namedUse()),
                    mapOf("label" to DataValue.StringValue("supplied")),
                ),
            )

        prepared.record.fields.getValue("label") shouldBe DataValue.StringValue("supplied")
        prepared.findings.map { finding -> finding.relativePath?.segments } shouldBe
            listOf(
                listOf(PathSegment.Field("styleA"), PathSegment.Field("seed")),
                listOf(PathSegment.Field("styleB"), PathSegment.Field("seed")),
            )
        plan.samples shouldBe 2
    }

    test("required recursive defaults terminate with located findings") {
        val generation = CatalogGeneration("recursive initialization")
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
                    TypeSelection.Complete(directId.namedUse()),
                    emptyMap(),
                ),
            )

        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("recursive_default_unavailable")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe
            listOf(PathSegment.Field("next"), PathSegment.Field("next"))
    }

    test("nonregular recursive defaults reject expanding applications") {
        val generation = CatalogGeneration("nonregular recursive initialization")
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
                    TypeSelection.Complete(growId.namedUse(listOf(ScalarKind.TEXT.use))),
                    emptyMap(),
                ),
            )

        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("recursive_default_unavailable")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe
            listOf(PathSegment.Field("next"), PathSegment.Field("next"))
    }

    test("abstract recursive input remains unselected without evaluating concrete forms") {
        val generation = CatalogGeneration("abstract recursive initialization")
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
                    TypeSelection.Complete(ownerId.namedUse()),
                    emptyMap(),
                ),
            )

        prepared.record.fields.getValue("node") shouldBe DataValue.Unfilled
        prepared.findings shouldBe emptyList()
    }

    test("finite nested applications and recursive collections keep ordinary defaults") {
        val generation = CatalogGeneration("finite recursive initialization")
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
                    TypeSelection.Complete(boxId.namedUse(listOf(innerBox.use))),
                    emptyMap(),
                ),
            )
        boxed.findings shouldBe emptyList()
        boxed.record.fields.getValue("value") shouldBe
            DataValue.Named(innerBox, DataValue.Record(mapOf("value" to DataValue.StringValue(""))))

        val treeUse = treeId.namedUse(listOf(text))
        val preparedTree =
            runtime.prepareNow(
                recordRequest(
                    generation,
                    TypeSelection.Complete(treeUse),
                    emptyMap(),
                ),
            )
        preparedTree.findings shouldBe emptyList()
        preparedTree.record.fields shouldBe
            mapOf(
                "value" to DataValue.StringValue(""),
                "children" to
                    DataValue.Named(
                        StandardTypes.list.namedUse(listOf(treeUse.use)),
                        DataValue.ListValue(emptyList()),
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
        return CaptureResult.Captured(mapOf(DEFAULTED_OWNER to DataValue.Integer(java.math.BigInteger.valueOf(3))))
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
    var samples = 0

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        samples += 1
        return CaptureResult.Unavailable(listOf(diagnostic))
    }
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
            mapOf(ABSTRACT_DEFAULT_OWNER to DataValue.Integer(java.math.BigInteger.valueOf(11))),
        )
    }
}

private class ChildPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(CHILD_DEFAULT_OWNER)
    var samples = 0

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        samples++
        return CaptureResult.Captured(
            mapOf(CHILD_DEFAULT_OWNER to DataValue.Integer(java.math.BigInteger.valueOf(7))),
        )
    }
}

private class PlanFactory(
    override val constructionPlan: NativeConstructionPlan,
    override val definition: TypeDefinitionId = INITIALIZED_ID,
) : NativeBindingFactory {
    override val provider = NativeBindingId("test.initialization")

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
    get() = (content as PreparedContent.Record).record

private fun recordRequest(
    generation: CatalogGeneration,
    selection: TypeSelection,
    supplied: Map<String, DataValue>,
) = InitializationRequest(
    catalog = generation,
    target = PreparationTarget.Record(selection),
    supplied = DataValue.Record(supplied),
)
