package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationCatalogPlanner
import com.typewritermc.authoring.InitializationDiagnostic
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.SamplingInputs
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.authoredDefault
import com.typewritermc.authoring.validateStructure
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine

val InitializationRuntimeConformanceTest by testSuite {
    test("shared scalar defaults preserve the authored representation") {
        ScalarKind.Bytes.authoredDefault() shouldBe DataValue.Bytes(emptyList())
        ScalarKind.Timestamp.authoredDefault() shouldBe DataValue.Unfilled
    }

    test("complete supplied values pass through without record synthesis") {
        val generation = CatalogGeneration("complete supplied value")
        val catalog = DefaultCheckedCatalog(generation, emptyList())
        val supplied = DataValue.StringValue("authored")
        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                InitializationRequest(
                    id = InitializationRequestId("complete value"),
                    catalog = generation,
                    target = PreparationTarget.Value(TypeUse.Scalar(ScalarKind.Text)),
                    supplied = supplied,
                    intentHash = "complete value",
                ),
            )

        prepared.content shouldBe PreparedContent.Value(supplied)
        prepared.findings shouldBe emptyList()
    }

    test("partial supplied record fields merge with captured constructor defaults") {
        val generation = CatalogGeneration("partial supplied record")
        val definition =
            TypeDefinition(
                INITIALIZED_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                DEFAULTED_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
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
                    InitializationRequestId("partial record"),
                    generation,
                    TypeSelection.Complete(INITIALIZED_USE),
                    mapOf("required" to DataValue.StringValue("authored")),
                    "partial record",
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
        val definitionId = TypeDefinitionId(TypeId.Qualified("test", "PendingConfiguration"), 1)
        val parameter = com.typewritermc.types.ParameterKey(definitionId, 0)
        val independent = FieldOwner(definitionId, "independent")
        val defaulted = FieldOwner(definitionId, "defaulted")
        val dependent = FieldOwner(definitionId, "dependent")
        val definition =
            TypeDefinition(
                definitionId,
                parameters = listOf(com.typewritermc.types.TypeParameter(parameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(independent, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                defaulted,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                            FieldDeclaration(dependent, TypeTemplate.Parameter(parameter)),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
        val construction =
            object : NativeConstructionPlan {
                override val defaultedFields = setOf(defaulted)

                override fun sample(
                    arguments: AppliedNativeArguments,
                    requiredInputs: SamplingInputs,
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
                    InitializationRequestId("pending generic"),
                    generation,
                    selection,
                    emptyMap(),
                    "intent",
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
                    InitializationRequestId("pending unknown field"),
                    generation,
                    selection,
                    mapOf("unknown" to DataValue.Boolean(true)),
                    "unknown intent",
                ),
            )
        unknown.record.fields shouldBe mapOf("unknown" to DataValue.Boolean(true))
        unknown.findings.map(InitializationDiagnostic::code) shouldBe listOf("unknown_field")

        val dependentSupplied =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    InitializationRequestId("pending dependent field"),
                    generation,
                    selection,
                    mapOf("dependent" to DataValue.StringValue("unchecked")),
                    "dependent intent",
                ),
            )
        dependentSupplied.record.fields shouldBe mapOf("dependent" to DataValue.StringValue("unchecked"))
        dependentSupplied.findings.map(InitializationDiagnostic::code) shouldBe listOf("dependent_field_type_unavailable")
    }

    test("ordinary defaults feed required sampling without becoming captured Kotlin defaults") {
        val generation = CatalogGeneration("initialization catalog")
        val definition =
            TypeDefinition(
                INITIALIZED_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                DEFAULTED_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
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
                        InitializationRequestId("create initialized"),
                        generation,
                        TypeSelection.Complete(INITIALIZED_USE),
                        emptyMap(),
                        "intent",
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
                    InitializationRequestId("complete unknown field"),
                    generation,
                    TypeSelection.Complete(INITIALIZED_USE),
                    mapOf("unknown" to DataValue.Boolean(true)),
                    "unknown intent",
                ),
            )
        unknown.record.fields shouldBe mapOf("unknown" to DataValue.Boolean(true))
        unknown.findings.map(InitializationDiagnostic::code) shouldBe listOf("unknown_field")
    }

    test("failed constructor sampling keeps declared defaults unfinished") {
        val generation = CatalogGeneration("failed initialization catalog")
        val definition =
            TypeDefinition(
                INITIALIZED_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                DEFAULTED_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
        val diagnostic = InitializationDiagnostic(DEFAULTED_OWNER, "constructor_failed", "The constructor failed.")
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(FailingPlan(diagnostic))))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        InitializationRequestId("failed capture"),
                        generation,
                        TypeSelection.Complete(INITIALIZED_USE),
                        emptyMap(),
                        "intent",
                    ),
                )
            }

        prepared.record.fields.getValue("required") shouldBe DataValue.StringValue("")
        prepared.record.fields.getValue("defaulted") shouldBe DataValue.Unfilled
        prepared.findings shouldBe listOf(diagnostic)
    }

    test("abstract constructor inputs use a concrete sample without authoring the sample") {
        val generation = CatalogGeneration("abstract sample catalog")
        val abstractDefinition =
            TypeDefinition(
                ABSTRACT_ID,
                representation = RepresentationTemplate.Record(emptyList(), abstract = true),
            )
        val concreteDefinition =
            TypeDefinition(
                CONCRETE_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(CONCRETE_VALUE_OWNER, TypeTemplate.Scalar(ScalarKind.Text))),
                    ),
                parents = listOf(TypeTemplate.Named(ABSTRACT_ID)),
            )
        val ownerDefinition =
            TypeDefinition(
                ABSTRACT_OWNER_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(ABSTRACT_INPUT_OWNER, TypeTemplate.Named(ABSTRACT_ID)),
                            FieldDeclaration(
                                ABSTRACT_DEFAULT_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(abstractDefinition, concreteDefinition, ownerDefinition))
        val plan = AbstractInputPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, ABSTRACT_OWNER_ID)))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        InitializationRequestId("abstract input"),
                        generation,
                        TypeSelection.Complete(TypeUse.Named(ABSTRACT_OWNER_ID)),
                        emptyMap(),
                        "intent",
                    ),
                )
            }

        plan.sampled
            .getValue(ABSTRACT_INPUT_OWNER)
            .schema.use shouldBe TypeUse.Named(CONCRETE_ID)
        plan.sampled.getValue(ABSTRACT_INPUT_OWNER).value shouldBe
            DataValue.Named(
                TypeUse.Named(CONCRETE_ID),
                DataValue.Record(mapOf("value" to DataValue.StringValue(""))),
            )
        prepared.record.fields.getValue("input") shouldBe DataValue.Unfilled
        prepared.record.fields.getValue("defaulted") shouldBe DataValue.Integer(java.math.BigInteger.valueOf(11))
    }

    test("nested records include captured Kotlin defaults") {
        val generation = CatalogGeneration("nested default catalog")
        val childDefinition =
            TypeDefinition(
                CHILD_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(CHILD_REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                CHILD_DEFAULT_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val parentDefinition =
            TypeDefinition(
                PARENT_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(PARENT_CHILD_OWNER, TypeTemplate.Named(CHILD_ID))),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(childDefinition, parentDefinition))
        val plan = ChildPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, CHILD_ID)))

        val prepared =
            runSuspend {
                DefaultInitializationRuntime(catalog, bindings).prepare(
                    recordRequest(
                        InitializationRequestId("nested defaults"),
                        generation,
                        TypeSelection.Complete(TypeUse.Named(PARENT_ID)),
                        emptyMap(),
                        "intent",
                    ),
                )
            }

        prepared.record.fields.getValue("child") shouldBe
            DataValue.Named(
                TypeUse.Named(CHILD_ID),
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
        val styleId = TypeDefinitionId(TypeId.Qualified("test", "DiagnosticStyle"), 1)
        val themeId = TypeDefinitionId(TypeId.Qualified("test", "DiagnosticTheme"), 1)
        val seed = FieldOwner(styleId, "seed")
        val style =
            TypeDefinition(
                styleId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                seed,
                                TypeTemplate.Scalar(ScalarKind.Text),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val theme =
            TypeDefinition(
                themeId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(themeId, "styleA"), TypeTemplate.Named(styleId)),
                            FieldDeclaration(FieldOwner(themeId, "styleB"), TypeTemplate.Named(styleId)),
                            FieldDeclaration(FieldOwner(themeId, "label"), TypeTemplate.Scalar(ScalarKind.Text)),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(style, theme))
        val diagnostic = InitializationDiagnostic(seed, "native_default_capture_failed", "Seed capture failed.")
        val plan = FieldFailingPlan(seed, diagnostic)
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, styleId)))

        val prepared =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                recordRequest(
                    InitializationRequestId("nested finding paths"),
                    generation,
                    TypeSelection.Complete(TypeUse.Named(themeId)),
                    mapOf("label" to DataValue.StringValue("supplied")),
                    "intent",
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
        val directId = TypeDefinitionId(TypeId.Qualified("test", "RequiredRecursive"), 1)
        val direct =
            TypeDefinition(
                directId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(directId, "next"), TypeTemplate.Named(directId))),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(direct))

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                recordRequest(
                    InitializationRequestId("required recursive"),
                    generation,
                    TypeSelection.Complete(TypeUse.Named(directId)),
                    emptyMap(),
                    "intent",
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
        val growId = TypeDefinitionId(TypeId.Qualified("test", "Grow"), 1)
        val parameter = com.typewritermc.types.ParameterKey(growId, 0)
        val grow =
            TypeDefinition(
                growId,
                parameters = listOf(com.typewritermc.types.TypeParameter(parameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(
                                FieldOwner(growId, "next"),
                                TypeTemplate.Named(
                                    growId,
                                    listOf(
                                        TypeTemplate.Named(StandardTypes.list, listOf(TypeTemplate.Parameter(parameter))),
                                    ),
                                ),
                            ),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + grow)

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                recordRequest(
                    InitializationRequestId("nonregular recursive"),
                    generation,
                    TypeSelection.Complete(TypeUse.Named(growId, listOf(TypeUse.Scalar(ScalarKind.Text)))),
                    emptyMap(),
                    "intent",
                ),
            )

        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("recursive_default_unavailable")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe
            listOf(PathSegment.Field("next"), PathSegment.Field("next"))
    }

    test("abstract recursive samples share the recursion context") {
        val generation = CatalogGeneration("abstract recursive initialization")
        val nodeId = TypeDefinitionId(TypeId.Qualified("test", "RecursiveNode"), 1)
        val branchId = TypeDefinitionId(TypeId.Qualified("test", "RecursiveBranch"), 1)
        val ownerId = TypeDefinitionId(TypeId.Qualified("test", "RecursiveOwner"), 1)
        val node = TypeDefinition(nodeId, representation = RepresentationTemplate.Record(emptyList(), abstract = true))
        val branch =
            TypeDefinition(
                branchId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(branchId, "child"), TypeTemplate.Named(nodeId))),
                    ),
                parents = listOf(TypeTemplate.Named(nodeId)),
            )
        val owner =
            TypeDefinition(
                ownerId,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(ownerId, "node"), TypeTemplate.Named(nodeId))),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(node, branch, owner))

        val prepared =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).prepareNow(
                recordRequest(
                    InitializationRequestId("abstract recursive"),
                    generation,
                    TypeSelection.Complete(TypeUse.Named(ownerId)),
                    emptyMap(),
                    "intent",
                ),
            )

        prepared.record.fields.getValue("node") shouldBe DataValue.Unfilled
        prepared.findings.map(InitializationDiagnostic::code) shouldBe listOf("recursive_default_unavailable")
        prepared.findings
            .single()
            .relativePath
            ?.segments shouldBe
            listOf(PathSegment.Field("node"), PathSegment.Field("child"))
    }

    test("finite nested applications and recursive collections keep ordinary defaults") {
        val generation = CatalogGeneration("finite recursive initialization")
        val boxId = TypeDefinitionId(TypeId.Qualified("test", "DefaultBox"), 1)
        val boxParameter = com.typewritermc.types.ParameterKey(boxId, 0)
        val box =
            TypeDefinition(
                boxId,
                parameters = listOf(com.typewritermc.types.TypeParameter(boxParameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(boxId, "value"), TypeTemplate.Parameter(boxParameter))),
                    ),
            )
        val treeId = TypeDefinitionId(TypeId.Qualified("test", "DefaultTree"), 1)
        val treeParameter = com.typewritermc.types.ParameterKey(treeId, 0)
        val tree =
            TypeDefinition(
                treeId,
                parameters = listOf(com.typewritermc.types.TypeParameter(treeParameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(FieldOwner(treeId, "value"), TypeTemplate.Parameter(treeParameter)),
                            FieldDeclaration(
                                FieldOwner(treeId, "children"),
                                TypeTemplate.Named(
                                    StandardTypes.list,
                                    listOf(TypeTemplate.Named(treeId, listOf(TypeTemplate.Parameter(treeParameter)))),
                                ),
                            ),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + listOf(box, tree))
        val runtime = DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList()))
        val text = TypeUse.Scalar(ScalarKind.Text)
        val innerBox = TypeUse.Named(boxId, listOf(text))

        val boxed =
            runtime.prepareNow(
                recordRequest(
                    InitializationRequestId("finite box"),
                    generation,
                    TypeSelection.Complete(TypeUse.Named(boxId, listOf(innerBox))),
                    emptyMap(),
                    "intent",
                ),
            )
        boxed.findings shouldBe emptyList()
        boxed.record.fields.getValue("value") shouldBe
            DataValue.Named(innerBox, DataValue.Record(mapOf("value" to DataValue.StringValue(""))))

        val treeUse = TypeUse.Named(treeId, listOf(text))
        val preparedTree =
            runtime.prepareNow(
                recordRequest(
                    InitializationRequestId("finite tree"),
                    generation,
                    TypeSelection.Complete(treeUse),
                    emptyMap(),
                    "intent",
                ),
            )
        preparedTree.findings shouldBe emptyList()
        preparedTree.record.fields shouldBe
            mapOf(
                "value" to DataValue.StringValue(""),
                "children" to
                    DataValue.Named(
                        TypeUse.Named(StandardTypes.list, listOf(treeUse)),
                        DataValue.ListValue(emptyList()),
                    ),
            )
    }

    test("startup planning captures dependencies once before their owners") {
        val generation = CatalogGeneration("startup plan catalog")
        val childDefinition =
            TypeDefinition(
                CHILD_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(CHILD_REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                CHILD_DEFAULT_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val parentDefinition =
            TypeDefinition(
                PARENT_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(PARENT_CHILD_OWNER, TypeTemplate.Named(CHILD_ID))),
                    ),
            )
        val definitions = listOf(parentDefinition, childDefinition)
        val catalog = DefaultCheckedCatalog(generation, definitions)
        val childPlan = ChildPlan()
        val bindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(childPlan, CHILD_ID)))

        val plan = InitializationCatalogPlanner(catalog, bindings).plan(definitions, emptyMap())
        val prepared =
            DefaultInitializationRuntime(catalog, bindings, plan.descriptors).prepareNow(
                recordRequest(
                    InitializationRequestId("planned nested defaults"),
                    generation,
                    TypeSelection.Complete(TypeUse.Named(PARENT_ID)),
                    emptyMap(),
                    "intent",
                ),
            )

        plan.descriptors.map { it.definition } shouldBe listOf(CHILD_ID, PARENT_ID)
        plan.descriptors
            .first()
            .captured
            .single { it.field == CHILD_DEFAULT_OWNER }
            .value shouldBe
            DataValue.Integer(java.math.BigInteger.valueOf(7))
        prepared.record.fields.getValue("child") shouldBe
            DataValue.Named(
                TypeUse.Named(CHILD_ID),
                DataValue.Record(
                    mapOf(
                        "required" to DataValue.StringValue(""),
                        "defaulted" to DataValue.Integer(java.math.BigInteger.valueOf(7)),
                    ),
                ),
            )
        childPlan.samples shouldBe 1
    }

    test("explicit startup parents retain dynamic children while inferred parents remain dynamic") {
        val generation = CatalogGeneration("nested mode boundary")
        val childDefinition =
            TypeDefinition(
                CHILD_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(CHILD_REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                CHILD_DEFAULT_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val parentDefinition =
            TypeDefinition(
                PARENT_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(PARENT_CHILD_OWNER, TypeTemplate.Named(CHILD_ID))),
                    ),
            )
        val definitions = listOf(parentDefinition, childDefinition)
        val catalog = DefaultCheckedCatalog(generation, definitions)

        val startupChildPlan = ChangingChildPlan()
        val startupBindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(startupChildPlan, CHILD_ID)))
        val startupPlan =
            InitializationCatalogPlanner(catalog, startupBindings).plan(
                definitions,
                mapOf(
                    CHILD_ID to com.typewritermc.configuration.InitializationPreference.Creation,
                    PARENT_ID to com.typewritermc.configuration.InitializationPreference.Startup,
                ),
            )
        val startupRuntime = DefaultInitializationRuntime(catalog, startupBindings, startupPlan.descriptors)
        val startupFirst = startupRuntime.prepareNow(parentRequest("startup first", generation))
        val startupSecond = startupRuntime.prepareNow(parentRequest("startup second", generation))

        startupPlan.descriptors.single { it.definition == PARENT_ID }.mode shouldBe
            com.typewritermc.authoring.InitializationMode.Startup
        startupFirst.record.fields.getValue("child") shouldBe startupSecond.record.fields.getValue("child")
        startupChildPlan.samples shouldBe 1

        val dynamicChildPlan = ChangingChildPlan()
        val dynamicBindings = FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(dynamicChildPlan, CHILD_ID)))
        val dynamicPlan =
            InitializationCatalogPlanner(catalog, dynamicBindings).plan(
                definitions,
                mapOf(CHILD_ID to com.typewritermc.configuration.InitializationPreference.Creation),
            )
        val dynamicRuntime = DefaultInitializationRuntime(catalog, dynamicBindings, dynamicPlan.descriptors)
        val dynamicFirst = dynamicRuntime.prepareNow(parentRequest("dynamic first", generation))
        val dynamicSecond = dynamicRuntime.prepareNow(parentRequest("dynamic second", generation))

        dynamicPlan.descriptors.single { it.definition == PARENT_ID }.mode shouldBe
            com.typewritermc.authoring.InitializationMode.Creation
        (dynamicFirst.record.fields.getValue("child") == dynamicSecond.record.fields.getValue("child")) shouldBe false
        dynamicChildPlan.samples shouldBe 2
    }

    test("forced generic child requirements reject an explicit startup parent") {
        val generation = CatalogGeneration("forced generic mode boundary")
        val child = TypeDefinitionId(TypeId.Qualified("test", "GenericDynamicChild"), 1)
        val parameter = com.typewritermc.types.ParameterKey(child, 0)
        val defaulted = FieldOwner(child, "defaulted")
        val parent = TypeDefinitionId(TypeId.Qualified("test", "ForcedGenericParent"), 1)
        val definitions =
            listOf(
                TypeDefinition(
                    parent,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(
                                    FieldOwner(parent, "child"),
                                    TypeTemplate.Named(child, listOf(TypeTemplate.Scalar(ScalarKind.Text))),
                                ),
                            ),
                        ),
                ),
                TypeDefinition(
                    child,
                    parameters = listOf(com.typewritermc.types.TypeParameter(parameter, "T")),
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(
                                    defaulted,
                                    TypeTemplate.Parameter(parameter),
                                    hasConstructorDefault = true,
                                ),
                            ),
                        ),
                ),
            )
        val catalog = DefaultCheckedCatalog(generation, definitions)
        val plan =
            InitializationCatalogPlanner(catalog, FactoryNativeBindingRegistry(catalog, emptyList())).plan(
                definitions,
                mapOf(parent to com.typewritermc.configuration.InitializationPreference.Startup),
            )

        plan.descriptors.any { it.definition == parent } shouldBe false
        plan.diagnostics
            .getValue(parent)
            .single()
            .code shouldBe "forced_creation_conflicts_with_startup"
    }

    test("startup planning preserves failure details and cancellation") {
        val generation = CatalogGeneration("startup failure catalog")
        val definition =
            TypeDefinition(
                INITIALIZED_ID,
                representation =
                    RepresentationTemplate.Record(
                        listOf(
                            FieldDeclaration(REQUIRED_OWNER, TypeTemplate.Scalar(ScalarKind.Text)),
                            FieldDeclaration(
                                DEFAULTED_OWNER,
                                TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32)),
                                hasConstructorDefault = true,
                            ),
                        ),
                    ),
            )
        val catalog = DefaultCheckedCatalog(generation, listOf(definition))
        val failed =
            InitializationCatalogPlanner(
                catalog,
                FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(ThrowingPlan(IllegalStateException("broken default"))))),
            ).plan(listOf(definition), emptyMap())

        failed.descriptors
            .single()
            .diagnostics
            .single()
            .message shouldBe "broken default"

        val cancelled =
            InitializationCatalogPlanner(
                catalog,
                FactoryNativeBindingRegistry(
                    catalog,
                    listOf(PlanFactory(ThrowingPlan(kotlinx.coroutines.CancellationException("cancel capture")))),
                ),
            )
        shouldThrow<kotlinx.coroutines.CancellationException> {
            cancelled.plan(listOf(definition), emptyMap())
        }
    }
}

