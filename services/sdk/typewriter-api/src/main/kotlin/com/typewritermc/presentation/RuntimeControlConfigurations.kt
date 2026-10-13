package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.PresentationNode as WirePresentationNode
import skirout.editor.v1.presentation.TogglePresentation as WireTogglePresentation
import skirout.editor.v1.presentation.TogglePosition as WireTogglePosition
import skirout.editor.v1.presentation.ToggleInteractionOptions as WireToggleInteractionOptions
import skirout.editor.v1.presentation.ToggleControl as WireToggleControl
import skirout.editor.v1.presentation.SliderValueDisplay as WireSliderValueDisplay
import skirout.editor.v1.presentation.SliderOrientation as WireSliderOrientation
import skirout.editor.v1.presentation.SliderInteractionOptions as WireSliderInteractionOptions
import skirout.editor.v1.presentation.SliderInteraction as WireSliderInteraction
import skirout.editor.v1.presentation.SliderControl as WireSliderControl
import skirout.editor.v1.presentation.SelectOption as WireSelectOption
import skirout.editor.v1.presentation.SelectInteractionOptions as WireSelectInteractionOptions
import skirout.editor.v1.presentation.SelectControl as WireSelectControl
import skirout.editor.v1.presentation.EnumControl as WireEnumControl
import skirout.editor.v1.presentation.DurationInteractionOptions as WireDurationInteractionOptions
import skirout.editor.v1.presentation.DurationControl as WireDurationControl
import skirout.editor.v1.presentation.DateTimePickerPresentation as WireDateTimePickerPresentation
import skirout.editor.v1.presentation.DateTimeInteractionOptions as WireDateTimeInteractionOptions
import skirout.editor.v1.presentation.DateTimeControl as WireDateTimeControl
import skirout.editor.v1.presentation.ColorPickerFormat as WireColorPickerFormat
import skirout.editor.v1.presentation.ColorInteractionOptions as WireColorInteractionOptions
import skirout.editor.v1.presentation.ColorEditingRepresentation as WireColorEditingRepresentation
import skirout.editor.v1.presentation.ColorControl as WireColorControl
import skirout.editor.v1.presentation.ChoicePresentation as WireChoicePresentation
import skirout.editor.v1.presentation.ChoiceOptionAppearance as WireChoiceOptionAppearance
import skirout.editor.v1.presentation.BytesInteractionOptions as WireBytesInteractionOptions
import skirout.editor.v1.presentation.BytesEditingEncoding as WireBytesEditingEncoding
import skirout.editor.v1.presentation.BytesControl as WireBytesControl
import skirout.editor.v1.presentation.BorderOverride as WireBorderOverride
import skirout.editor.v1.presentation.BoundControl as WireBoundControl
import skirout.editor.v1.presentation.CharacterFilter as WireCharacterFilter
import skirout.editor.v1.presentation.ControlDensity as WireControlDensity
import skirout.editor.v1.presentation.ExpressionMapping as WireExpressionMapping
import skirout.editor.v1.presentation.InputAdornment as WireInputAdornment
import skirout.editor.v1.presentation.InputAppearance as WireInputAppearance
import skirout.editor.v1.presentation.InputContent as WireInputContent
import skirout.editor.v1.presentation.InputTextAlignment as WireInputTextAlignment
import skirout.editor.v1.presentation.InputTextStyle as WireInputTextStyle
import skirout.editor.v1.presentation.NumericControl as WireNumericControl
import skirout.editor.v1.presentation.NumericInteractionOptions as WireNumericInteractionOptions
import skirout.editor.v1.presentation.NumericSteppers as WireNumericSteppers
import skirout.editor.v1.presentation.PopupAppearance as WirePopupAppearance
import skirout.editor.v1.presentation.PresentationElement as WirePresentationElement
import skirout.editor.v1.presentation.TextCapitalization as WireTextCapitalization
import skirout.editor.v1.presentation.TextControl as WireTextControl
import skirout.editor.v1.presentation.TextEditingOptions as WireTextEditingOptions
import skirout.editor.v1.presentation.TextEntryInteractionOptions as WireTextEntryInteractionOptions
import skirout.editor.v1.presentation.TextLengthPolicy as WireTextLengthPolicy
import skirout.editor.v1.presentation.TextLines as WireTextLines
import skirout.editor.v1.presentation.TextPurpose as WireTextPurpose
import skirout.editor.v1.presentation.ValueMappings as WireValueMappings

