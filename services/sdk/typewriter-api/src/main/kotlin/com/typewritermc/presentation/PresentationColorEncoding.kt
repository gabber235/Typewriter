package com.typewritermc.presentation

import skirout.editor.v1.presentation.PresentationStateColorRule
import skirout.editor.v1.presentation.PresentationColor as WireColor

internal fun PresentationColor.wire(state: PresentationBuildState): WireColor =
    when (this) {
        is PresentationColor.Value -> {
            WireColor.ValueWrapper(state.lower(expression, COLOR_SLOT))
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
                source = source.wire(state),
                mode = mode,
            )
        }

        is PresentationColor.Alpha -> {
            WireColor.createAlpha(source = source.wire(state), alpha = alpha)
        }

        is PresentationColor.Blend -> {
            WireColor.createBlend(foreground = foreground.wire(state), background = background.wire(state))
        }

        is PresentationColor.States -> {
            WireColor.createStates(
                rules = rules.map { rule -> PresentationStateColorRule(match = rule.match, color = rule.color.wire(state)) },
                fallback = fallback.wire(state),
            )
        }

        is PresentationColor.Adjusted -> {
            WireColor.createAdjusted(source = source.wire(state), lightness = lightness, chroma = chroma)
        }

        is PresentationColor.Brightness -> {
            WireColor.createBrightness(light = light.wire(state), dark = dark.wire(state))
        }
    }
