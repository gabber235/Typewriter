package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.GridChildrenLayout
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.WrapChildrenLayout
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment

internal class RuntimeLayout(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
    private val axis: PresentationAxisNodeList?,
    private val checked: CheckedPresentationTemplate,
    private val base: BindingRef,
) : AxisLayout,
    PresentationContent by RuntimePresentationContent(state, target),
    PresentationData by RuntimePresentationData(state, target, checked),
    PresentationInteractions by RuntimePresentationInteractions(state, target) {
    override val role get() = state.role
    override val subject =
        PresentationSubjectExpressions(
            Expr(
                ExpressionNode.Read(
                    com.typewritermc.expression.ExpressionBindingId("presentation.subject.identifier"),
                    com.typewritermc.authoring.ValuePath(),
                ),
            ),
        )
    override val context =
        PresentationContextExpressions(
            Expr(
                ExpressionNode.Read(
                    com.typewritermc.expression.ExpressionBindingId("presentation.context.selection_count"),
                    com.typewritermc.authoring.ValuePath(),
                ),
            ),
        )

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

    override fun divider() {
        target += state.node(PresentationElement.DIVIDER)
    }

    override fun spacer(
        width: Expr<Double, Handled>?,
        height: Expr<Double, Handled>?,
    ) {
        target += state.node(PresentationElement.createSpacer(width = width?.let(::expression), height = height?.let(::expression)))
    }

    override fun remainingFields(configure: RemainingFields.() -> Unit) {
        val excluded = mutableListOf<String>()
        val scope =
            object : RemainingFields {
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
        target += state.node(PresentationElement.createRemainingFields(excluded = patterns))
    }

    override fun tabs(
        initial: String?,
        body: TabsScope.() -> Unit,
    ) {
        val items = mutableListOf<skirout.editor.v1.presentation.TabItem>()
        val scope =
            object : TabsScope {
                override fun tab(
                    id: String,
                    label: Expr<String, Handled>,
                    body: Layout.() -> Unit,
                ) {
                    items +=
                        skirout.editor.v1.presentation.TabItem(
                            tabId = id,
                            label = expression(label),
                            child = child(body),
                        )
                }
            }
        scope.body()
        target +=
            state.node(
                PresentationElement.createTabs(
                    tabs = items,
                    initiallySelectedTabId = initial,
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
        val children = PresentationAxisNodeList()
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
                                mainAxisAlignment = WireMainAxisAlignment.START,
                                crossAxisAlignment = WireCrossAxisAlignment.START,
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

    override fun stack(body: Layout.() -> Unit) {
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { state.scope(children).body() }
        target += state.node(PresentationElement.ChildrenWrapper(ChildrenElement.createStack(children = children)))
    }

    override fun section(
        border: PresentationBorder?,
        body: Layout.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createSection(
                    child = child(body),
                    border = border?.wire(),
                ),
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
                    transitionMilliseconds = style.transitionMilliseconds,
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
                    alignment = alignment.wire(),
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
        val headerScope = RuntimeHeaderScope(state, base)
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
