package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.expression.portableValue
import com.typewritermc.types.canonicalText
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.template
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.BytesEditingEncoding
import skirout.editor.v1.presentation.ChoicePresentation
import skirout.editor.v1.presentation.ColorEditingRepresentation
import skirout.editor.v1.presentation.ColorPickerFormat
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.DateTimePickerPresentation
import skirout.editor.v1.presentation.InputTextAlignment
import skirout.editor.v1.presentation.NumericSteppers
import skirout.editor.v1.presentation.SliderInteraction
import skirout.editor.v1.presentation.SliderOrientation
import skirout.editor.v1.presentation.SliderValueDisplay
import skirout.editor.v1.presentation.TextCapitalization
import skirout.editor.v1.presentation.TextPurpose
import skirout.editor.v1.presentation.TogglePosition
import skirout.editor.v1.presentation.TogglePresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.presentation.BorderOverride as WireBorderOverride
import skirout.editor.v1.presentation.BoundControl as WireBoundControl
import skirout.editor.v1.presentation.BytesControl as WireBytesControl
import skirout.editor.v1.presentation.BytesInteractionOptions as WireBytesInteractionOptions
import skirout.editor.v1.presentation.CharacterFilter as WireCharacterFilter
import skirout.editor.v1.presentation.ChoiceOptionAppearance as WireChoiceOptionAppearance
import skirout.editor.v1.presentation.ColorControl as WireColorControl
import skirout.editor.v1.presentation.ColorInteractionOptions as WireColorInteractionOptions
import skirout.editor.v1.presentation.DateTimeControl as WireDateTimeControl
import skirout.editor.v1.presentation.DateTimeInteractionOptions as WireDateTimeInteractionOptions
import skirout.editor.v1.presentation.DurationControl as WireDurationControl
import skirout.editor.v1.presentation.DurationInteractionOptions as WireDurationInteractionOptions
import skirout.editor.v1.presentation.EnumControl as WireEnumControl
import skirout.editor.v1.presentation.ExpressionMapping as WireExpressionMapping
import skirout.editor.v1.presentation.InputAdornment as WireInputAdornment
import skirout.editor.v1.presentation.InputAppearance as WireInputAppearance
import skirout.editor.v1.presentation.InputContent as WireInputContent
import skirout.editor.v1.presentation.InputTextStyle as WireInputTextStyle
import skirout.editor.v1.presentation.NumericControl as WireNumericControl
import skirout.editor.v1.presentation.NumericInteractionOptions as WireNumericInteractionOptions
import skirout.editor.v1.presentation.PopupAppearance as WirePopupAppearance
import skirout.editor.v1.presentation.PresentationElement as WirePresentationElement
import skirout.editor.v1.presentation.PresentationNode as WirePresentationNode
import skirout.editor.v1.presentation.SelectControl as WireSelectControl
import skirout.editor.v1.presentation.SelectInteractionOptions as WireSelectInteractionOptions
import skirout.editor.v1.presentation.SelectOption as WireSelectOption
import skirout.editor.v1.presentation.SliderControl as WireSliderControl
import skirout.editor.v1.presentation.SliderInteractionOptions as WireSliderInteractionOptions
import skirout.editor.v1.presentation.TextControl as WireTextControl
import skirout.editor.v1.presentation.TextEditingOptions as WireTextEditingOptions
import skirout.editor.v1.presentation.TextEntryInteractionOptions as WireTextEntryInteractionOptions
import skirout.editor.v1.presentation.TextLengthPolicy as WireTextLengthPolicy
import skirout.editor.v1.presentation.TextLines as WireTextLines
import skirout.editor.v1.presentation.ToggleControl as WireToggleControl
import skirout.editor.v1.presentation.ToggleInteractionOptions as WireToggleInteractionOptions
import skirout.editor.v1.presentation.ValueMappings as WireValueMappings

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

