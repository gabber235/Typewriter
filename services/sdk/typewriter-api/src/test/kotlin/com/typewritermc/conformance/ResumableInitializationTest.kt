package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationDiagnostic
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InputAnswer
import com.typewritermc.authoring.ItemId
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
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointId
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ResumableInitializationTest by testSuite {
    test("required references are reported in a record without constructor defaults") {
        val fixture = resumeFixture()
        val step = fixture.runtime.stepNow(PreparationOperation.Start(fixture.request)) as PreparationStep.NeedsInput
        step.draft.requiredInputs shouldBe listOf(RequiredInput(path("settings", "target"), LINK_USE))
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
        val marker = (fields.getValue("marker") as DataValue.Named).payload as DataValue.Record
        marker.fields.getValue("id") shouldBe DataValue.StringValue("capture:1")
        val settings = (fields.getValue("settings") as DataValue.Named).payload as DataValue.Record
        settings.fields.getValue("label") shouldBe DataValue.StringValue("capture:1")
        resumed.value.findings shouldBe emptyList()
    }
    test("nested reference answers preserve list and map item identity") {
        val root = id("Collections")
        val nested = id("CollectionSettings")
        val list = id("SettingsList")
        val mapping = id("SettingsMap")
        val nestedUse = TypeUse.Named(nested, emptyList())
        val listUse = TypeUse.Named(list, emptyList())
        val mapUse = TypeUse.Named(mapping, emptyList())
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    resourceDefinition(),
                    linkDefinition(),
                    TypeDefinition(
                        nested,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(nested, "target"), LINK_USE.template()),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        list,
                        representation = RepresentationTemplate.Sequence(TypeTemplate.Named(nested, emptyList()), CollectionKind.List),
                    ),
                    TypeDefinition(
                        mapping,
                        representation =
                            RepresentationTemplate.Mapping(
                                TypeTemplate.Scalar(ScalarKind.Text),
                                TypeTemplate.Named(nested, emptyList()),
                            ),
                    ),
                    TypeDefinition(
                        root,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(root, "items"), TypeTemplate.Named(list, emptyList())),
                                    FieldDeclaration(FieldOwner(root, "mapping"), TypeTemplate.Named(mapping, emptyList())),
                                ),
                            ),
                    ),
                ),
            )
        val listItem = ItemId("list-item")
        val mapItem = ItemId("map-item")
        val value = DataValue.Named(nestedUse, DataValue.Record(mapOf("target" to DataValue.Unfilled)))
        val supplied =
            DataValue.Record(
                mapOf(
                    "items" to DataValue.Named(listUse, DataValue.ListValue(listOf(ListItem(listItem, value)))),
                    "mapping" to DataValue.Named(mapUse, DataValue.MapValue(listOf(MapRow(mapItem, DataValue.StringValue("key"), value)))),
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
        val items = ((record.fields.getValue("items") as DataValue.Named).payload as DataValue.ListValue).items
        items.single().id shouldBe listItem
        val rows = ((record.fields.getValue("mapping") as DataValue.Named).payload as DataValue.MapValue).rows
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
                PreparationOperation.Resume(first.draft, listOf(InputAnswer(answer.path, DataValue.StringValue("wrong")))),
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
        val concreteUse = TypeUse.Named(concreteId, emptyList())
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    resourceDefinition(),
                    linkDefinition(),
                    TypeDefinition(abstractId, representation = RepresentationTemplate.Record(emptyList(), abstract = true)),
                    TypeDefinition(
                        concreteId,
                        parents = listOf(TypeTemplate.Named(abstractId, emptyList())),
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(concreteId, "target"), LINK_USE.template()),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        ownerId,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(
                                    FieldDeclaration(FieldOwner(ownerId, "choice"), TypeTemplate.Named(abstractId, emptyList())),
                                ),
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
                    listOf(InputAnswer(path("choice"), DataValue.Named(concreteUse, DataValue.Record(emptyMap())))),
                ),
            ) as PreparationStep.NeedsInput
        next.draft.requiredInputs shouldBe listOf(RequiredInput(path("choice", "target"), LINK_USE))
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
        val field = FieldOwner(referenceId, "target")
        val plan = CountingPlan(field, value = reference())
        val catalog =
            DefaultCheckedCatalog(
                GENERATION,
                listOf(
                    resourceDefinition(),
                    linkDefinition(),
                    TypeDefinition(
                        referenceId,
                        representation =
                            RepresentationTemplate.Record(
                                listOf(FieldDeclaration(field, LINK_USE.template(), hasConstructorDefault = true)),
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
    val markerPlan = CountingPlan(FieldOwner(marker, "id"), fail = failMarker)
    val settingsPlan = CountingPlan(FieldOwner(settings, "label"))
    val settingsFields =
        buildList {
            add(FieldDeclaration(FieldOwner(settings, "target"), LINK_USE.template()))
            if (defaultedSettings) {
                add(
                    FieldDeclaration(FieldOwner(settings, "label"), TypeTemplate.Scalar(ScalarKind.Text), hasConstructorDefault = true),
                )
            }
        }
    val catalog =
        DefaultCheckedCatalog(
            GENERATION,
            listOf(
                resourceDefinition(),
                linkDefinition(),
                TypeDefinition(
                    root,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(FieldOwner(root, "settings"), TypeTemplate.Named(settings, emptyList())),
                                FieldDeclaration(FieldOwner(root, "marker"), TypeTemplate.Named(marker, emptyList())),
                            ),
                        ),
                ),
                TypeDefinition(settings, representation = RepresentationTemplate.Record(settingsFields)),
                TypeDefinition(
                    marker,
                    representation =
                        RepresentationTemplate.Record(
                            listOf(
                                FieldDeclaration(
                                    FieldOwner(marker, "id"),
                                    TypeTemplate.Scalar(ScalarKind.Text),
                                    hasConstructorDefault = true,
                                ),
                            ),
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
            CaptureResult.Captured(mapOf(field to (value ?: DataValue.StringValue("capture:$calls"))))
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
private val LINK_USE = TypeUse.Named(LINK_ID, emptyList())
private val ENDPOINT = EndpointId("required-reference")

private fun id(name: String) = TypeDefinitionId(TypeId.Qualified("test.resume", name), 1)

private fun TypeUse.Named.template() = TypeTemplate.Named(definition, emptyList())

private fun resourceDefinition() = TypeDefinition(RESOURCE_ID, representation = RepresentationTemplate.Record(emptyList()))

private fun linkDefinition() =
    TypeDefinition(LINK_ID, representation = RepresentationTemplate.Link(ENDPOINT, TypeTemplate.Named(RESOURCE_ID, emptyList())))

private fun request(id: TypeDefinitionId) =
    InitializationRequest(
        GENERATION,
        PreparationTarget.Record(TypeSelection.Complete(TypeUse.Named(id, emptyList()))),
        DataValue.Record(emptyMap()),
    )

private fun path(vararg fields: String) = ValuePath(fields.map(PathSegment::Field))

private fun reference() = DataValue.Named(LINK_USE, DataValue.Link(ENDPOINT, LinkTarget(ResourceId("reserved-target"), null)))
