package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.expression.portableValue
import com.typewritermc.types.listValue
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.BytesEditingEncoding
import skirout.editor.v1.presentation.ChoicePresentation
import skirout.editor.v1.presentation.ColorEditingRepresentation
import skirout.editor.v1.presentation.ColorPickerFormat
import skirout.editor.v1.presentation.DateTimePickerPresentation
import skirout.editor.v1.presentation.SliderInteraction
import skirout.editor.v1.presentation.SliderOrientation
import skirout.editor.v1.presentation.SliderValueDisplay
import skirout.editor.v1.presentation.TogglePosition
import skirout.editor.v1.presentation.TogglePresentation
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.presentation.BytesInteractionOptions as WireBytesInteractionOptions
import skirout.editor.v1.presentation.ChoiceOptionAppearance as WireChoiceOptionAppearance
import skirout.editor.v1.presentation.ColorInteractionOptions as WireColorInteractionOptions
import skirout.editor.v1.presentation.DurationInteractionOptions as WireDurationInteractionOptions
import skirout.editor.v1.presentation.SelectInteractionOptions as WireSelectInteractionOptions
import skirout.editor.v1.presentation.SliderInteractionOptions as WireSliderInteractionOptions
import skirout.editor.v1.presentation.ToggleInteractionOptions as WireToggleInteractionOptions

internal class RuntimeNumericInputScope<N>(
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<N>,
    numeric: NumericInteractionScope<N>,
) : NumericInputScope<N>,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    TextEntryInteractionScope by entry,
    ValueMappingScope<N> by mappings,
    NumericInteractionScope<N> by numeric

internal class RuntimeTextInputScope(
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<String>,
    text: TextEditingScope,
) : TextInputScope,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    TextEntryInteractionScope by entry,
    ValueMappingScope<String> by mappings,
    TextEditingScope by text

internal class RuntimeDateTimeInputScope(
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<kotlin.time.Instant>,
    popup: PopupAppearanceScope,
    private val interaction: RuntimeDateTimeInteraction,
) : DateTimeInputScope,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    TextEntryInteractionScope by entry,
    ValueMappingScope<kotlin.time.Instant> by mappings,
    PopupAppearanceScope by popup {
    override fun includeDate(value: Boolean) {
        interaction.includeDate = value
    }

    override fun includeTime(value: Boolean) {
        interaction.includeTime = value
    }

    override fun minimum(value: kotlin.time.Instant) = interaction.minimum(value)

    override fun minimum(value: Expr<kotlin.time.Instant, Handled>) = interaction.minimum(value)

    override fun maximum(value: kotlin.time.Instant) = interaction.maximum(value)

    override fun maximum(value: Expr<kotlin.time.Instant, Handled>) = interaction.maximum(value)

    override fun timeIncrement(value: kotlin.time.Duration) = interaction.timeIncrement(value)

    override fun presentation(value: DateTimePickerPresentation) = interaction.presentation(value)
}

internal class RuntimeDurationInputScope(
    private val state: PresentationBuildState,
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<kotlin.time.Duration>,
    private val options: WireDurationInteractionOptions.Mutable,
) : DurationInputScope,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    TextEntryInteractionScope by entry,
    ValueMappingScope<kotlin.time.Duration> by mappings {
    override fun minimum(value: kotlin.time.Duration) {
        options.minimum = state.lower(literal(value), DURATION_SLOT)
    }

    override fun minimum(value: Expr<kotlin.time.Duration, Handled>) {
        options.minimum = state.lower(value, DURATION_SLOT)
    }

    override fun maximum(value: kotlin.time.Duration) {
        options.maximum = state.lower(literal(value), DURATION_SLOT)
    }

    override fun maximum(value: Expr<kotlin.time.Duration, Handled>) {
        options.maximum = state.lower(value, DURATION_SLOT)
    }

    override fun step(value: kotlin.time.Duration) {
        require(value.isPositive())
        options.step = state.lower(literal(value), DURATION_SLOT)
    }

    override fun step(value: Expr<kotlin.time.Duration, Handled>) {
        options.step = state.lower(value, DURATION_SLOT)
    }
}

