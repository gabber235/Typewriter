package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.Color

enum class PresentationInteractionState { Hovered, Selected, Focused, Pressed, Disabled }

enum class PresentationThemeColor { Primary, OnPrimary, Surface, OnSurface, OnSurfaceVariant, FocusOutline }

enum class PresentationAmbientColor { Background, Foreground, SecondaryForeground }

enum class PresentationContrastMode { Tonal, Monochrome }

/**
 * A paint policy resolved by the panel against authored values, the displayed
 * surface, and the current interaction owner. This is not persisted Color data.
 * Containers publish their resolved foreground to ordinary text and icons.
 */
sealed interface PresentationColor {
    data class Value(
        val expression: Expr<Color, Handled>,
    ) : PresentationColor

    data class Theme(
        val role: PresentationThemeColor,
    ) : PresentationColor

    data class Ambient(
        val role: PresentationAmbientColor,
    ) : PresentationColor

    data class Contrast(
        val source: PresentationColor,
        val mode: PresentationContrastMode,
    ) : PresentationColor

    /** Scales existing opacity. A transparent source remains transparent. */
    data class Alpha(
        val source: PresentationColor,
        val alpha: Double,
    ) : PresentationColor {
        init {
            require(alpha.isFinite() && alpha in 0.0..1.0) { "Presentation alpha must be finite and between zero and one." }
        }
    }

    data class Blend(
        val foreground: PresentationColor,
        val background: PresentationColor,
    ) : PresentationColor

    /** Ordered rules use the first match. The fallback covers every other state. */
    data class States(
        val rules: List<PresentationStateColorRule>,
        val fallback: PresentationColor,
    ) : PresentationColor
}

/** A match requires every required state and excludes every excluded state. */
data class PresentationStateColorRule(
    val required: Set<PresentationInteractionState>,
    val excluded: Set<PresentationInteractionState>,
    val color: PresentationColor,
) {
    init {
        require(required.intersect(excluded).isEmpty()) { "Presentation states cannot be both required and excluded." }
    }
}

class PresentationStateColorScope internal constructor() {
    internal val rules = mutableListOf<PresentationStateColorRule>()

    fun whenAll(
        vararg required: PresentationInteractionState,
        excluded: Set<PresentationInteractionState> = emptySet(),
        color: PresentationColor,
    ) {
        rules += PresentationStateColorRule(required.toSet(), excluded.toSet(), color)
    }
}

fun Expr<Color, Handled>.asPresentationColor(): PresentationColor = PresentationColor.Value(this)

fun literalColor(value: Color): PresentationColor = literal(value).asPresentationColor()

fun themeColor(role: PresentationThemeColor): PresentationColor = PresentationColor.Theme(role)

fun ambientBackground(): PresentationColor = PresentationColor.Ambient(PresentationAmbientColor.Background)

fun ambientForeground(): PresentationColor = PresentationColor.Ambient(PresentationAmbientColor.Foreground)

fun ambientSecondaryForeground(): PresentationColor = PresentationColor.Ambient(PresentationAmbientColor.SecondaryForeground)

/** Derives the existing tonal foreground after compositing over the observed surface. */
fun PresentationColor.on(): PresentationColor = PresentationColor.Contrast(this, PresentationContrastMode.Tonal)

/** Chooses black or white using the displayed background brightness. */
fun PresentationColor.monochromeOn(): PresentationColor = PresentationColor.Contrast(this, PresentationContrastMode.Monochrome)

fun PresentationColor.withAlpha(alpha: Double): PresentationColor = PresentationColor.Alpha(this, alpha)

fun PresentationColor.over(background: PresentationColor): PresentationColor = PresentationColor.Blend(this, background)

/** Declares ordered rules; selection, focus, hover, and presses remain owned by the panel. */
fun stateColor(
    fallback: PresentationColor,
    configure: PresentationStateColorScope.() -> Unit,
): PresentationColor {
    val scope = PresentationStateColorScope().apply(configure)
    return PresentationColor.States(scope.rules.toList(), fallback)
}
