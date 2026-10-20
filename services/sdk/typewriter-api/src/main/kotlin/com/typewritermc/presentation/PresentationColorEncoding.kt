package com.typewritermc.presentation

import skirout.editor.v1.presentation.PresentationStateColorRule
import skirout.editor.v1.presentation.PresentationAmbientColor as WireAmbient
import skirout.editor.v1.presentation.PresentationColor as WireColor
import skirout.editor.v1.presentation.PresentationContrastMode as WireContrast
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
                rules = rules.map { rule -> PresentationStateColorRule(match = rule.match.wire(), color = rule.color.wire()) },
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