internal class RuntimeInputContent(
    private val state: PresentationBuildState,
    private val author: RuntimePresentationBuildScope,
    private val target: WireInputContent.Mutable,
    glyph: GlyphContentScope,
) : InputContentScope,
    GlyphContentScope by glyph {
    constructor(state: PresentationBuildState, author: RuntimePresentationBuildScope, target: WireInputContent.Mutable) :
        this(state, author, target, RuntimeGlyphContent(state) { target.leading = it })

    override fun placeholder(value: String) {
        target.placeholder = state.lower(literal(value), TEXT_SLOT)
    }

    override fun placeholder(value: Expr<String, Handled>) {
        target.placeholder = state.lower(value, TEXT_SLOT)
    }

    override fun prefix(body: Layout.() -> Unit) {
        target.leading = WireInputAdornment.ContentWrapper(author.presentation(body))
    }

    override fun suffix(body: Layout.() -> Unit) {
        target.suffix = author.presentation(body)
    }
}

internal class RuntimeTextEntryInteraction(
    private val target: WireTextEntryInteractionOptions.Mutable,
) : TextEntryInteractionScope {
    override fun selectAllOnFocus(value: Boolean) {
        target.selectAllOnFocus = value
    }
}

private class RuntimeValueExpressionScope<V>(
    override val value: Expr<V, Handled>,
) : ValueExpressionScope<V>

