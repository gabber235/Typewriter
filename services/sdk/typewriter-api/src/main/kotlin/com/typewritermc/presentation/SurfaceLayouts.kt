package com.typewritermc.presentation

import com.typewritermc.presentation.PresentationCurve.ElasticOut
import com.typewritermc.presentation.PresentationCurve.Emphasized
import com.typewritermc.presentation.PresentationInteractionState.Focused
import com.typewritermc.presentation.PresentationInteractionState.Hovered
import com.typewritermc.presentation.PresentationInteractionState.Selected

/** Springs into the selected state and eases back out of it: the motion of cards that react to being picked. */
val selectMotion: PresentationTransitionPolicy =
    stateTransition(fallback = PresentationTransition(milliseconds = 300, curve = Emphasized)) {
        whenAll(Selected, transition = PresentationTransition(milliseconds = 750, curve = ElasticOut(period = 0.9)))
    }

/** Grows and tilts [body] slightly while it is hovered. */
fun Layout.hoverLift(body: Layout.() -> Unit) =
    transform(
        TransformStyle(
            scale = stateNumber(fallback = 1.0) { whenAll(Hovered, value = 1.05) },
            rotateZ = stateNumber(fallback = 0.0) { whenAll(Hovered, value = 0.005) },
            transition = selectMotion,
        ),
        body,
    )

/** Outlines [body] in [accent] while it has keyboard focus. */
fun Layout.focusRing(
    accent: PresentationColor,
    body: Layout.() -> Unit,
) = container(
    ContainerStyle(
        border =
            PresentationBorder.All(
                width = 2.0,
                color = stateColor(accent.withAlpha(0.0)) { whenAll(Focused, color = accent) },
            ),
        radius = PresentationRadius.Large,
        transition = stateTransition(PresentationTransition(milliseconds = 120)),
    ),
    body,
)

/**
 * A standing volume of [width] by [height] logical pixels: spine layers in [accent] that fan out on selection behind
 * a cover that tilts open. [cover] fills the cover inside its margins, so any resource type can stand as a volume.
 */
fun Layout.stackedCard(
    accent: PresentationColor,
    width: Double,
    height: Double,
    cover: Layout.() -> Unit,
) {
    size(width = width, height = height) {
        stack {
            SPINE_LAYERS.forEach { layer -> spineLayer(accent, layer) }
            fill {
                transform(
                    TransformStyle(
                        origin = PresentationAlignment.CenterStart,
                        perspective = 0.002,
                        rotateY = stateNumber(fallback = 0.0) { whenAll(Selected, value = 0.05) },
                        scale = stateNumber(fallback = 1.0) { whenAll(Selected, value = 0.9) },
                        transition = selectMotion,
                    ),
                ) {
                    cardCover(accent, cover)
                }
            }
        }
    }
}

/**
 * One page edge behind the cover. Insets are logical pixels at rest and when selected; lightness moves the accent in
 * OkLch per editor brightness.
 */
private data class SpineLayer(
    val rest: Double,
    val raised: Double,
    val restEnd: Double,
    val raisedEnd: Double,
    val light: Double,
    val dark: Double,
)

private val SPINE_LAYERS =
    listOf(
        SpineLayer(rest = 10.0, raised = 15.0, restEnd = 0.0, raisedEnd = 0.0, light = 0.1, dark = -0.3),
        SpineLayer(rest = 5.0, raised = 12.0, restEnd = 5.0, raisedEnd = 4.0, light = 0.3, dark = -0.1),
        SpineLayer(rest = 5.0, raised = 10.0, restEnd = 5.0, raisedEnd = 8.0, light = 0.3, dark = 0.0),
        SpineLayer(rest = 5.0, raised = 5.0, restEnd = 5.0, raisedEnd = 14.0, light = 0.3, dark = 0.1),
    )

private fun StackLayout.spineLayer(
    accent: PresentationColor,
    layer: SpineLayer,
) {
    val edge = stateNumber(fallback = layer.rest) { whenAll(Selected, value = layer.raised) }
    positioned(
        top = edge,
        bottom = edge,
        end = stateNumber(fallback = layer.restEnd) { whenAll(Selected, value = layer.raisedEnd) },
        width = number(30.0),
        transition = selectMotion,
    ) {
        container(
            ContainerStyle(
                radius = PresentationRadius.Large,
                background =
                    brightnessColor(
                        light = accent.adjusted(lightness = layer.light, chroma = -0.3),
                        dark = accent.adjusted(lightness = layer.dark, chroma = -0.3),
                    ),
            ),
        ) {}
    }
}

/** The accent cover with a darker binding strip along its start edge; [content] sits inside its margins. */
private fun Layout.cardCover(
    accent: PresentationColor,
    content: Layout.() -> Unit,
) {
    stack {
        positioned(top = number(0.0), start = number(0.0), bottom = number(0.0), end = number(10.0)) {
            container(ContainerStyle(background = accent, foreground = accent.monochromeOn(), radius = PresentationRadius.Large)) {
                padding(PresentationInsets(start = 24.0, top = 10.0, end = 10.0, bottom = 10.0), content)
            }
        }
        positioned(top = number(0.0), start = number(0.0), bottom = number(0.0), width = number(16.0)) {
            container(
                ContainerStyle(
                    radius = PresentationRadius.Large,
                    background =
                        brightnessColor(
                            light = accent.adjusted(lightness = -0.2, chroma = -0.2),
                            dark = accent.adjusted(lightness = -0.3, chroma = -0.3),
                        ),
                ),
            ) {}
        }
    }
}
