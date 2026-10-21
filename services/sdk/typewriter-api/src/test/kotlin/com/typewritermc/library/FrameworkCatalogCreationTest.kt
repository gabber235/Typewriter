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
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.expression.literal
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationBuildScope
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.RecordControl
import com.typewritermc.presentation.TextControl
import com.typewritermc.presentation.invoke
import com.typewritermc.presentation.of
import com.typewritermc.presentation.presentationPart
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.Icon
import com.typewritermc.types.IconDefinition
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
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
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import java.lang.reflect.Modifier
import java.util.Collections
import kotlin.reflect.KClass
import skirout.editor.v1.expression.ExpressionNode as WireExpressionNode
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

val FrameworkCatalogCreationTest by testSuite {
    test("element graph defaults inherit while concrete graph presentations keep precedence") {
        val entries = generatedProviderEntries()
        val definitions =
            entries
                .filter { it.kind == GeneratedProviderKind.Type }
                .map { entry ->
                    (instantiateGeneratedProvider(Class.forName(entry.providerClass)) as GeneratedTypeProvider).definition
                }.distinctBy(TypeDefinition::id)
        val concreteId =
            TypeDefinitionId.qualified("test", "ConcreteEntry")
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "entry graph inheritance"),
                StandardTypes.definitions + definitions +
                    TypeDefinition.partial(
                        id = concreteId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents =
                            listOf(
                                com.typewritermc.elements.ElementDefinition.id
                                    .namedTemplate(),
                            ),
                    ),
            )
        val checked = (catalog.resolve(concreteId.use()) as Resolution.Ready).value
        val runtime = DefaultPresentationRuntime()
        val provider = com.typewritermc.elements.ElementGraphNodePresentation_ElementPresentationProvider(runtime)
        val inherited = provider.descriptor(origin("element_graph"))
        inherited.roles shouldBe setOf(PresentationRole.ITEM)
        entries.count { it.providerClass == provider.javaClass.name } shouldBe 1
        val inheritedRegistry = com.typewritermc.presentation.DefaultPresentationRegistry(catalog, listOf(inherited))
        (inheritedRegistry.select(PresentationRole.ITEM, checked) as com.typewritermc.presentation.PresentationSelection.Selected)
            .descriptor.id shouldBe inherited.id
        val concrete =
            inherited.copy(
                id =
                    skirout.editor.v1.type_catalog
                        .PresentationId(namespace = "test", name = "concrete entry graph"),
                target =
                    skirout.editor.v1.catalog.PresentationTarget
                        .NamedWrapper(concreteId.namedTemplate()),
                priority = inherited.priority - 1,
            )
        val customRegistry = com.typewritermc.presentation.DefaultPresentationRegistry(catalog, listOf(inherited, concrete))
        (customRegistry.select(PresentationRole.ITEM, checked) as com.typewritermc.presentation.PresentationSelection.Selected)
            .descriptor.id shouldBe concrete.id
        val material =
            provider.build(
                PresentationBuildBinding(
                    checked.presentationTemplate(),
                    PresentationRole.ITEM,
                    mapOf(
                        com.typewritermc.elements.Element::class to
                            com.typewritermc.elements.ElementDefinition.id
                                .namedTemplate(),
                    ),
                ),
            )
        val surface = (material.layout.singleFixed().element as PresentationElement.ContainerWrapper).value
        surface.radius shouldBe skirout.editor.v1.presentation.PresentationRadius.MEDIUM
        val inset = (surface.child.singleFixed().element as PresentationElement.PaddingWrapper).value
        listOf(inset.start, inset.top, inset.end, inset.bottom) shouldBe listOf(4.0, 4.0, 4.0, 4.0)
        val frame = (inset.child.singleFixed().element as PresentationElement.ContainerWrapper).value
        frame.radius shouldBe skirout.editor.v1.presentation.PresentationRadius.SMALL
        frame.transition?.fallback?.milliseconds shouldBe 400
        val border = (frame.border as skirout.editor.v1.presentation.PresentationBorder.AllWrapper).value
        border.width shouldBe 3.0
        val states = (border.color as skirout.editor.v1.presentation.PresentationColor.StatesWrapper).value
        states.rules.map { it.match.required } shouldBe
            listOf(
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.FOCUSED),
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.SELECTED),
            )
        val leading = frame.child.adaptiveLeading()
        with((leading.padding as skirout.editor.v1.presentation.PresentationInsets.OnlyWrapper).value) {
            listOf(left, top, right, bottom)
        } shouldBe listOf(12.0, 8.0, 12.0, 8.0)
        with((leading.compactPadding as skirout.editor.v1.presentation.PresentationInsets.OnlyWrapper).value) {
            listOf(left, top, right, bottom)
        } shouldBe listOf(4.0, 4.0, 4.0, 4.0)
        requireNotNull((leading.leading.element as PresentationElement.IconWrapper).value.size)
            .evaluate(emptyMap()) shouldBe DataValue.FloatWrapper(18.0)
        System.getenv("TYPEWRITER_CONTROL_FIXTURE_DIR")?.let { output ->
            java.io.File(output).mkdirs()
            java.io.File(output, "element-graph-layout.bin").writeBytes(
                PresentationNode.serializer.toBytes(material.layout).toByteArray(),
            )
        }
    }

    test("framework catalog exposes icon and placement forms with usable resource defaults") {
        val generation = CatalogGeneration(value = "framework creation")
        val entries = generatedProviderEntries()
        val definitions =
            entries
                .filter { it.kind == GeneratedProviderKind.Type }
                .map { entry ->
                    instantiateGeneratedProvider(Class.forName(entry.providerClass)) as GeneratedTypeProvider
                }.map(GeneratedTypeProvider::definition)
                .distinctBy(TypeDefinition::id)
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + definitions)
        val iconRepresentation = IconDefinition.declaration.representation as RepresentationTemplate.RecordWrapper
        iconRepresentation.value.fields shouldBe emptyList()
        val factories =
            entries
                .filter { it.kind == GeneratedProviderKind.NativeBinding }
                .map { entry ->
                    instantiateGeneratedProvider(Class.forName(entry.providerClass)) as NativeBindingFactory
                }.distinctBy(NativeBindingFactory::provider)
        val bindings = FactoryNativeBindingRegistry(catalog, factories)
        val checkedIconify = (catalog.resolve(IconIconifyDefinition.use.use) as Resolution.Ready).value
        val encodedIcon =
            bindings
                .bind(checkedIconify)
                .encodeGeneratedDefault(
                    Icon.Iconify("material-symbols:book"),
                )
        encodedIcon shouldBe
            DataValue.named(
                IconIconifyDefinition.use,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("material-symbols:book"))),
            )
        val initializer = DefaultInitializationRuntime(catalog, bindings)

        fun owner(
            link: NamedTypeUse,
            target: String,
        ): DataValue =
            bindings
                .bind((catalog.resolve(link.use) as Resolution.Ready).value)
                .encodeGeneratedDefault(com.typewritermc.types.Ref<Nothing, Nothing>(com.typewritermc.types.ResourceId(target)))

        // Books and tags are always created into their section, so creation supplies the owner link.
        val library =
            owner(
                LibraryBooks.Book.Definition.id
                    .namedUse(listOf(LibraryDefinition.use.use)),
                "library",
            )
        val taxonomy =
            owner(
                TaxonomyTags.Tag.Definition.id
                    .namedUse(listOf(TaxonomyDefinition.use.use)),
                "taxonomy",
            )
        val book = initializer.prepareNow(request(generation, BookDefinition.use, mapOf("library" to library)))
        val icon = book.record.fieldMap.getValue("icon") as DataValue.NamedWrapper
        icon.actualType shouldBe IconIconifyDefinition.use
        book.findings shouldBe emptyList()

        val tag = initializer.prepareNow(request(generation, TagDefinition.use, mapOf("taxonomy" to taxonomy)))
        tag.findings shouldBe emptyList()
        tag.record.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("")
        (tag.record.fieldMap.getValue("color") is DataValue.NamedWrapper) shouldBe true
        val parents = tag.record.fieldMap.getValue("parents") as DataValue.NamedWrapper
        parents.payload shouldBe DataValue.setValue(emptyList())
        val placement = tag.record.fieldMap.getValue("placement") as DataValue.NamedWrapper
        placement.actualType shouldBe GraphPlacementDefinition.use
        placement.payload shouldBe
            DataValue.record(
                mapOf(
                    "x" to DataValue.integer(java.math.BigInteger.ZERO),
                    "y" to DataValue.integer(java.math.BigInteger.ZERO),
                    "width" to DataValue.integer(java.math.BigInteger.ONE),
                    "height" to DataValue.integer(java.math.BigInteger.ONE),
                ),
            )

        val runtime = DefaultPresentationRuntime()
        val iconifyProvider =
            com.typewritermc.types
                .CoreIconSdkProvider_IconIconifyPresentationProvider(runtime)
        val svgProvider =
            com.typewritermc.types
                .CoreIconSdkProvider_IconSvgPresentationProvider(runtime)
        val placementProvider =
            com.typewritermc.authoring
                .PlacementSdkProvider_GraphPlacementPresentationProvider(runtime)
        val bookProvider = BookInspectorPresentation_BookPresentationProvider(runtime)
        val tagProvider = TagInspectorPresentation_TagPresentationProvider(runtime)
        val pageProvider = PageInspectorPresentation_PagePresentationProvider(runtime)
        val bookReferenceProvider = BookReferencePresentation_BookPresentationProvider(runtime)
        val tagReferenceProvider = TagReferencePresentation_TagPresentationProvider(runtime)
        val tagGraphProvider = TagGraphNodePresentation_TagPresentationProvider(runtime)
        val pageReferenceProvider = PageReferencePresentation_PagePresentationProvider(runtime)
        val iconifyDescriptor = iconifyProvider.descriptor(origin("iconify"))
        val svgDescriptor = svgProvider.descriptor(origin("svg"))
        val placementDescriptor = placementProvider.descriptor(origin("placement"))
        bookProvider.descriptor(origin("book"))
        tagProvider.descriptor(origin("tag"))
        pageProvider.descriptor(origin("page"))
        bookReferenceProvider.descriptor(origin("book"))
        tagReferenceProvider.descriptor(origin("tag"))
        tagGraphProvider.descriptor(origin("tag"))
        pageReferenceProvider.descriptor(origin("page"))
        val checkedBook = (catalog.resolve(BookDefinition.use.use) as Resolution.Ready).value
        val resourceTypes =
            factories
                .mapNotNull { factory ->
                    val native = factory.nativeClass ?: return@mapNotNull null
                    val definition = definitions.singleOrNull { it.id == factory.definition } ?: return@mapNotNull null
                    native to definition.id.namedTemplate(definition.parameters.map { it.key.template })
                }.toMap()
        val iconifyMaterial =
            iconifyProvider.build(
                PresentationBuildBinding(
                    checkedIconify.presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    resourceTypes,
                ),
            )
        (
            iconifyMaterial.layout
                .fixedChildren()
                .first()
                .element is PresentationElement.SearchInputWrapper
        ) shouldBe true
        // Search sources intentionally reuse the same canonical result body.
        val search =
            iconifyMaterial.layout
                .fixedChildren()
                .first()
                .element as PresentationElement.SearchInputWrapper
        val distinct = search.value.provider as skirout.editor.v1.presentation.SearchProvider.DistinctWrapper
        val merge = distinct.value.child as skirout.editor.v1.presentation.SearchProvider.MergeWrapper
        val remoteSection = merge.value.children[0] as skirout.editor.v1.presentation.SearchProvider.SectionWrapper
        val history = remoteSection.value.child as skirout.editor.v1.presentation.SearchProvider.HistoryWrapper
        val cache = history.value.child as skirout.editor.v1.presentation.SearchProvider.CacheWrapper
        val limit = cache.value.child as skirout.editor.v1.presentation.SearchProvider.LimitWrapper
        val debounce = limit.value.child as skirout.editor.v1.presentation.SearchProvider.DebounceWrapper
        val gate = debounce.value.child as skirout.editor.v1.presentation.SearchProvider.GateWrapper
        val remote = gate.value.child as skirout.editor.v1.presentation.SearchProvider.HttpJsonWrapper
        val suggestedSection = merge.value.children[1] as skirout.editor.v1.presentation.SearchProvider.SectionWrapper
        val suggested = suggestedSection.value.child as skirout.editor.v1.presentation.SearchProvider.StaticValuesWrapper
        remote.value.result.presentation shouldBe suggested.value.result.presentation
        remote.value.result.presentation!!
            .nodeId shouldBe
            suggested.value.result.presentation!!
                .nodeId

        val material =
            bookProvider.build(
                PresentationBuildBinding(
                    checkedBook.presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    resourceTypes,
                ),
            )
        val root = material.layout.singleFixed().element as PresentationElement.ChildrenWrapper
        val column = root.value as ChildrenElement.ColumnWrapper
        column.value.children shouldHaveSize 7
        column.value.children
            .drop(1)
            .take(5)
            .map(AxisChild::nodeId) shouldBe
            listOf("title", "icon", "color", "tags", "effective-tags")
        column.value.children
            .drop(1)
            .take(5)
            .map(AxisChild::sectionTitle) shouldBe
            listOf("Title", "Icon", "Color", "Direct Tags", "Effective Tags")
        column.value.children
            .drop(1)
            .take(5)
            .map { it.sectionNode().header?.binding } shouldBe
            listOf("title", "icon", "color", "tags", null).map(::fieldBinding)
        val iconNode = column.value.children[2].sectionContent()
        val polymorphic = iconNode.element as PresentationElement.PolymorphicInputWrapper
        polymorphic.value.concreteTypes shouldHaveSize 2
        polymorphic.value.concreteTypes.map { it.concreteType } shouldBe
            listOf(
                IconIconifyDefinition.use.use,
                IconSvgDefinition.use.use,
            )
        polymorphic.value.concreteTypes.map { it.presentation?.element }.all {
            it is PresentationElement.InvocationWrapper
        } shouldBe true
        polymorphic.value.concreteTypes.mapNotNull { option ->
            (option.presentation?.element as? PresentationElement.InvocationWrapper)?.value?.presentationId?.name
        } shouldBe listOf(iconifyDescriptor.id.name, svgDescriptor.id.name)
        column.value.children[5]
            .sectionContent()
            .collectionGraphSource() shouldBe TAG_COLLECTION_SOURCE_ID

        val checkedTag = (catalog.resolve(TagDefinition.use.use) as Resolution.Ready).value
        val graphMaterial =
            tagGraphProvider.build(
                PresentationBuildBinding(checkedTag.presentationTemplate(), PresentationRole.ITEM, resourceTypes),
            )
        val graphSurface = (graphMaterial.layout.singleFixed().element as PresentationElement.ContainerWrapper).value
        graphSurface.transition?.fallback?.milliseconds shouldBe 100
        val graphColors = (graphSurface.backgroundColor as skirout.editor.v1.presentation.PresentationColor.StatesWrapper).value
        graphColors.rules.map { it.match.required } shouldBe
            listOf(
                listOf(
                    skirout.editor.v1.presentation.PresentationInteractionState.SELECTED,
                    skirout.editor.v1.presentation.PresentationInteractionState.HOVERED,
                ),
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.SELECTED),
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.HOVERED),
            )
        val graphForeground = (graphSurface.foregroundColor as skirout.editor.v1.presentation.PresentationColor.StatesWrapper).value
        graphForeground.rules.map { it.match.required } shouldBe
            listOf(
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.HOVERED),
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.SELECTED),
            )
        val tagMaterial =
            tagProvider.build(
                PresentationBuildBinding(
                    checkedTag.presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    resourceTypes,
                ),
            )
        val tagRoot = tagMaterial.layout.singleFixed().element as PresentationElement.ChildrenWrapper
        val tagColumn = tagRoot.value as ChildrenElement.ColumnWrapper
        tagColumn.value.children shouldHaveSize 7
        tagColumn.value.children
            .drop(1)
            .take(5)
            .map(AxisChild::nodeId) shouldBe
            listOf("name", "color", "parents", "inheritance", "placement")
        tagColumn.value.children
            .drop(1)
            .take(5)
            .map(AxisChild::sectionTitle) shouldBe
            listOf("Name", "Color", "Direct Parents", "Inheritance", "Placement")
        tagColumn.value.children
            .drop(1)
            .take(5)
            .map { it.sectionNode().header?.binding } shouldBe
            listOf("name", "color", "parents", null, "placement").map(::fieldBinding)
        tagColumn.value.children[4]
            .sectionContent()
            .collectionGraphSource() shouldBe TAG_COLLECTION_SOURCE_ID
        val placementNode = tagColumn.value.children[5].sectionContent()
        val placementInvocation = placementNode.element as PresentationElement.DefaultPresentationWrapper
        placementInvocation.value.presentationId?.name shouldBe placementDescriptor.id.name

        val checkedPage = (catalog.resolve(PageDefinition.use.use) as Resolution.Ready).value
        val pageMaterial =
            pageProvider.build(
                PresentationBuildBinding(
                    checkedPage.presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    resourceTypes,
                ),
            )
        val pageRoot = pageMaterial.layout.singleFixed().element as PresentationElement.ChildrenWrapper
        val pageColumn = pageRoot.value as ChildrenElement.ColumnWrapper
        pageColumn.value.children shouldHaveSize 6
        pageColumn.value.children
            .drop(1)
            .take(4)
            .map(AxisChild::nodeId) shouldBe
            listOf("book", "name", "chapter", "priority")
        pageColumn.value.children
            .drop(1)
            .take(4)
            .map(AxisChild::sectionTitle) shouldBe
            listOf("Book", "Name", "Chapter", "Priority")
        pageColumn.value.children
            .drop(1)
            .take(4)
            .map { it.sectionNode().header?.binding } shouldBe
            listOf("book", "name", "chapter", "priority").map(::fieldBinding)

        val bookSummary =
            bookReferenceProvider.build(
                PresentationBuildBinding(
                    checkedBook.presentationTemplate(),
                    PresentationRole.REFERENCE_PREVIEW,
                    resourceTypes,
                ),
            )
        // A preview shows the resource as its display names and marks it, whatever its fields hold.
        val bookPreview = bookSummary.layout.adaptiveLeading()
        (bookPreview.leading.element as PresentationElement.IconWrapper).value.name.appearanceField() shouldBe "icon"
        (bookPreview.center!!.element as PresentationElement.TextWrapper).value.value.appearanceField() shouldBe "label"

        val tagSummary =
            tagReferenceProvider.build(
                PresentationBuildBinding(
                    checkedTag.presentationTemplate(),
                    PresentationRole.REFERENCE_PREVIEW,
                    resourceTypes,
                ),
            )
        val tagLeading =
            tagSummary.layout
                .adaptiveLeading()
                .leading
        (tagLeading.element as PresentationElement.IconWrapper).value.name.appearanceField() shouldBe "icon"

        val pageSummary =
            pageReferenceProvider.build(
                PresentationBuildBinding(
                    checkedPage.presentationTemplate(),
                    PresentationRole.REFERENCE_PREVIEW,
                    resourceTypes,
                ),
            )
        val pageIcon =
            pageSummary.layout
                .adaptiveLeading()
                .leading
                .element
        (pageIcon as PresentationElement.IconWrapper).value.name.appearanceField() shouldBe "icon"

        val checkedPlacement = (catalog.resolve(GraphPlacementDefinition.use.use) as Resolution.Ready).value
        val placementMaterial =
            placementProvider.build(
                PresentationBuildBinding(
                    checkedPlacement.presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    resourceTypes,
                ),
            )
        val placementRoot = placementMaterial.layout.element as PresentationElement.ChildrenWrapper
        val placementColumn = placementRoot.value as ChildrenElement.ColumnWrapper
        val placementPrefixes =
            placementColumn.value.children
                .flatMap { child ->
                    val node = (child as AxisChild.FixedWrapper).value
                    when (val element = node.element) {
                        is PresentationElement.NumericInputWrapper -> {
                            listOf(element.value)
                        }

                        is PresentationElement.ChildrenWrapper -> {
                            (element.value as ChildrenElement.RowWrapper).value.children.map {
                                val field = (it as AxisChild.FlexibleWrapper).value.child
                                (field.element as PresentationElement.NumericInputWrapper).value
                            }
                        }

                        else -> {
                            emptyList()
                        }
                    }
                }.map { numeric ->
                    val prefix =
                        requireNotNull(numeric.content).leading as
                            skirout.editor.v1.presentation.InputAdornment.ContentWrapper
                    val text = prefix.value.element as PresentationElement.TextWrapper
                    val label = text.value.value as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper
                    (label.value as skirout.editor.v1.type_catalog.DataValue.StringValueWrapper).value
                }
        placementPrefixes shouldBe listOf("X", "Y", "W", "H")
        exportFrameworkControlFixture(tag.record, book.record, tag.record.fieldMap.getValue("placement"))
    }
}