internal class RuntimeValueMappings<V>(
    private val state: PresentationBuildState,
    private val target: WireValueMappings.Mutable,
    private val payload: TypeTemplate,
) : ValueMappingScope<V> {
    override fun onComplete(body: ValueExpressionScope<V>.() -> Expr<V, Handled>) {
        target.completion = mapping("completion", payload, body)
    }

    override fun display(body: ValueExpressionScope<V>.() -> Expr<String, Handled>) {
        target.display = mapping("display", TEXT_SLOT, body)
    }

    /** A mapping evaluated with the edited value bound as its input, producing a value of [output] type. */
    private fun <R> mapping(
        purpose: String,
        output: TypeTemplate,
        body: ValueExpressionScope<V>.() -> Expr<R, Handled>,
    ): WireExpressionMapping =
        state.introduce("input.$purpose", payload, mayBeMissing = false) { input ->
            val receiver = RuntimeValueExpressionScope<V>(com.typewritermc.expression.inputExpression(input.id))
            WireExpressionMapping(inputBinding = input, body = state.lower(receiver.body(), output))
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

/** Bounds and step of a numeric input, each checked against the edited [payload] type. */
internal class RuntimeNumericInteraction<N>(
    private val state: PresentationBuildState,
    private val target: WireNumericInteractionOptions.Mutable,
    private val payload: TypeTemplate,
) : NumericInteractionScope<N> {
    override fun minimum(value: N) = minimum(numberLiteral(value))

    override fun minimum(value: Expr<N, Handled>) {
        target.minimum = state.lower(value, payload)
    }

    override fun maximum(value: N) = maximum(numberLiteral(value))

    override fun maximum(value: Expr<N, Handled>) {
        target.maximum = state.lower(value, payload)
    }

    override fun step(value: N) {
        require(value.toString().toBigDecimalOrNull()?.signum() == 1) { "Numeric step must be finite and positive." }
        step(numberLiteral(value))
    }

    override fun step(value: Expr<N, Handled>) {
        target.step = state.lower(value, payload)
    }

    override fun steppers(value: NumericSteppers) {
        target.steppers = value
    }

    override fun editingLocale(value: String) {
        require(value.isNotBlank())
        target.editingLocale = state.lower(literal(value), TEXT_SLOT)
    }

    override fun editingLocale(value: Expr<String, Handled>) {
        target.editingLocale = state.lower(value, TEXT_SLOT)
    }
}

internal class RuntimeTextEditing(
    private val target: WireTextEditingOptions.Mutable,
) : TextEditingScope {
    override fun lines(value: TextLines) {
        target.lines =
            when (value) {
                TextLines.Single -> WireTextLines.SINGLE
                is TextLines.Multiple -> WireTextLines.createMultiple(minimum = value.minimum, maximum = value.maximum)
            }
    }

    override fun purpose(value: TextPurpose) {
        target.purpose = value
    }

    override fun capitalization(value: TextCapitalization) {
        target.capitalization = value
    }

    override fun suggestions(value: Boolean) {
        target.suggestions = value
    }

    override fun length(value: TextLengthPolicy) {
        target.length = WireTextLengthPolicy(maximumGraphemes = value.maximum, enforceAfterComposition = value is TextLengthPolicy.Enforced)
    }

    override fun characterFilter(value: CharacterFilter) {
        val filter =
            when (value) {
                is CharacterFilter.Allow -> {
                    Regex(value.pattern)
                    WireCharacterFilter.AllowWrapper(value.pattern)
                }

                is CharacterFilter.Deny -> {
                    Regex(value.pattern)
                    WireCharacterFilter.DenyWrapper(value.pattern)
                }
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

    fun appearance(state: PresentationBuildState) = RuntimeTextEntryAppearance(state, appearance)

    fun content(
        state: PresentationBuildState,
        author: RuntimePresentationBuildScope,
    ) = RuntimeInputContent(state, author, content)

    fun entry() = RuntimeTextEntryInteraction(entry)

    fun <V> mappings(
        state: PresentationBuildState,
        payload: TypeTemplate,
    ) = RuntimeValueMappings<V>(state, mappings, payload)

    fun popup(state: PresentationBuildState) = RuntimePopupAppearance(state, popup)

    fun freeze() =
        FrozenInputConfiguration(appearance.toFrozen(), content.toFrozen(), entry.toFrozen(), mappings.toFrozen(), popup.toFrozen())
}

internal data class FrozenInputConfiguration(
    val appearance: WireInputAppearance,
    val content: WireInputContent,
    val entry: WireTextEntryInteractionOptions,
    val mappings: WireValueMappings,
    val popup: WirePopupAppearance,
)

private class RuntimeNumericInputScope<N>(
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

private class RuntimeTextInputScope(
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

internal class RuntimeInputConfigurationFactories(
    private val state: PresentationBuildState,
    private val payload: TypeTemplate,
) {
    /**
     * Requires the edited value to be a scalar this control edits, such as a number for a numeric input. A free type
     * parameter is no scalar, so a generic material cannot put such a control on a bare parameter.
     */
    private fun requirePayload(
        control: String,
        expected: String,
        accepts: (ScalarKind) -> Boolean,
    ) {
        val kind = (payload as? TypeTemplate.ScalarWrapper)?.value
        require(kind != null && accepts(kind)) { "A $control needs $expected, found ${payload.canonicalText}." }
    }

    private fun ScalarKind.isNumber(): Boolean =
        this is ScalarKind.IntegerWrapper || this is ScalarKind.FloatWrapper || this == ScalarKind.DECIMAL

    fun <N> numeric(
        author: RuntimePresentationBuildScope,
        configure: NumericInputScope<N>.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        requirePayload("numeric input", "a number") { it.isNumber() }
        val common = InputConfigurationDraft()
        val options = WireNumericInteractionOptions.partial().toMutable()
        RuntimeNumericInputScope(
            common.appearance(state),
            common.content(state, author),
            common.entry(),
            common.mappings<N>(state, payload),
            RuntimeNumericInteraction<N>(state, options, payload),
        ).configure()
        val frozen = common.freeze()
        val numeric = options.toFrozen()
        return { control ->
            WirePresentationElement.NumericInputWrapper(
                WireNumericControl(
                    control = control,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    entry = frozen.entry,
                    mappings = frozen.mappings,
                    options = numeric,
                ),
            )
        }
    }

    fun text(
        author: RuntimePresentationBuildScope,
        configure: TextInputScope.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        requirePayload("text input", "text") { it == ScalarKind.TEXT }
        val common = InputConfigurationDraft()
        val options = WireTextEditingOptions.partial().toMutable()
        RuntimeTextInputScope(
            common.appearance(state),
            common.content(state, author),
            common.entry(),
            common.mappings<String>(state, payload),
            RuntimeTextEditing(options),
        ).configure()
        val frozen = common.freeze()
        val text = options.toFrozen()
        return { control ->
            WirePresentationElement.TextInputWrapper(
                WireTextControl(
                    control = control,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    entry = frozen.entry,
                    mappings = frozen.mappings,
                    options = text,
                ),
            )
        }
    }

    fun dateTime(
        author: RuntimePresentationBuildScope,
        configure: DateTimeInputScope.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        requirePayload("date and time input", "a timestamp") { it == ScalarKind.TIMESTAMP }
        val common = InputConfigurationDraft()
        val options = WireDateTimeInteractionOptions.partial().toMutable()
        val interaction = RuntimeDateTimeInteraction(state, options)
        RuntimeDateTimeInputScope(
            common.appearance(state),
            common.content(state, author),
            common.entry(),
            common.mappings<kotlin.time.Instant>(state, payload),
            common.popup(state),
            interaction,
        ).configure()
        require(interaction.includeDate != false || interaction.includeTime != false) { "Date or time must be included." }
        val frozen = common.freeze()
        val native = options.toFrozen()
        val includeDate = interaction.includeDate
        val includeTime = interaction.includeTime
        return { control ->
            WirePresentationElement.DateTimeInputWrapper(
                WireDateTimeControl(
                    control = control,
                    includeDate = includeDate,
                    includeTime = includeTime,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    entry = frozen.entry,
                    mappings = frozen.mappings,
                    popup = frozen.popup,
                    options = native,
                ),
            )
        }
    }

    fun duration(
        author: RuntimePresentationBuildScope,
        configure: DurationInputScope.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        requirePayload("duration input", "a duration") { it == ScalarKind.DURATION }
        val common = InputConfigurationDraft()
        val options = WireDurationInteractionOptions.partial().toMutable()
        RuntimeDurationInputScope(
            state,
            common.appearance(state),
            common.content(state, author),
            common.entry(),
            common.mappings<kotlin.time.Duration>(state, payload),
            options,
        ).configure()
        val frozen = common.freeze()
        val native = options.toFrozen()
        return { control ->
            WirePresentationElement.DurationInputWrapper(
                WireDurationControl(
                    control = control,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    entry = frozen.entry,
                    mappings = frozen.mappings,
                    options = native,
                ),
            )
        }
    }

    fun color(
        author: RuntimePresentationBuildScope,
        configure: ColorInputScope.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireColorInteractionOptions.partial().toMutable()
        val receiver =
            RuntimeColorInputScope(
                state,
                common.appearance(state),
                common.content(state, author),
                common.entry(),
                common.mappings<com.typewritermc.types.Color>(state, payload),
                common.popup(state),
                options,
            )
        receiver.configure()
        val frozen = common.freeze()
        val native = options.toFrozen()
        val alpha = receiver.alpha
        return { control ->
            WirePresentationElement.ColorInputWrapper(
                WireColorControl(
                    control = control,
                    includeAlpha = alpha,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    entry = frozen.entry,
                    mappings = frozen.mappings,
                    popup = frozen.popup,
                    options = native,
                ),
            )
        }
    }

    fun bytes(
        author: RuntimePresentationBuildScope,
        configure: BytesInputScope.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        requirePayload("bytes input", "bytes") { it == ScalarKind.BYTES }
        val common = InputConfigurationDraft()
        val options = WireBytesInteractionOptions.partial().toMutable()
        RuntimeBytesInputScope(
            common.appearance(state),
            common.content(state, author),
            common.entry(),
            common.mappings<List<Byte>>(state, payload),
            options,
        ).configure()
        val frozen = common.freeze()
        val native = options.toFrozen()
        return { control ->
            WirePresentationElement.BytesInputWrapper(
                WireBytesControl(
                    control = control,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    entry = frozen.entry,
                    mappings = frozen.mappings,
                    options = native,
                ),
            )
        }
    }

    fun toggle(configure: ToggleInputScope.() -> Unit): (WireBoundControl) -> WirePresentationElement {
        requirePayload("toggle", "a boolean") { it == ScalarKind.BOOLEAN }
        val appearance = WireInputAppearance.partial().toMutable()
        val options = WireToggleInteractionOptions.partial().toMutable()
        RuntimeToggleInputScope(state, RuntimeTextEntryAppearance(state, appearance), options).configure()
        val frozen = appearance.toFrozen()
        val native = options.toFrozen()
        return { control ->
            WirePresentationElement.ToggleInputWrapper(WireToggleControl(control = control, appearance = frozen, options = native))
        }
    }

    fun <N> slider(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        configure: SliderInputScope<N>.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        requirePayload("slider", "a number") { it.isNumber() }
        val common = InputConfigurationDraft()
        val options = WireSliderInteractionOptions.partial().toMutable()
        val receiver = RuntimeSliderInputScope(state, common.appearance(state), common.mappings<N>(state, payload), options)
        receiver.configure()
        val appearance = common.appearance.toFrozen()
        val mappings = common.mappings.toFrozen()
        val native = options.toFrozen()
        val min = state.lower(minimum, payload)
        val max = state.lower(maximum, payload)
        val divisions = receiver.divisions
        return { control ->
            WirePresentationElement.SliderInputWrapper(
                WireSliderControl(
                    control = control,
                    minimum = min,
                    maximum = max,
                    divisions = divisions,
                    appearance = appearance,
                    mappings = mappings,
                    options = native,
                ),
            )
        }
    }

    fun <V> select(
        author: RuntimePresentationBuildScope,
        values: List<SelectOption<V>>,
        configure: SelectInputScope<V>.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        require(values.map { it.id }.toSet().size == values.size) { "Select option identifiers must be unique." }
        val common = InputConfigurationDraft()
        val options = WireSelectInteractionOptions.partial().toMutable()
        val receiver =
            RuntimeSelectInputScope<V>(
                state,
                author,
                common.appearance(state),
                common.content(state, author),
                common.popup(state),
                options,
                payload,
            )
        receiver.configure()
        val frozen = common.freeze()
        val native = receiver.finish(values.map { it.id }.toSet())
        val choices =
            values.map {
                WireSelectOption(
                    optionId = it.id,
                    label = state.lower(it.label, TEXT_SLOT),
                    value = state.lower(it.value, payload),
                    content = null,
                    enabledIf = null,
                    disabledReason = null,
                )
            }
        return { control ->
            WirePresentationElement.SelectInputWrapper(
                WireSelectControl(
                    control = control,
                    options = choices,
                    allowCustomValue =
                        native.customValue != null,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    popup = frozen.popup,
                    optionsConfig = native,
                ),
            )
        }
    }

    fun <V> enum(
        author: RuntimePresentationBuildScope,
        configure: SelectInputScope<V>.() -> Unit,
    ): (WireBoundControl) -> WirePresentationElement {
        val common = InputConfigurationDraft()
        val options = WireSelectInteractionOptions.partial().toMutable()
        val receiver =
            RuntimeSelectInputScope<V>(
                state,
                author,
                common.appearance(state),
                common.content(state, author),
                common.popup(state),
                options,
                payload,
            )
        receiver.configure()
        val frozen = common.freeze()
        val native = receiver.finish()
        return { control ->
            WirePresentationElement.EnumInputWrapper(
                WireEnumControl(
                    control = control,
                    appearance = frozen.appearance,
                    content = frozen.content,
                    popup = frozen.popup,
                    options = native,
                ),
            )
        }
    }
}

internal class RuntimeDateTimeInteraction(
    private val state: PresentationBuildState,
    private val target: WireDateTimeInteractionOptions.Mutable,
) {
    var includeDate: Boolean? = null
    var includeTime: Boolean? = null

    fun minimum(value: kotlin.time.Instant) {
        target.minimum = state.lower(literal(value), TIMESTAMP_SLOT)
    }

    fun minimum(value: Expr<kotlin.time.Instant, Handled>) {
        target.minimum = state.lower(value, TIMESTAMP_SLOT)
    }

    fun maximum(value: kotlin.time.Instant) {
        target.maximum = state.lower(literal(value), TIMESTAMP_SLOT)
    }

    fun maximum(value: Expr<kotlin.time.Instant, Handled>) {
        target.maximum = state.lower(value, TIMESTAMP_SLOT)
    }

    fun timeIncrement(value: kotlin.time.Duration) {
        require(value.isPositive())
        target.timeIncrement = state.lower(literal(value), DURATION_SLOT)
    }

    fun presentation(value: DateTimePickerPresentation) {
        target.presentation = value
    }
}

private class RuntimeDateTimeInputScope(
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

private class RuntimeDurationInputScope(
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

private class RuntimeColorInputScope(
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

private class RuntimeBytesInputScope(
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

private class RuntimeToggleInputScope(
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

private class RuntimeSliderInputScope<N>(
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

/** A literal of a Kotlin number of any family or signedness, for slots typed by the edited value. */
@Suppress("UNCHECKED_CAST")
internal fun <N> numberLiteral(value: N): Expr<N, Handled> =
    when (value) {
        is Number -> com.typewritermc.expression.numericLiteral(value)
        is UByte -> literal(value)
        is UShort -> literal(value)
        is UInt -> literal(value)
        is ULong -> literal(value)
        else -> throw IllegalArgumentException("Numeric presentation values must be Kotlin numbers.")
    } as Expr<N, Handled>
