package com.typewritermc.presentation

import com.typewritermc.capability.CapabilityId
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.PopupSide
import skirout.editor.v1.presentation.SearchSelectionMode
import skirout.editor.v1.presentation.SearchSelectorMultiplicity
import skirout.editor.v1.presentation.SearchSelectorValues
import skirout.editor.v1.type_catalog.TypeTemplate
import kotlin.time.Duration

interface SearchInputScope<Value, Row> :
    TextEntryAppearanceScope,
    InputContentScope,
    PopupAppearanceScope {
    val query: Expr<String, Handled>
    val sources: SearchSources

    fun selectors(configure: SearchSelectorsScope.() -> Unit)

    fun result(configure: SearchResultScope<Value, Row>.() -> Unit)

    fun summary(body: Layout.() -> Unit)

    fun initialQuery(value: String)

    fun initialQuery(value: Expr<String, Handled>)

    fun customValue(value: Expr<Value, Handled>)

    fun selectionMode(value: SearchSelectionMode)

    fun provider(source: SearchProviderSpec<Row>)

    fun popupSide(value: PopupSide)

    fun emptyText(value: String)

    fun emptyText(value: Expr<String, Handled>)

    fun loadingText(value: String)

    fun loadingText(value: Expr<String, Handled>)

    fun empty(body: Layout.() -> Unit)

    fun loading(body: Layout.() -> Unit)
}

/**
 * Describes portable search sources for the consuming editor runtime to execute.
 * Sources share the search input's result mapping and selectors. Decorations wrap in call order, so the last
 * decoration becomes the outermost provider. Network work, query cancellation, caches, and history are owned by the consumer.
 */
interface SearchSources {
    fun <Row> staticValues(values: Expr<List<Row>, Handled>): SearchProviderSpec<Row>

    fun <Row> collection(
        source: CollectionSource<Row, *>,
        where: PortableRowPredicate<Row>? = null,
    ): SearchProviderSpec<Row>

    fun <Row> httpJson(configure: HttpJsonSearchScope<Row>.() -> Unit): SearchProviderSpec<Row>

    fun <Payload, Row> realmCallback(
        capability: SearchCapability<Payload, Row>,
        payload: Expr<Payload, Handled>,
    ): SearchProviderSpec<Row>

    fun <Row> merge(vararg sources: SearchProviderSpec<Row>): SearchProviderSpec<Row>

    companion object : SearchSources by DefaultSearchSources
}

interface SearchProviderSpec<Row> {
    fun decorate(decoration: SearchDecoration): SearchProviderSpec<Row>

    fun rank(configure: RankingScope<Row>.() -> Unit): SearchProviderSpec<Row>
}

sealed interface SearchDecoration {
    data class Gate(
        val condition: skirout.editor.v1.expression.ExpressionNode,
        val guidance: skirout.editor.v1.expression.ExpressionNode?,
    ) : SearchDecoration

    data class Debounce(
        val duration: Duration,
    ) : SearchDecoration

    data class Cache(
        val capacity: Int,
        val retainStaleResults: Boolean,
    ) : SearchDecoration

    data class Limit(
        val maximum: skirout.editor.v1.expression.ExpressionNode,
    ) : SearchDecoration

    data object Distinct : SearchDecoration

    data class History(
        val key: String,
        val label: skirout.editor.v1.expression.ExpressionNode,
        val capacity: Int,
    ) : SearchDecoration

    data class Section(
        val id: String,
        val label: skirout.editor.v1.expression.ExpressionNode,
    ) : SearchDecoration

    data class Rank(
        val fields: List<SearchRankingField>,
    ) : SearchDecoration
}

data class SearchRankingField(
    val expression: ExpressionNode,
    val weight: Int,
)

fun <Row> SearchProviderSpec<Row>.gate(
    condition: Expr<Boolean, Handled>,
    guidance: Expr<String, Handled>? = null,
): SearchProviderSpec<Row> = decorate(SearchDecoration.Gate(condition.toNode(), guidance?.toNode()))

fun <Row> SearchProviderSpec<Row>.debounce(duration: Duration): SearchProviderSpec<Row> = decorate(SearchDecoration.Debounce(duration))

fun <Row> SearchProviderSpec<Row>.cache(
    capacity: Int,
    retainStaleResults: Boolean,
): SearchProviderSpec<Row> = decorate(SearchDecoration.Cache(capacity, retainStaleResults))