internal class RuntimeTextEntryAppearance(private val target: WireInputAppearance.Mutable) : TextEntryAppearanceScope {
    override fun iconColor(value: PresentationColor) { target.iconColor = value.wire() }
    override fun iconSize(value: Double) { positiveSize(value); target.iconSize = expression(value) }
    override fun iconSize(value: Expr<Double, Handled>) { target.iconSize = expression(value) }
    override fun textStyle(value: TextStyle) { target.valueStyle = value.inputWire(target.valueStyle) }
    override fun placeholderStyle(value: TextStyle) { target.placeholderStyle = value.inputWire(target.placeholderStyle) }
    override fun labelStyle(value: TextStyle) { target.labelStyle = value.inputWire(target.labelStyle) }
    override fun descriptionStyle(value: TextStyle) { target.descriptionStyle = value.inputWire(target.descriptionStyle) }
    override fun density(value: ControlDensity) { target.density = value.wire() }
    override fun padding(value: PresentationInsets) { value.checkInputInsets(); target.padding = value.wire() }
    override fun fill(value: PresentationColor) { target.fill = value.wire() }
    override fun border(value: PresentationBorder) {
        require(value.width.isFinite() && value.width >= 0) { "Border width must be finite and nonnegative." }
        target.border = WireBorderOverride.ValueWrapper(value.wire())
    }
    override fun noBorder() { target.border = WireBorderOverride.NONE }
    override fun radius(value: PresentationRadius) { target.radius = value.wire() }
    override fun alignment(value: TextAlignment) {
        target.alignment = when (value) {
            TextAlignment.Start -> WireInputTextAlignment.START
            TextAlignment.Center -> WireInputTextAlignment.CENTER
            TextAlignment.End -> WireInputTextAlignment.END
        }
    }
}

internal fun TextStyle.inputWire(previous: skirout.editor.v1.presentation.InputTextStyle_OrMutable? = null): WireInputTextStyle {
    require(sizing !is TextSizing.Fit) { "Native input typography does not support fitted sizing." }
    require(weight == null || weight in 1..1000) { "Font weight must be between one and one thousand." }
    return WireInputTextStyle(
        color = color?.wire() ?: previous?.color,
        weight = weight ?: previous?.weight,
        sizing = sizing?.wire() ?: previous?.sizing,
    )
}

internal fun ControlDensity.wire(): WireControlDensity = when (this) {
    ControlDensity.Comfortable -> WireControlDensity.COMFORTABLE
    ControlDensity.Compact -> WireControlDensity.COMPACT
}

internal fun positiveSize(value: Double) {
    require(value.isFinite() && value > 0) { "Size must be finite and positive." }
}

internal fun nonnegativeSize(value: Double) {
    require(value.isFinite() && value >= 0) { "Spacing must be finite and nonnegative." }
}

private fun PresentationInsets.checkInputInsets() {
    listOf(start, top, end, bottom).forEach(::nonnegativeSize)
}

internal fun PresentationBuildState.iconNode(id: String, options: IconOptions): WirePresentationNode {
    require(id.isNotBlank()) { "Icon identifier must not be blank." }
    options.size?.let(::positiveSize)
    return node(WirePresentationElement.createIcon(
        name = expression(id), semanticLabel = null,
        color = options.color?.wire(), size = options.size?.let(::expression),
    ))
}

internal class RuntimeGlyphContent(
    private val state: PresentationBuildState,
    private val setLeading: (WireInputAdornment) -> Unit,
) : GlyphContentScope {
    override fun icon(id: String, color: PresentationColor?, size: Double?) {
        setLeading(WireInputAdornment.ContentWrapper(state.iconNode(id, IconOptions(size = size, color = color))))
    }
    override fun noIcon() { setLeading(WireInputAdornment.NONE) }
}

internal class RuntimeInputContent(
    private val author: RuntimePresentationBuildScope,
    private val target: WireInputContent.Mutable,
    glyph: GlyphContentScope,
) : InputContentScope, GlyphContentScope by glyph {
    constructor(state: PresentationBuildState, author: RuntimePresentationBuildScope, target: WireInputContent.Mutable) :
        this(author, target, RuntimeGlyphContent(state) { target.leading = it })
    override fun placeholder(value: String) { target.placeholder = expression(value) }
    override fun placeholder(value: Expr<String, Handled>) { target.placeholder = expression(value) }
    override fun prefix(body: Layout.() -> Unit) { target.leading = WireInputAdornment.ContentWrapper(author.presentation(body)) }
    override fun suffix(body: Layout.() -> Unit) { target.suffix = author.presentation(body) }
}

