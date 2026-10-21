package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.literal
import com.typewritermc.types.Icon
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.CollectionGraphDirection
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.DateTimeZone
import skirout.editor.v1.presentation.HeaderActionPlacement
import skirout.editor.v1.presentation.HeaderActionTone
import skirout.editor.v1.presentation.PresentationTextOverflow
import skirout.editor.v1.presentation.PresentationTextTone
import skirout.editor.v1.presentation.RelativeTimeStyle
import skirout.editor.v1.presentation.TextParagraph
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.TypeTemplate
import kotlin.time.Instant

interface PresentationContent {
    fun text(
        value: Expr<String, Handled>,
        style: TextStyle = TextStyle(),
        paragraph: TextParagraph = textParagraph(),
    )

    fun richText(configure: RichTextScope.() -> Unit)

    fun markdown(
        value: Expr<String, Handled>,
        color: PresentationColor? = null,
    )

    /** Draws the Iconify icon named by [value], such as `material-symbols:label`. */
    fun icon(
        value: Expr<String, Handled>,
        options: IconOptions = IconOptions(),
    )

    /**
     * Draws a typed [Icon], such as a resource's display icon. The icon element accepts an Iconify name or an [Icon]
     * value and editors render the variant they receive. Call it as `icon(value)`; the typed overload forwards here.
     */
    fun iconValue(
        value: Expr<Icon, Handled>,
        options: IconOptions = IconOptions(),
    )

    fun image(
        source: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>? = null,
        configure: ImageScope.() -> Unit = {},
    )

    fun badge(
        label: Expr<String, Handled>,
        configure: DisplayAppearanceScope.() -> Unit = {},
    )

    fun chip(
        label: Expr<String, Handled>,
        color: PresentationColor? = null,
        configure: DisplayAppearanceScope.() -> Unit = {},
    )

    fun <N> progress(
        value: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        label: Expr<String, Handled>? = null,
        configure: ProgressAppearanceScope.() -> Unit = {},
    )

    fun <V> status(
        value: Expr<V, Handled>,
        cases: List<StatusCase<V>>,
        fallback: StatusAppearance? = null,
    )

    fun dateTime(
        value: Expr<Instant, Handled>,
        format: Expr<String, Handled>,
        zone: DateTimeZone = DateTimeZone.LOCAL,
        configure: DisplayAppearanceScope.() -> Unit = {},
    )

    fun relativeTime(
        value: Expr<Instant, Handled>,
        style: RelativeTimeStyle = RelativeTimeStyle.COMPACT,
        zone: DateTimeZone = DateTimeZone.LOCAL,
        configure: DisplayAppearanceScope.() -> Unit = {},
    )
}

interface PresentationData {
    fun showIf(
        condition: Expr<Boolean, Handled>,
        whenFalse: (Layout.() -> Unit)? = null,
        body: Layout.() -> Unit,
    )

    fun <V, ItemScope> repeated(
        source: Expr<List<V>, Handled>,
        items: SequenceScope<ItemScope>.() -> Unit,
    )

    fun <V, Scope> scoped(
        binding: PresentationInput<V, Scope>,
        body: Scope.() -> Unit,
    )

    fun <V, Scope> typedField(
        binding: PresentationInput<V, Scope>,
        body: Scope.() -> Unit,
    )

    fun <Row, Key> collectionLookup(
        source: CollectionSource<Row, Key>,
        key: PresentationInput<Key, *>,
        configure: LookupScope<Row>.() -> Unit,
    )

    fun <Row, Key> collectionGraph(
        source: CollectionSource<Row, Key>,
        configure: GraphScope<Row, Key>.() -> Unit,
    )

    fun <V> polymorphicMatch(
        binding: PresentationInput<V, *>,
        cases: MatchScope<V>.() -> Unit,
    )

    fun invoke(
        presentation: PresentationReference,
        arguments: PresentationArguments.() -> Unit,
    )
}

interface PresentationInteractions {
    fun button(
        label: Expr<String, Handled>,
        action: skirout.editor.v1.action.EditorAction,
        configure: ButtonScope.() -> Unit = {},
    )

