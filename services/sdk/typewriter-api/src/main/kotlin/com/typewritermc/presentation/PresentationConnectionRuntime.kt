package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled

internal class RuntimeAnchorScope : AnchorScope {
    private val anchors = mutableListOf<skirout.editor.v1.presentation.PresentationAnchorPoint>()

    override fun point(
        id: String,
        configure: AnchorPointScope.() -> Unit,
    ) {
        require(id.isNotBlank()) { "Anchor id must not be blank." }
        require(anchors.none { it.anchorId == id }) { "Anchor ids must be unique within one layout." }
        anchors += RuntimeAnchorPointScope(id).apply(configure).build()
    }

    fun build(): List<skirout.editor.v1.presentation.PresentationAnchorPoint> = anchors.toList()
}

private class RuntimeAnchorPointScope(
    private val id: String,
) : AnchorPointScope {
    private val groups = linkedSetOf<String>()
    private var alignment = AnchorAlignment.Center
    private var offset: PresentationOffset? = null
    private var visibleIf: Expr<Boolean, Handled>? = null
    private var exportToParent = false

    override fun groups(vararg ids: String) {
        require(ids.all(String::isNotBlank)) { "Anchor group ids must not be blank." }
        groups += ids
    }

    override fun alignment(value: AnchorAlignment) {
        alignment = value
    }

    override fun offset(value: PresentationOffset) {
        offset = value
    }

    override fun visibleIf(condition: Expr<Boolean, Handled>) {
        visibleIf = condition
    }

    override fun exportToParent(value: Boolean) {
        exportToParent = value
    }

    fun build(): skirout.editor.v1.presentation.PresentationAnchorPoint =
        skirout.editor.v1.presentation.PresentationAnchorPoint(
            anchorId = id,
            groupIds = groups,
            alignment = alignment.wire(),
            offset = offset?.wire(),
            visibleIf = visibleIf?.let(::expression),
            exportToParent = exportToParent,
        )
}

internal class RuntimeConnectionsScope(
    private val state: PresentationBuildState,
) : ConnectionsScope {
    private val connections = mutableListOf<skirout.editor.v1.presentation.PresentationConnection>()

    override fun connection(configure: ConnectionScope.() -> Unit) {
        connections +=
            skirout.editor.v1.presentation.PresentationConnection.ConnectionWrapper(
                RuntimeConnectionScope(state).apply(configure).build(),
            )
    }

    override fun bundle(configure: ConnectionBundleScope.() -> Unit) {
        connections +=
            skirout.editor.v1.presentation.PresentationConnection.BundleWrapper(
                RuntimeConnectionBundleScope(state).apply(configure).build(),
            )
    }

    fun build(): List<skirout.editor.v1.presentation.PresentationConnection> = connections.toList()
}

private class RuntimeConnectionScope(
    private val state: PresentationBuildState,
) : ConnectionScope {
    private var source: AnchorSelector? = null
    private var target: AnchorSelector? = null
    private var path: ConnectorPath = ConnectorPath.Straight
    private var style: ConnectorStyle? = null
    private val markers = mutableListOf<ConnectorMarker>()
    private var visibleIf: Expr<Boolean, Handled>? = null

    override fun source(value: AnchorSelector) {
        source = value
    }

    override fun target(value: AnchorSelector) {
        target = value
    }

    override fun path(value: ConnectorPath) {
        path = value
    }

    override fun style(value: ConnectorStyle) {
        style = value
    }

    override fun marker(value: ConnectorMarker) {
        markers += value
    }

    override fun visibleIf(condition: Expr<Boolean, Handled>) {
        visibleIf = condition
    }

    fun build(): skirout.editor.v1.presentation.AnchoredConnection =
        skirout.editor.v1.presentation.AnchoredConnection(
            source = requireNotNull(source) { "Connection source anchor is required." }.wire(),
            target = requireNotNull(target) { "Connection target anchor is required." }.wire(),
            path = path.wire(),
            style = requireNotNull(style) { "Connection style is required." }.wire(),
            markers = markers.map { it.wire(state) },
            visibleIf = visibleIf?.let(::expression),
        )
}

private class RuntimeConnectionBundleScope(
    private val state: PresentationBuildState,
) : ConnectionBundleScope {
    private var source: AnchorSelector? = null
    private var targets: AnchorSelector? = null
    private var path: ConnectorBundlePath = ConnectorBundlePath.Fan
    private var trunkStyle: ConnectorStyle? = null
    private var branchStyle: ConnectorStyle? = null
    private val trunkMarkers = mutableListOf<ConnectorMarker>()
    private val branchMarkers = mutableListOf<ConnectorMarker>()
    private var visibleIf: Expr<Boolean, Handled>? = null

    override fun source(value: AnchorSelector) {
        source = value
    }

    override fun targets(value: AnchorSelector) {
        targets = value
    }

    override fun path(value: ConnectorBundlePath) {
        path = value
    }

    override fun trunkStyle(value: ConnectorStyle) {
        trunkStyle = value
    }

    override fun branchStyle(value: ConnectorStyle) {
        branchStyle = value
    }

    override fun trunkMarker(value: ConnectorMarker) {
        trunkMarkers += value
    }

    override fun branchMarker(value: ConnectorMarker) {
        branchMarkers += value
    }

    override fun visibleIf(condition: Expr<Boolean, Handled>) {
        visibleIf = condition
    }

    fun build(): skirout.editor.v1.presentation.AnchoredConnectionBundle =
        skirout.editor.v1.presentation.AnchoredConnectionBundle(
            source = requireNotNull(source) { "Connection bundle source anchor is required." }.wire(),
            targets = requireNotNull(targets) { "Connection bundle target anchors are required." }.wire(),
            path = path.wire(),
            trunkStyle = requireNotNull(trunkStyle) { "Connection bundle trunk style is required." }.wire(),
            branchStyle = requireNotNull(branchStyle) { "Connection bundle branch style is required." }.wire(),
            trunkMarkers = trunkMarkers.map { it.wire(state) },
            branchMarkers = branchMarkers.map { it.wire(state) },
            visibleIf = visibleIf?.let(::expression),
        )
}

