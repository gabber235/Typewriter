package com.typewritermc.presentation

import com.typewritermc.capability.RealmSearchCapabilityRef
import com.typewritermc.types.Icon
import kotlin.reflect.KClass
import kotlin.reflect.KProperty1

/** A typed result field used when an external search value becomes an editable record. */
class SearchRecordField<T : Any> internal constructor(
    internal val name: String,
    internal val value: PresentationExpression<*>,
)

data class SearchQueryParameter internal constructor(
    val name: String,
    val value: PresentationExpression<String>,
    val omitIfEmpty: Boolean,
)

/** An immutable search source tree. Decorators retain the result type of their child. */
sealed interface SearchProviderSpec<R : Any> {
    data class HttpJson<R : Any>(
        val uri: String,
        val parameters: List<SearchQueryParameter>,
        val resultPath: String,
        val timeoutMillis: Long,
    ) : SearchProviderSpec<R>

    data class StaticValues<R : Any>(
        val values: List<R>,
    ) : SearchProviderSpec<R>

    data class RealmCallback<R : Any>(
        val capability: RealmSearchCapabilityRef<*, R>,
        val payload: PresentationExpression<*>,
    ) : SearchProviderSpec<R>

    data class Decorated<R : Any>(
        val operation: SearchDecoration,
        val child: SearchProviderSpec<R>,
    ) : SearchProviderSpec<R>

    data class Merged<R : Any>(
        val children: List<SearchProviderSpec<R>>,
    ) : SearchProviderSpec<R>
}

sealed interface SearchDecoration {
    data class Gate(
        val condition: PresentationExpression<Boolean>,
        val guidance: String?,
    ) : SearchDecoration

    data class Debounce(
        val milliseconds: Long,
    ) : SearchDecoration

    data class Rank(
        val fields: List<Pair<PresentationExpression<String>, Int>>,
    ) : SearchDecoration

    data class Limit(
        val maximum: Int,
    ) : SearchDecoration

    data class Cache(
        val capacity: Int,
        val retainStaleResults: Boolean,
    ) : SearchDecoration

    data class History(
        val key: String,
        val label: String,
        val capacity: Int,
    ) : SearchDecoration

    data class Section(
        val id: String,
        val label: String,
    ) : SearchDecoration

    data object Distinct : SearchDecoration
}

fun <R : Any> SearchProviderSpec<R>.gate(
    condition: PresentationExpression<Boolean>,
    guidance: String? = null,
): SearchProviderSpec<R> = SearchProviderSpec.Decorated(SearchDecoration.Gate(condition, guidance), this)

fun <R : Any> SearchProviderSpec<R>.debounce(milliseconds: Long): SearchProviderSpec<R> {
    require(milliseconds >= 0)
    return SearchProviderSpec.Decorated(SearchDecoration.Debounce(milliseconds), this)
}

fun <R : Any> SearchProviderSpec<R>.rank(vararg fields: Pair<PresentationExpression<String>, Int>): SearchProviderSpec<R> {
    require(fields.isNotEmpty())
    return SearchProviderSpec.Decorated(SearchDecoration.Rank(fields.toList()), this)
}

fun <R : Any> SearchProviderSpec<R>.limit(maximum: Int): SearchProviderSpec<R> {
    require(maximum > 0)
    return SearchProviderSpec.Decorated(SearchDecoration.Limit(maximum), this)
}

fun <R : Any> SearchProviderSpec<R>.cache(
    capacity: Int,
    retainStaleResults: Boolean = false,
): SearchProviderSpec<R> {
    require(capacity > 0)
    return SearchProviderSpec.Decorated(SearchDecoration.Cache(capacity, retainStaleResults), this)
}

fun <R : Any> SearchProviderSpec<R>.history(
    key: String,
    label: String,
    capacity: Int,
): SearchProviderSpec<R> {
    require(key.isNotBlank() && capacity > 0)
    return SearchProviderSpec.Decorated(SearchDecoration.History(key, label, capacity), this)
}

