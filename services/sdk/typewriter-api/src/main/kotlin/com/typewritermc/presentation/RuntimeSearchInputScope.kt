@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.PopupSide
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.SearchSelectionMode
import skirout.editor.v1.presentation.SearchSelectorMultiplicity
import skirout.editor.v1.presentation.SearchSelectorValues
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.TypeTemplate

/** Binds the current value while the summary of a search input renders. */
private val SEARCH_SUMMARY = ExpressionBindingId(value = "search_summary")

/**
 * Captures one search input. It is configured while the query binding is declared, so every expression of the input
 * may read the query; selectors add their bindings to that scope. The result mapping is lowered once the provider
 * fixes the row type, with the result row bound.
 */
internal class RuntimeSearchInputScope<Value, Row>(
    private val state: PresentationBuildState,
    private val author: RuntimePresentationBuildScope,
    private val value: TypeTemplate,
    private val common: InputConfigurationDraft = InputConfigurationDraft(),
) : SearchInputScope<Value, Row>,
    TextEntryAppearanceScope by common.appearance(state),
    InputContentScope by common.content(state, author),
    PopupAppearanceScope by common.popup(state) {
    override val query = com.typewritermc.expression.inputExpression<String, Handled>(SEARCH_QUERY)
    override val sources: SearchSources = SearchSources
    private val selectors = mutableListOf<skirout.editor.v1.presentation.SearchSelectorDefinition>()
    private var result: (SearchResultScope<Value, Row>.() -> Unit)? = null
    private var summary: PresentationNode? = null
    private var initialQuery: skirout.editor.v1.expression.ExpressionNode? = null
    private var customValue: skirout.editor.v1.expression.ExpressionNode? = null
    private var selectionMode: SearchSelectionMode = SearchSelectionMode.SINGLE
    private var provider: DefaultSearchProviderSpec<Row>? = null
    private var popupSide: skirout.editor.v1.presentation.PopupSide = skirout.editor.v1.presentation.PopupSide.AUTOMATIC
    private var emptyText: skirout.editor.v1.expression.ExpressionNode? = null
    private var loadingText: skirout.editor.v1.expression.ExpressionNode? = null
    private var empty: PresentationNode? = null
    private var loading: PresentationNode? = null

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
                    val type = if (multiplicity == SearchSelectorMultiplicity.MULTIPLE) listSlot(TEXT_SLOT) else TEXT_SLOT
                    val binding = state.extendScope(ExpressionBindingId(value = "search_selector.$id"), type, mayBeMissing = false)
                    selectors +=
                        skirout.editor.v1.presentation.SearchSelectorDefinition(
                            selectorId = id,
                            key = key,
                            valueBinding = binding,
                            values = values,
                            caseSensitive = caseSensitive,
                            multiplicity = multiplicity,
                            color = color,
                        )
                    return com.typewritermc.expression.inputExpression(binding.id)
                }
            }
        scope.configure()
    }

    override fun result(configure: SearchResultScope<Value, Row>.() -> Unit) {
        check(result == null) { "Search input may declare one result mapping." }
        result = configure
    }

    override fun summary(body: Layout.() -> Unit) {
        summary = author.presentation(body)
    }

    override fun initialQuery(value: Expr<String, Handled>) {
        initialQuery = state.lower(value, TEXT_SLOT)
    }

    override fun customValue(value: Expr<Value, Handled>) {
        customValue = state.lower(value, this.value)
    }

    override fun initialQuery(value: String) {
        initialQuery = state.lower(literal(value), TEXT_SLOT)
    }

    override fun popupSide(value: PopupSide) {
        popupSide = value
    }

    override fun emptyText(value: String) {
        emptyText = state.lower(literal(value), TEXT_SLOT)
    }

    override fun emptyText(value: Expr<String, Handled>) {
        emptyText = state.lower(value, TEXT_SLOT)
    }

    override fun loadingText(value: String) {
        loadingText = state.lower(literal(value), TEXT_SLOT)
    }

    override fun loadingText(value: Expr<String, Handled>) {
        loadingText = state.lower(value, TEXT_SLOT)
    }

    override fun empty(body: Layout.() -> Unit) {
        empty = author.presentation(body)
    }

    override fun loading(body: Layout.() -> Unit) {
        loading = author.presentation(body)
    }

    override fun selectionMode(value: SearchSelectionMode) {
        selectionMode = value
    }

    override fun provider(source: SearchProviderSpec<Row>) {
        provider = source.runtime()
    }

    /** Lowers the provider and the result mapping; the query binding must still be declared as [query]. */
    fun finish(query: skirout.editor.v1.presentation.BindingDeclaration): (BoundControl) -> PresentationElement {
        val configureResult = requireNotNull(result) { "Search input must declare its result mapping." }
        val source = requireNotNull(provider) { "Search input must declare a provider." }
        val rowType = source.rowType(state)
        val mapping =
            state.declare(SEARCH_RESULT_ROW, rowType, mayBeMissing = false) { row ->
                RuntimeSearchResultScope<Value, Row>(state, value).apply(configureResult).build(row)
            }
        val wireProvider = source.wire(state, mapping, selectors, rowType)
        val maximumExtent = state.lower(literal(400.0), DOUBLE_SLOT)
        return { control -> element(control, query, wireProvider, maximumExtent) }
    }

    private fun element(
        control: BoundControl,
        query: skirout.editor.v1.presentation.BindingDeclaration,
        provider: skirout.editor.v1.presentation.SearchProvider,
        defaultExtent: ExpressionNode,
    ): PresentationElement {
        val frozen = common.freeze()
        return PresentationElement.createSearchInput(
            control = control,
            selectionMode = selectionMode,
            queryBinding = query,
            summaryBinding =
                skirout.editor.v1.presentation
                    .BindingDeclaration(id = SEARCH_SUMMARY, type = value),
            maximumExtent = frozen.popup.maximumExtent ?: defaultExtent,
            provider = provider,
            summary = summary,
            placeholder = frozen.content.placeholder,
            customValue = customValue,
            initialQuery = initialQuery,
            appearance = frozen.appearance,
            content = frozen.content,
            popup = frozen.popup,
            popupSide = popupSide,
            emptyText = emptyText,
            loadingText = loadingText,
            empty = empty,
            loading = loading,
        )
    }
}

