package com.typewritermc.library

import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.InitializationCatalogPlanner
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.Icon
import com.typewritermc.types.IconDefinition
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import java.lang.reflect.Modifier
import java.util.Collections
import skirout.editor.v1.expression.ExpressionNode as WireExpressionNode
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

val FrameworkCatalogCreationTest by testSuite {
    test("framework catalog exposes icon and placement forms with usable resource defaults") {
        val generation = CatalogGeneration("framework creation")
        val entries = generatedProviderEntries()
        val definitions =
            entries
                .filter { it.kind == GeneratedProviderKind.Type }
                .map { entry ->
                    instantiateGeneratedProvider(Class.forName(entry.providerClass)) as GeneratedTypeProvider
                }.map(GeneratedTypeProvider::definition)
                .distinctBy(TypeDefinition::id)
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + definitions)
        val iconRepresentation = IconDefinition.declaration.representation as RepresentationTemplate.Record
        iconRepresentation.fields shouldBe emptyList()
        val factories =
            entries
                .filter { it.kind == GeneratedProviderKind.NativeBinding }
                .map { entry ->
                    instantiateGeneratedProvider(Class.forName(entry.providerClass)) as NativeBindingFactory
                }.distinctBy(NativeBindingFactory::provider)
        val bindings = FactoryNativeBindingRegistry(catalog, factories)
        val checkedIconify = (catalog.resolve(IconIconifyDefinition.use) as Resolution.Ready).value
        val encodedIcon =
            bindings
                .bind(checkedIconify)
                .encodeGeneratedDefault(
                    Icon.Iconify("material-symbols:book"),
                )
        encodedIcon shouldBe
            DataValue.Named(
                IconIconifyDefinition.use,
                DataValue.Record(mapOf("value" to DataValue.StringValue("material-symbols:book"))),
            )
        val initialization = InitializationCatalogPlanner(catalog, bindings).plan(definitions, emptyMap())
        val initializer = DefaultInitializationRuntime(catalog, bindings, initialization.descriptors)

        val book = initializer.prepareNow(request(generation, BookDefinition.use, "book"))
        val icon = book.record.fields.getValue("icon") as DataValue.Named
        icon.actualType shouldBe IconIconifyDefinition.use
        book.findings shouldBe emptyList()

        val tag = initializer.prepareNow(request(generation, TagDefinition.use, "tag"))
        tag.findings shouldBe emptyList()
        tag.record.fields.getValue("name") shouldBe DataValue.StringValue("")
        (tag.record.fields.getValue("color") is DataValue.Named) shouldBe true
        val parents = tag.record.fields.getValue("parents") as DataValue.Named
        parents.payload shouldBe DataValue.SetValue(emptyList())
        val placement = tag.record.fields.getValue("placement") as DataValue.Named
        placement.actualType shouldBe GraphPlacementDefinition.use
        placement.payload shouldBe
            DataValue.Record(
                mapOf(
                    "x" to DataValue.Integer(java.math.BigInteger.ZERO),
                    "y" to DataValue.Integer(java.math.BigInteger.ZERO),
                    "width" to DataValue.Integer(java.math.BigInteger.ONE),
                    "height" to DataValue.Integer(java.math.BigInteger.ONE),
                ),
            )

        val runtime = DefaultPresentationRuntime()
        val iconifyProvider =
            com.typewritermc.types
                .com_typewritermc_types_CoreIconSdkProvider_IconIconifyPresentationProvider(runtime)
        val svgProvider =
            com.typewritermc.types
                .com_typewritermc_types_CoreIconSdkProvider_IconSvgPresentationProvider(runtime)
        val placementProvider =
            com.typewritermc.authoring
                .com_typewritermc_authoring_PlacementSdkProvider_GraphPlacementPresentationProvider(runtime)
        val bookProvider = com_typewritermc_library_BookInspectorPresentation_BookPresentationProvider(runtime)
        val tagProvider = com_typewritermc_library_TagInspectorPresentation_TagPresentationProvider(runtime)
        val pageProvider = com_typewritermc_library_PageInspectorPresentation_PagePresentationProvider(runtime)
        val bookReferenceProvider = com_typewritermc_library_BookReferencePresentation_BookPresentationProvider(runtime)
        val tagReferenceProvider = com_typewritermc_library_TagReferencePresentation_TagPresentationProvider(runtime)
        val tagGraphProvider = com_typewritermc_library_TagGraphNodePresentation_TagPresentationProvider(runtime)
        val pageReferenceProvider = com_typewritermc_library_PageReferencePresentation_PagePresentationProvider(runtime)
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
        val checkedBook = (catalog.resolve(BookDefinition.use) as Resolution.Ready).value
        val resourceTypes =
            factories
                .mapNotNull { factory ->
                    val native = factory.nativeClass ?: return@mapNotNull null
                    val definition = definitions.singleOrNull { it.id == factory.definition } ?: return@mapNotNull null
                    native to TypeTemplate.Named(definition.id, definition.parameters.map { TypeTemplate.Parameter(it.key) })
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
                com.typewritermc.types.skir.SkirTypeCodec
                    .encode(IconIconifyDefinition.use)
                    .getOrThrow(),
                com.typewritermc.types.skir.SkirTypeCodec
                    .encode(IconSvgDefinition.use)
                    .getOrThrow(),
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

        val checkedTag = (catalog.resolve(TagDefinition.use) as Resolution.Ready).value
        val graphMaterial =
            tagGraphProvider.build(
                PresentationBuildBinding(checkedTag.presentationTemplate(), PresentationRole.GRAPH_NODE, resourceTypes),
            )
        val graphSurface = (graphMaterial.layout.singleFixed().element as PresentationElement.ContainerWrapper).value
        graphSurface.transitionMilliseconds shouldBe 100
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

        val checkedPage = (catalog.resolve(PageDefinition.use) as Resolution.Ready).value
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
                    PresentationRole.REFERENCE_SUMMARY,
                    resourceTypes,
                ),
            )
        val bookLeading =
            bookSummary.layout
                .adaptiveLeading()
                .leading
        (bookLeading.element is PresentationElement.PolymorphicMatchWrapper) shouldBe true
        val summary = bookSummary.layout.adaptiveLeading()
        val authoredBook =
            DataValue.Named(
                BookDefinition.use,
                DataValue.Record(book.record.fields + ("title" to DataValue.StringValue("b"))),
            )
        val configured = WireExpressionBindingId(value = "configured_value")
        val title = summary.center!!.element as PresentationElement.TextWrapper
        title.value.value.evaluate(mapOf(configured to authoredBook)) shouldBe DataValue.StringValue("b")
        title.value.value.evaluate(
            mapOf(
                configured to
                    DataValue.Named(
                        BookDefinition.use,
                        DataValue.Record(book.record.fields),
                    ),
            ),
        ) shouldBe DataValue.StringValue("Unnamed Book")

        val match = bookLeading.element as PresentationElement.PolymorphicMatchWrapper
        val iconValue = requireNotNull(authoredBook.at(match.value.binding.path))
        val iconCase =
            match.value.cases.single { candidate ->
                candidate.concreteType ==
                    com.typewritermc.types.skir.SkirTypeCodec
                        .encode(IconIconifyDefinition.use)
                        .getOrThrow()
            }
        val headerIcon = iconCase.child.singleFixed().element as PresentationElement.IconWrapper
        headerIcon.value.name.evaluate(mapOf(match.value.scopeBindingId to iconValue)) shouldBe
            DataValue.StringValue("material-symbols:book")

        val tagSummary =
            tagReferenceProvider.build(
                PresentationBuildBinding(
                    checkedTag.presentationTemplate(),
                    PresentationRole.REFERENCE_SUMMARY,
                    resourceTypes,
                ),
            )
        val tagLeading =
            tagSummary.layout
                .adaptiveLeading()
                .leading
        val tagIcon = tagLeading.element
        (tagIcon is PresentationElement.IconWrapper) shouldBe true

        val pageSummary =
            pageReferenceProvider.build(
                PresentationBuildBinding(
                    checkedPage.presentationTemplate(),
                    PresentationRole.REFERENCE_SUMMARY,
                    resourceTypes,
                ),
            )
        val pageIcon =
            pageSummary.layout
                .adaptiveLeading()
                .leading
                .element
        (pageIcon is PresentationElement.IconWrapper) shouldBe true

        val checkedPlacement = (catalog.resolve(GraphPlacementDefinition.use) as Resolution.Ready).value
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
        exportFrameworkControlFixture(entries, tag.record, book.record, tag.record.fields.getValue("placement"))
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

