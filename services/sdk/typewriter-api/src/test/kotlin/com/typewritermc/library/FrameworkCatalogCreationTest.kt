@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.library

import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.name
import com.typewritermc.authoring.payload
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.assemble
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.expression.literal
import com.typewritermc.presentation.DefaultPresentationRegistry
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationBuildScope
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.PresentationSelection
import com.typewritermc.presentation.RecordControl
import com.typewritermc.presentation.TextControl
import com.typewritermc.presentation.allNodes
import com.typewritermc.presentation.invoke
import com.typewritermc.presentation.of
import com.typewritermc.presentation.presentationPart
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.testkit.bytes
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.record
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainInOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import java.lang.reflect.Modifier
import java.math.BigInteger
import java.util.Collections
import kotlin.reflect.KClass
import skirout.editor.v1.expression.ExpressionNode as WireExpressionNode
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment

val FrameworkCatalogCreationTest by testSuite {
    test("the element graph presentation reaches every concrete element unless a concrete presentation targets it") {
        val concreteId = TypeDefinitionId.qualified("test", "ConcreteEntry")
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "entry graph inheritance"),
                StandardTypes.definitions + framework.definitions +
                    TypeDefinition.partial(
                        id = concreteId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(ElementDefinition.id.namedTemplate()),
                    ),
            )
        val checked = catalog.resolve(concreteId.use()).ready()
        val inherited =
            com.typewritermc.elements
                .ElementGraphNodePresentation_ElementPresentationProvider(DefaultPresentationRuntime())
                .descriptor(origin("element_graph"))
        val concrete =
            inherited.copy(
                id = PresentationId(namespace = "test", name = "concrete entry graph"),
                target = PresentationTarget.NamedWrapper(concreteId.namedTemplate()),
                priority = inherited.priority - 1,
            )

        DefaultPresentationRegistry(catalog, listOf(inherited)).selected(PresentationRole.ITEM, checked) shouldBe inherited.id
        DefaultPresentationRegistry(catalog, listOf(inherited, concrete)).selected(PresentationRole.ITEM, checked) shouldBe concrete.id
    }

    test("a new book starts with the book icon and no findings") {
        val book = framework.prepareBook()

        book.findings shouldBe emptyList()
        book.record.fieldMap.getValue("icon") shouldBe
            DataValue.named(
                IconIconifyDefinition.use,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("material-symbols:book"))),
            )
    }

    test("a new tag starts unnamed, without parents, at the origin of the graph") {
        val tag = framework.prepareTag()

        tag.findings shouldBe emptyList()
        tag.record.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("")
        (tag.record.fieldMap.getValue("parents") as DataValue.NamedWrapper).payload shouldBe DataValue.setValue(emptyList())
        tag.record.fieldMap.getValue("placement") shouldBe
            DataValue.named(
                GraphPlacementDefinition.use,
                DataValue.record(
                    mapOf(
                        "x" to DataValue.integer(BigInteger.ZERO),
                        "y" to DataValue.integer(BigInteger.ZERO),
                        "width" to DataValue.integer(BigInteger.ONE),
                        "height" to DataValue.integer(BigInteger.ONE),
                    ),
                ),
            )
    }

    test("every iconify search source shows its results with one presentation") {
        val layout =
            framework.build(
                "CoreIconSdkProvider_IconIconifyPresentationProvider",
                IconIconifyDefinition.use,
                PresentationRole.INSPECTOR,
            )
        val results =
            layout
                .elementsOf<PresentationElement.SearchInputWrapper>()
                .single()
                .value.provider
                .resultPresentations()

        results shouldHaveSize 2
        results.distinct() shouldHaveSize 1
        results.first() shouldNotBe null
    }

    test("the book inspector shows title, icon, color, direct tags and effective tags in order") {
        val layout = framework.build("BookInspectorPresentation_BookPresentationProvider", BookDefinition.use)

        layout.sections() shouldContainInOrder
            listOf("Title" to "title", "Icon" to "icon", "Color" to "color", "Direct Tags" to "tags", "Effective Tags" to null)
    }

    test("the tag inspector shows name, color, direct parents, inheritance and placement in order") {
        val layout = framework.build("TagInspectorPresentation_TagPresentationProvider", TagDefinition.use)

        layout.sections() shouldContainInOrder
            listOf("Name" to "name", "Color" to "color", "Direct Parents" to "parents", "Inheritance" to null, "Placement" to "placement")
    }

    test("the page inspector shows book, name, chapter and priority in order") {
        val layout = framework.build("PageInspectorPresentation_PagePresentationProvider", PageDefinition.use)

        layout.sections() shouldContainInOrder listOf("Book" to "book", "Name" to "name", "Chapter" to "chapter", "Priority" to "priority")
    }

    test("the book icon field offers the iconify and svg icon editors") {
        val iconify = framework.presentation("CoreIconSdkProvider_IconIconifyPresentationProvider").descriptor
        val svg = framework.presentation("CoreIconSdkProvider_IconSvgPresentationProvider").descriptor
        val layout = framework.build("BookInspectorPresentation_BookPresentationProvider", BookDefinition.use)
        val options =
            layout
                .elementsOf<PresentationElement.PolymorphicInputWrapper>()
                .single()
                .value.concreteTypes

        options.map { it.concreteType } shouldBe listOf(IconIconifyDefinition.use.use, IconSvgDefinition.use.use)
        options.map { (it.presentation?.element as PresentationElement.InvocationWrapper).value.presentationId?.name } shouldBe
            listOf(iconify.id.name, svg.id.name)
    }

    test("effective tags of a book and the inheritance of a tag draw the tag parents graph") {
        val book = framework.build("BookInspectorPresentation_BookPresentationProvider", BookDefinition.use)
        val tag = framework.build("TagInspectorPresentation_TagPresentationProvider", TagDefinition.use)

        for (layout in listOf(book, tag)) {
            val graph = layout.elementsOf<PresentationElement.CollectionGraphWrapper>().single().value
            graph.sourceId shouldBe TAG_COLLECTION_SOURCE_ID
            graph.relationId shouldBe "parents"
        }
    }

    test("reference previews of books, tags and pages show the resource's appearance") {
        val previews =
            listOf(
                framework.build(
                    "BookReferencePresentation_BookPresentationProvider",
                    BookDefinition.use,
                    PresentationRole.REFERENCE_PREVIEW,
                ),
                framework.build("TagReferencePresentation_TagPresentationProvider", TagDefinition.use, PresentationRole.REFERENCE_PREVIEW),
                framework.build(
                    "PageReferencePresentation_PagePresentationProvider",
                    PageDefinition.use,
                    PresentationRole.REFERENCE_PREVIEW,
                ),
            )

        for (preview in previews) {
            val leading = preview.elementsOf<PresentationElement.AdaptiveLeadingWrapper>().single().value
            (leading.leading.element as PresentationElement.IconWrapper).value.name.appearanceField() shouldBe "icon"
        }
        val book =
            previews
                .first()
                .elementsOf<PresentationElement.AdaptiveLeadingWrapper>()
                .single()
                .value
        (book.center!!.element as PresentationElement.TextWrapper).value.value.appearanceField() shouldBe "label"
    }

    test("the placement inspector labels its fields X, Y, W and H") {
        val layout =
            framework.build(
                "PlacementSdkProvider_GraphPlacementPresentationProvider",
                GraphPlacementDefinition.use,
            )
        val prefixes =
            layout.elementsOf<PresentationElement.NumericInputWrapper>().map { numeric ->
                val prefix = requireNotNull(numeric.value.content).leading as skirout.editor.v1.presentation.InputAdornment.ContentWrapper
                val text = prefix.value.element as PresentationElement.TextWrapper
                ((text.value.value as WireExpressionNode.LiteralWrapper).value as DataValue.StringValueWrapper).value
            }

        prefixes shouldBe listOf("X", "Y", "W", "H")
    }

    test("the compiled control catalog assembles its inherited inspectors without failures") {
        val assembly = controlCatalogAssembly(DefaultPresentationRuntime())
        val materials = assembly.editorCatalog.presentationMaterials

        assembly.callbackFailures.map { "${it.callback}: ${it.cause}" } shouldBe emptyList()
        assembly.editorCatalog.diagnostics.filter { it.code.contains("display") || it.code.contains("search_key") } shouldBe emptyList()
        assembly.editorCatalog.diagnostics.filter { it.code.contains("presentation") } shouldBe emptyList()
        materials
            .single {
                it.role == PresentationRole.INSPECTOR &&
                    (it.target as? PresentationTarget.NamedWrapper)?.value?.definition == ElementDefinition.id
            }.inheritableNodes shouldHaveSize 3
        materials
            .single { it.provider == PresentationId(namespace = "fixture", name = "entry inspector") }
            .inheritableNodes shouldHaveSize 3
    }
}
