@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionFactories
import com.typewritermc.types.namedUse
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.ResourceAppearance
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.AxisChildrenElement
import skirout.editor.v1.presentation.AxisChildrenLayout
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.FlexFit
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PositionedStackChild
import skirout.editor.v1.presentation.PresentationCollectionDefinition
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.StackChild
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import kotlin.reflect.KClass
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

/**
 * Owns one layout capture's node and binding identities, lexical type information, and published dependencies.
 * Nested layout scopes share this state while directing output into temporary targets. Target restoration runs even
 * when a builder fails, so child capture cannot leave subsequent output attached to the wrong parent.
 */
internal class PresentationBuildState(
    private val binding: PresentationBuildBinding,
    private val resolvePresentation: (PresentationReference, CheckedPresentationTemplate) -> skirout.editor.v1.type_catalog.PresentationId?,
    val expressions: ExpressionFactories,
) {
    val role: PresentationRole get() = binding.role
    val type get() = binding.type
    val nodes = mutableListOf<PresentationNode>()
    val controls = PresentationControlFactories()
    val queries = RuntimePresentationQueries(binding.nativeTypes)
    private val contextInputs = linkedMapOf<ExpressionBindingId, skirout.editor.v1.presentation.PresentationContextInput>()
    private var nextNode = 0
    private var nextBinding = 0
    private var activeTarget: MutableList<PresentationNode> = nodes
    private val types = linkedSetOf<skirout.editor.v1.type_catalog.TypeUse>()
    private val presentations = linkedSetOf<skirout.editor.v1.type_catalog.PresentationId>()
    private val capabilities = linkedSetOf<skirout.editor.v1.type_catalog.CapabilityId>()
    private val collections = linkedMapOf<String, PresentationCollectionDefinition>()
    private val expressionTypes =
        linkedMapOf(
            CONFIGURED_VALUE to type.type,
            ExpressionBindingId("presentation.subject.identifier") to
                com.typewritermc.types.ResourceIdDefinition.id
                    .template(),
        )

    /**
     * Checks the order key of a resources layout: [body] reads each member's link through [item], typed [link], and
     * may produce a key of any type.
     */
    internal fun checkOrder(
        body: ExpressionNode,
        item: ExpressionBindingId,
        link: TypeTemplate,
    ) {
        val errors = type.checkExpression(body, expressionTypes + (item to link), null, setOf(item))
        require(errors.isEmpty()) { "Invalid resources order: ${errors.joinToString()}." }
    }

    internal fun checkMapping(
        body: ExpressionNode,
        input: ExpressionBindingId,
        payload: TypeTemplate,
        output: TypeTemplate,
    ) {
        val errors = type.checkExpression(body, expressionTypes + (input to payload), output, setOf(input))
        require(errors.isEmpty()) { "Invalid control expression: ${errors.joinToString()}." }
    }

    val currentTarget: MutableList<PresentationNode> get() = activeTarget

    fun presentationId(
        reference: PresentationReference,
        checked: CheckedPresentationTemplate = type,
    ): skirout.editor.v1.type_catalog.PresentationId? = resolvePresentation(reference, checked)?.also { id -> presentations += id }

    fun type(use: TypeUse) {
        types += use
    }

    fun capability(id: com.typewritermc.capability.CapabilityId) {
        capabilities +=
            skirout.editor.v1.type_catalog
                .CapabilityId(value = id.value)
    }

    fun action(action: skirout.editor.v1.action.EditorAction) {
        val resource =
            com.typewritermc.types.ResourceIdDefinition.id
                .use()
        val selection =
            com.typewritermc.types.StandardTypes.list
                .use(listOf(resource))

        fun declare(
            id: String,
            use: TypeUse,
        ) {
            val key = ExpressionBindingId(id)
            contextInputs[key] =
                skirout.editor.v1.presentation.PresentationContextInput(
                    bindingId = key.wire(),
                    source = skirout.editor.v1.presentation.PresentationContextSource.CALLER,
                    valueType = use,
                )
            expressionTypes[key] = use.toTemplate()
            type(use)
        }
        when (action) {
            is skirout.editor.v1.action.EditorAction.NavigateWrapper -> {
                declare("context:subject", resource)
                declare("context:selection", selection)
                val expression =
                    action.value.resource
                val errors = type.checkExpression(expression, expressionTypes, resource.toTemplate(), expressionTypes.keys)
                require(errors.isEmpty()) { "Invalid resource navigation expression: ${errors.joinToString()}." }
            }

            is skirout.editor.v1.action.EditorAction.AuthoringWrapper -> {
                declare("context:subject", resource)
                declare("context:selection", selection)
                capability(com.typewritermc.capability.CapabilityId(action.value.capability.value))
                val expression =
                    action.value.targets
                val errors = type.checkExpression(expression, expressionTypes, selection.toTemplate(), expressionTypes.keys)
                require(errors.isEmpty()) { "Invalid authoring target expression: ${errors.joinToString()}." }
            }

            is skirout.editor.v1.action.EditorAction.CreateWrapper -> {
                checkCreate(action.value)
            }

            else -> {
                Unit
            }
        }
    }

    /**
     * Checks that a create action links the new resource into an owning link field of the subject that accepts its
     * type, and that every preset is a field of the created type receiving a value of that field's type.
     */
    private fun checkCreate(action: skirout.editor.v1.action.CreateResourceAction) {
        val created = action.type.requireValid()
        action.owner?.let { owner ->
            require(owner.bindingId == CONFIGURED_VALUE.wire()) { "A create action owner must be a field of the presentation subject." }
            val field = type.at(SkirAuthoringValueCodec.decode(owner.path).getOrThrow())
            val link =
                requireNotNull(field?.let { it.link() ?: it.itemsOrNull()?.link() }) {
                    "A create action owner must be a link field of the presentation subject."
                }
            require(
                link.endpoint in binding.ownershipEndpoints,
            ) { "A create action owner must be the owner side of an ownership relation." }
            val target =
                requireNotNull(link.target as? TypeTemplate.NamedWrapper) { "A create action owner must link a named resource type." }
            require(type.isSubtype(created, target.value.definition)) { "A create action owner does not accept resources of $created." }
        }
        val subject = type.rebind(created.template(emptyList()))
        action.fields.forEach { preset ->
            val path = SkirAuthoringValueCodec.decode(preset.path).getOrThrow()
            val field = requireNotNull(subject.at(path)) { "A create action preset ${path.segments} is not a field of $created." }
            // A preset that evaluates to missing leaves the field at its creation default.
            val errors = type.checkExpression(preset.value, expressionTypes, field.type, expressionTypes.keys, mayBeMissing = true)
            require(errors.isEmpty()) { "Invalid create action preset: ${errors.joinToString()}." }
        }
        type(created.use())
    }

    /** The field at [path] below this type, or null when a segment is not a field of it. */
    private fun CheckedPresentationTemplate.at(path: com.typewritermc.authoring.ValuePath): CheckedPresentationTemplate? =
        path.segments.fold(this as CheckedPresentationTemplate?) { current, segment ->
            (segment as? com.typewritermc.authoring.PathSegment.Field)?.let { current?.fieldOrNull(it.name) }
        }

    /** Types the binding of the presented resource's evaluated display, a canonical read model the editor supplies. */
    fun resourceAppearance(): com.typewritermc.expression.Expr<ResourceAppearance, com.typewritermc.expression.Handled> {
        val binding = com.typewritermc.authoring.PresentedResourceAppearance.binding
        expressionTypes[binding] =
            com.typewritermc.expression.CanonicalReadModels.resourceAppearance.use
                .toTemplate()
                .template
        return com.typewritermc.expression.inputExpression(binding)
    }

    /** Declares the group binding of a tree layout, typed as the hierarchy group the host supplies. */
    fun groupBinding(id: ExpressionBindingId) {
        val use =
            com.typewritermc.authoring.HierarchyGroupDefinition.id
                .namedUse()
        type(use.use)
        expressionTypes[id] = use.toTemplate().template
    }

    fun collection(source: CollectionSource<*, *>) {
        val definition = source.wire(this)
        val previous = collections[definition.sourceId]
        require(previous == null || previous == definition) {
            "One presentation build cannot declare conflicting collection sources with the same id."
        }
        collections[definition.sourceId] = definition
    }

    fun resourceType(native: KClass<*>): NamedTypeTemplate =
        requireNotNull(binding.nativeTypes[native]) {
            "No authored resource type is registered for ${native.qualifiedName}."
        }

    fun partId(key: PresentationPartKey<*>): skirout.editor.v1.presentation.PresentationPartId {
        val owner = resourceType(key.ownerClass)
        return skirout.editor.v1.presentation.PresentationPartId(
            owner = owner.definition,
            name = key.name,
        )
    }

    fun result(layout: PresentationNode): PresentationBuildResult =
        PresentationBuildResult(
            layout = layout,
            dependencies =
                PresentationDependencies(
                    types = types,
                    presentations = presentations,
                    conversions = emptyList(),
                    capabilities = capabilities,
                    collections = collections.values,
                    contextInputs = contextInputs.values,
                ),
        )

    fun <Value : Any> readContext(
        key: PresentationContextKey<Value>,
    ): com.typewritermc.expression.Expr<Value, com.typewritermc.expression.MayBeMissing> {
        val use =
            when (val valueType = key.valueType) {
                is PresentationContextValueType.Fixed -> {
                    valueType.use
                }

                is PresentationContextValueType.Registered -> {
                    val template =
                        requireNotNull(binding.nativeTypes[valueType.valueClass]) { "Caller input type is not registered." }
                    require(template.arguments.isEmpty()) { "Caller inputs require a closed registered type." }
                    template.definition.use()
                }
            }
        val declaration =
            skirout.editor.v1.presentation.PresentationContextInput(
                bindingId = key.binding.wire(),
                source = key.source,
                valueType = use,
            )
        val previous = contextInputs[key.binding]
        require(previous == null || previous == declaration) { "Context input types conflict." }
        require(previous != null || !expressionTypes.containsKey(key.binding)) { "Context input shadows a binding." }
        type(use)
        contextInputs.putIfAbsent(key.binding, declaration)
        expressionTypes[key.binding] = use.toTemplate()
        return com.typewritermc.expression.inputExpression(key.binding)
    }

    fun bindingId(purpose: String): ExpressionBindingId = ExpressionBindingId("presentation.$purpose.${nextBinding++}")

    fun <T> withTarget(
        target: MutableList<PresentationNode>,
        operation: () -> T,
    ): T {
        val previous = activeTarget
        activeTarget = target
        return try {
            operation()
        } finally {
            activeTarget = previous
        }
    }

    fun scope(
        target: MutableList<PresentationNode> = nodes,
        axis: PresentationAxisNodeList? = null,
        checked: CheckedPresentationTemplate = type,
        base: BindingRef = BindingRef(path = WireValuePath(segments = emptyList()), bindingId = CONFIGURED_VALUE.wire()),
    ): RuntimePresentationBuildScope {
        if (base.path.segments.isEmpty()) expressionTypes[ExpressionBindingId(base.bindingId.value)] = checked.type
        return RuntimePresentationBuildScope(this, RuntimeLayout(this, target, axis, checked, base), target, checked, base)
    }

    fun node(
        element: PresentationElement?,
        properties: WirePresentationProperties = WirePresentationProperties.partial(),
        nodeId: String = "generated.${nextNode++}",
        header: skirout.editor.v1.presentation.PresentationHeader? = null,
    ): PresentationNode =
        PresentationNode(
            nodeId = nodeId,
            properties = properties,
            element = element,
            header = header,
        )

    fun column(children: List<PresentationNode>): PresentationNode =
        node(
            PresentationElement.ChildrenWrapper(
                ChildrenElement.ColumnWrapper(
                    AxisChildrenElement(
                        children = children.map(AxisChild::FixedWrapper),
                        layout =
                            AxisChildrenLayout(
                                spacing = 0.0,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.START,
                                clipOverflow = false,
                            ),
                    ),
                ),
            ),
        )

    fun axis(
        children: List<AxisChild>,
        row: Boolean,
        spacing: Double,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
    ): PresentationNode {
        val layout =
            AxisChildrenLayout(
                spacing = spacing,
                mainAxisAlignment = main,
                crossAxisAlignment = cross,
                clipOverflow = false,
            )
        val element =
            if (row) {
                ChildrenElement.createRow(children = children, layout = layout)
            } else {
                ChildrenElement.createColumn(children = children, layout = layout)
            }
        return node(PresentationElement.ChildrenWrapper(element))
    }
}

