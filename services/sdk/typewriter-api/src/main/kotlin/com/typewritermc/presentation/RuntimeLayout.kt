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
            return PresentationSubjectExpressions(com.typewritermc.expression.inputExpression(SUBJECT_IDENTIFIER, ValuePath.root))
        }
    override val context = RuntimePresentationContext(state)

    override fun clippedRow(
        spacing: Spacing,
        body: Layout.() -> Unit,
    ) {
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
                                spacing = spacing.pixels,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.CENTER,
                                clipOverflow = true,
                            ),
                    ),
                ),
            )
    }

    override fun row(
        spacing: Spacing,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
        body: AxisLayout.() -> Unit,
    ) = axisLayout(true, spacing, main, cross, body)

    override fun column(
        spacing: Spacing,
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
        RuntimeDividerAppearanceScope(state, draft).configure()
        target += state.node(PresentationElement.DividerWrapper(draft.toFrozen()))
    }

    override fun spacer(
        width: Expr<Double, Handled>?,
        height: Expr<Double, Handled>?,
    ) {
        target +=
            state.node(
                PresentationElement.createSpacer(
                    width = width?.let { state.lower(it, DOUBLE_SLOT) },
                    height = height?.let { state.lower(it, DOUBLE_SLOT) },
                ),
            )
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
            RuntimeTabsScope(RuntimeTextEntryAppearance(state, visual)) { id, label, icon, body ->
                require(id.isNotBlank() && items.none { it.tabId == id }) { "Tab identifiers must be nonempty and unique." }
                items +=
                    skirout.editor.v1.presentation.TabItem(
                        tabId = id,
                        label = state.lower(label, TEXT_SLOT),
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
        spacing: Spacing,
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
        spacing: Spacing,
        runSpacing: Spacing,
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
                                spacing = spacing.pixels,
                                runSpacing = runSpacing.pixels,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.START,
                            ),
                    ),
                ),
            )
    }

    override fun grid(
        columns: Int,
        horizontalSpacing: Spacing,
        verticalSpacing: Spacing,
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
                                horizontalSpacing = horizontalSpacing.pixels,
                                verticalSpacing = verticalSpacing.pixels,
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
                    border = border?.wire(state),
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
                    top = insets.top.pixels,
                    start = insets.start.pixels,
                    end = insets.end.pixels,
                    bottom = insets.bottom.pixels,
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
                    border = style.border?.wire(state),
                    backgroundColor = style.background?.wire(state),
                    radius = style.radius.wire(state),
                    foregroundColor = style.foreground?.wire(state),
                    transition = style.transition?.requireValid(),
                    shadows = style.shadows.map { it.wire(state) },
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
                    width = width?.let { state.lower(literal(it), DOUBLE_SLOT) },
                    height = height?.let { state.lower(literal(it), DOUBLE_SLOT) },
                    minimumWidth = minimumWidth?.let { state.lower(literal(it), DOUBLE_SLOT) },
                    maximumWidth = maximumWidth?.let { state.lower(literal(it), DOUBLE_SLOT) },
                    minimumHeight = minimumHeight?.let { state.lower(literal(it), DOUBLE_SLOT) },
                    maximumHeight = maximumHeight?.let { state.lower(literal(it), DOUBLE_SLOT) },
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
                    scale = style.scale?.wire(state),
                    rotateX = style.rotateX?.wire(state),
                    rotateY = style.rotateY?.wire(state),
                    rotateZ = style.rotateZ?.wire(state),
                    translateX = style.translateX?.wire(state),
                    translateY = style.translateY?.wire(state),
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
                        .AppearanceDefaultsElement(appearance = appearance.wire(), child = child(body)),
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
        val scope = RuntimeAnchorScope(state)
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
                        enabledIf = properties.enabledIf?.let { state.lower(it, BOOLEAN_SLOT) },
                        readOnly = properties.readOnly,
                    ),
                header = headerScope.build(),
            )
    }

    override fun fixed(body: Layout.() -> Unit) {
        val axis = requireNotNull(axis) { "Fixed children are only available inside row and column layouts." }
        axis += child(body)
    }

    private fun InputAppearance.wire(): skirout.editor.v1.presentation.InputAppearance {
        val draft =
            skirout.editor.v1.presentation.InputAppearance
                .partial()
                .toMutable()
        RuntimeTextEntryAppearance(state, draft).configure()
        return draft.toFrozen()
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
                top = top?.wire(state),
                start = start?.wire(state),
                end = end?.wire(state),
                bottom = bottom?.wire(state),
                width = width?.wire(state),
                height = height?.wire(state),
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
    private var padding = PresentationInsets.all(Spacing.NONE)
    private var compactPadding = PresentationInsets.all(Spacing.NONE)
    private var gap = Spacing(8.0)
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

    override fun gap(value: Spacing) {
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
            gap = gap.pixels,
            minimumCenterWidth = minimumCenterWidth,
        )
}