private class CapturingPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)
    var sampled: Map<FieldOwner, CompleteValue> = emptyMap()

    override fun sample(
        arguments: AppliedNativeArguments,
        requiredInputs: SamplingInputs,
    ): CaptureResult {
        sampled = requiredInputs.required
        return CaptureResult.Captured(mapOf(DEFAULTED_OWNER to DataValue.Integer(java.math.BigInteger.valueOf(3))))
    }
}

private class FailingPlan(
    private val diagnostic: InitializationDiagnostic,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)

    override fun sample(
        arguments: AppliedNativeArguments,
        requiredInputs: SamplingInputs,
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
        requiredInputs: SamplingInputs,
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
        requiredInputs: SamplingInputs,
    ): CaptureResult {
        sampled = requiredInputs.required
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
        requiredInputs: SamplingInputs,
    ): CaptureResult {
        samples++
        return CaptureResult.Captured(
            mapOf(CHILD_DEFAULT_OWNER to DataValue.Integer(java.math.BigInteger.valueOf(7))),
        )
    }
}

private class ChangingChildPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(CHILD_DEFAULT_OWNER)
    var samples = 0

    override fun sample(
        arguments: AppliedNativeArguments,
        requiredInputs: SamplingInputs,
    ): CaptureResult {
        samples++
        return CaptureResult.Captured(
            mapOf(CHILD_DEFAULT_OWNER to DataValue.Integer(samples.toBigInteger())),
        )
    }
}

