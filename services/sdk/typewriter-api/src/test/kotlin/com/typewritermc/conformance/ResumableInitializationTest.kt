package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationDiagnostic
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InputAnswer
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparationOperation
import com.typewritermc.authoring.PreparationStep
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.RequiredInput
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.materialize
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.link
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

val ResumableInitializationTest by testSuite {
    test("required references are reported in a record without constructor defaults") {
        val fixture = resumeFixture()
        val step = fixture.runtime.stepNow(PreparationOperation.Start(fixture.request)) as PreparationStep.NeedsInput
        step.draft.requiredInputs shouldBe listOf(RequiredInput(path("settings", "target"), LINK_USE.use))
        val ready =
            fixture.runtime.stepNow(
                PreparationOperation.Resume(step.draft, listOf(InputAnswer(path("settings", "target"), reference()))),
            ) as PreparationStep.Ready
        ready.value.findings shouldBe emptyList()
    }
    test("nested pending defaults resume while unrelated captures remain frozen") {
        val fixture = resumeFixture(defaultedSettings = true)
        val first = fixture.runtime.stepNow(PreparationOperation.Start(fixture.request)) as PreparationStep.NeedsInput
        fixture.marker.calls shouldBe 1
        fixture.settings.calls shouldBe 0
        first.draft.pendingDefaults shouldBe setOf(path("settings", "label"))
        val unchanged = fixture.runtime.stepNow(PreparationOperation.Resume(first.draft, emptyList())) as PreparationStep.NeedsInput
        unchanged.draft shouldBe first.draft
        fixture.marker.calls shouldBe 1
        fixture.settings.calls shouldBe 0
        val resumed =
            fixture.runtime.stepNow(
                PreparationOperation.Resume(first.draft, listOf(InputAnswer(path("settings", "target"), reference()))),
            ) as PreparationStep.Ready
        fixture.marker.calls shouldBe 1
        fixture.settings.calls shouldBe 1
        val fields = (resumed.value.content as PreparedContent.Record).record.fields
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
        val first = runtime.stepNow(PreparationOperation.Start(request(root).copy(supplied = supplied))) as PreparationStep.NeedsInput
        val listPath = ValuePath(path("items").segments + PathSegment.Item(listItem) + PathSegment.Field("target"))
        val mapPath = ValuePath(path("mapping").segments + PathSegment.Item(mapItem) + PathSegment.MapValue + PathSegment.Field("target"))
        first.draft.requiredInputs
            .map { it.path }
            .toSet() shouldBe setOf(listPath, mapPath)
        val ready =
            runtime.stepNow(
                PreparationOperation.Resume(
                    first.draft,
                    listOf(
                        InputAnswer(listPath, reference()),
                        InputAnswer(mapPath, reference()),
                    ),
                ),
            ) as PreparationStep.Ready
        val record = (ready.value.content as PreparedContent.Record).record
        val items = ((record.fields.getValue("items") as DataValue.NamedWrapper).payload as DataValue.ListValueWrapper).items
        items.single().id shouldBe listItem
        val rows = ((record.fields.getValue("mapping") as DataValue.NamedWrapper).payload as DataValue.MapValueWrapper).rows
        rows.single().id shouldBe mapItem
    }
    test("continuations and answers round trip through the current wire") {
        val fixture = resumeFixture(defaultedSettings = true)
        val step = fixture.runtime.stepNow(PreparationOperation.Start(fixture.request))
        SkirAuthoringOperationCodec.decode(SkirAuthoringOperationCodec.encode(step).getOrThrow()).getOrThrow() shouldBe step
        val draft = (step as PreparationStep.NeedsInput).draft
        val operation = PreparationOperation.Resume(draft, listOf(InputAnswer(path("settings", "target"), reference())))
        SkirAuthoringOperationCodec.decode(SkirAuthoringOperationCodec.encode(operation).getOrThrow()).getOrThrow() shouldBe operation
    }
    test("invalid paths, duplicate answers and forged pending defaults are rejected without capture") {
        val fixture = resumeFixture(defaultedSettings = true)
        val first = fixture.runtime.stepNow(PreparationOperation.Start(fixture.request)) as PreparationStep.NeedsInput
        val answer = InputAnswer(path("settings", "target"), reference())
        val invalidOperations =
            listOf(
                PreparationOperation.Resume(first.draft, listOf(answer, answer)),
                PreparationOperation.Resume(first.draft, listOf(InputAnswer(path("absent"), reference()))),
                PreparationOperation.Resume(first.draft, listOf(InputAnswer(answer.path, DataValue.StringValueWrapper("wrong")))),
                PreparationOperation.Resume(first.draft.copy(pendingDefaults = setOf(answer.path)), listOf(answer)),
                PreparationOperation.Resume(first.draft.copy(catalog = CatalogGeneration("old")), listOf(answer)),
            )
        invalidOperations.forEach {
            (fixture.runtime.stepNow(it) is PreparationStep.Unavailable) shouldBe true
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
        val start = runtime.stepNow(PreparationOperation.Start(request(ownerId))) as PreparationStep.NeedsInput
        start.draft.requiredInputs
            .single()
            .path shouldBe path("choice")
        val next =
            runtime.stepNow(
                PreparationOperation.Resume(
                    start.draft,
                    listOf(InputAnswer(path("choice"), DataValue.named(concreteUse, DataValue.record(emptyMap())))),
                ),
            ) as PreparationStep.NeedsInput
        next.draft.requiredInputs shouldBe listOf(RequiredInput(path("choice", "target"), LINK_USE.use))
        (
            runtime.stepNow(
                PreparationOperation.Resume(next.draft, listOf(InputAnswer(path("choice", "target"), reference()))),
            ) is PreparationStep.Ready
        ) shouldBe
            true
    }
    test("ordinary editing preserves incomplete fields and capture failures") {
        val fixture = resumeFixture(defaultedSettings = true)
        val ordinary = fixture.runtime.prepareNow(fixture.request)
        ordinary.findings.any { it.code == "unfinished_constructor_input" } shouldBe true
        val failing = resumeFixture(failMarker = true)
        val unavailable = failing.runtime.stepNow(PreparationOperation.Start(failing.request)) as PreparationStep.Unavailable
        val content = (unavailable.materialize().content as PreparedContent.Record).record.fields
        content.keys shouldBe setOf("settings", "marker")
        unavailable.draft.findings.any { it.code == "test_capture_failed" } shouldBe true
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
        val ready = runtime.stepNow(PreparationOperation.Start(request(referenceId))) as PreparationStep.Ready
        ((ready.value.content as PreparedContent.Record).record.fields.getValue("target")) shouldBe reference()
        plan.calls shouldBe 1
    }
}

private data class ResumeFixture(
    val runtime: DefaultInitializationRuntime,
    val request: InitializationRequest,
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
            CaptureResult.Unavailable(listOf(InitializationDiagnostic(field, "test_capture_failed", "Capture failed.")))
        } else {
            CaptureResult.Captured(mapOf(field to (value ?: DataValue.StringValueWrapper("capture:$calls"))))
        }
    }
}

private class ResumePlanFactory(
    override val definition: TypeDefinitionId,
    override val constructionPlan: NativeConstructionPlan,
) : NativeBindingFactory {
    override val provider = NativeBindingId("test.resume")

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> = error("Preparation does not decode complete records.")
}

private val GENERATION = CatalogGeneration("resume")
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
    InitializationRequest(
        GENERATION,
        PreparationTarget.Record(TypeSelection.Complete(id.namedUse(emptyList()))),
        DataValue.record(emptyMap()),
    )

private fun path(vararg fields: String) = ValuePath(fields.map(PathSegment::Field))

private fun reference() = DataValue.named(LINK_USE, DataValue.link(ENDPOINT, LinkTarget(ResourceId("reserved-target"), null)))
