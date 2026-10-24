package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationAnchorSelector

internal class RuntimeAnchorScope(
    private val state: PresentationBuildState,
) : AnchorScope {
    private val anchors = mutableListOf<skirout.editor.v1.presentation.PresentationAnchorPoint>()

    override fun point(
        id: String,
        configure: AnchorPointScope.() -> Unit,
    ) {
        require(id.isNotBlank()) { "Anchor id must not be blank." }
        require(anchors.none { it.anchorId == id }) { "Anchor ids must be unique within one layout." }
        anchors += RuntimeAnchorPointScope(state, id).apply(configure).build()
    }

    fun build(): List<skirout.editor.v1.presentation.PresentationAnchorPoint> = anchors.toList()
}

private class RuntimeAnchorPointScope(
    private val state: PresentationBuildState,
    private val id: String,
) : AnchorPointScope {
    private val groups = linkedSetOf<String>()
    private var alignment: PresentationAlignment = PresentationAlignment.CENTER
    private var offset: PresentationOffset? = null
    private var visibleIf: Expr<Boolean, Handled>? = null
    private var exportToParent = false

    override fun groups(vararg ids: String) {
        require(ids.all(String::isNotBlank)) { "Anchor group ids must not be blank." }
        groups += ids
    }

    override fun alignment(value: PresentationAlignment) {
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
            alignment = alignment,
            offset = offset?.wire(state),
            visibleIf = visibleIf?.let { state.lower(it, BOOLEAN_SLOT) },
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
    private var source: PresentationAnchorSelector? = null
    private var target: PresentationAnchorSelector? = null
    private var path: ConnectorPath = ConnectorPath.Straight
    private var style: ConnectorStyle? = null
    private val markers = mutableListOf<ConnectorMarker>()
    private var visibleIf: Expr<Boolean, Handled>? = null

    override fun source(value: PresentationAnchorSelector) {
        source = value
    }

    override fun target(value: PresentationAnchorSelector) {
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
            source = requireNotNull(source) { "Connection source anchor is required." },
            target = requireNotNull(target) { "Connection target anchor is required." },
            path = path.wire(state),
            style = requireNotNull(style) { "Connection style is required." }.wire(state),
            markers = markers.map { it.wire(state) },
            visibleIf = visibleIf?.let { state.lower(it, BOOLEAN_SLOT) },
        )
}

private class RuntimeConnectionBundleScope(
    private val state: PresentationBuildState,
) : ConnectionBundleScope {
    private var source: PresentationAnchorSelector? = null
    private var targets: PresentationAnchorSelector? = null
    private var path: ConnectorBundlePath = ConnectorBundlePath.Fan
    private var trunkStyle: ConnectorStyle? = null
    private var branchStyle: ConnectorStyle? = null
    private val trunkMarkers = mutableListOf<ConnectorMarker>()
    private val branchMarkers = mutableListOf<ConnectorMarker>()
    private var visibleIf: Expr<Boolean, Handled>? = null

    override fun source(value: PresentationAnchorSelector) {
        source = value
    }

    override fun targets(value: PresentationAnchorSelector) {
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
            source = requireNotNull(source) { "Connection bundle source anchor is required." },
            targets = requireNotNull(targets) { "Connection bundle target anchors are required." },
            path = path.wire(state),
            trunkStyle = requireNotNull(trunkStyle) { "Connection bundle trunk style is required." }.wire(state),
            branchStyle = requireNotNull(branchStyle) { "Connection bundle branch style is required." }.wire(state),
            trunkMarkers = trunkMarkers.map { it.wire(state) },
            branchMarkers = branchMarkers.map { it.wire(state) },
            visibleIf = visibleIf?.let { state.lower(it, BOOLEAN_SLOT) },
        )
}

private fun PresentationOffset.wire(state: PresentationBuildState): skirout.editor.v1.presentation.PresentationOffset =
    skirout.editor.v1.presentation.PresentationOffset(
        x = state.lower(x, DOUBLE_SLOT),
        y = state.lower(y, DOUBLE_SLOT),
    )

private fun ConnectorPath.wire(state: PresentationBuildState): skirout.editor.v1.presentation.ConnectionPath =
    when (this) {
        ConnectorPath.Straight -> {
            skirout.editor.v1.presentation.ConnectionPath.STRAIGHT
        }

        is ConnectorPath.Orthogonal -> {
            skirout.editor.v1.presentation.ConnectionPath.createOrthogonal(
                bendPosition = state.lower(bendPosition, DOUBLE_SLOT),
            )
        }

        is ConnectorPath.Curved -> {
            skirout.editor.v1.presentation.ConnectionPath.createCurved(
                sourceControlOffset = sourceControlOffset.wire(state),
                targetControlOffset = targetControlOffset.wire(state),
            )
        }
    }

private fun ConnectorBundlePath.wire(state: PresentationBuildState): skirout.editor.v1.presentation.ConnectionBundlePath =
    when (this) {
        ConnectorBundlePath.Fan -> {
            skirout.editor.v1.presentation.ConnectionBundlePath.FAN
        }

        is ConnectorBundlePath.Orthogonal -> {
            skirout.editor.v1.presentation.ConnectionBundlePath.createOrthogonal(
                axis = axis,
                bendPosition = state.lower(bendPosition, DOUBLE_SLOT),
            )
        }
    }

internal fun ConnectorStyle.wire(state: PresentationBuildState): skirout.editor.v1.presentation.ConnectorStyle =
    skirout.editor.v1.presentation.ConnectorStyle(
        stroke =
            skirout.editor.v1.presentation.ConnectorStroke(
                color = color.wire(state),
                width = state.lower(width, DOUBLE_SLOT),
            ),
        cornerRadius = state.lower(cornerRadius, DOUBLE_SLOT),
        startMarker = startMarker?.wire(state),
        endMarker = endMarker?.wire(state),
    )

private fun ConnectorEndpointMarker.wire(state: PresentationBuildState): skirout.editor.v1.presentation.ConnectorEndpointMarker =
    when (this) {
        is ConnectorEndpointMarker.Arrow -> {
            skirout.editor.v1.presentation.ConnectorEndpointMarker.createArrow(
                size = state.lower(size, DOUBLE_SLOT),
            )
        }

        is ConnectorEndpointMarker.Circle -> {
            skirout.editor.v1.presentation.ConnectorEndpointMarker.createCircle(
                diameter = state.lower(diameter, DOUBLE_SLOT),
            )
        }
    }

private fun ConnectorMarker.wire(state: PresentationBuildState): skirout.editor.v1.presentation.ConnectionMarker =
    skirout.editor.v1.presentation.ConnectionMarker(
        node = state.presentation(node),
        position = state.lower(position, DOUBLE_SLOT),
        alignToPath = state.lower(alignToPath, BOOLEAN_SLOT),
        scope = scope,
    )
