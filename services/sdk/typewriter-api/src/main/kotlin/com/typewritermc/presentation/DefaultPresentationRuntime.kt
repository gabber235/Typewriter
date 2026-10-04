package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.configuration.generatedExpressionScope
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.AxisChildrenElement
import skirout.editor.v1.presentation.AxisChildrenLayout
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.GridChildrenLayout
import skirout.editor.v1.presentation.PageGraphDirection
import skirout.editor.v1.presentation.PresentationCollectionDefinition
import skirout.editor.v1.presentation.PresentationCollectionProjection
import skirout.editor.v1.presentation.PresentationCollectionProjectionField
import skirout.editor.v1.presentation.PresentationCollectionProjectionValue
import skirout.editor.v1.presentation.PresentationCollectionRelationDefinition
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationResourceCollection
import skirout.editor.v1.presentation.WrapChildrenLayout
import skirout.editor.v1.type_catalog.FieldPathSegment
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import java.math.BigInteger
import java.util.IdentityHashMap
import kotlin.reflect.KClass
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern as WireRelativeFieldPattern
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

class DefaultPresentationRuntime : PresentationRuntime {
    private val presentations = IdentityHashMap<PresentationReference, MutableList<PresentationDescriptor>>()

    override fun register(
        reference: PresentationReference,
        descriptor: PresentationDescriptor,
    ) {
        synchronized(presentations) {
            val registered = presentations[reference].orEmpty()
            val previous = registered.singleOrNull { it.id == descriptor.id }
            require(previous == null || previous == descriptor) {
                "One presentation id cannot describe different providers in one catalog runtime."
            }
            if (previous == null) presentations.getOrPut(reference, ::mutableListOf) += descriptor
        }
    }

    private fun resolve(
        reference: PresentationReference,
        binding: CheckedPresentationTemplate,
    ): com.typewritermc.types.PresentationId? =
        synchronized(presentations) {
            binding.select(presentations[reference].orEmpty())?.id
        }

    override fun build(
        binding: PresentationBuildBinding,
        content: (PresentationBuildScope) -> Unit,
    ): PresentationBuildResult {
        val state = BuildState(binding, ::resolve)
        state.withTarget(state.nodes) { content(state.scope()) }
        return state.result(state.column(state.nodes))
    }
}

