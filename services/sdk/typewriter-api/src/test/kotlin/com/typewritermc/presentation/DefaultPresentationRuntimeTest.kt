@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.text
import com.typewritermc.configuration.field
import com.typewritermc.configuration.of
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.discovery.ownership
import com.typewritermc.expression.eq
import com.typewritermc.expression.evaluate
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.coreTagCollectionProjection
import com.typewritermc.presentation.of
import com.typewritermc.testkit.Rejection
import com.typewritermc.testkit.boundControl
import com.typewritermc.testkit.bytes
import com.typewritermc.testkit.definitions
import com.typewritermc.testkit.fixedChildren
import com.typewritermc.testkit.iconName
import com.typewritermc.testkit.literalText
import com.typewritermc.testkit.literalValue
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.rejectionOf
import com.typewritermc.testkit.singleFixed
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
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
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requireValid
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.text
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldNotThrowAny
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RoleFallback
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.CollectionGraphDirection
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.FlexFit
import skirout.editor.v1.presentation.ImageFit
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationContextSource
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationTextTone
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
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
import skirout.editor.v1.type_catalog.ValuePath

val DefaultPresentationRuntimeTest by testSuite {
    test("a caller input read twice registers one caller dependency typed as a resource id") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "caller inputs"),
                StandardTypes.definitions + com.typewritermc.types.ResourceIdDefinition.definition,
            )
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
        input.source shouldBe skirout.editor.v1.presentation.PresentationContextSource.CALLER
        input.binding.type shouldBe
            com.typewritermc.types.ResourceIdDefinition.use.use
                .toTemplate()
    }

    test("host inputs declare their host source and the host contract's value types") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "host inputs"),
                StandardTypes.definitions + com.typewritermc.types.ResourceIdDefinition.definition,
            )
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
        active.binding.id.value shouldBe EditorContext.activeResource.binding.value
        active.binding.type shouldBe
            com.typewritermc.types.ResourceIdDefinition.use.use
                .toTemplate()
        val count =
            inputs.getValue(
                skirout.editor.v1.presentation.PresentationContextSource.HostWrapper(
                    skirout.editor.v1.presentation.HostContextInput.SELECTION_COUNT,
                ),
            )
        count.binding.id.value shouldBe EditorContext.selectionCount.binding.value
        count.binding.type shouldBe
            integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
        inputs.size shouldBe 2
    }

    test("a part defined once and requested again is owned by its type and excluded from remaining fields") {
        val id = TypeDefinitionId.qualified("test", "PartOwner")
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "parts"),
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
        val nodes = result.layout.fixedChildren()
        val definition = nodes[0].element as PresentationElement.PartWrapper
        val request = nodes[1].element as PresentationElement.PartWrapper
        val rest = nodes[2].element as PresentationElement.RemainingFieldsWrapper
        definition.value.key.owner shouldBe id
        definition.value.key.name shouldBe "heading"
        definition.value.body.literalText() shouldBe "Shared heading"
        request.value.key shouldBe definition.value.key
        request.value.body shouldBe null
        rest.value.excludedParts shouldBe listOf(definition.value.key)
        shouldNotThrowAny { result.layout.validateInheritableNodes(result.layout.inferInheritableNodes()) { true } }
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
            definitions {
                record(rootId) {
                    field("details", nestedId.template())
                }
            }.single()
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "nested part request"),
                StandardTypes.definitions + listOf(nested, root),
            )
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
        scope.value.scopeBinding.id.value shouldBe "configured_value"
        val part = scope.value.child.element as PresentationElement.PartWrapper
        part.value.key.owner shouldBe nestedId
        part.value.body shouldBe null
        result.layout.inferInheritableNodes() shouldBe emptyList()
    }

    test("clipped fixed and repeated rows preserve one line layout") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "clipped rows"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.RESOURCE_SEARCH_RESULT),
            ) { build ->
                build.clippedRow(spacing = Spacing(4.0)) {
                    text(literal("Book"))
                    text(literal("Page"))
                }
                build.repeated<String, String>(
                    com.typewritermc.expression.portableLiteral(
                        DataValue.listValue(listOf(ListItem(id = ItemId(value = "only"), value = DataValue.StringValueWrapper("Book")))),
                    ),
                ) {
                    clippedRow(spacing = Spacing(4.0))
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
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "header diagnostics"), StandardTypes.definitions)
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
            val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "presentation bodies"), StandardTypes.definitions)
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

    test("an image keeps its configured width and fit") {
        val image = (displayElements()[0] as PresentationElement.ImageWrapper).value

        image.options?.fit shouldBe ImageFit.COVER
        image.options?.width.literalValue() shouldBe DataValue.FloatWrapper(80.0)
    }

    test("a badge keeps its text weight and its book icon") {
        val badge = (displayElements()[1] as PresentationElement.BadgeWrapper).value

        badge.options
            ?.appearance
            ?.valueStyle
            ?.weight shouldBe 500
        (badge.options?.icon as skirout.editor.v1.presentation.InputAdornment.ContentWrapper).value.iconName() shouldBe "book"
    }

    test("a chip without an icon shows none") {
        (displayElements()[2] as PresentationElement.ChipWrapper).value.options?.icon shouldBe
            skirout.editor.v1.presentation.InputAdornment.NONE
    }

    test("a progress bar keeps its minimum height") {
        (displayElements()[3] as PresentationElement.ProgressWrapper)
            .value.appearance
            ?.minimumHeight
            .literalValue() shouldBe
            DataValue.FloatWrapper(5.0)
    }

    test("a tooltip keeps its wait delay") {
        (displayElements()[4] as PresentationElement.TooltipWrapper).value.appearance?.waitMilliseconds shouldBe 250
    }

    test("a divider keeps its end indent") {
        (displayElements()[5] as PresentationElement.DividerWrapper).value.endIndent.literalValue() shouldBe DataValue.FloatWrapper(6.0)
    }

    test("tabs keep their spacing and each tab its icon") {
        val tabs = (displayElements()[6] as PresentationElement.TabsWrapper).value

        tabs.spacing shouldBe 4.0
        tabs.contentSpacing shouldBe 10.0
        tabs.tabs
            .single()
            .icon
            .iconName() shouldBe "book"
    }

    test("status, date time and relative time keep their icon, weight and density") {
        val elements = displayElements()

        (elements[7] as PresentationElement.StatusWrapper)
            .value.cases
            .single()
            .appearance.options
            ?.icon shouldBe
            skirout.editor.v1.presentation.InputAdornment.NONE
        (elements[8] as PresentationElement.DateTimeWrapper)
            .value.options
            ?.appearance
            ?.valueStyle
            ?.weight shouldBe 500
        (elements[9] as PresentationElement.RelativeTimeWrapper)
            .value.options
            ?.appearance
            ?.density shouldBe ControlDensity.COMPACT
    }

    test("fields with an editor share a row evenly while fixed content keeps its size") {
        val row = coordinateRow()

        row.children.map { it.kind } shouldBe
            listOf(
                skirout.editor.v1.presentation.AxisChild.Kind.FLEXIBLE_WRAPPER,
                skirout.editor.v1.presentation.AxisChild.Kind.FLEXIBLE_WRAPPER,
                skirout.editor.v1.presentation.AxisChild.Kind.FIXED_WRAPPER,
            )
        row.children.take(2).map { (it as skirout.editor.v1.presentation.AxisChild.FlexibleWrapper).value.flex } shouldBe listOf(1, 1)
    }

    test("metadata authored before or after the editor reaches the field it describes") {
        val row = coordinateRow()
        val xNode = (row.children[0] as skirout.editor.v1.presentation.AxisChild.FlexibleWrapper).value.child
        val x = (xNode.element as PresentationElement.NumericInputWrapper).value
        val y =
            (
                (row.children[1] as skirout.editor.v1.presentation.AxisChild.FlexibleWrapper).value.child.element
                    as PresentationElement.NumericInputWrapper
            ).value

        x.control.label.literalValue() shouldBe DataValue.StringValueWrapper("Horizontal")
        y.control.label.literalValue() shouldBe DataValue.StringValueWrapper("Vertical")
        xNode.properties.readOnly shouldBe true
        xNode.properties.enabledIf.literalValue() shouldBe DataValue.BooleanWrapper(false)
        x.appearance?.density shouldBe ControlDensity.COMPACT
        x.appearance?.valueStyle?.weight shouldBe 500
        x.entry?.selectAllOnFocus shouldBe true
        x.options.step shouldBe y.options.step
        (x.content?.leading as skirout.editor.v1.presentation.InputAdornment.ContentWrapper).value.literalText() shouldBe "axis"
        y.content?.leading shouldBe null
        x.mappings?.completion shouldNotBe null
        y.mappings?.completion shouldBe null
    }

    test("appearance defaults are immutable sparse wrappers and local controls stay sparse") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "input appearance"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val shared =
            inputAppearance {
                density(ControlDensity.COMPACT)
                textStyle(TextStyle(weight = FontWeight(600)))
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
        wrapper.appearance.density shouldBe ControlDensity.COMPACT
        wrapper.appearance.valueStyle?.weight shouldBe 600
        wrapper.appearance.valueStyle?.sizing shouldBe null
        val input = (wrapper.child.singleFixed().element as PresentationElement.TextInputWrapper).value
        input.appearance?.density shouldBe null
        input.appearance?.valueStyle?.weight shouldBe null
        (input.appearance?.valueStyle?.sizing != null) shouldBe true
    }

    test("default control receives metadata authored after prefix and no explicit editor") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "default metadata"), StandardTypes.definitions)
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
        control.prefix.literalText() shouldBe "prefix"
        control.label.literalValue() shouldBe DataValue.StringValueWrapper("Name")
        node.properties.readOnly shouldBe true
    }

    test("surface policies serialize through ordinary presentation nodes") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "surface policies"), StandardTypes.definitions)
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
                        transition = moveOverrides(hovered = MoveOverride.Timed(length = DisplayDelay(100))),
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
        container.transition?.hovered shouldBe
            skirout.editor.v1.presentation.PresentationTransition.TimedWrapper(
                skirout.editor.v1.presentation
                    .PresentationTimedTransition(milliseconds = 100, curve = null),
            )
        val alignment = (container.child.singleFixed().element as PresentationElement.AlignWrapper).value
        alignment.alignment shouldBe skirout.editor.v1.presentation.PresentationAlignment.CENTER
    }

    test("a resource heading shows its title and the subject identifier only while one resource is selected") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "headings"),
                StandardTypes.definitions + com.typewritermc.types.ResourceIdDefinition.definition +
                    com.typewritermc.types.ColorDefinition.definition,
            )
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
        val selectionCount = EditorContext.selectionCount.binding.value

        result.dependencies.contextInputs.map { it.source } shouldBe
            listOf(
                skirout.editor.v1.presentation.PresentationContextSource.HostWrapper(
                    skirout.editor.v1.presentation.HostContextInput.SELECTION_COUNT,
                ),
            )
        evaluate(conditional.value.condition, selectionCount to DataValue.integer(java.math.BigInteger.ONE)) shouldBe
            Availability.Available(DataValue.BooleanWrapper(true))
        evaluate(conditional.value.condition, selectionCount to DataValue.integer(java.math.BigInteger.TWO)) shouldBe
            Availability.Available(DataValue.BooleanWrapper(false))
        val paragraphs =
            conditional.value.whenTrue
                .singleFixed()
                .fixedChildren()
        paragraphs.first().literalText() shouldBe "A title"
        val identity = (paragraphs.last().element as PresentationElement.ConditionalWrapper).value.whenTrue.singleFixed()
        val identifier = DataValue.named(com.typewritermc.types.ResourceIdDefinition.use, DataValue.StringValueWrapper("quest-1"))
        evaluate(
            (identity.element as PresentationElement.TextWrapper).value.value,
            "presentation.subject.identifier" to identifier,
        ) shouldBe
            Availability.Available(DataValue.StringValueWrapper("quest-1"))
    }

    test("rich text keeps its sizing, paragraph behavior, shared style and run weights") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "rich sizing"), StandardTypes.definitions)
        val checked = catalog.ready(ScalarKind.TEXT.use)
        val result =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                build.richText {
                    sizing(TextSizing.Fit(literal(18.0), literal(40.0)))
                    paragraph(textParagraph(maxLines = 2, softWrap = true, selectable = true, tone = PresentationTextTone.SECONDARY))
                    style(
                        TextStyleOverride(
                            color = literal(com.typewritermc.types.Color(0xff123456u)).asPresentationColor(),
                            weight = FontWeight(500),
                        ),
                    )
                    run(literal("First"))
                    run(literal("Second"), TextStyleOverride(weight = FontWeight(700)))
                }
            }
        val text = (result.layout.singleFixed().element as PresentationElement.RichTextWrapper).value
        (text.sizing is skirout.editor.v1.presentation.TextSizing.FitWrapper) shouldBe true
        text.paragraph.maxLines shouldBe 2
        text.paragraph.softWrap shouldBe true
        text.paragraph.selectable shouldBe true
        text.paragraph.tone shouldBe skirout.editor.v1.presentation.PresentationTextTone.SECONDARY
        text.runs.map { it.text.literalValue() } shouldBe
            listOf(DataValue.StringValueWrapper("First"), DataValue.StringValueWrapper("Second"))
        text.style?.fontWeight.literalValue() shouldBe DataValue.integer(java.math.BigInteger.valueOf(500))
        text.runs.map { it.style?.fontWeight?.literalValue() } shouldBe listOf(null, DataValue.integer(java.math.BigInteger.valueOf(700)))
        text.style?.color shouldNotBe null
    }

    test("one generic material serves every argument and a mapping of the wrong type rejects it") {
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
        val target = PresentationTarget.NamedWrapper(id.namedTemplate(listOf(parameter.template)))
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
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "symbolic presentation")))

        val material = assembly.editorCatalog.presentationMaterials.single()
        material.target shouldBe target
        val valueNode =
            material.layout
                .fixedChildren()
                .first()
                .element as PresentationElement.TypedFieldWrapper
        val expected = valueNode.value.expectedType.requireValid()
        expected shouldBe parameter.template
        val weight = material.layout.fixedChildren()[1].element as PresentationElement.NumericInputWrapper
        weight.value.appearance?.density shouldBe skirout.editor.v1.presentation.ControlDensity.COMPACT
        weight.value.options.minimum
            .literalValue() shouldBe DataValue.integer(java.math.BigInteger.ZERO)
        weight.value.content
            ?.placeholder
            .literalValue() shouldBe DataValue.StringValueWrapper("Weight")
        weight.value.control.label
            .literalValue() shouldBe DataValue.StringValueWrapper("Relative weight")
        weight.value.mappings?.display shouldNotBe null

        val text = mapOf(parameter to ScalarKind.TEXT.use)
        val integer = mapOf(parameter to integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use)
        (target.value.apply(text) as Resolution.Ready).value shouldBe id.namedUse(listOf(ScalarKind.TEXT.use))
        (target.value.apply(integer) as Resolution.Ready).value shouldBe
            id.namedUse(listOf(integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use))
        (expected.apply(text) as Resolution.Ready).value shouldBe ScalarKind.TEXT.use
        (expected.apply(integer) as Resolution.Ready).value shouldBe
            integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
        invalidMapping = true
        val rejected =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "invalid symbolic presentation")))
        rejected.editorCatalog.presentationMaterials shouldBe emptyList()
        rejected.editorCatalog.diagnostics.map { it.code } shouldBe listOf("presentation_material_build_failed")
    }

    test("isolates a named presentation with an invalid collection projection") {
        val subjectId = TypeDefinitionId.qualified("test", "InvalidCollectionSubject")
        val unrelatedId = TypeDefinitionId.qualified("test", "UnrelatedCollectionSubject")
        val subject =
            definitions {
                record(subjectId) {
                    field("title", ScalarKind.TEXT.template)
                }
            }.single()
        val unrelated =
            TypeDefinition.partial(
                id = unrelatedId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val target = PresentationTarget.NamedWrapper(subjectId.namedTemplate())
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
                    CatalogGeneration(value = "invalid presentation collection"),
                    relations = listOf(ownership("test.root.owns.0", RealmRootDefinition.id, subjectId)),
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
            definitions {
                record(baseId) {
                    field("title", ScalarKind.TEXT.template)
                }
            }.single()
        val child =
            TypeDefinition.partial(
                id = childId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(baseId.namedTemplate()),
            )
        val resource =
            definitions {
                record(resourceId) {
                    field("child", childId.template())
                    field("selected", ScalarKind.TEXT.template)
                }
            }.single()
        val target = PresentationTarget.NamedWrapper(resourceId.namedTemplate())
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
                    CatalogGeneration(value = "valid presentation collection"),
                    relations = listOf(ownership("test.root.owns.0", RealmRootDefinition.id, resourceId)),
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
            definitions {
                record(id) {
                    field("title", ScalarKind.TEXT.template)
                    field("selected", selected)
                }
            }.single()

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
                val target = PresentationTarget.NamedWrapper(id.namedTemplate())
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
                    CatalogGeneration(value = "invalid collection admission"),
                    relations =
                        listOf(literalId, boundedId).mapIndexed {
                            index,
                            member,
                            ->
                            ownership("test.root.owns.$index", RealmRootDefinition.id, member)
                        },
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

    test("a presentation reference resolves by the bound type and refuses a conflicting or missing registration") {
        val reference = object : PresentationReference {}
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "reference targets"), StandardTypes.definitions)
        val text = descriptor("text reference", PresentationTarget.RepresentationWrapper(RepresentationKind.TEXT), 0)
        val boolean = descriptor("boolean reference", PresentationTarget.RepresentationWrapper(RepresentationKind.BOOLEAN), 0)
        val first = DefaultPresentationRuntime()
        val second = DefaultPresentationRuntime()

        first.register(reference, text)
        first.register(reference, boolean)
        first.register(reference, text)

        shouldThrow<IllegalArgumentException> {
            first.register(reference, text.copy(target = PresentationTarget.RepresentationWrapper(RepresentationKind.INTEGER)))
        }.message shouldBe "One presentation id cannot describe different providers in one catalog runtime."

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
        shouldThrow<IllegalArgumentException> { selected(second, ScalarKind.TEXT) }.message shouldBe
            "The invoked presentation reference was not registered by its generated provider."
    }

    test("a field editor binds its field and remaining fields leave out the excluded ones") {
        val id = TypeDefinitionId.qualified("test", "PresentationSubject")
        val definition =
            TypeDefinition.partial(
                id = id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf("title", "note").map { name ->
                                FieldDeclaration.partial(owner = FieldOwner(definition = id, name = name), type = ScalarKind.TEXT.template)
                            },
                        abstract_ = false,
                    ),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "presentation runtime"), listOf(definition))
        val root =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(catalog.ready(id.use()).presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    val note: PresentedField<String, TextControl> = field("note", TextControl::class)
                    title {
                        label("Title")
                        textInput()
                    }
                    remainingFields { exclude(note) }
                }
            }
        val (fieldNode, remainingNode) = root.layout.fixedChildren()
        val field = (fieldNode.element as PresentationElement.TextInputWrapper).value

        field.control.binding.path.text shouldBe "title"
        field.control.label.literalValue() shouldBe DataValue.StringValueWrapper("Title")
        (remainingNode.element as PresentationElement.RemainingFieldsWrapper).value.excluded shouldBe
            listOf(
                skirout.editor.v1.type_catalog.RelativeFieldPattern
                    .of(
                        skirout.editor.v1.type_catalog.FieldPatternSegment
                            .field("note"),
                    ),
            )
    }

    /** A record with a single link field `link` and a set of links `links`. */
    val linkSubject =
        run {
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
                    definitions {
                        record(subjectId) {
                            field("link", linkType)
                            field("links", StandardTypes.set.template(listOf(linkType)))
                        }
                    }.single()
            val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "mangled link controls"), definitions)
            catalog.ready(subjectId.use())
        }

    test("single and collection link fields get link inputs with their candidate policy and reorder setting") {
        val checked = linkSubject
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

    test("a single link input cannot allow reordering") {
        shouldThrow<IllegalArgumentException> {
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(linkSubject.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                with(build) {
                    @Suppress("UNCHECKED_CAST")
                    val link: PresentedField<Any, LinkControl<ProjectionFixtureResource>> =
                        field("link", LinkControl::class as kotlin.reflect.KClass<LinkControl<ProjectionFixtureResource>>)

                    link { linkInput { allowReorder(true) } }
                }
            }
        }.message shouldBe "A single link cannot be reordered."
    }

    mapOf(
        "a polymorphic match with two cases for one type" to
            Rejection("A polymorphic match may declare one case per concrete type.") {
                PresentationDataFixture.build { title ->
                    polymorphicMatch(title.input) {
                        case(AppliedPresentation<String>(PresentationDataFixture.id.namedUse(), PresentationDataFixture.reference)) {}
                        case(AppliedPresentation<String>(PresentationDataFixture.id.namedUse(), PresentationDataFixture.reference)) {}
                    }
                }
            },
        "a polymorphic match without a case" to
            Rejection("A polymorphic match requires at least one concrete case.") {
                PresentationDataFixture.build { title ->
                    polymorphicMatch(title.input) { fallback { text(literal("fallback")) } }
                }
            },
        "a presentation parameter bound twice" to
            Rejection("A presentation parameter may be bound once per invocation.") {
                PresentationDataFixture.build { title ->
                    invoke(PresentationDataFixture.reference) {
                        bind(PresentationDataFixture.parameter, title.input)
                        bind(PresentationDataFixture.parameter, title.input)
                    }
                }
            },
        "a presentation parameter in the caller input namespace" to
            Rejection("Presentation parameters cannot shadow caller inputs.") {
                PresentationDataFixture.build { title ->
                    invoke(PresentationDataFixture.reference) {
                        bind(PresentationParameter<String>(ExpressionBindingId(value = "context:title")), title.input)
                    }
                }
            },
        "one caller input read with two types" to
            Rejection("Context input context:mode is declared with conflicting types.") {
                PresentationDataFixture.build {
                    context.read(
                        PresentationContextKey(
                            ExpressionBindingId(value = "context:mode"),
                            PresentationContextSource.CALLER,
                            PresentationContextValueType.Fixed<String>(ScalarKind.TEXT.use),
                        ),
                    )
                    context.read(
                        PresentationContextKey(
                            ExpressionBindingId(value = "context:mode"),
                            PresentationContextSource.CALLER,
                            PresentationContextValueType.Fixed<Long>(integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use),
                        ),
                    )
                }
            },
        "a caller input that shadows a binding" to
            Rejection("Context input ${CONFIGURED_VALUE.value} shadows a binding.") {
                PresentationDataFixture.build {
                    context.read(
                        PresentationContextKey(
                            CONFIGURED_VALUE,
                            PresentationContextSource.CALLER,
                            PresentationContextValueType.Fixed<String>(ScalarKind.TEXT.use),
                        ),
                    )
                }
            },
        "two search selectors with one id" to
            Rejection("Binding search_selector.tag is already declared in this scope.") {
                PresentationDataFixture.build { title ->
                    title {
                        searchInput<String> {
                            selectors {
                                selector("tag", "tag")
                                selector("tag", "tag")
                            }
                            provider(
                                sources.staticValues(
                                    com.typewritermc.expression.portableLiteral<List<String>>(DataValue.listValue(emptyList())),
                                ),
                            )
                            result {
                                key(row)
                                selectedValue(row)
                                presentation { text(row) }
                            }
                        }
                    }
                }
            },
    ).forEach { (case, rejection) ->
        test("$case is refused") {
            rejectionOf(rejection.check) shouldBe rejection.reason
        }
    }

    test("a field with a named presentation cannot also declare an explicit control") {
        val textReference = object : PresentationReference {}
        val runtime =
            DefaultPresentationRuntime().also {
                it.register(textReference, descriptor("plain text", PresentationTarget.RepresentationWrapper(RepresentationKind.TEXT), 0))
            }

        shouldThrow<IllegalArgumentException> {
            runtime.build(
                PresentationBuildBinding(PresentationDataFixture.checked.presentationTemplate(), PresentationRole.INSPECTOR),
            ) { build ->
                val title: PresentedField<String, TextControl> = build.field("title", TextControl::class)
                title(using = textReference) { textInput() }
            }
        }.message shouldBe "A named presentation reference cannot be combined with an explicit field control."
    }

    test("a presentation parameter cannot be named in the caller input namespace") {
        shouldThrow<IllegalArgumentException> { presentationParameter<String>("context:title") }.message shouldBe
            "Presentation parameters cannot shadow caller inputs."
    }

    test("layout containers and input options keep the values they were authored with") {
        val id = TypeDefinitionId.qualified("test", "PresentationInventory")
        val definition =
            definitions {
                record(id) {
                    field("title", ScalarKind.TEXT.template)
                    field("amount", integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)
                }
            }.single()
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "presentation inventory"), listOf(definition))
        val checked = catalog.ready(id.use())
        val root =
            DefaultPresentationRuntime().build(
                PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
            ) { build ->
                with(build) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)

                    @Suppress("UNCHECKED_CAST")
                    val amount: PresentedField<Int, NumberControl<Int>> =
                        field("amount", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
                    row(Spacing(4.0), MainAxisAlignment.SPACE_BETWEEN, CrossAxisAlignment.STRETCH) {
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
                    wrap(Spacing(2.0), Spacing(3.0)) { divider() }
                    grid(2, Spacing(4.0), Spacing(5.0)) { divider() }
                    stack { divider() }
                    section(PresentationBorder.All(1.0, literalColor(com.typewritermc.types.Color(0xff3366ccu)))) { divider() }
                    padding(PresentationInsets(Spacing(1.0), Spacing(2.0), Spacing(3.0), Spacing(4.0))) { divider() }
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
                        ) { dropdown { customValue { this } } }
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
        text.mappings?.completion shouldNotBe null
        text.control.prefix.iconName() shouldBe "book"
        val wrap = ((elements[1] as PresentationElement.ChildrenWrapper).value as ChildrenElement.WrapWrapper).value.layout
        listOf(wrap.spacing, wrap.runSpacing) shouldBe listOf(2.0, 3.0)
        val grid = ((elements[2] as PresentationElement.ChildrenWrapper).value as ChildrenElement.GridWrapper).value.layout
        listOf(grid.columns.toDouble(), grid.horizontalSpacing, grid.verticalSpacing) shouldBe listOf(2.0, 4.0, 5.0)
        ((elements[3] as PresentationElement.ChildrenWrapper).value is ChildrenElement.StackWrapper) shouldBe true
        val border = (elements[4] as PresentationElement.SectionWrapper).value.border
        (border as skirout.editor.v1.presentation.PresentationBorder.AllWrapper).value.width shouldBe 1.0
        with((elements[5] as PresentationElement.PaddingWrapper).value) { listOf(start, top, end, bottom) } shouldBe
            listOf(1.0, 2.0, 3.0, 4.0)
        (elements[6] is PresentationElement.ContainerWrapper) shouldBe true
        (elements[7] is PresentationElement.TooltipWrapper) shouldBe true
        val select = elements[8] as PresentationElement.SelectInputWrapper
        select.value.options
            .single()
            .optionId shouldBe "one"
        select.value.allowCustomValue shouldBe true
    }

    test("list, set and map editors bind items, keys and values to their own lexical bindings") {
        val elements = CompositeFixture.root().layout.fixedChildren()
        val map = (elements[2].element as PresentationElement.MapInputWrapper).value
        val nullable = (map.valuePresentation.singleFixed().element as PresentationElement.NullableInputWrapper).value

        (elements[0].element as PresentationElement.ListInputWrapper)
            .value.itemPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe
            "list_item"
        (elements[1].element as PresentationElement.SetInputWrapper)
            .value.itemPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe
            "set_item"
        map.keyPresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "map_key"
        nullable.valuePresentation
            .singleFixed()
            .boundControl()
            .binding.bindingId.value shouldBe "map_value"
    }

    test("a named scalar editor binds its payload at the field and a record editor binds its nested field") {
        val elements = CompositeFixture.root().layout.fixedChildren()

        (elements[3].element as PresentationElement.NamedInputWrapper)
            .value.payloadPresentation
            .singleFixed()
            .boundControl()
            .binding.path.text shouldBe
            "code"
        (elements[4].element as PresentationElement.RecordInputWrapper)
            .value.fieldPresentation
            .singleFixed()
            .boundControl()
            .binding.path.text shouldBe
            "position.x"
    }

    test("a nested record remainder covers the record's other fields under the configured value") {
        val record =
            CompositeFixture
                .nestedRemainder()
                .layout
                .singleFixed()
                .element as PresentationElement.RecordInputWrapper
        val children = requireNotNull(record.value.fieldPresentation).fixedChildren()
        val remainder = (children.last().element as PresentationElement.ScopedBindingWrapper).value

        children
            .first()
            .boundControl()
            .binding.path.text shouldBe "position.x"
        remainder.binding.path.text shouldBe "position"
        remainder.scopeBinding.id.value shouldBe "configured_value"
        (remainder.child.element is PresentationElement.RemainingFieldsWrapper) shouldBe true
    }

    test("nested named controls remain local to their record and collection binders") {
        val positionId = TypeDefinitionId.qualified("test", "NestedChoicePosition")
        val subjectId = TypeDefinitionId.qualified("test", "NestedChoiceSubject")
        val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
        val position =
            definitions {
                record(positionId) {
                    field("x", integer.template)
                }
            }.single()
        val subject =
            definitions {
                record(subjectId) {
                    field("style", positionId.template())
                    field("buttons", StandardTypes.list.template(listOf(positionId.template())))
                }
            }.single()
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "nested explicit presentation paths"),
                StandardTypes.definitions + position + subject,
            )
        val checked = catalog.ready(subjectId.use())
        val selected =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "special numeric")
        val reference = object : PresentationReference {}
        val runtime =
            DefaultPresentationRuntime().also {
                it.register(
                    reference,
                    descriptor("special numeric", PresentationTarget.RepresentationWrapper(RepresentationKind.INTEGER), 0),
                )
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
        val inherited = layout.layout.inferInheritableNodes()
        val nestedInvocations =
            layout.layout
                .allNodes()
                .filter { it.element is PresentationElement.DefaultPresentationWrapper }
                .map { it.nodeId }

        nestedInvocations shouldHaveSize 2
        inherited shouldHaveSize 3
        inherited.intersect(nestedInvocations.toSet()) shouldBe emptySet()
    }

    test("a data layout depends on its collection source, invoked presentation and subject type") {
        val dependencies = PresentationDataFixture.root().dependencies

        dependencies.collections.single().sourceId shouldBe "rows"
        dependencies.collections
            .single()
            .relations
            .single()
            .targets shouldBe PresentationDataFixture.repeatedSource.toNode()
        dependencies.presentations.single().name shouldBe "invoked"
        dependencies.types.single() shouldBe PresentationDataFixture.id.use()
    }

    test("a repeated node shows its empty and separator content") {
        val repeated = (dataElements()[0] as PresentationElement.RepeatedWrapper).value.presentation

        repeated.empty.literalText() shouldBe "empty"
        (repeated.separator?.element is PresentationElement.DividerWrapper) shouldBe true
    }

    test("a scoped node binds its editor to the scope it declares") {
        val scoped = (dataElements()[1] as PresentationElement.ScopedBindingWrapper).value

        scoped.child
            .singleFixed()
            .boundControl()
            .binding.bindingId shouldBe scoped.scopeBinding.id
    }

    test("a typed field binds its editor to the field") {
        (dataElements()[2] as PresentationElement.TypedFieldWrapper)
            .value.presentation
            .singleFixed()
            .boundControl()
            .binding.path.text shouldBe
            "title"
    }

    test("a collection lookup reads its source and shows loading content") {
        val lookup = (dataElements()[3] as PresentationElement.CollectionLookupWrapper).value

        lookup.sourceId shouldBe "rows"
        lookup.loading.literalText() shouldBe "loading"
    }

    test("a collection graph follows its relation in the authored direction up to its depth") {
        val graph = (dataElements()[4] as PresentationElement.CollectionGraphWrapper).value

        graph.sourceId shouldBe "rows"
        graph.relationId shouldBe "children"
        graph.maximumDepth shouldBe 4
        graph.direction shouldBe CollectionGraphDirection.REVERSE
    }

    test("a polymorphic match keeps its case and fallback") {
        val match = (dataElements()[5] as PresentationElement.PolymorphicMatchWrapper).value

        match.cases
            .single()
            .child
            .literalText() shouldBe "subject case"
        match.fallback.literalText() shouldBe "fallback"
    }

    test("an invocation binds its parameter to the field") {
        val argument = (dataElements()[6] as PresentationElement.InvocationWrapper).value.arguments.single()

        argument.input.value shouldBe "title"
        argument.binding.path.text shouldBe "title"
    }

    test("a lookup row binding carries the row type of its source") {
        with(PresentationDataFixture) {
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
                .rowBinding.type shouldBe ScalarKind.BOOLEAN.template
            otherResult.dependencies.presentations shouldBe emptyList()
        }
    }

    test("two collection sources under one id with different row types are refused") {
        with(PresentationDataFixture) {
            shouldThrow<IllegalArgumentException> {
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
            }.message shouldBe "One presentation build cannot declare conflicting collection sources with the same id."
        }
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
        val key = (byName.key.toNode() as ExpressionNode.OrElseWrapper).value
        key.fallback.literalValue() shouldBe DataValue.StringValueWrapper("unnamed")
        key.value shouldNotBe byResource.key.toNode()
        byName.relations shouldBe emptyList()
    }

    test("selects specific presentations before priority and preserves fallback order") {
        val id = TypeDefinitionId.qualified("test", "RegistrySubject")
        val definition =
            TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false))
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "presentation registry"), listOf(definition))
        val checked = catalog.ready(id.use())
        val representation =
            descriptor("generic", PresentationTarget.RepresentationWrapper(skirout.editor.v1.catalog.RepresentationKind.RECORD), 100)
        val named = descriptor("specific", PresentationTarget.NamedWrapper(id.namedTemplate()), 10)
        val fallbackFirst =
            descriptor("fallback first", PresentationTarget.NamedWrapper(id.namedTemplate()), 10, PresentationRole.REFERENCE_PREVIEW)
        val fallbackSecond =
            descriptor("fallback second", PresentationTarget.NamedWrapper(id.namedTemplate()), 100, PresentationRole.RESOURCE_SEARCH_RESULT)
        val registry =
            DefaultPresentationRegistry(
                catalog,
                listOf(representation, named, fallbackFirst, fallbackSecond),
                listOf(
                    RoleFallback(
                        role = PresentationRole.REFERENCE_PICKER_RESULT,
                        parents = listOf(PresentationRole.REFERENCE_PREVIEW, PresentationRole.RESOURCE_SEARCH_RESULT),
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
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "reference fallback"), listOf(definition))
        val checked = catalog.ready(id.use())
        val preview = descriptor("preview", PresentationTarget.NamedWrapper(id.namedTemplate()), 0, PresentationRole.REFERENCE_PREVIEW)
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

        val inspector = descriptor("inspector", preview.target, 0, PresentationRole.INSPECTOR)
        DefaultPresentationRegistry(catalog, listOf(inspector), com.typewritermc.discovery.DEFAULT_ROLE_FALLBACKS)
            .select(PresentationRole.WORKSPACE, checked) shouldBe PresentationSelection.Missing(PresentationRole.WORKSPACE)
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
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "incomparable presentations"), StandardTypes.definitions + definition)
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
                PresentationTarget.NamedWrapper(
                    pairId.namedTemplate(listOf(ScalarKind.TEXT.template, first.template)),
                ),
                10,
            )
        val right =
            descriptor(
                "right",
                PresentationTarget.NamedWrapper(
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
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "repeated parameter presentation"), listOf(definition))
        val actual =
            catalog.ready(
                pairId.use(listOf(ScalarKind.TEXT.use, ScalarKind.TEXT.use)),
            )
        val repeated =
            descriptor(
                "repeated",
                PresentationTarget.NamedWrapper(
                    pairId.namedTemplate(listOf(first.template, first.template)),
                ),
                10,
            )
        val broad =
            descriptor(
                "broad",
                PresentationTarget.NamedWrapper(
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
                CatalogGeneration(value = "readable presentation argument"),
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
                PresentationTarget.NamedWrapper(
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
                CatalogGeneration(value = "specific readable presentation argument"),
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
                PresentationTarget.NamedWrapper(
                    variableId.namedTemplate(listOf(coinId.template())),
                ),
                10,
            )
        val broad =
            descriptor(
                "reward variable",
                PresentationTarget.NamedWrapper(
                    variableId.namedTemplate(listOf(rewardId.template())),
                ),
                100,
            )

        val selection = DefaultPresentationRegistry(catalog, listOf(concrete, broad)).select(PresentationRole.WORKSPACE, actual)

        (selection as PresentationSelection.Selected).descriptor.id shouldBe concrete.id
    }
}
