package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.materialize
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
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
import com.typewritermc.types.requireValid
import com.typewritermc.types.rows
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
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
    test("nested pending defaults resume while unrelated captures remain frozen") {
        val fixture = resumeFixture(defaultedSettings = true)
        val first = fixture.runtime.stepNow(PreparationOperation.StartWrapper(fixture.request)) as PrepareValueResult.NeedsInputWrapper
        fixture.marker.calls shouldBe 1
        fixture.settings.calls shouldBe 0
        first.value.pendingDefaults shouldBe setOf(path("settings", "label"))
        val unchanged =
            fixture.runtime.stepNow(
                PreparationOperation.createResume(draft = first.value, answers = emptyList()),
            ) as PrepareValueResult.NeedsInputWrapper
        unchanged.value shouldBe first.value
        fixture.marker.calls shouldBe 1
        fixture.settings.calls shouldBe 0
        val resumed =
            fixture.runtime.stepNow(
                PreparationOperation.createResume(
                    draft = first.value,
                    answers = listOf(InputAnswer(path = path("settings", "target"), value = reference())),
                ),
            ) as PrepareValueResult.ReadyWrapper
        fixture.marker.calls shouldBe 1
        fixture.settings.calls shouldBe 1
        val fields = (resumed.value.content as PreparedContent.RecordWrapper).value.fieldMap
        val marker = (fields.getValue("marker") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper
        marker.field("id") shouldBe DataValue.StringValueWrapper("capture:1")
        val settings = (fields.getValue("settings") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper
        settings.field("label") shouldBe DataValue.StringValueWrapper("capture:1")
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
                                abstract_ = false,
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
                                abstract_ = false,
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
    test("continuations and answers round trip through the current wire") {
        val fixture = resumeFixture(defaultedSettings = true)
        val step = fixture.runtime.stepNow(PreparationOperation.StartWrapper(fixture.request))
        PrepareValueResult.serializer.fromBytes(PrepareValueResult.serializer.toBytes(step).toByteArray()) shouldBe step
        val draft = (step as PrepareValueResult.NeedsInputWrapper).value
        val operation =
            PreparationOperation.createResume(
                draft = draft,
                answers = listOf(InputAnswer(path = path("settings", "target"), value = reference())),
            )
        PreparationOperation.serializer
            .fromBytes(PreparationOperation.serializer.toBytes(operation).toByteArray())
            .requireValid() shouldBe operation
    }
    test("invalid paths, duplicate answers and forged pending defaults are rejected without capture") {
        val fixture = resumeFixture(defaultedSettings = true)
        val first = fixture.runtime.stepNow(PreparationOperation.StartWrapper(fixture.request)) as PrepareValueResult.NeedsInputWrapper
        val answer = InputAnswer(path = path("settings", "target"), value = reference())
        val invalidOperations =
            listOf(
                PreparationOperation.createResume(draft = first.value, answers = listOf(answer, answer)),
                PreparationOperation.createResume(
                    draft = first.value,
                    answers = listOf(InputAnswer(path = path("absent"), value = reference())),
                ),
                PreparationOperation.createResume(
                    draft = first.value,
                    answers = listOf(InputAnswer(path = answer.path, value = DataValue.StringValueWrapper("wrong"))),
                ),
                PreparationOperation.createResume(draft = first.value.copy(pendingDefaults = setOf(answer.path)), answers = listOf(answer)),
                PreparationOperation.createResume(
                    draft = first.value.copy(catalog = CatalogGeneration(value = "old")),
                    answers = listOf(answer),
                ),
            )
        invalidOperations.forEach {
            (fixture.runtime.stepNow(it) is PrepareValueResult.UnavailableErrorWrapper) shouldBe true
        }
        fixture.settings.calls shouldBe 0
        fixture.marker.calls shouldBe 1
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
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
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
                                abstract_ = false,
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
                                abstract_ = false,
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
        (
            runtime.stepNow(
                PreparationOperation.createResume(
                    draft = next.value,
                    answers = listOf(InputAnswer(path = path("choice", "target"), value = reference())),
                ),
            ) is PrepareValueResult.ReadyWrapper
        ) shouldBe
            true
    }
    test("ordinary editing preserves incomplete fields and capture failures") {
        val fixture = resumeFixture(defaultedSettings = true)
        val ordinary = fixture.runtime.prepareNow(fixture.request)
        ordinary.findings.any { it.code == "unfinished_constructor_input" } shouldBe true
        val failing = resumeFixture(failMarker = true)
        val unavailable =
            failing.runtime.stepNow(
                PreparationOperation.StartWrapper(failing.request),
            ) as PrepareValueResult.UnavailableErrorWrapper
        val content = (unavailable.materialize().content as PreparedContent.RecordWrapper).value.fieldMap
        content.keys shouldBe setOf("settings", "marker")
        unavailable.value.findings.any { it.code == "test_capture_failed" } shouldBe true
    }
    test("a valid default reference is retained without an input prompt") {
        val referenceId = id("DefaultReference")
        val field = FieldOwner(definition = referenceId, name = "target")
        val plan = CountingPlan(field, value = reference())
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
                                abstract_ = false,
                            ),
                    ),
                ),
            )
        val runtime =
            DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, listOf(ResumePlanFactory(referenceId, plan))))
        val ready = runtime.stepNow(PreparationOperation.StartWrapper(request(referenceId))) as PrepareValueResult.ReadyWrapper
        ((ready.value.content as PreparedContent.RecordWrapper).value.fieldMap.getValue("target")) shouldBe reference()
        plan.calls shouldBe 1
    }
}