internal class RuntimeTextEntryInteraction(private val target: WireTextEntryInteractionOptions.Mutable) : TextEntryInteractionScope {
    override fun selectAllOnFocus(value: Boolean) { target.selectAllOnFocus = value }
}

private class RuntimeValueExpressionScope<V>(override val value: Expr<V, Handled>) : ValueExpressionScope<V>

internal class RuntimeValueMappings<V>(
    private val state: PresentationBuildState,
    private val target: WireValueMappings.Mutable,
    private val payload: com.typewritermc.types.TypeTemplate,
) : ValueMappingScope<V> {
    override fun onComplete(body: ValueExpressionScope<V>.() -> Expr<V, Handled>) { target.completion = mapping("completion", body) }
    override fun display(body: ValueExpressionScope<V>.() -> Expr<String, Handled>) { target.display = mapping("display", body) }
    private fun <R> mapping(purpose: String, body: ValueExpressionScope<V>.() -> Expr<R, Handled>): WireExpressionMapping {
        val input = state.bindingId("input.$purpose")
        val receiver = RuntimeValueExpressionScope<V>(Expr(ExpressionNode.Read(input, ValuePath())))
        val result = receiver.body()
        val output = if (purpose == "display") com.typewritermc.types.TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Text) else payload
        state.checkMapping(result.node, input, payload, output)
        return WireExpressionMapping(inputBinding = input.wire(), body = expression(result))
    }
}

internal class RuntimePopupAppearance(private val target: WirePopupAppearance.Mutable) : PopupAppearanceScope {
    override fun minimumPopupWidth(value: Double) { nonnegativeSize(value); target.minimumWidth = expression(value) }
    override fun minimumPopupWidth(value: Expr<Double, Handled>) { target.minimumWidth = expression(value) }
    override fun maximumPopupWidth(value: Double) { positiveSize(value); target.maximumWidth = expression(value) }
    override fun maximumPopupWidth(value: Expr<Double, Handled>) { target.maximumWidth = expression(value) }
    override fun maximumExtent(value: Double) { positiveSize(value); target.maximumExtent = expression(value) }
    override fun maximumExtent(value: Expr<Double, Handled>) { target.maximumExtent = expression(value) }
    override fun popupPadding(value: PresentationInsets) { value.checkInputInsets(); target.padding = value.wire() }
    override fun popupFill(value: PresentationColor) { target.fill = value.wire() }
    override fun popupBorder(value: PresentationBorder) { target.border = value.wire() }
    override fun popupRadius(value: PresentationRadius) { target.radius = value.wire() }
}

internal class RuntimeNumericInteraction<N>(private val target: WireNumericInteractionOptions.Mutable) : NumericInteractionScope<N> {
    override fun minimum(value: N) { target.minimum = expression(value) }
    override fun minimum(value: Expr<N, Handled>) { target.minimum = expression(value) }
    override fun maximum(value: N) { target.maximum = expression(value) }
    override fun maximum(value: Expr<N, Handled>) { target.maximum = expression(value) }
    override fun step(value: N) {
        require(value.toString().toBigDecimalOrNull()?.signum() == 1) { "Numeric step must be finite and positive." }
        target.step = expression(value)
    }
    override fun step(value: Expr<N, Handled>) { target.step = expression(value) }
    override fun steppers(value: NumericSteppers) {
        target.steppers = when (value) {
            NumericSteppers.Hidden -> WireNumericSteppers.HIDDEN
            NumericSteppers.Inline -> WireNumericSteppers.INLINE
        }
    }
    override fun editingLocale(value: String) { require(value.isNotBlank()); target.editingLocale = expression(value) }
    override fun editingLocale(value: Expr<String, Handled>) { target.editingLocale = expression(value) }
}

