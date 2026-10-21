@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.toTemplate
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.LinkRejectionDisplay
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.ResourcesLayout
import skirout.editor.v1.presentation.GraphDirection as WireGraphDirection
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

/**
 * Captures one bound field editor and publishes it once after its configuration finishes.
 * An explicit control and a named presentation reference are mutually exclusive. With neither selected, publication
 * requests the default presentation and preserves the field's binding, decorations, and read or write policy.
 * Nested collection editors receive their slot's binding instead of borrowing the owner's field path.
 */
internal class RuntimeControlBinding(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
    private val field: String,
    private val fieldBinding: BindingRef,
    private val checked: CheckedPresentationTemplate,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val selectedPresentation: skirout.editor.v1.type_catalog.PresentationId?,
    private val author: RuntimePresentationBuildScope,
) : Control {
    private var selected: ((BoundControl) -> PresentationElement)? = null
    private var finished = false
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var semanticLabel: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var prefix: PresentationNode? = null
    private var readOnly = false
    private val factories = RuntimeInputConfigurationFactories(state, checked.payloadType())

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

    override fun icon(id: String) {
        prefix = state.iconNode(id, IconOptions())
    }

    override fun prefix(body: Layout.() -> Unit) {
        prefix = author.presentation(body)
    }

    fun textInput(configure: TextInputScope.() -> Unit) = select(factories.text(author, configure))

    fun <N> numericInput(configure: NumericInputScope<N>.() -> Unit) = select(factories.numeric(author, configure))

    fun toggleInput(configure: ToggleInputScope.() -> Unit) = select(factories.toggle(configure))

    fun durationInput(configure: DurationInputScope.() -> Unit) = select(factories.duration(author, configure))

    fun bytesInput(configure: BytesInputScope.() -> Unit) = select(factories.bytes(author, configure))

    fun <E> enumInput(configure: SelectInputScope<E>.() -> Unit) = select(factories.enum(author, configure))

    fun colorInput(configure: ColorInputScope.() -> Unit) = select(factories.color(author, configure))

    fun dateTimeInput(configure: DateTimeInputScope.() -> Unit) = select(factories.dateTime(author, configure))

    fun <V> selectInput(
        options: List<SelectOption<V>>,
        configure: SelectInputScope<V>.() -> Unit,
    ) = select(factories.select(author, options, configure))

    fun <N> sliderInput(
        minimum: N,
        maximum: N,
        configure: SliderInputScope<N>.() -> Unit,
    ) = select(factories.slider(minimum, maximum, configure))

    fun <N> sliderInput(
        minimum: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        configure: SliderInputScope<N>.() -> Unit,
    ) = select(factories.slider(minimum, maximum, configure))

    fun <V, Row> searchInput(configure: SearchInputScope<V, Row>.() -> Unit) {
        val scope = RuntimeSearchInputScope<V, Row>(state, author)
        scope.configure()
        select(scope::element)
    }

    fun <Scope> namedInput(configure: NamedInputScope<Scope>.() -> Unit) {
        val draft = CollectionConfigurationDraft()
        val scope = RuntimeNamedInputScope<Scope>(draft.appearance())
        scope.configure()
        val body = nestedPresentation(scope.payload ?: {}, NestedPresentationSlot.Payload)
        val appearance = draft.appearance.toFrozen()
        val content = draft.content.toFrozen()
        select {
            PresentationElement.createNamedInput(
                control = it,
                payloadPresentation = body,
                appearance = appearance,
                content = content,
            )
        }
    }

    fun <Fields : Layout> recordInput(configure: RecordInputScope<Fields>.() -> Unit) {
        val draft = CollectionConfigurationDraft()
        val scope = RuntimeRecordInputScope<Fields>(draft.appearance())
        scope.configure()
        val body = nestedPresentation(scope.fields ?: {}, NestedPresentationSlot.Fields)
        val appearance = draft.appearance.toFrozen()
        val content = draft.content.toFrozen()
        select { PresentationElement.createRecordInput(control = it, fieldPresentation = body, appearance = appearance, content = content) }
    }

    fun <Scope> listInput(configure: ListInputScope<Scope>.() -> Unit) {
        val draft = CollectionConfigurationDraft()
        val scope = RuntimeListInputScope<Scope>(draft.appearance(), draft.operations(state, author), state, draft)
        scope.configure()
        val body = nestedPresentation(scope.items ?: {}, NestedPresentationSlot.Items)
        val appearance = draft.appearance.toFrozen()
        val content = draft.content.toFrozen()
        val add = draft.operations.allowAdd
        val remove = draft.operations.allowRemove
        val reorder = draft.operations.allowReorder
        select {
            PresentationElement.createListInput(
                control = it,
                itemPresentation = body,
                allowAdd = add,
                allowRemove = remove,
                allowReorder = reorder,
                itemBindingId = WireExpressionBindingId(value = "list_item"),
                indexBindingId = WireExpressionBindingId(value = "list_index"),
                appearance = appearance,
                content = content,
            )
        }
    }

    fun <Scope> collectionInput(configure: SetInputScope<Scope>.() -> Unit) {
        val draft = CollectionConfigurationDraft()
        val scope = RuntimeSetInputScope<Scope>(draft.appearance(), draft.operations(state, author))
        scope.configure()
        val body = nestedPresentation(scope.items ?: {}, NestedPresentationSlot.Items)
        val appearance = draft.appearance.toFrozen()
        val content = draft.content.toFrozen()
        val add = draft.operations.allowAdd
        val remove = draft.operations.allowRemove
        select {
            PresentationElement.createSetInput(
                control = it,
                itemPresentation = body,
                allowAdd = add,
                allowRemove = remove,
                itemBindingId = WireExpressionBindingId(value = "set_item"),
                appearance = appearance,
                content = content,
            )
        }
    }

    fun <K, V> mapInput(configure: MapInputScope<K, V>.() -> Unit) {
        val draft = CollectionConfigurationDraft()
        val scope = RuntimeMapInputScope<K, V>(draft.appearance(), draft.operations(state, author), draft.content)
        scope.configure()
        val keys = nestedPresentation(scope.keys ?: {}, NestedPresentationSlot.Keys)
        val values = nestedPresentation(scope.values ?: {}, NestedPresentationSlot.Values)
        val appearance = draft.appearance.toFrozen()
        val content = draft.content.toFrozen()
        val add = draft.operations.allowAdd
        val remove = draft.operations.allowRemove
        select {
            PresentationElement.createMapInput(
                control = it,
                keyPresentation = keys,
                valuePresentation = values,
                allowAdd = add,
                allowRemove = remove,
                keyBindingId = WireExpressionBindingId(value = "map_key"),
                valueBindingId = WireExpressionBindingId(value = "map_value"),
                appearance = appearance,
                content = content,
            )
        }
    }

    fun <Scope> nullableInput(configure: NullableInputScope<Scope>.() -> Unit) {
        val scope = RuntimeNullableInputScope<Scope>()
        scope.configure()
        val body = nestedPresentation(scope.value ?: {}, NestedPresentationSlot.Values)
        select {
            PresentationElement.createNullableInput(
                control = it,
                valuePresentation = body,
                emptyText = scope.emptyText,
                clearLabel = scope.clearLabel,
            )
        }
    }

    private var resourceOrder: ExpressionNode? = null

    fun order(key: ResourceItemScope<*>.() -> Expr<*, Handled>) {
        check(resourceOrder == null) { "A resources layout may declare one order." }
        val scope =
            object : ResourceItemScope<com.typewritermc.types.Resource> {
                override val resource =
                    ResourceExpr<com.typewritermc.types.Resource>(
                        ResourceReadSource.Reference(
                            com.typewritermc.expression.inputExpression<
                                com.typewritermc.types.Ref<Nothing, com.typewritermc.types.Resource>,
                                Handled,
                            >(RESOURCES_ITEM),
                        ),
                    )
            }
        resourceOrder = expression(scope.key())
    }

    fun graph(
        direction: GraphDirection,
        configure: GraphAppearanceScope.() -> Unit,
    ) {
        val draft =
            skirout.editor.v1.presentation.ResourceGraphAppearance
                .partial()
                .toMutable()
        RuntimeGraphAppearanceScope(draft).configure()
        val wireDirection =
            when (direction) {
                GraphDirection.LEFT_TO_RIGHT -> WireGraphDirection.LEFT_TO_RIGHT
                GraphDirection.RIGHT_TO_LEFT -> WireGraphDirection.RIGHT_TO_LEFT
                GraphDirection.TOP_TO_BOTTOM -> WireGraphDirection.TOP_TO_BOTTOM
                GraphDirection.BOTTOM_TO_TOP -> WireGraphDirection.BOTTOM_TO_TOP
            }
        resources(
            ResourcesLayout.createGraph(
                direction = wireDirection,
                appearance = draft.toFrozen(),
            ),
        )
    }

    fun timeline(configure: TimelineAppearanceScope.() -> Unit) {
        val draft =
            skirout.editor.v1.presentation.ResourceTimelineAppearance
                .partial()
                .toMutable()
        RuntimeTimelineAppearanceScope(draft).configure()
        resources(ResourcesLayout.createTimeline(appearance = draft.toFrozen()))
    }

    fun grid(
        itemExtent: Double,
        aspectRatio: Double,
        spacing: Double,
    ) {
        require(itemExtent.isFinite() && itemExtent > 0) { "Grid item extents must be finite and positive." }
        require(aspectRatio.isFinite() && aspectRatio > 0) { "Grid aspect ratios must be finite and positive." }
        require(spacing.isFinite() && spacing >= 0) { "Grid spacing must be finite and nonnegative." }
        resources(
            ResourcesLayout.createGrid(
                itemExtent = expression(itemExtent),
                aspectRatio = expression(aspectRatio),
                spacing = expression(spacing),
            ),
        )
    }

    fun list() = resources(ResourcesLayout.LIST)

    fun tree(
        path: com.typewritermc.authoring.TypedPath<*, com.typewritermc.authoring.HierarchyPath>,
        configure: TreeScope.() -> Unit,
    ) {
        val groupBinding = state.bindingId("resources.group")
        val scope = RuntimeTreeScope(state, groupBinding)
        scope.configure()
        resources(
            ResourcesLayout.createTree(
                path = SkirAuthoringValueCodec.encode(path.path).getOrThrow(),
                group = scope.group,
                groupBindingId = groupBinding.wire(),
                connectors = null,
                initiallyExpanded = scope.initiallyExpanded,
            ),
        )
    }

    private fun resources(layout: ResourcesLayout) {
        resourceOrder?.let { order ->
            require(layout !is ResourcesLayout.GraphWrapper && layout !is ResourcesLayout.TimelineWrapper) {
                "Graph and timeline layouts place members by their placements and cannot declare an order."
            }
            val link = requireNotNull(checked.itemsOrNull()) { "A resources layout presents a collection of links." }.type
            state.checkOrder(order, RESOURCES_ITEM, link)
        }
        select {
            PresentationElement.createResources(
                control = it,
                layout = layout,
                order = resourceOrder,
                itemBindingId = RESOURCES_ITEM.wire(),
            )
        }
    }

    fun <V> polymorphicInput(configure: PolymorphicInputScope<V>.() -> Unit) {
        val forms = mutableListOf<skirout.editor.v1.presentation.ConcreteTypePresentation>()
        val formScope =
            object : ConcreteForms<V> {
                override fun <Subtype : V> form(
                    type: AppliedPresentation<Subtype>,
                    label: Expr<String, Handled>?,
                ) {
                    state.type(type.type)
                    val id =
                        requireNotNull(state.presentationId(type.reference, state.type.rebind(type.type.toTemplate()))) {
                            "A concrete form presentation must be registered before use."
                        }
                    // Without an authored label the form is named by the readable Skir JSON of its definition id,
                    // a stable spelling that does not depend on Kotlin object formatting.
                    val fallback =
                        skirout.editor.v1.type_catalog.TypeDefinitionId.serializer
                            .toJsonCode(SkirTypeCodec.encode(type.type.definition).getOrThrow(), build.skir.JsonFlavor.READABLE)
                    forms +=
                        skirout.editor.v1.presentation.ConcreteTypePresentation(
                            concreteType = SkirTypeCodec.encode(type.type).getOrThrow(),
                            label = expression(label ?: fallback),
                            presentation =
                                state.node(
                                    PresentationElement.createInvocation(
                                        presentationId = id,
                                        arguments = emptyList(),
                                    ),
                                ),
                        )
                }
            }
        val common = InputConfigurationDraft()
        val collection = CollectionConfigurationDraft()
        val scope =
            RuntimePolymorphicInputScope(
                formScope,
                common.appearance(),
                common.content(state, author),
                collection.appearance(),
                collection.content,
                state,
            )
        scope.configure()
        val input = common.freeze()
        val appearance = collection.appearance.toFrozen()
        val content = collection.content.toFrozen()
        select {
            PresentationElement.createPolymorphicInput(
                control = it,
                concreteTypes = forms.toList(),
                appearance = appearance,
                content = content,
                inputAppearance = input.appearance,
                inputContent = input.content,
                searchHint = scope.searchHint,
            )
        }
    }

    fun linkInput(
        collection: Boolean,
        source: CollectionSource<*, com.typewritermc.types.ResourceId>?,
        policy: LinkCandidatePolicyId?,
        rejection: LinkRejectionDisplay,
        configure: LinkInputScope.() -> Unit,
    ) {
        source?.let(state::collection)
        val common = InputConfigurationDraft()
        val draft = CollectionConfigurationDraft()
        val scope =
            RuntimeLinkInputScope(
                common.appearance(),
                common.content(state, author),
                common.popup(),
                draft.appearance(),
                draft.content,
                state,
            )
        scope.allowReorder = collection
        scope.configure()
        require(collection || !scope.allowReorder) { "A single link cannot be reordered." }
        val input = common.freeze()
        val appearance = draft.appearance.toFrozen()
        val content = draft.content.toFrozen()
        select {
            PresentationElement.createLinkInput(
                control = it,
                allowReorder = scope.allowReorder,
                candidatePolicy =
                    policy?.let { p ->
                        skirout.editor.v1.presentation
                            .LinkCandidatePolicyId(value = p.value)
                    },
                rejectionDisplay = rejection,
                sourceId = source?.id,
                appearance = appearance,
                content = content,
                inputAppearance = input.appearance,
                inputContent = input.content,
                popup = input.popup,
            )
        }
    }

    private fun <Scope> nestedPresentation(
        block: ControlConfiguration<Scope>,
        slot: NestedPresentationSlot,
    ): PresentationNode? {
        val descriptor = nested[slot] ?: return null
        val children = mutableListOf<PresentationNode>()
        val child = checked.nested(slot)
        val childBinding = fieldBinding.nested(slot, checked, child)
        val build = state.scope(children, checked = child.type, base = childBinding)
        var childControl: RuntimeControlBinding? = null
        val receiver =
            descriptor.create?.invoke(build) ?: if (Layout::class.java.isAssignableFrom(descriptor.control.java)) {
                build
            } else {
                val handler =
                    RuntimeControlBinding(state, children, "$field.$slot", childBinding, child.type, descriptor.nested, null, build)
                childControl = handler
                state.controls.create(descriptor.control, handler)
            }
        state.withTarget(children) { checkedGeneratedScope<Scope>(descriptor.control, receiver).block() }
        childControl?.finishInto(children)
        return children.takeIf(List<PresentationNode>::isNotEmpty)?.let(state::column)
    }

    private fun select(factory: (BoundControl) -> PresentationElement) {
        check(!finished) { "A field presentation is already complete." }
        require(selectedPresentation == null) { "A named presentation reference cannot be combined with an explicit field control." }
        check(selected == null) { "A field presentation may emit one control." }
        selected = factory
    }

    fun finishInto(destination: MutableList<PresentationNode>) {
        check(!finished) { "A field presentation is already complete." }
        val control =
            BoundControl(binding = fieldBinding, label = label, description = description, prefix = prefix, semanticLabel = semanticLabel)
        val element =
            selected?.invoke(control)
                ?: PresentationElement.createDefaultPresentation(control = control, presentationId = selectedPresentation)
        publishField(destination, state.node(element, WirePresentationProperties(enabledIf = enabledIf, readOnly = readOnly)))
        finished = true
    }
}

/** Binds each member's link while a resources layout evaluates its order. */
private val RESOURCES_ITEM = ExpressionBindingId("resources_item")

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
