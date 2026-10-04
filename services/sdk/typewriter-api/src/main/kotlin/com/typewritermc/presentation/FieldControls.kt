package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Color
import kotlin.time.Duration
import kotlin.time.Instant

interface PresentationReference

typealias ControlConfiguration<Scope> = Scope.() -> Unit

interface PresentedField<Value, Scope> {
    val input: PresentationInput<Value, Scope>

    operator fun invoke(
        using: PresentationReference? = null,
        configure: ControlConfiguration<Scope> = {},
    )
}

interface Control {
    fun label(text: String)

    fun label(text: Expr<String, Handled>)

    fun description(text: Expr<String, Handled>)

    fun semanticLabel(text: Expr<String, Handled>)

    fun icon(id: String)

    fun prefix(body: Layout.() -> Unit)

    fun enabledIf(condition: Expr<Boolean, Handled>)

    fun readOnly(value: Boolean = true)
}

data class SelectOption<V>(
    val id: String,
    val label: Expr<String, Handled>,
    val value: Expr<V, Handled>,
)

interface ChoiceControl<V> : Control {
    fun selectInput(
        options: List<SelectOption<V>>,
        allowCustomValue: Boolean = false,
    )

    fun <Row> searchInput(configure: SearchInputScope<V, Row>.() -> Unit)
}

interface TextControl : ChoiceControl<String> {
    fun textInput(
        multiline: Boolean = false,
        placeholder: Expr<String, Handled>? = null,
        formatters: List<TextInputFormat> = emptyList(),
    )
}

interface NumberControl<N> : ChoiceControl<N> {
    fun numericInput()

    fun sliderInput(
        minimum: N,
        maximum: N,
        divisions: Int? = null,
    )

    fun sliderInput(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        divisions: Expr<Int, Handled>? = null,
    )
}

interface BooleanControl : ChoiceControl<Boolean> {
    fun toggleInput()
}

interface ColorControl : ChoiceControl<Color> {
    fun colorInput(includeAlpha: Boolean = false)
}

interface BytesControl : ChoiceControl<List<Byte>> {
    fun bytesInput()
}

interface EnumControl<E> : ChoiceControl<E> {
    fun enumInput()
}

interface DateTimeControl : ChoiceControl<Instant> {
    fun dateTimeInput(
        includeDate: Boolean = true,
        includeTime: Boolean = true,
    )
}

interface DurationControl : ChoiceControl<Duration> {
    fun durationInput()
}

interface NamedControl<V, PayloadScope> : ChoiceControl<V> {
    fun namedInput(payload: ControlConfiguration<PayloadScope> = {})
}

sealed interface TextInputFormat {
    data object Trim : TextInputFormat

    data class Pattern(
        val regex: String,
    ) : TextInputFormat
}