internal class RuntimeTextEditing(private val target: WireTextEditingOptions.Mutable) : TextEditingScope {
    override fun lines(value: TextLines) {
        target.lines = when (value) {
            TextLines.Single -> WireTextLines.SINGLE
            is TextLines.Multiple -> WireTextLines.createMultiple(minimum = value.minimum, maximum = value.maximum)
        }
    }
    override fun purpose(value: TextPurpose) {
        target.purpose = when (value) {
            TextPurpose.Plain -> WireTextPurpose.PLAIN
            TextPurpose.Email -> WireTextPurpose.EMAIL
            TextPurpose.Url -> WireTextPurpose.URL
            TextPurpose.Password -> WireTextPurpose.PASSWORD
        }
    }
    override fun capitalization(value: TextCapitalization) {
        target.capitalization = when (value) {
            TextCapitalization.None -> WireTextCapitalization.NONE
            TextCapitalization.Words -> WireTextCapitalization.WORDS
            TextCapitalization.Sentences -> WireTextCapitalization.SENTENCES
            TextCapitalization.Characters -> WireTextCapitalization.CHARACTERS
        }
    }
    override fun suggestions(value: Boolean) { target.suggestions = value }
    override fun length(value: TextLengthPolicy) {
        target.length = WireTextLengthPolicy(maximumGraphemes = value.maximum, enforceAfterComposition = value is TextLengthPolicy.Enforced)
    }
    override fun characterFilter(value: CharacterFilter) {
        val filter = when (value) {
            is CharacterFilter.Allow -> { Regex(value.pattern); WireCharacterFilter.AllowWrapper(value.pattern) }
            is CharacterFilter.Deny -> { Regex(value.pattern); WireCharacterFilter.DenyWrapper(value.pattern) }
        }
        target.characterFilters = target.characterFilters + filter
    }
}

internal class InputConfigurationDraft {
    val appearance = WireInputAppearance.partial().toMutable()
    val content = WireInputContent.partial().toMutable()
    val entry = WireTextEntryInteractionOptions.partial().toMutable()
    val mappings = WireValueMappings.partial().toMutable()
    val popup = WirePopupAppearance.partial().toMutable()
    fun appearance() = RuntimeTextEntryAppearance(appearance)
    fun content(state: PresentationBuildState, author: RuntimePresentationBuildScope) = RuntimeInputContent(state, author, content)
    fun entry() = RuntimeTextEntryInteraction(entry)
    fun <V> mappings(state: PresentationBuildState, payload: com.typewritermc.types.TypeTemplate) = RuntimeValueMappings<V>(state, mappings, payload)
    fun popup() = RuntimePopupAppearance(popup)
    fun freeze() = FrozenInputConfiguration(appearance.toFrozen(), content.toFrozen(), entry.toFrozen(), mappings.toFrozen(), popup.toFrozen())
}

internal data class FrozenInputConfiguration(
    val appearance: WireInputAppearance,
    val content: WireInputContent,
    val entry: WireTextEntryInteractionOptions,
    val mappings: WireValueMappings,
    val popup: WirePopupAppearance,
)

private class RuntimeNumericInputScope<N>(
    appearance: TextEntryAppearanceScope, content: InputContentScope, entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<N>, numeric: NumericInteractionScope<N>,
) : NumericInputScope<N>, TextEntryAppearanceScope by appearance, InputContentScope by content,
    TextEntryInteractionScope by entry, ValueMappingScope<N> by mappings, NumericInteractionScope<N> by numeric

private class RuntimeTextInputScope(
    appearance: TextEntryAppearanceScope, content: InputContentScope, entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<String>, text: TextEditingScope,
) : TextInputScope, TextEntryAppearanceScope by appearance, InputContentScope by content,
    TextEntryInteractionScope by entry, ValueMappingScope<String> by mappings, TextEditingScope by text

internal class RuntimeInputConfigurationFactories(private val state: PresentationBuildState, private val payload: com.typewritermc.types.TypeTemplate) {
    fun <N> numeric(author: RuntimePresentationBuildScope, configure: NumericInputScope<N>.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireNumericInteractionOptions.partial().toMutable()
        RuntimeNumericInputScope(common.appearance(), common.content(state, author), common.entry(), common.mappings<N>(state, payload), RuntimeNumericInteraction<N>(options)).configure()
        val frozen = common.freeze()
        val numeric = options.toFrozen()
        return { control -> WirePresentationElement.NumericInputWrapper(WireNumericControl(control = control, appearance = frozen.appearance, content = frozen.content, entry = frozen.entry, mappings = frozen.mappings, options = numeric)) }
    }

