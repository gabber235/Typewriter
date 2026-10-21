package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationTextOverflow
import skirout.editor.v1.presentation.PresentationTextTone

fun Layout.searchTitle(value: Expr<String, Handled>) {
    text(
        value = value,
        style = TextStyle(sizing = TextSizing.Exact(literal(14.0)), weight = 500, lineHeight = 1.1),
        paragraph =
            textParagraph(
                maxLines = 1,
                overflow = PresentationTextOverflow.ELLIPSIS,
            ),
    )
}

fun Layout.searchDescription(value: Expr<String, Handled>) {
    text(
        value = value,
        style = TextStyle(sizing = TextSizing.Exact(literal(12.0)), weight = 400, lineHeight = 1.2),
        paragraph =
            textParagraph(
                maxLines = 1,
                overflow = PresentationTextOverflow.ELLIPSIS,
                tone = PresentationTextTone.SECONDARY,
            ),
    )
}

fun Layout.searchChip(
    label: Expr<String, Handled>,
    accent: PresentationColor,
) {
    val surface = ambientBackground()
    val contrast = surface.monochromeOn()
    val background =
        stateColor(accent.withAlpha(0.30).over(surface)) {
            whenAll(
                PresentationInteractionState.FOCUSED,
                PresentationInteractionState.SELECTED,
                color = contrast.withAlpha(0.90).over(surface),
            )
            whenAll(
                PresentationInteractionState.FOCUSED,
                color = contrast.withAlpha(0.55).over(surface),
            )
            whenAll(
                PresentationInteractionState.SELECTED,
                color = accent.withAlpha(0.72).over(surface),
            )
        }
    val foreground =
        stateColor(accent) {
            whenAll(PresentationInteractionState.FOCUSED, color = accent)
            whenAll(PresentationInteractionState.SELECTED, color = contrast)
        }
    container(
        ContainerStyle(
            background = background,
            foreground = foreground,
            radius = PresentationRadius.Custom(literal(1000.0)),
            transition = stateTransition(transition(milliseconds = 300)),
        ),
    ) {
        padding(PresentationInsets(7.0, 3.0, 7.0, 3.0)) {
            text(
                value = label,
                style = TextStyle(sizing = TextSizing.Exact(literal(10.0)), weight = 400),
                paragraph = textParagraph(maxLines = 1, overflow = PresentationTextOverflow.ELLIPSIS),
            )
        }
    }
}