private fun fieldBinding(name: String?): skirout.editor.v1.binding.BindingRef? =
    name?.let {
        skirout.editor.v1.binding.BindingRef(
            bindingId = WireExpressionBindingId(value = "configured_value"),
            path = WireValuePath(segments = listOf(WirePathSegment.createField(name = it))),
        )
    }

private fun instantiateGeneratedProvider(type: Class<*>): Any =
    type.fields
        .singleOrNull { field ->
            field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type === type
        }?.get(null)
        ?: type.getConstructor().newInstance()

private fun AxisChild.node(): PresentationNode = (this as AxisChild.FixedWrapper).value

private fun AxisChild.nodeId(): String = sectionNode().nodeId

private fun AxisChild.sectionTitle(): String {
    val title = sectionNode().header?.title as PresentationHeaderTitle.TextWrapper
    val literal = title.value as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper
    return (literal.value as skirout.editor.v1.type_catalog.DataValue.StringValueWrapper).value
}

private fun AxisChild.sectionContent(): PresentationNode {
    val section = node().visibleSection().element as PresentationElement.SectionWrapper
    val column =
        section.value.child
            .singleFixed()
            .element as PresentationElement.ChildrenWrapper
    val children = (column.value as ChildrenElement.ColumnWrapper).value.children
    children shouldHaveSize 1
    return children.single().node()
}

