package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.Color
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.presentation.PresentationCollectionDefinition
import skirout.editor.v1.presentation.PresentationCollectionProjection
import skirout.editor.v1.presentation.PresentationCollectionProjectionField
import skirout.editor.v1.presentation.PresentationCollectionProjectionValue
import skirout.editor.v1.presentation.PresentationCollectionRelationDefinition
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationResourceCollection
import kotlin.reflect.KClass
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment

internal fun PresentationLayoutHandler.resourceCollection(args: Array<out Any?>): CollectionSource<*, *> {
    val id = args[0] as String
    val native = args[1] as KClass<*>
    val appearance = args[2] as? PresentationReference

    @Suppress("UNCHECKED_CAST")
    val configure = args[3] as ResourceCollectionSourceScope<com.typewritermc.types.Resource>.() -> Unit
    return resourceCollectionSource(id, state.resourceType(native), appearance, configure)
}

internal fun PresentationLayoutHandler.repeated(args: Array<out Any?>) {
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

internal fun PresentationLayoutHandler.collectionLookup(args: Array<out Any?>) {
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

internal fun PresentationLayoutHandler.collectionGraph(args: Array<out Any?>) {
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

private fun PresentationLayoutHandler.sequence(
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

private fun PresentationLayoutHandler.hierarchySequence(
    item: PresentationNode,
    empty: PresentationNode? = null,
): skirout.editor.v1.presentation.SequencePresentation {
    val neutral = literal(Color(0xff9e9e9eu))

    fun connector(
        cornerRadius: Double,
        marker: ConnectorEndpointMarker?,
    ) = ConnectorStyle(
        color = neutral.asPresentationColor(),
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

internal fun CollectionSource<*, *>.wire(state: PresentationBuildState): PresentationCollectionDefinition =
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