private data class ResumeFixture(
    val runtime: DefaultInitializationRuntime,
    val request: ValuePreparationRequest,
    val marker: CountingPlan,
    val settings: CountingPlan,
)

private fun resumeFixture(
    defaultedSettings: Boolean = false,
    failMarker: Boolean = false,
): ResumeFixture {
    val root = id("Root")
    val settings = id("Settings")
    val marker = id("Marker")
    val markerPlan = CountingPlan(FieldOwner(definition = marker, name = "id"), fail = failMarker)
    val settingsPlan = CountingPlan(FieldOwner(definition = settings, name = "label"))
    val settingsFields =
        buildList {
            add(
                FieldDeclaration.partial(owner = FieldOwner(definition = settings, name = "target"), type = LINK_USE.template()),
            )
            if (defaultedSettings) {
                add(
                    FieldDeclaration.partial(
                        owner = FieldOwner(definition = settings, name = "label"),
                        type = ScalarKind.TEXT.template,
                        hasConstructorDefault = true,
                    ),
                )
            }
        }
    val catalog =
        DefaultCheckedCatalog(
            GENERATION,
            listOf(
                resourceDefinition(),
                linkDefinition(),
                TypeDefinition.partial(
                    id = root,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = root, name = "settings"),
                                        type = settings.template(emptyList()),
                                    ),
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = root, name = "marker"),
                                        type = marker.template(emptyList()),
                                    ),
                                ),
                            abstract_ = false,
                        ),
                ),
                TypeDefinition.partial(
                    id = settings,
                    representation = RepresentationTemplate.createRecord(fields = settingsFields, abstract_ = false),
                ),
                TypeDefinition.partial(
                    id = marker,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = marker, name = "id"),
                                        type = ScalarKind.TEXT.template,
                                        hasConstructorDefault = true,
                                    ),
                                ),
                            abstract_ = false,
                        ),
                ),
            ),
        )
    val factories =
        buildList {
            add(ResumePlanFactory(marker, markerPlan))
            if (defaultedSettings) add(ResumePlanFactory(settings, settingsPlan))
        }
    return ResumeFixture(
        DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, factories)),
        request(root),
        markerPlan,
        settingsPlan,
    )
}

private class CountingPlan(
    val field: FieldOwner,
    val fail: Boolean = false,
    val value: DataValue? = null,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(field)
    var calls = 0

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        calls++
        return if (fail) {
            CaptureResult.Unavailable(
                listOf(
                    InitializationDiagnostic(field = field, code = "test_capture_failed", message = "Capture failed.", relativePath = null),
                ),
            )
        } else {
            CaptureResult.Captured(mapOf(field to (value ?: DataValue.StringValueWrapper("capture:$calls"))))
        }
    }
}

private class ResumePlanFactory(
    override val definition: TypeDefinitionId,
    override val constructionPlan: NativeConstructionPlan,
) : NativeBindingFactory {
    override val provider = NativeBindingId(value = "test.resume")

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> = error("Preparation does not decode complete records.")
}

private val GENERATION = CatalogGeneration(value = "resume")
private val RESOURCE_ID = id("Resource")
private val LINK_ID = id("Reference")
private val LINK_USE = LINK_ID.namedUse(emptyList())
private val ENDPOINT = EndpointId(value = "required-reference")

private fun id(name: String) = TypeDefinitionId.qualified("test.resume", name)

private fun NamedTypeUse.template() = definition.template(emptyList())

private fun resourceDefinition() =
    TypeDefinition.partial(id = RESOURCE_ID, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false))

private fun linkDefinition() =
    TypeDefinition.partial(
        id = LINK_ID,
        representation = RepresentationTemplate.createLink(endpoint = ENDPOINT, target = RESOURCE_ID.template(emptyList())),
    )

private fun request(id: TypeDefinitionId) =
    ValuePreparationRequest(
        catalog = GENERATION,
        target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(id.namedUse(emptyList()))),
        suppliedValue = DataValue.record(emptyMap()),
    )

private fun path(vararg fields: String) = ValuePath(segments = fields.map { PathSegment.createField(name = it) })

private fun reference() =
    DataValue.named(
        LINK_USE,
        DataValue.createLink(endpoint = ENDPOINT, target = LinkTarget(resource = ResourceId("reserved-target").toSkir(), opposite = null)),
    )