private class RuntimeAdaptiveLeadingScope(
    private val state: BuildState,
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

private class RuntimeAnchorScope : AnchorScope {
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

private class RuntimeConnectionsScope(
    private val state: BuildState,
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
    private val state: BuildState,
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
    private val state: BuildState,
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

private class RuntimeHeaderScope(
    private val state: BuildState,
    private val binding: BindingRef,
) : HeaderScope {
    private var title: skirout.editor.v1.presentation.PresentationHeaderTitle? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var initiallyExpanded: Boolean? = null
    private var headerPadding: skirout.editor.v1.presentation.PresentationInsets? = null
    private var contentPadding: skirout.editor.v1.presentation.PresentationInsets? = null
    private val items = mutableListOf<skirout.editor.v1.presentation.HeaderItem>()

    override fun title(text: Expr<String, Handled>) {
        check(title == null) { "Presentation header title may be declared once." }
        title =
            skirout.editor.v1.presentation.PresentationHeaderTitle
                .TextWrapper(expression(text))
    }

    override fun title(body: Layout.() -> Unit) {
        check(title == null) { "Presentation header title may be declared once." }
        title =
            skirout.editor.v1.presentation.PresentationHeaderTitle
                .PresentationWrapper(state.presentation(body))
    }

    override fun description(text: Expr<String, Handled>) {
        description = expression(text)
    }

    override fun expanded(initially: Boolean) {
        initiallyExpanded = initially
    }

    override fun padding(
        header: PresentationInsets,
        content: PresentationInsets,
    ) {
        headerPadding = header.wire()
        contentPadding = content.wire()
    }

    override fun button(
        id: HeaderItemId,
        configure: HeaderButtonScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderButtonScope(id).apply(configure).build()
    }

    override fun toggle(
        id: HeaderItemId,
        configure: HeaderToggleScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderToggleScope(id).apply(configure).build()
    }

    override fun reorderHandle(
        id: HeaderItemId,
        configure: HeaderReorderScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderReorderScope(id).apply(configure).build()
    }

    private fun requireItemId(id: HeaderItemId) {
        require(id.value.isNotBlank()) { "Header item id must not be blank." }
        require(items.none { item -> item.itemName() == id.value }) { "Header item ids must be unique within one node." }
    }

    fun build(): skirout.editor.v1.presentation.PresentationHeader? =
        if (title == null && description == null && initiallyExpanded == null && items.isEmpty() && headerPadding == null &&
            contentPadding == null
        ) {
            null
        } else {
            skirout.editor.v1.presentation.PresentationHeader(
                binding = binding,
                title = title,
                description = description,
                initiallyExpanded = initiallyExpanded,
                items = items,
                headerPadding = headerPadding,
                contentPadding = contentPadding,
            )
        }
}

private abstract class RuntimeHeaderActionScope {
    var tooltip: skirout.editor.v1.expression.ExpressionNode? = null
    var priority: skirout.editor.v1.expression.ExpressionNode? = null
    var visibleIf: skirout.editor.v1.expression.ExpressionNode? = null
    var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    var confirmation: skirout.editor.v1.presentation.HeaderActionConfirmation? = null
    var placement = HeaderActionPlacement.End

    fun setTooltip(value: Expr<String, Handled>) {
        tooltip = expression(value)
    }

    fun setPriority(value: Expr<Int, Handled>) {
        priority = expression(value)
    }

    fun setVisibleIf(value: Expr<Boolean, Handled>) {
        visibleIf = expression(value)
    }

    fun setEnabledIf(value: Expr<Boolean, Handled>) {
        enabledIf = expression(value)
    }

    fun setConfirmation(value: HeaderActionConfirmation) {
        confirmation = value.wire()
    }
}

private class RuntimeHeaderButtonScope(
    private val id: HeaderItemId,
) : RuntimeHeaderActionScope(),
    HeaderButtonScope {
    private var icon: skirout.editor.v1.expression.ExpressionNode? = null
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var action: skirout.editor.v1.action.EditorAction? = null
    private var tone = HeaderActionTone.Neutral

    override fun icon(value: Expr<String, Handled>) {
        icon = expression(value)
    }

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    override fun tooltip(value: Expr<String, Handled>) = setTooltip(value)

    override fun action(value: skirout.editor.v1.action.EditorAction) {
        action = value
    }

    override fun priority(value: Expr<Int, Handled>) = setPriority(value)

    override fun visibleIf(value: Expr<Boolean, Handled>) = setVisibleIf(value)

    override fun enabledIf(value: Expr<Boolean, Handled>) = setEnabledIf(value)

    override fun tone(value: HeaderActionTone) {
        tone = value
    }

    override fun confirmation(value: HeaderActionConfirmation) = setConfirmation(value)

    override fun placement(value: HeaderActionPlacement) {
        placement = value
    }

    fun build(): skirout.editor.v1.presentation.HeaderItem =
        skirout.editor.v1.presentation.HeaderItem.createButton(
            itemId = id.wire(),
            icon = requireNotNull(icon) { "Header button icon is required." },
            label = requireNotNull(label) { "Header button label is required." },
            tooltip = tooltip,
            action = requireNotNull(action) { "Header button action is required." },
            priority = priority,
            visibleIf = visibleIf,
            enabledIf = enabledIf,
            tone = tone.wire(),
            confirmation = confirmation,
            placement = placement.wire(),
        )
}

private class RuntimeHeaderToggleScope(
    private val id: HeaderItemId,
) : RuntimeHeaderActionScope(),
    HeaderToggleScope {
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var checked: skirout.editor.v1.expression.ExpressionNode? = null
    private var action: skirout.editor.v1.action.EditorAction? = null

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    override fun checked(value: Expr<Boolean, Handled>) {
        checked = expression(value)
    }

    override fun action(value: skirout.editor.v1.action.EditorAction) {
        action = value
    }

    override fun tooltip(value: Expr<String, Handled>) = setTooltip(value)

    override fun priority(value: Expr<Int, Handled>) = setPriority(value)

    override fun visibleIf(value: Expr<Boolean, Handled>) = setVisibleIf(value)

    override fun enabledIf(value: Expr<Boolean, Handled>) = setEnabledIf(value)

    override fun confirmation(value: HeaderActionConfirmation) = setConfirmation(value)

    override fun placement(value: HeaderActionPlacement) {
        placement = value
    }

    fun build(): skirout.editor.v1.presentation.HeaderItem =
        skirout.editor.v1.presentation.HeaderItem.createBooleanToggle(
            itemId = id.wire(),
            label = requireNotNull(label) { "Header toggle label is required." },
            checked = requireNotNull(checked) { "Header toggle checked expression is required." },
            action = requireNotNull(action) { "Header toggle action is required." },
            tooltip = tooltip,
            priority = priority,
            visibleIf = visibleIf,
            enabledIf = enabledIf,
            confirmation = confirmation,
            placement = placement.wire(),
        )
}

private class RuntimeHeaderReorderScope(
    private val id: HeaderItemId,
) : HeaderReorderScope {
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var source: BindingRef? = null
    private var tooltip: skirout.editor.v1.expression.ExpressionNode? = null
    private var visibleIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    override fun source(value: PresentationInput<*, *>) {
        source = value.binding
    }

    override fun tooltip(value: Expr<String, Handled>) {
        tooltip = expression(value)
    }

    override fun visibleIf(value: Expr<Boolean, Handled>) {
        visibleIf = expression(value)
    }

    override fun enabledIf(value: Expr<Boolean, Handled>) {
        enabledIf = expression(value)
    }

    fun build(): skirout.editor.v1.presentation.HeaderItem =
        skirout.editor.v1.presentation.HeaderItem.createReorderHandle(
            itemId = id.wire(),
            label = requireNotNull(label) { "Header reorder label is required." },
            source = requireNotNull(source) { "Header reorder source is required." },
            tooltip = tooltip,
            visibleIf = visibleIf,
            enabledIf = enabledIf,
        )
}

private class BuildState(
    private val binding: PresentationBuildBinding,
    private val resolvePresentation: (PresentationReference, CheckedPresentationTemplate) -> com.typewritermc.types.PresentationId?,
) {
    val role: PresentationRole get() = binding.role
    val type get() = binding.type
    val nodes = mutableListOf<PresentationNode>()
    private var nextNode = 0
    private var nextBinding = 0
    private var activeTarget: MutableList<PresentationNode> = nodes
    private val types = linkedSetOf<skirout.editor.v1.type_catalog.TypeUse>()
    private val presentations = linkedSetOf<skirout.editor.v1.type_catalog.PresentationId>()
    private val capabilities = linkedSetOf<skirout.editor.v1.type_catalog.CapabilityId>()
    private val collections = linkedMapOf<String, PresentationCollectionDefinition>()

    val currentTarget: MutableList<PresentationNode> get() = activeTarget

    fun presentationId(
        reference: PresentationReference,
        checked: CheckedPresentationTemplate = type,
    ): com.typewritermc.types.PresentationId? =
        resolvePresentation(reference, checked)?.also { id ->
            presentations +=
                skirout.editor.v1.type_catalog.PresentationId(
                    namespace = id.namespace,
                    name = id.name,
                )
        }

    fun type(use: TypeUse) {
        types += SkirTypeCodec.encode(use).getOrThrow()
    }

    fun capability(id: com.typewritermc.capability.CapabilityId) {
        capabilities +=
            skirout.editor.v1.type_catalog
                .CapabilityId(value = id.value)
    }

    fun collection(source: CollectionSource<*, *>) {
        val definition = source.wire(this)
        val previous = collections[definition.sourceId]
        require(previous == null || previous == definition) {
            "One presentation build cannot declare conflicting collection sources with the same id."
        }
        collections[definition.sourceId] = definition
    }

    fun resourceType(native: KClass<*>): TypeTemplate.Named =
        requireNotNull(binding.resourceTypes[native]) {
            "No authored resource type is registered for ${native.qualifiedName}."
        }

    fun result(layout: PresentationNode): PresentationBuildResult =
        PresentationBuildResult(
            layout = layout,
            dependencies =
                PresentationDependencies(
                    types = types,
                    presentations = presentations,
                    conversions = emptyList(),
                    capabilities = capabilities,
                    collections = collections.values,
                ),
        )

    fun bindingId(purpose: String): ExpressionBindingId = ExpressionBindingId("presentation.$purpose.${nextBinding++}")

    fun <T> withTarget(
        target: MutableList<PresentationNode>,
        operation: () -> T,
    ): T {
        val previous = activeTarget
        activeTarget = target
        return try {
            operation()
        } finally {
            activeTarget = previous
        }
    }

    fun scope(
        target: MutableList<PresentationNode> = nodes,
        axis: AxisNodeList? = null,
        checked: CheckedPresentationTemplate = type,
        base: BindingRef = BindingRef(path = WireValuePath(segments = emptyList()), bindingId = CONFIGURED_VALUE.wire()),
    ): PresentationBuildScope =
        Proxy.newProxyInstance(
            PresentationBuildScope::class.java.classLoader,
            arrayOf(PresentationBuildScope::class.java, AxisLayout::class.java),
            LayoutHandler(this, target, axis, checked, base),
        ) as PresentationBuildScope

    fun node(
        element: PresentationElement?,
        properties: WirePresentationProperties = WirePresentationProperties.partial(),
        nodeId: String = "generated.${nextNode++}",
        header: skirout.editor.v1.presentation.PresentationHeader? = null,
    ): PresentationNode =
        PresentationNode(
            nodeId = nodeId,
            properties = properties,
            element = element,
            header = header,
        )

    fun column(children: List<PresentationNode>): PresentationNode =
        node(
            PresentationElement.ChildrenWrapper(
                ChildrenElement.ColumnWrapper(
                    AxisChildrenElement(
                        children = children.map(AxisChild::FixedWrapper),
                        layout =
                            AxisChildrenLayout(
                                spacing = 0.0,
                                mainAxisAlignment = WireMainAxisAlignment.START,
                                crossAxisAlignment = WireCrossAxisAlignment.START,
                            ),
                    ),
                ),
            ),
        )

    fun axis(
        children: List<AxisChild>,
        row: Boolean,
        spacing: Double,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
    ): PresentationNode {
        val layout =
            AxisChildrenLayout(
                spacing = spacing,
                mainAxisAlignment = main.wire(),
                crossAxisAlignment = cross.wire(),
            )
        val element =
            if (row) {
                ChildrenElement.createRow(children = children, layout = layout)
            } else {
                ChildrenElement.createColumn(children = children, layout = layout)
            }
        return node(PresentationElement.ChildrenWrapper(element))
    }
}

private class AxisNodeList : AbstractMutableList<PresentationNode>() {
    private val nodes = mutableListOf<PresentationNode>()
    val children = mutableListOf<AxisChild>()

    override val size: Int get() = nodes.size

    override fun get(index: Int): PresentationNode = nodes[index]

    override fun add(
        index: Int,
        element: PresentationNode,
    ) {
        nodes.add(index, element)
        children.add(index, AxisChild.FixedWrapper(element))
    }

    override fun removeAt(index: Int): PresentationNode {
        children.removeAt(index)
        return nodes.removeAt(index)
    }

    override fun set(
        index: Int,
        element: PresentationNode,
    ): PresentationNode {
        children[index] = AxisChild.FixedWrapper(element)
        return nodes.set(index, element)
    }

    fun addFlexible(
        node: PresentationNode,
        flex: Int,
        fit: FlexFit,
    ) {
        nodes += node
        children +=
            AxisChild.createFlexible(
                child = node,
                flex = flex,
                fit =
                    when (fit) {
                        FlexFit.Tight -> skirout.editor.v1.presentation.FlexFit.TIGHT
                        FlexFit.Loose -> skirout.editor.v1.presentation.FlexFit.LOOSE
                    },
            )
    }
}

private class LayoutHandler(
    private val state: BuildState,
    private val target: MutableList<PresentationNode>,
    private val axis: AxisNodeList? = null,
    private val checked: CheckedPresentationTemplate,
    private val base: BindingRef,
) : InvocationHandler {
    override fun invoke(
        proxy: Any,
        method: Method,
        arguments: Array<out Any?>?,
    ): Any? {
        val args = arguments.orEmpty()
        return when (method.presentationOperationName()) {
            "getRole" -> {
                state.role
            }

            "value" -> {
                presentedValue(
                    args[0] as KClass<*>,
                    args.getOrNull(1) as? Map<NestedPresentationSlot, NestedPresentationScope> ?: emptyMap(),
                )
            }

            "field" -> {
                presentedField(
                    args[0] as String,
                    args[1] as KClass<*>,
                    args.getOrNull(2) as? Map<NestedPresentationSlot, NestedPresentationScope> ?: emptyMap(),
                )
            }

            "expressions" -> {
                expressions(args.single() as KClass<*>)
            }

            "conditional" -> {
                conditional(args[0] as Expr<Boolean, Handled>, args[1], args[2])
            }

            "resourceCollection" -> {
                resourceCollection(args)
            }

            "repeated" -> {
                repeated(args)
            }

            "scoped" -> {
                scoped(args, typed = false)
            }

            "typedField" -> {
                scoped(args, typed = true)
            }

            "collectionLookup" -> {
                collectionLookup(args)
            }

            "collectionGraph" -> {
                collectionGraph(args)
            }

            "polymorphicMatch" -> {
                polymorphicMatch(args)
            }

            "remainingFields" -> {
                remainingFields(args.single())
            }

            "column" -> {
                axisLayout(false, args)
            }

            "row" -> {
                axisLayout(true, args)
            }

            "wrap" -> {
                wrap(args)
            }

            "grid" -> {
                grid(args)
            }

            "stack" -> {
                stack(args.last())
            }

            "tabs" -> {
                tabs(args)
            }

            "adaptiveLeading" -> {
                adaptiveLeading(args.singleOrNull())
            }

            "anchors" -> {
                anchors(args)
            }

            "connectionLayer" -> {
                connectionLayer(args)
            }

            "node" -> {
                authoredNode(args)
            }

            "section" -> {
                section(args)
            }

            "padding" -> {
                padding(args)
            }

            "container" -> {
                container(args)
            }

            "showIf" -> {
                conditional(args[0] as Expr<Boolean, Handled>, args[1], args[2])
            }

            "tooltip" -> {
                tooltip(args)
            }

            "fixed" -> {
                fixed(args.last())
            }

            "flexible" -> {
                flexible(args)
            }

            "divider" -> {
                target += state.node(PresentationElement.DIVIDER)
            }

            "slot" -> {
                target += state.node(PresentationElement.createSlot(slotId = args.single() as String))
            }

            "spacer" -> {
                target +=
                    state.node(
                        PresentationElement.createSpacer(
                            width = args.getOrNull(0)?.let(::expression),
                            height = args.getOrNull(1)?.let(::expression),
                        ),
                    )
            }

            "text" -> {
                text(args)
            }

            "richText" -> {
                richText(args.singleOrNull())
            }

            "markdown" -> {
                markdown(args)
            }

            "icon" -> {
                icon(args)
            }

            "image" -> {
                target +=
                    state.node(
                        PresentationElement.createImage(
                            source = expression(args[0]),
                            semanticLabel = args.getOrNull(1)?.let(::expression),
                        ),
                    )
            }

            "badge" -> {
                target +=
                    state.node(
                        PresentationElement.createBadge(
                            label = expression(args[0]),
                            tone = args[1] as String,
                        ),
                    )
            }

            "chip" -> {
                target +=
                    state.node(
                        PresentationElement.createChip(
                            label = expression(args[0]),
                            color = args.getOrNull(1)?.let(::expression),
                        ),
                    )
            }

            "progress" -> {
                target +=
                    state.node(
                        PresentationElement.createProgress(
                            value = expression(args[0]),
                            maximum = expression(args[1]),
                            label = args.getOrNull(2)?.let(::expression),
                        ),
                    )
            }

            "status" -> {
                status(args)
            }

            "dateTime" -> {
                dateTime(args)
            }

            "relativeTime" -> {
                relativeTime(args)
            }

            "button" -> {
                target +=
                    state.node(
                        PresentationElement.createButton(
                            label = expression(args[0]),
                            action = args[1] as skirout.editor.v1.action.EditorAction,
                        ),
                    )
            }

            "iconButton" -> {
                target +=
                    state.node(
                        PresentationElement.createIconButton(
                            icon = expression(args[0]),
                            semanticLabel = expression(args[1]),
                            action = args[2] as skirout.editor.v1.action.EditorAction,
                        ),
                    )
            }

            "menu" -> {
                menu(args)
            }

            "commitControls" -> {
                val input = args.single() as PresentationInput<*, *>
                target += state.node(PresentationElement.createCommitControls(binding = input.binding))
            }

            "invoke" -> {
                invokePresentation(args)
            }

            "toString" -> {
                "PresentationBuildScope"
            }

            "hashCode" -> {
                System.identityHashCode(proxy)
            }

            "equals" -> {
                proxy === args.singleOrNull()
            }

            else -> {
                throw UnsupportedOperationException("Presentation operation ${method.name} is not implemented.")
            }
        }
    }

    private fun presentedField(
        name: String,
        scope: KClass<*>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    ): PresentedField<*, *> {
        val fieldType = checked.field(name)
        @Suppress("UNCHECKED_CAST")
        return RuntimePresentedField<Any?, Any>(
            state,
            name,
            scope as KClass<Any>,
            nested,
            base.field(name),
            fieldType,
        )
    }

    private fun presentedValue(
        scope: KClass<*>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    ): PresentedField<*, *> {
        @Suppress("UNCHECKED_CAST")
        return RuntimePresentedField<Any?, Any>(state, "value", scope as KClass<Any>, nested, base, checked)
    }

    private fun expressions(scope: KClass<*>): Any =
        generatedExpressionScope(
            scope,
            Expr<Any?, com.typewritermc.expression.MayBeMissing>(
                ExpressionNode.Read(CONFIGURED_VALUE, ValuePath()),
            ),
        )

    private fun resourceCollection(args: Array<out Any?>): CollectionSource<*, *> {
        val id = args[0] as String
        val native = args[1] as KClass<*>
        val appearance = args[2] as? PresentationReference

        @Suppress("UNCHECKED_CAST")
        val configure = args[3] as ResourceCollectionSourceScope<com.typewritermc.types.Resource>.() -> Unit
        return resourceCollectionSource(id, state.resourceType(native), appearance, configure)
    }

    private fun text(args: Array<out Any?>) {
        val style = args.getOrNull(1) as? TextStyle ?: TextStyle()
        target +=
            state.node(
                PresentationElement.createText(
                    value = expression(args[0]),
                    color = style.tone?.let(::expression),
                    fontSize = null,
                    fontWeight = style.weight?.let(::expression),
                    fontItalic = null,
                    fontOpticalSize = null,
                    fontSlant = null,
                    fontWidth = null,
                    textAlignment = null,
                    lineHeight = null,
                    letterSpacing = null,
                    decoration = null,
                    semanticLabel = null,
                    paragraph =
                        skirout.editor.v1.presentation.TextParagraph
                            .partial(),
                ),
            )
    }

    private fun markdown(args: Array<out Any?>) {
        target +=
            state.node(
                PresentationElement.createMarkdown(
                    value = expression(args[0]),
                    color = args.getOrNull(1)?.let(::expression),
                    fontSize = null,
                    fontWeight = null,
                    fontItalic = null,
                    fontOpticalSize = null,
                    fontSlant = null,
                    fontWidth = null,
                    textAlignment = null,
                    lineHeight = null,
                    letterSpacing = null,
                    decoration = null,
                    semanticLabel = null,
                    paragraph =
                        skirout.editor.v1.presentation.TextParagraph
                            .partial(),
                ),
            )
    }

    private fun icon(args: Array<out Any?>) {
        val options = args.getOrNull(1) as? IconOptions ?: IconOptions()
        target +=
            state.node(
                PresentationElement.createIcon(
                    name = expression(args[0]),
                    semanticLabel = null,
                    color = options.color?.let(::expression),
                    size = options.size?.let(::expression),
                ),
            )
    }

    private fun dateTime(args: Array<out Any?>) {
        target +=
            state.node(
                PresentationElement.createDateTime(
                    value = expression(args[0]),
                    format = expression(args[1]),
                    timeZone =
                        when (args[2] as DateTimeZone) {
                            DateTimeZone.Local -> skirout.editor.v1.presentation.DateTimeZone.LOCAL
                            DateTimeZone.Utc -> skirout.editor.v1.presentation.DateTimeZone.UTC
                        },
                ),
            )
    }

    private fun tabs(args: Array<out Any?>) {
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

    private fun richText(configuration: Any?) {
        val runs = mutableListOf<skirout.editor.v1.presentation.TextRun>()
        var overallStyle: TextStyleOverride? = null
        var overallParagraph = TextParagraph()
        val scope =
            object : RichTextScope {
                override fun run(
                    text: Expr<String, Handled>,
                    style: TextStyleOverride?,
                ) {
                    runs +=
                        skirout.editor.v1.presentation.TextRun(
                            text = expression(text),
                            style = style?.wire(),
                        )
                }

                override fun style(style: TextStyleOverride) {
                    overallStyle = style
                }

                override fun paragraph(paragraph: TextParagraph) {
                    overallParagraph = paragraph
                }
            }
        invokeBlock(configuration, scope)
        target +=
            state.node(
                PresentationElement.createRichText(
                    runs = runs,
                    style = overallStyle?.wire(),
                    paragraph = overallParagraph.wire(),
                ),
            )
    }

    private fun status(args: Array<out Any?>) {
        val cases =
            (args[1] as List<*>).map { candidate ->
                candidate as StatusCase<*>
                skirout.editor.v1.presentation.StatusCase(
                    match =
                        com.typewritermc.types.skir.SkirDataValueCodec
                            .encode(portableLiteral(candidate.value))
                            .getOrThrow(),
                    appearance = candidate.appearance.wire(),
                )
            }
        target +=
            state.node(
                PresentationElement.createStatus(
                    value = expression(args[0]),
                    cases = cases,
                    fallback = (args.getOrNull(2) as? StatusAppearance)?.wire(),
                ),
            )
    }

    private fun menu(args: Array<out Any?>) {
        val items = mutableListOf<skirout.editor.v1.presentation.MenuItem>()
        val scope =
            object : MenuScope {
                override fun item(
                    id: String,
                    label: Expr<String, Handled>,
                    action: skirout.editor.v1.action.EditorAction,
                ) {
                    items +=
                        skirout.editor.v1.presentation.MenuItem(
                            itemId = id,
                            label = expression(label),
                            action = action,
                        )
                }
            }
        invokeBlock(args[1], scope)
        target +=
            state.node(
                PresentationElement.createMenu(
                    label = args[0]?.let(::expression),
                    items = items,
                ),
            )
    }

    private fun repeated(args: Array<out Any?>) {
        val binding = state.bindingId("repeated.item")
        val itemNodes = mutableListOf<PresentationNode>()
        val itemLayout = state.scope(itemNodes)
        var empty: PresentationNode? = null
        var separator: PresentationNode? = null
        val scope =
            object : SequenceScope<Any?>, Layout by itemLayout {
                override val item =
                    Expr<Any?, com.typewritermc.expression.MayBeMissing>(
                        ExpressionNode.Read(binding, ValuePath()),
                    )

                override fun empty(body: Layout.() -> Unit) {
                    check(empty == null) { "A repeated presentation may declare empty content once." }
                    empty = state.presentation(body)
                }

                override fun separator(body: Layout.() -> Unit) {
                    check(separator == null) { "A repeated presentation may declare one separator." }
                    separator = state.presentation(body)
                }
            }
        state.withTarget(itemNodes) { invokeBlock(args[1], scope) }
        target +=
            state.node(
                PresentationElement.createRepeated(
                    source = expression(args[0]),
                    itemBindingId = binding.wire(),
                    presentation = sequence(state.column(itemNodes), empty, separator),
                ),
            )
    }

    @Suppress("UNCHECKED_CAST")
    private fun scoped(
        args: Array<out Any?>,
        typed: Boolean,
    ) {
        val input = args[0] as PresentationInput<*, *>
        val children = mutableListOf<PresentationNode>()
        val scopeBinding = if (typed) null else state.bindingId("scoped.value")
        val receiver =
            if (typed) {
                val factory = input.rebind as? (BindingRef, MutableList<PresentationNode>) -> Any?
                factory?.invoke(input.binding, children) ?: input.scope
            } else {
                val rebound =
                    BindingRef(
                        path = WireValuePath(segments = emptyList()),
                        bindingId = requireNotNull(scopeBinding).wire(),
                    )
                val factory = input.rebind as? (BindingRef, MutableList<PresentationNode>) -> Any?
                factory?.invoke(rebound, children) ?: input.scope
            }
        state.withTarget(children) { invokeBlock(args[1], requireNotNull(receiver)) }
        val child = state.column(children)
        target +=
            if (typed) {
                val expected = requireNotNull(input.expected) { "A typed presentation input must carry its expected type." }
                state.node(
                    PresentationElement.createTypedField(
                        binding = input.binding,
                        expectedType = SkirTypeCodec.encode(expected).getOrThrow(),
                        presentation = child,
                    ),
                )
            } else {
                state.node(
                    PresentationElement.createScopedBinding(
                        binding = input.binding,
                        scopeBindingId = requireNotNull(scopeBinding).wire(),
                        child = child,
                    ),
                )
            }
    }

    private fun collectionLookup(args: Array<out Any?>) {
        val source = args[0] as CollectionSource<*, *>
        state.collection(source)
        val key = args[1] as PresentationInput<*, *>
        var found: PresentationNode? = null
        var missing: PresentationNode? = null
        var loading: PresentationNode? = null
        val scope =
            object : LookupScope<Any?> {
                override val row =
                    Expr<Any?, com.typewritermc.expression.MayBeMissing>(
                        ExpressionNode.Read(source.rowBinding, ValuePath()),
                    )

                override fun found(body: Layout.() -> Unit) {
                    check(found == null) { "Collection lookup found content may be declared once." }
                    found = state.presentation(body)
                }

                override fun missing(body: Layout.() -> Unit) {
                    check(missing == null) { "Collection lookup missing content may be declared once." }
                    missing = state.presentation(body)
                }

                override fun loading(body: Layout.() -> Unit) {
                    check(loading == null) { "Collection lookup loading content may be declared once." }
                    loading = state.presentation(body)
                }
            }
        invokeBlock(args[2], scope)
        target +=
            state.node(
                PresentationElement.createCollectionLookup(
                    sourceId = source.id,
                    key = key.binding,
                    found = requireNotNull(found) { "Collection lookup found content is required." },
                    missing = requireNotNull(missing) { "Collection lookup missing content is required." },
                    loading = loading,
                ),
            )
    }

    private fun collectionGraph(args: Array<out Any?>) {
        val source = args[0] as CollectionSource<*, *>
        state.collection(source)
        val childrenBinding = state.bindingId("graph.children")
        val childBinding = state.bindingId("graph.child")
        val rootSlot = "graph.root.${childrenBinding.value}"
        val childSlot = "graph.child.${childBinding.value}"
        var roots: ExpressionNode? = null
        var relation: String? = null
        var graphDirection = CollectionDirection.Forward
        var graphMaximumDepth: Int? = null
        var node: PresentationNode? = null
        val scope =
            object : GraphScope<Any?, Any?> {
                override fun root(binding: PresentationInput<Any?, *>) {
                    check(roots == null) { "Collection graph roots may be declared once." }
                    roots =
                        ExpressionNode.Read(
                            ExpressionBindingId(binding.binding.bindingId.value),
                            SkirAuthoringValueCodec.decode(binding.binding.path).getOrThrow(),
                        )
                }

                override fun roots(binding: PresentationInput<List<Any?>, *>) {
                    check(roots == null) { "Collection graph roots may be declared once." }
                    roots =
                        ExpressionNode.Read(
                            ExpressionBindingId(binding.binding.bindingId.value),
                            SkirAuthoringValueCodec.decode(binding.binding.path).getOrThrow(),
                        )
                }

                override fun root(value: Expr<Any?, Handled>) {
                    check(roots == null) { "Collection graph roots may be declared once." }
                    roots = value.node
                }

                override fun roots(value: Expr<List<Any?>, Handled>) {
                    check(roots == null) { "Collection graph roots may be declared once." }
                    roots = value.node
                }

                override fun relation(
                    id: String,
                    direction: CollectionDirection,
                    maximumDepth: Int?,
                ) {
                    require(id.isNotBlank()) { "Collection graph relation ids must not be blank." }
                    require(maximumDepth == null || maximumDepth > 0) { "Collection graph maximum depth must be positive." }
                    check(relation == null) { "Collection graph relation may be declared once." }
                    relation = id
                    graphDirection = direction
                    graphMaximumDepth = maximumDepth
                }

                override fun node(body: GraphNodeScope<Any?>.() -> Unit) {
                    check(node == null) { "Collection graph node content may be declared once." }
                    val nodes = mutableListOf<PresentationNode>()
                    val layout = state.scope(nodes)
                    val nodeScope =
                        object : GraphNodeScope<Any?>, Layout by layout {
                            override val row =
                                Expr<Any?, com.typewritermc.expression.MayBeMissing>(
                                    ExpressionNode.Read(source.rowBinding, ValuePath()),
                                )
                            override val children =
                                Expr<List<Any?>, com.typewritermc.expression.MayBeMissing>(
                                    ExpressionNode.Read(childrenBinding, ValuePath()),
                                )

                            override fun descendants() {
                                layout.slot(childSlot)
                            }
                        }
                    state.withTarget(nodes) { invokeBlock(body, nodeScope) }
                    node = state.column(nodes)
                }
            }
        invokeBlock(args[1], scope)
        val rootSequence =
            hierarchySequence(
                item = state.node(PresentationElement.createSlot(slotId = rootSlot)),
                empty = state.presentation { text(literal("No linked items")) },
            )
        val children = hierarchySequence(state.node(PresentationElement.createSlot(slotId = childSlot)))
        target +=
            state.node(
                PresentationElement.createCollectionGraph(
                    sourceId = source.id,
                    roots = SkirTypeCodec.encode(requireNotNull(roots) { "Collection graph roots are required." }).getOrThrow(),
                    rootSequence = rootSequence,
                    relationId = requireNotNull(relation) { "Collection graph relation is required." },
                    direction =
                        when (graphDirection) {
                            CollectionDirection.Forward -> skirout.editor.v1.presentation.CollectionGraphDirection.FORWARD
                            CollectionDirection.Reverse -> skirout.editor.v1.presentation.CollectionGraphDirection.REVERSE
                        },
                    maximumDepth = graphMaximumDepth,
                    node = requireNotNull(node) { "Collection graph node content is required." },
                    childrenBindingId = childrenBinding.wire(),
                    childBindingId = childBinding.wire(),
                    children = children,
                ),
            )
    }

    private fun polymorphicMatch(args: Array<out Any?>) {
        val input = args[0] as PresentationInput<*, *>
        val binding = state.bindingId("match.value")
        val cases = mutableListOf<skirout.editor.v1.presentation.PolymorphicMatchCase>()
        var fallback: PresentationNode? = null
        val scope =
            object : MatchScope<Any?> {
                override fun <Subtype : Any?> case(
                    type: AppliedPresentation<Subtype>,
                    body: MatchCaseScope<Subtype>.() -> Unit,
                ) {
                    state.type(type.type)
                    require(cases.none { candidate -> candidate.concreteType == SkirTypeCodec.encode(type.type).getOrThrow() }) {
                        "A polymorphic match may declare one case per concrete type."
                    }
                    val nodes = mutableListOf<PresentationNode>()
                    val layout = state.scope(nodes)
                    val caseScope =
                        object : MatchCaseScope<Subtype>, Layout by layout {
                            override val value =
                                Expr<Subtype, com.typewritermc.expression.MayBeMissing>(
                                    ExpressionNode.Read(binding, ValuePath()),
                                )
                        }
                    state.withTarget(nodes) { caseScope.body() }
                    cases +=
                        skirout.editor.v1.presentation.PolymorphicMatchCase(
                            concreteType = SkirTypeCodec.encode(type.type).getOrThrow(),
                            child = state.column(nodes),
                        )
                }

                override fun fallback(body: Layout.() -> Unit) {
                    check(fallback == null) { "A polymorphic match may declare fallback content once." }
                    fallback = state.presentation(body)
                }
            }
        invokeBlock(args[1], scope)
        require(cases.isNotEmpty()) { "A polymorphic match requires at least one concrete case." }
        target +=
            state.node(
                PresentationElement.createPolymorphicMatch(
                    binding = input.binding,
                    scopeBindingId = binding.wire(),
                    cases = cases,
                    fallback = fallback,
                ),
            )
    }

    private fun sequence(
        item: PresentationNode,
        empty: PresentationNode? = null,
        separator: PresentationNode? = null,
    ): skirout.editor.v1.presentation.SequencePresentation =
        skirout.editor.v1.presentation.SequencePresentation(
            item = item,
            empty = empty,
            separator = separator,
            layout =
                skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper(
                    skirout.editor.v1.presentation.ChildrenLayout.createColumn(
                        spacing = 0.0,
                        mainAxisAlignment = WireMainAxisAlignment.START,
                        crossAxisAlignment = WireCrossAxisAlignment.START,
                    ),
                ),
        )

    private fun hierarchySequence(
        item: PresentationNode,
        empty: PresentationNode? = null,
    ): skirout.editor.v1.presentation.SequencePresentation {
        val neutral = literal(Color(0xff9e9e9eu))

        fun connector(
            cornerRadius: Double,
            marker: ConnectorEndpointMarker?,
        ) = ConnectorStyle(
            color = neutral,
            width = literal(2.0),
            cornerRadius = literal(cornerRadius),
            startMarker = marker,
        ).wire()

        return skirout.editor.v1.presentation.SequencePresentation(
            item = item,
            empty = empty,
            separator = null,
            layout =
                skirout.editor.v1.presentation.SequenceLayout.createHierarchy(
                    unaryConnector =
                        connector(
                            cornerRadius = 0.0,
                            marker = ConnectorEndpointMarker.Arrow(literal(8.0)),
                        ),
                    trunkConnector =
                        connector(
                            cornerRadius = 8.0,
                            marker = ConnectorEndpointMarker.Arrow(literal(10.0)),
                        ),
                    branchConnector =
                        connector(
                            cornerRadius = 8.0,
                            marker = ConnectorEndpointMarker.Circle(literal(6.0)),
                        ),
                    itemSpacing = expression(24.0),
                    indentation = expression(16.0),
                    leadingSpacing = expression(16.0),
                    itemAnchor = skirout.editor.v1.presentation.ConnectorAnchor.CENTER,
                    flattenSingleItem = expression(true),
                    crossAxisAlignment = WireCrossAxisAlignment.STRETCH,
                ),
        )
    }

    private fun invokePresentation(args: Array<out Any?>) {
        val reference = args[0] as PresentationReference
        val id =
            requireNotNull(state.presentationId(reference, checked)) {
                "The invoked presentation reference was not registered by its generated provider."
            }
        val arguments = mutableListOf<skirout.editor.v1.presentation.PresentationArgument>()
        val scope =
            object : PresentationArguments {
                override fun <Value> bind(
                    parameter: PresentationParameter<Value>,
                    value: PresentationInput<out Value, *>,
                ) {
                    require(arguments.none { it.input.value == parameter.binding.value }) {
                        "A presentation parameter may be bound once per invocation."
                    }
                    arguments +=
                        skirout.editor.v1.presentation.PresentationArgument(
                            input = parameter.binding.wire(),
                            binding = value.binding,
                        )
                }
            }
        invokeBlock(args[1], scope)
        target +=
            state.node(
                PresentationElement.createInvocation(
                    presentationId =
                        skirout.editor.v1.type_catalog
                            .PresentationId(namespace = id.namespace, name = id.name),
                    arguments = arguments,
                ),
            )
    }

    private fun relativeTime(args: Array<out Any?>) {
        target +=
            state.node(
                PresentationElement.createRelativeTime(
                    value = expression(args[0]),
                    style =
                        when (args[1] as RelativeTimeStyle) {
                            RelativeTimeStyle.Compact -> skirout.editor.v1.presentation.RelativeTimeStyle.COMPACT
                            RelativeTimeStyle.Full -> skirout.editor.v1.presentation.RelativeTimeStyle.NATURAL
                        },
                    timeZone =
                        when (args[2] as DateTimeZone) {
                            DateTimeZone.Local -> skirout.editor.v1.presentation.DateTimeZone.LOCAL
                            DateTimeZone.Utc -> skirout.editor.v1.presentation.DateTimeZone.UTC
                        },
                ),
            )
    }

    private fun conditional(
        condition: Expr<Boolean, Handled>,
        whenFalse: Any?,
        body: Any?,
    ) {
        val whenTrueNodes = mutableListOf<PresentationNode>()
        state.withTarget(whenTrueNodes) { invokeBlock(body, state.scope(whenTrueNodes)) }
        val whenFalseNode =
            if (whenFalse == null) {
                null
            } else {
                val whenFalseNodes = mutableListOf<PresentationNode>()
                state.withTarget(whenFalseNodes) { invokeBlock(whenFalse, state.scope(whenFalseNodes)) }
                state.column(whenFalseNodes)
            }
        target +=
            state.node(
                PresentationElement.createConditional(
                    condition = SkirTypeCodec.encode(condition.node).getOrThrow(),
                    whenTrue = state.column(whenTrueNodes),
                    whenFalse = whenFalseNode,
                ),
            )
    }

    private fun remainingFields(configuration: Any?) {
        val excluded = mutableListOf<String>()
        val scope =
            object : RemainingFields {
                override fun exclude(field: PresentedField<*, *>) {
                    excluded += (field as RuntimePresentedField<*, *>).name
                }
            }
        invokeBlock(configuration, scope)
        val patterns =
            excluded.map { name ->
                WireRelativeFieldPattern(
                    segments =
                        listOf(
                            FieldPatternSegment.FieldWrapper(
                                NamedFieldPatternSegment(name = name),
                            ),
                        ),
                )
            }
        target += state.node(PresentationElement.createRemainingFields(excluded = patterns))
    }

    private fun child(configuration: Any?): PresentationNode {
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { invokeBlock(configuration, state.scope(children)) }
        return state.column(children)
    }

    private fun axisLayout(
        row: Boolean,
        args: Array<out Any?>,
    ) {
        val children = AxisNodeList()
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

    private fun wrap(args: Array<out Any?>) {
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

    private fun grid(args: Array<out Any?>) {
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

    private fun stack(configuration: Any?) {
        val children = mutableListOf<PresentationNode>()
        state.withTarget(children) { invokeBlock(configuration, state.scope(children)) }
        target += state.node(PresentationElement.ChildrenWrapper(ChildrenElement.createStack(children = children)))
    }

    private fun section(args: Array<out Any?>) {
        val border = args[0] as? PresentationBorder
        target +=
            state.node(
                PresentationElement.createSection(
                    child = child(args.last()),
                    border = border?.wire(),
                ),
            )
    }

    private fun padding(args: Array<out Any?>) {
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

    private fun container(args: Array<out Any?>) {
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

    private fun tooltip(args: Array<out Any?>) {
        target +=
            state.node(
                PresentationElement.createTooltip(
                    message = expression(args[0]),
                    child = child(args[1]),
                ),
            )
    }

    private fun adaptiveLeading(configuration: Any?) {
        val scope = RuntimeAdaptiveLeadingScope(state)
        invokeBlock(configuration, scope)
        target += state.node(PresentationElement.AdaptiveLeadingWrapper(scope.build()))
    }

    private fun anchors(args: Array<out Any?>) {
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

    private fun connectionLayer(args: Array<out Any?>) {
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

    private fun authoredNode(args: Array<out Any?>) {
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

    private fun fixed(configuration: Any?) {
        val axis = requireNotNull(axis) { "Fixed children are only available inside row and column layouts." }
        axis += child(configuration)
    }

    private fun flexible(args: Array<out Any?>) {
        val axis = requireNotNull(axis) { "Flexible children are only available inside row and column layouts." }
        axis.addFlexible(child(args.last()), args[0] as Int, args[1] as FlexFit)
    }
}

private class RuntimePresentedField<V, S : Any>(
    private val state: BuildState,
    val name: String,
    private val scope: KClass<S>,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val binding: BindingRef,
    private val checked: CheckedPresentationTemplate,
) : PresentedField<V, S> {
    override val input: PresentationInput<V, S>
        get() {
            val createScope: (BindingRef, MutableList<PresentationNode>) -> S = { rebound, children ->
                proxy(
                    scope,
                    ControlHandler(
                        state = state,
                        target = children,
                        field = name,
                        fieldBinding = rebound,
                        checked = checked,
                        nested = nested,
                        selectedPresentation = null,
                    ),
                )
            }
            return PresentationInput(
                binding = binding,
                scope = createScope(binding, state.currentTarget),
                expected = checked.type,
                rebind = createScope,
            )
        }

    override fun invoke(
        using: PresentationReference?,
        configure: S.() -> Unit,
    ) {
        val presentationId =
            using?.let { state.presentationId(it, checked) }?.let { id ->
                skirout.editor.v1.type_catalog
                    .PresentationId(namespace = id.namespace, name = id.name)
            }
        require(using == null || presentationId != null) {
            "The selected presentation reference was not registered by its generated provider."
        }
        val handler = ControlHandler(state, state.currentTarget, name, binding, checked, nested, presentationId)
        val control = proxy(scope, handler)
        control.configure()
        if (!handler.emitted) handler.defaultPresentation()
    }
}

private class ControlHandler(
    private val state: BuildState,
    private val target: MutableList<PresentationNode>,
    private val field: String,
    private val fieldBinding: BindingRef,
    private val checked: CheckedPresentationTemplate,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val selectedPresentation: skirout.editor.v1.type_catalog.PresentationId?,
) : InvocationHandler {
    var emitted = false
        private set
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var semanticLabel: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var prefix: PresentationNode? = null
    private var readOnly = false

    override fun invoke(
        proxy: Any,
        method: Method,
        arguments: Array<out Any?>?,
    ): Any? {
        val args = arguments.orEmpty()
        return when (method.presentationOperationName()) {
            "label" -> {
                label = expression(args.single())
            }

            "description" -> {
                description = expression(args.single())
            }

            "semanticLabel" -> {
                semanticLabel = expression(args.single())
            }

            "enabledIf" -> {
                enabledIf = expression(args.single())
            }

            "readOnly" -> {
                readOnly = args.single() as Boolean
            }

            "textInput" -> {
                val multiline = args.getOrNull(0) as? Boolean
                val placeholder = args.getOrNull(1)?.let(::expression)
                val formats =
                    (args.getOrNull(2) as? List<*>).orEmpty().map { format ->
                        when (format) {
                            TextInputFormat.Trim -> {
                                skirout.editor.v1.presentation.TextInputFormat.createReplace(
                                    pattern = "^\\s+|\\s+$",
                                    replacement = "",
                                )
                            }

                            is TextInputFormat.Pattern -> {
                                skirout.editor.v1.presentation.TextInputFormat
                                    .AllowWrapper(format.regex)
                            }

                            else -> {
                                throw IllegalArgumentException("Unknown text input formatter $format.")
                            }
                        }
                    }
                emit(
                    PresentationElement.createTextInput(
                        control = boundControl(),
                        multiline = multiline,
                        placeholder = placeholder,
                        inputFormatters = formats,
                    ),
                )
            }

            "selectInput" -> {
                val options =
                    (args[0] as List<*>).map { option ->
                        option as SelectOption<*>
                        skirout.editor.v1.presentation.SelectOption(
                            optionId = option.id,
                            label = expression(option.label),
                            value = expression(option.value),
                        )
                    }
                emit(
                    PresentationElement.createSelectInput(
                        control = boundControl(),
                        options = options,
                        allowCustomValue = args[1] as Boolean,
                    ),
                )
            }

            "sliderInput" -> {
                emit(
                    PresentationElement.createSliderInput(
                        control = boundControl(),
                        minimum = expression(args[0]),
                        maximum = expression(args[1]),
                        divisions = args.getOrNull(2)?.let(::expression),
                    ),
                )
            }

            "searchInput" -> {
                val search = RuntimeSearchInputScope<Any?, Any?>(state)
                invokeBlock(args.single(), search)
                emit(search.element(boundControl()))
            }

            "namedInput" -> {
                emit(
                    PresentationElement.createNamedInput(
                        control = boundControl(),
                        payloadPresentation = nestedPresentation(args.singleOrNull(), NestedPresentationSlot.Payload),
                    ),
                )
            }

            "recordInput" -> {
                emit(
                    PresentationElement.createRecordInput(
                        control = boundControl(),
                        fieldPresentation = nestedPresentation(args.singleOrNull(), NestedPresentationSlot.Fields),
                    ),
                )
            }

            "graphPage" -> {
                val direction =
                    when (args.single() as GraphDirection) {
                        GraphDirection.LEFT_TO_RIGHT -> PageGraphDirection.LEFT_TO_RIGHT
                        GraphDirection.RIGHT_TO_LEFT -> PageGraphDirection.RIGHT_TO_LEFT
                        GraphDirection.TOP_TO_BOTTOM -> PageGraphDirection.TOP_TO_BOTTOM
                        GraphDirection.BOTTOM_TO_TOP -> PageGraphDirection.BOTTOM_TO_TOP
                    }
                emit(PresentationElement.createPageGraph(control = boundControl(), direction = direction))
            }

            "timelinePage" -> {
                emit(PresentationElement.createPageTimeline(control = boundControl()))
            }

            "listInput" -> {
                emit(
                    PresentationElement.createListInput(
                        control = boundControl(),
                        itemPresentation = nestedPresentation(args[3], NestedPresentationSlot.Items),
                        allowAdd = args[0] as Boolean,
                        allowRemove = args[1] as Boolean,
                        allowReorder = args[2] as Boolean,
                        itemBindingId = WireExpressionBindingId(value = "list_item"),
                        indexBindingId = WireExpressionBindingId(value = "list_index"),
                    ),
                )
            }

            "collectionInput" -> {
                emit(
                    PresentationElement.createSetInput(
                        control = boundControl(),
                        itemPresentation = nestedPresentation(args[2], NestedPresentationSlot.Items),
                        allowAdd = args[0] as Boolean,
                        allowRemove = args[1] as Boolean,
                        itemBindingId = WireExpressionBindingId(value = "set_item"),
                    ),
                )
            }

            "mapInput" -> {
                emit(
                    PresentationElement.createMapInput(
                        control = boundControl(),
                        keyPresentation = nestedPresentation(args[2], NestedPresentationSlot.Keys),
                        valuePresentation = nestedPresentation(args[3], NestedPresentationSlot.Values),
                        allowAdd = args[0] as Boolean,
                        allowRemove = args[1] as Boolean,
                        keyBindingId = WireExpressionBindingId(value = "map_key"),
                        valueBindingId = WireExpressionBindingId(value = "map_value"),
                    ),
                )
            }

            "nullableInput" -> {
                emit(
                    PresentationElement.createNullableInput(
                        control = boundControl(),
                        valuePresentation = nestedPresentation(args.singleOrNull(), NestedPresentationSlot.Values),
                    ),
                )
            }

            "polymorphicInput" -> {
                polymorphicInput(args.singleOrNull())
            }

            "linkInput" -> {
                linkInput(args)
            }

            "numericInput" -> {
                emit(PresentationElement.NumericInputWrapper(boundControl()))
            }

            "toggleInput" -> {
                emit(PresentationElement.ToggleInputWrapper(boundControl()))
            }

            "durationInput" -> {
                emit(PresentationElement.DurationInputWrapper(boundControl()))
            }

            "bytesInput" -> {
                emit(PresentationElement.BytesInputWrapper(boundControl()))
            }

            "enumInput" -> {
                emit(PresentationElement.EnumInputWrapper(boundControl()))
            }

            "colorInput" -> {
                val includeAlpha = args.getOrNull(0) as? Boolean ?: false
                emit(
                    PresentationElement.createColorInput(
                        control = boundControl(),
                        includeAlpha = includeAlpha,
                    ),
                )
            }

            "dateTimeInput" -> {
                emit(
                    PresentationElement.createDateTimeInput(
                        control = boundControl(),
                        includeDate = args.getOrNull(0) as? Boolean,
                        includeTime = args.getOrNull(1) as? Boolean,
                    ),
                )
            }

            "icon" -> {
                prefix =
                    state.node(
                        PresentationElement.createIcon(
                            name = expression(args.single()),
                            semanticLabel = null,
                            color = null,
                            size = null,
                        ),
                    )
            }

            "prefix" -> {
                val nodes = mutableListOf<PresentationNode>()
                state.withTarget(nodes) { invokeBlock(args.single(), state.scope(nodes)) }
                prefix = state.column(nodes)
            }

            "toString" -> {
                "ControlScope($field)"
            }

            "hashCode" -> {
                System.identityHashCode(proxy)
            }

            "equals" -> {
                proxy === args.singleOrNull()
            }

            else -> {
                throw UnsupportedOperationException("Control operation ${method.name} is not implemented.")
            }
        }
    }

    fun defaultPresentation() {
        emit(
            PresentationElement.createDefaultPresentation(
                binding = binding(),
                presentationId = selectedPresentation,
            ),
        )
    }

    private fun nestedPresentation(
        block: Any?,
        slot: NestedPresentationSlot,
    ): PresentationNode? {
        if (block == null) return null
        val descriptor = nested[slot] ?: return null
        val children = mutableListOf<PresentationNode>()
        val child = checked.nested(slot)
        val childBinding = fieldBinding.nested(slot, checked, child)
        val childType = child.type
        val build = state.scope(children, checked = childType, base = childBinding)
        var childControl: ControlHandler? = null
        val receiver =
            descriptor.create?.invoke(build)
                ?: if (Layout::class.java.isAssignableFrom(descriptor.control.java)) {
                    build
                } else {
                    val handler =
                        ControlHandler(
                            state,
                            children,
                            "$field.$slot",
                            childBinding,
                            childType,
                            descriptor.nested,
                            null,
                        )
                    childControl = handler
                    proxy(descriptor.control, handler)
                }
        state.withTarget(children) { invokeBlock(block, receiver) }
        childControl?.takeUnless(ControlHandler::emitted)?.defaultPresentation()
        return children.takeIf(List<PresentationNode>::isNotEmpty)?.let(state::column)
    }

    private fun polymorphicInput(configuration: Any?) {
        val forms = mutableListOf<skirout.editor.v1.presentation.ConcreteTypePresentation>()
        val scope =
            object : ConcreteForms<Any?> {
                override fun <Subtype> form(
                    type: AppliedPresentation<Subtype>,
                    label: Expr<String, Handled>?,
                ) {
                    state.type(type.type)
                    val id =
                        requireNotNull(state.presentationId(type.reference, state.type.rebind(type.type.template()))) {
                            "A concrete form presentation must be registered before use."
                        }
                    forms +=
                        skirout.editor.v1.presentation.ConcreteTypePresentation(
                            concreteType = SkirTypeCodec.encode(type.type).getOrThrow(),
                            label = expression(label ?: type.type.definition.toString()),
                            presentation =
                                state.node(
                                    PresentationElement.createInvocation(
                                        presentationId =
                                            skirout.editor.v1.type_catalog.PresentationId(
                                                namespace = id.namespace,
                                                name = id.name,
                                            ),
                                        arguments = emptyList(),
                                    ),
                                ),
                        )
                }
            }
        invokeBlock(configuration, scope)
        emit(PresentationElement.createPolymorphicInput(control = boundControl(), concreteTypes = forms))
    }

    private fun linkInput(args: Array<out Any?>) {
        val collection = args.size == 4
        val allowReorder = if (collection) args[0] as Boolean else false
        val source = args[if (collection) 1 else 0] as? CollectionSource<*, *>
        val policy =
            when (val value = args[if (collection) 2 else 1]) {
                is LinkCandidatePolicyId -> value.value
                is String -> value
                null -> null
                else -> error("A link candidate policy must be represented by its string value.")
            }
        val rejection = args[if (collection) 3 else 2] as LinkRejectionDisplay
        source?.let(state::collection)
        emit(
            PresentationElement.createLinkInput(
                control = boundControl(),
                allowReorder = allowReorder,
                candidatePolicy =
                    policy?.let {
                        skirout.editor.v1.presentation
                            .LinkCandidatePolicyId(value = it)
                    },
                rejectionDisplay =
                    when (rejection) {
                        LinkRejectionDisplay.Hidden -> skirout.editor.v1.presentation.LinkRejectionDisplay.HIDDEN
                        LinkRejectionDisplay.DisabledWithReason -> skirout.editor.v1.presentation.LinkRejectionDisplay.DISABLED
                    },
                sourceId = source?.id,
            ),
        )
    }

    private fun boundControl(): BoundControl =
        BoundControl(
            binding = binding(),
            label = label,
            description = description,
            prefix = prefix,
            semanticLabel = semanticLabel,
        )

    private fun binding(): BindingRef = fieldBinding

    private fun emit(element: PresentationElement) {
        require(selectedPresentation == null || element is PresentationElement.DefaultPresentationWrapper) {
            "A named presentation reference cannot be combined with an explicit field control."
        }
        check(!emitted) { "A field presentation may emit one control." }
        target +=
            state.node(
                element,
                WirePresentationProperties(enabledIf = enabledIf, readOnly = readOnly),
            )
        emitted = true
    }
}

private fun Method.presentationOperationName(): String = name.substringBefore('-')

private fun BindingRef.field(name: String): BindingRef =
    BindingRef(
        path =
            WireValuePath(
                segments =
                    path.segments +
                        WirePathSegment.FieldWrapper(
                            FieldPathSegment(name = name),
                        ),
            ),
        bindingId = bindingId,
    )

private fun BindingRef.nested(
    slot: NestedPresentationSlot,
    checked: CheckedPresentationTemplate,
    nested: CheckedPresentationNested,
): BindingRef =
    when (slot) {
        NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
            this
        }

        NestedPresentationSlot.Items -> {
            val bindingId =
                when (requireNotNull(nested.collectionKind)) {
                    CollectionKind.List -> "list_item"
                    CollectionKind.Set -> "set_item"
                }
            BindingRef(
                path = WireValuePath(segments = emptyList()),
                bindingId = ExpressionBindingId(bindingId).wire(),
            )
        }

        NestedPresentationSlot.Keys -> {
            BindingRef(
                path = WireValuePath(segments = emptyList()),
                bindingId = ExpressionBindingId("map_key").wire(),
            )
        }

        NestedPresentationSlot.Values -> {
            if (checked.type is TypeTemplate.Nullable) {
                this
            } else {
                BindingRef(
                    path = WireValuePath(segments = emptyList()),
                    bindingId = ExpressionBindingId("map_value").wire(),
                )
            }
        }
    }

private class RuntimeSearchInputScope<Value, Row>(
    private val state: BuildState,
) : SearchInputScope<Value, Row> {
    override val query = Expr<String, Handled>(ExpressionNode.Read(SEARCH_QUERY, ValuePath()))
    override val sources: SearchSources = SearchSources
    private val selectors = mutableListOf<skirout.editor.v1.presentation.SearchSelectorDefinition>()
    private var result: skirout.editor.v1.presentation.SearchResultMapping? = null
    private var summary: PresentationNode? = null
    private var initialQuery: skirout.editor.v1.expression.ExpressionNode? = null
    private var placeholder: skirout.editor.v1.expression.ExpressionNode? = null
    private var customValue: skirout.editor.v1.expression.ExpressionNode? = null
    private var maximumExtent = expression(400.0)
    private var selectionMode = SearchSelectionMode.Single
    private var provider: DefaultSearchProviderSpec<Row>? = null

    override fun selectors(configure: SearchSelectorsScope.() -> Unit) {
        val scope =
            object : SearchSelectorsScope {
                override fun selector(
                    id: String,
                    key: String,
                    values: SearchSelectorValues,
                    caseSensitive: Boolean,
                    multiplicity: SearchSelectorMultiplicity,
                    color: Long?,
                ): Expr<Any?, Handled> {
                    require(id.isNotBlank()) { "Search selector id must not be blank." }
                    require(key.isNotBlank()) { "Search selector key must not be blank." }
                    val binding = ExpressionBindingId("search_selector.$id")
                    selectors +=
                        skirout.editor.v1.presentation.SearchSelectorDefinition(
                            selectorId = id,
                            key = key,
                            valueBindingId = binding.wire(),
                            values = values.wire(),
                            caseSensitive = caseSensitive,
                            multiplicity = multiplicity.wire(),
                            color = color,
                        )
                    return Expr(ExpressionNode.Read(binding, ValuePath()))
                }
            }
        scope.configure()
    }

    override fun result(configure: SearchResultScope<Value, Row>.() -> Unit) {
        val builder = RuntimeSearchResultScope<Value, Row>(state)
        builder.configure()
        result = builder.build()
    }

    override fun summary(body: Layout.() -> Unit) {
        summary = state.presentation(body)
    }

    override fun initialQuery(value: Expr<String, Handled>) {
        initialQuery = expression(value)
    }

    override fun placeholder(value: Expr<String, Handled>) {
        placeholder = expression(value)
    }

    override fun customValue(value: Expr<Value, Handled>) {
        customValue = expression(value)
    }

    override fun maximumExtent(value: Expr<Double, Handled>) {
        maximumExtent = expression(value)
    }

    override fun selectionMode(value: SearchSelectionMode) {
        selectionMode = value
    }

    override fun provider(source: SearchProviderSpec<Row>) {
        provider = source.runtime()
    }

    fun element(control: BoundControl): PresentationElement {
        val mapping = requireNotNull(result) { "Search input must declare its result mapping." }
        val source = requireNotNull(provider) { "Search input must declare a provider." }
        return PresentationElement.createSearchInput(
            control = control,
            selectionMode = selectionMode.wire(),
            queryBindingId = SEARCH_QUERY.wire(),
            summaryBindingId = ExpressionBindingId("search_summary").wire(),
            maximumExtent = maximumExtent,
            provider = source.wire(state, mapping, selectors),
            summary = summary,
            placeholder = placeholder,
            customValue = customValue,
            initialQuery = initialQuery,
        )
    }
}

private class RuntimeSearchResultScope<Value, Row>(
    private val state: BuildState,
) : SearchResultScope<Value, Row> {
    override val row = Expr<Row, Handled>(ExpressionNode.Read(SEARCH_RESULT_ROW, ValuePath()))
    private var key: skirout.editor.v1.expression.ExpressionNode? = null
    private var selectedValue: skirout.editor.v1.expression.ExpressionNode? = null
    private var presentation: PresentationNode? = null
    private var label: skirout.editor.v1.expression.ExpressionNode? = null

    override fun key(value: Expr<*, Handled>) {
        key = expression(value)
    }

    override fun selectedValue(value: Expr<Value, Handled>) {
        selectedValue = expression(value)
    }

    override fun presentation(body: Layout.() -> Unit) {
        presentation = state.presentation(body)
    }

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    fun build(): skirout.editor.v1.presentation.SearchResultMapping =
        skirout.editor.v1.presentation.SearchResultMapping(
            bindingId = SEARCH_RESULT_ROW.wire(),
            key = requireNotNull(key) { "Search result mapping must declare a key." },
            selectedValue = requireNotNull(selectedValue) { "Search result mapping must declare a selected value." },
            presentation = requireNotNull(presentation) { "Search result mapping must declare a presentation." },
            label = label,
        )
}

private fun BuildState.presentation(body: Layout.() -> Unit): PresentationNode {
    val children = mutableListOf<PresentationNode>()
    withTarget(children) { scope(children).body() }
    return column(children)
}

private fun DefaultSearchProviderSpec<*>.wire(
    state: BuildState,
    result: skirout.editor.v1.presentation.SearchResultMapping,
    selectors: List<skirout.editor.v1.presentation.SearchSelectorDefinition>,
): skirout.editor.v1.presentation.SearchProvider {
    val source = description.wire(state, result, selectors)
    return decorations.fold(source) { child, decoration -> decoration.wire(child) }
}

private fun SearchProviderDescription<*>.wire(
    state: BuildState,
    result: skirout.editor.v1.presentation.SearchResultMapping,
    selectors: List<skirout.editor.v1.presentation.SearchSelectorDefinition>,
): skirout.editor.v1.presentation.SearchProvider =
    when (this) {
        is SearchProviderDescription.Static<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createStaticValues(
                values = SkirTypeCodec.encode(values).getOrThrow(),
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Collection<*> -> {
            state.collection(source)
            skirout.editor.v1.presentation.SearchProvider.createCollection(
                sourceId = source.id,
                result = result,
                where = predicate?.let { expression(Expr<Any?, Handled>(it)) },
                selectors = selectors,
            )
        }

        is SearchProviderDescription.HttpJson<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createHttpJson(
                uri = expression(Expr<String, Handled>(uri)),
                parameters =
                    parameters.map { parameter ->
                        skirout.editor.v1.presentation.HttpQueryParameter(
                            name = parameter.name,
                            value = expression(Expr<String, Handled>(parameter.value)),
                            omitIfEmpty = parameter.omitIfEmpty,
                        )
                    },
                resultPath = resultPath,
                resultType = SkirTypeCodec.encode(resultType).getOrThrow(),
                result = result,
                contextBindings =
                    contexts.map { context ->
                        skirout.editor.v1.presentation.HttpJsonContextBinding(
                            bindingId = context.binding.wire(),
                            path = context.path,
                            valueType = SkirTypeCodec.encode(context.type).getOrThrow(),
                        )
                    },
                selectors = selectors,
                timeoutMilliseconds = timeout.inWholeMilliseconds,
            )
        }

        is SearchProviderDescription.RealmCallback<*> -> {
            state.capability(capability)
            skirout.editor.v1.presentation.SearchProvider.createRealmCallback(
                capabilityId =
                    skirout.editor.v1.type_catalog
                        .CapabilityId(value = capability.value),
                payload = expression(Expr<Any?, Handled>(payload)),
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Merge<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createMerge(
                children = children.map { it.wire(state, result, selectors) },
            )
        }
    }

private fun CollectionSource<*, *>.wire(state: BuildState): PresentationCollectionDefinition =
    PresentationCollectionDefinition(
        sourceId = id,
        rowType = SkirTypeCodec.encode(rowType).getOrThrow(),
        rowBindingId = rowBinding.wire(),
        key = expression(key),
        selectability = expression(selectability),
        relations =
            relations.map { relation ->
                PresentationCollectionRelationDefinition(
                    relationId = relation.id,
                    targets = SkirTypeCodec.encode(relation.targets).getOrThrow(),
                )
            },
        projection =
            (rows as? CollectionRows.Projected)?.let { projected ->
                val root =
                    SkirTypeCodec.encode(projected.projection.root).getOrThrow()
                        as skirout.editor.v1.type_catalog.TypeTemplate.NamedWrapper
                PresentationCollectionProjection(
                    root = root.value,
                    resourceBindingId = projected.resourceBinding.wire(),
                    fields =
                        projected.projection.fields.map { field ->
                            PresentationCollectionProjectionField(
                                target = SkirAuthoringValueCodec.encode(field.target).getOrThrow(),
                                source =
                                    when (val source = field.source) {
                                        is CollectionProjectionValueSpec.Content -> {
                                            PresentationCollectionProjectionValue.ContentWrapper(
                                                SkirAuthoringValueCodec.encode(source.path).getOrThrow(),
                                            )
                                        }

                                        is CollectionProjectionValueSpec.Literal -> {
                                            PresentationCollectionProjectionValue.LiteralWrapper(
                                                SkirDataValueCodec.encode(source.value).getOrThrow(),
                                            )
                                        }
                                    },
                            )
                        },
                )
            },
        resources =
            (rows as? CollectionRows.Resources)?.let { resources ->
                val encodedRoot =
                    SkirTypeCodec.encode(rowType).getOrThrow()
                        as skirout.editor.v1.type_catalog.TypeTemplate.NamedWrapper
                val appearance =
                    resources.appearance?.let { reference ->
                        state.presentationId(reference, state.type.rebind(rowType))
                    }
                PresentationResourceCollection(
                    root = encodedRoot.value.definition,
                    resourceBindingId = resources.resourceBinding.wire(),
                    appearance =
                        appearance?.let { id ->
                            skirout.editor.v1.type_catalog
                                .PresentationId(namespace = id.namespace, name = id.name)
                        },
                )
            },
    )

private fun SearchDecoration.wire(child: skirout.editor.v1.presentation.SearchProvider): skirout.editor.v1.presentation.SearchProvider =
    when (this) {
        is SearchDecoration.Gate -> {
            skirout.editor.v1.presentation.SearchProvider.createGate(
                condition = expression(Expr<Boolean, Handled>(condition)),
                guidance = guidance?.let { expression(Expr<String, Handled>(it)) },
                child = child,
            )
        }

        is SearchDecoration.Debounce -> {
            skirout.editor.v1.presentation.SearchProvider.createDebounce(
                durationMilliseconds = duration.inWholeMilliseconds,
                child = child,
            )
        }

        is SearchDecoration.Cache -> {
            skirout.editor.v1.presentation.SearchProvider.createCache(
                capacity = capacity,
                retainStaleResults = retainStaleResults,
                child = child,
            )
        }

        is SearchDecoration.Limit -> {
            skirout.editor.v1.presentation.SearchProvider.createLimit(
                maximum = expression(Expr<Int, Handled>(maximum)),
                child = child,
            )
        }

        SearchDecoration.Distinct -> {
            skirout.editor.v1.presentation.SearchProvider
                .createDistinct(child = child)
        }

        is SearchDecoration.History -> {
            skirout.editor.v1.presentation.SearchProvider.createHistory(
                historyKey = key,
                label = expression(Expr<String, Handled>(label)),
                capacity = capacity,
                child = child,
            )
        }

        is SearchDecoration.Section -> {
            skirout.editor.v1.presentation.SearchProvider.createSection(
                sectionId = id,
                label = expression(Expr<String, Handled>(label)),
                child = child,
            )
        }

        is SearchDecoration.Rank -> {
            skirout.editor.v1.presentation.SearchProvider.createRank(
                fields =
                    fields.map { field ->
                        skirout.editor.v1.presentation.SearchRankingField(
                            expression = expression(Expr<Any?, Handled>(field.expression)),
                            weight = field.weight,
                        )
                    },
                child = child,
            )
        }
    }

private fun ExpressionBindingId.wire(): WireExpressionBindingId = WireExpressionBindingId(value = value)

private fun SearchSelectorValues.wire(): skirout.editor.v1.presentation.SearchSelectorValues =
    when (this) {
        SearchSelectorValues.FreeText -> {
            skirout.editor.v1.presentation.SearchSelectorValues.FREE_TEXT
        }

        is SearchSelectorValues.Enumeration -> {
            skirout.editor.v1.presentation.SearchSelectorValues
                .createEnumeration(values = values)
        }
    }

private fun SearchSelectorMultiplicity.wire(): skirout.editor.v1.presentation.SearchSelectorMultiplicity =
    when (this) {
        SearchSelectorMultiplicity.Single -> skirout.editor.v1.presentation.SearchSelectorMultiplicity.SINGLE
        SearchSelectorMultiplicity.Multiple -> skirout.editor.v1.presentation.SearchSelectorMultiplicity.MULTIPLE
    }

private fun SearchSelectionMode.wire(): skirout.editor.v1.presentation.SearchSelectionMode =
    when (this) {
        SearchSelectionMode.Single -> skirout.editor.v1.presentation.SearchSelectionMode.SINGLE
        SearchSelectionMode.Multiple -> skirout.editor.v1.presentation.SearchSelectionMode.MULTIPLE
    }

private fun expression(value: Any?): skirout.editor.v1.expression.ExpressionNode =
    when (value) {
        is String -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.StringValue(value))).getOrThrow()
        }

        is Boolean -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Boolean(value))).getOrThrow()
        }

        is Byte -> {
            integerExpression(value.toLong())
        }

        is Short -> {
            integerExpression(value.toLong())
        }

        is Int -> {
            integerExpression(value.toLong())
        }

        is Long -> {
            integerExpression(value)
        }

        is UByte -> {
            integerExpression(value.toLong())
        }

        is UShort -> {
            integerExpression(value.toLong())
        }

        is UInt -> {
            integerExpression(value.toLong())
        }

        is ULong -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Integer(BigInteger(value.toString())))).getOrThrow()
        }

        is Float -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Float(value.toDouble()))).getOrThrow()
        }

        is Double -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Float(value))).getOrThrow()
        }

        is Expr<*, *> -> {
            SkirTypeCodec.encode(value.node).getOrThrow()
        }

        else -> {
            throw IllegalArgumentException("Presentation expressions must be authored expressions or text literals.")
        }
    }