private class RuntimeSearchResultScope<Value, Row>(
    private val state: PresentationBuildState,
    private val value: TypeTemplate,
) : SearchResultScope<Value, Row> {
    override val row = com.typewritermc.expression.inputExpression<Row, Handled>(SEARCH_RESULT_ROW)
    private var key: skirout.editor.v1.expression.ExpressionNode? = null
    private var selectedValue: skirout.editor.v1.expression.ExpressionNode? = null
    private var presentation: PresentationNode? = null
    private var label: skirout.editor.v1.expression.ExpressionNode? = null

    override fun key(value: Expr<*, out com.typewritermc.expression.MissingPolicy>) {
        key = state.lowerInferred(value).first
    }

    override fun selectedValue(value: Expr<Value, out com.typewritermc.expression.MissingPolicy>) {
        selectedValue = state.lower(value, this.value, mayBeMissing = true)
    }

    override fun presentation(body: Layout.() -> Unit) {
        check(presentation == null) { "Search result presentation may be declared once." }
        presentation = state.presentation(body)
    }

    override fun label(value: Expr<String, Handled>) {
        label = state.lower(value, TEXT_SLOT)
    }

    fun build(row: skirout.editor.v1.presentation.BindingDeclaration): skirout.editor.v1.presentation.SearchResultMapping =
        skirout.editor.v1.presentation.SearchResultMapping(
            binding = row,
            key = requireNotNull(key) { "Search result mapping must declare a key." },
            selectedValue = requireNotNull(selectedValue) { "Search result mapping must declare a selected value." },
            presentation = requireNotNull(presentation) { "Search result mapping must declare a presentation." },
            label = label,
        )
}