private fun AxisChild.sectionNode(): PresentationNode {
    val section = node().visibleSection().element as PresentationElement.SectionWrapper
    return section.value.child.singleFixed()
}

private fun PresentationNode.visibleSection(): PresentationNode =
    when (val element = element) {
        is PresentationElement.ConditionalWrapper -> element.value.whenTrue.singleFixed()
        else -> this
    }

private fun PresentationNode.collectionGraphSource(): String {
    val graph = element as PresentationElement.CollectionGraphWrapper
    graph.value.relationId shouldBe "parents"
    val roots = graph.value.rootSequence.layout as skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper
    val rootColumn = roots.value as skirout.editor.v1.presentation.ChildrenLayout.ColumnWrapper
    rootColumn.value.spacing shouldBe 12.0
    rootColumn.value.crossAxisAlignment shouldBe skirout.editor.v1.presentation.CrossAxisAlignment.STRETCH
    val hierarchy = (graph.value.children.layout as skirout.editor.v1.presentation.SequenceLayout.HierarchyWrapper).value
    hierarchy.crossAxisAlignment shouldBe skirout.editor.v1.presentation.CrossAxisAlignment.STRETCH
    hierarchy.itemAnchor shouldBe skirout.editor.v1.presentation.ConnectorAnchor.CENTER
    val trunk = hierarchy.trunkConnector.stroke.color as skirout.editor.v1.presentation.PresentationColor.ValueWrapper
    val branch = hierarchy.branchConnector.stroke.color as skirout.editor.v1.presentation.PresentationColor.ValueWrapper
    (trunk != hierarchy.unaryConnector.stroke.color) shouldBe true
    (trunk != branch) shouldBe true
    graph.value.children.empty shouldBe null
    graph.value.rootSequence.empty shouldBe null
    val branchConditional =
        graph.value.node
            .singleFixed()
            .singleFixed()
            .element as PresentationElement.ConditionalWrapper
    val branchSection =
        branchConditional.value.whenTrue
            .singleFixed()
            .singleFixed()
    branchSection.header?.initiallyExpanded shouldBe false
    (branchSection.header?.title is PresentationHeaderTitle.PresentationWrapper) shouldBe true
    val branchBorder = (branchSection.element as PresentationElement.SectionWrapper).value.border
    val border = branchBorder as skirout.editor.v1.presentation.PresentationBorder.SidesWrapper
    border.value.start?.width shouldBe 4.0
    border.value.top shouldBe null
    border.value.end shouldBe null
    border.value.bottom shouldBe null
    val title = (branchSection.header!!.title as PresentationHeaderTitle.PresentationWrapper).value
    val card = (title.singleFixed().element as PresentationElement.ContainerWrapper).value
    val tint = card.backgroundColor as skirout.editor.v1.presentation.PresentationColor.AlphaWrapper
    tint.value.alpha shouldBe 46.0 / 255.0
    val cardBorder = card.border as skirout.editor.v1.presentation.PresentationBorder.AllWrapper
    cardBorder.value.width shouldBe 1.0
    return graph.value.sourceId
}