private fun integerExpression(value: Long): skirout.editor.v1.expression.ExpressionNode =
    SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Integer(BigInteger.valueOf(value)))).getOrThrow()

private fun portableLiteral(value: Any?): DataValue =
    when (value) {
        null -> DataValue.Null
        is DataValue -> value
        is String -> DataValue.StringValue(value)
        is Boolean -> DataValue.Boolean(value)
        is Byte -> DataValue.Integer(value.toLong().toBigInteger())
        is Short -> DataValue.Integer(value.toLong().toBigInteger())
        is Int -> DataValue.Integer(value.toBigInteger())
        is Long -> DataValue.Integer(value.toBigInteger())
        is UByte -> DataValue.Integer(value.toLong().toBigInteger())
        is UShort -> DataValue.Integer(value.toLong().toBigInteger())
        is UInt -> DataValue.Integer(value.toLong().toBigInteger())
        is ULong -> DataValue.Integer(value.toString().toBigInteger())
        is Float -> DataValue.Float(value.toDouble())
        is Double -> DataValue.Float(value)
        else -> throw IllegalArgumentException("A status case value must have a portable literal representation.")
    }

private fun TextStyleOverride.wire(): skirout.editor.v1.presentation.TextStyleOverride =
    skirout.editor.v1.presentation.TextStyleOverride(
        color = tone?.let(::expression),
        fontWeight = weight?.let(::expression),
        fontItalic = null,
        decoration = null,
    )

