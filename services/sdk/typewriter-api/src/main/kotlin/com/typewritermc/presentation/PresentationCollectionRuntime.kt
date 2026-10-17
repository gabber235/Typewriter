package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.PresentationCollectionDefinition
import skirout.editor.v1.presentation.PresentationCollectionProjection
import skirout.editor.v1.presentation.PresentationCollectionProjectionField
import skirout.editor.v1.presentation.PresentationCollectionProjectionValue
import skirout.editor.v1.presentation.PresentationCollectionRelationDefinition
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationResourceCollection
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment

internal fun <V, ItemScope> RuntimePresentationData.renderRepeated(
    source: Expr<List<V>, Handled>,
    items: SequenceScope<ItemScope>.() -> Unit,
) {
    val binding = state.bindingId("repeated.item")
    val itemNodes = mutableListOf<PresentationNode>()
    val itemLayout = state.scope(itemNodes)
    var empty: PresentationNode? = null
    var separator: PresentationNode? = null
    val sequenceLayout = RuntimeSequenceLayoutScope()
    val scope =
        object : SequenceScope<ItemScope>, Layout by itemLayout, SequenceLayoutScope by sequenceLayout {
            override val item =
                com.typewritermc.expression.inputExpression<ItemScope, MayBeMissing>(binding)

            override fun empty(body: Layout.() -> Unit) {
                check(empty == null) { "A repeated presentation may declare empty content once." }
                empty = state.presentation(body)
            }

            override fun separator(body: Layout.() -> Unit) {
                check(separator == null) { "A repeated presentation may declare one separator." }
                separator = state.presentation(body)
            }
        }
    state.withTarget(itemNodes) { scope.items() }
    target +=
        state.node(
            PresentationElement.createRepeated(
                source = expression(source),
                itemBindingId = binding.wire(),
                presentation =
                    skirout.editor.v1.presentation.SequencePresentation(
                        item = state.column(itemNodes),
                        empty = empty,
                        separator = separator,
                        layout = sequenceLayout.build(),
                    ),
            ),
        )
}

