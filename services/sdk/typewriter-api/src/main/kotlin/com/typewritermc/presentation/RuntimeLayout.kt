package com.typewritermc.presentation

import com.typewritermc.authoring.root
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.requireValid
import com.typewritermc.types.use
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.FlexFit
import skirout.editor.v1.presentation.GridChildrenLayout
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationTransitionPolicy
import skirout.editor.v1.presentation.WrapChildrenLayout
import skirout.editor.v1.type_catalog.ValuePath

internal class RuntimeLayout(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
    private val axis: PresentationAxisNodeList?,
    private val checked: CheckedPresentationTemplate,
    private val base: BindingRef,
) : AxisLayout,
    PresentationQueries by state.queries,
    PresentationContent by RuntimePresentationContent(state, target),
    PresentationData by RuntimePresentationData(state, target, checked),
    PresentationInteractions by RuntimePresentationInteractions(state, target) {
    override val role get() = state.role
    override val subject: PresentationSubjectExpressions
        get() {
            state.type(com.typewritermc.types.ResourceIdDefinition.use.use)
            return PresentationSubjectExpressions(
                com.typewritermc.expression.inputExpression(
                    skirout.editor.v1.type_catalog
                        .ExpressionBindingId(value = "presentation.subject.identifier"),
                    ValuePath.root,
                ),
            )
        }
    override val context = RuntimePresentationContext(state)

    override fun clippedRow(
        spacing: Double,
        body: Layout.() -> Unit,
    ) {
        require(spacing.isFinite() && spacing >= 0) { "Row spacing must be finite and nonnegative." }
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { state.scope(children).body() }
        target +=
            state.node(
                PresentationElement.ChildrenWrapper(
                    ChildrenElement.createRow(
                        children =
                            children.map {
                                skirout.editor.v1.presentation.AxisChild
                                    .FixedWrapper(it)
                            },
                        layout =
                            skirout.editor.v1.presentation.AxisChildrenLayout(
                                spacing = spacing,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.CENTER,
                                clipOverflow = true,
                            ),
                    ),
                ),
            )
    }

    override fun row(
        spacing: Double,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
        body: AxisLayout.() -> Unit,
    ) = axisLayout(true, spacing, main, cross, body)

    override fun column(
        spacing: Double,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
        body: AxisLayout.() -> Unit,
    ) = axisLayout(false, spacing, main, cross, body)

    override fun slot(id: String) {
        target += state.node(PresentationElement.createSlot(slotId = id))
    }

    override fun part(
        key: PresentationPartKey<*>,
        body: (Layout.() -> Unit)?,
    ) {
        target += configuredScope(state.node(PresentationElement.createPart(key = state.partId(key), body = body?.let(::child))))
    }

    override fun divider(configure: DividerAppearanceScope.() -> Unit) {
        val draft =
            skirout.editor.v1.presentation.DividerAppearance
                .partial()
                .toMutable()
        RuntimeDividerAppearanceScope(draft).configure()
        target += state.node(PresentationElement.DividerWrapper(draft.toFrozen()))
    }

    override fun spacer(
        width: Expr<Double, Handled>?,
        height: Expr<Double, Handled>?,
    ) {
        target += state.node(PresentationElement.createSpacer(width = width?.let(::expression), height = height?.let(::expression)))
    }

    override fun remainingFields(configure: RemainingFields.() -> Unit) {
        val excluded = mutableListOf<String>()
        val excludedParts = mutableListOf<skirout.editor.v1.presentation.PresentationPartId>()
        val scope =
            object : RemainingFields {
                override fun exclude(part: PresentationPartKey<*>) {
                    excludedParts += state.partId(part)
                }

                override fun exclude(field: PresentedField<*, *>) {
                    excluded += (field as RuntimePresentedField<*, *>).name
                }
            }
        scope.configure()
        val patterns =
            excluded.map { name ->
                skirout.editor.v1.type_catalog.RelativeFieldPattern(
                    segments =
                        listOf(
                            skirout.editor.v1.type_catalog.FieldPatternSegment.FieldWrapper(
                                skirout.editor.v1.type_catalog
                                    .NamedFieldPatternSegment(name = name),
                            ),
                        ),
                )
            }
        val remainder = state.node(PresentationElement.createRemainingFields(excluded = patterns, excludedParts = excludedParts))
        target += configuredScope(remainder)
    }

    private fun configuredScope(node: PresentationNode): PresentationNode =
        if (base.bindingId == CONFIGURED_VALUE && base.path.segments.isEmpty()) {
            node
        } else {
            state.node(
                PresentationElement.createScopedBinding(
                    binding = base,
                    scopeBinding =
                        skirout.editor.v1.presentation
                            .BindingDeclaration(id = CONFIGURED_VALUE, type = checked.type),
                    child = node,
                ),
            )
        }

    override fun tabs(
        initial: String?,
        body: TabsScope.() -> Unit,
    ) {
        val items = mutableListOf<skirout.editor.v1.presentation.TabItem>()
        val visual =
            skirout.editor.v1.presentation.InputAppearance
                .partial()
                .toMutable()
        val scope =
            RuntimeTabsScope(RuntimeTextEntryAppearance(visual)) { id, label, icon, body ->
                require(id.isNotBlank() && items.none { it.tabId == id }) { "Tab identifiers must be nonempty and unique." }
                items +=
                    skirout.editor.v1.presentation.TabItem(
                        tabId = id,
                        label = expression(label),
                        child = child(body),
                        icon =
                            icon?.let {
                                state.iconNode(it, IconOptions())
                            },
                    )
            }
        scope.body()
        target +=
            state.node(
                PresentationElement.createTabs(
                    tabs = items,
                    initiallySelectedTabId = initial,
                    appearance = visual.toFrozen(),
                    spacing = scope.spacing,
                    contentSpacing = scope.contentSpacing,
                ),
            )
    }

    private fun child(configuration: Layout.() -> Unit): PresentationNode {
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { state.scope(children).configuration() }
        return state.column(children)
    }

    private fun axisLayout(
        row: Boolean,
        spacing: Double,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
        body: AxisLayout.() -> Unit,
    ) {
        val children = PresentationAxisNodeList(horizontal = row)
        state.withTarget(children) { state.scope(children, children).body() }
        target +=
            state.axis(
                children.children,
                row,
                spacing,
                main,
                cross,
            )
    }

    override fun wrap(
        spacing: Double,
        runSpacing: Double,
        body: Layout.() -> Unit,
    ) {
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { state.scope(children).body() }
        target +=
            state.node(
                PresentationElement.ChildrenWrapper(
                    ChildrenElement.createWrap(
                        children = children,
                        layout =
                            WrapChildrenLayout(
                                spacing = spacing,
                                runSpacing = runSpacing,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.START,
                            ),
                    ),
                ),
            )
    }

    override fun grid(
        columns: Int,
        horizontalSpacing: Double,
        verticalSpacing: Double,
        body: Layout.() -> Unit,
    ) {
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { state.scope(children).body() }
        target +=
            state.node(
                PresentationElement.ChildrenWrapper(
                    ChildrenElement.createGrid(
                        children = children,
                        layout =
                            GridChildrenLayout(
                                columns = columns,
                                horizontalSpacing = horizontalSpacing,
                                verticalSpacing = verticalSpacing,
                            ),
                    ),
                ),
            )
    }

    override fun stack(
        alignment: PresentationAlignment?,
        body: StackLayout.() -> Unit,
    ) {
        val children = PresentationStackNodeList()
        state.withTarget(children) { RuntimeStackLayout(state, state.scope(children), children).body() }
        target +=
            state.node(
                PresentationElement.ChildrenWrapper(
                    ChildrenElement.createStack(children = children.children, alignment = alignment),
                ),
            )
    }

    override fun section(
        border: PresentationBorder?,
        header: HeaderScope.() -> Unit,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createSection(
                    child = child(body),
                    border = border?.wire(),
                ),
                header = RuntimeHeaderScope(state).apply(header).build(),
            )
    }

    override fun padding(
        insets: PresentationInsets,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createPadding(
                    child = child(body),
                    top = insets.top,
                    start = insets.start,
                    end = insets.end,
                    bottom = insets.bottom,
                ),
            )
    }

    override fun container(
        style: ContainerStyle,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createContainer(
                    child = child(body),
                    border = style.border?.wire(),
                    backgroundColor = style.background?.wire(),
                    radius = style.radius.wire(),
                    foregroundColor = style.foreground?.wire(),
                    transition = style.transition?.requireValid(),
                    shadows = style.shadows.map { it.wire() },
                ),
            )
    }

    override fun size(
        width: Double?,
        height: Double?,
        minimumWidth: Double?,
        maximumWidth: Double?,
        minimumHeight: Double?,
        maximumHeight: Double?,
        body: Layout.() -> Unit,
    ) {
        val bounds = listOfNotNull(width, height, minimumWidth, maximumWidth, minimumHeight, maximumHeight)
        require(bounds.all { it.isFinite() && it >= 0.0 }) { "Sizes must be finite and nonnegative." }
        require(minimumWidth == null || maximumWidth == null || minimumWidth <= maximumWidth) {
            "A minimum width cannot exceed its maximum."
        }
        require(minimumHeight == null || maximumHeight == null || minimumHeight <= maximumHeight) {
            "A minimum height cannot exceed its maximum."
        }
        target +=
            state.node(
                PresentationElement.createSize(
                    child = child(body),
                    width = width?.let { expression(literal(it)) },
                    height = height?.let { expression(literal(it)) },
                    minimumWidth = minimumWidth?.let { expression(literal(it)) },
                    maximumWidth = maximumWidth?.let { expression(literal(it)) },
                    minimumHeight = minimumHeight?.let { expression(literal(it)) },
                    maximumHeight = maximumHeight?.let { expression(literal(it)) },
                ),
            )
    }

    override fun transform(
        style: TransformStyle,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createTransform(
                    child = child(body),
                    origin = style.origin,
                    perspective = style.perspective,
                    scale = style.scale?.wire(),
                    rotateX = style.rotateX?.wire(),
                    rotateY = style.rotateY?.wire(),
                    rotateZ = style.rotateZ?.wire(),
                    translateX = style.translateX?.wire(),
                    translateY = style.translateY?.wire(),
                    transition = style.transition?.requireValid(),
                ),
            )
    }

    override fun withInputAppearance(
        appearance: InputAppearance,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.AppearanceDefaultsWrapper(
                    skirout.editor.v1.presentation
                        .AppearanceDefaultsElement(appearance = appearance, child = child(body)),
                ),
            )
    }

    override fun align(
        alignment: PresentationAlignment,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createAlign(
                    child = child(body),
                    alignment = alignment,
                ),
            )
    }

    override fun adaptiveLeading(configure: AdaptiveLeadingScope.() -> Unit) {
        val scope = RuntimeAdaptiveLeadingScope(state)
        scope.configure()
        target += state.node(PresentationElement.AdaptiveLeadingWrapper(scope.build()))
    }

    override fun anchors(
        configure: AnchorScope.() -> Unit,
        body: Layout.() -> Unit,
    ) {
        val scope = RuntimeAnchorScope()
        scope.configure()
        target +=
            state.node(
                PresentationElement.createAnchor(
                    child = child(body),
                    anchors = scope.build(),
                ),
            )
    }

    override fun connectionLayer(
        configure: ConnectionsScope.() -> Unit,
        body: Layout.() -> Unit,
    ) {
        val scope = RuntimeConnectionsScope(state)
        scope.configure()
        target +=
            state.node(
                PresentationElement.createConnectionLayer(
                    child = child(body),
                    connections = scope.build(),
                ),
            )
    }

    override fun node(
        id: String,
        properties: PresentationProperties,
        header: HeaderScope.() -> Unit,
        body: Layout.() -> Unit,
    ) {
        require(id.isNotBlank()) { "Presentation node id must not be blank." }
        val headerScope = RuntimeHeaderScope(state)
        headerScope.header()
        val nodeBody = child(body)
        target +=
            nodeBody.copy(
                nodeId = id,
                properties =
                    skirout.editor.v1.presentation.PresentationProperties(
                        enabledIf = properties.enabledIf?.let(::expression),
                        readOnly = properties.readOnly,
                    ),
                header = headerScope.build(),
            )
    }

    override fun fixed(body: Layout.() -> Unit) {
        val axis = requireNotNull(axis) { "Fixed children are only available inside row and column layouts." }
        axis += child(body)
    }

    override fun flexible(
        flex: Int,
        fit: FlexFit,
        body: Layout.() -> Unit,
    ) {
        val axis = requireNotNull(axis) { "Flexible children are only available inside row and column layouts." }
        axis.addFlexible(child(body), flex, fit)
    }
}