internal class PresentationAxisNodeList(
    private val horizontal: Boolean,
) : AbstractMutableList<PresentationNode>() {
    private val nodes = mutableListOf<PresentationNode>()
    val children = mutableListOf<AxisChild>()

    override val size: Int get() = nodes.size

    override fun get(index: Int): PresentationNode = nodes[index]

    override fun add(
        index: Int,
        element: PresentationNode,
    ) {
        nodes.add(index, element)
        children.add(index, AxisChild.FixedWrapper(element))
    }

    override fun removeAt(index: Int): PresentationNode {
        children.removeAt(index)
        return nodes.removeAt(index)
    }

    override fun set(
        index: Int,
        element: PresentationNode,
    ): PresentationNode {
        children[index] = AxisChild.FixedWrapper(element)
        return nodes.set(index, element)
    }

    fun addField(node: PresentationNode) {
        if (horizontal) addFlexible(node, 1, FlexFit.TIGHT) else add(node)
    }

    fun addFlexible(
        node: PresentationNode,
        flex: Int,
        fit: FlexFit,
    ) {
        nodes += node
        children +=
            AxisChild.createFlexible(
                child = node,
                flex = flex,
                fit = fit,
            )
    }
}

/** Records stack children in order: direct additions flow, [addPositioned] places a child by insets. */
internal class PresentationStackNodeList : AbstractMutableList<PresentationNode>() {
    private val nodes = mutableListOf<PresentationNode>()
    val children = mutableListOf<StackChild>()

    override val size: Int get() = nodes.size

    override fun get(index: Int): PresentationNode = nodes[index]

    override fun add(
        index: Int,
        element: PresentationNode,
    ) {
        nodes.add(index, element)
        children.add(
            index,
            StackChild.FlowWrapper(element),
        )
    }

    override fun removeAt(index: Int): PresentationNode {
        children.removeAt(index)
        return nodes.removeAt(index)
    }

    override fun set(
        index: Int,
        element: PresentationNode,
    ): PresentationNode {
        children[index] =
            StackChild.FlowWrapper(element)
        return nodes.set(index, element)
    }

    fun addPositioned(child: PositionedStackChild) {
        nodes += child.child
        children +=
            StackChild.PositionedWrapper(child)
    }
}

internal fun PresentationBuildState.presentation(body: Layout.() -> Unit): PresentationNode {
    val children = mutableListOf<PresentationNode>()
    withTarget(children) { scope(children).body() }
    return children.singleOrNull() ?: column(children)
}

internal fun publishField(
    target: MutableList<PresentationNode>,
    node: PresentationNode,
) {
    if (target is PresentationAxisNodeList) target.addField(node) else target.add(node)
}