private fun PresentationNode.adaptiveLeading(): skirout.editor.v1.presentation.AdaptiveLeadingElement {
    val leading = fixedChildren().single { it.element is PresentationElement.AdaptiveLeadingWrapper }
    return (leading.element as PresentationElement.AdaptiveLeadingWrapper).value
}

private fun PresentationNode.singleFixed(): PresentationNode = fixedChildren().single()

private fun PresentationNode.fixedChildren(): List<PresentationNode> {
    val children = element as PresentationElement.ChildrenWrapper
    val column = children.value as ChildrenElement.ColumnWrapper
    return column.value.children.map(AxisChild::node)
}

/** The field of the presented resource's appearance this expression reads directly, or null for any other expression. */
private fun WireExpressionNode.appearanceField(): String? {
    val input = (this as? WireExpressionNode.InputWrapper)?.value ?: return null
    if (input.binding.value != "presentation.subject.appearance") return null
    return (input.path.segments.single() as WirePathSegment.FieldWrapper).value.name
}

private fun WireExpressionNode.evaluate(bindings: Map<WireExpressionBindingId, DataValue>): DataValue? =
    when (this) {
        is WireExpressionNode.LiteralWrapper -> {
            value.requirePortable()
        }

        is WireExpressionNode.InputWrapper -> {
            bindings[value.binding]?.at(value.path)
        }

        is WireExpressionNode.RuleUnaryWrapper -> {
            require(value.operation == skirout.editor.v1.expression.RuleUnaryOperation.NON_BLANK)
            DataValue.BooleanWrapper((value.source.evaluate(bindings) as? DataValue.StringValueWrapper)?.value?.isNotBlank() == true)
        }

        is WireExpressionNode.ConditionalWrapper -> {
            if ((value.test.evaluate(bindings) as? DataValue.BooleanWrapper)?.value == true) {
                value.yes.evaluate(bindings)
            } else {
                value.no.evaluate(bindings)
            }
        }

        is WireExpressionNode.OrElseWrapper -> {
            value.input.evaluate(bindings).let { resolved ->
                if (resolved == null || resolved == DataValue.NULL || resolved == DataValue.UNFILLED) {
                    value.fallback.evaluate(bindings)
                } else {
                    resolved
                }
            }
        }

        else -> {
            error("The material expression uses an unsupported test operation")
        }
    }