private fun WireExpressionNode.evaluate(bindings: Map<WireExpressionBindingId, DataValue>): DataValue? =
    when (this) {
        is WireExpressionNode.LiteralWrapper -> {
            SkirDataValueCodec.decode(value).getOrThrow()
        }

        is WireExpressionNode.ReadWrapper -> {
            bindings[value.binding]?.at(value.path)
        }

        is WireExpressionNode.CallWrapper -> {
            when (value.operation.value) {
                "typewriter.rule.nonBlank" -> {
                    DataValue.Boolean(
                        (value.arguments.single().evaluate(bindings) as? DataValue.StringValue)?.value?.isNotBlank() == true,
                    )
                }

                else -> {
                    error("The material expression uses an unsupported test operation")
                }
            }
        }

        is WireExpressionNode.ConditionalWrapper -> {
            if ((value.test.evaluate(bindings) as? DataValue.Boolean)?.value == true) {
                value.yes.evaluate(bindings)
            } else {
                value.no.evaluate(bindings)
            }
        }

        is WireExpressionNode.OrElseWrapper -> {
            value.input.evaluate(bindings).let { resolved ->
                if (resolved == null || resolved == DataValue.Null || resolved == DataValue.Unfilled) {
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
        while (current is DataValue.Named) current = current.payload
        val segment =
            SkirAuthoringValueCodec
                .decode(WireValuePath(segments = listOf(wireSegment)))
                .getOrThrow()
                .segments
                .single()
        current =
            when (segment) {
                is com.typewritermc.authoring.PathSegment.Field -> {
                    (current as? DataValue.Record)?.fields?.get(segment.name)
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
    use: TypeUse.Named,
    id: String,
) = InitializationRequest(
    id = InitializationRequestId(id),
    catalog = generation,
    target = PreparationTarget.Record(TypeSelection.Complete(use)),
    supplied = DataValue.Record(emptyMap()),
    intentHash = "framework creation",
)

private val PreparedValue.record
    get() = (content as PreparedContent.Record).record

private fun origin(name: String): ProviderOrigin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    ContributionKey(
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
    entries: List<com.typewritermc.discovery.GeneratedProviderIndexEntry>,
    tag: com.typewritermc.authoring.AuthoringRecord,
    book: com.typewritermc.authoring.AuthoringRecord,
    placement: DataValue,
) {
    val directory = System.getenv("TYPEWRITER_CONTROL_FIXTURE_DIR")?.let { java.io.File(it) } ?: return
    val runtime = DefaultPresentationRuntime()

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
            GeneratedProviderKind.Resource,
            GeneratedProviderKind.Relation,
            GeneratedProviderKind.EndpointBindings,
        )
    val providers = entries.filter { it.kind in exportedKinds }.associateWith(::instance)
    val declarations =
        providers.filterKeys { it.kind == GeneratedProviderKind.Type }.map { (entry, value) ->
            val provider = value as com.typewritermc.discovery.GeneratedTypeProvider
            com.typewritermc.discovery.OwnedTypeDeclaration(
                origin(entry.providerClass.substringAfterLast('.')),
                provider.definition,
                provider.display,
            )
        }
    val presentations =
        providers.filterKeys { it.kind == GeneratedProviderKind.Presentation }.map { (entry, value) ->
            val provider = value as com.typewritermc.discovery.GeneratedPresentationProvider
            val owner = origin(entry.providerClass.substringAfterLast('.'))
            com.typewritermc.discovery.OwnedPresentation(owner, provider.descriptor(owner), provider)
        }
    val contributions =
        com.typewritermc.discovery.CatalogContributions(
            declarations = declarations,
            presentations = presentations,
            configurations =
                providers.filterKeys { it.kind == GeneratedProviderKind.Configuration }.map { (entry, value) ->
                    val provider = value as com.typewritermc.discovery.GeneratedConfigurationProvider
                    com.typewritermc.discovery.OwnedConfiguration(
                        origin(entry.providerClass.substringAfterLast('.')),
                        provider.target,
                        provider,
                    )
                },
            nativeBindings =
                providers.filterKeys { it.kind == GeneratedProviderKind.NativeBinding }.map { (entry, value) ->
                    com.typewritermc.discovery.OwnedNativeBinding(
                        origin(entry.providerClass.substringAfterLast('.')),
                        value as NativeBindingFactory,
                    )
                },
            resources =
                providers
                    .filterKeys {
                        it.kind == GeneratedProviderKind.Resource
                    }.values
                    .map { (it as com.typewritermc.discovery.GeneratedResourceProvider).definition },
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
        )
    val assembly = contributions.assemble(com.typewritermc.discovery.CatalogAssemblyContext(CatalogGeneration("compiled controls fixture")))
    assembly.snapshot.diagnostics.filter { it.code.contains("presentation") } shouldBe emptyList()
    val wire =
        com.typewritermc.types.skir.SkirTypeCodec
            .encode(assembly.snapshot)
            .getOrThrow()
    directory.mkdirs()
    java.io.File(directory, "book.bin").writeBytes(
        skirout.editor.v1.type_catalog.AuthoringRecord.serializer
            .toBytes(SkirAuthoringValueCodec.encode(book).getOrThrow())
            .toByteArray(),
    )
    java.io.File(directory, "book-value.bin").writeBytes(
        skirout.editor.v1.type_catalog.DataValue.serializer
            .toBytes(SkirDataValueCodec.encode(DataValue.Named(BookDefinition.use, DataValue.Record(book.fields))).getOrThrow())
            .toByteArray(),
    )
    java.io
        .File(
            directory,
            "catalog.bin",
        ).writeBytes(
            skirout.editor.v1.catalog.EditorCatalogWireSnapshot.serializer
                .toBytes(wire)
                .toByteArray(),
        )
    java.io
        .File(
            directory,
            "tag.bin",
        ).writeBytes(
            skirout.editor.v1.type_catalog.AuthoringRecord.serializer
                .toBytes(SkirAuthoringValueCodec.encode(tag).getOrThrow())
                .toByteArray(),
        )
    java.io
        .File(
            directory,
            "tag-value.bin",
        ).writeBytes(
            skirout.editor.v1.type_catalog.DataValue.serializer
                .toBytes(
                    SkirDataValueCodec.encode(DataValue.Named(TagDefinition.use, DataValue.Record(tag.fields))).getOrThrow(),
                ).toByteArray(),
        )
    java.io
        .File(
            directory,
            "placement.bin",
        ).writeBytes(
            skirout.editor.v1.type_catalog.DataValue.serializer
                .toBytes(SkirDataValueCodec.encode(placement).getOrThrow())
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
