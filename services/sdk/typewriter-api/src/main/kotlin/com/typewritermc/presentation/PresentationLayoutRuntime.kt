package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.GridChildrenLayout
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.WrapChildrenLayout
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment

internal fun PresentationLayoutHandler.tabs(args: Array<out Any?>) {
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
    invokeBlock(args[1], scope)
    target +=
        state.node(
            PresentationElement.createTabs(
                tabs = items,
                initiallySelectedTabId = args[0] as String?,
            ),
        )
}

internal fun PresentationLayoutHandler.child(configuration: Any?): PresentationNode {
    val children = mutableListOf<PresentationNode>()
    state.withTarget(children) { invokeBlock(configuration, state.scope(children)) }
    return state.column(children)
}

internal fun PresentationLayoutHandler.axisLayout(
    row: Boolean,
    args: Array<out Any?>,
) {
    val children = PresentationAxisNodeList()
    state.withTarget(children) { invokeBlock(args.last(), state.scope(children, children)) }
    target +=
        state.axis(
            children.children,
            row,
            args[0] as Double,
            args[1] as MainAxisAlignment,
            args[2] as CrossAxisAlignment,
        )
}

internal fun PresentationLayoutHandler.wrap(args: Array<out Any?>) {
    val children = mutableListOf<PresentationNode>()
    state.withTarget(children) { invokeBlock(args.last(), state.scope(children)) }
    target +=
        state.node(
            PresentationElement.ChildrenWrapper(
                ChildrenElement.createWrap(
                    children = children,
                    layout =
                        WrapChildrenLayout(
                            spacing = args[0] as Double,
                            runSpacing = args[1] as Double,
                            mainAxisAlignment = WireMainAxisAlignment.START,
                            crossAxisAlignment = WireCrossAxisAlignment.START,
                        ),
                ),
            ),
        )
}

internal fun PresentationLayoutHandler.grid(args: Array<out Any?>) {
    val children = mutableListOf<PresentationNode>()
    state.withTarget(children) { invokeBlock(args.last(), state.scope(children)) }
    target +=
        state.node(
            PresentationElement.ChildrenWrapper(
                ChildrenElement.createGrid(
                    children = children,
                    layout =
                        GridChildrenLayout(
                            columns = args[0] as Int,
                            horizontalSpacing = args[1] as Double,
                            verticalSpacing = args[2] as Double,
                        ),
                ),
            ),
        )
}

internal fun PresentationLayoutHandler.stack(configuration: Any?) {
    val children = mutableListOf<PresentationNode>()
    state.withTarget(children) { invokeBlock(configuration, state.scope(children)) }
    target += state.node(PresentationElement.ChildrenWrapper(ChildrenElement.createStack(children = children)))
}

internal fun PresentationLayoutHandler.section(args: Array<out Any?>) {
    val border = args[0] as? PresentationBorder
    target +=
        state.node(
            PresentationElement.createSection(
                child = child(args.last()),
                border = border?.wire(),
            ),
        )
}

internal fun PresentationLayoutHandler.padding(args: Array<out Any?>) {
    val insets = args[0] as PresentationInsets
    target +=
        state.node(
            PresentationElement.createPadding(
                child = child(args.last()),
                top = insets.top,
                start = insets.start,
                end = insets.end,
                bottom = insets.bottom,
            ),
        )
}

internal fun PresentationLayoutHandler.container(args: Array<out Any?>) {
    val style = args[0] as ContainerStyle
    target +=
        state.node(
            PresentationElement.createContainer(
                child = child(args.last()),
                border = style.border?.wire(),
                backgroundColor = style.color?.let(::expression),
                radius = skirout.editor.v1.presentation.PresentationRadius.NONE,
            ),
        )
}

internal fun PresentationLayoutHandler.tooltip(args: Array<out Any?>) {
    target +=
        state.node(
            PresentationElement.createTooltip(
                message = expression(args[0]),
                child = child(args[1]),
            ),
        )
}

internal fun PresentationLayoutHandler.adaptiveLeading(configuration: Any?) {
    val scope = RuntimeAdaptiveLeadingScope(state)
    invokeBlock(configuration, scope)
    target += state.node(PresentationElement.AdaptiveLeadingWrapper(scope.build()))
}

internal fun PresentationLayoutHandler.anchors(args: Array<out Any?>) {
    val scope = RuntimeAnchorScope()
    invokeBlock(args[0], scope)
    target +=
        state.node(
            PresentationElement.createAnchor(
                child = child(args[1]),
                anchors = scope.build(),
            ),
        )
}

internal fun PresentationLayoutHandler.connectionLayer(args: Array<out Any?>) {
    val scope = RuntimeConnectionsScope(state)
    invokeBlock(args[0], scope)
    target +=
        state.node(
            PresentationElement.createConnectionLayer(
                child = child(args[1]),
                connections = scope.build(),
            ),
        )
}

internal fun PresentationLayoutHandler.authoredNode(args: Array<out Any?>) {
    val id = args[0] as String
    require(id.isNotBlank()) { "Presentation node id must not be blank." }
    val properties = args[1] as PresentationProperties
    val headerScope = RuntimeHeaderScope(state, base)
    invokeBlock(args[2], headerScope)
    val body = child(args[3])
    target +=
        body.copy(
            nodeId = id,
            properties =
                skirout.editor.v1.presentation.PresentationProperties(
                    enabledIf = properties.enabledIf?.let(::expression),
                    readOnly = properties.readOnly,
                ),
            header = headerScope.build(),
        )
}

internal fun PresentationLayoutHandler.fixed(configuration: Any?) {
    val axis = requireNotNull(axis) { "Fixed children are only available inside row and column layouts." }
    axis += child(configuration)
}

internal fun PresentationLayoutHandler.flexible(args: Array<out Any?>) {
    val axis = requireNotNull(axis) { "Flexible children are only available inside row and column layouts." }
    axis.addFlexible(child(args.last()), args[0] as Int, args[1] as FlexFit)
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
