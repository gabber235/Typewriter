package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.configuration.generatedExpressionScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.literal
import com.typewritermc.types.Color
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import skirout.editor.v1.action.EditorAction
import kotlin.time.Instant

interface PresentationContent {
    fun text(
        value: Expr<String, Handled>,
        style: TextStyle = TextStyle(),
        paragraph: TextParagraph = TextParagraph(),
    )

    fun richText(configure: RichTextScope.() -> Unit)

    fun markdown(
        value: Expr<String, Handled>,
        color: PresentationColor? = null,
    )

    fun icon(
        value: Expr<String, Handled>,
        options: IconOptions = IconOptions(),
    )

    fun image(
        source: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>? = null,
    )

    fun badge(
        label: Expr<String, Handled>,
        tone: String,
    )

    fun chip(
        label: Expr<String, Handled>,
        color: PresentationColor? = null,
    )

    fun <N> progress(
        value: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        label: Expr<String, Handled>? = null,
    )

    fun <V> status(
        value: Expr<V, Handled>,
        cases: List<StatusCase<V>>,
        fallback: StatusAppearance? = null,
    )

    fun dateTime(
        value: Expr<Instant, Handled>,
        format: Expr<String, Handled>,
        zone: DateTimeZone = DateTimeZone.Local,
    )

    fun relativeTime(
        value: Expr<Instant, Handled>,
        style: RelativeTimeStyle = RelativeTimeStyle.Compact,
        zone: DateTimeZone = DateTimeZone.Local,
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
        action: EditorAction,
    )

    fun iconButton(
        icon: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>,
        action: EditorAction,
    )

    fun menu(
        label: Expr<String, Handled>? = null,
        body: MenuScope.() -> Unit,
    )

    fun tooltip(
        message: Expr<String, Handled>,
        body: Layout.() -> Unit,
    )

    fun commitControls(binding: PresentationInput<*, *>)
}