    fun text(author: RuntimePresentationBuildScope, configure: TextInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireTextEditingOptions.partial().toMutable()
        RuntimeTextInputScope(common.appearance(), common.content(state, author), common.entry(), common.mappings<String>(state, payload), RuntimeTextEditing(options)).configure()
        val frozen = common.freeze()
        val text = options.toFrozen()
        return { control -> WirePresentationElement.TextInputWrapper(WireTextControl(control = control, appearance = frozen.appearance, content = frozen.content, entry = frozen.entry, mappings = frozen.mappings, options = text)) }
    }
    fun dateTime(author: RuntimePresentationBuildScope, configure: DateTimeInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireDateTimeInteractionOptions.partial().toMutable()
        val interaction = RuntimeDateTimeInteraction(options)
        RuntimeDateTimeInputScope(common.appearance(), common.content(state, author), common.entry(), common.mappings<kotlin.time.Instant>(state, payload), common.popup(), interaction).configure()
        require(interaction.includeDate != false || interaction.includeTime != false) { "Date or time must be included." }
        val frozen = common.freeze()
        val native = options.toFrozen()
        val includeDate = interaction.includeDate
        val includeTime = interaction.includeTime
        return { control -> WirePresentationElement.DateTimeInputWrapper(WireDateTimeControl(control = control, includeDate = includeDate, includeTime = includeTime, appearance = frozen.appearance, content = frozen.content, entry = frozen.entry, mappings = frozen.mappings, popup = frozen.popup, options = native)) }
    }

    fun duration(author: RuntimePresentationBuildScope, configure: DurationInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireDurationInteractionOptions.partial().toMutable()
        RuntimeDurationInputScope(common.appearance(), common.content(state, author), common.entry(), common.mappings<kotlin.time.Duration>(state, payload), options).configure()
        val frozen = common.freeze()
        val native = options.toFrozen()
        return { control -> WirePresentationElement.DurationInputWrapper(WireDurationControl(control = control, appearance = frozen.appearance, content = frozen.content, entry = frozen.entry, mappings = frozen.mappings, options = native)) }
    }

    fun color(author: RuntimePresentationBuildScope, configure: ColorInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireColorInteractionOptions.partial().toMutable()
        val receiver = RuntimeColorInputScope(common.appearance(), common.content(state, author), common.entry(), common.mappings<com.typewritermc.types.Color>(state, payload), common.popup(), options)
        receiver.configure()
        val frozen = common.freeze()
        val native = options.toFrozen()
        val alpha = receiver.alpha
        return { control -> WirePresentationElement.ColorInputWrapper(WireColorControl(control = control, includeAlpha = alpha, appearance = frozen.appearance, content = frozen.content, entry = frozen.entry, mappings = frozen.mappings, popup = frozen.popup, options = native)) }
    }

    fun bytes(author: RuntimePresentationBuildScope, configure: BytesInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireBytesInteractionOptions.partial().toMutable()
        RuntimeBytesInputScope(common.appearance(), common.content(state, author), common.entry(), common.mappings<List<Byte>>(state, payload), options).configure()
        val frozen = common.freeze()
        val native = options.toFrozen()
        return { control -> WirePresentationElement.BytesInputWrapper(WireBytesControl(control = control, appearance = frozen.appearance, content = frozen.content, entry = frozen.entry, mappings = frozen.mappings, options = native)) }
    }

    fun toggle(configure: ToggleInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val appearance = WireInputAppearance.partial().toMutable()
        val options = WireToggleInteractionOptions.partial().toMutable()
        RuntimeToggleInputScope(RuntimeTextEntryAppearance(appearance), options).configure()
        val frozen = appearance.toFrozen()
        val native = options.toFrozen()
        return { control -> WirePresentationElement.ToggleInputWrapper(WireToggleControl(control = control, appearance = frozen, options = native)) }
    }

    fun <N> slider(minimum: Any?, maximum: Any?, configure: SliderInputScope<N>.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireSliderInteractionOptions.partial().toMutable()
        val receiver = RuntimeSliderInputScope(common.appearance(), common.mappings<N>(state, payload), options)
        receiver.configure()
        val appearance = common.appearance.toFrozen()
        val mappings = common.mappings.toFrozen()
        val native = options.toFrozen()
        val min = expression(minimum)
        val max = expression(maximum)
        val divisions = receiver.divisions
        return { control -> WirePresentationElement.SliderInputWrapper(WireSliderControl(control = control, minimum = min, maximum = max, divisions = divisions, appearance = appearance, mappings = mappings, options = native)) }
    }

