package com.typewritermc.elements

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.IconOptions
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationAlignment
import com.typewritermc.presentation.PresentationBorder
import com.typewritermc.presentation.PresentationInsets
import com.typewritermc.presentation.PresentationInteractionState.Focused
import com.typewritermc.presentation.PresentationInteractionState.Selected
import com.typewritermc.presentation.PresentationRadius
import com.typewritermc.presentation.PresentationTransition
import com.typewritermc.presentation.TextOverflow
import com.typewritermc.presentation.TextParagraph
import com.typewritermc.presentation.TextSizing
import com.typewritermc.presentation.TextStyle
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.icon
import com.typewritermc.presentation.literalColor
import com.typewritermc.presentation.monochromeOn
import com.typewritermc.presentation.on
import com.typewritermc.presentation.stateColor
import com.typewritermc.presentation.stateTransition
import com.typewritermc.types.Color
import com.typewritermc.types.Icon

/** Displays an entry identity with a fixed inset frame and an icon at compact widths. */
fun Layout.entryNode(
    title: Expr<String, Handled>,
    icon: Expr<Icon, Handled>,
    accent: Expr<Color, Handled>,
) {
    val fill = accent.asPresentationColor()
    val outline =
        stateColor(fill) {
            whenAll(Focused, color = literalColor(Color(0xffffffffu)))
            whenAll(Selected, color = fill.on())
        }
    container(
        ContainerStyle(
            background = fill,
            foreground = fill.monochromeOn(),
            radius = PresentationRadius.Medium,
        ),
    ) {
        padding(PresentationInsets(4.0, 4.0, 4.0, 4.0)) {
            container(
                ContainerStyle(
                    border = PresentationBorder.All(width = 3.0, color = outline),
                    radius = PresentationRadius.Small,
                    transition = stateTransition(PresentationTransition(milliseconds = 400)),
                ),
            ) {
                adaptiveLeading {
                    padding(PresentationInsets(12.0, 8.0, 12.0, 8.0))
                    compactPadding(PresentationInsets(4.0, 4.0, 4.0, 4.0))
                    leading { icon(icon, IconOptions(size = 18.0)) }
                    center {
                        align(PresentationAlignment.Center) {
                            text(
                                title,
                                TextStyle(sizing = TextSizing.Exact(literal(13.0))),
                                TextParagraph(maximumLines = 1, overflow = TextOverflow.Ellipsis),
                            )
                        }
                    }
                }
            }
        }
    }
}