fun <R : Any> SearchProviderSpec<R>.section(
    id: String,
    label: String,
): SearchProviderSpec<R> {
    require(id.isNotBlank())
    return SearchProviderSpec.Decorated(SearchDecoration.Section(id, label), this)
}

fun <R : Any> SearchProviderSpec<R>.distinct(): SearchProviderSpec<R> = SearchProviderSpec.Decorated(SearchDecoration.Distinct, this)

internal sealed interface SearchLayout {
    data class Text(
        val value: PresentationExpression<String>,
    ) : SearchLayout

    data class Icon(
        val value: PresentationExpression<out com.typewritermc.types.Icon>,
    ) : SearchLayout

    data class Axis(
        val row: Boolean,
        val spacing: Double,
        val children: List<SearchAxisChild>,
    ) : SearchLayout
}

internal data class SearchAxisChild(
    val layout: SearchLayout,
    val flex: Int?,
)

/** Layout shared by result and selected-value previews. */
@PresentationDsl
class SearchLayoutBuilder internal constructor() {
    private val children = mutableListOf<SearchAxisChild>()

    fun text(value: PresentationExpression<String>) {
        children += SearchAxisChild(SearchLayout.Text(value), null)
    }

    fun icon(value: PresentationExpression<out Icon>) {
        children += SearchAxisChild(SearchLayout.Icon(value), null)
    }

    fun row(
        spacing: Double = 0.0,
        block: SearchLayoutBuilder.() -> Unit,
    ) {
        children += SearchAxisChild(SearchLayoutBuilder().apply(block).axis(true, spacing), null)
    }

    fun column(
        spacing: Double = 0.0,
        block: SearchLayoutBuilder.() -> Unit,
    ) {
        children += SearchAxisChild(SearchLayoutBuilder().apply(block).axis(false, spacing), null)
    }

    fun fixed(block: SearchLayoutBuilder.() -> Unit) {
        children += SearchAxisChild(SearchLayoutBuilder().apply(block).axis(false, 0.0), null)
    }

    fun flexible(
        flex: Int = 1,
        block: SearchLayoutBuilder.() -> Unit,
    ) {
        require(flex > 0)
        children += SearchAxisChild(SearchLayoutBuilder().apply(block).axis(false, 0.0), flex)
    }

    internal fun axis(
        row: Boolean = false,
        spacing: Double = 0.0,
    ): SearchLayout.Axis {
        require(spacing.isFinite() && spacing >= 0.0)
        return SearchLayout.Axis(row, spacing, children.toList())
    }
}

internal data class SearchResultSpec<V : Any>(
    val key: PresentationExpression<String>,
    val selectedValue: PresentationExpression<V>,
    val label: PresentationExpression<String>,
    val presentation: SearchLayout,
)

internal data class AuthoredSearchInput<V : Any, R : Any>(
    val value: PresentationValue<V>,
    val resultType: KClass<R>,
    val placeholder: String?,
    val label: String?,
    val maximumExtent: Int,
    val result: SearchResultSpec<V>,
    val summary: SearchLayout?,
    val customValue: PresentationExpression<V>?,
    val provider: SearchProviderSpec<R>,
)