private fun AnchorAlignment.wire(): skirout.editor.v1.presentation.PresentationAnchorAlignment =
    when (this) {
        AnchorAlignment.TopStart -> skirout.editor.v1.presentation.PresentationAnchorAlignment.TOP_START
        AnchorAlignment.TopCenter -> skirout.editor.v1.presentation.PresentationAnchorAlignment.TOP_CENTER
        AnchorAlignment.TopEnd -> skirout.editor.v1.presentation.PresentationAnchorAlignment.TOP_END
        AnchorAlignment.CenterStart -> skirout.editor.v1.presentation.PresentationAnchorAlignment.CENTER_START
        AnchorAlignment.Center -> skirout.editor.v1.presentation.PresentationAnchorAlignment.CENTER
        AnchorAlignment.CenterEnd -> skirout.editor.v1.presentation.PresentationAnchorAlignment.CENTER_END
        AnchorAlignment.BottomStart -> skirout.editor.v1.presentation.PresentationAnchorAlignment.BOTTOM_START
        AnchorAlignment.BottomCenter -> skirout.editor.v1.presentation.PresentationAnchorAlignment.BOTTOM_CENTER
        AnchorAlignment.BottomEnd -> skirout.editor.v1.presentation.PresentationAnchorAlignment.BOTTOM_END
    }

private fun PresentationOffset.wire(): skirout.editor.v1.presentation.PresentationOffset =
    skirout.editor.v1.presentation.PresentationOffset(
        x = expression(x),
        y = expression(y),
    )

private fun AnchorSelector.wire(): skirout.editor.v1.presentation.PresentationAnchorSelector =
    when (this) {
        is AnchorSelector.Local -> {
            skirout.editor.v1.presentation.PresentationAnchorSelector
                .LocalWrapper(id)
        }

        is AnchorSelector.ExportedGroup -> {
            skirout.editor.v1.presentation.PresentationAnchorSelector
                .ExportedGroupWrapper(id)
        }
    }

private fun ConnectorPath.wire(): skirout.editor.v1.presentation.ConnectionPath =
    when (this) {
        ConnectorPath.Straight -> {
            skirout.editor.v1.presentation.ConnectionPath.STRAIGHT
        }

        is ConnectorPath.Orthogonal -> {
            skirout.editor.v1.presentation.ConnectionPath.createOrthogonal(
                bendPosition = expression(bendPosition),
            )
        }

        is ConnectorPath.Curved -> {
            skirout.editor.v1.presentation.ConnectionPath.createCurved(
                sourceControlOffset = sourceControlOffset.wire(),
                targetControlOffset = targetControlOffset.wire(),
            )
        }
    }

private fun ConnectorBundlePath.wire(): skirout.editor.v1.presentation.ConnectionBundlePath =
    when (this) {
        ConnectorBundlePath.Fan -> {
            skirout.editor.v1.presentation.ConnectionBundlePath.FAN
        }

        is ConnectorBundlePath.Orthogonal -> {
            skirout.editor.v1.presentation.ConnectionBundlePath.createOrthogonal(
                axis =
                    when (axis) {
                        ConnectionAxis.Horizontal -> skirout.editor.v1.presentation.ConnectionAxis.HORIZONTAL
                        ConnectionAxis.Vertical -> skirout.editor.v1.presentation.ConnectionAxis.VERTICAL
                    },
                bendPosition = expression(bendPosition),
            )
        }
    }

internal fun ConnectorStyle.wire(): skirout.editor.v1.presentation.ConnectorStyle =
    skirout.editor.v1.presentation.ConnectorStyle(
        stroke =
            skirout.editor.v1.presentation.ConnectorStroke(
                color = expression(color),
                width = expression(width),
            ),
        cornerRadius = expression(cornerRadius),
        startMarker = startMarker?.wire(),
        endMarker = endMarker?.wire(),
    )

private fun ConnectorEndpointMarker.wire(): skirout.editor.v1.presentation.ConnectorEndpointMarker =
    when (this) {
        is ConnectorEndpointMarker.Arrow -> {
            skirout.editor.v1.presentation.ConnectorEndpointMarker.createArrow(
                size = expression(size),
            )
        }

        is ConnectorEndpointMarker.Circle -> {
            skirout.editor.v1.presentation.ConnectorEndpointMarker.createCircle(
                diameter = expression(diameter),
            )
        }
    }

private fun ConnectorMarker.wire(state: PresentationBuildState): skirout.editor.v1.presentation.ConnectionMarker =
    skirout.editor.v1.presentation.ConnectionMarker(
        node = state.presentation(node),
        position = expression(position),
        alignToPath = expression(alignToPath),
        scope =
            when (scope) {
                ConnectionExpressionScope.Layer -> skirout.editor.v1.presentation.ConnectionExpressionScope.LAYER
                ConnectionExpressionScope.Source -> skirout.editor.v1.presentation.ConnectionExpressionScope.SOURCE
                ConnectionExpressionScope.Target -> skirout.editor.v1.presentation.ConnectionExpressionScope.TARGET
            },
    )