fun <Row> SearchProviderSpec<Row>.limit(maximum: Expr<Int, Handled>): SearchProviderSpec<Row> =
    decorate(SearchDecoration.Limit(maximum.toNode()))

fun <Row> SearchProviderSpec<Row>.distinct(): SearchProviderSpec<Row> = decorate(SearchDecoration.Distinct)

fun <Row> SearchProviderSpec<Row>.history(
    key: String,
    label: Expr<String, Handled>,
    capacity: Int,
): SearchProviderSpec<Row> = decorate(SearchDecoration.History(key, label.toNode(), capacity))

fun <Row> SearchProviderSpec<Row>.section(
    id: String,
    label: Expr<String, Handled>,
): SearchProviderSpec<Row> = decorate(SearchDecoration.Section(id, label.toNode()))

interface SearchSelectorsScope {
    fun selector(
        id: String,
        key: String,
        values: SearchSelectorValues = SearchSelectorValues.FREE_TEXT,
        caseSensitive: Boolean = false,
        multiplicity: SearchSelectorMultiplicity = SearchSelectorMultiplicity.SINGLE,
        color: Long? = null,
    ): Expr<Any?, Handled>
}

/**
 * Maps a provider row to a stable result key, a value to write on selection, and its displayed presentation.
 * The selected value can differ from the row's type and identity. Required mappings are checked when the search
 * input is captured; a row's [presentation] body is captured with it.
 */
interface SearchResultScope<Value, Row> {
    val row: Expr<Row, Handled>

    fun key(value: Expr<*, out com.typewritermc.expression.MissingPolicy>)

    fun selectedValue(value: Expr<Value, out com.typewritermc.expression.MissingPolicy>)

    fun presentation(body: Layout.() -> Unit)

    fun label(value: Expr<String, Handled>)
}

interface PortableRowPredicate<Row> {
    val expression: Expr<Boolean, Handled>
}

fun <Row> rowPredicate(expression: Expr<Boolean, Handled>): PortableRowPredicate<Row> =
    object : PortableRowPredicate<Row> {
        override val expression = expression
    }

interface HttpJsonSearchScope<Row> {
    val query: Expr<String, Handled>

    fun uri(value: Expr<String, Handled>)

    fun parameter(
        name: String,
        value: Expr<String, Handled>,
        omitIfEmpty: Boolean = false,
    )

    fun result(
        path: String,
        type: TypeTemplate,
    )

    fun context(
        id: String,
        path: String,
        type: TypeTemplate,
    ): Expr<Any?, Handled>

    fun timeout(value: Duration)
}

interface SearchCapability<Payload, Row> {
    val id: CapabilityId
}

interface RankingScope<Row> {
    val row: Expr<Row, Handled>

    fun field(
        value: Expr<*, Handled>,
        weight: Int = 1,
    )
}

internal sealed interface SearchProviderDescription<Row> {
    data class Static<Row>(
        val values: ExpressionNode,
    ) : SearchProviderDescription<Row>

    data class Collection<Row>(
        val source: CollectionSource<Row, *>,
        val predicate: ExpressionNode?,
    ) : SearchProviderDescription<Row>

    data class HttpJson<Row>(
        val uri: ExpressionNode,
        val parameters: List<HttpParameter>,
        val resultPath: String,
        val resultType: TypeTemplate,
        val contexts: List<HttpContext>,
        val timeout: Duration,
    ) : SearchProviderDescription<Row>

    data class RealmCallback<Row>(
        val capability: CapabilityId,
        val payload: ExpressionNode,
    ) : SearchProviderDescription<Row>

    data class Merge<Row>(
        val children: List<DefaultSearchProviderSpec<Row>>,
    ) : SearchProviderDescription<Row>
}

internal data class HttpParameter(
    val name: String,
    val value: ExpressionNode,
    val omitIfEmpty: Boolean,
)

internal data class HttpContext(
    val binding: ExpressionBindingId,
    val path: String,
    val type: TypeTemplate,
)