    fun iconButton(
        icon: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>,
        action: skirout.editor.v1.action.EditorAction,
        configure: IconButtonScope.() -> Unit = {},
    )

    fun menu(
        label: Expr<String, Handled>? = null,
        body: MenuScope.() -> Unit,
    )

    fun tooltip(
        message: Expr<String, Handled>,
        configure: TooltipAppearanceScope.() -> Unit = {},
        body: Layout.() -> Unit,
    )

    fun commitControls(binding: PresentationInput<*, *>)
}

interface TabsScope : InputAppearanceScope {
    fun spacing(value: Double)

    fun contentSpacing(value: Double)

    fun tab(
        id: String,
        label: Expr<String, Handled>,
        icon: String? = null,
        body: Layout.() -> Unit,
    )
}

interface RichTextScope {
    fun run(
        text: Expr<String, Handled>,
        style: TextStyleOverride? = null,
    )

    fun style(style: TextStyleOverride)

    fun paragraph(paragraph: TextParagraph)

    fun sizing(sizing: TextSizing)
}

interface HeaderScope {
    /**
     * Includes diagnostics for this input even when its editor is absent.
     * The header also summarizes its contained controls. Without an explicit
     * input, only those contained controls contribute to the summary.
     */
    fun diagnostics(input: PresentationInput<*, *>)

    fun title(text: Expr<String, Handled>)

    fun title(body: Layout.() -> Unit)

    fun description(text: Expr<String, Handled>)

    fun expanded(initially: Boolean)

    fun padding(
        header: PresentationInsets,
        content: PresentationInsets,
    )

    fun button(
        id: HeaderItemId,
        configure: HeaderButtonScope.() -> Unit,
    )

    fun toggle(
        id: HeaderItemId,
        configure: HeaderToggleScope.() -> Unit,
    )

    fun reorderHandle(
        id: HeaderItemId,
        configure: HeaderReorderScope.() -> Unit,
    )
}

interface AnchorScope {
    fun point(
        id: String,
        configure: AnchorPointScope.() -> Unit,
    )
}

interface ConnectionsScope {
    fun connection(configure: ConnectionScope.() -> Unit)

    fun bundle(configure: ConnectionBundleScope.() -> Unit)
}

data class TextStyle(
    val color: PresentationColor? = null,
    val weight: Int? = null,
    val sizing: TextSizing? = null,
    val lineHeight: Double? = null,
) {
    init {
        require(lineHeight == null || (lineHeight.isFinite() && lineHeight > 0)) { "Text line height must be finite and positive." }
    }
}

data class TextStyleOverride(
    val color: PresentationColor? = null,
    val weight: Int? = null,
)

/** Logical font size policy. Fit bounds must resolve to positive whole sizes. */
sealed interface TextSizing {
    data class Exact(
        val value: Expr<Double, Handled>,
    ) : TextSizing

    data class Fit(
        val minimum: Expr<Double, Handled>,
        val maximum: Expr<Double, Handled>,
    ) : TextSizing
}

/** The Skir [TextParagraph] policy of authored text, with the defaults text uses when a field is not given. */
fun textParagraph(
    maxLines: Int? = null,
    overflow: PresentationTextOverflow = PresentationTextOverflow.CLIP,
    softWrap: Boolean = false,
    selectable: Boolean = false,
    tone: PresentationTextTone = PresentationTextTone.PRIMARY,
) = TextParagraph(maxLines = maxLines, overflow = overflow, softWrap = softWrap, selectable = selectable, tone = tone)

data class IconOptions(
    val size: Double? = null,
    val color: PresentationColor? = null,
)

/** Draws a typed [Icon] such as a resource's display icon, beside the Iconify name overload of the same element. */
@JvmName("typedIcon")
fun PresentationContent.icon(
    value: Expr<Icon, Handled>,
    options: IconOptions = IconOptions(),
) = iconValue(value, options)

data class StatusCase<V>(
    val value: V,
    val appearance: StatusAppearance,
)

