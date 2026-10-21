@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.coreTagCollectionProjection
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.text
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.CollectionGraphDirection
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.FlexFit
import skirout.editor.v1.presentation.ImageFit
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationTextTone
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath

val DefaultPresentationRuntimeTest by testSuite {
    test("caller inputs register one typed dependency without copying canonical facts") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("caller inputs"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val key = presentationContextKey<ResourceId>("test.active_resource")
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(
                    checked.presentationTemplate(),
                    PresentationRole.RESOURCE_SEARCH_RESULT,
                    mapOf(
                        ResourceId::class to
                            com.typewritermc.types.ResourceIdDefinition.id
                                .namedTemplate(),
                    ),
                ),
            ) { build ->
                build.text(
                    build.context
                        .read(key)
                        .text
                        .orElse(literal("No origin")),
                )
                build.text(
                    build.context
                        .read(key)
                        .text
                        .orElse(literal("No origin")),
                )
            }
        val input = result.dependencies.contextInputs.single()
        input.bindingId.value shouldBe "context:test.active_resource"
        input.source shouldBe skirout.editor.v1.presentation.PresentationContextSource.CALLER
        input.valueType shouldBe com.typewritermc.types.ResourceIdDefinition.use.use
    }

    test("host inputs declare their host source and the host contract's value types") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("host inputs"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.RESOURCE_SEARCH_RESULT),
            ) { build ->
                build.text(
                    build.context
                        .read(EditorContext.activeResource)
                        .text
                        .orElse(literal("No origin")),
                )
                build.showIf(build.context.read(EditorContext.selectionCount).orElse(literal(1)) eq literal(1)) {}
            }
        val inputs = result.dependencies.contextInputs.associateBy { it.source }
        val active =
            inputs.getValue(
                skirout.editor.v1.presentation.PresentationContextSource.HostWrapper(
                    skirout.editor.v1.presentation.HostContextInput.ACTIVE_RESOURCE,
                ),
            )
        active.bindingId.value shouldBe EditorContext.activeResource.binding.value
        active.valueType shouldBe com.typewritermc.types.ResourceIdDefinition.use.use
        val count =
            inputs.getValue(
                skirout.editor.v1.presentation.PresentationContextSource.HostWrapper(
                    skirout.editor.v1.presentation.HostContextInput.SELECTION_COUNT,
                ),
            )
        count.bindingId.value shouldBe EditorContext.selectionCount.binding.value
        count.valueType shouldBe
            integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
        inputs.size shouldBe 2
    }

    test("callable part keys compile declarations requests and typed exclusions with canonical owner identity") {
        val id = TypeDefinitionId.qualified("test", "PartOwner")
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("parts"),
                StandardTypes.definitions +
                    TypeDefinition.partial(
                        id = id,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
            )
        val checked = catalog.ready(id.use())
        val heading = presentationPart<String>("heading")
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(
                    checked.presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    mapOf(String::class to id.namedTemplate()),
                ),
            ) { build ->
                with(build) {
                    heading { text(literal("Shared heading")) }
                    heading()
                    remainingFields { exclude(heading) }
                }
            }
        val nodes = ((result.layout.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper).value.children
        val definition =
            (nodes[0] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element as PresentationElement.PartWrapper
        val request = (nodes[1] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element as PresentationElement.PartWrapper
        val rest =
            (nodes[2] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element as PresentationElement.RemainingFieldsWrapper
        definition.value.key.owner shouldBe id
        definition.value.key.name shouldBe "heading"
        (definition.value.body != null) shouldBe true
        request.value.body shouldBe null
        rest.value.excludedParts shouldBe listOf(definition.value.key)
        result.layout.validateInheritableNodes(result.layout.inferInheritableNodes()) { true }
    }

    test("nested record part requests bind the configured record to their field") {
        val nestedId = TypeDefinitionId.qualified("test", "NestedPartOwner")
        val rootId = TypeDefinitionId.qualified("test", "PartEnvelope")
        val nested =
            TypeDefinition.partial(
                id = nestedId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val root =
            TypeDefinition.partial(
                id = rootId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = rootId, name = "details"),
                                    type = nestedId.template(),
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("nested part request"), StandardTypes.definitions + listOf(nested, root))
        val heading = presentationPart<String>("heading")
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(
                    catalog.ready(rootId.use()).presentationTemplate(),
                    PresentationRole.INSPECTOR,
                    mapOf(String::class to nestedId.namedTemplate()),
                ),
            ) { build ->
                @Suppress("UNCHECKED_CAST")
                val details =
                    build.field<Any, RecordControl<Layout>>(
                        "details",
                        RecordControl::class as kotlin.reflect.KClass<RecordControl<Layout>>,
                        mapOf(NestedPresentationSlot.Fields to NestedPresentationScope(Layout::class, create = { it })),
                    )
                details { recordInput { fields { heading() } } }
            }
        val record = result.layout.singleFixed().element as PresentationElement.RecordInputWrapper
        val scope =
            record.value.fieldPresentation!!
                .singleFixed()
                .element as PresentationElement.ScopedBindingWrapper
        scope.value.binding.path.segments shouldBe
            listOf(
                PathSegment.createField(name = "details"),
            )
        scope.value.scopeBindingId.value shouldBe "configured_value"
        val part = scope.value.child.element as PresentationElement.PartWrapper
        part.value.key.owner shouldBe nestedId
        part.value.body shouldBe null
        result.layout.inferInheritableNodes() shouldBe emptyList()
    }

    test("clipped fixed and repeated rows preserve one line layout") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("clipped rows"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.RESOURCE_SEARCH_RESULT),
            ) { build ->
                build.clippedRow(spacing = 4.0) {
                    text(literal("Book"))
                    text(literal("Page"))
                }
                build.repeated<String, String>(com.typewritermc.expression.emptyListExpression()) {
                    clippedRow(spacing = 4.0)
                    text(item.orElse(literal("")))
                }
            }
        val roots = result.layout.fixedChildren()
        val fixed = ((roots.first().element as PresentationElement.ChildrenWrapper).value as ChildrenElement.RowWrapper).value
        fixed.layout.clipOverflow shouldBe true
        fixed.layout.spacing shouldBe 4.0
        val repeated = (roots.last().element as PresentationElement.RepeatedWrapper).value
        val sequence = repeated.presentation.layout as skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper
        val layout = sequence.value as skirout.editor.v1.presentation.ChildrenLayout.RowWrapper
        layout.value.clipOverflow shouldBe true
        layout.value.spacing shouldBe 4.0
    }

    test("headers acquire data scopes only when explicitly declared") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("header diagnostics"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                val field: PresentedField<String, TextControl> = build.value(TextControl::class)
                build.node("content", header = { title(literal("Content")) }) {
                    text(literal("Ordinary content"))
                }
                build.node("summary", header = { diagnostics(field.input) }) {
                    text(literal("The editor is absent"))
                }
            }
        val nodes = result.layout.fixedChildren()
        nodes[0].header?.binding shouldBe null
        val explicit = requireNotNull(nodes[1].header?.binding)
        explicit.bindingId.value shouldBe "configured_value"
        explicit.path.segments shouldBe emptyList()
    }

    for (count in 0..2) {
        test("presentation bodies preserve their content with $count nodes") {
            val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation bodies"), StandardTypes.definitions)
            val checked = catalog.ready(ScalarKind.TEXT.use)
            val result =
                DefaultPresentationRuntime().build(
                    PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
                ) { build ->
                    val field: PresentedField<String, TextControl> = build.value(TextControl::class)
                    field {
                        textInput {
                            prefix { repeat(count) { text(literal("prefix $it")) } }
                        }
                    }
                    build.tooltip(literal("Details")) { repeat(count) { text(literal("tooltip $it")) } }
                }
            val roots = result.layout.fixedChildren()
            val prefix =
                (
                    (roots[0].element as PresentationElement.TextInputWrapper).value.content!!.leading as
                        skirout.editor.v1.presentation.InputAdornment.ContentWrapper
                ).value
            val tooltip = (roots[1].element as PresentationElement.TooltipWrapper).value.child
            for ((node, label) in listOf(prefix to "prefix", tooltip to "tooltip")) {
                val contents = if (count == 1) listOf(node) else node.fixedChildren()
                contents.size shouldBe count
                contents.map { child ->
                    val text = (child.element as PresentationElement.TextWrapper).value.value
                    (
                        (text as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper).value as
                            skirout.editor.v1.type_catalog.DataValue.StringValueWrapper
                    ).value
                } shouldBe List(count) { "$label $it" }
            }
        }
    }

    test("display families lower their declared options through shared appearance and glyph delegates") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("display options"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val color = literalColor(com.typewritermc.types.Color(0xff3366ccu))
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                with(build) {
                    image(literal("https://example.test/image.png")) {
                        width(80.0)
                        height(literal(60.0))
                        fit(ImageFit.COVER)
                        radius(PresentationRadius.Small)
                    }
                    badge(literal("Ready")) {
                        textStyle(TextStyle(weight = 500))
                        fill(color)
                        icon("book", size = 14.0)
                    }
                    chip(literal("Label")) {
                        noIcon()
                        noBorder()
                        density(ControlDensity.COMPACT)
                    }
                    progress(literal(3), literal(10)) {
                        color(color)
                        backgroundColor(color)
                        minimumHeight(5.0)
                        radius(PresentationRadius.Small)
                    }
                    tooltip(literal("Details"), configure = {
                        waitMilliseconds(250)
                        showMilliseconds(2000)
                        preferBelow(false)
                        fill(color)
                    }) { text(literal("Help")) }
                    divider {
                        color(color)
                        thickness(2.0)
                        space(literal(12.0))
                        indent(4.0)
                        endIndent(6.0)
                    }
                    tabs {
                        density(ControlDensity.COMPACT)
                        spacing(4.0)
                        contentSpacing(10.0)
                        tab("first", literal("First"), icon = "book") { text(literal("Content")) }
                    }
                    status(
                        literal(true),
                        listOf(
                            StatusCase(
                                true,
                                StatusAppearance("Active", "active") {
                                    noIcon()
                                    textStyle(TextStyle(weight = 600))
                                },
                            ),
                        ),
                    )
                    dateTime(literal(kotlin.time.Instant.fromEpochMilliseconds(1000)), literal("yyyy")) {
                        noIcon()
                        textStyle(TextStyle(weight = 500))
                    }
                    relativeTime(literal(kotlin.time.Instant.fromEpochMilliseconds(1000))) {
                        noIcon()
                        density(ControlDensity.COMPACT)
                    }
                }
            }
        val nodes = result.layout.fixedChildren().map { it.element }
        val image = (nodes[0] as PresentationElement.ImageWrapper).value
        image.options?.fit shouldBe skirout.editor.v1.presentation.ImageFit.COVER
        (image.options?.width != null) shouldBe true
        val badge = (nodes[1] as PresentationElement.BadgeWrapper).value
        badge.options
            ?.appearance
            ?.valueStyle
            ?.weight shouldBe 500
        (badge.options?.icon is skirout.editor.v1.presentation.InputAdornment.ContentWrapper) shouldBe true
        (nodes[2] as PresentationElement.ChipWrapper).value.options?.icon shouldBe skirout.editor.v1.presentation.InputAdornment.NONE
        ((nodes[3] as PresentationElement.ProgressWrapper).value.appearance?.minimumHeight != null) shouldBe true
        (nodes[4] as PresentationElement.TooltipWrapper).value.appearance?.waitMilliseconds shouldBe 250
        ((nodes[5] as PresentationElement.DividerWrapper).value.endIndent != null) shouldBe true
        val tabs = (nodes[6] as PresentationElement.TabsWrapper).value
        tabs.spacing shouldBe 4.0
        tabs.contentSpacing shouldBe 10.0
        (tabs.tabs.single().icon != null) shouldBe true
        (nodes[7] as PresentationElement.StatusWrapper)
            .value.cases
            .single()
            .appearance.options
            ?.icon shouldBe
            skirout.editor.v1.presentation.InputAdornment.NONE
        (nodes[8] as PresentationElement.DateTimeWrapper)
            .value.options
            ?.appearance
            ?.valueStyle
            ?.weight shouldBe 500
        (nodes[9] as PresentationElement.RelativeTimeWrapper)
            .value.options
            ?.appearance
            ?.density shouldBe
            skirout.editor.v1.presentation.ControlDensity.COMPACT
    }

    test("field publication captures metadata after control selection and direct row fields share width") {
        val id = TypeDefinitionId.qualified("test", "ConfiguredCoordinates")
        val number = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
        val definition =
            TypeDefinition.partial(
                id = id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "x"), type = number),
                                FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "y"), type = number),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("configured coordinates"), listOf(definition))
        val checked = catalog.ready(id.use())

        fun NumericInputScope<Int>.coordinateInput() {
            step(2)
            density(ControlDensity.COMPACT)
            selectAllOnFocus()
            textStyle(TextStyle(weight = 500))
        }
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val scope = NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>
                    val x: PresentedField<Int, NumberControl<Int>> = field("x", scope)
                    val y: PresentedField<Int, NumberControl<Int>> = field("y", scope)
                    row {
                        x {
                            numericInput {
                                coordinateInput()
                                placeholder("X")
                                noIcon()
                                prefix { text(literal("axis")) }
                                onComplete { value }
                            }
                            label("Horizontal")
                            readOnly()
                            enabledIf(literal(false))
                        }
                        y {
                            label("Vertical")
                            numericInput {
                                coordinateInput()
                                placeholder(literal("Y"))
                            }
                        }
                        text(literal("units"))
                    }
                }
            }
        val row = ((result.layout.singleFixed().element as PresentationElement.ChildrenWrapper).value as ChildrenElement.RowWrapper).value
        row.children.map { it.kind } shouldBe
            listOf(
                skirout.editor.v1.presentation.AxisChild.Kind.FLEXIBLE_WRAPPER,
                skirout.editor.v1.presentation.AxisChild.Kind.FLEXIBLE_WRAPPER,
                skirout.editor.v1.presentation.AxisChild.Kind.FIXED_WRAPPER,
            )
        val xNode = (row.children[0] as skirout.editor.v1.presentation.AxisChild.FlexibleWrapper).value.child
        val x = (xNode.element as PresentationElement.NumericInputWrapper).value
        val y =
            (
                (row.children[1] as skirout.editor.v1.presentation.AxisChild.FlexibleWrapper).value.child.element as
                    PresentationElement.NumericInputWrapper
            ).value
        (row.children[0] as skirout.editor.v1.presentation.AxisChild.FlexibleWrapper).value.flex shouldBe 1
        (x.control.label as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper).value shouldBe
            skirout.editor.v1.type_catalog.DataValue
                .StringValueWrapper("Horizontal")
        xNode.properties.readOnly shouldBe true
        (xNode.properties.enabledIf != null) shouldBe true
        x.appearance?.density shouldBe skirout.editor.v1.presentation.ControlDensity.COMPACT
        x.appearance?.valueStyle?.weight shouldBe 500
        x.entry?.selectAllOnFocus shouldBe true
        x.options.step shouldBe y.options.step
        (x.mappings?.completion != null) shouldBe true
        y.mappings?.completion shouldBe null
        (x.content?.leading is skirout.editor.v1.presentation.InputAdornment.ContentWrapper) shouldBe true
        y.content?.leading shouldBe null
    }

    test("appearance defaults are immutable sparse wrappers and local controls stay sparse") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("input appearance"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val shared =
            inputAppearance {
                density(ControlDensity.COMPACT)
                textStyle(TextStyle(weight = 600))
                noBorder()
            }
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    val text: PresentedField<String, TextControl> = value(TextControl::class)
                    withInputAppearance(shared) {
                        text {
                            textInput {
                                placeholder("Name")
                                textStyle(TextStyle(sizing = TextSizing.Exact(literal(18.0))))
                            }
                        }
                    }
                }
            }
        val wrapper = (result.layout.singleFixed().element as PresentationElement.AppearanceDefaultsWrapper).value
        wrapper.appearance shouldBe shared
        wrapper.appearance.valueStyle?.weight shouldBe 600
        val input = (wrapper.child.singleFixed().element as PresentationElement.TextInputWrapper).value
        input.appearance?.density shouldBe null
        input.appearance?.valueStyle?.weight shouldBe null
        (input.appearance?.valueStyle?.sizing != null) shouldBe true
        shared.valueStyle?.sizing shouldBe null
    }

    test("default control receives metadata authored after prefix and no explicit editor") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("default metadata"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                val text: PresentedField<String, TextControl> = build.value(TextControl::class)
                text {
                    prefix { text(literal("prefix")) }
                    label("Name")
                    readOnly()
                }
            }
        val node = result.layout.singleFixed()
        val control = (node.element as PresentationElement.DefaultPresentationWrapper).value.control
        (control.prefix != null) shouldBe true
        (control.label != null) shouldBe true
        node.properties.readOnly shouldBe true
    }

    test("surface policies serialize through ordinary presentation nodes") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("surface policies"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val accent = literalColor(com.typewritermc.types.Color(0x803366ccu))
        val fill =
            stateColor(accent.withAlpha(0.2)) {
                whenAll(PresentationInteractionState.SELECTED, color = accent)
                whenAll(PresentationInteractionState.HOVERED, color = accent.withAlpha(0.5))
            }
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                build.container(
                    ContainerStyle(
                        background = fill,
                        foreground = ambientBackground().on(),
                        radius = PresentationRadius.Large,
                        transition = stateTransition(transition(milliseconds = 100)),
                    ),
                ) {
                    align(PresentationAlignment.CENTER) { text(literal("Adventure")) }
                }
            }
        val container = (result.layout.singleFixed().element as PresentationElement.ContainerWrapper).value
        val states = (container.backgroundColor as skirout.editor.v1.presentation.PresentationColor.StatesWrapper).value
        states.rules.map { it.match.required } shouldBe
            listOf(
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.SELECTED),
                listOf(skirout.editor.v1.presentation.PresentationInteractionState.HOVERED),
            )
        (states.fallback as skirout.editor.v1.presentation.PresentationColor.AlphaWrapper).value.alpha shouldBe 0.2
        val contrast = (container.foregroundColor as skirout.editor.v1.presentation.PresentationColor.ContrastWrapper).value
        contrast.source shouldBe
            skirout.editor.v1.presentation.PresentationColor.AmbientWrapper(
                skirout.editor.v1.presentation.PresentationAmbientColor.BACKGROUND,
            )
        container.transition?.fallback?.milliseconds shouldBe 100
        val alignment = (container.child.singleFixed().element as PresentationElement.AlignWrapper).value
        alignment.alignment shouldBe skirout.editor.v1.presentation.PresentationAlignment.CENTER
    }

    test("resource headings compose ordinary nodes with identity and pane context") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("headings"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                with(build) {
                    resourceHeading(literal("A title"), literal(com.typewritermc.types.Color(0xff123456u)), subject.identifier.text)
                }
            }
        val conditional = result.layout.singleFixed().element as PresentationElement.ConditionalWrapper
        val condition = conditional.value.condition as skirout.editor.v1.expression.ExpressionNode.ValueCompareWrapper
        condition.value.operation shouldBe skirout.editor.v1.expression.ValueCompareOperation.EQUAL
        val count = condition.value.left as skirout.editor.v1.expression.ExpressionNode.OrElseWrapper
        (count.value.input as skirout.editor.v1.expression.ExpressionNode.InputWrapper).value.binding.value shouldBe
            EditorContext.selectionCount.binding.value
        result.dependencies.contextInputs
            .single()
            .source shouldBe
            skirout.editor.v1.presentation.PresentationContextSource.HostWrapper(
                skirout.editor.v1.presentation.HostContextInput.SELECTION_COUNT,
            )
        val paragraphs =
            conditional.value.whenTrue
                .singleFixed()
                .fixedChildren()
        val title = (paragraphs.first().element as PresentationElement.TextWrapper).value
        val fit = title.sizing as skirout.editor.v1.presentation.TextSizing.FitWrapper
        ((fit.value.minimum as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper).value).requirePortable() shouldBe
            DataValue.FloatWrapper(18.0)
        ((fit.value.maximum as skirout.editor.v1.expression.ExpressionNode.LiteralWrapper).value).requirePortable() shouldBe
            DataValue.FloatWrapper(40.0)
        title.paragraph.maxLines shouldBe 1
        title.paragraph.selectable shouldBe true
        title.paragraph.overflow shouldBe skirout.editor.v1.presentation.PresentationTextOverflow.ELLIPSIS
        val identity = paragraphs.last().element as PresentationElement.ConditionalWrapper
        val idText =
            (
                identity.value.whenTrue
                    .singleFixed()
                    .element as PresentationElement.TextWrapper
            ).value
        idText.paragraph.selectable shouldBe true
        idText.paragraph.softWrap shouldBe true
        val identifier = idText.value as skirout.editor.v1.expression.ExpressionNode.OrElseWrapper
        val representation = identifier.value.input as skirout.editor.v1.expression.ExpressionNode.TextUnaryWrapper
        val identityRead = representation.value.source as skirout.editor.v1.expression.ExpressionNode.InputWrapper
        identityRead.value.binding.value shouldBe "presentation.subject.identifier"
    }

    test("rich paragraphs serialize sizing and paragraph behavior") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("rich sizing"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                build.richText {
                    sizing(TextSizing.Fit(literal(18.0), literal(40.0)))
                    paragraph(TextParagraph(maximumLines = 2, softWrap = true, selectable = true, tone = PresentationTextTone.SECONDARY))
                    style(TextStyleOverride(color = literal(com.typewritermc.types.Color(0xff123456u)).asPresentationColor(), weight = 500))
                    run(literal("First"))
                    run(literal("Second"), TextStyleOverride(weight = 700))
                }
            }
        val text = (result.layout.singleFixed().element as PresentationElement.RichTextWrapper).value
        (text.sizing is skirout.editor.v1.presentation.TextSizing.FitWrapper) shouldBe true
        text.paragraph.maxLines shouldBe 2
        text.paragraph.softWrap shouldBe true
        text.paragraph.selectable shouldBe true
        text.paragraph.tone shouldBe skirout.editor.v1.presentation.PresentationTextTone.SECONDARY
        text.runs.size shouldBe 2
        (text.style?.color != null) shouldBe true
        val restored =
            skirout.editor.v1.presentation.RichTextContent.serializer.fromBytes(
                skirout.editor.v1.presentation.RichTextContent.serializer
                    .toBytes(text),
            )
        restored shouldBe text
    }

    test("builds one symbolic generic material and applies it to concrete uses") {
        val id = TypeDefinitionId.qualified("test", "Weighted")
        val parameter = ParameterKey(owner = id, index = 0)
        val definition =
            TypeDefinition.partial(
                id = id,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = id, name = "weight"),
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val target = PresentationTarget.Named(id.namedTemplate(listOf(parameter.template)))
        val descriptor = descriptor("weighted", target, 0, PresentationRole.INSPECTOR)
        val origin = ProviderOrigin(descriptor.owner, ArtifactId("test:presentation"), "main")
        val runtime = DefaultPresentationRuntime()
        var invalidMapping = false
        val provider =
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                    runtime.build(binding) { build ->
                        with(build) {
                            val value: PresentedField<Any?, Control> = field("value", Control::class)
                            typedField(value.input) { }
                            val weight: PresentedField<Int, NumberControl<Int>> =
                                field("weight", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
                            weight {
                                numericInput {
                                    minimum(literal(0))
                                    step(1)
                                    placeholder("Weight")
                                    density(ControlDensity.COMPACT)
                                    onComplete {
                                        @Suppress("UNCHECKED_CAST")
                                        if (invalidMapping) {
                                            literal(
                                                "wrong",
                                            ) as com.typewritermc.expression.Expr<Int, com.typewritermc.expression.Handled>
                                        } else {
                                            this.value
                                        }
                                    }
                                    display { literal("Weight") }
                                }
                                label("Relative weight")
                            }
                        }
                    }
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("symbolic presentation")))

        val material = assembly.editorCatalog.presentationMaterials.single()
        material.target shouldBe SkirTypeCodec.encode(target).getOrThrow()
        val valueNode =
            material.layout
                .fixedChildren()
                .first()
                .element as PresentationElement.TypedFieldWrapper
        val expected = valueNode.value.expectedType.requireValid()
        expected shouldBe parameter.template
        val weight = material.layout.fixedChildren()[1].element as PresentationElement.NumericInputWrapper
        weight.value.appearance?.density shouldBe skirout.editor.v1.presentation.ControlDensity.COMPACT
        (weight.value.options.minimum != null) shouldBe true
        (weight.value.options.step != null) shouldBe true
        (weight.value.content?.placeholder != null) shouldBe true
        (weight.value.mappings?.completion != null) shouldBe true
        (weight.value.mappings?.display != null) shouldBe true
        (weight.value.control.label != null) shouldBe true

        val text = mapOf(parameter to ScalarKind.TEXT.use)
        val integer = mapOf(parameter to integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use)
        (target.type.apply(text) as Resolution.Ready).value shouldBe id.namedUse(listOf(ScalarKind.TEXT.use))
        (target.type.apply(integer) as Resolution.Ready).value shouldBe
            id.namedUse(listOf(integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use))
        (expected.apply(text) as Resolution.Ready).value shouldBe ScalarKind.TEXT.use
        (expected.apply(integer) as Resolution.Ready).value shouldBe
            integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
        invalidMapping = true
        val rejected =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("invalid symbolic presentation")))
        rejected.editorCatalog.presentationMaterials.isEmpty() shouldBe true
        rejected.editorCatalog.diagnostics.isNotEmpty() shouldBe true
    }

    test("isolates a named presentation with an invalid collection projection") {
        val subjectId = TypeDefinitionId.qualified("test", "InvalidCollectionSubject")
        val unrelatedId = TypeDefinitionId.qualified("test", "UnrelatedCollectionSubject")
        val subject =
            TypeDefinition.partial(
                id = subjectId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "title"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val unrelated =
            TypeDefinition.partial(
                id = unrelatedId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val target = PresentationTarget.Named(subjectId.namedTemplate())
        val descriptor = descriptor("invalid collection", target, 0, PresentationRole.INSPECTOR)
        val origin = ProviderOrigin(descriptor.owner, ArtifactId("test:invalid-collection"), "main")
        val projection =
            CollectionProjection<ProjectionFixtureResource, Int, ProjectionFixtureExpressions>(
                specification =
                    CollectionProjectionSpec(
                        sourceId = "invalid",
                        root = subjectId.namedTemplate(),
                        rowType = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    target = ValuePath.root,
                                    source =
                                        CollectionProjectionValueSpec.Content(
                                            ValuePath.root.field("title"),
                                        ),
                                ),
                            ),
                    ),
                expressions = ProjectionFixtureExpressionsFactory,
            )
        val runtime = DefaultPresentationRuntime()
        val provider =
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                    runtime.build(binding) { build ->
                        with(build) {
                            val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                            val invalid = projection.projectedCollectionSource(key = { literal("key") })
                            collectionLookup(invalid, title.input) {
                                found { text(literal("found")) }
                                missing { text(literal("missing")) }
                            }
                        }
                    }
            }

        val assembly =
            CatalogContributions(
                declarations = listOf(ownedResource(origin, subject), OwnedTypeDeclaration(origin, unrelated)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(
                CatalogAssemblyContext(
                    CatalogGeneration("invalid presentation collection"),
                    relations = rootOwnership(subjectId),
                ),
            )

        val status =
            assembly.editorCatalog.types
                .single { it.definition.id == subjectId }
                .status as skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper
        status.value.map { it.code } shouldBe listOf("invalid_presentation_collection_dependency")
        assembly.editorCatalog.types
            .single { it.definition.id == unrelatedId }
            .status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
    }

    test("admits readable projection mappings from declared resource roots") {
        val baseId = TypeDefinitionId.qualified("test", "ProjectionBase")
        val childId = TypeDefinitionId.qualified("test", "ProjectionChild")
        val resourceId = TypeDefinitionId.qualified("test", "ProjectionResource")
        val base =
            TypeDefinition.partial(
                id = baseId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = baseId, name = "title"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val child =
            TypeDefinition.partial(
                id = childId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(baseId.namedTemplate()),
            )
        val resource =
            TypeDefinition.partial(
                id = resourceId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = resourceId, name = "child"),
                                    type = childId.template(),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = resourceId, name = "selected"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val target = PresentationTarget.Named(resourceId.namedTemplate())
        val descriptor = descriptor("valid collection", target, 0, PresentationRole.INSPECTOR)
        val origin = ProviderOrigin(descriptor.owner, ArtifactId("test:valid-collection"), "main")
        val projection =
            CollectionProjection<ProjectionFixtureResource, Any, ProjectionFixtureExpressions>(
                specification =
                    CollectionProjectionSpec(
                        sourceId = "valid",
                        root = resourceId.namedTemplate(),
                        rowType = baseId.template(),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    target = ValuePath.root,
                                    source =
                                        CollectionProjectionValueSpec.Content(
                                            ValuePath.root.field("child"),
                                        ),
                                ),
                            ),
                    ),
                expressions = ProjectionFixtureExpressionsFactory,
            )
        val runtime = DefaultPresentationRuntime()
        val provider =
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                    runtime.build(binding) { build ->
                        with(build) {
                            val selected: PresentedField<String, TextControl> = field("selected", TextControl::class)
                            val source = projection.projectedCollectionSource(key = { literal("key") })
                            collectionLookup(source, selected.input) {
                                found { text(literal("found")) }
                                missing { text(literal("missing")) }
                            }
                        }
                    }
            }

        val assembly =
            CatalogContributions(
                declarations =
                    listOf(OwnedTypeDeclaration(origin, base), OwnedTypeDeclaration(origin, child), ownedResource(origin, resource)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(
                CatalogAssemblyContext(
                    CatalogGeneration("valid presentation collection"),
                    relations = rootOwnership(resourceId),
                ),
            )

        assembly.editorCatalog.types
            .single { it.definition.id == resourceId }
            .status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
        assembly.editorCatalog.presentationMaterials
            .single()
            .dependencies.collections
            .single()
            .sourceId shouldBe "valid"
    }

    test("isolates collections with missing resources invalid bounds or invalid literals") {
        val missingId = TypeDefinitionId.qualified("test", "MissingResourceCollection")
        val literalId = TypeDefinitionId.qualified("test", "InvalidLiteralCollection")
        val boundedId = TypeDefinitionId.qualified("test", "InvalidBoundCollection")
        val unrelatedId = TypeDefinitionId.qualified("test", "ValidUnrelatedCollection")
        val baseId = TypeDefinitionId.qualified("test", "CollectionBound")
        val genericId = TypeDefinitionId.qualified("test", "BoundedCollectionRow")
        val parameter = ParameterKey(owner = genericId, index = 0)
        val selected = ScalarKind.TEXT.template

        fun subject(id: TypeDefinitionId): TypeDefinition =
            TypeDefinition.partial(
                id = id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = id, name = "title"),
                                    type = ScalarKind.TEXT.template,
                                ),
                                FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "selected"), type = selected),
                            ),
                        abstract_ = false,
                    ),
            )

        val base =
            TypeDefinition.partial(
                id = baseId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val generic =
            TypeDefinition.partial(
                id = genericId,
                parameters = listOf(TypeParameter(key = parameter, name = "T", bounds = listOf(baseId.template()))),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = genericId, name = "value"),
                                    type = parameter.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val projections =
            mapOf(
                missingId to
                    CollectionProjectionSpec(
                        sourceId = "missing-resource",
                        root = missingId.namedTemplate(),
                        rowType = ScalarKind.TEXT.template,
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    ValuePath.root,
                                    CollectionProjectionValueSpec.Content(
                                        ValuePath.root.field("title"),
                                    ),
                                ),
                            ),
                    ),
                literalId to
                    CollectionProjectionSpec(
                        sourceId = "invalid-literal",
                        root = literalId.namedTemplate(),
                        rowType = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    ValuePath.root,
                                    CollectionProjectionValueSpec.Literal(DataValue.StringValueWrapper("wrong")),
                                ),
                            ),
                    ),
                boundedId to
                    CollectionProjectionSpec(
                        sourceId = "invalid-bound",
                        root = boundedId.namedTemplate(),
                        rowType =
                            genericId.template(listOf(ScalarKind.TEXT.template)),
                        fields =
                            listOf(
                                CollectionProjectionFieldSpec(
                                    ValuePath.root.field("value"),
                                    CollectionProjectionValueSpec.Literal(DataValue.StringValueWrapper("value")),
                                ),
                            ),
                    ),
            )
        val origin =
            ProviderOrigin(
                DeclarationOwner(
                    source =
                        contributionKey(
                            ContributionSourceId("test"),
                            "main",
                            ProducerId("test"),
                            ContributionName("invalid_collections"),
                        ),
                    localIdentity = "invalid-collections",
                ),
                ArtifactId("test:invalid-collections"),
                "main",
            )
        val runtime = DefaultPresentationRuntime()
        val ownedPresentations =
            projections.map { (id, specification) ->
                val target = PresentationTarget.Named(id.namedTemplate())
                val descriptor = descriptor(specification.sourceId, target, 0, PresentationRole.INSPECTOR)
                val projection =
                    CollectionProjection<ProjectionFixtureResource, Any, ProjectionFixtureExpressions>(
                        specification,
                        ProjectionFixtureExpressionsFactory,
                    )
                val provider =
                    object : PresentationProvider {
                        override fun build(binding: PresentationBuildBinding): PresentationBuildResult =
                            runtime.build(binding) { build ->
                                with(build) {
                                    val selectedField: PresentedField<String, TextControl> =
                                        field("selected", TextControl::class)
                                    val source = projection.projectedCollectionSource(key = { literal("key") })
                                    collectionLookup(source, selectedField.input) {
                                        found { text(literal("found")) }
                                        missing { text(literal("missing")) }
                                    }
                                }
                            }
                    }
                OwnedPresentation(origin, descriptor, provider)
            }
        val definitions = projections.keys.map(::subject) + listOf(base, generic, subject(unrelatedId))

        val assembly =
            CatalogContributions(
                declarations =
                    definitions.map { definition ->
                        if (definition.id in setOf(literalId, boundedId)) {
                            ownedResource(origin, definition)
                        } else {
                            OwnedTypeDeclaration(origin, definition)
                        }
                    },
                presentations = ownedPresentations,
            ).assemble(
                CatalogAssemblyContext(
                    CatalogGeneration("invalid collection admission"),
                    relations = rootOwnership(literalId, boundedId),
                ),
            )

        projections.keys.forEach { id ->
            val status =
                assembly.editorCatalog.types
                    .single { it.definition.id == id }
                    .status as skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper
            status.value.map { it.code } shouldBe listOf("invalid_presentation_collection_dependency")
        }
        assembly.editorCatalog.types
            .single { it.definition.id == unrelatedId }
            .status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
    }

    test("resolves one presentation reference by its checked binding without mutating rejected registrations") {
        val reference = object : PresentationReference {}
        val catalog = DefaultCheckedCatalog(CatalogGeneration("reference targets"), StandardTypes.definitions)
        val text = descriptor("text reference", PresentationTarget.Representation(RepresentationKind.Text), 0)
        val boolean = descriptor("boolean reference", PresentationTarget.Representation(RepresentationKind.Boolean), 0)
        val first = DefaultPresentationRuntime()
        val second = DefaultPresentationRuntime()

        first.register(reference, text)
        first.register(reference, boolean)
        first.register(reference, text)

        runCatching {
            first.register(reference, text.copy(target = PresentationTarget.Representation(RepresentationKind.Integer)))
        }.isFailure shouldBe true

        fun selected(
            runtime: DefaultPresentationRuntime,
            kind: ScalarKind,
        ): String =
            runtime
                .build(
                    PresentationBuildBinding(catalog.ready(kind.use).presentationTemplate(), PresentationRole.WORKSPACE),
                ) {
                    it.invoke(reference) {}
                }.dependencies.presentations
                .single()
                .name

        selected(first, ScalarKind.TEXT) shouldBe text.id.name
        selected(first, ScalarKind.BOOLEAN) shouldBe boolean.id.name
        runCatching { selected(second, ScalarKind.TEXT) }.isFailure shouldBe true
    }

    test("builds scalar field controls and remaining field exclusions") {
        val id = TypeDefinitionId.qualified("test", "PresentationSubject")
        val definition =
            TypeDefinition.partial(
                id = id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = id, name = "title"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation runtime"), listOf(definition))
        val checked = (catalog.resolve(id.use()) as Resolution.Ready).value
        val runtime = DefaultPresentationRuntime()
        val root =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    title {
                        label("Title")
                        textInput()
                    }
                    remainingFields()
                }
            }
        val column = (root.layout.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val fieldNode = (column.value.children[0] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
        val remainingNode = (column.value.children[1] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
        val field = fieldNode.element as PresentationElement.TextInputWrapper
        val remaining = remainingNode.element as PresentationElement.RemainingFieldsWrapper
        field.value.control.binding.path.segments.size shouldBe 1
        (field.value.control.label != null) shouldBe true
        remaining.value.excluded.size shouldBe 0
    }

    test("dispatches value class mangled link controls") {
        val resourceId = TypeDefinitionId.qualified("test", "LinkTargetResource")
        val linkId = TypeDefinitionId.qualified("test", "LinkValue")
        val subjectId = TypeDefinitionId.qualified("test", "LinkControlSubject")
        val linkType = linkId.template()
        val definitions =
            StandardTypes.definitions +
                TypeDefinition.partial(
                    id = resourceId,
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ) +
                TypeDefinition.partial(
                    id = linkId,
                    representation =
                        RepresentationTemplate.createLink(
                            endpoint = EndpointId(value = "test:link"),
                            target = resourceId.template(),
                        ),
                ) +
                TypeDefinition.partial(
                    id = subjectId,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(owner = FieldOwner(definition = subjectId, name = "link"), type = linkType),
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = subjectId, name = "links"),
                                        type = StandardTypes.set.template(listOf(linkType)),
                                    ),
                                ),
                            abstract_ = false,
                        ),
                )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("mangled link controls"), definitions)
        val checked = catalog.ready(subjectId.use())
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val link: PresentedField<Any, LinkControl<ProjectionFixtureResource>> =
                        field(
                            "link",
                            LinkControl::class as kotlin.reflect.KClass<LinkControl<ProjectionFixtureResource>>,
                        )

                    @Suppress("UNCHECKED_CAST")
                    val links: PresentedField<Set<Any>, LinkCollectionControl<ProjectionFixtureResource>> =
                        field(
                            "links",
                            LinkCollectionControl::class as
                                kotlin.reflect.KClass<LinkCollectionControl<ProjectionFixtureResource>>,
                        )

                    link { linkInput(policy = LinkCandidatePolicyId("single")) }
                    links {
                        linkInput(
                            policy = LinkCandidatePolicyId("many"),
                        ) { allowReorder(true) }
                    }
                }
            }

        val elements = result.layout.fixedChildren().map(PresentationNode::element)
        val link = elements[0] as PresentationElement.LinkInputWrapper
        val links = elements[1] as PresentationElement.LinkInputWrapper
        link.value.candidatePolicy?.value shouldBe "single"
        link.value.allowReorder shouldBe false
        links.value.candidatePolicy?.value shouldBe "many"
        links.value.allowReorder shouldBe true
    }

    test("preserves layout kinds and control options") {
        val id = TypeDefinitionId.qualified("test", "PresentationInventory")
        val definition =
            TypeDefinition.partial(
                id = id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = id, name = "title"),
                                    type = ScalarKind.TEXT.template,
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = id, name = "amount"),
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation inventory"), listOf(definition))
        val checked = (catalog.resolve(id.use()) as Resolution.Ready).value
        val root =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)

                    @Suppress("UNCHECKED_CAST")
                    val amount: PresentedField<Int, NumberControl<Int>> =
                        field("amount", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
                    row(4.0, MainAxisAlignment.SPACE_BETWEEN, CrossAxisAlignment.STRETCH) {
                        fixed {
                            title {
                                icon("book")
                                textInput {
                                    characterFilter(CharacterFilter.Allow("[a-z]+"))
                                    onComplete { value }
                                }
                            }
                        }
                        flexible(2, FlexFit.TIGHT) {
                            amount { sliderInput(0, 10) { divisions(5) } }
                        }
                    }
                    wrap(2.0, 3.0) { divider() }
                    grid(2, 4.0, 5.0) { divider() }
                    stack { divider() }
                    section(PresentationBorder.All(1.0, literalColor(com.typewritermc.types.Color(0xff3366ccu)))) { divider() }
                    padding(PresentationInsets(1.0, 2.0, 3.0, 4.0)) { divider() }
                    container(
                        ContainerStyle(
                            background =
                                literal(
                                    com.typewritermc.types.Color
                                        .parseRgb("#3366CC"),
                                ).asPresentationColor(),
                        ),
                    ) { divider() }
                    tooltip(literal("help")) { divider() }
                    title {
                        selectInput(
                            listOf(SelectOption("one", literal("One"), literal("one"))),
                        ) { customValue(query) }
                    }
                }
            }

        val rootColumn = (root.layout.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val elements = rootColumn.value.children.map { (it as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element }
        val row = (elements[0] as PresentationElement.ChildrenWrapper).value as ChildrenElement.RowWrapper
        row.value.layout.spacing shouldBe 4.0
        row.value.children[1].kind shouldBe skirout.editor.v1.presentation.AxisChild.Kind.FLEXIBLE_WRAPPER
        val first = (row.value.children[0] as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
        val firstColumn = (first.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val text =
            (
                (firstColumn.value.children.single() as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value.element
                    as PresentationElement.TextInputWrapper
            ).value
        text.options.characterFilters.size shouldBe 1
        (text.mappings?.completion != null) shouldBe true
        (text.control.prefix?.element is PresentationElement.IconWrapper) shouldBe true
        ((elements[1] as PresentationElement.ChildrenWrapper).value is ChildrenElement.WrapWrapper) shouldBe true
        ((elements[2] as PresentationElement.ChildrenWrapper).value is ChildrenElement.GridWrapper) shouldBe true
        ((elements[3] as PresentationElement.ChildrenWrapper).value is ChildrenElement.StackWrapper) shouldBe true
        (elements[4] is PresentationElement.SectionWrapper) shouldBe true
        (elements[5] is PresentationElement.PaddingWrapper) shouldBe true
        (elements[6] is PresentationElement.ContainerWrapper) shouldBe true
        (elements[7] is PresentationElement.TooltipWrapper) shouldBe true
        val select = elements[8] as PresentationElement.SelectInputWrapper
        select.value.options
            .single()
            .optionId shouldBe "one"
        select.value.allowCustomValue shouldBe true
    }

    test("binds composite callbacks to their nested schema and lexical values") {
        val wrapperId = TypeDefinitionId.qualified("test", "Code")
        val positionId = TypeDefinitionId.qualified("test", "Position")
        val subjectId = TypeDefinitionId.qualified("test", "CompositeSubject")
        val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
        val position =
            TypeDefinition.partial(
                id = positionId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = FieldOwner(definition = positionId, name = "x"), type = integer.template),
                                FieldDeclaration.partial(owner = FieldOwner(definition = positionId, name = "y"), type = integer.template),
                            ),
                        abstract_ = false,
                    ),
            )
        val wrapper =
            TypeDefinition.partial(id = wrapperId, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
        val subject =
            TypeDefinition.partial(
                id = subjectId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "list"),
                                    type = StandardTypes.list.template(listOf(ScalarKind.TEXT.template)),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "set"),
                                    type = StandardTypes.set.template(listOf(ScalarKind.TEXT.template)),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "map"),
                                    type =
                                        StandardTypes.map.template(
                                            listOf(
                                                ScalarKind.TEXT.template,
                                                integer.template.nullable(),
                                            ),
                                        ),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "code"),
                                    type = wrapperId.template(),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "position"),
                                    type = positionId.template(),
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("nested presentation callbacks"),
                StandardTypes.definitions + wrapper + position + subject,
            )
        val checked = catalog.ready(subjectId.use())
        val root =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val list: PresentedField<List<String>, ListControl<TextControl>> =
                        field(
                            "list",
                            ListControl::class as kotlin.reflect.KClass<ListControl<TextControl>>,
                            mapOf(NestedPresentationSlot.Items to NestedPresentationScope(TextControl::class)),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val set: PresentedField<Set<String>, SetControl<TextControl>> =
                        field(
                            "set",
                            SetControl::class as kotlin.reflect.KClass<SetControl<TextControl>>,
                            mapOf(NestedPresentationSlot.Items to NestedPresentationScope(TextControl::class)),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val map: PresentedField<Map<String, Int?>, MapControl<TextControl, NullableControl<NumberControl<Int>>>> =
                        field(
                            "map",
                            MapControl::class as kotlin.reflect.KClass<MapControl<TextControl, NullableControl<NumberControl<Int>>>>,
                            mapOf(
                                NestedPresentationSlot.Keys to NestedPresentationScope(TextControl::class),
                                NestedPresentationSlot.Values to
                                    NestedPresentationScope(
                                        NullableControl::class,
                                        nested =
                                            mapOf(
                                                NestedPresentationSlot.Values to NestedPresentationScope(NumberControl::class),
                                            ),
                                    ),
                            ),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val code: PresentedField<String, NamedControl<String, TextControl>> =
                        field(
                            "code",
                            NamedControl::class as kotlin.reflect.KClass<NamedControl<String, TextControl>>,
                            mapOf(NestedPresentationSlot.Payload to NestedPresentationScope(TextControl::class)),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val positionField: PresentedField<Any, RecordControl<TestPositionScope>> =
                        field(
                            "position",
                            RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                            mapOf(
                                NestedPresentationSlot.Fields to
                                    NestedPresentationScope(
                                        TestPositionScope::class,
                                        create = { nested -> TestPositionScopeImpl(nested) },
                                    ),
                            ),
                        )

                    list { listInput { items { textInput() } } }
                    set { collectionInput { items { textInput() } } }
                    map {
                        mapInput {
                            keys { textInput() }
                            values { nullableInput { value { numericInput() } } }
                        }
                    }
                    code { namedInput { payload { textInput() } } }
                    positionField { recordInput { fields { x { numericInput() } } } }
                }
            }

        val nestedRemainder =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val positionField: PresentedField<Any, RecordControl<TestPositionScope>> =
                        field(
                            "position",
                            RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                            mapOf(
                                NestedPresentationSlot.Fields to
                                    NestedPresentationScope(TestPositionScope::class, create = { nested -> TestPositionScopeImpl(nested) }),
                            ),
                        )
                    positionField {
                        recordInput {
                            fields {
                                x { numericInput { placeholder("X") } }
                                remainingFields()
                            }
                        }
                    }
                }
            }
        val positionBody = (nestedRemainder.layout.singleFixed().element as PresentationElement.RecordInputWrapper).value.fieldPresentation
        val nestedChildren = requireNotNull(positionBody).fixedChildren()
        nestedChildren
            .first()
            .boundControl()
            .binding.path.segments.size shouldBe 2
        val scopedRemainder = nestedChildren.last().element as PresentationElement.ScopedBindingWrapper
        scopedRemainder.value.binding.path.segments.size shouldBe 1
        scopedRemainder.value.scopeBindingId.value shouldBe "configured_value"
        (scopedRemainder.value.child.element is PresentationElement.RemainingFieldsWrapper) shouldBe true

        System.getenv("TYPEWRITER_CONTROL_FIXTURE_DIR")?.let { output ->
            val directory = java.io.File(output)
            directory.mkdirs()
            java.io.File(directory, "composite-layout.bin").writeBytes(PresentationNode.serializer.toBytes(root.layout).toByteArray())
            val value =
                DataValue.record(
                    mapOf(
                        "list" to DataValue.listValue(emptyList()),
                        "set" to DataValue.setValue(emptyList()),
                        "map" to DataValue.mapValue(emptyList()),
                        "code" to DataValue.named(wrapperId.namedUse(), DataValue.StringValueWrapper("Authored code")),
                        "position" to
                            DataValue.named(
                                positionId.namedUse(),
                                DataValue.record(
                                    mapOf(
                                        "x" to DataValue.integer(java.math.BigInteger.valueOf(7)),
                                        "y" to DataValue.integer(java.math.BigInteger.valueOf(8)),
                                    ),
                                ),
                            ),
                    ),
                )
            val encoded =
                value.requirePortable()
            java.io
                .File(
                    directory,
                    "composite-value.bin",
                ).writeBytes(
                    skirout.editor.v1.type_catalog.DataValue.serializer
                        .toBytes(encoded)
                        .toByteArray(),
                )
            java.io
                .File(
                    directory,
                    "nested-remainder-layout.bin",
                ).writeBytes(PresentationNode.serializer.toBytes(nestedRemainder.layout).toByteArray())
            val owner =
                ProviderOrigin(
                    descriptor(
                        "nested remainder",
                        PresentationTarget.Named(subjectId.namedTemplate()),
                        0,
                        PresentationRole.WORKSPACE,
                    ).owner,
                    ArtifactId("test:nested-remainder"),
                    "main",
                )
            val assembly =
                CatalogContributions(
                    declarations =
                        listOf(wrapper, position, subject).map {
                            OwnedTypeDeclaration(owner, it)
                        },
                ).assemble(CatalogAssemblyContext(CatalogGeneration("nested remainder fixture")))
            val wire = assembly.editorCatalog
            java.io
                .File(
                    directory,
                    "nested-remainder-catalog.bin",
                ).writeBytes(
                    skirout.editor.v1.catalog.EditorCatalog.serializer
                        .toBytes(wire)
                        .toByteArray(),
                )
        }
        val elements = root.layout.fixedChildren()
        val list = elements[0].element as PresentationElement.ListInputWrapper
        list.value.itemPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "list_item"
        val set = elements[1].element as PresentationElement.SetInputWrapper
        set.value.itemPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "set_item"
        val map = elements[2].element as PresentationElement.MapInputWrapper
        map.value.keyPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "map_key"
        val nullable =
            map.value.valuePresentation
                .singleFixed()
                .element as PresentationElement.NullableInputWrapper
        System.getenv("TYPEWRITER_CONTROL_FIXTURE_DIR")?.let { output ->
            java.io
                .File(
                    output,
                    "nullable-layout.bin",
                ).writeBytes(PresentationNode.serializer.toBytes(map.value.valuePresentation!!).toByteArray())
            val value =
                DataValue.integer(java.math.BigInteger.valueOf(42))
            java.io
                .File(
                    output,
                    "nullable-value.bin",
                ).writeBytes(
                    skirout.editor.v1.type_catalog.DataValue.serializer
                        .toBytes(value)
                        .toByteArray(),
                )
        }
        nullable.value.valuePresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "map_value"
        val named = elements[3].element as PresentationElement.NamedInputWrapper
        named.value.payloadPresentation
            .singleFixed()
            .boundControl()
            .binding.path.segments.size shouldBe 1
        val record = elements[4].element as PresentationElement.RecordInputWrapper
        record.value.fieldPresentation
            .singleFixed()
            .boundControl()
            .binding.path.segments.size shouldBe 2
    }

    test("nested named controls remain local to their record and collection binders") {
        val positionId = TypeDefinitionId.qualified("test", "NestedChoicePosition")
        val subjectId = TypeDefinitionId.qualified("test", "NestedChoiceSubject")
        val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
        val position =
            TypeDefinition.partial(
                id = positionId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(owner = FieldOwner(definition = positionId, name = "x"), type = integer.template),
                            ),
                        abstract_ = false,
                    ),
            )
        val subject =
            TypeDefinition.partial(
                id = subjectId,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "style"),
                                    type = positionId.template(),
                                ),
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = subjectId, name = "buttons"),
                                    type = StandardTypes.list.template(listOf(positionId.template())),
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("nested explicit presentation paths"),
                StandardTypes.definitions + position + subject,
            )
        val checked = catalog.ready(subjectId.use())
        val selected =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "special numeric")
        val reference = object : PresentationReference {}
        val runtime =
            DefaultPresentationRuntime().also {
                it.register(reference, descriptor("special numeric", PresentationTarget.Representation(RepresentationKind.Integer), 0))
            }
        val layout =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR)) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val style: PresentedField<Any, RecordControl<TestPositionScope>> =
                        field(
                            "style",
                            RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                            mapOf(
                                NestedPresentationSlot.Fields to
                                    NestedPresentationScope(
                                        TestPositionScope::class,
                                        create = { nested -> TestPositionScopeImpl(nested) },
                                    ),
                            ),
                        )

                    @Suppress("UNCHECKED_CAST")
                    val buttons: PresentedField<List<Any>, ListControl<RecordControl<TestPositionScope>>> =
                        field(
                            "buttons",
                            ListControl::class as kotlin.reflect.KClass<ListControl<RecordControl<TestPositionScope>>>,
                            mapOf(
                                NestedPresentationSlot.Items to
                                    NestedPresentationScope(
                                        RecordControl::class,
                                        nested =
                                            mapOf(
                                                NestedPresentationSlot.Fields to
                                                    NestedPresentationScope(
                                                        TestPositionScope::class,
                                                        create = { nested -> TestPositionScopeImpl(nested) },
                                                    ),
                                            ),
                                    ),
                            ),
                        )

                    style { recordInput { fields { x(using = reference) } } }
                    buttons { listInput { items { recordInput { fields { x(using = reference) } } } } }
                }
            }
        layout.layout.inferInheritableNodes().size shouldBe 3
    }

    test("builds scoped collection match and invocation data nodes with lexical bindings") {
        val id = TypeDefinitionId.qualified("test", "PresentationDataSubject")
        val definition =
            TypeDefinition.partial(
                id = id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = id, name = "title"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation data"), listOf(definition))
        val checked = catalog.ready(id.use())
        val reference = object : PresentationReference {}
        val referenceId =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "invoked")
        val parameter = presentationParameter<String>("title")
        val runtime =
            DefaultPresentationRuntime().also {
                it.register(reference, descriptor("invoked", PresentationTarget.Named(id.namedTemplate()), 0))
            }
        val repeatedSource =
            com.typewritermc.expression.portableLiteral<List<String>>(
                DataValue.listValue(
                    listOf(ListItem(id = ItemId(value = "first"), value = DataValue.StringValueWrapper("value"))),
                ),
            )
        val source =
            collectionSource<String, String>("rows", ScalarKind.TEXT.template) {
                key(row)
                relations("children", repeatedSource)
            }
        val root =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    repeated<String, String>(repeatedSource) {
                        text(item.orElse(literal("missing")))
                        empty { text(literal("empty")) }
                        separator { divider() }
                    }
                    scoped(title.input) { textInput() }
                    typedField(title.input) { textInput() }
                    collectionLookup(source, title.input) {
                        found { text(row.orElse(literal("missing row"))) }
                        missing { text(literal("missing")) }
                        loading { text(literal("loading")) }
                    }
                    collectionGraph(source) {
                        root(title.input)
                        relation("children", CollectionGraphDirection.REVERSE, maximumDepth = 4)
                        node {
                            text(row.orElse(literal("missing node")))
                            descendants()
                        }
                    }
                    polymorphicMatch(title.input) {
                        case(AppliedPresentation<String>(id.namedUse(), reference)) {
                            text(value.orElse(literal("missing value")))
                        }
                        fallback { text(literal("fallback")) }
                    }
                    invoke(reference) { bind(parameter, title.input) }
                }
            }

        root.dependencies.collections
            .single()
            .sourceId shouldBe "rows"
        root.dependencies.presentations
            .single()
            .name shouldBe "invoked"
        root.dependencies.types.single() shouldBe id.use()

        val elements = root.layout.fixedChildren().map(PresentationNode::element)
        val repeated = elements[0] as PresentationElement.RepeatedWrapper
        repeated.value.itemBindingId.value
            .startsWith("presentation.repeated.item") shouldBe true
        (repeated.value.presentation.empty != null) shouldBe true
        val scoped = elements[1] as PresentationElement.ScopedBindingWrapper
        scoped.value.child
            .singleFixed()
            .boundControl()
            .binding.bindingId shouldBe scoped.value.scopeBindingId
        val typed = elements[2] as PresentationElement.TypedFieldWrapper
        System.getenv("TYPEWRITER_CONTROL_FIXTURE_DIR")?.let { output ->
            java.io
                .File(
                    output,
                    "typed-layout.bin",
                ).writeBytes(PresentationNode.serializer.toBytes(root.layout.fixedChildren()[2]).toByteArray())
            val value =
                DataValue
                    .record(
                        mapOf("title" to DataValue.StringValueWrapper("Authored title")),
                    ).requirePortable()
            java.io
                .File(
                    output,
                    "typed-value.bin",
                ).writeBytes(
                    skirout.editor.v1.type_catalog.DataValue.serializer
                        .toBytes(value)
                        .toByteArray(),
                )
        }
        typed.value.presentation
            .singleFixed()
            .boundControl()
            .binding.path.segments.size shouldBe 1
        val lookup = elements[3] as PresentationElement.CollectionLookupWrapper
        lookup.value.sourceId shouldBe "rows"
        (lookup.value.loading != null) shouldBe true
        val graph = elements[4] as PresentationElement.CollectionGraphWrapper
        graph.value.sourceId shouldBe "rows"
        graph.value.maximumDepth shouldBe 4
        graph.value.direction shouldBe skirout.editor.v1.presentation.CollectionGraphDirection.REVERSE
        (graph.value.rootSequence.layout is skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper) shouldBe true
        (graph.value.children.layout is skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper) shouldBe true
        graph.value.rootSequence.empty shouldBe null
        root.dependencies.collections
            .single()
            .relations
            .single()
            .targets shouldBe repeatedSource.toNode()
        val match = elements[5] as PresentationElement.PolymorphicMatchWrapper
        match.value.cases.size shouldBe 1
        (match.value.fallback != null) shouldBe true
        val invocation = elements[6] as PresentationElement.InvocationWrapper
        invocation.value.arguments
            .single()
            .input.value shouldBe "title"
        invocation.value.arguments
            .single()
            .binding.path.segments.size shouldBe 1

        val other =
            collectionSource<Boolean, String>("rows", ScalarKind.BOOLEAN.template) {
                key(literal("same key type"))
            }
        val otherResult =
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    collectionLookup(other, title.input) {
                        found { text(literal("found")) }
                        missing { text(literal("missing")) }
                    }
                }
            }
        otherResult.dependencies.collections
            .single()
            .rowType shouldBe
            ScalarKind.BOOLEAN.template
        otherResult.dependencies.presentations shouldBe emptyList()

        runCatching {
            runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    collectionLookup(source, title.input) {
                        found { text(literal("found")) }
                        missing { text(literal("missing")) }
                    }
                    collectionLookup(other, title.input) {
                        found { text(literal("found")) }
                        missing { text(literal("missing")) }
                    }
                }
            }
        }.isFailure shouldBe true
    }

    test("projected collection sources use stable resource identities by default and allow handled custom keys") {
        val projection = coreTagCollectionProjection()
        val byResource = projection.projectedCollectionSource()
        val projectedRows = byResource.rows as CollectionRows.Projected

        byResource.id shouldBe projection.specification.sourceId
        byResource.rowType shouldBe projection.specification.rowType
        byResource.key.toNode() shouldBe
            com.typewritermc.expression
                .input<Any?>(projectedRows.resourceBinding)
                .toNode()

        val byName: CollectionSource<com.typewritermc.library.TagCollectionRow, String> =
            projection.projectedCollectionSource(
                key = { expressions.name.orElse(literal("unnamed")) },
            )
        (byName.key.toNode() is ExpressionNode.OrElseWrapper) shouldBe true
        byName.relations shouldBe emptyList()
    }

    test("selects specific presentations before priority and preserves fallback order") {
        val id = TypeDefinitionId.qualified("test", "RegistrySubject")
        val definition =
            TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false))
        val catalog = DefaultCheckedCatalog(CatalogGeneration("presentation registry"), listOf(definition))
        val checked = (catalog.resolve(id.use()) as Resolution.Ready).value
        val representation =
            descriptor("generic", PresentationTarget.Representation(com.typewritermc.configuration.RepresentationKind.Record), 100)
        val named = descriptor("specific", PresentationTarget.Named(id.namedTemplate()), 10)
        val fallbackFirst =
            descriptor("fallback first", PresentationTarget.Named(id.namedTemplate()), 10, PresentationRole.REFERENCE_PREVIEW)
        val fallbackSecond =
            descriptor("fallback second", PresentationTarget.Named(id.namedTemplate()), 100, PresentationRole.RESOURCE_SEARCH_RESULT)
        val registry =
            DefaultPresentationRegistry(
                catalog,
                listOf(representation, named, fallbackFirst, fallbackSecond),
                listOf(
                    RoleFallback(
                        PresentationRole.REFERENCE_PICKER_RESULT,
                        listOf(PresentationRole.REFERENCE_PREVIEW, PresentationRole.RESOURCE_SEARCH_RESULT),
                    ),
                ),
            )

        (registry.select(PresentationRole.WORKSPACE, checked) as PresentationSelection.Selected).descriptor.id shouldBe named.id
        (registry.select(PresentationRole.REFERENCE_PICKER_RESULT, checked) as PresentationSelection.Selected).descriptor.id shouldBe
            fallbackFirst.id
    }

    test("reference pickers fall back to previews without sharing editing or search roles") {
        val id = TypeDefinitionId.qualified("test", "ReferenceTarget")
        val definition =
            TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false))
        val catalog = DefaultCheckedCatalog(CatalogGeneration("reference fallback"), listOf(definition))
        val checked = (catalog.resolve(id.use()) as Resolution.Ready).value
        val preview = descriptor("preview", PresentationTarget.Named(id.namedTemplate()), 0, PresentationRole.REFERENCE_PREVIEW)
        val registry = DefaultPresentationRegistry(catalog, listOf(preview), com.typewritermc.discovery.DEFAULT_ROLE_FALLBACKS)

        (registry.select(PresentationRole.REFERENCE_PICKER_RESULT, checked) as PresentationSelection.Selected)
            .descriptor.id shouldBe preview.id
        for (role in listOf(PresentationRole.WORKSPACE, PresentationRole.INSPECTOR, PresentationRole.RESOURCE_SEARCH_RESULT)) {
            registry.select(role, checked) shouldBe PresentationSelection.Missing(role)
        }

        val picker = descriptor("picker", preview.target, 0, PresentationRole.REFERENCE_PICKER_RESULT)
        val specialized = DefaultPresentationRegistry(catalog, listOf(preview, picker), com.typewritermc.discovery.DEFAULT_ROLE_FALLBACKS)
        (specialized.select(PresentationRole.REFERENCE_PICKER_RESULT, checked) as PresentationSelection.Selected)
            .descriptor.id shouldBe picker.id
    }

    test("inspector presentations do not satisfy workspace selection") {
        val id = TypeDefinitionId.qualified("test", "RoleSubject")
        val definition =
            TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false))
        val catalog = DefaultCheckedCatalog(CatalogGeneration("role separation"), listOf(definition))
        val checked = (catalog.resolve(id.use()) as Resolution.Ready).value
        val inspector = descriptor("inspector", PresentationTarget.Named(id.namedTemplate()), 10, PresentationRole.INSPECTOR)
        val registry = DefaultPresentationRegistry(catalog, listOf(inspector))

        (registry.select(PresentationRole.INSPECTOR, checked) as PresentationSelection.Selected).descriptor.id shouldBe inspector.id
        registry.select(PresentationRole.WORKSPACE, checked) shouldBe
            PresentationSelection.Missing(PresentationRole.WORKSPACE)
    }

    test("reports incomparable generic presentation targets as a conflict before priority") {
        val pairId = TypeDefinitionId.qualified("test", "Pair")
        val first = ParameterKey(owner = pairId, index = 0)
        val second = ParameterKey(owner = pairId, index = 1)
        val definition =
            TypeDefinition.partial(
                id = pairId,
                parameters =
                    listOf(
                        TypeParameter.partial(key = first, name = "A"),
                        TypeParameter.partial(key = second, name = "B"),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("incomparable presentations"), StandardTypes.definitions + definition)
        val actual =
            catalog.ready(
                pairId.use(
                    listOf(
                        ScalarKind.TEXT.use,
                        StandardTypes.list.use(listOf(ScalarKind.TEXT.use)),
                    ),
                ),
            )
        val left =
            descriptor(
                "left",
                PresentationTarget.Named(
                    pairId.namedTemplate(listOf(ScalarKind.TEXT.template, first.template)),
                ),
                10,
            )
        val right =
            descriptor(
                "right",
                PresentationTarget.Named(
                    pairId.namedTemplate(
                        listOf(
                            first.template,
                            StandardTypes.list.template(listOf(ScalarKind.TEXT.template)),
                        ),
                    ),
                ),
                100,
            )
        val selection = DefaultPresentationRegistry(catalog, listOf(left, right)).select(PresentationRole.WORKSPACE, actual)

        selection shouldBe PresentationSelection.Conflict(listOf(left.id, right.id))
    }

    test("selects repeated generic parameters before a broader target") {
        val pairId = TypeDefinitionId.qualified("test", "RepeatedPair")
        val first = ParameterKey(owner = pairId, index = 0)
        val second = ParameterKey(owner = pairId, index = 1)
        val definition =
            TypeDefinition.partial(
                id = pairId,
                parameters =
                    listOf(
                        TypeParameter.partial(key = first, name = "A"),
                        TypeParameter.partial(key = second, name = "B"),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("repeated parameter presentation"), listOf(definition))
        val actual =
            catalog.ready(
                pairId.use(listOf(ScalarKind.TEXT.use, ScalarKind.TEXT.use)),
            )
        val repeated =
            descriptor(
                "repeated",
                PresentationTarget.Named(
                    pairId.namedTemplate(listOf(first.template, first.template)),
                ),
                10,
            )
        val broad =
            descriptor(
                "broad",
                PresentationTarget.Named(
                    pairId.namedTemplate(listOf(first.template, second.template)),
                ),
                100,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(repeated, broad)).select(PresentationRole.WORKSPACE, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe repeated.id
    }

    test("matches presentation arguments through readable nominal subtypes") {
        val rewardId = TypeDefinitionId.qualified("test", "Reward")
        val coinId = TypeDefinitionId.qualified("test", "CoinReward")
        val variableId = TypeDefinitionId.qualified("test", "Variable")
        val variableParameter = ParameterKey(owner = variableId, index = 0)
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("readable presentation argument"),
                listOf(
                    TypeDefinition.partial(
                        id = rewardId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
                    ),
                    TypeDefinition.partial(
                        id = coinId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(rewardId.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = variableId,
                        parameters = listOf(TypeParameter.partial(key = variableParameter, name = "T")),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
            )
        val actual = catalog.ready(variableId.use(listOf(coinId.use())))
        val broad =
            descriptor(
                "reward variable",
                PresentationTarget.Named(
                    variableId.namedTemplate(listOf(rewardId.template())),
                ),
                10,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(broad)).select(PresentationRole.WORKSPACE, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe broad.id
    }

    test("selects a concrete generic argument before its readable base argument") {
        val rewardId = TypeDefinitionId.qualified("test", "SpecificReward")
        val coinId = TypeDefinitionId.qualified("test", "SpecificCoinReward")
        val variableId = TypeDefinitionId.qualified("test", "SpecificVariable")
        val variableParameter = ParameterKey(owner = variableId, index = 0)
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("specific readable presentation argument"),
                listOf(
                    TypeDefinition.partial(
                        id = rewardId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
                    ),
                    TypeDefinition.partial(
                        id = coinId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(rewardId.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = variableId,
                        parameters = listOf(TypeParameter.partial(key = variableParameter, name = "T")),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
            )
        val actual = catalog.ready(variableId.use(listOf(coinId.use())))
        val concrete =
            descriptor(
                "coin variable",
                PresentationTarget.Named(
                    variableId.namedTemplate(listOf(coinId.template())),
                ),
                10,
            )
        val broad =
            descriptor(
                "reward variable",
                PresentationTarget.Named(
                    variableId.namedTemplate(listOf(rewardId.template())),
                ),
                100,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(concrete, broad)).select(PresentationRole.WORKSPACE, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe concrete.id
    }
}

private fun DefaultCheckedCatalog.ready(use: TypeUse): com.typewritermc.types.catalog.CheckedType = (resolve(use) as Resolution.Ready).value

private fun descriptor(
    name: String,
    target: PresentationTarget,
    priority: Int,
    role: PresentationRole = PresentationRole.WORKSPACE,
): PresentationDescriptor =
    PresentationDescriptor(
        skirout.editor.v1.type_catalog
            .PresentationId(namespace = "test", name = name),
        DeclarationOwner(
            source =
                contributionKey(
                    ContributionSourceId("test"),
                    "main",
                    ProducerId("test"),
                    ContributionName(name.replace(' ', '_')),
                ),
            localIdentity = name,
        ),
        target,
        setOf(role),
        priority,
    )

private interface TestPositionScope : Layout {
    val x: PresentedField<Int, NumberControl<Int>>
}

private class TestPositionScopeImpl(
    private val build: PresentationBuildScope,
) : TestPositionScope,
    Layout by build {
    @Suppress("UNCHECKED_CAST")
    override val x: PresentedField<Int, NumberControl<Int>>
        get() = build.field("x", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
}

private class ProjectionFixtureResource : Resource

private object ProjectionFixtureExpressionsFactory : com.typewritermc.expression.ExpressionFactory<ProjectionFixtureExpressions> {
    override val scope = ProjectionFixtureExpressions::class

    override fun create(
        value: com.typewritermc.expression.Expr<*, out com.typewritermc.expression.MissingPolicy>,
    ): ProjectionFixtureExpressions = object : ProjectionFixtureExpressions {}
}

private interface ProjectionFixtureExpressions

private fun PresentationNode.fixedChildren(): List<PresentationNode> {
    val column = (element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
    return column.value.children.map { (it as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value }
}

private fun PresentationNode?.singleFixed(): PresentationNode = requireNotNull(this).fixedChildren().single()

private fun PresentationNode.boundControl(): skirout.editor.v1.presentation.BoundControl =
    when (val value = element) {
        is PresentationElement.TextInputWrapper -> value.value.control
        is PresentationElement.NumericInputWrapper -> value.value.control
        else -> error("Expected a scalar input, found $value.")
    }

/** Declares [definition] a resource type, which collection projections may read. */
private fun ownedResource(
    origin: ProviderOrigin,
    definition: TypeDefinition,
): OwnedTypeDeclaration =
    OwnedTypeDeclaration(
        origin,
        definition,
        searchKey =
            definition.id
                .toString()
                .filter(Char::isLetter)
                .lowercase(),
    )

/** Lets the realm root own [members], as every concrete resource type must be owned. */
private fun rootOwnership(vararg members: TypeDefinitionId): List<com.typewritermc.types.RelationContract> =
    members.mapIndexed { index, member ->
        com.typewritermc.types.RelationContract(
            id = com.typewritermc.types.RelationId("test.root.owns.$index"),
            first =
                com.typewritermc.types.EndpointDefinition(
                    EndpointId(value = "test.root.owns.$index:first"),
                    com.typewritermc.types.EndpointSlot.First,
                    com.typewritermc.authoring.RealmRootDefinition.id
                        .namedTemplate(),
                    com.typewritermc.types.EndpointCardinality.One,
                    com.typewritermc.types.RelationDeletePolicy.CASCADE,
                ),
            second =
                com.typewritermc.types.EndpointDefinition(
                    EndpointId(value = "test.root.owns.$index:second"),
                    com.typewritermc.types.EndpointSlot.Second,
                    member.namedTemplate(),
                    com.typewritermc.types.EndpointCardinality.Many,
                    com.typewritermc.types.RelationDeletePolicy.CLEAR,
                ),
            families = setOf(com.typewritermc.types.RelationFamilyId(com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID)),
        )
    }
