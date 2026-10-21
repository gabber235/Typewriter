package com.typewritermc.presentation

import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.TypedPath
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import skirout.editor.v1.presentation.GraphDirection
import skirout.editor.v1.presentation.LinkRejectionDisplay
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
        register(ResourcesControl::class) { RuntimeResourcesControl<Resource>(it) }
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
        configure: SelectInputScope<V>.() -> Unit,
    ) = binding.selectInput(options, configure)

    override fun <Row> searchInput(configure: SearchInputScope<V, Row>.() -> Unit) = binding.searchInput(configure)
}

private class RuntimeTextControl(
    private val binding: RuntimeControlBinding,
) : TextControl,
    ChoiceControl<String> by RuntimeChoiceControl(binding) {
    override fun textInput(configure: TextInputScope.() -> Unit) = binding.textInput(configure)
}

private class RuntimeNumberControl<N>(
    private val binding: RuntimeControlBinding,
) : NumberControl<N>,
    ChoiceControl<N> by RuntimeChoiceControl(binding) {
    override fun numericInput(configure: NumericInputScope<N>.() -> Unit) = binding.numericInput(configure)

    override fun sliderInput(
        minimum: N,
        maximum: N,
        configure: SliderInputScope<N>.() -> Unit,
    ) = binding.sliderInput(minimum, maximum, configure)

    override fun sliderInput(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        configure: SliderInputScope<N>.() -> Unit,
    ) = binding.sliderInput(minimum, maximum, configure)
}

private class RuntimeBooleanControl(
    private val binding: RuntimeControlBinding,
) : BooleanControl,
    ChoiceControl<Boolean> by RuntimeChoiceControl(binding) {
    override fun toggleInput(configure: ToggleInputScope.() -> Unit) = binding.toggleInput(configure)
}

private class RuntimeColorControl(
    private val binding: RuntimeControlBinding,
) : ColorControl,
    ChoiceControl<com.typewritermc.types.Color> by RuntimeChoiceControl(binding) {
    override fun colorInput(configure: ColorInputScope.() -> Unit) = binding.colorInput(configure)
}

private class RuntimeBytesControl(
    private val binding: RuntimeControlBinding,
) : BytesControl,
    ChoiceControl<List<Byte>> by RuntimeChoiceControl(binding) {
    override fun bytesInput(configure: BytesInputScope.() -> Unit) = binding.bytesInput(configure)
}

private class RuntimeEnumControl<E>(
    private val binding: RuntimeControlBinding,
) : EnumControl<E>,
    ChoiceControl<E> by RuntimeChoiceControl(binding) {
    override fun enumInput(configure: SelectInputScope<E>.() -> Unit) = binding.enumInput(configure)
}

private class RuntimeDateTimeControl(
    private val binding: RuntimeControlBinding,
) : DateTimeControl,
    ChoiceControl<kotlin.time.Instant> by RuntimeChoiceControl(binding) {
    override fun dateTimeInput(configure: DateTimeInputScope.() -> Unit) = binding.dateTimeInput(configure)
}

private class RuntimeDurationControl(
    private val binding: RuntimeControlBinding,
) : DurationControl,
    ChoiceControl<kotlin.time.Duration> by RuntimeChoiceControl(binding) {
    override fun durationInput(configure: DurationInputScope.() -> Unit) = binding.durationInput(configure)
}

private class RuntimeNamedControl<V, PayloadScope>(
    private val binding: RuntimeControlBinding,
) : NamedControl<V, PayloadScope>,
    ChoiceControl<V> by RuntimeChoiceControl(binding) {
    override fun namedInput(configure: NamedInputScope<PayloadScope>.() -> Unit) = binding.namedInput(configure)
}

private class RuntimeRecordControl<Fields : Layout>(
    private val binding: RuntimeControlBinding,
) : RecordControl<Fields>,
    Control by binding {
    override fun recordInput(configure: RecordInputScope<Fields>.() -> Unit) = binding.recordInput(configure)
}

private class RuntimeListControl<ItemScope>(
    private val binding: RuntimeControlBinding,
) : ListControl<ItemScope>,
    Control by binding {
    override fun listInput(configure: ListInputScope<ItemScope>.() -> Unit) = binding.listInput(configure)
}

private class RuntimeSetControl<ItemScope>(
    private val binding: RuntimeControlBinding,
) : SetControl<ItemScope>,
    Control by binding {
    override fun collectionInput(configure: SetInputScope<ItemScope>.() -> Unit) = binding.collectionInput(configure)
}

private class RuntimeMapControl<KeyScope, ValueScope>(
    private val binding: RuntimeControlBinding,
) : MapControl<KeyScope, ValueScope>,
    Control by binding {
    override fun mapInput(configure: MapInputScope<KeyScope, ValueScope>.() -> Unit) = binding.mapInput(configure)
}

private class RuntimeNullableControl<ValueScope>(
    private val binding: RuntimeControlBinding,
) : NullableControl<ValueScope>,
    Control by binding {
    override fun nullableInput(configure: NullableInputScope<ValueScope>.() -> Unit) = binding.nullableInput(configure)
}

private class RuntimePolymorphicControl<V>(
    private val binding: RuntimeControlBinding,
) : PolymorphicControl<V>,
    Control by binding {
    override fun polymorphicInput(configure: PolymorphicInputScope<V>.() -> Unit) = binding.polymorphicInput(configure)
}

private class RuntimeLinkControl<R : Resource>(
    private val binding: RuntimeControlBinding,
) : LinkControl<R>,
    Control by binding {
    override fun linkInput(
        source: CollectionSource<*, ResourceId>?,
        policy: LinkCandidatePolicyId?,
        rejection: LinkRejectionDisplay,
        configure: LinkInputScope.() -> Unit,
    ) = binding.linkInput(false, source, policy, rejection, configure)
}

private class RuntimeLinkCollectionControl<R : Resource>(
    private val binding: RuntimeControlBinding,
) : LinkCollectionControl<R>,
    Control by binding {
    override fun linkInput(
        source: CollectionSource<*, ResourceId>?,
        policy: LinkCandidatePolicyId?,
        rejection: LinkRejectionDisplay,
        configure: LinkInputScope.() -> Unit,
    ) = binding.linkInput(true, source, policy, rejection, configure)
}

private class RuntimeResourcesControl<R : Resource>(
    private val binding: RuntimeControlBinding,
) : ResourcesControl<R>,
    ListControl<LinkControl<R>> by RuntimeListControl(binding) {
    @Suppress("UNCHECKED_CAST")
    override fun order(key: ResourceItemScope<R>.() -> Expr<*, Handled>) = binding.order(key as ResourceItemScope<*>.() -> Expr<*, Handled>)

    override fun graph(
        direction: GraphDirection,
        configure: GraphAppearanceScope.() -> Unit,
    ) = binding.graph(direction, configure)

    override fun timeline(configure: TimelineAppearanceScope.() -> Unit) = binding.timeline(configure)

    override fun grid(
        itemExtent: Double,
        aspectRatio: Double,
        spacing: Double,
    ) = binding.grid(itemExtent, aspectRatio, spacing)

    override fun list() = binding.list()

    override fun tree(
        path: TypedPath<R, HierarchyPath>,
        configure: TreeScope.() -> Unit,
    ) = binding.tree(path, configure)
}
