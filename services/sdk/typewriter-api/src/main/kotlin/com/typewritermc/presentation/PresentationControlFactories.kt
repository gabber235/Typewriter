package com.typewritermc.presentation

import com.typewritermc.discovery.GraphDirection
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import kotlin.reflect.KClass

/** Selects typed control implementations for one presentation build. */
internal class PresentationControlFactories {
    private val factories = mutableMapOf<KClass<*>, (RuntimeControlBinding) -> Any>()

    init {
        register(Control::class) { it }
        register(ChoiceControl::class) { RuntimeChoiceControl<Any?>(it) }
        register(TextControl::class, ::RuntimeTextControl)
        register(NumberControl::class) { RuntimeNumberControl<Any?>(it) }
        register(BooleanControl::class, ::RuntimeBooleanControl)
        register(ColorControl::class, ::RuntimeColorControl)
        register(BytesControl::class, ::RuntimeBytesControl)
        register(EnumControl::class) { RuntimeEnumControl<Any?>(it) }
        register(DateTimeControl::class, ::RuntimeDateTimeControl)
        register(DurationControl::class, ::RuntimeDurationControl)
        register(NamedControl::class) { RuntimeNamedControl<Any?, Any>(it) }
        register(RecordControl::class) { RuntimeRecordControl<Layout>(it) }
        register(ListControl::class) { RuntimeListControl<Any>(it) }
        register(ResourceLinksControl::class) { RuntimeResourceLinksControl<Resource>(it) }
        register(SetControl::class) { RuntimeSetControl<Any>(it) }
        register(MapControl::class) { RuntimeMapControl<Any, Any>(it) }
        register(NullableControl::class) { RuntimeNullableControl<Any>(it) }
        register(PolymorphicControl::class) { RuntimePolymorphicControl<Any?>(it) }
        register(LinkControl::class) { RuntimeLinkControl<Resource>(it) }
        register(LinkCollectionControl::class) { RuntimeLinkCollectionControl<Resource>(it) }
    }

    private fun <S : Any> register(
        scope: KClass<S>,
        create: (RuntimeControlBinding) -> S,
    ) {
        require(scope !in factories) { "A control scope may have one typed factory." }
        factories[scope] = create
    }

    fun <S : Any> create(
        scope: KClass<S>,
        binding: RuntimeControlBinding,
    ): S {
        val factory = requireNotNull(factories[scope]) { "No typed control factory for ${scope.qualifiedName}." }
        return checkedGeneratedScope(scope, factory(binding))
    }
}

private class RuntimeChoiceControl<V>(
    private val binding: RuntimeControlBinding,
) : ChoiceControl<V>,
    Control by binding {
    override fun selectInput(
        options: List<SelectOption<V>>,
        allowCustomValue: Boolean,
    ) = binding.selectInput(options, allowCustomValue)

    override fun <Row> searchInput(configure: SearchInputScope<V, Row>.() -> Unit) = binding.searchInput(configure)
}

private class RuntimeTextControl(
    private val binding: RuntimeControlBinding,
) : TextControl,
    ChoiceControl<String> by RuntimeChoiceControl(binding) {
    override fun textInput(
        multiline: Boolean,
        placeholder: Expr<String, Handled>?,
        formatters: List<TextInputFormat>,
    ) = binding.textInput(multiline, placeholder, formatters)
}

private class RuntimeNumberControl<N>(
    private val binding: RuntimeControlBinding,
) : NumberControl<N>,
    ChoiceControl<N> by RuntimeChoiceControl(binding) {
    override fun numericInput() = binding.numericInput()

    override fun sliderInput(
        minimum: N,
        maximum: N,
        divisions: Int?,
    ) = binding.sliderInput(minimum, maximum, divisions)

    override fun sliderInput(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        divisions: Expr<Int, Handled>?,
    ) = binding.sliderInput(minimum, maximum, divisions)
}

private class RuntimeBooleanControl(
    private val binding: RuntimeControlBinding,
) : BooleanControl,
    ChoiceControl<Boolean> by RuntimeChoiceControl(binding) {
    override fun toggleInput() = binding.toggleInput()
}

private class RuntimeColorControl(
    private val binding: RuntimeControlBinding,
) : ColorControl,
    ChoiceControl<com.typewritermc.types.Color> by RuntimeChoiceControl(binding) {
    override fun colorInput(includeAlpha: Boolean) = binding.colorInput(includeAlpha)
}

private class RuntimeBytesControl(
    private val binding: RuntimeControlBinding,
) : BytesControl,
    ChoiceControl<List<Byte>> by RuntimeChoiceControl(binding) {
    override fun bytesInput() = binding.bytesInput()
}