private fun DataValue.at(path: WireValuePath): DataValue? {
    var current = this
    for (wireSegment in path.segments) {
        while (current is DataValue.NamedWrapper) current = current.payload
        val segment =
            (WireValuePath(segments = listOf(wireSegment)))
                .requireValid()
                .segments
                .single()
        current =
            when (segment) {
                is PathSegment.FieldWrapper -> {
                    (current as? DataValue.RecordWrapper)?.field(segment.name)
                }

                else -> {
                    null
                }
            } ?: return null
    }
    return current
}

private fun generatedProviderEntries(): List<com.typewritermc.discovery.GeneratedProviderIndexEntry> {
    val resources =
        Collections.list(
            requireNotNull(Thread.currentThread().contextClassLoader).getResources("META-INF/typewriter/generated-providers"),
        )
    return resources
        .flatMap { resource ->
            resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) }
        }.distinct()
}

private fun request(
    generation: CatalogGeneration,
    use: NamedTypeUse,
    supplied: Map<String, DataValue> = emptyMap(),
) = ValuePreparationRequest(
    catalog = generation,
    target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(use)),
    suppliedValue = DataValue.record(supplied),
)

private val PreparedValue.record
    get() = (content as PreparedContent.RecordWrapper).value

private fun origin(name: String): ProviderOrigin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    contributionKey(
                        source = ContributionSourceId("test"),
                        sourcePart = "main",
                        producer = ProducerId("test"),
                        name = ContributionName(name),
                    ),
                localIdentity = name,
            ),
        artifact = ArtifactId("test:framework"),
        sourcePart = "main",
    )