    fun <V> select(author: RuntimePresentationBuildScope, values: List<SelectOption<V>>, configure: SelectInputScope<V>.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        require(values.map { it.id }.toSet().size == values.size) { "Select option identifiers must be unique." }
        val common = InputConfigurationDraft()
        val options = WireSelectInteractionOptions.partial().toMutable()
        val receiver = RuntimeSelectInputScope<V>(state, author, common.appearance(), common.content(state, author), common.popup(), options)
        receiver.configure()
        val frozen = common.freeze()
        val native = receiver.finish(values.map { it.id }.toSet())
        val choices = values.map { WireSelectOption(optionId = it.id, label = expression(it.label), value = expression(it.value), content = null, enabledIf = null, disabledReason = null) }
        return { control -> WirePresentationElement.SelectInputWrapper(WireSelectControl(control = control, options = choices, allowCustomValue = native.customValue != null, appearance = frozen.appearance, content = frozen.content, popup = frozen.popup, optionsConfig = native)) }
    }

    fun <V> enum(author: RuntimePresentationBuildScope, configure: SelectInputScope<V>.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireSelectInteractionOptions.partial().toMutable()
        val receiver = RuntimeSelectInputScope<V>(state, author, common.appearance(), common.content(state, author), common.popup(), options)
        receiver.configure()
        val frozen = common.freeze()
        val native = receiver.finish()
        return { control -> WirePresentationElement.EnumInputWrapper(WireEnumControl(control = control, appearance = frozen.appearance, content = frozen.content, popup = frozen.popup, options = native)) }
    }

}

internal class RuntimeDateTimeInteraction(private val target: WireDateTimeInteractionOptions.Mutable) {
    var includeDate: Boolean? = null
    var includeTime: Boolean? = null
    fun minimum(value: kotlin.time.Instant) { target.minimum = expression(literal(value)) }
    fun minimum(value: Expr<kotlin.time.Instant, Handled>) { target.minimum = expression(value) }
    fun maximum(value: kotlin.time.Instant) { target.maximum = expression(literal(value)) }
    fun maximum(value: Expr<kotlin.time.Instant, Handled>) { target.maximum = expression(value) }
    fun timeIncrement(value: kotlin.time.Duration) { require(value.isPositive()); target.timeIncrement = expression(literal(value)) }
    fun presentation(value: DateTimePickerPresentation) { target.presentation = when (value) {
        DateTimePickerPresentation.Calendar -> WireDateTimePickerPresentation.CALENDAR
        DateTimePickerPresentation.Text -> WireDateTimePickerPresentation.TEXT
    } }
}

private class RuntimeDateTimeInputScope(
    appearance: TextEntryAppearanceScope, content: InputContentScope, entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<kotlin.time.Instant>, popup: PopupAppearanceScope,
    private val interaction: RuntimeDateTimeInteraction,
) : DateTimeInputScope, TextEntryAppearanceScope by appearance, InputContentScope by content,
    TextEntryInteractionScope by entry, ValueMappingScope<kotlin.time.Instant> by mappings, PopupAppearanceScope by popup {
    override fun includeDate(value: Boolean) { interaction.includeDate = value }
    override fun includeTime(value: Boolean) { interaction.includeTime = value }
    override fun minimum(value: kotlin.time.Instant) = interaction.minimum(value)
    override fun minimum(value: Expr<kotlin.time.Instant, Handled>) = interaction.minimum(value)
    override fun maximum(value: kotlin.time.Instant) = interaction.maximum(value)
    override fun maximum(value: Expr<kotlin.time.Instant, Handled>) = interaction.maximum(value)
    override fun timeIncrement(value: kotlin.time.Duration) = interaction.timeIncrement(value)
    override fun presentation(value: DateTimePickerPresentation) = interaction.presentation(value)
}

private class RuntimeDurationInputScope(
    appearance: TextEntryAppearanceScope, content: InputContentScope, entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<kotlin.time.Duration>, private val options: WireDurationInteractionOptions.Mutable,
) : DurationInputScope, TextEntryAppearanceScope by appearance, InputContentScope by content,
    TextEntryInteractionScope by entry, ValueMappingScope<kotlin.time.Duration> by mappings {
    override fun minimum(value: kotlin.time.Duration) { options.minimum = expression(literal(value)) }
    override fun minimum(value: Expr<kotlin.time.Duration, Handled>) { options.minimum = expression(value) }
    override fun maximum(value: kotlin.time.Duration) { options.maximum = expression(literal(value)) }
    override fun maximum(value: Expr<kotlin.time.Duration, Handled>) { options.maximum = expression(value) }
    override fun step(value: kotlin.time.Duration) { require(value.isPositive()); options.step = expression(literal(value)) }
    override fun step(value: Expr<kotlin.time.Duration, Handled>) { options.step = expression(value) }
}