internal class RuntimeColorInputScope(
    private val state: PresentationBuildState,
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<com.typewritermc.types.Color>,
    popup: PopupAppearanceScope,
    private val options: WireColorInteractionOptions.Mutable,
) : ColorInputScope,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    TextEntryInteractionScope by entry,
    ValueMappingScope<com.typewritermc.types.Color> by mappings,
    PopupAppearanceScope by popup {
    var alpha = false

    override fun includeAlpha(value: Boolean) {
        alpha = value
    }

    override fun editingRepresentation(value: ColorEditingRepresentation) {
        options.editingRepresentation = value
    }

    override fun pickerFormat(value: ColorPickerFormat) {
        options.pickerFormat = value
    }

    override fun showSwatch(value: Boolean) {
        options.showSwatch = value
    }

    override fun showFormatSelector(value: Boolean) {
        options.showFormatSelector = value
    }

    override fun showCopyAction(value: Boolean) {
        options.showCopyAction = value
    }

    override fun offeredSwatches(value: List<com.typewritermc.types.Color>) {
        val colors =
            skirout.editor.v1.type_catalog.DataValue.listValue(
                value.mapIndexed { index, color ->
                    skirout.editor.v1.type_catalog.ListItem(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "swatch.$index"),
                        value = color.portableValue(),
                    )
                },
            )
        options.offeredSwatches =
            state.lower(com.typewritermc.expression.portableLiteral<List<com.typewritermc.types.Color>>(colors), listSlot(COLOR_SLOT))
    }

    override fun offeredSwatches(value: Expr<List<com.typewritermc.types.Color>, Handled>) {
        options.offeredSwatches = state.lower(value, listSlot(COLOR_SLOT))
    }
}

internal class RuntimeBytesInputScope(
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<List<Byte>>,
    private val options: WireBytesInteractionOptions.Mutable,
) : BytesInputScope,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    TextEntryInteractionScope by entry,
    ValueMappingScope<List<Byte>> by mappings {
    override fun editingEncoding(value: BytesEditingEncoding) {
        options.editingEncoding = value
    }

    override fun groupSize(value: Int) {
        require(value > 0)
        options.groupSize = value
    }

    override fun showCount(value: Boolean) {
        options.showCount = value
    }
}

internal class RuntimeToggleInputScope(
    private val state: PresentationBuildState,
    appearance: InputAppearanceScope,
    private val options: WireToggleInteractionOptions.Mutable,
) : ToggleInputScope,
    InputAppearanceScope by appearance {
    override fun presentation(value: TogglePresentation) {
        options.presentation = value
    }

    override fun position(value: TogglePosition) {
        options.position = value
    }

    override fun trueLabel(value: String) {
        options.trueLabel = state.lower(literal(value), TEXT_SLOT)
    }

    override fun trueLabel(value: Expr<String, Handled>) {
        options.trueLabel = state.lower(value, TEXT_SLOT)
    }

    override fun falseLabel(value: String) {
        options.falseLabel = state.lower(literal(value), TEXT_SLOT)
    }

    override fun falseLabel(value: Expr<String, Handled>) {
        options.falseLabel = state.lower(value, TEXT_SLOT)
    }

    override fun thumbColor(value: PresentationColor) {
        options.thumbColor = value.wire(state)
    }

    override fun trackColor(value: PresentationColor) {
        options.trackColor = value.wire(state)
    }

    override fun checkColor(value: PresentationColor) {
        options.checkColor = value.wire(state)
    }
}

internal class RuntimeSliderInputScope<N>(
    private val state: PresentationBuildState,
    appearance: InputAppearanceScope,
    private val mappings: ValueMappingScope<N>,
    private val options: WireSliderInteractionOptions.Mutable,
) : SliderInputScope<N>,
    InputAppearanceScope by appearance {
    var divisions: skirout.editor.v1.expression.ExpressionNode? = null

    override fun divisions(value: Int) {
        require(value > 0)
        divisions = state.lower(literal(value), INT_SLOT)
    }

    override fun divisions(value: Expr<Int, Handled>) {
        divisions = state.lower(value, INT_SLOT)
    }

    override fun display(body: ValueExpressionScope<N>.() -> Expr<String, Handled>) = mappings.display(body)

    override fun showValue(value: SliderValueDisplay) {
        options.showValue = value
    }

    override fun showTicks(value: Boolean) {
        options.showTicks = value
    }

    override fun orientation(value: SliderOrientation) {
        options.orientation = value
    }

    override fun interaction(value: SliderInteraction) {
        options.interaction = value
    }

    override fun activeColor(value: PresentationColor) {
        options.activeColor = value.wire(state)
    }

    override fun inactiveColor(value: PresentationColor) {
        options.inactiveColor = value.wire(state)
    }

    override fun thumbColor(value: PresentationColor) {
        options.thumbColor = value.wire(state)
    }

    override fun trackHeight(value: Double) {
        positiveSize(value)
        options.trackHeight = value
    }
}

