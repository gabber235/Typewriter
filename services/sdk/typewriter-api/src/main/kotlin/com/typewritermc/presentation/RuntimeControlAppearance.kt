package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.InputTextAlignment
import skirout.editor.v1.presentation.BorderOverride as WireBorderOverride
import skirout.editor.v1.presentation.InputAdornment as WireInputAdornment
import skirout.editor.v1.presentation.InputAppearance as WireInputAppearance
import skirout.editor.v1.presentation.InputTextStyle as WireInputTextStyle
import skirout.editor.v1.presentation.PopupAppearance as WirePopupAppearance
import skirout.editor.v1.presentation.PresentationElement as WirePresentationElement
import skirout.editor.v1.presentation.PresentationNode as WirePresentationNode

internal class RuntimeTextEntryAppearance(
    private val state: PresentationBuildState,
    private val target: WireInputAppearance.Mutable,
) : TextEntryAppearanceScope {
    override fun iconColor(value: PresentationColor) {
        target.iconColor = value.wire(state)
    }

    override fun iconSize(value: Double) {
        positiveSize(value)
        target.iconSize = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun iconSize(value: Expr<Double, Handled>) {
        target.iconSize = state.lower(value, DOUBLE_SLOT)
    }

    override fun textStyle(value: TextStyle) {
        target.valueStyle = value.inputWire(state, target.valueStyle)
    }

    override fun placeholderStyle(value: TextStyle) {
        target.placeholderStyle = value.inputWire(state, target.placeholderStyle)
    }

    override fun labelStyle(value: TextStyle) {
        target.labelStyle = value.inputWire(state, target.labelStyle)
    }

    override fun descriptionStyle(value: TextStyle) {
        target.descriptionStyle = value.inputWire(state, target.descriptionStyle)
    }

    override fun density(value: ControlDensity) {
        target.density = value
    }

    override fun padding(value: PresentationInsets) {
        target.padding = value.wire()
    }

    override fun fill(value: PresentationColor) {
        target.fill = value.wire(state)
    }

    override fun border(value: PresentationBorder) {
        target.border = WireBorderOverride.ValueWrapper(value.wire(state))
    }

    override fun noBorder() {
        target.border = WireBorderOverride.NONE
    }

    override fun radius(value: PresentationRadius) {
        target.radius = value.wire(state)
    }

    override fun alignment(value: InputTextAlignment) {
        target.alignment = value
    }
}

internal fun TextStyle.inputWire(
    state: PresentationBuildState,
    previous: skirout.editor.v1.presentation.InputTextStyle_OrMutable? = null,
): WireInputTextStyle {
    require(sizing !is TextSizing.Fit) { "Native input typography does not support fitted sizing." }
    return WireInputTextStyle(
        color = color?.wire(state) ?: previous?.color,
        weight = weight?.value ?: previous?.weight,
        sizing = sizing?.wire(state) ?: previous?.sizing,
    )
}

internal fun positiveSize(value: Double) {
    require(value.isFinite() && value > 0) { "Size must be finite and positive." }
}

internal fun nonnegativeSize(value: Double) {
    require(value.isFinite() && value >= 0) { "Spacing must be finite and nonnegative." }
}

internal fun PresentationBuildState.iconNode(
    id: String,
    options: IconOptions,
): WirePresentationNode {
    require(id.isNotBlank()) { "Icon identifier must not be blank." }
    options.size?.let(::positiveSize)
    return node(
        WirePresentationElement.createIcon(
            name = lower(literal(id), TEXT_SLOT),
            semanticLabel = null,
            color = options.color?.wire(this),
            size = options.size?.let { lower(literal(it), DOUBLE_SLOT) },
        ),
    )
}

internal class RuntimeGlyphContent(
    private val state: PresentationBuildState,
    private val setLeading: (WireInputAdornment) -> Unit,
) : GlyphContentScope {
    override fun icon(
        id: String,
        color: PresentationColor?,
        size: Double?,
    ) {
        setLeading(WireInputAdornment.ContentWrapper(state.iconNode(id, IconOptions(size = size, color = color))))
    }

    override fun noIcon() {
        setLeading(WireInputAdornment.NONE)
    }
}

internal class RuntimePopupAppearance(
    private val state: PresentationBuildState,
    private val target: WirePopupAppearance.Mutable,
) : PopupAppearanceScope {
    override fun minimumPopupWidth(value: Double) {
        nonnegativeSize(value)
        target.minimumWidth = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun minimumPopupWidth(value: Expr<Double, Handled>) {
        target.minimumWidth = state.lower(value, DOUBLE_SLOT)
    }

    override fun maximumPopupWidth(value: Double) {
        positiveSize(value)
        target.maximumWidth = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun maximumPopupWidth(value: Expr<Double, Handled>) {
        target.maximumWidth = state.lower(value, DOUBLE_SLOT)
    }

    override fun maximumExtent(value: Double) {
        positiveSize(value)
        target.maximumExtent = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun maximumExtent(value: Expr<Double, Handled>) {
        target.maximumExtent = state.lower(value, DOUBLE_SLOT)
    }

    override fun popupPadding(value: PresentationInsets) {
        target.padding = value.wire()
    }

    override fun popupFill(value: PresentationColor) {
        target.fill = value.wire(state)
    }

    override fun popupBorder(value: PresentationBorder) {
        target.border = value.wire(state)
    }

    override fun popupRadius(value: PresentationRadius) {
        target.radius = value.wire(state)
    }
}
