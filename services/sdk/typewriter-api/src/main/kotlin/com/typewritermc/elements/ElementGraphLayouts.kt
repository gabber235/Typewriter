package com.typewritermc.elements

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.DisplayDelay
import com.typewritermc.presentation.IconOptions
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationBorder
import com.typewritermc.presentation.PresentationInsets
import com.typewritermc.presentation.PresentationRadius
import com.typewritermc.presentation.Spacing
import com.typewritermc.presentation.TextSizing
import com.typewritermc.presentation.TextStyle
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.icon
import com.typewritermc.presentation.literalColor
import com.typewritermc.presentation.monochromeOn
import com.typewritermc.presentation.on
import com.typewritermc.presentation.stateColor
import com.typewritermc.presentation.stateTransition
import com.typewritermc.presentation.textParagraph
import com.typewritermc.presentation.transition
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationInteractionState.FOCUSED
import skirout.editor.v1.presentation.PresentationInteractionState.SELECTED
import skirout.editor.v1.presentation.PresentationTextOverflow

/** Displays an entry identity with a fixed inset frame and an icon at compact widths. */
fun Layout.entryNode(
    title: Expr<String, Handled>,
    icon: Expr<Icon, Handled>,
    accent: Expr<Color, Handled>,
) {
    val fill = accent.asPresentationColor()
    val outline =
        stateColor(fill) {
            whenAll(FOCUSED, color = literalColor(Color(0xffffffffu)))
            whenAll(SELECTED, color = fill.on())
        }
    container(
        ContainerStyle(
            background = fill,
            foreground = fill.monochromeOn(),
            radius = PresentationRadius.Medium,
        ),
    ) {
        padding(PresentationInsets.all(Spacing(4.0))) {
            container(
                ContainerStyle(
                    border = PresentationBorder.All(width = 3.0, color = outline),
                    radius = PresentationRadius.Small,
                    transition = stateTransition(transition(DisplayDelay(400))),
                ),
            ) {
                adaptiveLeading {
                    padding(PresentationInsets(Spacing(12.0), Spacing(8.0), Spacing(12.0), Spacing(8.0)))
                    compactPadding(PresentationInsets.all(Spacing(4.0)))
                    leading { icon(icon, IconOptions(size = 18.0)) }
                    center {
                        align(PresentationAlignment.CENTER) {
                            text(
                                title,
                                TextStyle(sizing = TextSizing.Exact(literal(13.0))),
                                textParagraph(maxLines = 1, overflow = PresentationTextOverflow.ELLIPSIS),
                            )
                        }
                    }
                }
            }
        }
    }
}
