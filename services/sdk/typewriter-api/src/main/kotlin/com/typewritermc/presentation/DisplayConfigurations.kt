package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled

enum class ImageFit { Contain, Cover, Fill, FitWidth, FitHeight, None, ScaleDown }
interface ImageScope {
    fun width(value: Double)
    fun width(value: Expr<Double, Handled>)
    fun height(value: Double)
    fun height(value: Expr<Double, Handled>)
    fun fit(value: ImageFit)
    fun alignment(value: PresentationAlignment)
    fun radius(value: PresentationRadius)
}
interface DisplayAppearanceScope : InputAppearanceScope, GlyphContentScope
interface ProgressAppearanceScope {
    fun color(value: PresentationColor)
    fun backgroundColor(value: PresentationColor)
    fun minimumHeight(value: Double)
    fun minimumHeight(value: Expr<Double, Handled>)
    fun radius(value: PresentationRadius)
}
interface TooltipAppearanceScope : InputAppearanceScope {
    fun waitMilliseconds(value: Int)
    fun showMilliseconds(value: Int)
    fun preferBelow(value: Boolean)
}
interface DividerAppearanceScope {
    fun color(value: PresentationColor)
    fun thickness(value: Double)
    fun thickness(value: Expr<Double, Handled>)
    fun space(value: Double)
    fun space(value: Expr<Double, Handled>)
    fun indent(value: Double)
    fun indent(value: Expr<Double, Handled>)
    fun endIndent(value: Double)
    fun endIndent(value: Expr<Double, Handled>)
}