/** Places positioned children into the enclosing stack; direct children flow through the delegated layout. */
private class RuntimeStackLayout(
    private val state: PresentationBuildState,
    layout: Layout,
    private val children: PresentationStackNodeList,
) : StackLayout,
    Layout by layout {
    override fun positioned(
        top: PresentationNumber?,
        start: PresentationNumber?,
        end: PresentationNumber?,
        bottom: PresentationNumber?,
        width: PresentationNumber?,
        height: PresentationNumber?,
        transition: PresentationTransitionPolicy?,
        body: Layout.() -> Unit,
    ) {
        require(listOfNotNull(start, end, width).size <= 2) { "A positioned child may declare at most two horizontal bounds." }
        require(listOfNotNull(top, bottom, height).size <= 2) { "A positioned child may declare at most two vertical bounds." }
        children.addPositioned(
            skirout.editor.v1.presentation.PositionedStackChild(
                child = state.presentation(body),
                top = top?.wire(),
                start = start?.wire(),
                end = end?.wire(),
                bottom = bottom?.wire(),
                width = width?.wire(),
                height = height?.wire(),
                transition = transition?.requireValid(),
            ),
        )
    }
}

private class RuntimeAdaptiveLeadingScope(
    private val state: PresentationBuildState,
) : AdaptiveLeadingScope {
    private var leading: PresentationNode? = null
    private var center: PresentationNode? = null
    private var suffix: PresentationNode? = null
    private var padding = PresentationInsets(0.0, 0.0, 0.0, 0.0)
    private var compactPadding = PresentationInsets(0.0, 0.0, 0.0, 0.0)
    private var gap = 8.0
    private var minimumCenterWidth = 30.0

    override fun leading(body: Layout.() -> Unit) {
        check(leading == null) { "Adaptive leading content may be declared once." }
        leading = state.presentation(body)
    }

    override fun center(body: Layout.() -> Unit) {
        check(center == null) { "Adaptive center content may be declared once." }
        center = state.presentation(body)
    }

    override fun suffix(body: Layout.() -> Unit) {
        check(suffix == null) { "Adaptive suffix content may be declared once." }
        suffix = state.presentation(body)
    }

    override fun padding(value: PresentationInsets) {
        padding = value
    }

    override fun compactPadding(value: PresentationInsets) {
        compactPadding = value
    }

    override fun gap(value: Double) {
        require(value.isFinite() && value >= 0.0) { "Adaptive leading gap must be finite and nonnegative." }
        gap = value
    }

    override fun minimumCenterWidth(value: Double) {
        require(value.isFinite() && value >= 0.0) { "Adaptive center width must be finite and nonnegative." }
        minimumCenterWidth = value
    }

    fun build(): skirout.editor.v1.presentation.AdaptiveLeadingElement =
        skirout.editor.v1.presentation.AdaptiveLeadingElement(
            leading = requireNotNull(leading) { "Adaptive leading content is required." },
            center = center,
            suffix = suffix,
            padding = padding.wire(),
            compactPadding = compactPadding.wire(),
            gap = gap,
            minimumCenterWidth = minimumCenterWidth,
        )
}
