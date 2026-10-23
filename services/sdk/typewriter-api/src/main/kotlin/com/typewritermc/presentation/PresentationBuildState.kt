@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.name
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactories
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.apply
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
import skirout.editor.v1.presentation.BindingDeclaration
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
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import kotlin.reflect.KClass
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

/**
 * Owns one layout capture's node and binding identities, lexical binding types, and published dependencies.
 * Nested layout scopes share this state while directing output into temporary targets. Target restoration runs even
 * when a builder fails, so child capture cannot leave subsequent output attached to the wrong parent.
 *
 * Every expression enters the wire through [lower] or [lowerInferred], which check it against the bindings visible
 * where it is lowered; every binding the builder introduces is declared with its type through [introduce] or
 * [declare], and is visible only while the block that declares it runs.
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

    /** Lexical binding scopes, innermost last. The root holds the subject and inputs the whole material reads. */
    private val scopes =
        ArrayDeque(
            listOf(
                linkedMapOf(
                    CONFIGURED_VALUE to LexicalBinding(type.type, mayBeMissing = true),
                    SUBJECT_IDENTIFIER to LexicalBinding(ResourceIdDefinition.id.template(), mayBeMissing = true),
                ),
            ),
        )

    private fun visibleBindings(): Map<ExpressionBindingId, LexicalBinding> = buildMap { scopes.forEach(::putAll) }

    /**
     * Lowers [expression] for a slot of [expected] type, which accepts a missing value only when [mayBeMissing]. This
     * is the only way an expression enters the wire, so an ill typed slot fails the build with its check failures.
     */
    fun lower(
        expression: Expr<*, *>,
        expected: TypeTemplate,
        mayBeMissing: Boolean = false,
    ): ExpressionNode {
        val node = expression.toNode()
        val failures = type.typing.check(node, visibleBindings(), expected, mayBeMissing)
        require(failures.isEmpty()) { "Invalid ${expected.canonicalText} expression: ${failures.joinToString { it.value }}." }
        return node
    }

    /**
     * Lowers a computed source of any type, such as a sort key or a repeated list, with its inferred type. [purpose]
     * names the source in the failure of an ill typed one.
     */
    fun lowerInferred(
        expression: Expr<*, *>,
        purpose: String = "expression",
    ): Pair<ExpressionNode, TypeTemplate> {
        val node = expression.toNode()
        return when (val inference = type.typing.infer(node, visibleBindings())) {
            is TemplateInference.Typed -> node to inference.type

            is TemplateInference.Failed -> throw IllegalArgumentException(
                "Invalid $purpose: ${inference.failures.joinToString { it.value }}.",
            )
        }
    }

    /**
     * Lowers a sort key, whose type must be ordered as value.compare requires (text, a number, boolean, timestamp or
     * duration); any other key throws. [purpose] names the key in the failure.
     */
    fun lowerOrderKey(
        expression: Expr<*, *>,
        purpose: String,
    ): ExpressionNode {
        val (node, _) = lowerInferred(expression, purpose)
        val comparison =
            ExpressionNode.createCall(
                operation = PortableOperationCatalog.VALUE_COMPARE.id,
                typeArguments = emptyList(),
                arguments = listOf(node, node),
            )
        require(type.typing.infer(comparison, visibleBindings()) is TemplateInference.Typed) {
            "Invalid $purpose: the key is not of an ordered type."
        }
        return node
    }

    /**
     * Introduces a fresh binding of [type] for [body], named after [purpose]. Its declaration, with the type, goes to
     * the wire; reads of it may be missing unless [mayBeMissing] is false.
     */
    fun <R> introduce(
        purpose: String,
        type: TypeTemplate,
        mayBeMissing: Boolean = true,
        body: (BindingDeclaration) -> R,
    ): R = declare(ExpressionBindingId(value = "presentation.$purpose.${nextBinding++}"), type, mayBeMissing, body)

    /** Declares the binding [id] of [type] for [body], for bindings whose name the wire contract fixes. */
    fun <R> declare(
        id: ExpressionBindingId,
        type: TypeTemplate,
        mayBeMissing: Boolean = true,
        body: (BindingDeclaration) -> R,
    ): R {
        scopes.addLast(linkedMapOf(id to LexicalBinding(type, mayBeMissing)))
        return try {
            body(BindingDeclaration(id = id, type = type))
        } finally {
            scopes.removeLast()
        }
    }

    /**
     * Declares [id] of [type] in the innermost scope, for bindings a block introduces while it runs, such as the
     * selectors of a search input; they stay visible until that scope ends.
     */
    fun extendScope(
        id: ExpressionBindingId,
        type: TypeTemplate,
        mayBeMissing: Boolean = true,
    ): BindingDeclaration {
        check(scopes.size > 1) { "Only a nested scope can be extended." }
        require(id !in scopes.last()) { "Binding ${id.value} is already declared in this scope." }
        scopes.last()[id] = LexicalBinding(type, mayBeMissing)
        return BindingDeclaration(id = id, type = type)
    }

    /** The type of the value [ref] addresses: a visible binding and a path of fields below it. */
    fun typeOf(ref: BindingRef): TypeTemplate {
        val root =
            requireNotNull(visibleBindings()[ref.bindingId]) { "Binding ${ref.bindingId.value} is not visible here." }.type
        return ref.path.segments
            .fold(type.rebind(root)) { current, segment ->
                val field = requireNotNull(segment as? PathSegment.FieldWrapper) { "Bound paths address fields." }
                current.field(field.value.name)
            }.type
    }

    /** The item type of a list or set of [collection] type, or null when it is not one. */
    fun itemType(collection: TypeTemplate): TypeTemplate? = type.rebind(collection).itemsOrNull()?.type

    /** Adds [id] of [binding] type to the root scope, for inputs the whole material reads such as context values. */
    private fun declareRoot(
        id: ExpressionBindingId,
        binding: LexicalBinding,
    ) {
        val previous = scopes.first()[id]
        require(previous == null || previous == binding) { "Binding ${id.value} is declared with conflicting types." }
        scopes.first()[id] = binding
    }

    val currentTarget: MutableList<PresentationNode> get() = activeTarget

    fun presentationId(
        reference: PresentationReference,
        checked: CheckedPresentationTemplate = type,
    ): skirout.editor.v1.type_catalog.PresentationId? = resolvePresentation(reference, checked)?.also { id -> presentations += id }

    fun type(use: TypeUse) {
        types += use
    }

    fun capability(id: skirout.editor.v1.type_catalog.CapabilityId) {
        capabilities += id
    }

    /**
     * Lowers [action] for an interaction of this material. Navigation and authoring targets read the caller's
     * subject and selection, which this declares as caller inputs.
     */
    fun action(action: PresentationAction): skirout.editor.v1.action.EditorAction = action.lower(this)

    /** Declares the caller inputs actions read, which the caller supplies whenever it runs an action. */
    fun actionContext() {
        val resource = ResourceIdDefinition.id.template()
        callerInput(ACTION_SUBJECT, resource)
        callerInput(
            ACTION_SELECTION,
            com.typewritermc.types.StandardTypes.list
                .template(listOf(resource)),
        )
    }

    private fun callerInput(
        id: ExpressionBindingId,
        template: TypeTemplate,
    ) {
        contextInput(
            skirout.editor.v1.presentation.PresentationContextInput(
                binding = BindingDeclaration(id = id, type = template),
                source = skirout.editor.v1.presentation.PresentationContextSource.CALLER,
            ),
        )
    }

    private fun contextInput(input: skirout.editor.v1.presentation.PresentationContextInput) {
        val id = input.binding.id
        val previous = contextInputs[id]
        require(previous == null || previous == input) { "Context input ${id.value} is declared with conflicting types." }
        require(previous != null || visibleBindings()[id] == null) { "Context input ${id.value} shadows a binding." }
        declareRoot(id, LexicalBinding(input.binding.type, mayBeMissing = id != ACTION_SUBJECT && id != ACTION_SELECTION))
        contextInputs[id] = input
        (input.binding.type.apply(emptyMap()) as? com.typewritermc.types.catalog.Resolution.Ready)?.value?.let(::type)
    }

    /**
     * Lowers a create action: [owner] must be an owning link field of the subject that accepts [created] resources,
     * and every preset must be a field of the created type receiving a value of that field's type. A preset that
     * evaluates to missing leaves the field at its creation default.
     */
    fun createResource(
        created: skirout.editor.v1.type_catalog.TypeDefinitionId,
        owner: BindingRef?,
        presets: Map<ValuePath, Expr<*, *>>,
    ): skirout.editor.v1.action.EditorAction {
        owner?.let {
            val field = type.at(it.path)
            val link =
                requireNotNull(field?.let { candidate -> candidate.link() ?: candidate.itemsOrNull()?.link() }) {
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
        val fields =
            presets.map { (path, value) ->
                val field = requireNotNull(subject.at(path)) { "A create action preset ${path.segments} is not a field of $created." }
                skirout.editor.v1.action
                    .CreateFieldValue(path = path, value = lower(value, field.type, mayBeMissing = true))
            }
        type(created.use())
        return skirout.editor.v1.action.EditorAction
            .createCreate(type = created, owner = owner, fields = fields)
    }

    /** The field at [path] below this type, or null when a segment is not a field of it. */
    private fun CheckedPresentationTemplate.at(path: ValuePath): CheckedPresentationTemplate? =
        path.segments.fold(this as CheckedPresentationTemplate?) { current, segment ->
            (segment as? PathSegment.FieldWrapper)?.let { current?.fieldOrNull(it.name) }
        }

    /** The presented resource's evaluated display, a canonical read model the editor supplies. */
    fun resourceAppearance(): com.typewritermc.expression.Expr<ResourceAppearance, com.typewritermc.expression.Handled> {
        val binding = com.typewritermc.authoring.PresentedResourceAppearance.binding
        declareRoot(
            binding,
            LexicalBinding(
                com.typewritermc.expression.CanonicalReadModels.resourceAppearance.use
                    .toTemplate()
                    .template,
                mayBeMissing = false,
            ),
        )
        return com.typewritermc.expression.inputExpression(binding)
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
        contextInput(
            skirout.editor.v1.presentation.PresentationContextInput(
                binding = BindingDeclaration(id = key.binding, type = use.toTemplate()),
                source = key.source,
            ),
        )
        return com.typewritermc.expression.inputExpression(key.binding)
    }

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
        base: BindingRef = BindingRef(path = WireValuePath(segments = emptyList()), bindingId = CONFIGURED_VALUE),
    ): RuntimePresentationBuildScope =
        RuntimePresentationBuildScope(this, RuntimeLayout(this, target, axis, checked, base), target, checked, base)

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
        spacing: Spacing,
        main: MainAxisAlignment,
        cross: CrossAxisAlignment,
    ): PresentationNode {
        val layout =
            AxisChildrenLayout(
                spacing = spacing.pixels,
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

/** The resource identity of the presented subject, absent for plain values. */
internal val SUBJECT_IDENTIFIER = ExpressionBindingId(value = "presentation.subject.identifier")

/** The resource an action acts for, supplied by the caller. */
internal val ACTION_SUBJECT = ExpressionBindingId(value = "context:subject")

/** The resources selected where an action runs, supplied by the caller. */
internal val ACTION_SELECTION = ExpressionBindingId(value = "context:selection")