internal data class DefaultSearchProviderSpec<Row>(
    val description: SearchProviderDescription<Row>,
    val decorations: List<SearchDecoration> = emptyList(),
) : SearchProviderSpec<Row> {
    override fun decorate(decoration: SearchDecoration): SearchProviderSpec<Row> = copy(decorations = decorations + decoration)

    override fun rank(configure: RankingScope<Row>.() -> Unit): SearchProviderSpec<Row> {
        val fields = mutableListOf<SearchRankingField>()
        val row = com.typewritermc.expression.inputExpression<Row, Handled>(SEARCH_RESULT_ROW)
        val scope =
            object : RankingScope<Row> {
                override val row = row

                override fun field(
                    value: Expr<*, Handled>,
                    weight: Int,
                ) {
                    require(weight > 0) { "Search ranking weight must be positive." }
                    fields += SearchRankingField(value.toNode(), weight)
                }
            }
        scope.configure()
        require(fields.isNotEmpty()) { "Search ranking must declare at least one field." }
        return decorate(SearchDecoration.Rank(fields))
    }
}

internal object DefaultSearchSources : SearchSources {
    override fun <Row> staticValues(values: Expr<List<Row>, Handled>): SearchProviderSpec<Row> =
        DefaultSearchProviderSpec(SearchProviderDescription.Static(values.toNode()))

    override fun <Row> collection(
        source: CollectionSource<Row, *>,
        where: PortableRowPredicate<Row>?,
    ): SearchProviderSpec<Row> =
        DefaultSearchProviderSpec(
            SearchProviderDescription.Collection(source, where?.expression?.toNode()),
        )

    override fun <Row> httpJson(configure: HttpJsonSearchScope<Row>.() -> Unit): SearchProviderSpec<Row> {
        val scope = DefaultHttpJsonSearchScope<Row>()
        scope.configure()
        return DefaultSearchProviderSpec(scope.description())
    }

    override fun <Payload, Row> realmCallback(
        capability: SearchCapability<Payload, Row>,
        payload: Expr<Payload, Handled>,
    ): SearchProviderSpec<Row> = DefaultSearchProviderSpec(SearchProviderDescription.RealmCallback(capability.id, payload.toNode()))

    override fun <Row> merge(vararg sources: SearchProviderSpec<Row>): SearchProviderSpec<Row> {
        val children = sources.map { it.runtime() }
        require(children.isNotEmpty()) { "Merged search providers must contain at least one child." }
        return DefaultSearchProviderSpec(SearchProviderDescription.Merge(children))
    }
}

private class DefaultHttpJsonSearchScope<Row> : HttpJsonSearchScope<Row> {
    override val query = com.typewritermc.expression.inputExpression<String, Handled>(SEARCH_QUERY)
    private var uri: ExpressionNode? = null
    private val parameters = mutableListOf<HttpParameter>()
    private var resultPath: String? = null
    private var resultType: TypeTemplate? = null
    private val contexts = mutableListOf<HttpContext>()
    private var timeout = Duration.parse("10s")

    override fun uri(value: Expr<String, Handled>) {
        uri = value.toNode()
    }

    override fun parameter(
        name: String,
        value: Expr<String, Handled>,
        omitIfEmpty: Boolean,
    ) {
        require(name.isNotBlank()) { "HTTP search parameter name must not be blank." }
        parameters += HttpParameter(name, value.toNode(), omitIfEmpty)
    }

    override fun result(
        path: String,
        type: TypeTemplate,
    ) {
        resultPath = path
        resultType = type
    }

    override fun context(
        id: String,
        path: String,
        type: TypeTemplate,
    ): Expr<Any?, Handled> {
        require(id.isNotBlank()) { "HTTP search context id must not be blank." }
        val binding = ExpressionBindingId("search_context.$id")
        contexts += HttpContext(binding, path, type)
        return com.typewritermc.expression.inputExpression(binding)
    }

    override fun timeout(value: Duration) {
        require(value.isPositive()) { "HTTP search timeout must be positive." }
        timeout = value
    }

    fun description(): SearchProviderDescription.HttpJson<Row> =
        SearchProviderDescription.HttpJson(
            requireNotNull(uri) { "HTTP search must declare a URI." },
            parameters.toList(),
            requireNotNull(resultPath) { "HTTP search must declare a result path." },
            requireNotNull(resultType) { "HTTP search must declare a result type." },
            contexts.toList(),
            timeout,
        )
}

internal fun <Row> SearchProviderSpec<Row>.runtime(): DefaultSearchProviderSpec<Row> =
    this as? DefaultSearchProviderSpec<Row>
        ?: throw IllegalArgumentException("Search providers must be created by SearchSources.")

internal val SEARCH_QUERY = ExpressionBindingId("search_query")
internal val SEARCH_RESULT_ROW = ExpressionBindingId("search_result")