internal fun <Row, Key> RuntimePresentationData.renderCollectionLookup(
    source: CollectionSource<Row, Key>,
    key: PresentationInput<Key, *>,
    configure: LookupScope<Row>.() -> Unit,
) {
    state.collection(source)
    var found: PresentationNode? = null
    var missing: PresentationNode? = null
    var loading: PresentationNode? = null
    val scope =
        object : LookupScope<Row> {
            override val row =
                com.typewritermc.expression.inputExpression<Row, MayBeMissing>(source.rowBinding)

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
    scope.configure()
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

internal fun <Row, Key> RuntimePresentationData.renderCollectionGraph(
    source: CollectionSource<Row, Key>,
    configure: GraphScope<Row, Key>.() -> Unit,
) {
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
    var rootSequence: skirout.editor.v1.presentation.SequencePresentation? = null
    var childSequence: skirout.editor.v1.presentation.SequencePresentation? = null
    val rootItem = state.node(PresentationElement.createSlot(slotId = rootSlot))
    val childItem = state.node(PresentationElement.createSlot(slotId = childSlot))
    val scope =
        object : GraphScope<Row, Key> {
            override fun rootSequence(body: GraphRootSequenceScope<Row>.() -> Unit) {
                check(rootSequence == null) { "Collection graph root layout may be declared once." }
                val layout = RuntimeSequenceLayoutScope()
                var empty: PresentationNode? = null
                val sequenceScope =
                    object : GraphRootSequenceScope<Row>, SequenceLayoutScope by layout {
                        override val item =
                            com.typewritermc.expression.inputExpression<Row, MayBeMissing>(source.rowBinding)

                        override fun empty(body: Layout.() -> Unit) {
                            check(empty == null) { "Collection graph empty content may be declared once." }
                            empty = state.presentation(body)
                        }
                    }
                sequenceScope.body()
                rootSequence =
                    skirout.editor.v1.presentation.SequencePresentation(
                        item = rootItem,
                        empty = empty,
                        separator = null,
                        layout = layout.build(),
                    )
            }

            override fun childrenSequence(body: GraphChildrenSequenceScope<Row>.() -> Unit) {
                check(childSequence == null) { "Collection graph child layout may be declared once." }
                val layout = RuntimeSequenceLayoutScope()
                val sequenceScope =
                    object : GraphChildrenSequenceScope<Row>, SequenceLayoutScope by layout {
                        override val parent =
                            com.typewritermc.expression.inputExpression<Row, MayBeMissing>(source.rowBinding)
                        override val item =
                            com.typewritermc.expression.inputExpression<Row, MayBeMissing>(childBinding)
                    }
                sequenceScope.body()
                childSequence =
                    skirout.editor.v1.presentation.SequencePresentation(
                        item = childItem,
                        empty = null,
                        separator = null,
                        layout = layout.build(),
                    )
            }

            override fun root(binding: PresentationInput<Key, *>) {
                check(roots == null) { "Collection graph roots may be declared once." }
                roots =
                    ExpressionNode.createInput(binding = binding.binding.bindingId, path = binding.binding.path)
            }

            override fun roots(binding: PresentationInput<List<Key>, *>) {
                check(roots == null) { "Collection graph roots may be declared once." }
                roots =
                    ExpressionNode.createInput(binding = binding.binding.bindingId, path = binding.binding.path)
            }

            override fun root(value: Expr<Key, MayBeMissing>) {
                check(roots == null) { "Collection graph roots may be declared once." }
                roots = value.toNode()
            }

            override fun roots(value: Expr<List<Key>, MayBeMissing>) {
                check(roots == null) { "Collection graph roots may be declared once." }
                roots = value.toNode()
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

            override fun node(body: GraphNodeScope<Row>.() -> Unit) {
                check(node == null) { "Collection graph node content may be declared once." }
                val nodes = mutableListOf<PresentationNode>()
                val layout = state.scope(nodes)
                val nodeScope =
                    object : GraphNodeScope<Row>, Layout by layout {
                        override val row =
                            com.typewritermc.expression.inputExpression<Row, MayBeMissing>(source.rowBinding)
                        override val children =
                            com.typewritermc.expression.inputExpression<List<Row>, MayBeMissing>(childrenBinding)

                        override fun descendants() {
                            state.currentTarget += state.node(PresentationElement.createSlot(slotId = childSlot))
                        }
                    }
                state.withTarget(nodes) { nodeScope.body() }
                node = state.column(nodes)
            }
        }
    scope.configure()
    target +=
        state.node(
            PresentationElement.createCollectionGraph(
                sourceId = source.id,
                roots = requireNotNull(roots) { "Collection graph roots are required." },
                rootSequence = rootSequence ?: sequence(rootItem),
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
                children = childSequence ?: sequence(childItem),
            ),
        )
}

private fun RuntimePresentationData.sequence(
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
                    clipOverflow = false,
                ),
            ),
    )

private class RuntimeSequenceLayoutScope : SequenceLayoutScope {
    private var layout: skirout.editor.v1.presentation.SequenceLayout? = null

    override fun clippedRow(spacing: Double) {
        require(spacing.isFinite() && spacing >= 0) { "Sequence spacing must be finite and nonnegative." }
        set(
            skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper(
                skirout.editor.v1.presentation.ChildrenLayout.createRow(
                    spacing = spacing,
                    mainAxisAlignment = WireMainAxisAlignment.START,
                    crossAxisAlignment = WireCrossAxisAlignment.CENTER,
                    clipOverflow = true,
                ),
            ),
        )
    }

    override fun column(
        spacing: Double,
        cross: CrossAxisAlignment,
    ) {
        require(spacing.isFinite() && spacing >= 0) { "Sequence spacing must be finite and nonnegative." }
        set(
            skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper(
                skirout.editor.v1.presentation.ChildrenLayout.createColumn(
                    spacing = spacing,
                    mainAxisAlignment = WireMainAxisAlignment.START,
                    crossAxisAlignment = cross.wire(),
                    clipOverflow = false,
                ),
            ),
        )
    }

    override fun hierarchy(
        unaryConnector: ConnectorStyle,
        trunkConnector: ConnectorStyle,
        branchConnector: ConnectorStyle,
        itemSpacing: Double,
        indentation: Double,
        leadingSpacing: Double,
        itemAnchor: ConnectorAnchor,
        flattenSingleItem: Boolean,
        cross: CrossAxisAlignment,
    ) {
        require(listOf(itemSpacing, indentation, leadingSpacing).all { it.isFinite() && it >= 0 }) {
            "Hierarchy spacing must be finite and nonnegative."
        }
        set(
            skirout.editor.v1.presentation.SequenceLayout.createHierarchy(
                unaryConnector = unaryConnector.wire(),
                trunkConnector = trunkConnector.wire(),
                branchConnector = branchConnector.wire(),
                itemSpacing = expression(itemSpacing),
                indentation = expression(indentation),
                leadingSpacing = expression(leadingSpacing),
                itemAnchor =
                    when (itemAnchor) {
                        ConnectorAnchor.Start -> skirout.editor.v1.presentation.ConnectorAnchor.START
                        ConnectorAnchor.Center -> skirout.editor.v1.presentation.ConnectorAnchor.CENTER
                    },
                flattenSingleItem = expression(flattenSingleItem),
                crossAxisAlignment = cross.wire(),
            ),
        )
    }

    private fun set(value: skirout.editor.v1.presentation.SequenceLayout) {
        check(layout == null) { "A sequence layout may be declared once." }
        layout = value
    }

    fun build(): skirout.editor.v1.presentation.SequenceLayout {
        if (layout == null) column()
        return requireNotNull(layout)
    }
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
                    targets = relation.targets,
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
