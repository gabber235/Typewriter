package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.literal
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.requirePortable
import com.typewritermc.types.template
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.BindingDeclaration
import skirout.editor.v1.presentation.CollectionGraphDirection
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PresentationCollectionDefinition
import skirout.editor.v1.presentation.PresentationCollectionProjection
import skirout.editor.v1.presentation.PresentationCollectionProjectionField
import skirout.editor.v1.presentation.PresentationCollectionProjectionValue
import skirout.editor.v1.presentation.PresentationCollectionRelationDefinition
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.TypeTemplate

internal fun <V, ItemScope> RuntimePresentationData.renderRepeated(
    source: Expr<List<V>, Handled>,
    items: SequenceScope<ItemScope>.() -> Unit,
) {
    val (body, sourceType) = state.lowerInferred(source, "repeated source")
    val itemType = requireNotNull(state.itemType(sourceType)) { "A repeated source must be a list." }
    state.introduce("repeated.item", itemType) { item ->
        val itemNodes = mutableListOf<PresentationNode>()
        val itemLayout = state.scope(itemNodes)
        var empty: PresentationNode? = null
        var separator: PresentationNode? = null
        val sequenceLayout = RuntimeSequenceLayoutScope(state)
        val scope =
            object : SequenceScope<ItemScope>, Layout by itemLayout, SequenceLayoutScope by sequenceLayout {
                override val item =
                    com.typewritermc.expression.inputExpression<ItemScope, MayBeMissing>(item.id)

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
                    source = body,
                    itemBinding = item,
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
    state.declareRow(source) { scope.configure() }
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
    val keyType = state.keyType(source)
    state.declareRow(source) {
        state.introduce("graph.children", listSlot(source.rowType)) { childrenBinding ->
            state.introduce("graph.child", source.rowType) { childBinding ->
                renderCollectionGraph(source, keyType, childrenBinding, childBinding, configure)
            }
        }
    }
}

private fun <Row, Key> RuntimePresentationData.renderCollectionGraph(
    source: CollectionSource<Row, Key>,
    keyType: TypeTemplate,
    childrenBinding: BindingDeclaration,
    childBinding: BindingDeclaration,
    configure: GraphScope<Row, Key>.() -> Unit,
) {
    val rootSlot = "graph.root.${childrenBinding.id.value}"
    val childSlot = "graph.child.${childBinding.id.value}"
    var roots: ExpressionNode? = null
    var relation: String? = null
    var graphDirection: CollectionGraphDirection = CollectionGraphDirection.FORWARD
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
                val layout = RuntimeSequenceLayoutScope(state)
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
                val layout = RuntimeSequenceLayoutScope(state)
                val sequenceScope =
                    object : GraphChildrenSequenceScope<Row>, SequenceLayoutScope by layout {
                        override val parent =
                            com.typewritermc.expression.inputExpression<Row, MayBeMissing>(source.rowBinding)
                        override val item =
                            com.typewritermc.expression.inputExpression<Row, MayBeMissing>(childBinding.id)
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

            override fun root(binding: PresentationInput<Key, *>) = root(binding.read())

            override fun roots(binding: PresentationInput<List<Key>, *>) = roots(binding.read())

            override fun root(value: Expr<Key, MayBeMissing>) {
                check(roots == null) { "Collection graph roots may be declared once." }
                roots = state.lower(value, keyType, mayBeMissing = true)
            }

            override fun roots(value: Expr<List<Key>, MayBeMissing>) {
                check(roots == null) { "Collection graph roots may be declared once." }
                roots = state.lower(value, listSlot(keyType), mayBeMissing = true)
            }

            override fun relation(
                id: String,
                direction: CollectionGraphDirection,
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
                            com.typewritermc.expression.inputExpression<List<Row>, MayBeMissing>(childrenBinding.id)

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
                direction = graphDirection,
                maximumDepth = graphMaximumDepth,
                node = requireNotNull(node) { "Collection graph node content is required." },
                childrenBinding = childrenBinding,
                childBinding = childBinding,
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
                    mainAxisAlignment = MainAxisAlignment.START,
                    crossAxisAlignment = CrossAxisAlignment.START,
                    clipOverflow = false,
                ),
            ),
    )

private class RuntimeSequenceLayoutScope(
    private val state: PresentationBuildState,
) : SequenceLayoutScope {
    private var layout: skirout.editor.v1.presentation.SequenceLayout? = null

    override fun clippedRow(spacing: Spacing) {
        set(
            skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper(
                skirout.editor.v1.presentation.ChildrenLayout.createRow(
                    spacing = spacing.pixels,
                    mainAxisAlignment = MainAxisAlignment.START,
                    crossAxisAlignment = CrossAxisAlignment.CENTER,
                    clipOverflow = true,
                ),
            ),
        )
    }

    override fun column(
        spacing: Spacing,
        cross: CrossAxisAlignment,
    ) {
        set(
            skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper(
                skirout.editor.v1.presentation.ChildrenLayout.createColumn(
                    spacing = spacing.pixels,
                    mainAxisAlignment = MainAxisAlignment.START,
                    crossAxisAlignment = cross,
                    clipOverflow = false,
                ),
            ),
        )
    }

    override fun hierarchy(
        unaryConnector: ConnectorStyle,
        trunkConnector: ConnectorStyle,
        branchConnector: ConnectorStyle,
        itemSpacing: Spacing,
        indentation: Spacing,
        leadingSpacing: Spacing,
        itemAnchor: ConnectorAnchor,
        flattenSingleItem: Boolean,
        cross: CrossAxisAlignment,
    ) {
        set(
            skirout.editor.v1.presentation.SequenceLayout.createHierarchy(
                unaryConnector = unaryConnector.wire(state),
                trunkConnector = trunkConnector.wire(state),
                branchConnector = branchConnector.wire(state),
                itemSpacing = state.lower(literal(itemSpacing.pixels), DOUBLE_SLOT),
                indentation = state.lower(literal(indentation.pixels), DOUBLE_SLOT),
                leadingSpacing = state.lower(literal(leadingSpacing.pixels), DOUBLE_SLOT),
                itemAnchor =
                    when (itemAnchor) {
                        ConnectorAnchor.Start -> skirout.editor.v1.presentation.ConnectorAnchor.START
                        ConnectorAnchor.Center -> skirout.editor.v1.presentation.ConnectorAnchor.CENTER
                    },
                flattenSingleItem = state.lower(literal(flattenSingleItem), BOOLEAN_SLOT),
                crossAxisAlignment = cross,
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

/**
 * The wire definition of this source. Its key, selectability and relation targets read the row binding, and a
 * projected source's also the resource binding, so they are lowered while those are declared.
 */
internal fun CollectionSource<*, *>.wire(state: PresentationBuildState): PresentationCollectionDefinition =
    state.declareRow(this) { row ->
        val keyType = state.keyType(this)
        PresentationCollectionDefinition(
            sourceId = id,
            rowBinding = row,
            key = state.lower(key, keyType),
            selectability = state.lower(selectability, BOOLEAN_SLOT),
            relations =
                relations.map { relation ->
                    PresentationCollectionRelationDefinition(
                        relationId = relation.id,
                        targets = state.lower(relation.targets, if (relation.many) listSlot(keyType) else keyType),
                    )
                },
            projection =
                (rows as? CollectionRows.Projected)?.let { projected ->
                    PresentationCollectionProjection(
                        root = projected.projection.root,
                        resourceBinding = BindingDeclaration(id = projected.resourceBinding, type = ResourceIdDefinition.id.template()),
                        fields =
                            projected.projection.fields.map { field ->
                                PresentationCollectionProjectionField(
                                    target = field.target,
                                    source =
                                        when (val source = field.source) {
                                            is CollectionProjectionValueSpec.Content -> {
                                                PresentationCollectionProjectionValue.ContentWrapper(source.path)
                                            }

                                            is CollectionProjectionValueSpec.Literal -> {
                                                PresentationCollectionProjectionValue.LiteralWrapper(source.value.requirePortable())
                                            }
                                        },
                                )
                            },
                    )
                },
        )
    }

/**
 * Runs [body] with the row binding of [source] declared, typed as its rows; rows of a projected source may be
 * missing, and its resource binding is declared too.
 */
internal fun <R> PresentationBuildState.declareRow(
    source: CollectionSource<*, *>,
    body: (BindingDeclaration) -> R,
): R =
    when (val rows = source.rows) {
        CollectionRows.Supplied -> {
            declare(source.rowBinding, source.rowType, mayBeMissing = false, body)
        }

        is CollectionRows.Projected -> {
            declare(rows.resourceBinding, ResourceIdDefinition.id.template(), mayBeMissing = false) {
                declare(source.rowBinding, source.rowType, mayBeMissing = true, body)
            }
        }
    }

/** The type of the keys of [source], inferred from its key expression over one row. */
internal fun PresentationBuildState.keyType(source: CollectionSource<*, *>): TypeTemplate =
    declareRow(source) { lowerInferred(source.key).second }