private fun TextParagraph.wire(): skirout.editor.v1.presentation.TextParagraph =
    skirout.editor.v1.presentation.TextParagraph
        .partial(maxLines = maximumLines)

private fun StatusAppearance.wire(): skirout.editor.v1.presentation.StatusAppearance =
    skirout.editor.v1.presentation.StatusAppearance(
        tone = tone.wireStatusTone(),
        label = expression(label),
    )

private fun String.wireStatusTone(): skirout.editor.v1.presentation.StatusTone =
    when (lowercase()) {
        "neutral" -> skirout.editor.v1.presentation.StatusTone.NEUTRAL
        "unknown" -> skirout.editor.v1.presentation.StatusTone.UNKNOWN_STATUS
        "information", "info" -> skirout.editor.v1.presentation.StatusTone.INFORMATION
        "success" -> skirout.editor.v1.presentation.StatusTone.SUCCESS
        "warning" -> skirout.editor.v1.presentation.StatusTone.WARNING
        "danger", "error" -> skirout.editor.v1.presentation.StatusTone.DANGER
        "active" -> skirout.editor.v1.presentation.StatusTone.ACTIVE
        "inactive" -> skirout.editor.v1.presentation.StatusTone.INACTIVE
        "online" -> skirout.editor.v1.presentation.StatusTone.ONLINE
        "offline" -> skirout.editor.v1.presentation.StatusTone.OFFLINE
        "pending" -> skirout.editor.v1.presentation.StatusTone.PENDING
        "in_progress" -> skirout.editor.v1.presentation.StatusTone.IN_PROGRESS
        "paused" -> skirout.editor.v1.presentation.StatusTone.PAUSED
        else -> throw IllegalArgumentException("Unknown status tone $this.")
    }

