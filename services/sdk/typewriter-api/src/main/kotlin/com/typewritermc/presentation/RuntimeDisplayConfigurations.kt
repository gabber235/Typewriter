package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.presentation.DisplayAppearance
import skirout.editor.v1.presentation.DividerAppearance
import skirout.editor.v1.presentation.ImageFit
import skirout.editor.v1.presentation.ImageOptions
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.ProgressAppearance
import skirout.editor.v1.presentation.TooltipAppearance
import skirout.editor.v1.presentation.InputAppearance as WireInputAppearance

internal class RuntimeImageScope(
    private val target: ImageOptions.Mutable,
) : ImageScope {
    override fun width(value: Double) {
        positiveSize(value)
        target.width = expression(value)
    }

    override fun width(value: Expr<Double, Handled>) {
        target.width = expression(value)
    }

    override fun height(value: Double) {
        positiveSize(value)
        target.height = expression(value)
    }

    override fun height(value: Expr<Double, Handled>) {
        target.height = expression(value)
    }

    override fun fit(value: ImageFit) {
        target.fit = value
    }

    override fun alignment(value: PresentationAlignment) {
        target.alignment = value
    }

    override fun radius(value: PresentationRadius) {
        target.radius = value.wire()
    }
}

internal class RuntimeDisplayAppearanceScope(
    appearance: InputAppearanceScope,
    glyph: GlyphContentScope,
) : DisplayAppearanceScope,
    InputAppearanceScope by appearance,
    GlyphContentScope by glyph

internal fun PresentationBuildState.displayAppearance(configure: DisplayAppearanceScope.() -> Unit): DisplayAppearance {
    val appearance = WireInputAppearance.partial().toMutable()
    val draft = DisplayAppearance.partial().toMutable()
    RuntimeDisplayAppearanceScope(RuntimeTextEntryAppearance(appearance), RuntimeGlyphContent(this) { draft.icon = it }).configure()
    draft.appearance = appearance.toFrozen()
    return draft.toFrozen()
}

internal class RuntimeProgressAppearanceScope(
    private val target: ProgressAppearance.Mutable,
) : ProgressAppearanceScope {
    override fun color(value: PresentationColor) {
        target.color = value.wire()
    }

    override fun backgroundColor(value: PresentationColor) {
        target.backgroundColor = value.wire()
    }

    override fun minimumHeight(value: Double) {
        positiveSize(value)
        target.minimumHeight = expression(value)
    }

    override fun minimumHeight(value: Expr<Double, Handled>) {
        target.minimumHeight = expression(value)
    }

    override fun radius(value: PresentationRadius) {
        target.radius = value.wire()
    }
}

internal class RuntimeTooltipAppearanceScope(
    appearance: InputAppearanceScope,
    private val target: TooltipAppearance.Mutable,
) : TooltipAppearanceScope,
    InputAppearanceScope by appearance {
    override fun waitMilliseconds(value: Int) {
        require(value >= 0)
        target.waitMilliseconds = value
    }

    override fun showMilliseconds(value: Int) {
        require(value >= 0)
        target.showMilliseconds = value
    }

    override fun preferBelow(value: Boolean) {
        target.preferBelow = value
    }
}

internal class RuntimeDividerAppearanceScope(
    private val target: DividerAppearance.Mutable,
) : DividerAppearanceScope {
    override fun color(value: PresentationColor) {
        target.color = value.wire()
    }

    override fun thickness(value: Double) {
        positiveSize(value)
        target.thickness = expression(value)
    }

    override fun thickness(value: Expr<Double, Handled>) {
        target.thickness = expression(value)
    }

    override fun space(value: Double) {
        nonnegativeSize(value)
        target.space = expression(value)
    }

    override fun space(value: Expr<Double, Handled>) {
        target.space = expression(value)
    }

    override fun indent(value: Double) {
        nonnegativeSize(value)
        target.indent = expression(value)
    }

    override fun indent(value: Expr<Double, Handled>) {
        target.indent = expression(value)
    }

    override fun endIndent(value: Double) {
        nonnegativeSize(value)
        target.endIndent = expression(value)
    }

    override fun endIndent(value: Expr<Double, Handled>) {
        target.endIndent = expression(value)
    }
}

internal class RuntimeTabsScope(
    appearance: InputAppearanceScope,
    private val add: (String, Expr<String, Handled>, String?, Layout.() -> Unit) -> Unit,
) : TabsScope,
    InputAppearanceScope by appearance {
    var spacing: Double? = null
    var contentSpacing: Double? = null

    override fun spacing(value: Double) {
        nonnegativeSize(value)
        spacing = value
    }

    override fun contentSpacing(value: Double) {
        nonnegativeSize(value)
        contentSpacing = value
    }

    override fun tab(
        id: String,
        label: Expr<String, Handled>,
        icon: String?,
        body: Layout.() -> Unit,
    ) = add(id, label, icon, body)
}
