package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled

/** Native input paint shared by group defaults and local control overrides. */
enum class ControlDensity { Comfortable, Compact }

enum class TextAlignment { Start, Center, End }

interface GlyphContentScope {
    fun icon(
        id: String,
        color: PresentationColor? = null,
        size: Double? = null,
    )

    fun noIcon()
}

interface InputContentScope : GlyphContentScope {
    fun placeholder(value: String)

    fun placeholder(value: Expr<String, Handled>)

    fun prefix(body: Layout.() -> Unit)

    fun suffix(body: Layout.() -> Unit)
}

interface InputAppearanceScope {
    fun iconColor(value: PresentationColor)

    fun iconSize(value: Double)

    fun iconSize(value: Expr<Double, Handled>)

    fun textStyle(value: TextStyle)

    fun density(value: ControlDensity)

    fun padding(value: PresentationInsets)

    fun fill(value: PresentationColor)

    fun border(value: PresentationBorder)

    fun noBorder()

    fun radius(value: PresentationRadius)
}

interface TextEntryAppearanceScope : InputAppearanceScope {
    fun placeholderStyle(value: TextStyle)

    fun labelStyle(value: TextStyle)

    fun descriptionStyle(value: TextStyle)

    fun alignment(value: TextAlignment)
}

interface TextEntryInteractionScope {
    fun selectAllOnFocus(value: Boolean = true)
}

enum class NumericSteppers { Hidden, Inline }

interface NumericInteractionScope<N> {
    fun minimum(value: N)

    fun minimum(value: Expr<N, Handled>)

    fun maximum(value: N)

    fun maximum(value: Expr<N, Handled>)

    fun step(value: N)

    fun step(value: Expr<N, Handled>)

    fun steppers(value: NumericSteppers)

    fun editingLocale(value: String)

    fun editingLocale(value: Expr<String, Handled>)
}

interface NumericInputScope<N> :
    TextEntryAppearanceScope,
    InputContentScope,
    TextEntryInteractionScope,
    ValueMappingScope<N>,
    NumericInteractionScope<N>

sealed interface TextLines {
    data object Single : TextLines

    data class Multiple(
        val minimum: Int = 1,
        val maximum: Int? = null,
    ) : TextLines {
        init {
            require(minimum > 0)
            require(maximum == null || maximum >= minimum)
        }
    }
}

enum class TextPurpose { Plain, Email, Url, Password }

enum class TextCapitalization { None, Words, Sentences, Characters }

sealed interface TextLengthPolicy {
    val maximum: Int

    data class CounterOnly(
        override val maximum: Int,
    ) : TextLengthPolicy {
        init {
            require(maximum > 0)
        }
    }

    data class Enforced(
        override val maximum: Int,
    ) : TextLengthPolicy {
        init {
            require(maximum > 0)
        }
    }
}

sealed interface CharacterFilter {
    data class Allow(
        val pattern: String,
    ) : CharacterFilter

    data class Deny(
        val pattern: String,
    ) : CharacterFilter
}

interface TextEditingScope {
    fun lines(value: TextLines)

    fun purpose(value: TextPurpose)

    fun capitalization(value: TextCapitalization)

    fun suggestions(value: Boolean)

    fun length(value: TextLengthPolicy)

    fun characterFilter(value: CharacterFilter)
}

interface TextInputScope :
    TextEntryAppearanceScope,
    InputContentScope,
    TextEntryInteractionScope,
    ValueMappingScope<String>,
    TextEditingScope

interface ValueExpressionScope<V> {
    val value: Expr<V, Handled>
}

interface ValueMappingScope<V> {
    fun onComplete(body: ValueExpressionScope<V>.() -> Expr<V, Handled>)

    fun display(body: ValueExpressionScope<V>.() -> Expr<String, Handled>)
}

enum class DateTimePickerPresentation { Calendar, Text }

enum class ColorEditingRepresentation { Hex, Rgb, Hsl }

enum class ColorPickerFormat { Hex, Rgb, Hsl }

enum class BytesEditingEncoding { Hexadecimal, Base64 }

enum class TogglePresentation { Switch, Checkbox }

enum class TogglePosition { Leading, Trailing }

enum class SliderValueDisplay { Hidden, WhileInteracting, Always }

enum class SliderOrientation { Horizontal, Vertical }

enum class SliderInteraction { TapAndDrag, DragOnly }

interface PopupAppearanceScope {
    fun minimumPopupWidth(value: Double)

    fun minimumPopupWidth(value: Expr<Double, Handled>)

    fun maximumPopupWidth(value: Double)

    fun maximumPopupWidth(value: Expr<Double, Handled>)

    fun maximumExtent(value: Double)

    fun maximumExtent(value: Expr<Double, Handled>)

    fun popupPadding(value: PresentationInsets)

    fun popupFill(value: PresentationColor)

    fun popupBorder(value: PresentationBorder)

    fun popupRadius(value: PresentationRadius)
}

interface DateTimeInputScope :
    TextEntryAppearanceScope,
    InputContentScope,
    TextEntryInteractionScope,
    ValueMappingScope<kotlin.time.Instant>,
    PopupAppearanceScope {
    fun includeDate(value: Boolean)

    fun includeTime(value: Boolean)

    fun minimum(value: kotlin.time.Instant)

    fun minimum(value: Expr<kotlin.time.Instant, Handled>)

    fun maximum(value: kotlin.time.Instant)

    fun maximum(value: Expr<kotlin.time.Instant, Handled>)

    fun timeIncrement(value: kotlin.time.Duration)

    fun presentation(value: DateTimePickerPresentation)
}