private class RuntimeColorInputScope(
    appearance: TextEntryAppearanceScope, content: InputContentScope, entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<com.typewritermc.types.Color>, popup: PopupAppearanceScope,
    private val options: WireColorInteractionOptions.Mutable,
) : ColorInputScope, TextEntryAppearanceScope by appearance, InputContentScope by content,
    TextEntryInteractionScope by entry, ValueMappingScope<com.typewritermc.types.Color> by mappings, PopupAppearanceScope by popup {
    var alpha = false
    override fun includeAlpha(value: Boolean) { alpha = value }
    override fun editingRepresentation(value: ColorEditingRepresentation) { options.editingRepresentation = when (value) {
        ColorEditingRepresentation.Hex -> WireColorEditingRepresentation.HEX
        ColorEditingRepresentation.Rgb -> WireColorEditingRepresentation.RGB
        ColorEditingRepresentation.Hsl -> WireColorEditingRepresentation.HSL
    } }
    override fun pickerFormat(value: ColorPickerFormat) { options.pickerFormat = when (value) {
        ColorPickerFormat.Hex -> WireColorPickerFormat.HEX
        ColorPickerFormat.Rgb -> WireColorPickerFormat.RGB
        ColorPickerFormat.Hsl -> WireColorPickerFormat.HSL
    } }
    override fun showSwatch(value: Boolean) { options.showSwatch = value }
    override fun showFormatSelector(value: Boolean) { options.showFormatSelector = value }
    override fun showCopyAction(value: Boolean) { options.showCopyAction = value }
    override fun offeredSwatches(value: List<com.typewritermc.types.Color>) {
        options.offeredSwatches = expression(Expr<List<com.typewritermc.types.Color>, Handled>(ExpressionNode.Literal(
            com.typewritermc.types.DataValue.ListValue(value.mapIndexed { index, color ->
                com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("swatch.$index"), literal(color).node.let { (it as ExpressionNode.Literal).value })
            }),
        )))
    }
    override fun offeredSwatches(value: Expr<List<com.typewritermc.types.Color>, Handled>) { options.offeredSwatches = expression(value) }
}

private class RuntimeBytesInputScope(
    appearance: TextEntryAppearanceScope, content: InputContentScope, entry: TextEntryInteractionScope,
    mappings: ValueMappingScope<List<Byte>>, private val options: WireBytesInteractionOptions.Mutable,
) : BytesInputScope, TextEntryAppearanceScope by appearance, InputContentScope by content,
    TextEntryInteractionScope by entry, ValueMappingScope<List<Byte>> by mappings {
    override fun editingEncoding(value: BytesEditingEncoding) { options.editingEncoding = when (value) {
        BytesEditingEncoding.Hexadecimal -> WireBytesEditingEncoding.HEXADECIMAL
        BytesEditingEncoding.Base64 -> WireBytesEditingEncoding.BASE64
    } }
    override fun groupSize(value: Int) { require(value > 0); options.groupSize = value }
    override fun showCount(value: Boolean) { options.showCount = value }
}

private class RuntimeToggleInputScope(
    appearance: InputAppearanceScope, private val options: WireToggleInteractionOptions.Mutable,
) : ToggleInputScope, InputAppearanceScope by appearance {
    override fun presentation(value: TogglePresentation) { options.presentation = when (value) {
        TogglePresentation.Switch -> WireTogglePresentation.SWITCH
        TogglePresentation.Checkbox -> WireTogglePresentation.CHECKBOX
    } }
    override fun position(value: TogglePosition) { options.position = when (value) {
        TogglePosition.Leading -> WireTogglePosition.LEADING
        TogglePosition.Trailing -> WireTogglePosition.TRAILING
    } }
    override fun trueLabel(value: String) { options.trueLabel = expression(value) }
    override fun trueLabel(value: Expr<String, Handled>) { options.trueLabel = expression(value) }
    override fun falseLabel(value: String) { options.falseLabel = expression(value) }
    override fun falseLabel(value: Expr<String, Handled>) { options.falseLabel = expression(value) }
    override fun thumbColor(value: PresentationColor) { options.thumbColor = value.wire() }
    override fun trackColor(value: PresentationColor) { options.trackColor = value.wire() }
    override fun checkColor(value: PresentationColor) { options.checkColor = value.wire() }
}