data class StatusAppearance(
    val label: String,
    val tone: String,
    val configure: DisplayAppearanceScope.() -> Unit = {},
)

@JvmInline value class HeaderItemId(
    val value: String,
)

data class HeaderActionConfirmation(
    val title: Expr<String, Handled>,
    val message: Expr<String, Handled>,
    val confirmationLabel: Expr<String, Handled>,
)

interface HeaderButtonScope {
    fun icon(value: Expr<String, Handled>)

    fun label(value: Expr<String, Handled>)

    fun tooltip(value: Expr<String, Handled>)

    fun action(value: EditorAction)

    fun priority(value: Expr<Int, Handled>)

    fun visibleIf(value: Expr<Boolean, Handled>)

    fun enabledIf(value: Expr<Boolean, Handled>)

    fun tone(value: HeaderActionTone)

    fun confirmation(value: HeaderActionConfirmation)

    fun placement(value: HeaderActionPlacement)
}

interface HeaderToggleScope {
    fun label(value: Expr<String, Handled>)

    fun checked(value: Expr<Boolean, Handled>)

    fun action(value: EditorAction)

    fun tooltip(value: Expr<String, Handled>)

    fun priority(value: Expr<Int, Handled>)

    fun visibleIf(value: Expr<Boolean, Handled>)

    fun enabledIf(value: Expr<Boolean, Handled>)

    fun confirmation(value: HeaderActionConfirmation)

    fun placement(value: HeaderActionPlacement)
}

interface HeaderReorderScope {
    fun label(value: Expr<String, Handled>)

    fun source(value: PresentationInput<*, *>)

    fun tooltip(value: Expr<String, Handled>)

    fun visibleIf(value: Expr<Boolean, Handled>)

    fun enabledIf(value: Expr<Boolean, Handled>)
}

interface SequenceScope<Item> :
    Layout,
    SequenceLayoutScope {
    val item: Expr<Item, MayBeMissing>

    fun empty(body: Layout.() -> Unit)

    fun separator(body: Layout.() -> Unit)
}

interface CollectionSource<Row, Key> {
    val id: String

    val rowType: TypeTemplate

    val rowBinding: ExpressionBindingId

    val key: Expr<Key, Handled>

    val selectability: Expr<Boolean, Handled>

    val relations: List<CollectionRelation<Key>>

    val rows: CollectionRows
}

sealed interface CollectionRows {
    data object Supplied : CollectionRows

    data class Projected(
        val projection: CollectionProjectionSpec,
        val resourceBinding: ExpressionBindingId,
    ) : CollectionRows
}

data class CollectionRelation<Key>(
    val id: String,
    val targets: ExpressionNode,
)

interface CollectionSourceScope<Row, Key> {
    val row: Expr<Row, Handled>

    fun key(value: Expr<Key, Handled>)

    fun selectability(value: Expr<Boolean, Handled>)

    fun relation(
        id: String,
        target: Expr<Key, Handled>,
    )

    fun relations(
        id: String,
        targets: Expr<List<Key>, Handled>,
    )
}

interface ProjectedCollectionSourceScope<Row, Key, Expressions : Any> {
    val row: Expr<Row, MayBeMissing>

    val resource: Expr<ResourceId, Handled>

    val expressions: Expressions

    fun selectability(value: Expr<Boolean, Handled>)

    fun relation(
        id: String,
        target: Expr<Key, Handled>,
    )

    fun relations(
        id: String,
        targets: Expr<List<Key>, Handled>,
    )
}

fun <Row, Key> collectionSource(
    id: String,
    rowType: TypeTemplate,
    configure: CollectionSourceScope<Row, Key>.() -> Unit,
): CollectionSource<Row, Key> {
    require(id.isNotBlank()) { "Collection source ids must not be blank." }
    val rowBinding = ExpressionBindingId(value = "collection.$id.row")
    val scope = DefaultCollectionSourceScope<Row, Key>(rowBinding)
    scope.configure()
    return scope.build(id, rowType, CollectionRows.Supplied)
}

