package com.typewritermc.engine.pages

import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.TimelineEntryPlacementDefinition
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedPresentationProvider
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.DefaultPresentationRegistry
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.PresentationSelection
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.GraphDirection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.ResourcesLayout
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinition
import java.util.Collections

val CorePageEditorPresentationTest by testSuite {
    val entries =
        Collections
            .list(requireNotNull(Thread.currentThread().contextClassLoader).getResources(GENERATED_PROVIDER_INDEX_PATH))
            .flatMap { resource -> resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) } }
            .distinct()
    val definitions =
        entries
            .filter { it.kind == GeneratedProviderKind.Type }
            .map { (corePageProviderInstance(it.providerClass) as GeneratedTypeProvider).definition }
            .distinctBy(TypeDefinition::id)
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "core page editor coverage"), StandardTypes.definitions + definitions)
    val runtime = DefaultPresentationRuntime()
    val providers =
        entries
            .filter {
                it.kind == GeneratedProviderKind.Presentation &&
                    (
                        it.providerClass.startsWith("com.typewritermc.engine.pages.") ||
                            it.providerClass.contains("PlacementSdkProvider_")
                    )
            }.associate { entry ->
                val provider =
                    Class
                        .forName(entry.providerClass)
                        .getConstructor(PresentationRuntime::class.java)
                        .newInstance(runtime) as GeneratedPresentationProvider
                val key =
                    contributionKey(
                        ContributionSourceId("artifact:typewritermc:engine"),
                        entry.sourcePart,
                        ProducerId("types"),
                        ContributionName(entry.providerClass),
                    )
                val origin =
                    ProviderOrigin(
                        DeclarationOwner(source = key, localIdentity = entry.providerClass),
                        ArtifactId("typewritermc:engine"),
                        entry.sourcePart,
                    )
                provider.descriptor(origin) to provider
            }
    val registry = DefaultPresentationRegistry(catalog, providers.keys.toList())

    listOf(
        Triple("Sequence", SequenceEntryDefinition.use, GraphPlacementDefinition.use),
        Triple("Static", StaticEntryDefinition.use, GraphPlacementDefinition.use),
        Triple("Manifest", ManifestEntryDefinition.use, GraphPlacementDefinition.use),
        Triple("Scene", SceneEntryDefinition.use, TimelineEntryPlacementDefinition.use),
    ).forEach { (name, type, placement) ->
        test("$name entry inspector shows the name first, then the remaining fields, then the placement editor") {
            val checked = (catalog.resolve(type.use) as Resolution.Ready).value
            val selected = registry.select(PresentationRole.INSPECTOR, checked).shouldBeInstanceOf<PresentationSelection.Selected>()
            val layout =
                providers
                    .getValue(selected.descriptor)
                    .build(
                        PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
                    ).layout
            val presented = layout.flattened().filter { it.presentsFields }

            presented.map { it.fieldPaths } shouldBe listOf(listOf("name"), listOf(REMAINING_FIELDS), listOf("placement"))
            presented.first().defaultPresentation?.presentationId shouldBe null
            val placementRequest = presented.last().defaultPresentation.shouldNotBeNull()
            val checkedPlacement = (catalog.resolve(placement.use) as Resolution.Ready).value
            val placementSelection =
                registry
                    .select(PresentationRole.INSPECTOR, checkedPlacement)
                    .shouldBeInstanceOf<PresentationSelection.Selected>()
            placementRequest.presentationId?.namespace shouldBe placementSelection.descriptor.id.namespace
            placementRequest.presentationId?.name shouldBe placementSelection.descriptor.id.name
        }
    }

    listOf(
        Triple("Sequence", SequencePageDefinition.use, GraphDirection.LEFT_TO_RIGHT),
        Triple("Static", StaticPageDefinition.use, GraphDirection.BOTTOM_TO_TOP),
        Triple("Manifest", ManifestPageDefinition.use, GraphDirection.TOP_TO_BOTTOM),
        Triple("Scene", ScenePageDefinition.use, null),
    ).forEach { (name, type, direction) ->
        test("$name page workspace presents its resources on its intended canvas") {
            val checked = (catalog.resolve(type.use) as Resolution.Ready).value
            val selection = registry.select(PresentationRole.WORKSPACE, checked).shouldBeInstanceOf<PresentationSelection.Selected>()
            val binding = PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)
            val layout = providers.getValue(selection.descriptor).build(binding).layout
            val resources =
                layout
                    .flattened()
                    .filterIsInstance<PresentationElement.ResourcesWrapper>()
                    .single()
                    .value.layout
            if (direction == null) {
                resources.shouldBeInstanceOf<ResourcesLayout.TimelineWrapper>()
            } else {
                resources.shouldBeInstanceOf<ResourcesLayout.GraphWrapper>().value.direction shouldBe direction
            }
        }
    }
}

private fun corePageProviderInstance(name: String): Any {
    val type = Class.forName(name)
    return type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()
}

private const val REMAINING_FIELDS = "remaining fields"

/** The element of [this] and every element nested in its column and row children, in reading order. */
private fun PresentationNode.flattened(): List<PresentationElement> {
    val element = element ?: return emptyList()
    val axis =
        when (val children = (element as? PresentationElement.ChildrenWrapper)?.value) {
            is ChildrenElement.ColumnWrapper -> children.value.children
            is ChildrenElement.RowWrapper -> children.value.children
            else -> emptyList()
        }
    val nodes =
        axis.mapNotNull { child ->
            when (child) {
                is AxisChild.FixedWrapper -> child.value
                is AxisChild.FlexibleWrapper -> child.value.child
                else -> null
            }
        }
    return listOf(element) + nodes.flatMap { it.flattened() }
}

private val PresentationElement.defaultPresentation get() = (this as? PresentationElement.DefaultPresentationWrapper)?.value

private val PresentationElement.presentsFields
    get() = defaultPresentation != null || this is PresentationElement.RemainingFieldsWrapper

/** The field names an element edits, or [REMAINING_FIELDS] for the slot that presents every field not placed. */
private val PresentationElement.fieldPaths: List<String>
    get() =
        defaultPresentation?.control?.binding?.path?.segments?.map { segment ->
            (segment as PathSegment.FieldWrapper).value.name
        } ?: listOf(REMAINING_FIELDS)