internal class RuntimeSelectInputScope<V>(
    private val state: PresentationBuildState,
    private val author: RuntimePresentationBuildScope,
    appearance: TextEntryAppearanceScope,
    content: InputContentScope,
    popup: PopupAppearanceScope,
    private val options: WireSelectInteractionOptions.Mutable,
    private val payload: TypeTemplate,
) : SelectInputScope<V>,
    TextEntryAppearanceScope by appearance,
    InputContentScope by content,
    PopupAppearanceScope by popup {
    private val overrides = linkedMapOf<String, WireChoiceOptionAppearance.Mutable>()

    private fun option(id: String): WireChoiceOptionAppearance.Mutable {
        require(id.isNotBlank())
        return overrides.getOrPut(id) { WireChoiceOptionAppearance.partial(optionId = id).toMutable() }
    }

    override fun dropdown(configure: DropdownChoiceScope<V>.() -> Unit) {
        presentation(ChoicePresentation.DROPDOWN)
        object : DropdownChoiceScope<V> {
            override fun customValue(parse: Expr<String, Handled>.() -> Expr<V, com.typewritermc.expression.MissingPolicy>) {
                check(options.customValue == null) { "A dropdown may declare one custom value." }
                // The typed query is bound while the custom value is evaluated; a query that names no value is missing.
                state.introduce("select.query", TEXT_SLOT, mayBeMissing = false) { query ->
                    options.queryBinding = query
                    options.customValue =
                        state.lower(
                            com.typewritermc.expression
                                .inputExpression<String, Handled>(query.id)
                                .parse(),
                            payload,
                            mayBeMissing = true,
                        )
                }
            }
        }.configure()
    }

    override fun segmented() = presentation(ChoicePresentation.SEGMENTED)

    override fun radio() = presentation(ChoicePresentation.RADIO)

    private fun presentation(value: ChoicePresentation) {
        check(options.presentation == null) { "A choice input may declare one presentation." }
        options.presentation = value
    }

    override fun filtering(value: Boolean) {
        options.filtering = value
    }

    override fun maximumMenuHeight(value: Double) {
        positiveSize(value)
        options.maximumMenuHeight = state.lower(literal(value), DOUBLE_SLOT)
    }

    override fun maximumMenuHeight(value: Expr<Double, Handled>) {
        options.maximumMenuHeight = state.lower(value, DOUBLE_SLOT)
    }

    override fun selectedTextStyle(value: TextStyle) {
        options.selectedTextStyle = value.inputWire(state, options.selectedTextStyle)
    }

    override fun optionContent(
        id: String,
        body: Layout.() -> Unit,
    ) {
        option(id).content = author.presentation(body)
    }

    override fun optionEnabled(
        id: String,
        value: Expr<Boolean, Handled>,
    ) {
        option(id).enabledIf = state.lower(value, BOOLEAN_SLOT)
    }

    override fun optionDisabledReason(
        id: String,
        value: String,
    ) {
        option(id).disabledReason = state.lower(literal(value), TEXT_SLOT)
    }

    override fun optionDisabledReason(
        id: String,
        value: Expr<String, Handled>,
    ) {
        option(id).disabledReason = state.lower(value, TEXT_SLOT)
    }

    fun finish(allowed: Set<String>? = null): WireSelectInteractionOptions {
        require(allowed == null || allowed.containsAll(overrides.keys)) { "Choice appearance targets an unknown option." }
        options.optionOverrides = overrides.values.map { it.toFrozen() }
        return options.toFrozen()
    }
}
