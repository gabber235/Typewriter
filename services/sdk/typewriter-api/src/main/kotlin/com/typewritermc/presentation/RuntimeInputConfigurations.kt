package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.canonicalText
import com.typewritermc.types.integer
import com.typewritermc.types.template
import skirout.editor.v1.presentation.DateTimePickerPresentation
import skirout.editor.v1.presentation.NumericSteppers
import skirout.editor.v1.presentation.TextCapitalization
import skirout.editor.v1.presentation.TextPurpose
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.presentation.BoundControl as WireBoundControl
import skirout.editor.v1.presentation.BytesControl as WireBytesControl
import skirout.editor.v1.presentation.BytesInteractionOptions as WireBytesInteractionOptions
import skirout.editor.v1.presentation.CharacterFilter as WireCharacterFilter
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
import skirout.editor.v1.presentation.NumericControl as WireNumericControl
import skirout.editor.v1.presentation.NumericInteractionOptions as WireNumericInteractionOptions
import skirout.editor.v1.presentation.PopupAppearance as WirePopupAppearance
import skirout.editor.v1.presentation.PresentationElement as WirePresentationElement
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
