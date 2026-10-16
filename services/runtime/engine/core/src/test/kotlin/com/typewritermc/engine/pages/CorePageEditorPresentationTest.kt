package com.typewritermc.engine.pages

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedPresentationProvider
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.ProviderOrigin
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
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PageGraphDirection
import skirout.editor.v1.presentation.PresentationElement
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
    val catalog = DefaultCheckedCatalog(CatalogGeneration("core page editor coverage"), StandardTypes.definitions + definitions)
    val runtime = DefaultPresentationRuntime()
    val providers =
        entries
            .filter {
                it.kind == GeneratedProviderKind.Presentation &&
                    it.providerClass.startsWith("com.typewritermc.engine.pages.")
            }.associate { entry ->
                val provider =
                    Class
                        .forName(entry.providerClass)
                        .getConstructor(PresentationRuntime::class.java)
                        .newInstance(runtime) as GeneratedPresentationProvider
                val key =
                    ContributionKey(
                        ContributionSourceId("artifact:typewritermc:engine"),
                        entry.sourcePart,
                        ProducerId("types"),
                        ContributionName(entry.providerClass),
                    )
                val origin = ProviderOrigin(DeclarationOwner(key, entry.providerClass), ArtifactId("typewritermc:engine"), entry.sourcePart)
                provider.descriptor(origin) to provider
            }
    val registry = DefaultPresentationRegistry(catalog, providers.keys.toList())

    listOf(
        Triple("Sequence", SequencePageDefinition.use, PageGraphDirection.LEFT_TO_RIGHT),
        Triple("Static", StaticPageDefinition.use, PageGraphDirection.BOTTOM_TO_TOP),
        Triple("Manifest", ManifestPageDefinition.use, PageGraphDirection.TOP_TO_BOTTOM),
        Triple("Scene", ScenePageDefinition.use, null),
    ).forEach { (name, type, direction) ->
        test("$name page has a discovered editor with its intended canvas") {
            val checked = (catalog.resolve(type) as Resolution.Ready).value
            val selection = registry.select(PresentationRole.EDITOR, checked).shouldBeInstanceOf<PresentationSelection.Selected>()
            val binding = PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)
            val layout = providers.getValue(selection.descriptor).build(binding).layout
            val children = layout.element.shouldBeInstanceOf<PresentationElement.ChildrenWrapper>().value
            val column = children.shouldBeInstanceOf<ChildrenElement.ColumnWrapper>().value
            val child = column.children.single().shouldBeInstanceOf<AxisChild.FixedWrapper>()
            val canvas = child.value.element
            if (direction == null) {
                canvas.shouldBeInstanceOf<PresentationElement.PageTimelineWrapper>()
            } else {
                canvas.shouldBeInstanceOf<PresentationElement.PageGraphWrapper>().value.direction shouldBe direction
            }
        }
    }
}

private fun corePageProviderInstance(name: String): Any {
    val type = Class.forName(name)
    return type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()
}
