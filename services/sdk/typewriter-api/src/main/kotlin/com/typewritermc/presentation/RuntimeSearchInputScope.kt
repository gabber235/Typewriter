package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode

internal class RuntimeSearchInputScope<Value, Row>(
    private val state: PresentationBuildState,
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
    private val state: PresentationBuildState,
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