private fun exportFrameworkControlFixture(
    tag: AuthoringRecord,
    book: AuthoringRecord,
    placement: DataValue,
) {
    val directory = System.getenv("TYPEWRITER_CONTROL_FIXTURE_DIR")?.let { java.io.File(it) } ?: return
    val runtime = DefaultPresentationRuntime()
    val inspectorOrigin = origin("fixture_entry_inspector")
    val entryInspector =
        com.typewritermc.discovery.OwnedPresentation(
            inspectorOrigin,
            PresentationDescriptor.of(
                id =
                    skirout.editor.v1.type_catalog
                        .PresentationId(namespace = "fixture", name = "entry inspector"),
                owner = inspectorOrigin.owner,
                target =
                    skirout.editor.v1.catalog.PresentationTarget
                        .NamedWrapper(entryGraphFixtureType.namedTemplate()),
                roles = setOf(PresentationRole.INSPECTOR),
                priority = 0,
            ),
            object : com.typewritermc.presentation.PresentationProvider {
                override fun build(binding: PresentationBuildBinding) =
                    runtime.build(binding) { scope ->
                        scope.field<String, com.typewritermc.presentation.TextControl>(
                            "name",
                            com.typewritermc.presentation.TextControl::class,
                        )()
                        scope.remainingFields()
                    }
            },
        )
    val framework = frameworkContributions(runtime)
    val contributions =
        framework.copy(
            declarations =
                framework.declarations +
                    com.typewritermc.discovery.OwnedTypeDeclaration(
                        origin("fixture_entry"),
                        TypeDefinition.partial(
                            id = entryGraphFixtureType,
                            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                            parents =
                                listOf(
                                    com.typewritermc.elements.ElementDefinition.id
                                        .namedTemplate(),
                                ),
                        ),
                        com.typewritermc.types.TypeDisplay(
                            "Message action",
                            "Entry graph fixture",
                            com.typewritermc.types.Icon
                                .Iconify("fa6-solid:message"),
                            com.typewritermc.types.Color(0xFFE74C3Cu),
                        ),
                    ) + inheritedInspectorDeclarations(),
            presentations = framework.presentations + entryInspector + inheritedInspectorPresentations(runtime),
        )
    val assembly =
        contributions.assemble(
            com.typewritermc.discovery.CatalogAssemblyContext(CatalogGeneration(value = "compiled controls fixture")),
        )
    assembly.callbackFailures.map { "${it.callback}: ${it.cause}" } shouldBe emptyList()
    assembly.editorCatalog.diagnostics.filter { it.code.contains("display") || it.code.contains("search_key") } shouldBe emptyList()
    assembly.editorCatalog.diagnostics.filter { it.code.contains("presentation") } shouldBe emptyList()
    val elementMaterial =
        assembly.editorCatalog.presentationMaterials.single {
            it.role == skirout.editor.v1.catalog.PresentationRole.INSPECTOR &&
                (it.target as? skirout.editor.v1.catalog.PresentationTarget.NamedWrapper)?.value?.definition ==
                com.typewritermc.elements.ElementDefinition.id
        }
    elementMaterial.inheritableNodes.size shouldBe 3
    assembly.editorCatalog.presentationMaterials
        .single { it.provider.namespace == entryInspector.descriptor.id.namespace && it.provider.name == entryInspector.descriptor.id.name }
        .inheritableNodes.size shouldBe 3
    val wire = assembly.editorCatalog
    directory.mkdirs()
    java.io.File(directory, "element-value.bin").writeBytes(
        skirout.editor.v1.type_catalog.DataValue.serializer
            .toBytes(
                DataValue
                    .named(
                        entryGraphFixtureType.namedUse(),
                        DataValue.record(mapOf("name" to DataValue.StringValueWrapper("Welcome to the village"))),
                    ).requirePortable(),
            ).toByteArray(),
    )
    java.io.File(directory, "inherited-inspector-value.bin").writeBytes(
        skirout.editor.v1.type_catalog.DataValue.serializer
            .toBytes(
                DataValue
                    .named(
                        inspectorMessageFixtureType.namedUse(),
                        DataValue.record(
                            mapOf(
                                "name" to DataValue.StringValueWrapper("Welcome"),
                                "message" to DataValue.StringValueWrapper("Hello player"),
                                "other" to DataValue.StringValueWrapper("Cooldown"),
                                "notes" to DataValue.StringValueWrapper("Shared note"),
                                "placement" to placement,
                            ),
                        ),
                    ).requirePortable(),
            ).toByteArray(),
    )
    java.io.File(directory, "book.bin").writeBytes(
        AuthoringRecord.serializer
            .toBytes(book)
            .toByteArray(),
    )
    java.io.File(directory, "book-value.bin").writeBytes(
        skirout.editor.v1.type_catalog.DataValue.serializer
            .toBytes(DataValue.named(BookDefinition.use, DataValue.RecordWrapper(book.payload)).requirePortable())
            .toByteArray(),
    )
    java.io
        .File(
            directory,
            "catalog.bin",
        ).writeBytes(
            skirout.editor.v1.catalog.EditorCatalog.serializer
                .toBytes(wire)
                .toByteArray(),
        )
    java.io
        .File(
            directory,
            "tag.bin",
        ).writeBytes(
            AuthoringRecord.serializer
                .toBytes(tag)
                .toByteArray(),
        )
    java.io
        .File(
            directory,
            "tag-value.bin",
        ).writeBytes(
            skirout.editor.v1.type_catalog.DataValue.serializer
                .toBytes(
                    DataValue.named(TagDefinition.use, DataValue.RecordWrapper(tag.payload)).requirePortable(),
                ).toByteArray(),
        )
    java.io
        .File(
            directory,
            "placement.bin",
        ).writeBytes(
            skirout.editor.v1.type_catalog.DataValue.serializer
                .toBytes(placement.requirePortable())
                .toByteArray(),
        )
    java.io
        .File(
            directory,
            "manifest.json",
        ).writeText(
            """{"generation":"${wire.generation.value}","materials":${wire.presentationMaterials.size},"types":${wire.types.size},"tagType":"${TagDefinition.id}","placementType":"${GraphPlacementDefinition.id}"}""",
        )
}

