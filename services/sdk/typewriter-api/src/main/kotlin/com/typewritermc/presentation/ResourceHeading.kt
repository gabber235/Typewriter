package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.expression.neq
import com.typewritermc.expression.orElse
import com.typewritermc.types.Color

/**
 * Composes resource identity using ordinary presentation nodes.
 * The entire composition is hidden for multiple selection. Outside a selection
 * surface, missing selection context defaults to one. Color belongs to the caller.
 */
fun Layout.resourceHeading(
    title: Expr<String, Handled>,
    color: Expr<Color, Handled>,
    identifier: Expr<String, MayBeMissing>? = null,
    selectionCount: Expr<Int, MayBeMissing> = context.selectionCount,
) {
    showIf(selectionCount.orElse(literal(1)) eq literal(1)) {
        column(spacing = 8.0, cross = CrossAxisAlignment.Stretch) {
            text(
                title,
                style = TextStyle(color = color, weight = 700, sizing = TextSizing.Fit(literal(18.0), literal(40.0))),
                paragraph = TextParagraph(maximumLines = 1, overflow = TextOverflow.Ellipsis, selectable = true),
            )
            if (identifier != null) {
                val value = identifier.orElse(literal(""))
                showIf(value neq literal("")) {
                    text(
                        value,
                        style = TextStyle(sizing = TextSizing.Exact(literal(12.0))),
                        paragraph = TextParagraph(softWrap = true, selectable = true, tone = TextTone.Secondary),
                    )
                }
            }
        }
    }
}