private class RuntimeSliderInputScope<N>(
    appearance: InputAppearanceScope, private val mappings: ValueMappingScope<N>,
    private val options: WireSliderInteractionOptions.Mutable,
) : SliderInputScope<N>, InputAppearanceScope by appearance {
    var divisions: skirout.editor.v1.expression.ExpressionNode? = null
    override fun divisions(value: Int) { require(value > 0); divisions = expression(value) }
    override fun divisions(value: Expr<Int, Handled>) { divisions = expression(value) }
    override fun display(body: ValueExpressionScope<N>.() -> Expr<String, Handled>) = mappings.display(body)
    override fun showValue(value: SliderValueDisplay) { options.showValue = when (value) {
        SliderValueDisplay.Hidden -> WireSliderValueDisplay.HIDDEN
        SliderValueDisplay.WhileInteracting -> WireSliderValueDisplay.WHILE_INTERACTING
        SliderValueDisplay.Always -> WireSliderValueDisplay.ALWAYS
    } }
    override fun showTicks(value: Boolean) { options.showTicks = value }
    override fun orientation(value: SliderOrientation) { options.orientation = when (value) {
        SliderOrientation.Horizontal -> WireSliderOrientation.HORIZONTAL
        SliderOrientation.Vertical -> WireSliderOrientation.VERTICAL
    } }
    override fun interaction(value: SliderInteraction) { options.interaction = when (value) {
        SliderInteraction.TapAndDrag -> WireSliderInteraction.TAP_AND_DRAG
        SliderInteraction.DragOnly -> WireSliderInteraction.DRAG_ONLY
    } }
    override fun activeColor(value: PresentationColor) { options.activeColor = value.wire() }
    override fun inactiveColor(value: PresentationColor) { options.inactiveColor = value.wire() }
    override fun thumbColor(value: PresentationColor) { options.thumbColor = value.wire() }
    override fun trackHeight(value: Double) { positiveSize(value); options.trackHeight = value }
}

internal class RuntimeSelectInputScope<V>(
    private val state: PresentationBuildState, private val author: RuntimePresentationBuildScope,
    appearance: TextEntryAppearanceScope, content: InputContentScope, popup: PopupAppearanceScope,
    private val options: WireSelectInteractionOptions.Mutable,
) : SelectInputScope<V>, TextEntryAppearanceScope by appearance, InputContentScope by content, PopupAppearanceScope by popup {
    private val queryId = state.bindingId("select.query")
    override val query = Expr<String, Handled>(ExpressionNode.Read(queryId, ValuePath()))
    private val overrides = linkedMapOf<String, WireChoiceOptionAppearance.Mutable>()
    init { options.queryBindingId = queryId.wire() }
    private fun option(id: String): WireChoiceOptionAppearance.Mutable {
        require(id.isNotBlank())
        return overrides.getOrPut(id) { WireChoiceOptionAppearance.partial(optionId = id).toMutable() }
    }
    override fun presentation(value: ChoicePresentation) { options.presentation = when (value) {
        ChoicePresentation.Automatic -> WireChoicePresentation.AUTOMATIC
        ChoicePresentation.Dropdown -> WireChoicePresentation.DROPDOWN
        ChoicePresentation.Segmented -> WireChoicePresentation.SEGMENTED
        ChoicePresentation.Radio -> WireChoicePresentation.RADIO
    } }
    override fun filtering(value: Boolean) { options.filtering = value }
    override fun maximumMenuHeight(value: Double) { positiveSize(value); options.maximumMenuHeight = expression(value) }
    override fun maximumMenuHeight(value: Expr<Double, Handled>) { options.maximumMenuHeight = expression(value) }
    override fun selectedTextStyle(value: TextStyle) { options.selectedTextStyle = value.inputWire(options.selectedTextStyle) }
    override fun optionContent(id: String, body: Layout.() -> Unit) { option(id).content = author.presentation(body) }
    override fun optionEnabled(id: String, value: Expr<Boolean, Handled>) { option(id).enabledIf = expression(value) }
    override fun optionDisabledReason(id: String, value: String) { option(id).disabledReason = expression(value) }
    override fun optionDisabledReason(id: String, value: Expr<String, Handled>) { option(id).disabledReason = expression(value) }
    override fun customValue(value: Expr<V, Handled>) { options.customValue = expression(value) }
    fun finish(allowed: Set<String>? = null): WireSelectInteractionOptions {
        require(allowed == null || allowed.containsAll(overrides.keys)) { "Choice appearance targets an unknown option." }
        options.optionOverrides = overrides.values.map { it.toFrozen() }
        return options.toFrozen()
    }
}
