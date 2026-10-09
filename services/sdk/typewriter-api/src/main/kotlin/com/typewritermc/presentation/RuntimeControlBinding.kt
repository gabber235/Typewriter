package com.typewritermc.presentation

import com.typewritermc.discovery.GraphDirection
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.PageGraphDirection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

internal class RuntimeControlBinding(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
    private val field: String,
    private val fieldBinding: BindingRef,
    private val checked: CheckedPresentationTemplate,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val selectedPresentation: skirout.editor.v1.type_catalog.PresentationId?,
) : Control {
    var emitted = false
        private set
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var semanticLabel: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var prefix: PresentationNode? = null
    private var readOnly = false

    override fun label(text: String) {
        label = expression(text)
    }

    override fun label(text: Expr<String, Handled>) {
        label = expression(text)
    }

    override fun description(text: Expr<String, Handled>) {
        description = expression(text)
    }

    override fun semanticLabel(text: Expr<String, Handled>) {
        semanticLabel = expression(text)
    }

    override fun enabledIf(condition: Expr<Boolean, Handled>) {
        enabledIf = expression(condition)
    }

    override fun readOnly(value: Boolean) {
        readOnly = value
    }

    fun textInput(
        multiline: Boolean,
        placeholder: Expr<String, Handled>?,
        formatters: List<TextInputFormat>,
    ) {
        val formats =
            formatters.map { format ->
                when (format) {
                    TextInputFormat.Trim -> {
                        skirout.editor.v1.presentation.TextInputFormat.createReplace(
                            pattern = "^\\s+|\\s+$",
                            replacement = "",
                        )
                    }

                    is TextInputFormat.Pattern -> {
                        skirout.editor.v1.presentation.TextInputFormat
                            .AllowWrapper(format.regex)
                    }
                }
            }
        emit(
            PresentationElement.createTextInput(
                control = boundControl(),
                multiline = multiline,
                placeholder = placeholder?.let(::expression),
                inputFormatters = formats,
            ),
        )
    }

    fun <V> selectInput(
        options: List<SelectOption<V>>,
        allowCustomValue: Boolean,
    ) {
        val wireOptions =
            options.map { option ->
                skirout.editor.v1.presentation.SelectOption(
                    optionId = option.id,
                    label = expression(option.label),
                    value = expression(option.value),
                )
            }
        emit(
            PresentationElement.createSelectInput(
                control = boundControl(),
                options = wireOptions,
                allowCustomValue = allowCustomValue,
            ),
        )
    }

    fun <N> sliderInput(
        minimum: N,
        maximum: N,
        divisions: Int?,
    ) = sliderInputWire(expression(minimum), expression(maximum), divisions?.let(::expression))

    fun <N> sliderInput(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        divisions: Expr<Int, Handled>?,
    ) = sliderInputWire(expression(minimum), expression(maximum), divisions?.let(::expression))

    private fun sliderInputWire(
        minimum: skirout.editor.v1.expression.ExpressionNode,
        maximum: skirout.editor.v1.expression.ExpressionNode,
        divisions: skirout.editor.v1.expression.ExpressionNode?,
    ) {
        emit(
            PresentationElement.createSliderInput(
                control = boundControl(),
                minimum = minimum,
                maximum = maximum,
                divisions = divisions,
            ),
        )
    }

    fun <V, Row> searchInput(configure: SearchInputScope<V, Row>.() -> Unit) {
        val search = RuntimeSearchInputScope<V, Row>(state)
        search.configure()
        emit(search.element(boundControl()))
    }

    fun <Scope> namedInput(payload: ControlConfiguration<Scope>) {
        emit(
            PresentationElement.createNamedInput(
                control = boundControl(),
                payloadPresentation = nestedPresentation(payload, NestedPresentationSlot.Payload),
            ),
        )
    }

    fun <Fields : Layout> recordInput(fields: ControlConfiguration<Fields>) {
        emit(
            PresentationElement.createRecordInput(
                control = boundControl(),
                fieldPresentation = nestedPresentation(fields, NestedPresentationSlot.Fields),
            ),
        )
    }

    fun graphPage(direction: GraphDirection) {
        val wireDirection =
            when (direction) {
                GraphDirection.LEFT_TO_RIGHT -> PageGraphDirection.LEFT_TO_RIGHT
                GraphDirection.RIGHT_TO_LEFT -> PageGraphDirection.RIGHT_TO_LEFT
                GraphDirection.TOP_TO_BOTTOM -> PageGraphDirection.TOP_TO_BOTTOM
                GraphDirection.BOTTOM_TO_TOP -> PageGraphDirection.BOTTOM_TO_TOP
            }
        emit(PresentationElement.createPageGraph(control = boundControl(), direction = wireDirection))
    }

    fun timelinePage() {
        emit(PresentationElement.createPageTimeline(control = boundControl()))
    }

    fun <Scope> listInput(
        allowAdd: Boolean,
        allowRemove: Boolean,
        allowReorder: Boolean,
        items: ControlConfiguration<Scope>,
    ) {
        emit(
            PresentationElement.createListInput(
                control = boundControl(),
                itemPresentation = nestedPresentation(items, NestedPresentationSlot.Items),
                allowAdd = allowAdd,
                allowRemove = allowRemove,
                allowReorder = allowReorder,
                itemBindingId = WireExpressionBindingId(value = "list_item"),
                indexBindingId = WireExpressionBindingId(value = "list_index"),
            ),
        )
    }

    fun <Scope> collectionInput(
        allowAdd: Boolean,
        allowRemove: Boolean,
        items: ControlConfiguration<Scope>,
    ) {
        emit(
            PresentationElement.createSetInput(
                control = boundControl(),
                itemPresentation = nestedPresentation(items, NestedPresentationSlot.Items),
                allowAdd = allowAdd,
                allowRemove = allowRemove,
                itemBindingId = WireExpressionBindingId(value = "set_item"),
            ),
        )
    }

    fun <KeyScope, ValueScope> mapInput(
        allowAdd: Boolean,
        allowRemove: Boolean,
        keys: ControlConfiguration<KeyScope>,
        values: ControlConfiguration<ValueScope>,
    ) {
        emit(
            PresentationElement.createMapInput(
                control = boundControl(),
                keyPresentation = nestedPresentation(keys, NestedPresentationSlot.Keys),
                valuePresentation = nestedPresentation(values, NestedPresentationSlot.Values),
                allowAdd = allowAdd,
                allowRemove = allowRemove,
                keyBindingId = WireExpressionBindingId(value = "map_key"),
                valueBindingId = WireExpressionBindingId(value = "map_value"),
            ),
        )
    }

    fun <Scope> nullableInput(value: ControlConfiguration<Scope>) {
        emit(
            PresentationElement.createNullableInput(
                control = boundControl(),
                valuePresentation = nestedPresentation(value, NestedPresentationSlot.Values),
            ),
        )
    }

    fun numericInput() {
        emit(PresentationElement.NumericInputWrapper(boundControl()))
    }

    fun toggleInput() {
        emit(PresentationElement.ToggleInputWrapper(boundControl()))
    }

    fun durationInput() {
        emit(PresentationElement.DurationInputWrapper(boundControl()))
    }

    fun bytesInput() {
        emit(PresentationElement.BytesInputWrapper(boundControl()))
    }

    fun enumInput() {
        emit(PresentationElement.EnumInputWrapper(boundControl()))
    }

    fun colorInput(includeAlpha: Boolean) {
        emit(
            PresentationElement.createColorInput(
                control = boundControl(),
                includeAlpha = includeAlpha,
            ),
        )
    }

    fun dateTimeInput(
        includeDate: Boolean,
        includeTime: Boolean,
    ) {
        emit(
            PresentationElement.createDateTimeInput(
                control = boundControl(),
                includeDate = includeDate,
                includeTime = includeTime,
            ),
        )
    }

    override fun icon(id: String) {
        prefix =
            state.node(
                PresentationElement.createIcon(
                    name = expression(id),
                    semanticLabel = null,
                    color = null,
                    size = null,
                ),
            )
    }

    override fun prefix(body: Layout.() -> Unit) {
        val nodes = mutableListOf<PresentationNode>()
        state.withTarget(nodes) { state.scope(nodes).body() }
        prefix = state.column(nodes)
    }

    fun defaultPresentation() {
        emit(
            PresentationElement.createDefaultPresentation(
                binding = binding(),
                presentationId = selectedPresentation,
            ),
        )
    }

    private fun <Scope> nestedPresentation(
        block: ControlConfiguration<Scope>,
        slot: NestedPresentationSlot,
    ): PresentationNode? {
        val descriptor = nested[slot] ?: return null
        val children = mutableListOf<PresentationNode>()
        val child = checked.nested(slot)
        val childBinding = fieldBinding.nested(slot, checked, child)
        val childType = child.type
        val build = state.scope(children, checked = childType, base = childBinding)
        var childControl: RuntimeControlBinding? = null
        val receiver =
            descriptor.create?.invoke(build)
                ?: if (Layout::class.java.isAssignableFrom(descriptor.control.java)) {
                    build
                } else {
                    val handler =
                        RuntimeControlBinding(
                            state,
                            children,
                            "$field.$slot",
                            childBinding,
                            childType,
                            descriptor.nested,
                            null,
                        )
                    childControl = handler
                    state.controls.create(descriptor.control, handler)
                }
        state.withTarget(children) { checkedGeneratedScope<Scope>(descriptor.control, receiver).block() }
        childControl?.takeUnless(RuntimeControlBinding::emitted)?.defaultPresentation()
        return children.takeIf(List<PresentationNode>::isNotEmpty)?.let(state::column)
    }

    fun <V> polymorphicInput(configure: ConcreteForms<V>.() -> Unit) {
        val forms = mutableListOf<skirout.editor.v1.presentation.ConcreteTypePresentation>()
        val scope =
            object : ConcreteForms<V> {
                override fun <Subtype : V> form(
                    type: AppliedPresentation<Subtype>,
                    label: Expr<String, Handled>?,
                ) {
                    state.type(type.type)
                    val id =
                        requireNotNull(state.presentationId(type.reference, state.type.rebind(type.type.template()))) {
                            "A concrete form presentation must be registered before use."
                        }
                    forms +=
                        skirout.editor.v1.presentation.ConcreteTypePresentation(
                            concreteType = SkirTypeCodec.encode(type.type).getOrThrow(),
                            label = expression(label ?: type.type.definition.toString()),
                            presentation =
                                state.node(
                                    PresentationElement.createInvocation(
                                        presentationId =
                                            skirout.editor.v1.type_catalog.PresentationId(
                                                namespace = id.namespace,
                                                name = id.name,
                                            ),
                                        arguments = emptyList(),
                                    ),
                                ),
                        )
                }
            }
        scope.configure()
        emit(PresentationElement.createPolymorphicInput(control = boundControl(), concreteTypes = forms))
    }

    fun linkInput(
        allowReorder: Boolean,
        source: CollectionSource<*, com.typewritermc.types.ResourceId>?,
        policy: LinkCandidatePolicyId?,
        rejection: LinkRejectionDisplay,
    ) {
        source?.let(state::collection)
        emit(
            PresentationElement.createLinkInput(
                control = boundControl(),
                allowReorder = allowReorder,
                candidatePolicy =
                    policy?.let {
                        skirout.editor.v1.presentation
                            .LinkCandidatePolicyId(value = it.value)
                    },
                rejectionDisplay =
                    when (rejection) {
                        LinkRejectionDisplay.Hidden -> skirout.editor.v1.presentation.LinkRejectionDisplay.HIDDEN
                        LinkRejectionDisplay.DisabledWithReason -> skirout.editor.v1.presentation.LinkRejectionDisplay.DISABLED
                    },
                sourceId = source?.id,
            ),
        )
    }

    private fun boundControl(): BoundControl =
        BoundControl(
            binding = binding(),
            label = label,
            description = description,
            prefix = prefix,
            semanticLabel = semanticLabel,
        )

    private fun binding(): BindingRef = fieldBinding

    private fun emit(element: PresentationElement) {
        require(selectedPresentation == null || element is PresentationElement.DefaultPresentationWrapper) {
            "A named presentation reference cannot be combined with an explicit field control."
        }
        check(!emitted) { "A field presentation may emit one control." }
        target +=
            state.node(
                element,
                WirePresentationProperties(enabledIf = enabledIf, readOnly = readOnly),
            )
        emitted = true
    }
}

private fun BindingRef.nested(
    slot: NestedPresentationSlot,
    checked: CheckedPresentationTemplate,
    nested: CheckedPresentationNested,
): BindingRef =
    when (slot) {
        NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
            this
        }

        NestedPresentationSlot.Items -> {
            val bindingId =
                when (requireNotNull(nested.collectionKind)) {
                    CollectionKind.List -> "list_item"
                    CollectionKind.Set -> "set_item"
                }
            BindingRef(
                path = WireValuePath(segments = emptyList()),
                bindingId = ExpressionBindingId(bindingId).wire(),
            )
        }

        NestedPresentationSlot.Keys -> {
            BindingRef(
                path = WireValuePath(segments = emptyList()),
                bindingId = ExpressionBindingId("map_key").wire(),
            )
        }

        NestedPresentationSlot.Values -> {
            if (checked.type is TypeTemplate.Nullable) {
                this
            } else {
                BindingRef(
                    path = WireValuePath(segments = emptyList()),
                    bindingId = ExpressionBindingId("map_value").wire(),
                )
            }
        }
    }