private fun MainAxisAlignment.wire(): WireMainAxisAlignment =
    when (this) {
        MainAxisAlignment.Start -> WireMainAxisAlignment.START
        MainAxisAlignment.Center -> WireMainAxisAlignment.CENTER
        MainAxisAlignment.End -> WireMainAxisAlignment.END
        MainAxisAlignment.SpaceBetween -> WireMainAxisAlignment.SPACE_BETWEEN
        MainAxisAlignment.SpaceAround -> WireMainAxisAlignment.SPACE_AROUND
        MainAxisAlignment.SpaceEvenly -> WireMainAxisAlignment.SPACE_EVENLY
    }

private fun CrossAxisAlignment.wire(): WireCrossAxisAlignment =
    when (this) {
        CrossAxisAlignment.Start -> WireCrossAxisAlignment.START
        CrossAxisAlignment.Center -> WireCrossAxisAlignment.CENTER
        CrossAxisAlignment.End -> WireCrossAxisAlignment.END
        CrossAxisAlignment.Stretch -> WireCrossAxisAlignment.STRETCH
    }

private fun PresentationBorder.wire(): skirout.editor.v1.presentation.PresentationBorder =
    skirout.editor.v1.presentation.PresentationBorder.createAll(
        color = expression(color),
        width = width,
    )

