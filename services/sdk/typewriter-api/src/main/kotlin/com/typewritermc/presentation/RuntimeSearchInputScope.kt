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
    private val author: RuntimePresentationBuildScope,
    private val common: InputConfigurationDraft = InputConfigurationDraft(),
) : SearchInputScope<Value, Row>,
    TextEntryAppearanceScope by common.appearance(),
    InputContentScope by common.content(state, author),
    PopupAppearanceScope by common.popup() {
    override val query = Expr<String, Handled>(ExpressionNode.Read(SEARCH_QUERY, ValuePath()))
    override val sources: SearchSources = SearchSources
    private val selectors = mutableListOf<skirout.editor.v1.presentation.SearchSelectorDefinition>()
    private var result: skirout.editor.v1.presentation.SearchResultMapping? = null
    private var summary: PresentationNode? = null
    private var initialQuery: skirout.editor.v1.expression.ExpressionNode? = null
    private var customValue: skirout.editor.v1.expression.ExpressionNode? = null
    private var selectionMode = SearchSelectionMode.Single
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
        summary = author.presentation(body)
    }

    override fun initialQuery(value: Expr<String, Handled>) {
        initialQuery = expression(value)
    }

    override fun customValue(value: Expr<Value, Handled>) {
        customValue = expression(value)
    }

    override fun initialQuery(value: String) {
        initialQuery = expression(value)
    }

    override fun popupSide(value: PopupSide) {
        popupSide =
            when (value) {
                PopupSide.Automatic -> skirout.editor.v1.presentation.PopupSide.AUTOMATIC
                PopupSide.Above -> skirout.editor.v1.presentation.PopupSide.ABOVE
                PopupSide.Below -> skirout.editor.v1.presentation.PopupSide.BELOW
            }
    }

    override fun emptyText(value: String) {
        emptyText = expression(value)
    }

    override fun emptyText(value: Expr<String, Handled>) {
        emptyText = expression(value)
    }

    override fun loadingText(value: String) {
        loadingText = expression(value)
    }

    override fun loadingText(value: Expr<String, Handled>) {
        loadingText = expression(value)
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

    fun element(control: BoundControl): PresentationElement {
        val mapping = requireNotNull(result) { "Search input must declare its result mapping." }
        val source = requireNotNull(provider) { "Search input must declare a provider." }
        val frozen = common.freeze()
        return PresentationElement.createSearchInput(
            control = control,
            selectionMode = selectionMode.wire(),
            queryBindingId = SEARCH_QUERY.wire(),
            summaryBindingId = ExpressionBindingId("search_summary").wire(),
            maximumExtent = frozen.popup.maximumExtent ?: expression(400.0),
            provider = source.wire(state, mapping, selectors),
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
) : SearchResultScope<Value, Row> {
    override val row = Expr<Row, Handled>(ExpressionNode.Read(SEARCH_RESULT_ROW, ValuePath()))
    private var key: skirout.editor.v1.expression.ExpressionNode? = null
    private var selectedValue: skirout.editor.v1.expression.ExpressionNode? = null
    private var presentation: PresentationNode? = null
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var appearance: skirout.editor.v1.presentation.ResultAppearance? = null

    override fun key(value: Expr<*, out com.typewritermc.expression.MissingPolicy>) {
        key = expression(value)
    }

    override fun selectedValue(value: Expr<Value, out com.typewritermc.expression.MissingPolicy>) {
        selectedValue = expression(value)
    }

    override fun presentation(body: Layout.() -> Unit) {
        check(presentation == null) { "Search result presentation may be declared once." }
        val captured = state.captureResult { scope -> scope.body() }
        presentation = captured.nodes.singleOrNull() ?: state.column(captured.nodes)
        appearance = captured.appearance
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
            resultAppearance = appearance,
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