private class ThrowingPlan(
    private val failure: RuntimeException,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)

    override fun sample(
        arguments: AppliedNativeArguments,
        requiredInputs: SamplingInputs,
    ): CaptureResult = throw failure
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

private val INITIALIZED_ID = TypeDefinitionId(TypeId.Qualified("test", "Initialized"), 1)
private val INITIALIZED_USE = TypeUse.Named(INITIALIZED_ID, emptyList())
private val REQUIRED_OWNER = FieldOwner(INITIALIZED_ID, "required")
private val DEFAULTED_OWNER = FieldOwner(INITIALIZED_ID, "defaulted")
private val ABSTRACT_ID = TypeDefinitionId(TypeId.Qualified("test", "AbstractInput"), 1)
private val CONCRETE_ID = TypeDefinitionId(TypeId.Qualified("test", "ConcreteInput"), 1)
private val CONCRETE_VALUE_OWNER = FieldOwner(CONCRETE_ID, "value")
private val ABSTRACT_OWNER_ID = TypeDefinitionId(TypeId.Qualified("test", "AbstractOwner"), 1)
private val ABSTRACT_INPUT_OWNER = FieldOwner(ABSTRACT_OWNER_ID, "input")
private val ABSTRACT_DEFAULT_OWNER = FieldOwner(ABSTRACT_OWNER_ID, "defaulted")
private val CHILD_ID = TypeDefinitionId(TypeId.Qualified("test", "Child"), 1)
private val CHILD_REQUIRED_OWNER = FieldOwner(CHILD_ID, "required")
private val CHILD_DEFAULT_OWNER = FieldOwner(CHILD_ID, "defaulted")
private val PARENT_ID = TypeDefinitionId(TypeId.Qualified("test", "Parent"), 1)
private val PARENT_CHILD_OWNER = FieldOwner(PARENT_ID, "child")

private val PreparedValue.record
    get() = (content as PreparedContent.Record).record

private fun recordRequest(
    id: InitializationRequestId,
    generation: CatalogGeneration,
    selection: TypeSelection,
    supplied: Map<String, DataValue>,
    intentHash: String,
) = InitializationRequest(
    id = id,
    catalog = generation,
    target = PreparationTarget.Record(selection),
    supplied = DataValue.Record(supplied),
    intentHash = intentHash,
)

private fun parentRequest(
    id: String,
    generation: CatalogGeneration,
): InitializationRequest =
    recordRequest(
        InitializationRequestId(id),
        generation,
        TypeSelection.Complete(TypeUse.Named(PARENT_ID)),
        emptyMap(),
        id,
    )
