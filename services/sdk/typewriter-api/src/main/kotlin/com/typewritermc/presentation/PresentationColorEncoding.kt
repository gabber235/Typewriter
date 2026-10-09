package com.typewritermc.presentation

import skirout.editor.v1.presentation.PresentationStateColorRule
import skirout.editor.v1.presentation.PresentationStateMatch
import skirout.editor.v1.presentation.PresentationAmbientColor as WireAmbient
import skirout.editor.v1.presentation.PresentationColor as WireColor
import skirout.editor.v1.presentation.PresentationContrastMode as WireContrast
import skirout.editor.v1.presentation.PresentationInteractionState as WireState
import skirout.editor.v1.presentation.PresentationThemeColor as WireTheme

internal fun PresentationColor.wire(): WireColor =
    when (this) {
        is PresentationColor.Value -> {
            WireColor.ValueWrapper(expression(expression))
        }

        is PresentationColor.Theme -> {
            WireColor.ThemeWrapper(
                when (role) {
                    PresentationThemeColor.Primary -> WireTheme.PRIMARY
                    PresentationThemeColor.OnPrimary -> WireTheme.ON_PRIMARY
                    PresentationThemeColor.Surface -> WireTheme.SURFACE
                    PresentationThemeColor.OnSurface -> WireTheme.ON_SURFACE
                    PresentationThemeColor.OnSurfaceVariant -> WireTheme.ON_SURFACE_VARIANT
                    PresentationThemeColor.FocusOutline -> WireTheme.FOCUS_OUTLINE
                },
            )
        }

        is PresentationColor.Ambient -> {
            WireColor.AmbientWrapper(
                when (role) {
                    PresentationAmbientColor.Background -> WireAmbient.BACKGROUND
                    PresentationAmbientColor.Foreground -> WireAmbient.FOREGROUND
                    PresentationAmbientColor.SecondaryForeground -> WireAmbient.SECONDARY_FOREGROUND
                },
            )
        }

        is PresentationColor.Contrast -> {
            WireColor.createContrast(
                source = source.wire(),
                mode =
                    when (mode) {
                        PresentationContrastMode.Tonal -> WireContrast.TONAL
                        PresentationContrastMode.Monochrome -> WireContrast.MONOCHROME
                    },
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
                rules =
                    rules.map { rule ->
                        PresentationStateColorRule(
                            match =
                                PresentationStateMatch(
                                    required = rule.required.map { it.wire() },
                                    excluded = rule.excluded.map { it.wire() },
                                ),
                            color = rule.color.wire(),
                        )
                    },
                fallback = fallback.wire(),
            )
        }
    }

private fun PresentationInteractionState.wire(): WireState =
    when (this) {
        PresentationInteractionState.Hovered -> WireState.HOVERED
        PresentationInteractionState.Selected -> WireState.SELECTED
        PresentationInteractionState.Focused -> WireState.FOCUSED
        PresentationInteractionState.Pressed -> WireState.PRESSED
        PresentationInteractionState.Disabled -> WireState.DISABLED
    }
