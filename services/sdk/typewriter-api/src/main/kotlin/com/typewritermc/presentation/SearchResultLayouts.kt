package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.Color

fun Layout.searchTitle(value: Expr<String, Handled>) {
    text(
        value = value,
        style = TextStyle(sizing = TextSizing.Exact(literal(14.0)), weight = 500, lineHeight = 1.1),
        paragraph =
            TextParagraph(
                maximumLines = 1,
                overflow = TextOverflow.Ellipsis,
            ),
    )
}

fun Layout.searchDescription(value: Expr<String, Handled>) {
    text(
        value = value,
        style = TextStyle(sizing = TextSizing.Exact(literal(12.0)), weight = 400, lineHeight = 1.2),
        paragraph =
            TextParagraph(
                maximumLines = 1,
                overflow = TextOverflow.Ellipsis,
                tone = TextTone.Secondary,
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
                PresentationInteractionState.Focused,
                PresentationInteractionState.Selected,
                color = contrast.withAlpha(0.90).over(surface),
            )
            whenAll(
                PresentationInteractionState.Focused,
                color = contrast.withAlpha(0.55).over(surface),
            )
            whenAll(
                PresentationInteractionState.Selected,
                color = accent.withAlpha(0.72).over(surface),
            )
        }
    val foreground =
        stateColor(accent) {
            whenAll(PresentationInteractionState.Focused, color = accent)
            whenAll(PresentationInteractionState.Selected, color = contrast)
        }
    container(
        ContainerStyle(
            background = background,
            foreground = foreground,
            radius = PresentationRadius.Custom(literal(1000.0)),
            transitionMilliseconds = 300,
        ),
    ) {
        padding(PresentationInsets(7.0, 3.0, 7.0, 3.0)) {
            text(
                value = label,
                style = TextStyle(sizing = TextSizing.Exact(literal(10.0)), weight = 400),
                paragraph = TextParagraph(maximumLines = 1, overflow = TextOverflow.Ellipsis),
            )
        }
    }
}

fun Layout.resourceSearchResult(
    title: Expr<String, Handled>,
    accent: Expr<Color, Handled>,
    kind: Expr<String, Handled>,
    icon: Layout.() -> Unit,
    details: Layout.() -> Unit = {},
) {
    val resultAccent = accent
    val resultIcon = icon
    searchResult {
        appearance(SearchResultAppearance.Card)
        accent(resultAccent)
        kindLabel(kind)
        leading(resultIcon)
        column(spacing = 4.0, cross = CrossAxisAlignment.Start) {
            searchTitle(title)
            details()
        }
    }
}