interface TabsScope {
    fun tab(
        id: String,
        label: Expr<String, Handled>,
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

interface MenuScope {
    fun item(
        id: String,
        label: Expr<String, Handled>,
        action: EditorAction,
    )
}

interface HeaderScope {
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
)

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

enum class TextOverflow { Clip, Ellipsis }

enum class TextTone { Primary, Secondary }

data class TextParagraph(
    val maximumLines: Int? = null,
    val overflow: TextOverflow = TextOverflow.Clip,
    val softWrap: Boolean = false,
    val selectable: Boolean = false,
    val tone: TextTone = TextTone.Primary,
)

data class IconOptions(
    val size: Double? = null,
    val color: PresentationColor? = null,
)

data class StatusCase<V>(
    val value: V,
    val appearance: StatusAppearance,
)

data class StatusAppearance(
    val label: String,
    val tone: String,
)

enum class DateTimeZone { Local, Utc }

enum class RelativeTimeStyle { Compact, Full }

@JvmInline value class HeaderItemId(
    val value: String,
)

enum class HeaderActionTone { Neutral, Destructive }

enum class HeaderActionPlacement { BeforeTitle, AfterTitle, End }

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

interface SequenceScope<Item> : Layout {
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

    data class Resources(
        val root: TypeDefinitionId,
        val resourceBinding: ExpressionBindingId,
        val appearance: PresentationReference?,
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

interface ResourceCollectionSourceScope<Row : Resource> {
    val row: Expr<Row, MayBeMissing>

    val resource: Expr<ResourceId, Handled>

    fun selectability(value: Expr<Boolean, Handled>)

    fun relation(
        id: String,
        target: Expr<ResourceId, Handled>,
    )

    fun relations(
        id: String,
        targets: Expr<List<ResourceId>, Handled>,
    )
}

fun <Row, Key> collectionSource(
    id: String,
    rowType: TypeTemplate,
    configure: CollectionSourceScope<Row, Key>.() -> Unit,
): CollectionSource<Row, Key> {
    require(id.isNotBlank()) { "Collection source ids must not be blank." }
    val rowBinding = ExpressionBindingId("collection.$id.row")
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
    val rowBinding = ExpressionBindingId("collection.${projection.sourceId}.row")
    val resourceBinding = ExpressionBindingId("collection.${projection.sourceId}.resource")
    val scope = DefaultProjectedCollectionSourceScope<Row, Key, Expressions>(rowBinding, resourceBinding, expressions)
    scope.configure()
    return scope.build(projection, scope.key())
}

internal fun <Row : Resource> resourceCollectionSource(
    id: String,
    root: TypeTemplate.Named,
    appearance: PresentationReference?,
    configure: ResourceCollectionSourceScope<Row>.() -> Unit,
): CollectionSource<Row, ResourceId> {
    require(id.isNotBlank()) { "Collection source ids must not be blank." }
    val rowBinding = ExpressionBindingId("collection.$id.row")
    val resourceBinding = ExpressionBindingId("collection.$id.resource")
    val scope = DefaultResourceCollectionSourceScope<Row>(rowBinding, resourceBinding)
    scope.configure()
    return scope.build(id, root, appearance)
}

private class DefaultCollectionSourceScope<Row, Key>(
    private val binding: ExpressionBindingId,
) : CollectionSourceScope<Row, Key> {
    override val row = Expr<Row, Handled>(ExpressionNode.Read(binding, ValuePath()))
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
        addRelation(id, target.node)
    }

    override fun relations(
        id: String,
        targets: Expr<List<Key>, Handled>,
    ) {
        addRelation(id, targets.node)
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
    expressionType: kotlin.reflect.KClass<Expressions>,
) : ProjectedCollectionSourceScope<Row, Key, Expressions> {
    override val row = Expr<Row, MayBeMissing>(ExpressionNode.Read(rowBinding, ValuePath()))
    override val resource = Expr<ResourceId, Handled>(ExpressionNode.Read(resourceBinding, ValuePath()))
    override val expressions: Expressions = generatedExpressionScope(expressionType, row)
    private var selectability: Expr<Boolean, Handled> = literal(true)
    private val relations = mutableListOf<CollectionRelation<Key>>()

    override fun selectability(value: Expr<Boolean, Handled>) {
        selectability = value
    }

    override fun relation(
        id: String,
        target: Expr<Key, Handled>,
    ) {
        addRelation(id, target.node)
    }

    override fun relations(
        id: String,
        targets: Expr<List<Key>, Handled>,
    ) {
        addRelation(id, targets.node)
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

private class DefaultResourceCollectionSourceScope<Row : Resource>(
    private val rowBinding: ExpressionBindingId,
    private val resourceBinding: ExpressionBindingId,
) : ResourceCollectionSourceScope<Row> {
    override val row = Expr<Row, MayBeMissing>(ExpressionNode.Read(rowBinding, ValuePath()))
    override val resource = Expr<ResourceId, Handled>(ExpressionNode.Read(resourceBinding, ValuePath()))
    private var selectability: Expr<Boolean, Handled> = literal(true)
    private val relations = mutableListOf<CollectionRelation<ResourceId>>()

    override fun selectability(value: Expr<Boolean, Handled>) {
        selectability = value
    }

    override fun relation(
        id: String,
        target: Expr<ResourceId, Handled>,
    ) {
        addRelation(id, target.node)
    }

    override fun relations(
        id: String,
        targets: Expr<List<ResourceId>, Handled>,
    ) {
        addRelation(id, targets.node)
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
        root: TypeTemplate.Named,
        appearance: PresentationReference?,
    ): CollectionSource<Row, ResourceId> =
        DefaultCollectionSource(
            id = id,
            rowType = root,
            rowBinding = rowBinding,
            key = resource,
            selectability = selectability,
            relations = relations.toList(),
            rows = CollectionRows.Resources(root.definition, resourceBinding, appearance),
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

enum class CollectionDirection { Forward, Reverse }

interface GraphNodeScope<Row> : Layout {
    val row: Expr<Row, MayBeMissing>

    val children: Expr<List<Row>, MayBeMissing>

    fun descendants()
}

interface GraphScope<Row, Key> {
    fun root(binding: PresentationInput<Key, *>)

    fun roots(binding: PresentationInput<List<Key>, *>)

    fun root(value: Expr<Key, Handled>)

    fun roots(value: Expr<List<Key>, Handled>)

    fun relation(
        id: String,
        direction: CollectionDirection = CollectionDirection.Forward,
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