/** Declares one search control while keeping query, candidate, and summary bindings scoped to it. */
@PresentationDsl
class SearchInputBuilder<Value : Any, Result : Any> internal constructor(
    private val context: PresentationBuildContext,
    private val resultType: KClass<Result>,
    valueType: KClass<Value>,
) {
    val query =
        PresentationExpression(String::class, AuthoredExpression.ScopedBinding(AuthoredExpression.SearchBinding.QUERY, String::class))
    val candidate =
        PresentationExpression(resultType, AuthoredExpression.ScopedBinding(AuthoredExpression.SearchBinding.CANDIDATE, resultType))
    val summaryValue =
        PresentationExpression(valueType, AuthoredExpression.ScopedBinding(AuthoredExpression.SearchBinding.SUMMARY, valueType))

    private var result: SearchResultSpec<Value>? = null
    private var summary: SearchLayout? = null
    private var customValue: PresentationExpression<Value>? = null
    private var provider: SearchProviderSpec<Result>? = null

    fun literal(value: String): PresentationExpression<String> = PresentationExpression(String::class, AuthoredExpression.Literal(value))

    fun parameter(
        name: String,
        value: PresentationExpression<String>,
        omitIfEmpty: Boolean = false,
    ): SearchQueryParameter {
        require(name.isNotBlank())
        return SearchQueryParameter(name, value, omitIfEmpty)
    }

    fun <T : Any, F : Any> field(
        type: KClass<T>,
        property: KProperty1<T, F>,
        value: PresentationExpression<F>,
    ): SearchRecordField<T> = SearchRecordField(context.field(type, property.name).serializedName, value)

    @Suppress("UNCHECKED_CAST")
    fun <T : Any, F : Any> PresentationExpression<T>.field(property: KProperty1<T, F>): PresentationExpression<F> {
        val fieldType = property.returnType.classifier as KClass<F>
        return PresentationExpression(
            fieldType,
            AuthoredExpression.Field(authored, context.field(type, property.name).serializedName, fieldType),
        )
    }

    fun <T : Any> record(
        type: KClass<T>,
        vararg fields: SearchRecordField<T>,
    ): PresentationExpression<T> {
        require(fields.map { it.name }.distinct().size == fields.size) { "Record expression fields must be unique." }
        return PresentationExpression(type, AuthoredExpression.Record(type, fields.associate { it.name to it.value.authored }))
    }

    fun result(
        key: PresentationExpression<String>,
        selectedValue: PresentationExpression<Value>,
        label: PresentationExpression<String>,
        presentation: SearchLayoutBuilder.() -> Unit,
    ) {
        check(result == null) { "Search result mapping is already declared." }
        result = SearchResultSpec(key, selectedValue, label, SearchLayoutBuilder().apply(presentation).axis())
    }

    fun summary(presentation: SearchLayoutBuilder.() -> Unit) {
        summary = SearchLayoutBuilder().apply(presentation).axis()
    }

    fun customValue(value: PresentationExpression<Value>) {
        customValue = value
    }

    fun httpJson(
        uri: String,
        resultPath: String,
        timeoutMillis: Long,
        parameters: List<SearchQueryParameter>,
    ): SearchProviderSpec<Result> {
        require(uri.startsWith("https://") && resultPath.isNotBlank() && timeoutMillis > 0)
        require(parameters.map { it.name }.distinct().size == parameters.size) { "HTTP search parameter names must be unique." }
        return SearchProviderSpec.HttpJson(uri, parameters, resultPath, timeoutMillis)
    }

    fun staticValues(values: List<Result>): SearchProviderSpec<Result> {
        require(resultType == String::class) { "Static search values currently support string results." }
        return SearchProviderSpec.StaticValues(values)
    }

    fun <Context : Any> realmCallback(
        capability: RealmSearchCapabilityRef<Context, Result>,
        payload: PresentationExpression<Context>,
    ): SearchProviderSpec<Result> = SearchProviderSpec.RealmCallback(capability, payload)

    fun merge(vararg providers: SearchProviderSpec<Result>): SearchProviderSpec<Result> {
        require(providers.isNotEmpty())
        return SearchProviderSpec.Merged(providers.toList())
    }

    fun provider(source: SearchProviderSpec<Result>) {
        check(provider == null) { "Search provider is already declared." }
        provider = source
    }

    internal fun build(
        value: PresentationValue<Value>,
        placeholder: String?,
        label: String?,
        maximumExtent: Int,
    ): AuthoredSearchInput<Value, Result> {
        require(value.input.editable) { "Search input requires an editable value." }
        require(maximumExtent > 0)
        return AuthoredSearchInput(
            value,
            resultType,
            placeholder,
            label,
            maximumExtent,
            checkNotNull(result) { "Search result mapping is required." },
            summary,
            customValue,
            checkNotNull(provider) { "Search provider is required." },
        )
    }
}
