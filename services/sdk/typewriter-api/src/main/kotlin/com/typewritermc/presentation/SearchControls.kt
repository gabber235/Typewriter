package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.capability.CapabilityId
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.types.TypeTemplate
import kotlin.time.Duration

interface SearchInputScope<Value, Row> {
    val query: Expr<String, Handled>

    val sources: SearchSources

    fun selectors(configure: SearchSelectorsScope.() -> Unit)

    fun result(configure: SearchResultScope<Value, Row>.() -> Unit)

    fun summary(body: Layout.() -> Unit)

    fun initialQuery(value: Expr<String, Handled>)

    fun placeholder(value: Expr<String, Handled>)

    fun customValue(value: Expr<Value, Handled>)

    fun maximumExtent(value: Expr<Double, Handled>)

    fun selectionMode(value: SearchSelectionMode)

    fun provider(source: SearchProviderSpec<Row>)
}

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
        val condition: com.typewritermc.presentation.ExpressionNode,
        val guidance: com.typewritermc.presentation.ExpressionNode?,
    ) : SearchDecoration

    data class Debounce(
        val duration: Duration,
    ) : SearchDecoration

    data class Cache(
        val capacity: Int,
        val retainStaleResults: Boolean,
    ) : SearchDecoration

    data class Limit(
        val maximum: com.typewritermc.presentation.ExpressionNode,
    ) : SearchDecoration

    data object Distinct : SearchDecoration

    data class History(
        val key: String,
        val label: com.typewritermc.presentation.ExpressionNode,
        val capacity: Int,
    ) : SearchDecoration

    data class Section(
        val id: String,
        val label: com.typewritermc.presentation.ExpressionNode,
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
): SearchProviderSpec<Row> = decorate(SearchDecoration.Gate(condition.node, guidance?.node))

fun <Row> SearchProviderSpec<Row>.debounce(duration: Duration): SearchProviderSpec<Row> = decorate(SearchDecoration.Debounce(duration))

fun <Row> SearchProviderSpec<Row>.cache(
    capacity: Int,
    retainStaleResults: Boolean,
): SearchProviderSpec<Row> = decorate(SearchDecoration.Cache(capacity, retainStaleResults))

fun <Row> SearchProviderSpec<Row>.limit(maximum: Expr<Int, Handled>): SearchProviderSpec<Row> =
    decorate(SearchDecoration.Limit(maximum.node))

fun <Row> SearchProviderSpec<Row>.distinct(): SearchProviderSpec<Row> = decorate(SearchDecoration.Distinct)

fun <Row> SearchProviderSpec<Row>.history(
    key: String,
    label: Expr<String, Handled>,
    capacity: Int,
): SearchProviderSpec<Row> = decorate(SearchDecoration.History(key, label.node, capacity))

fun <Row> SearchProviderSpec<Row>.section(
    id: String,
    label: Expr<String, Handled>,
): SearchProviderSpec<Row> = decorate(SearchDecoration.Section(id, label.node))

enum class SearchSelectionMode { Single, Multiple }

enum class SearchSelectorMultiplicity { Single, Multiple }

sealed interface SearchSelectorValues {
    data object FreeText : SearchSelectorValues

    data class Enumeration(
        val values: List<String>,
    ) : SearchSelectorValues
}

interface SearchSelectorsScope {
    fun selector(
        id: String,
        key: String,
        values: SearchSelectorValues = SearchSelectorValues.FreeText,
        caseSensitive: Boolean = false,
        multiplicity: SearchSelectorMultiplicity = SearchSelectorMultiplicity.Single,
        color: Long? = null,
    ): Expr<Any?, Handled>
}

interface SearchResultScope<Value, Row> {
    val row: Expr<Row, Handled>

    fun key(value: Expr<*, Handled>)

    fun selectedValue(value: Expr<Value, Handled>)

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
        val row = Expr<Row, Handled>(ExpressionNode.Read(SEARCH_RESULT_ROW, ValuePath()))
        val scope =
            object : RankingScope<Row> {
                override val row = row

                override fun field(
                    value: Expr<*, Handled>,
                    weight: Int,
                ) {
                    require(weight > 0) { "Search ranking weight must be positive." }
                    fields += SearchRankingField(value.node, weight)
                }
            }
        scope.configure()
        require(fields.isNotEmpty()) { "Search ranking must declare at least one field." }
        return decorate(SearchDecoration.Rank(fields))
    }
}

internal object DefaultSearchSources : SearchSources {
    override fun <Row> staticValues(values: Expr<List<Row>, Handled>): SearchProviderSpec<Row> =
        DefaultSearchProviderSpec(SearchProviderDescription.Static(values.node))

    override fun <Row> collection(
        source: CollectionSource<Row, *>,
        where: PortableRowPredicate<Row>?,
    ): SearchProviderSpec<Row> =
        DefaultSearchProviderSpec(
            SearchProviderDescription.Collection(source, where?.expression?.node),
        )

    override fun <Row> httpJson(configure: HttpJsonSearchScope<Row>.() -> Unit): SearchProviderSpec<Row> {
        val scope = DefaultHttpJsonSearchScope<Row>()
        scope.configure()
        return DefaultSearchProviderSpec(scope.description())
    }

    override fun <Payload, Row> realmCallback(
        capability: SearchCapability<Payload, Row>,
        payload: Expr<Payload, Handled>,
    ): SearchProviderSpec<Row> = DefaultSearchProviderSpec(SearchProviderDescription.RealmCallback(capability.id, payload.node))

    override fun <Row> merge(vararg sources: SearchProviderSpec<Row>): SearchProviderSpec<Row> {
        val children = sources.map { it.runtime() }
        require(children.isNotEmpty()) { "Merged search providers must contain at least one child." }
        return DefaultSearchProviderSpec(SearchProviderDescription.Merge(children))
    }
}

private class DefaultHttpJsonSearchScope<Row> : HttpJsonSearchScope<Row> {
    override val query = Expr<String, Handled>(ExpressionNode.Read(SEARCH_QUERY, ValuePath()))
    private var uri: ExpressionNode? = null
    private val parameters = mutableListOf<HttpParameter>()
    private var resultPath: String? = null
    private var resultType: TypeTemplate? = null
    private val contexts = mutableListOf<HttpContext>()
    private var timeout = Duration.parse("10s")

    override fun uri(value: Expr<String, Handled>) {
        uri = value.node
    }

    override fun parameter(
        name: String,
        value: Expr<String, Handled>,
        omitIfEmpty: Boolean,
    ) {
        require(name.isNotBlank()) { "HTTP search parameter name must not be blank." }
        parameters += HttpParameter(name, value.node, omitIfEmpty)
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
        return Expr(ExpressionNode.Read(binding, ValuePath()))
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