private class RuntimeEnumControl<E>(
    private val binding: RuntimeControlBinding,
) : EnumControl<E>,
    ChoiceControl<E> by RuntimeChoiceControl(binding) {
    override fun enumInput() = binding.enumInput()
}

private class RuntimeDateTimeControl(
    private val binding: RuntimeControlBinding,
) : DateTimeControl,
    ChoiceControl<kotlin.time.Instant> by RuntimeChoiceControl(binding) {
    override fun dateTimeInput(
        includeDate: Boolean,
        includeTime: Boolean,
    ) = binding.dateTimeInput(includeDate, includeTime)
}

private class RuntimeDurationControl(
    private val binding: RuntimeControlBinding,
) : DurationControl,
    ChoiceControl<kotlin.time.Duration> by RuntimeChoiceControl(binding) {
    override fun durationInput() = binding.durationInput()
}

private class RuntimeNamedControl<V, PayloadScope>(
    private val binding: RuntimeControlBinding,
) : NamedControl<V, PayloadScope>,
    ChoiceControl<V> by RuntimeChoiceControl(binding) {
    override fun namedInput(payload: ControlConfiguration<PayloadScope>) = binding.namedInput(payload)
}

private class RuntimeRecordControl<Fields : Layout>(
    private val binding: RuntimeControlBinding,
) : RecordControl<Fields>,
    Control by binding {
    override fun recordInput(fields: ControlConfiguration<Fields>) = binding.recordInput(fields)
}

private class RuntimeListControl<ItemScope>(
    private val binding: RuntimeControlBinding,
) : ListControl<ItemScope>,
    Control by binding {
    override fun listInput(
        allowAdd: Boolean,
        allowRemove: Boolean,
        allowReorder: Boolean,
        items: ControlConfiguration<ItemScope>,
    ) = binding.listInput(allowAdd, allowRemove, allowReorder, items)
}

private class RuntimeSetControl<ItemScope>(
    private val binding: RuntimeControlBinding,
) : SetControl<ItemScope>,
    Control by binding {
    override fun collectionInput(
        allowAdd: Boolean,
        allowRemove: Boolean,
        items: ControlConfiguration<ItemScope>,
    ) = binding.collectionInput(allowAdd, allowRemove, items)
}

private class RuntimeMapControl<KeyScope, ValueScope>(
    private val binding: RuntimeControlBinding,
) : MapControl<KeyScope, ValueScope>,
    Control by binding {
    override fun mapInput(
        allowAdd: Boolean,
        allowRemove: Boolean,
        keys: ControlConfiguration<KeyScope>,
        values: ControlConfiguration<ValueScope>,
    ) = binding.mapInput(allowAdd, allowRemove, keys, values)
}

private class RuntimeNullableControl<ValueScope>(
    private val binding: RuntimeControlBinding,
) : NullableControl<ValueScope>,
    Control by binding {
    override fun nullableInput(value: ControlConfiguration<ValueScope>) = binding.nullableInput(value)
}

private class RuntimePolymorphicControl<V>(
    private val binding: RuntimeControlBinding,
) : PolymorphicControl<V>,
    Control by binding {
    override fun polymorphicInput(configure: ConcreteForms<V>.() -> Unit) = binding.polymorphicInput(configure)
}

private class RuntimeLinkControl<R : Resource>(
    private val binding: RuntimeControlBinding,
) : LinkControl<R>,
    Control by binding {
    override fun linkInput(
        source: CollectionSource<*, ResourceId>?,
        policy: LinkCandidatePolicyId?,
        rejection: LinkRejectionDisplay,
    ) = binding.linkInput(false, source, policy, rejection)
}

private class RuntimeLinkCollectionControl<R : Resource>(
    private val binding: RuntimeControlBinding,
) : LinkCollectionControl<R>,
    Control by binding {
    override fun linkInput(
        allowReorder: Boolean,
        source: CollectionSource<*, ResourceId>?,
        policy: LinkCandidatePolicyId?,
        rejection: LinkRejectionDisplay,
    ) = binding.linkInput(allowReorder, source, policy, rejection)
}

private class RuntimeResourceLinksControl<R : Resource>(
    private val binding: RuntimeControlBinding,
) : ResourceLinksControl<R>,
    ListControl<LinkControl<R>> by RuntimeListControl(binding) {
    override fun graphPage(direction: GraphDirection) = binding.graphPage(direction)

    override fun timelinePage() = binding.timelinePage()
}