fun <R : Resource, Row, Expressions : Any> CollectionProjection<R, Row, Expressions>.projectedCollectionSource(
    configure: ProjectedCollectionSourceScope<Row, ResourceId, Expressions>.() -> Unit = {},
): CollectionSource<Row, ResourceId> = projectedCollectionSource({ resource }, configure)

fun <R : Resource, Row, Key, Expressions : Any> CollectionProjection<R, Row, Expressions>.projectedCollectionSource(
    key: ProjectedCollectionSourceScope<Row, Key, Expressions>.() -> Expr<Key, Handled>,
    configure: ProjectedCollectionSourceScope<Row, Key, Expressions>.() -> Unit = {},
): CollectionSource<Row, Key> {
    val projection = specification
    val rowBinding = ExpressionBindingId(value = "collection.${projection.sourceId}.row")
    val resourceBinding = ExpressionBindingId(value = "collection.${projection.sourceId}.resource")
    val scope = DefaultProjectedCollectionSourceScope<Row, Key, Expressions>(rowBinding, resourceBinding, expressions)
    scope.configure()
    return scope.build(projection, scope.key())
}

private class DefaultCollectionSourceScope<Row, Key>(
    private val binding: ExpressionBindingId,
) : CollectionSourceScope<Row, Key> {
    override val row = com.typewritermc.expression.inputExpression<Row, Handled>(binding)
    private var key: Expr<Key, Handled>? = null
    private var selectability: Expr<Boolean, Handled> = literal(true)
    private val relations = mutableListOf<CollectionRelation<Key>>()

    override fun key(value: Expr<Key, Handled>) {
        check(key == null) { "A collection source key may be declared once." }
        key = value
    }

    override fun selectability(value: Expr<Boolean, Handled>) {
        selectability = value
    }

    override fun relation(
        id: String,
        target: Expr<Key, Handled>,
    ) {
        addRelation(id, target.toNode())
    }

    override fun relations(
        id: String,
        targets: Expr<List<Key>, Handled>,
    ) {
        addRelation(id, targets.toNode())
    }

    private fun addRelation(
        id: String,
        targets: ExpressionNode,
    ) {
        require(id.isNotBlank()) { "Collection relation ids must not be blank." }
        require(relations.none { it.id == id }) { "Collection relation ids must be unique within one source." }
        relations += CollectionRelation(id, targets)
    }

    fun build(
        id: String,
        rowType: TypeTemplate,
        rows: CollectionRows,
    ): CollectionSource<Row, Key> =
        DefaultCollectionSource(
            id = id,
            rowType = rowType,
            rowBinding = binding,
            key = requireNotNull(key) { "A collection source must declare its row key." },
            selectability = selectability,
            relations = relations.toList(),
            rows = rows,
        )
}

private class DefaultProjectedCollectionSourceScope<Row, Key, Expressions : Any>(
    private val rowBinding: ExpressionBindingId,
    private val resourceBinding: ExpressionBindingId,
    expressionFactory: ExpressionFactory<Expressions>,
) : ProjectedCollectionSourceScope<Row, Key, Expressions> {
    override val row = com.typewritermc.expression.inputExpression<Row, MayBeMissing>(rowBinding)
    override val resource = com.typewritermc.expression.inputExpression<ResourceId, Handled>(resourceBinding)
    override val expressions: Expressions = expressionFactory.create(row)
    private var selectability: Expr<Boolean, Handled> = literal(true)
    private val relations = mutableListOf<CollectionRelation<Key>>()

    override fun selectability(value: Expr<Boolean, Handled>) {
        selectability = value
    }

    override fun relation(
        id: String,
        target: Expr<Key, Handled>,
    ) {
        addRelation(id, target.toNode())
    }

    override fun relations(
        id: String,
        targets: Expr<List<Key>, Handled>,
    ) {
        addRelation(id, targets.toNode())
    }

    private fun addRelation(
        id: String,
        targets: ExpressionNode,
    ) {
        require(id.isNotBlank()) { "Collection relation ids must not be blank." }
        require(relations.none { it.id == id }) { "Collection relation ids must be unique within one source." }
        relations += CollectionRelation(id, targets)
    }

    fun build(
        projection: CollectionProjectionSpec,
        key: Expr<Key, Handled>,
    ): CollectionSource<Row, Key> =
        DefaultCollectionSource(
            id = projection.sourceId,
            rowType = projection.rowType,
            rowBinding = rowBinding,
            key = key,
            selectability = selectability,
            relations = relations.toList(),
            rows = CollectionRows.Projected(projection, resourceBinding),
        )
}