interface DurationInputScope :
    TextEntryAppearanceScope,
    InputContentScope,
    TextEntryInteractionScope,
    ValueMappingScope<kotlin.time.Duration> {
    fun minimum(value: kotlin.time.Duration)

    fun minimum(value: Expr<kotlin.time.Duration, Handled>)

    fun maximum(value: kotlin.time.Duration)

    fun maximum(value: Expr<kotlin.time.Duration, Handled>)

    fun step(value: kotlin.time.Duration)

    fun step(value: Expr<kotlin.time.Duration, Handled>)
}

interface ColorInputScope :
    TextEntryAppearanceScope,
    InputContentScope,
    TextEntryInteractionScope,
    ValueMappingScope<com.typewritermc.types.Color>,
    PopupAppearanceScope {
    fun includeAlpha(value: Boolean)

    fun editingRepresentation(value: ColorEditingRepresentation)

    fun pickerFormat(value: ColorPickerFormat)

    fun showSwatch(value: Boolean = true)

    fun showFormatSelector(value: Boolean = true)

    fun showCopyAction(value: Boolean = true)

    fun offeredSwatches(value: List<com.typewritermc.types.Color>)

    fun offeredSwatches(value: Expr<List<com.typewritermc.types.Color>, Handled>)
}

interface BytesInputScope :
    TextEntryAppearanceScope,
    InputContentScope,
    TextEntryInteractionScope,
    ValueMappingScope<List<Byte>> {
    fun editingEncoding(value: BytesEditingEncoding)

    fun groupSize(value: Int)

    fun showCount(value: Boolean = true)
}

interface ToggleInputScope : InputAppearanceScope {
    fun presentation(value: TogglePresentation)

    fun position(value: TogglePosition)

    fun trueLabel(value: String)

    fun trueLabel(value: Expr<String, Handled>)

    fun falseLabel(value: String)

    fun falseLabel(value: Expr<String, Handled>)

    fun thumbColor(value: PresentationColor)

    fun trackColor(value: PresentationColor)

    fun checkColor(value: PresentationColor)
}

interface SliderInputScope<N> : InputAppearanceScope {
    fun divisions(value: Int)

    fun divisions(value: Expr<Int, Handled>)

    fun showValue(value: SliderValueDisplay)

    fun display(body: ValueExpressionScope<N>.() -> Expr<String, Handled>)

    fun showTicks(value: Boolean = true)

    fun orientation(value: SliderOrientation)

    fun interaction(value: SliderInteraction)

    fun activeColor(value: PresentationColor)

    fun inactiveColor(value: PresentationColor)

    fun thumbColor(value: PresentationColor)

    fun trackHeight(value: Double)
}

enum class ChoicePresentation { Automatic, Dropdown, Segmented, Radio }

enum class ButtonVariant { Filled, Outlined, Text }

enum class PopupSide { Automatic, Above, Below }

interface SelectInputScope<V> :
    TextEntryAppearanceScope,
    InputContentScope,
    PopupAppearanceScope {
    val query: Expr<String, Handled>

    fun presentation(value: ChoicePresentation)

    fun filtering(value: Boolean = true)

    fun maximumMenuHeight(value: Double)

    fun maximumMenuHeight(value: Expr<Double, Handled>)

    fun selectedTextStyle(value: TextStyle)

    fun optionContent(
        id: String,
        body: Layout.() -> Unit,
    )

    fun optionEnabled(
        id: String,
        value: Expr<Boolean, Handled>,
    )

    fun optionDisabledReason(
        id: String,
        value: String,
    )

    fun optionDisabledReason(
        id: String,
        value: Expr<String, Handled>,
    )

    fun customValue(value: Expr<V, Handled>)
}

interface ActionAppearanceScope : InputAppearanceScope {
    fun variant(value: ButtonVariant)

    fun tooltip(value: String)

    fun tooltip(value: Expr<String, Handled>)
}

interface ButtonScope :
    ActionAppearanceScope,
    GlyphContentScope

interface IconButtonScope : ActionAppearanceScope

interface MenuItemScope : GlyphContentScope {
    fun description(value: String)

    fun description(value: Expr<String, Handled>)

    fun enabledIf(value: Expr<Boolean, Handled>)

    fun disabledReason(value: String)

    fun disabledReason(value: Expr<String, Handled>)
}

interface MenuScope :
    ActionAppearanceScope,
    PopupAppearanceScope {
    fun item(
        id: String,
        label: Expr<String, Handled>,
        action: skirout.editor.v1.action.EditorAction,
        configure: MenuItemScope.() -> Unit = {},
    )

    fun separator(id: String)
}

/** Reusable sparse paint. Expressions acquire their context at wrapper application. */
typealias InputAppearance = skirout.editor.v1.presentation.InputAppearance

fun inputAppearance(configure: TextEntryAppearanceScope.() -> Unit): InputAppearance {
    val draft = InputAppearance.partial().toMutable()
    RuntimeTextEntryAppearance(draft).configure()
    return draft.toFrozen()
}

interface InputAppearanceLayout {
    fun withInputAppearance(
        appearance: InputAppearance,
        body: Layout.() -> Unit,
    )
}