private fun PresentationInsets.wire(): skirout.editor.v1.presentation.PresentationInsets =
    skirout.editor.v1.presentation.PresentationInsets.createOnly(
        top = top,
        left = start,
        right = end,
        bottom = bottom,
    )

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

private fun ConnectorStyle.wire(): skirout.editor.v1.presentation.ConnectorStyle =
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

private fun ConnectorMarker.wire(state: BuildState): skirout.editor.v1.presentation.ConnectionMarker =
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

private fun HeaderItemId.wire(): skirout.editor.v1.presentation.HeaderItemId =
    skirout.editor.v1.presentation
        .HeaderItemId(namespace = "generated", name = value)

private fun HeaderActionTone.wire(): skirout.editor.v1.presentation.HeaderActionTone =
    when (this) {
        HeaderActionTone.Neutral -> skirout.editor.v1.presentation.HeaderActionTone.NEUTRAL
        HeaderActionTone.Destructive -> skirout.editor.v1.presentation.HeaderActionTone.DESTRUCTIVE
    }

private fun HeaderActionPlacement.wire(): skirout.editor.v1.presentation.HeaderActionPlacement =
    when (this) {
        HeaderActionPlacement.BeforeTitle -> skirout.editor.v1.presentation.HeaderActionPlacement.BEFORE_TITLE
        HeaderActionPlacement.AfterTitle -> skirout.editor.v1.presentation.HeaderActionPlacement.AFTER_TITLE
        HeaderActionPlacement.End -> skirout.editor.v1.presentation.HeaderActionPlacement.END
    }

private fun HeaderActionConfirmation.wire(): skirout.editor.v1.presentation.HeaderActionConfirmation =
    skirout.editor.v1.presentation.HeaderActionConfirmation(
        title = expression(title),
        message = expression(message),
        confirmationLabel = expression(confirmationLabel),
    )

private fun skirout.editor.v1.presentation.HeaderItem.itemName(): String =
    when (this) {
        is skirout.editor.v1.presentation.HeaderItem.ButtonWrapper -> value.itemId.name
        is skirout.editor.v1.presentation.HeaderItem.BooleanToggleWrapper -> value.itemId.name
        is skirout.editor.v1.presentation.HeaderItem.ReorderHandleWrapper -> value.itemId.name
        else -> ""
    }

@Suppress("UNCHECKED_CAST")
private fun <T : Any> proxy(
    type: KClass<T>,
    handler: InvocationHandler,
): T = Proxy.newProxyInstance(type.java.classLoader, arrayOf(type.java), handler) as T

@Suppress("UNCHECKED_CAST")
private fun invokeBlock(
    block: Any?,
    receiver: Any,
) {
    (block as? Function1<Any, Unit>)?.invoke(receiver)
}

private val CONFIGURED_VALUE = ExpressionBindingId("configured_value")
