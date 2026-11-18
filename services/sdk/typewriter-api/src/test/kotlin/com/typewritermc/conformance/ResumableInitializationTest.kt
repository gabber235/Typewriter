package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.materialize
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.template
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.InputAnswer
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.RequiredInput
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValuePath

val ResumableInitializationTest by testSuite {
    test("required references are reported in a record without constructor defaults") {
        val fixture = resumeFixture()
        val step = fixture.runtime.stepNow(PreparationOperation.StartWrapper(fixture.request)) as PrepareValueResult.NeedsInputWrapper
        step.value.requiredInputs shouldBe listOf(RequiredInput(path = path("settings", "target"), expected = LINK_USE.use))
        val ready =
            fixture.runtime.stepNow(
                PreparationOperation.createResume(
                    draft = step.value,
                    answers = listOf(InputAnswer(path = path("settings", "target"), value = reference())),
                ),
            ) as PrepareValueResult.ReadyWrapper
        ready.value.findings shouldBe emptyList()
    }
    test("a nested default waits for its required input and is captured on resume while the earlier capture is kept") {
        val fixture = resumeFixture(defaultedSettings = true)
        val first = fixture.runtime.stepNow(PreparationOperation.StartWrapper(fixture.request)) as PrepareValueResult.NeedsInputWrapper
        val unchanged = fixture.runtime.stepNow(PreparationOperation.createResume(draft = first.value, answers = emptyList()))
        val resumed =
            fixture.runtime.stepNow(
                PreparationOperation.createResume(
                    draft = first.value,
                    answers = listOf(InputAnswer(path = path("settings", "target"), value = reference())),
                ),
            ) as PrepareValueResult.ReadyWrapper
        val fields = (resumed.value.content as PreparedContent.RecordWrapper).value.fieldMap

        first.value.pendingDefaults shouldBe setOf(path("settings", "label"))
        unchanged shouldBe first
        ((fields.getValue("marker") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper).field("id") shouldBe
            DataValue.StringValueWrapper("capture:1")
        ((fields.getValue("settings") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper).field("label") shouldBe
            DataValue.StringValueWrapper("capture:1")
        resumed.value.findings shouldBe emptyList()
    }

    test("nested reference answers preserve list and map item identity") {
        val root = id("Collections")
        val nested = id("CollectionSettings")
        val list = id("SettingsList")
        val mapping = id("SettingsMap")
        val nestedUse = nested.namedUse(emptyList())
        val listUse = list.namedUse(emptyList())
        val mapUse = mapping.namedUse(emptyList())
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    resourceDefinition(),
                    linkDefinition(),
                    TypeDefinition.partial(
                        id = nested,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = nested, name = "target"),
                                            type = LINK_USE.template(),
                                        ),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = list,
                        representation =
                            RepresentationTemplate.createSequence(
                                item = nested.template(emptyList()),
                                kind = CollectionKind.LIST,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = mapping,
                        representation =
                            RepresentationTemplate.createMapping(
                                key = ScalarKind.TEXT.template,
                                value = nested.template(emptyList()),
                            ),
                    ),
                    TypeDefinition.partial(
                        id = root,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = root, name = "items"),
                                            type = list.template(emptyList()),
                                        ),
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = root, name = "mapping"),
                                            type = mapping.template(emptyList()),
                                        ),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                ),
            )
        val listItem = ItemId(value = "list-item")
        val mapItem = ItemId(value = "map-item")
        val value = DataValue.named(nestedUse, DataValue.record(mapOf("target" to DataValue.UNFILLED)))
        val supplied =
            DataValue.record(
                mapOf(
                    "items" to DataValue.named(listUse, DataValue.listValue(listOf(ListItem(id = listItem, value = value)))),
                    "mapping" to
                        DataValue.named(
                            mapUse,
                            DataValue.mapValue(listOf(MapRow(id = mapItem, key = DataValue.StringValueWrapper("key"), value = value))),
                        ),
                ),
            )
        val runtime = DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList()))
        val first =
            runtime.stepNow(
                PreparationOperation.StartWrapper(request(root).copy(suppliedValue = supplied)),
            ) as PrepareValueResult.NeedsInputWrapper
        val listPath =
            ValuePath(
                segments =
                    path("items").segments + PathSegment.createItem(id = listItem) + PathSegment.createField(name = "target"),
            )
        val mapPath =
            ValuePath(
                segments =
                    path("mapping").segments + PathSegment.createItem(id = mapItem) + PathSegment.MAP_VALUE +
                        PathSegment.createField(name = "target"),
            )
        first.value.requiredInputs
            .map { it.path }
            .toSet() shouldBe setOf(listPath, mapPath)
        val ready =
            runtime.stepNow(
                PreparationOperation.createResume(
                    draft = first.value,
                    answers =
                        listOf(
                            InputAnswer(path = listPath, value = reference()),
                            InputAnswer(path = mapPath, value = reference()),
                        ),
                ),
            ) as PrepareValueResult.ReadyWrapper
        val record = (ready.value.content as PreparedContent.RecordWrapper).value
        val items = ((record.fieldMap.getValue("items") as DataValue.NamedWrapper).payload as DataValue.ListValueWrapper).items
        items.single().id shouldBe listItem
        val rows = ((record.fieldMap.getValue("mapping") as DataValue.NamedWrapper).payload as DataValue.MapValueWrapper).rows
        rows.single().id shouldBe mapItem
    }
    val rejectedResume =
        run {
            val fixture = resumeFixture(defaultedSettings = true)
            val first =
                (
                    fixture.runtime.stepNow(
                        PreparationOperation.StartWrapper(fixture.request),
                    ) as PrepareValueResult.NeedsInputWrapper
                ).value
            val answer = InputAnswer(path = path("settings", "target"), value = reference())
            mapOf(
                "a duplicate answer" to PreparationOperation.createResume(draft = first, answers = listOf(answer, answer)),
                "an answer for an absent path" to
                    PreparationOperation.createResume(
                        draft = first,
                        answers = listOf(InputAnswer(path = path("absent"), value = reference())),
                    ),
                "an answer of the wrong type" to
                    PreparationOperation.createResume(
                        draft = first,
                        answers = listOf(InputAnswer(path = answer.path, value = DataValue.StringValueWrapper("wrong"))),
                    ),
                "a forged pending default" to
                    PreparationOperation.createResume(draft = first.copy(pendingDefaults = setOf(answer.path)), answers = listOf(answer)),
                "a draft from another catalog generation" to
                    PreparationOperation.createResume(
                        draft = first.copy(catalog = CatalogGeneration(value = "old")),
                        answers = listOf(answer),
                    ),
            ).mapValues { (_, operation) -> fixture.runtime.stepNow(operation) }
        }

    mapOf(
        "a duplicate answer" to "invalid_preparation_continuation: An input was answered more than once.",
        "an answer for an absent path" to "invalid_preparation_continuation: The answer does not belong to a pending input.",
        "an answer of the wrong type" to "invalid_preparation_continuation: The answer does not match its applied type.",
        "a forged pending default" to "invalid_preparation_continuation: A pending default is not an omitted constructor field.",
        "a draft from another catalog generation" to "invalid_preparation_continuation: The preparation catalog changed.",
    ).forEach { (case, expected) ->
        test("resuming with $case is refused") {
            val refused = rejectedResume.getValue(case).shouldBeInstanceOf<PrepareValueResult.UnavailableErrorWrapper>()

            refused.value.findings.map { "${it.code}: ${it.message}" } shouldBe listOf(expected)
        }
    }

    test("an abstract required record can choose a concrete type and discover its nested reference") {
        val abstractId = id("Abstract")
        val concreteId = id("Concrete")
        val ownerId = id("Owner")
        val concreteUse = concreteId.namedUse(emptyList())
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    resourceDefinition(),
                    linkDefinition(),
                    TypeDefinition.partial(
                        id = abstractId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
                    ),
                    TypeDefinition.partial(
                        id = concreteId,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = concreteId, name = "target"),
                                            type = LINK_USE.template(),
                                        ),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                        parents = listOf(abstractId.namedTemplate(emptyList())),
                    ),
                    TypeDefinition.partial(
                        id = ownerId,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(
                                            owner = FieldOwner(definition = ownerId, name = "choice"),
                                            type = abstractId.template(emptyList()),
                                        ),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                ),
            )
        val runtime = DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList()))
        val start = runtime.stepNow(PreparationOperation.StartWrapper(request(ownerId))) as PrepareValueResult.NeedsInputWrapper
        start.value.requiredInputs
            .single()
            .path shouldBe path("choice")
        val next =
            runtime.stepNow(
                PreparationOperation.createResume(
                    draft = start.value,
                    answers =
                        listOf(
                            InputAnswer(path = path("choice"), value = DataValue.named(concreteUse, DataValue.record(emptyMap()))),
                        ),
                ),
            ) as PrepareValueResult.NeedsInputWrapper
        next.value.requiredInputs shouldBe listOf(RequiredInput(path = path("choice", "target"), expected = LINK_USE.use))
        val ready =
            runtime.stepNow(
                PreparationOperation.createResume(
                    draft = next.value,
                    answers = listOf(InputAnswer(path = path("choice", "target"), value = reference())),
                ),
            ) as PrepareValueResult.ReadyWrapper
        (ready.value.content as PreparedContent.RecordWrapper).value.fieldMap shouldBe
            mapOf("choice" to DataValue.named(concreteUse, DataValue.record(mapOf("target" to reference()))))
        ready.value.findings shouldBe emptyList()
    }
    test("ordinary preparation keeps a default that waits for a required input unfinished") {
        val fixture = resumeFixture(defaultedSettings = true)

        fixture.runtime
            .prepareNow(fixture.request)
            .findings
            .map { it.code } shouldBe listOf("unfinished_constructor_input")
    }

    test("a failed capture still materializes the fields it could prepare and reports the failure") {
        val failing = resumeFixture(failMarker = true)
        val unavailable =
            failing.runtime.stepNow(
                PreparationOperation.StartWrapper(failing.request),
            ) as PrepareValueResult.UnavailableErrorWrapper

        val fields = (unavailable.materialize().content as PreparedContent.RecordWrapper).value.fieldMap

        fields.keys shouldBe setOf("settings", "marker")
        ((fields.getValue("marker") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper).field("id") shouldBe DataValue.UNFILLED
        unavailable.value.findings.map { it.code } shouldBe listOf("test_capture_failed")
    }

    test("a valid default reference is retained without an input prompt") {
        val referenceId = id("DefaultReference")
        val field = FieldOwner(definition = referenceId, name = "target")
        val plan = SamplingPlan(field, value = reference())
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    resourceDefinition(),
                    linkDefinition(),
                    TypeDefinition.partial(
                        id = referenceId,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        FieldDeclaration.partial(owner = field, type = LINK_USE.template(), hasConstructorDefault = true),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                ),
            )
        val runtime =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(plan, referenceId))))
        val ready = runtime.stepNow(PreparationOperation.StartWrapper(request(referenceId))) as PrepareValueResult.ReadyWrapper
        ((ready.value.content as PreparedContent.RecordWrapper).value.fieldMap.getValue("target")) shouldBe reference()
    }
}
