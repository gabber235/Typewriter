package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Color
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.ResultAppearance
import skirout.editor.v1.presentation.ResultStyle

enum class SearchResultAppearance { Compact, Card }

/** Native result decoration, independent of the ordinary portable body. */
interface SearchResultLayout : Layout {
    fun appearance(value: SearchResultAppearance)

    fun accent(value: Expr<Color, Handled>)

    fun leading(body: Layout.() -> Unit)

    fun kindLabel(value: Expr<String, Handled>)
}

internal data class CapturedResultPresentation(
    val nodes: List<PresentationNode>,
    val appearance: ResultAppearance?,
)

internal class ResultPresentationDraft(
    val target: MutableList<PresentationNode>,
) {
    private var appearance: ResultAppearance? = null

    fun declare(value: ResultAppearance) {
        check(appearance == null) { "One result presentation may declare its appearance once." }
        appearance = value
    }

    fun finish() = CapturedResultPresentation(target.toList(), appearance)
}

internal class RuntimeSearchResultLayout(
    private val state: PresentationBuildState,
    layout: Layout,
) : SearchResultLayout,
    Layout by layout {
    private var style: SearchResultAppearance? = null
    private var accent: Expr<Color, Handled>? = null
    private var leading: PresentationNode? = null
    private var kind: Expr<String, Handled>? = null

    override fun appearance(value: SearchResultAppearance) {
        check(style == null) { "Result style may be declared once." }
        style = value
    }

    override fun accent(value: Expr<Color, Handled>) {
        check(accent == null) { "Result accent may be declared once." }
        accent = value
    }

    override fun leading(body: Layout.() -> Unit) {
        check(leading == null) { "Result leading content may be declared once." }
        leading = state.presentation(body)
    }

    override fun kindLabel(value: Expr<String, Handled>) {
        check(kind == null) { "Result kind label may be declared once." }
        kind = value
    }

    fun build() =
        ResultAppearance(
            style =
                when (style) {
                    SearchResultAppearance.Compact -> ResultStyle.COMPACT
                    SearchResultAppearance.Card -> ResultStyle.CARD
                    null -> null
                },
            accent = accent?.let(::expression),
            leading = leading,
            kindLabel = kind?.let(::expression),
        )
}