private data class DefaultCollectionSource<Row, Key>(
    override val id: String,
    override val rowType: TypeTemplate,
    override val rowBinding: ExpressionBindingId,
    override val key: Expr<Key, Handled>,
    override val selectability: Expr<Boolean, Handled>,
    override val relations: List<CollectionRelation<Key>>,
    override val rows: CollectionRows,
) : CollectionSource<Row, Key>

interface LookupScope<Row> {
    val row: Expr<Row, MayBeMissing>

    fun found(body: Layout.() -> Unit)

    fun missing(body: Layout.() -> Unit)

    fun loading(body: Layout.() -> Unit)
}

enum class ConnectorAnchor { Start, Center }

/** Arranges graph occurrences without changing their traversal or content. */
interface SequenceLayoutScope {
    fun clippedRow(spacing: Double = 0.0)

    fun column(
        spacing: Double = 0.0,
        cross: CrossAxisAlignment = CrossAxisAlignment.START,
    )

    fun hierarchy(
        unaryConnector: ConnectorStyle,
        trunkConnector: ConnectorStyle,
        branchConnector: ConnectorStyle,
        itemSpacing: Double = 24.0,
        indentation: Double = 16.0,
        leadingSpacing: Double = 16.0,
        itemAnchor: ConnectorAnchor = ConnectorAnchor.Center,
        flattenSingleItem: Boolean = true,
        cross: CrossAxisAlignment = CrossAxisAlignment.STRETCH,
    )
}

interface GraphRootSequenceScope<Row> : SequenceLayoutScope {
    /** The root occurrence for per item styling; shared trunk styling uses the sequence owner scope. */
    val item: Expr<Row, MayBeMissing>

    fun empty(body: Layout.() -> Unit)
}

interface GraphChildrenSequenceScope<Row> : SequenceLayoutScope {
    /** The owner of this child sequence, used for shared trunk styling. */
    val parent: Expr<Row, MayBeMissing>

    /** The individual child occurrence, used for unary and branch styling. */
    val item: Expr<Row, MayBeMissing>
}

interface GraphNodeScope<Row> : Layout {
    val row: Expr<Row, MayBeMissing>

    val children: Expr<List<Row>, MayBeMissing>

    fun descendants()
}

interface GraphScope<Row, Key> {
    /** Configures independent roots. Unspecified sequences use a plain column. */
    fun rootSequence(body: GraphRootSequenceScope<Row>.() -> Unit)

    /** Configures each node's descendants independently of its root layout. */
    fun childrenSequence(body: GraphChildrenSequenceScope<Row>.() -> Unit)

    fun root(binding: PresentationInput<Key, *>)

    fun roots(binding: PresentationInput<List<Key>, *>)

    fun root(value: Expr<Key, MayBeMissing>)

    fun roots(value: Expr<List<Key>, MayBeMissing>)

    fun relation(
        id: String,
        direction: CollectionGraphDirection = CollectionGraphDirection.FORWARD,
        maximumDepth: Int? = null,
    )

    fun node(body: GraphNodeScope<Row>.() -> Unit)
}

interface MatchCaseScope<Value> : Layout {
    val value: Expr<Value, MayBeMissing>
}

interface MatchScope<V> {
    fun <Subtype : V> case(
        type: AppliedPresentation<Subtype>,
        body: MatchCaseScope<Subtype>.() -> Unit,
    )

    fun fallback(body: Layout.() -> Unit)
}

interface PresentationArguments {
    fun <Value> bind(
        parameter: PresentationParameter<Value>,
        value: PresentationInput<out Value, *>,
    )
}