private val entryGraphFixtureType =
    TypeDefinitionId.qualified("fixture", "MessageEntry")

private interface CompiledInspectorFamily : Element {
    override val placement: GraphPlacement
    val notes: String
}

private val inspectorFamilyFixtureType =
    TypeDefinitionId.qualified("fixture", "InspectorFamily")
private val inspectorMessageFixtureType =
    TypeDefinitionId.qualified("fixture", "InspectorMessage")

private fun inheritedInspectorDeclarations(): List<OwnedTypeDeclaration> {
    val family =
        TypeDefinition.partial(
            id = inspectorFamilyFixtureType,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = inspectorFamilyFixtureType, name = "placement"),
                                type = GraphPlacementDefinition.id.template(),
                                overrides =
                                    listOf(
                                        FieldOwner(definition = ElementDefinition.id, name = "placement"),
                                    ),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = inspectorFamilyFixtureType, name = "notes"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = true,
                ),
            parents = listOf(ElementDefinition.id.namedTemplate()),
        )
    val message =
        TypeDefinition.partial(
            id = inspectorMessageFixtureType,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf("message", "other").map { name ->
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = inspectorMessageFixtureType, name = name),
                                type = ScalarKind.TEXT.template,
                            )
                        },
                    abstract_ = false,
                ),
            parents = listOf(inspectorFamilyFixtureType.namedTemplate()),
        )
    return listOf(
        OwnedTypeDeclaration(
            origin("inherited_inspector_family"),
            family,
            nativeClass = CompiledInspectorFamily::class,
        ),
        OwnedTypeDeclaration(origin("inherited_inspector_message"), message),
    )
}

