package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.DisplayAppearance
import skirout.editor.v1.presentation.DividerAppearance
import skirout.editor.v1.presentation.ImageFit
import skirout.editor.v1.presentation.ImageOptions
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.ProgressAppearance
import skirout.editor.v1.presentation.TooltipAppearance
import skirout.editor.v1.presentation.InputAppearance as WireInputAppearance

internal class RuntimeImageScope(
    private val state: PresentationBuildState,
    private val target: ImageOptions.Mutable,
) : ImageScope {
    override fun width(value: Double) {
        positiveSize(value)
        target.width = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun width(value: Expr<Double, Handled>) {
        target.width = state.lower(value, DOUBLE_SLOT)
    }

    override fun height(value: Double) {
        positiveSize(value)
        target.height = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun height(value: Expr<Double, Handled>) {
        target.height = state.lower(value, DOUBLE_SLOT)
    }

    override fun fit(value: ImageFit) {
        target.fit = value
    }

    override fun alignment(value: PresentationAlignment) {
        target.alignment = value
    }

    override fun radius(value: PresentationRadius) {
        target.radius = value.wire(state)
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
    RuntimeDisplayAppearanceScope(RuntimeTextEntryAppearance(this, appearance), RuntimeGlyphContent(this) { draft.icon = it }).configure()
    draft.appearance = appearance.toFrozen()
    return draft.toFrozen()
}

internal class RuntimeProgressAppearanceScope(
    private val state: PresentationBuildState,
    private val target: ProgressAppearance.Mutable,
) : ProgressAppearanceScope {
    override fun color(value: PresentationColor) {
        target.color = value.wire(state)
    }

    override fun backgroundColor(value: PresentationColor) {
        target.backgroundColor = value.wire(state)
    }

    override fun minimumHeight(value: Double) {
        positiveSize(value)
        target.minimumHeight = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun minimumHeight(value: Expr<Double, Handled>) {
        target.minimumHeight = state.lower(value, DOUBLE_SLOT)
    }

    override fun radius(value: PresentationRadius) {
        target.radius = value.wire(state)
    }
}

internal class RuntimeTooltipAppearanceScope(
    appearance: InputAppearanceScope,
    private val target: TooltipAppearance.Mutable,
) : TooltipAppearanceScope,
    InputAppearanceScope by appearance {
    override fun waitDelay(value: DisplayDelay) {
        target.waitMilliseconds = value.milliseconds
    }

    override fun showDelay(value: DisplayDelay) {
        target.showMilliseconds = value.milliseconds
    }

    override fun preferBelow(value: Boolean) {
        target.preferBelow = value
    }
}

internal class RuntimeDividerAppearanceScope(
    private val state: PresentationBuildState,
    private val target: DividerAppearance.Mutable,
) : DividerAppearanceScope {
    override fun color(value: PresentationColor) {
        target.color = value.wire(state)
    }

    override fun thickness(value: Double) {
        positiveSize(value)
        target.thickness = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun thickness(value: Expr<Double, Handled>) {
        target.thickness = state.lower(value, DOUBLE_SLOT)
    }

    override fun space(value: Double) {
        nonnegativeSize(value)
        target.space = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun space(value: Expr<Double, Handled>) {
        target.space = state.lower(value, DOUBLE_SLOT)
    }

    override fun indent(value: Double) {
        nonnegativeSize(value)
        target.indent = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun indent(value: Expr<Double, Handled>) {
        target.indent = state.lower(value, DOUBLE_SLOT)
    }

    override fun endIndent(value: Double) {
        nonnegativeSize(value)
        target.endIndent = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun endIndent(value: Expr<Double, Handled>) {
        target.endIndent = state.lower(value, DOUBLE_SLOT)
    }
}

internal class RuntimeTabsScope(
    appearance: InputAppearanceScope,
    private val add: (String, Expr<String, Handled>, String?, Layout.() -> Unit) -> Unit,
) : TabsScope,
    InputAppearanceScope by appearance {
    var spacing: Double? = null
    var contentSpacing: Double? = null

    override fun spacing(value: Spacing) {
        spacing = value.pixels
    }

    override fun contentSpacing(value: Spacing) {
        contentSpacing = value.pixels
    }

    override fun tab(
        id: String,
        label: Expr<String, Handled>,
        icon: String?,
        body: Layout.() -> Unit,
    ) = add(id, label, icon, body)
}
