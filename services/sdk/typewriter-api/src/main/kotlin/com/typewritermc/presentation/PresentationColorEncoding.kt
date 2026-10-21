package com.typewritermc.presentation

import skirout.editor.v1.presentation.PresentationAmbientColor
import skirout.editor.v1.presentation.PresentationContrastMode
import skirout.editor.v1.presentation.PresentationStateColorRule
import skirout.editor.v1.presentation.PresentationThemeColor
import skirout.editor.v1.presentation.PresentationColor as WireColor

internal fun PresentationColor.wire(): WireColor =
    when (this) {
        is PresentationColor.Value -> {
            WireColor.ValueWrapper(expression(expression))
        }

        is PresentationColor.Theme -> {
            WireColor.ThemeWrapper(
                role,
            )
        }

        is PresentationColor.Ambient -> {
            WireColor.AmbientWrapper(
                role,
            )
        }

        is PresentationColor.Contrast -> {
            WireColor.createContrast(
                source = source.wire(),
                mode = mode,
            )
        }

        is PresentationColor.Alpha -> {
            WireColor.createAlpha(source = source.wire(), alpha = alpha)
        }

        is PresentationColor.Blend -> {
            WireColor.createBlend(foreground = foreground.wire(), background = background.wire())
        }

        is PresentationColor.States -> {
            WireColor.createStates(
                rules = rules.map { rule -> PresentationStateColorRule(match = rule.match, color = rule.color.wire()) },
                fallback = fallback.wire(),
            )
        }

        is PresentationColor.Adjusted -> {
            WireColor.createAdjusted(source = source.wire(), lightness = lightness, chroma = chroma)
        }

        is PresentationColor.Brightness -> {
            WireColor.createBrightness(light = light.wire(), dark = dark.wire())
        }
    }