private fun inheritedInspectorPresentations(runtime: PresentationRuntime): List<OwnedPresentation> {
    val heading = presentationPart<Element>("fixture_heading")
    val details = presentationPart<CompiledInspectorFamily>("fixture_details")

    fun provider(
        name: String,
        target: TypeDefinitionId,
        body: (PresentationBuildScope) -> Unit,
    ): OwnedPresentation {
        val owner = origin(name.replace(' ', '_'))
        return OwnedPresentation(
            owner,
            PresentationDescriptor.of(
                id = PresentationId(namespace = "fixture", name = name),
                owner = owner.owner,
                target =
                    PresentationTarget
                        .NamedWrapper(target.namedTemplate()),
                roles = setOf(PresentationRole.INSPECTOR),
                priority = 0,
            ),
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding) = runtime.build(binding, body)
            },
        )
    }
    return listOf(
        provider("inherited family inspector", inspectorFamilyFixtureType) { scope ->
            val name =
                scope.field<String, TextControl>(
                    "name",
                    TextControl::class,
                )
            val notes =
                scope.field<String, TextControl>(
                    "notes",
                    TextControl::class,
                )

            @Suppress("UNCHECKED_CAST")
            val placement =
                scope
                    .field<GraphPlacement, RecordControl<Layout>>(
                        "placement",
                        RecordControl::class as KClass<RecordControl<Layout>>,
                    )
            with(scope) {
                name()
                heading { text(literal("Entry heading")) }
                details {
                    section {
                        text(literal("Shared details"))
                        notes {
                            label("Notes")
                            textInput()
                        }
                    }
                }
                remainingFields()
                placement(using = PlacementSdkProvider)
            }
        },
        provider("inherited child inspector", inspectorMessageFixtureType) { scope ->
            val name =
                scope.field<String, TextControl>(
                    "name",
                    TextControl::class,
                )
            val message =
                scope.field<String, TextControl>(
                    "message",
                    TextControl::class,
                )
            with(scope) {
                name()
                heading()
                message {
                    label("Message")
                    textInput()
                }
                remainingFields()
            }
        },
    )
}

/**
 * Every contribution the framework generates on the test classpath, with presentations built by [runtime], so tests
 * assemble the core catalog exactly as discovery would.
 */
internal fun frameworkContributions(
    runtime: PresentationRuntime = DefaultPresentationRuntime(),
): com.typewritermc.discovery.CatalogContributions {
    val entries = generatedProviderEntries()

    fun instance(entry: com.typewritermc.discovery.GeneratedProviderIndexEntry): Any {
        val type = Class.forName(entry.providerClass)
        return if (entry.kind ==
            GeneratedProviderKind.Presentation
        ) {
            type.getConstructor(PresentationRuntime::class.java).newInstance(runtime)
        } else {
            instantiateGeneratedProvider(type)
        }
    }
    val exportedKinds =
        setOf(
            GeneratedProviderKind.Type,
            GeneratedProviderKind.Presentation,
            GeneratedProviderKind.Configuration,
            GeneratedProviderKind.NativeBinding,
            GeneratedProviderKind.Relation,
            GeneratedProviderKind.EndpointBindings,
            GeneratedProviderKind.ResourceDisplay,
            GeneratedProviderKind.ResourceOperation,
        )
    val providers = entries.filter { it.kind in exportedKinds }.associateWith(::instance)
    val declarations =
        providers.filterKeys { it.kind == GeneratedProviderKind.Type }.map { (entry, value) ->
            val provider = value as com.typewritermc.discovery.GeneratedTypeProvider
            com.typewritermc.discovery.OwnedTypeDeclaration(
                origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                provider.definition,
                provider.display,
                provider.nativeClass,
                provider.searchKey,
            )
        }
    val presentations =
        providers.filterKeys { it.kind == GeneratedProviderKind.Presentation }.map { (entry, value) ->
            val provider = value as com.typewritermc.discovery.GeneratedPresentationProvider
            val owner = origin(entry.providerClass.substringAfterLast('.').replace('$', '_'))
            com.typewritermc.discovery.OwnedPresentation(owner, provider.descriptor(owner), provider)
        }
    return com.typewritermc.discovery.CatalogContributions(
        declarations = declarations,
        presentations = presentations,
        configurations =
            providers.filterKeys { it.kind == GeneratedProviderKind.Configuration }.map { (entry, value) ->
                val provider = value as com.typewritermc.discovery.GeneratedConfigurationProvider
                com.typewritermc.discovery.OwnedConfiguration(
                    origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                    provider.target,
                    provider,
                )
            },
        nativeBindings =
            providers.filterKeys { it.kind == GeneratedProviderKind.NativeBinding }.map { (entry, value) ->
                com.typewritermc.discovery.OwnedNativeBinding(
                    origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                    value as NativeBindingFactory,
                )
            },
        relations =
            providers
                .filterKeys {
                    it.kind == GeneratedProviderKind.Relation
                }.values
                .map { (it as com.typewritermc.discovery.GeneratedRelationProvider).contract },
        endpointBindings =
            providers
                .filterKeys {
                    it.kind == GeneratedProviderKind.EndpointBindings
                }.values
                .flatMap { (it as com.typewritermc.discovery.GeneratedEndpointBindingsProvider).bindings },
        displays =
            providers.filterKeys { it.kind == GeneratedProviderKind.ResourceDisplay }.map { (entry, value) ->
                com.typewritermc.discovery.OwnedResourceDisplay(
                    origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                    value as com.typewritermc.discovery.GeneratedResourceDisplayProvider,
                )
            },
        operations =
            providers.filterKeys { it.kind == GeneratedProviderKind.ResourceOperation }.map { (entry, value) ->
                (value as com.typewritermc.discovery.GeneratedResourceOperationProvider)
                    .contribute(origin(entry.providerClass.substringAfterLast('.').replace('$', '_')))
            },
    )
}
