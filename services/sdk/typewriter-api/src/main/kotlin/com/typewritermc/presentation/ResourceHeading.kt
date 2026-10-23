package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.expression.shortcuts.neq
import com.typewritermc.types.Color
import com.typewritermc.types.text
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.PresentationTextOverflow
import skirout.editor.v1.presentation.PresentationTextTone

/**
 * Composes resource identity using ordinary presentation nodes.
 * The entire composition is hidden for multiple selection. Outside a selection
 * surface, missing selection context defaults to one. Color belongs to the caller; the identifier defaults to the
 * presented resource's own id.
 */
fun Layout.resourceHeading(
    title: Expr<String, Handled>,
    color: Expr<Color, Handled>,
    identifier: Expr<String, MayBeMissing>? = subject.identifier.text,
    selectionCount: Expr<Int, MayBeMissing> = context.read(EditorContext.selectionCount),
) {
    showIf(selectionCount.orElse(literal(1)) eq literal(1)) {
        column(spacing = Spacing(8.0), cross = CrossAxisAlignment.STRETCH) {
            text(
                title,
                style =
                    TextStyle(
                        color = color.asPresentationColor(),
                        weight = FontWeight(700),
                        sizing = TextSizing.Fit(literal(18.0), literal(40.0)),
                    ),
                paragraph = textParagraph(maxLines = 1, overflow = PresentationTextOverflow.ELLIPSIS, selectable = true),
            )
            if (identifier != null) {
                val value = identifier.orElse(literal(""))
                showIf(value neq literal("")) {
                    text(
                        value,
                        style = TextStyle(sizing = TextSizing.Exact(literal(12.0))),
                        paragraph = textParagraph(softWrap = true, selectable = true, tone = PresentationTextTone.SECONDARY),
                    )
                }
            }
        }
    }
}
