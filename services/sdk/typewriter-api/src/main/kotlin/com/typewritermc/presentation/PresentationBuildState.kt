package com.typewritermc.presentation

import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionFactories
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.AxisChildrenElement
import skirout.editor.v1.presentation.AxisChildrenLayout
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationCollectionDefinition
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import kotlin.reflect.KClass
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

/**
 * Owns one layout capture's node and binding identities, lexical type information, and published dependencies.
 * Nested layout scopes share this state while directing output into temporary targets. Target restoration runs even
 * when a builder fails, so child capture cannot leave subsequent output attached to the wrong parent.
 */
internal class PresentationBuildState(
    private val binding: PresentationBuildBinding,
    private val resolvePresentation: (PresentationReference, CheckedPresentationTemplate) -> com.typewritermc.types.PresentationId?,
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
            ExpressionBindingId("presentation.subject.identifier") to TypeTemplate.Named(com.typewritermc.types.ResourceIdDefinition.id),
            ExpressionBindingId("presentation.context.selection_count") to
                TypeTemplate.Scalar(
                    com.typewritermc.types.ScalarKind
                        .Integer(com.typewritermc.types.IntegerWidth.SIGNED_32),
                ),
        )

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
    ): com.typewritermc.types.PresentationId? =
        resolvePresentation(reference, checked)?.also { id ->
            presentations +=
                skirout.editor.v1.type_catalog.PresentationId(
                    namespace = id.namespace,
                    name = id.name,
                )
        }

    fun type(use: TypeUse) {
        types += SkirTypeCodec.encode(use).getOrThrow()
    }

    fun capability(id: com.typewritermc.capability.CapabilityId) {
        capabilities +=
            skirout.editor.v1.type_catalog
                .CapabilityId(value = id.value)
    }

    fun action(action: skirout.editor.v1.action.EditorAction) {
        val resource = TypeUse.Named(com.typewritermc.types.ResourceIdDefinition.id)
        val selection = TypeUse.Named(com.typewritermc.types.StandardTypes.list, listOf(resource))

        fun declare(
            id: String,
            use: TypeUse,
        ) {
            val key = ExpressionBindingId(id)
            contextInputs[key] =
                skirout.editor.v1.presentation.PresentationContextInput(
                    bindingId = key.wire(),
                    valueType = SkirTypeCodec.encode(use).getOrThrow(),
                )
            expressionTypes[key] = use.template()
            type(use)
        }
        when (action) {
            is skirout.editor.v1.action.EditorAction.NavigateWrapper -> {
                declare("context:subject", resource)
                declare("context:selection", selection)
                val expression =
                    com.typewritermc.types.skir.SkirExpressionCodec
                        .decode(action.value.resource)
                        .getOrThrow()
                val errors = type.checkExpression(expression, expressionTypes, resource.template(), expressionTypes.keys)
                require(errors.isEmpty()) { "Invalid resource navigation expression: ${errors.joinToString()}." }
            }

            is skirout.editor.v1.action.EditorAction.AuthoringWrapper -> {
                declare("context:subject", resource)
                declare("context:selection", selection)
                capability(com.typewritermc.capability.CapabilityId(action.value.capability.value))
                val expression =
                    com.typewritermc.types.skir.SkirExpressionCodec
                        .decode(action.value.targets)
                        .getOrThrow()
                val errors = type.checkExpression(expression, expressionTypes, selection.template(), expressionTypes.keys)
                require(errors.isEmpty()) { "Invalid authoring target expression: ${errors.joinToString()}." }
            }

            else -> {
                Unit
            }
        }
    }

    fun collection(source: CollectionSource<*, *>) {
        val definition = source.wire(this)
        val previous = collections[definition.sourceId]
        require(previous == null || previous == definition) {
            "One presentation build cannot declare conflicting collection sources with the same id."
        }
        collections[definition.sourceId] = definition
    }

    fun resourceType(native: KClass<*>): TypeTemplate.Named =
        requireNotNull(binding.nativeTypes[native]) {
            "No authored resource type is registered for ${native.qualifiedName}."
        }

    fun partId(key: PresentationPartKey<*>): skirout.editor.v1.presentation.PresentationPartId {
        val owner = resourceType(key.ownerClass)
        return skirout.editor.v1.presentation.PresentationPartId(
            owner = SkirTypeCodec.encode(owner.definition).getOrThrow(),
            name = key.name,
        )
    }

    fun result(
        layout: PresentationNode,
        appearance: skirout.editor.v1.presentation.ResultAppearance? = null,
    ): PresentationBuildResult =
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
            resultAppearance = appearance,
        )

    fun <Value : Any> readContext(
        key: PresentationContextKey<Value>,
    ): com.typewritermc.expression.Expr<Value, com.typewritermc.expression.MayBeMissing> {
        val template = requireNotNull(binding.nativeTypes[key.valueClass]) { "Caller input type is not registered." }
        require(template.arguments.isEmpty()) { "Caller inputs require a closed registered type." }
        val use = TypeUse.Named(template.definition)
        val declaration =
            skirout.editor.v1.presentation.PresentationContextInput(
                bindingId = key.binding.wire(),
                valueType = SkirTypeCodec.encode(use).getOrThrow(),
            )
        val previous = contextInputs[key.binding]
        require(previous == null || previous == declaration) { "Caller input types conflict." }
        require(previous != null || !expressionTypes.containsKey(key.binding)) { "Caller input shadows a binding." }
        type(use)
        contextInputs.putIfAbsent(key.binding, declaration)
        expressionTypes[key.binding] = template
        return com.typewritermc.expression.Expr(ExpressionNode.Read(key.binding, com.typewritermc.authoring.ValuePath()))
    }

    fun captureResult(content: (PresentationBuildScope) -> Unit): CapturedResultPresentation {
        val target = mutableListOf<PresentationNode>()
        val result = ResultPresentationDraft(target)
        withTarget(target) { content(scope(target = target, result = result)) }
        return result.finish()
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
        result: ResultPresentationDraft? = null,
    ): RuntimePresentationBuildScope {
        if (base.path.segments.isEmpty()) expressionTypes[ExpressionBindingId(base.bindingId.value)] = checked.type
        return RuntimePresentationBuildScope(this, RuntimeLayout(this, target, axis, checked, base, result), target, checked, base)
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
                                mainAxisAlignment = WireMainAxisAlignment.START,
                                crossAxisAlignment = WireCrossAxisAlignment.START,
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
                mainAxisAlignment = main.wire(),
                crossAxisAlignment = cross.wire(),
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
        if (horizontal) addFlexible(node, 1, FlexFit.Tight) else add(node)
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
                fit =
                    when (fit) {
                        FlexFit.Tight -> skirout.editor.v1.presentation.FlexFit.TIGHT
                        FlexFit.Loose -> skirout.editor.v1.presentation.FlexFit.LOOSE
                    },
            )
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
