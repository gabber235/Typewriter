package com.typewritermc.presentation

import com.typewritermc.dsl.TypewriterDsl
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

@TypewriterDsl
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
        configure: SelectInputScope<V>.() -> Unit = {},
    )

    fun <Row> searchInput(configure: SearchInputScope<V, Row>.() -> Unit)
}

interface TextControl : ChoiceControl<String> {
    fun textInput(configure: TextInputScope.() -> Unit = {})
}

interface NumberControl<N> : ChoiceControl<N> {
    fun numericInput(configure: NumericInputScope<N>.() -> Unit = {})

    fun sliderInput(
        minimum: N,
        maximum: N,
        configure: SliderInputScope<N>.() -> Unit = {},
    )

    fun sliderInput(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        configure: SliderInputScope<N>.() -> Unit = {},
    )
}

interface BooleanControl : ChoiceControl<Boolean> {
    fun toggleInput(configure: ToggleInputScope.() -> Unit = {})
}

interface ColorControl : ChoiceControl<Color> {
    fun colorInput(configure: ColorInputScope.() -> Unit = {})
}

interface BytesControl : ChoiceControl<List<Byte>> {
    fun bytesInput(configure: BytesInputScope.() -> Unit = {})
}

interface EnumControl<E> : ChoiceControl<E> {
    fun enumInput(configure: SelectInputScope<E>.() -> Unit = {})
}

interface DateTimeControl : ChoiceControl<Instant> {
    fun dateTimeInput(configure: DateTimeInputScope.() -> Unit = {})
}

interface DurationControl : ChoiceControl<Duration> {
    fun durationInput(configure: DurationInputScope.() -> Unit = {})
}

interface NamedControl<V, PayloadScope> : ChoiceControl<V> {
    fun namedInput(configure: NamedInputScope<PayloadScope>.() -> Unit = {})
}
