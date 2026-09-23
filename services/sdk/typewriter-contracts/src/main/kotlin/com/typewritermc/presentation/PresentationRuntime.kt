package com.typewritermc.presentation

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.types.DataValue
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.action.RealmEditorAction
import skirout.editor.v1.binding.BindingId
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.CoalesceExpression
import skirout.editor.v1.expression.CollectionOperation
import skirout.editor.v1.expression.CollectionOperationExpression
import skirout.editor.v1.expression.ComparisonExpression
import skirout.editor.v1.expression.ComparisonOperator
import skirout.editor.v1.expression.Expression
import skirout.editor.v1.expression.RecordExpressionField
import skirout.editor.v1.expression.RegexOperation
import skirout.editor.v1.expression.StringOperation
import skirout.editor.v1.expression.StringOperationExpression
import skirout.editor.v1.expression.TypedExpression
import skirout.editor.v1.path.DataPath
import skirout.editor.v1.path.DataPathSegment
import skirout.editor.v1.path.FieldPathSegment
import skirout.editor.v1.presentation.AdaptiveLeadingElement
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.AxisChildrenElement
import skirout.editor.v1.presentation.AxisChildrenLayout
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.ButtonElement
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.ChildrenLayout
import skirout.editor.v1.presentation.ColorControl
import skirout.editor.v1.presentation.CommitControlsElement
import skirout.editor.v1.presentation.ConcreteTypePresentation
import skirout.editor.v1.presentation.ConnectorAnchor
import skirout.editor.v1.presentation.ConnectorEndpointMarker
import skirout.editor.v1.presentation.ConnectorStroke
import skirout.editor.v1.presentation.ConnectorStyle
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.HierarchySequenceLayout
import skirout.editor.v1.presentation.HttpQueryParameter
import skirout.editor.v1.presentation.IconContent
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PolymorphicControl
import skirout.editor.v1.presentation.PresentationBorder
import skirout.editor.v1.presentation.PresentationBorderSide
import skirout.editor.v1.presentation.PresentationDefinition
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeader
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationInsets
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationProperties
import skirout.editor.v1.presentation.PresentationTextOverflow
import skirout.editor.v1.presentation.PresentationTextTone
import skirout.editor.v1.presentation.RichTextContent
import skirout.editor.v1.presentation.SearchControl
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.presentation.SearchRankingField
import skirout.editor.v1.presentation.SearchResultMapping
import skirout.editor.v1.presentation.SearchSelectionMode
import skirout.editor.v1.presentation.SectionLayout
import skirout.editor.v1.presentation.SequenceLayout
import skirout.editor.v1.presentation.TextContent
import skirout.editor.v1.presentation.TextControl
import skirout.editor.v1.presentation.TextParagraph
import skirout.editor.v1.presentation.TextStyleOverride
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CollectionConstraints
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NumericConstraints
import skirout.editor.v1.type_catalog.StringConstraints
import skirout.editor.v1.type_catalog.TypedValue
import skirout.editor.v1.presentation.FlexFit as WireFlexFit
import skirout.editor.v1.presentation.TextRun as WireTextRun
import skirout.editor.v1.type_catalog.PresentationId as SkirPresentationId
import skirout.editor.v1.type_catalog.TypeExpression as SkirTypeExpression

/**
 * Generated bridge from an annotated declaration to deployment presentation assembly.
 *
 * Provenance identifies invalid declarations. [specification] runs authored builder code with deployment field
 * metadata and may fail; the assembler turns such failures into diagnostics.
 */
interface PresentationProvider {
    /** Stable namespace used to form the presentation identity. */
    val namespace: String

    /** Source part that contributed this provider. */
    val sourcePart: String

    /** Declaration name used to identify failures before a specification exists. */
    val declarationName: String

    /** Whether this provider may become the default presentation for its target type. */
    val default: Boolean

    /** Priority used to select among default or same named presentations. */
    val priority: Int

    /** Semantic roles claimed for the declaration target. */
    val roles: Set<PresentationRole>
        get() = emptySet()

    /** Builds the authored specification against deployment serialization metadata. */
    fun specification(context: PresentationBuildContext): PresentationSpec<*>
}

/** Describes a presentation declaration rejected during catalog compilation. */
data class PresentationDiagnostic(
    /** Stable diagnostic category used by catalog consumers. */
    val code: String,
    /** Human readable failure detail. */
    val message: String,
    /** Provider namespace, when compilation reached provider provenance. */
    val namespace: String? = null,
    /** Provider source part, when compilation reached provider provenance. */
    val sourcePart: String? = null,
    /** Presentation name, when the specification supplied one. */
    val presentationName: String? = null,
)

/**
 * Returns compiled protocol presentations, updated type associations, and rejected declaration diagnostics.
 *
 * Use the returned type catalog to observe default and named presentation choices; the input catalog is not
 * mutated.
 */
data class PresentationCatalog(
    /** Type catalog with valid default and named presentation associations. */
    val types: TypeCatalog,
    /** Compiled protocol definitions in stable presentation identity order. */
    val definitions: List<PresentationDefinition>,
    /** Nonfatal declaration and association failures encountered during assembly. */
    val diagnostics: List<PresentationDiagnostic>,
)

/**
 * Compiles authored presentations and associates valid choices with their target types.
 *
 * Malformed trees, missing capabilities, and duplicate identities produce diagnostics. Default and named selection
 * prefer the highest unique priority, skipping tied priority groups. Compiled definitions and provider processing
 * use stable ordering.
 */
object PresentationCatalogAssembler {
    fun assemble(
        providers: Collection<PresentationProvider>,
        prototypes: TypePrototypeRegistry,
        types: TypeCatalog,
        capabilities: Collection<RealmCapabilityDescriptor> = emptyList(),
    ): PresentationCatalog {
        val diagnostics = mutableListOf<PresentationDiagnostic>()
        val context = PresentationBuildContext(prototypes)
        val compiled =
            providers
                .sortedWith(
                    compareBy<PresentationProvider>(
                        { it.namespace },
                        { it.sourcePart },
                        { it.declarationName },
                    ),
                ).mapNotNull { provider -> compile(provider, context, prototypes, diagnostics) }
        val knownCapabilities = capabilities.mapTo(mutableSetOf()) { it.id.value }
        val valid =
            compiled.filter { candidate ->
                val missing =
                    candidate.definition.dependencies.capabilities
                        .map { it.value }
                        .filterNot(knownCapabilities::contains)
                if (missing.isEmpty()) {
                    true
                } else {
                    diagnostics +=
                        candidate.diagnostic(
                            "missing_capability",
                            "Presentation references unavailable capabilities: ${missing.sorted().joinToString()}.",
                        )
                    false
                }
            }
        val unique =
            valid.groupBy { it.id }.flatMap { (id, candidates) ->
                if (candidates.size == 1) {
                    candidates
                } else {
                    candidates.forEach { candidate ->
                        diagnostics += candidate.diagnostic("duplicate_id", "Presentation id $id is declared more than once.")
                    }
                    emptyList()
                }
            }
        val available = unique.toMutableList()
        do {
            val known = available.associateBy { it.id }
            val rejected =
                available.filter { candidate ->
                    runCatching {
                        candidate.invocations.forEach { invocation ->
                            val target = requireNotNull(known[invocation.id]) { "Invoked presentation ${invocation.id} is unavailable." }
                            require(
                                invocation.arguments.size == target.inputs.size,
                            ) { "Presentation input count does not match ${invocation.id}." }
                            require(
                                invocation.arguments
                                    .map { it.input }
                                    .toSet()
                                    .size == invocation.arguments.size,
                            ) { "Presentation arguments must be unique." }
                            invocation.arguments.forEach { argument ->
                                require(
                                    target.inputs.any {
                                        it.index == argument.input.index && it.name == argument.input.name &&
                                            it.type == argument.input.type
                                    },
                                ) { "Argument belongs to a different presentation declaration." }
                                require(
                                    argument.input.type.java
                                        .isAssignableFrom(argument.value.type.java),
                                ) { "Presentation argument type does not match ${argument.input.name}." }
                                require(
                                    !argument.input.editable || argument.value.input.editable,
                                ) { "Presentation input ${argument.input.name} requires editing." }
                            }
                        }
                    }.exceptionOrNull()?.let { failure ->
                        diagnostics += candidate.diagnostic("invalid_invocation", failure.message.orEmpty())
                        true
                    } ?: false
                }
            available.removeAll(rejected.toSet())
        } while (rejected.isNotEmpty())
        val byTarget = available.groupBy(CompiledPresentation::target)
        val updatedTypes =
            types.definitions.map { definition ->
                val candidates = byTarget[definition.id].orEmpty()
                val default = select(candidates.filter(CompiledPresentation::default), "default", diagnostics)
                val named =
                    candidates
                        .groupBy { it.specificationName }
                        .mapNotNull { (name, values) -> select(values, "named presentation $name", diagnostics)?.let { name to it.id } }
                        .toMap()
                val roles =
                    PresentationRole.entries
                        .mapNotNull { role ->
                            select(candidates.filter { role in it.roles }, "${role.name.lowercase()} role", diagnostics)
                                ?.let { role to it.id }
                        }.toMap()
                definition.copy(defaultPresentationId = default?.id, namedPresentations = named, rolePresentations = roles)
            }
        return PresentationCatalog(
            types = TypeCatalog(updatedTypes),
            definitions =
                available
                    .map(
                        CompiledPresentation::definition,
                    ).sortedBy { "${it.presentationId.namespace}/${it.presentationId.name}" },
            diagnostics = diagnostics,
        )
    }

    private fun compile(
        provider: PresentationProvider,
        context: PresentationBuildContext,
        prototypes: TypePrototypeRegistry,
        diagnostics: MutableList<PresentationDiagnostic>,
    ): CompiledPresentation? =
        runCatching {
            val specification = provider.specification(context)
            val target =
                (context.type(specification.target) as? TypeExpression.Named)?.reference
            require((!provider.default && provider.roles.isEmpty()) || target != null) {
                "Default and role presentations require a nominal declaration target."
            }
            val compiler = NodeCompiler(prototypes, specification.inputs)
            val root = compiler.compile(specification.root, "root", emptyList())
            assertUniqueNodeIds(root)
            val id = PresentationId(provider.namespace, specification.name)
            val dependencies =
                collectPresentationDependencies(
                    root,
                    specification.inputs.map { context.type(it.type) },
                    compiler.collections,
                )
            CompiledPresentation(
                id = id,
                target = target,
                inputs = specification.inputs,
                invocations = compiler.invocations,
                specificationName = specification.name,
                default = provider.default,
                roles = provider.roles,
                priority = provider.priority,
                provider = provider,
                definition =
                    PresentationDefinition(
                        presentationId = SkirPresentationId(namespace = id.namespace, name = id.name),
                        inputs =
                            specification.inputs.map { input ->
                                skirout.editor.v1.presentation.PresentationInput(
                                    bindingId = BindingId(value = input.index),
                                    name = input.name,
                                    valueType = SkirTypeCodec.encode(context.type(input.type)).getOrThrow(),
                                    access =
                                        if (input.editable) {
                                            skirout.editor.v1.presentation.PresentationInputAccess.EDIT
                                        } else {
                                            skirout.editor.v1.presentation.PresentationInputAccess.READ
                                        },
                                )
                            },
                        primaryInput = specification.inputs.singleOrNull()?.let { BindingId(value = it.index) },
                        root = root,
                        dependencies = dependencies.toWire(compiler.collections),
                    ),
            )
        }.getOrElse { failure ->
            diagnostics +=
                PresentationDiagnostic(
                    code = "invalid_presentation",
                    message = failure.message ?: "Presentation compilation failed.",
                    namespace = provider.namespace,
                    sourcePart = provider.sourcePart,
                    presentationName = provider.declarationName,
                )
            null
        }

    private fun select(
        candidates: List<CompiledPresentation>,
        association: String,
        diagnostics: MutableList<PresentationDiagnostic>,
    ): CompiledPresentation? {
        candidates.groupBy(CompiledPresentation::priority).toSortedMap(compareByDescending { it }).forEach { (priority, values) ->
            if (values.size == 1) return values.single()
            values.forEach { candidate ->
                diagnostics += candidate.diagnostic("priority_tie", "Priority $priority is tied for $association.")
            }
        }
        return null
    }
}

private data class CompiledPresentation(
    val id: PresentationId,
    val target: ResolvedTypeRef?,
    val inputs: List<PresentationInputRef<*>>,
    val invocations: List<AuthoredPresentationNode.Invocation>,
    val specificationName: String,
    val default: Boolean,
    val roles: Set<PresentationRole>,
    val priority: Int,
    val provider: PresentationProvider,
    val definition: PresentationDefinition,
) {
    fun diagnostic(
        code: String,
        message: String,
    ) = PresentationDiagnostic(code, message, provider.namespace, provider.sourcePart, specificationName)
}

private class NodeCompiler(
    private val prototypes: TypePrototypeRegistry,
    private val inputs: List<PresentationInputRef<*>>,
) {
    val invocations = mutableListOf<AuthoredPresentationNode.Invocation>()
    val collections: List<skirout.editor.v1.presentation.PresentationCollectionDefinition>
        get() = collectionsBySource.values.toList()

    private val collectionsBySource = linkedMapOf<String, skirout.editor.v1.presentation.PresentationCollectionDefinition>()
    private val collectionDeclarations = linkedMapOf<String, PresentationCollection<*>>()
    private var nextBindingId = inputs.size.toLong()

    private fun inputId(input: PresentationInputRef<*>): Long {
        require(inputs.any { it === input }) { "Presentation references an input from a different declaration." }
        return input.index
    }

    private fun reference(value: PresentationValue<*>): BindingRef =
        BindingRef(
            bindingId = BindingId(value = inputId(value.input)),
            path = DataPath(segments = value.fields.map(::fieldPathSegment)),
        )

    fun compile(
        node: AuthoredPresentationNode,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode =
        when (node) {
            is AuthoredPresentationNode.CommitControls -> {
                require(node.value.input.editable) { "Commit controls require an editable presentation input." }
                presentationNode(
                    path,
                    PresentationElement.CommitControlsWrapper(CommitControlsElement(binding = reference(node.value))),
                )
            }

            is AuthoredPresentationNode.Column -> {
                column(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.Axis -> {
                axis(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.AdaptiveLeading -> {
                presentationNode(
                    path,
                    PresentationElement.AdaptiveLeadingWrapper(
                        AdaptiveLeadingElement(
                            leading = compile(node.leading, "$path.leading", bindingPath, bindingId),
                            center = node.center?.let { compile(it, "$path.center", bindingPath, bindingId) },
                            suffix = node.suffix?.let { compile(it, "$path.suffix", bindingPath, bindingId) },
                            padding = PresentationInsets.AllWrapper(0.0),
                            compactPadding = PresentationInsets.AllWrapper(0.0),
                            gap = 8.0,
                            minimumCenterWidth = 30.0,
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.Section -> {
                section(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.TextInput -> {
                textInput(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.NumericInput -> {
                numericInput(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.ColorInput -> {
                colorInput(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.CommandButton -> {
                commandButton(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.RealmSearchInput -> {
                realmSearchInput(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.SearchInput -> {
                searchInput(node.specification, path)
            }

            is AuthoredPresentationNode.PolymorphicInput -> {
                polymorphicInput(node, path, bindingPath, bindingId)
            }

            is AuthoredPresentationNode.Wire -> {
                node.node
            }

            is AuthoredPresentationNode.Text -> {
                presentationNode(
                    path,
                    PresentationElement.TextWrapper(
                        TextContent(
                            value = bindingExpression(node.value.type, inputId(node.value.input), node.value.fields),
                            color = null,
                            fontSize = null,
                            fontWeight = null,
                            fontItalic = null,
                            fontOpticalSize = null,
                            fontSlant = null,
                            fontWidth = null,
                            textAlignment = null,
                            lineHeight = null,
                            letterSpacing = null,
                            decoration = null,
                            semanticLabel = null,
                            paragraph =
                                TextParagraph(
                                    maxLines = null,
                                    overflow = PresentationTextOverflow.CLIP,
                                    softWrap = true,
                                    selectable = false,
                                    tone = PresentationTextTone.PRIMARY,
                                ),
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.ExpressionText -> {
                presentationNode(
                    path,
                    PresentationElement.TextWrapper(
                        TextContent(
                            value = authoredExpression(node.value.authored),
                            color = null,
                            fontSize = null,
                            fontWeight = null,
                            fontItalic = null,
                            fontOpticalSize = null,
                            fontSlant = null,
                            fontWidth = null,
                            textAlignment = null,
                            lineHeight = null,
                            letterSpacing = null,
                            decoration = null,
                            semanticLabel = null,
                            paragraph = defaultParagraph(),
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.RichText -> {
                presentationNode(
                    path,
                    PresentationElement.RichTextWrapper(
                        RichTextContent(
                            runs =
                                node.runs.map { run ->
                                    WireTextRun(
                                        text = authoredExpression(run.text.authored),
                                        style =
                                            if (run.fontWeight == null && run.fontItalic == null) {
                                                null
                                            } else {
                                                TextStyleOverride(
                                                    color = null,
                                                    fontWeight = run.fontWeight?.let(::floatExpression),
                                                    fontItalic = run.fontItalic?.let(::floatExpression),
                                                    decoration = null,
                                                )
                                            },
                                    )
                                },
                            style = null,
                            paragraph =
                                TextParagraph(
                                    maxLines = node.maxLines,
                                    overflow =
                                        if (node.ellipsis) {
                                            PresentationTextOverflow.ELLIPSIS
                                        } else {
                                            PresentationTextOverflow.CLIP
                                        },
                                    softWrap = node.softWrap,
                                    selectable = node.selectable,
                                    tone =
                                        if (node.secondary) {
                                            PresentationTextTone.SECONDARY
                                        } else {
                                            PresentationTextTone.PRIMARY
                                        },
                                ),
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.Icon -> {
                presentationNode(
                    path,
                    PresentationElement.IconWrapper(
                        IconContent(
                            name = bindingExpression(node.value.type, inputId(node.value.input), node.value.fields),
                            semanticLabel = null,
                            color = null,
                            size = null,
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.SelectInput<*> -> {
                val type = PresentationBuildContext(prototypes).type(node.value.type)
                val expected = SkirTypeCodec.encode(type).getOrThrow()
                presentationNode(
                    path,
                    PresentationElement.SelectInputWrapper(
                        skirout.editor.v1.presentation.SelectControl(
                            control = boundControl(node.value.fields, node.label, inputId(node.value.input)),
                            options =
                                node.options.map { option ->
                                    skirout.editor.v1.presentation.SelectOption(
                                        optionId = option.id,
                                        label = stringExpression(option.label),
                                        value =
                                            TypedExpression(
                                                resultType = expected,
                                                expression =
                                                    Expression.LiteralWrapper(
                                                        SkirDataValueCodec.encode(option.encode(prototypes, type)).getOrThrow(),
                                                    ),
                                            ),
                                    )
                                },
                            allowCustomValue = false,
                            defaultValue = node.defaultValue?.let { bindingExpression(it.type, inputId(it.input), it.fields) },
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.DefaultEditor -> {
                presentationNode(
                    path,
                    PresentationElement.DefaultPresentationWrapper(
                        skirout.editor.v1.presentation.DefaultPresentationElement(
                            binding = reference(node.value),
                            presentationId = null,
                        ),
                    ),
                )
            }

            is AuthoredPresentationNode.Invocation -> {
                presentationNode(
                    path,
                    PresentationElement.InvocationWrapper(
                        skirout.editor.v1.presentation.PresentationInvocation(
                            presentationId = SkirPresentationId(namespace = node.id.namespace, name = node.id.name),
                            arguments =
                                node.also(invocations::add).arguments.map { argument ->
                                    skirout.editor.v1.presentation.PresentationArgument(
                                        input = BindingId(value = argument.input.index),
                                        binding = reference(argument.value),
                                    )
                                },
                        ),
                    ),
                )
            }

            is AuthoredCollectionNode.Lookup<*> -> {
                collectionLookup(node, path)
            }

            is AuthoredCollectionNode.Graph<*> -> {
                collectionGraph(node, path)
            }

            is AuthoredCollectionNode.Surface -> {
                presentationNode(
                    path,
                    PresentationElement.createContainer(
                        child = compile(node.child, "$path.child", bindingPath, bindingId),
                        border = null,
                        backgroundColor = authoredExpression(node.backgroundColor.authored),
                        radius = skirout.editor.v1.presentation.PresentationRadius.SMALL,
                    ),
                )
            }
        }

    private fun collectionLookup(
        node: AuthoredCollectionNode.Lookup<*>,
        path: String,
    ): PresentationNode {
        val definition = collection(node.collection)
        val found = collectionRowSurface(definition, node.collection, node.label.name, node.color.name, "$path.found")
        return presentationNode(
            path,
            PresentationElement.createCollectionLookup(
                sourceId = definition.sourceId,
                key = reference(node.key),
                found = found,
                missing =
                    presentationNode(
                        "$path.missing",
                        PresentationElement.TextWrapper(TextContent.partial(value = stringExpression(node.missingLabel))),
                    ),
                loading = null,
            ),
        )
    }

    private fun collectionGraph(
        node: AuthoredCollectionNode.Graph<*>,
        path: String,
    ): PresentationNode {
        val definition = collection(node.collection)
        val childrenBindingId = BindingId(value = allocateBindingId())
        val childBindingId = BindingId(value = allocateBindingId())
        val slotId = "$path.children"
        val childrenType =
            SkirTypeExpression.createList(
                element = definition.rowType,
                constraints = CollectionConstraints.partial(),
            )
        val childCount = collectionLength(childrenBindingId.value, childrenType)
        val hasOneChild = comparison(childCount, ComparisonOperator.EQUAL, 1)
        val hasSeveralChildren = comparison(childCount, ComparisonOperator.GREATER_THAN_OR_EQUAL, 2)
        val unary =
            presentationNode(
                "$path.node.unary",
                PresentationElement.ChildrenWrapper(
                    ChildrenElement.ColumnWrapper(
                        AxisChildrenElement(
                            children =
                                listOf(
                                    AxisChild.FixedWrapper(
                                        collectionRowSurface(
                                            definition,
                                            node.collection,
                                            node.label.name,
                                            node.color.name,
                                            "$path.node.unary.row",
                                        ),
                                    ),
                                    AxisChild.FixedWrapper(
                                        presentationNode(
                                            "$path.node.unary.children",
                                            PresentationElement.createSlot(slotId = slotId),
                                        ),
                                    ),
                                ),
                            layout =
                                AxisChildrenLayout(
                                    spacing = 8.0,
                                    mainAxisAlignment = MainAxisAlignment.START,
                                    crossAxisAlignment = CrossAxisAlignment.STRETCH,
                                ),
                        ),
                    ),
                ),
            )
        val leafOrUnary =
            presentationNode(
                "$path.node.flattened",
                PresentationElement.createConditional(
                    condition = hasOneChild,
                    whenTrue = unary,
                    whenFalse =
                        collectionRowSurface(
                            definition,
                            node.collection,
                            node.label.name,
                            node.color.name,
                            "$path.node.leaf.row",
                        ),
                ),
            )
        val rowColor = collectionFieldExpression(node.collection, definition.rowBindingId.value, node.color.name)
        val branch =
            presentationNode(
                "$path.node.branch",
                PresentationElement.SectionWrapper(
                    SectionLayout(
                        child =
                            presentationNode(
                                "$path.node.branch.children",
                                PresentationElement.createSlot(slotId = slotId),
                            ),
                        border =
                            PresentationBorder.createSides(
                                top = null,
                                start = PresentationBorderSide(color = rowColor, width = 4.0),
                                end = null,
                                bottom = null,
                            ),
                    ),
                ),
                PresentationHeader(
                    binding = null,
                    title =
                        PresentationHeaderTitle.PresentationWrapper(
                            collectionRowSurface(
                                definition,
                                node.collection,
                                node.label.name,
                                node.color.name,
                                "$path.node.branch.row",
                            ),
                        ),
                    description = null,
                    initiallyExpanded = false,
                    items = emptyList(),
                    headerPadding = null,
                    contentPadding = null,
                ),
            )
        val nodePresentation =
            presentationNode(
                "$path.node",
                PresentationElement.createConditional(
                    condition = hasSeveralChildren,
                    whenTrue = branch,
                    whenFalse = leafOrUnary,
                ),
            )
        val rootSequenceLayout =
            skirout.editor.v1.presentation.SequenceLayout.ChildrenWrapper(
                ChildrenLayout.ColumnWrapper(
                    AxisChildrenLayout(
                        spacing = 12.0,
                        mainAxisAlignment = MainAxisAlignment.START,
                        crossAxisAlignment = CrossAxisAlignment.STRETCH,
                    ),
                ),
            )
        val childColor = collectionFieldExpression(node.collection, childBindingId.value, node.color.name)
        val hierarchyLayout =
            SequenceLayout.HierarchyWrapper(
                HierarchySequenceLayout(
                    unaryConnector = connector(childColor, startMarker = ConnectorEndpointMarker.createArrow(size = floatExpression(8.0))),
                    trunkConnector =
                        connector(
                            rowColor,
                            cornerRadius = 8.0,
                            startMarker = ConnectorEndpointMarker.createArrow(size = floatExpression(10.0)),
                        ),
                    branchConnector =
                        connector(
                            childColor,
                            cornerRadius = 8.0,
                            startMarker = ConnectorEndpointMarker.createCircle(diameter = floatExpression(6.0)),
                        ),
                    itemSpacing = floatExpression(24.0),
                    indentation = floatExpression(16.0),
                    leadingSpacing = floatExpression(16.0),
                    itemAnchor = ConnectorAnchor.CENTER,
                    flattenSingleItem = booleanExpression(true),
                    crossAxisAlignment = CrossAxisAlignment.STRETCH,
                ),
            )
        return presentationNode(
            path,
            PresentationElement.createCollectionGraph(
                sourceId = definition.sourceId,
                roots = reference(node.roots),
                rootSequence =
                    skirout.editor.v1.presentation.SequencePresentation(
                        item = presentationNode("$path.root.slot", PresentationElement.createSlot(slotId = slotId)),
                        empty = null,
                        separator = null,
                        layout = rootSequenceLayout,
                    ),
                relationId = node.relation.id,
                direction = skirout.editor.v1.presentation.CollectionGraphDirection.FORWARD,
                maximumDepth = node.maximumDepth,
                node = nodePresentation,
                childrenBindingId = childrenBindingId,
                childBindingId = childBindingId,
                children =
                    skirout.editor.v1.presentation.SequencePresentation(
                        item = presentationNode("$path.child.slot", PresentationElement.createSlot(slotId = slotId)),
                        empty = null,
                        separator = null,
                        layout = hierarchyLayout,
                    ),
            ),
        )
    }

    private fun collectionLength(
        bindingId: Long,
        collectionType: SkirTypeExpression,
    ): TypedExpression =
        TypedExpression(
            resultType = integerExpression(0).resultType,
            expression =
                Expression.CollectionOperationWrapper(
                    CollectionOperationExpression(
                        operation = CollectionOperation.LENGTH,
                        operands = listOf(bindingExpression(collectionType, bindingId, emptyList())),
                    ),
                ),
        )

    private fun comparison(
        left: TypedExpression,
        operator: ComparisonOperator,
        right: Int,
    ): TypedExpression =
        TypedExpression(
            resultType = SkirTypeExpression.BOOLEAN,
            expression =
                Expression.ComparisonWrapper(
                    ComparisonExpression(operator_ = operator, left = left, right = integerExpression(right)),
                ),
        )

    private fun connector(
        color: TypedExpression,
        cornerRadius: Double = 0.0,
        startMarker: ConnectorEndpointMarker? = null,
    ): ConnectorStyle =
        ConnectorStyle(
            stroke = ConnectorStroke(color = color, width = floatExpression(2.0)),
            cornerRadius = floatExpression(cornerRadius),
            startMarker = startMarker,
            endMarker = null,
        )

    private fun collectionRowSurface(
        definition: skirout.editor.v1.presentation.PresentationCollectionDefinition,
        collection: PresentationCollection<*>,
        labelProperty: String,
        colorProperty: String,
        path: String,
    ): PresentationNode {
        val label = collectionFieldExpression(collection, definition.rowBindingId.value, labelProperty)
        val color = collectionFieldExpression(collection, definition.rowBindingId.value, colorProperty)
        val text = presentationNode("$path.label", PresentationElement.TextWrapper(TextContent.partial(value = label)))
        val adaptive =
            presentationNode(
                "$path.adaptive",
                PresentationElement.AdaptiveLeadingWrapper(
                    AdaptiveLeadingElement(
                        leading = text,
                        center = null,
                        suffix = null,
                        padding = PresentationInsets.AllWrapper(8.0),
                        compactPadding = PresentationInsets.AllWrapper(4.0),
                        gap = 8.0,
                        minimumCenterWidth = 30.0,
                    ),
                ),
            )
        return presentationNode(
            path,
            PresentationElement.createContainer(
                child = adaptive,
                border = null,
                backgroundColor = color,
                radius = skirout.editor.v1.presentation.PresentationRadius.SMALL,
            ),
        )
    }

    private fun collection(collection: PresentationCollection<*>): skirout.editor.v1.presentation.PresentationCollectionDefinition {
        collectionsBySource[collection.sourceId]?.let { existing ->
            val declared = collectionDeclarations.getValue(collection.sourceId)
            require(
                declared.rowType == collection.rowType &&
                    declared.key.name == collection.key.name &&
                    declared.selectability.name == collection.selectability.name &&
                    declared.relations.map { it.id to it.targets.name } == collection.relations.map { it.id to it.targets.name },
            ) { "Collection source ${collection.sourceId} has conflicting declarations." }
            return existing
        }
        val rowBindingId = BindingId(value = allocateBindingId())
        val candidate =
            skirout.editor.v1.presentation.PresentationCollectionDefinition(
                sourceId = collection.sourceId,
                rowType = SkirTypeCodec.encode(PresentationBuildContext(prototypes).type(collection.rowType)).getOrThrow(),
                rowBindingId = rowBindingId,
                key = collectionFieldExpression(collection, rowBindingId.value, collection.key.name),
                selectability = collectionFieldExpression(collection, rowBindingId.value, collection.selectability.name),
                relations =
                    collection.relations.map { relation ->
                        skirout.editor.v1.presentation.PresentationCollectionRelationDefinition(
                            relationId = relation.id,
                            targets = collectionFieldExpression(collection, rowBindingId.value, relation.targets.name),
                        )
                    },
            )
        collectionDeclarations[collection.sourceId] = collection
        collectionsBySource[collection.sourceId] = candidate
        return candidate
    }

    private fun collectionFieldExpression(
        collection: PresentationCollection<*>,
        bindingId: Long,
        kotlinName: String,
    ): TypedExpression {
        val prototype = prototypes.require(collection.rowType)
        val serializedName =
            requireNotNull(prototype.serializedFieldNames[kotlinName]) {
                "Serialized field metadata is unavailable for ${collection.rowType.qualifiedName}.$kotlinName."
            }
        val representation =
            prototype.definition.representation as? TypeExpression.Record
                ?: error("Collection rows require record representations: ${prototype.type}.")
        val type =
            requireNotNull(representation.fields.singleOrNull { it.name == serializedName }) {
                "Collection row field $serializedName is unavailable on ${prototype.type}."
            }.type
        return bindingExpression(SkirTypeCodec.encode(type).getOrThrow(), bindingId, listOf(serializedName))
    }

    private fun column(
        node: AuthoredPresentationNode.Column,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode =
        presentationNode(
            path,
            PresentationElement.ChildrenWrapper(
                ChildrenElement.ColumnWrapper(
                    AxisChildrenElement(
                        children =
                            node.children.mapIndexed { index, child ->
                                AxisChild.FixedWrapper(compile(child, "$path.$index", bindingPath, bindingId))
                            },
                        layout =
                            AxisChildrenLayout(
                                spacing = 8.0,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.STRETCH,
                            ),
                    ),
                ),
            ),
        )

    private fun axis(
        node: AuthoredPresentationNode.Axis,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val children =
            node.children.mapIndexed { index, child ->
                val compiled = compile(child.child, "$path.$index", bindingPath, bindingId)
                when (child) {
                    is AuthoredPresentationAxisChild.Fixed -> {
                        AxisChild.FixedWrapper(compiled)
                    }

                    is AuthoredPresentationAxisChild.Flexible -> {
                        AxisChild.FlexibleWrapper(
                            skirout.editor.v1.presentation.FlexibleAxisChild(
                                child = compiled,
                                flex = child.flex,
                                fit =
                                    when (child.fit) {
                                        PresentationFlexFit.TIGHT -> WireFlexFit.TIGHT
                                        PresentationFlexFit.LOOSE -> WireFlexFit.LOOSE
                                    },
                            ),
                        )
                    }
                }
            }
        val element =
            AxisChildrenElement(
                children = children,
                layout =
                    AxisChildrenLayout(
                        spacing = node.spacing,
                        mainAxisAlignment = MainAxisAlignment.START,
                        crossAxisAlignment = CrossAxisAlignment.STRETCH,
                    ),
            )
        return presentationNode(
            path,
            PresentationElement.ChildrenWrapper(
                if (node.row) ChildrenElement.RowWrapper(element) else ChildrenElement.ColumnWrapper(element),
            ),
        )
    }

    private fun section(
        node: AuthoredPresentationNode.Section,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode =
        presentationNode(
            node.key,
            PresentationElement.SectionWrapper(
                SectionLayout(child = compile(node.child, "$path.content", bindingPath, bindingId), border = null),
            ),
            PresentationHeader(
                binding = null,
                title = node.title?.let { PresentationHeaderTitle.TextWrapper(stringExpression(it)) },
                description = null,
                initiallyExpanded = node.initiallyExpanded,
                items = emptyList(),
                headerPadding = null,
                contentPadding = null,
            ),
        )

    private fun textInput(
        node: AuthoredPresentationNode.TextInput,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val field = field(node.field)
        val fields = ((if (node.field.input == null) bindingPath else node.field.prefix) + field).filter(String::isNotEmpty)
        val control = boundControl(fields, node.label, node.field.input?.let(::inputId) ?: bindingId)
        return presentationNode(
            "field:${fields.joinToString(".")}:$path",
            PresentationElement.TextInputWrapper(
                TextControl(control = control, multiline = node.multiline, placeholder = null, inputFormatters = emptyList()),
            ),
        )
    }

    private fun numericInput(
        node: AuthoredPresentationNode.NumericInput,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val field = field(node.field)
        val fields = ((if (node.field.input == null) bindingPath else node.field.prefix) + field).filter(String::isNotEmpty)
        return presentationNode(
            "field:${fields.joinToString(".")}:$path",
            PresentationElement.NumericInputWrapper(boundControl(fields, node.label, node.field.input?.let(::inputId) ?: bindingId)),
        )
    }

    private fun colorInput(
        node: AuthoredPresentationNode.ColorInput,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val field = field(node.field)
        val fields = ((if (node.field.input == null) bindingPath else node.field.prefix) + field).filter(String::isNotEmpty)
        return presentationNode(
            "field:${fields.joinToString(".")}:$path",
            PresentationElement.ColorInputWrapper(
                ColorControl(
                    control = boundControl(fields, node.label, node.field.input?.let(::inputId) ?: bindingId),
                    includeAlpha = node.includeAlpha,
                ),
            ),
        )
    }

    private fun commandButton(
        node: AuthoredPresentationNode.CommandButton,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val payload =
            node.payload?.let { bindingExpression(it.type, inputId(it.input), it.fields) }
                ?: bindingExpression(node.capability.requestType, bindingId, bindingPath)
        val action =
            EditorAction.RealmWrapper(
                RealmEditorAction.createCommand(
                    capabilityId = CapabilityId(value = node.capability.id.value),
                    payload = payload,
                ),
            )
        return presentationNode(
            "command:${node.capability.id.value}:$path",
            PresentationElement.ButtonWrapper(ButtonElement(label = stringExpression(node.label), action = action)),
        )
    }

    private data class SearchScope(
        val query: Long,
        val candidate: Long,
        val summary: Long,
    ) {
        fun binding(slot: AuthoredExpression.SearchBinding): Long =
            when (slot) {
                AuthoredExpression.SearchBinding.QUERY -> query
                AuthoredExpression.SearchBinding.CANDIDATE -> candidate
                AuthoredExpression.SearchBinding.SUMMARY -> summary
            }
    }

    private fun searchInput(
        specification: AuthoredSearchInput<*, *>,
        path: String,
    ): PresentationNode {
        val value = specification.value
        return searchControl(
            path = path,
            control = boundControl(value.fields, specification.label, inputId(value.input)),
            maximumExtent = specification.maximumExtent,
            placeholder = specification.placeholder,
            provider = { scope ->
                searchProvider(specification.provider, specification.resultType, specification.result, scope, "$path.provider")
            },
            summary = { scope -> specification.summary?.let { searchLayout(it, "$path.summary", scope) } },
            customValue = { scope -> specification.customValue?.let { authoredExpression(it.authored, scope) } },
        )
    }

    private fun searchControl(
        path: String,
        nodeId: String = "search:$path",
        control: BoundControl,
        maximumExtent: Int,
        placeholder: String?,
        provider: (SearchScope) -> SearchProvider,
        summary: (SearchScope) -> PresentationNode?,
        customValue: (SearchScope) -> TypedExpression?,
    ): PresentationNode {
        val scope = SearchScope(allocateBindingId(), allocateBindingId(), allocateBindingId())
        return presentationNode(
            nodeId,
            PresentationElement.SearchInputWrapper(
                SearchControl(
                    control = control,
                    selectionMode = SearchSelectionMode.SINGLE,
                    queryBindingId = BindingId(value = scope.query),
                    summaryBindingId = BindingId(value = scope.summary),
                    maximumExtent = integerExpression(maximumExtent),
                    provider = provider(scope),
                    summary = summary(scope),
                    placeholder = placeholder?.let(::stringExpression),
                    customValue = customValue(scope),
                    initialQuery = null,
                ),
            ),
        )
    }

    private fun searchProvider(
        source: SearchProviderSpec<*>,
        resultType: kotlin.reflect.KClass<*>,
        result: SearchResultSpec<*>,
        scope: SearchScope,
        path: String,
    ): SearchProvider =
        when (source) {
            is SearchProviderSpec.HttpJson -> {
                SearchProvider.createHttpJson(
                    uri = stringExpression(source.uri),
                    parameters =
                        source.parameters.map {
                            HttpQueryParameter(
                                name = it.name,
                                value = authoredExpression(it.value.authored, scope),
                                omitIfEmpty = it.omitIfEmpty,
                            )
                        },
                    resultPath = source.resultPath,
                    resultType = authoredType(resultType),
                    result = searchResult(result, scope, "$path.result"),
                    contextBindings = emptyList(),
                    selectors = emptyList(),
                    timeoutMilliseconds = source.timeoutMillis,
                )
            }

            is SearchProviderSpec.StaticValues -> {
                require(source.values.all { it is String }) { "Static search values currently require strings." }
                val values = source.values.map { DataValue.StringValue(it as String) }
                SearchProvider.createStaticValues(
                    values =
                        TypedExpression(
                            resultType = SkirTypeCodec.encode(TypeExpression.ListType(TypeExpression.StringType())).getOrThrow(),
                            expression = Expression.LiteralWrapper(SkirDataValueCodec.encode(DataValue.ListValue(values)).getOrThrow()),
                        ),
                    result = searchResult(result, scope, "$path.result"),
                    selectors = emptyList(),
                )
            }

            is SearchProviderSpec.RealmCallback -> {
                SearchProvider.createRealmCallback(
                    capabilityId = CapabilityId(value = source.capability.id.value),
                    payload = authoredExpression(source.payload.authored, scope),
                    result = searchResult(result, scope, "$path.result"),
                    selectors = emptyList(),
                )
            }

            is SearchProviderSpec.Decorated -> {
                val child = searchProvider(source.child, resultType, result, scope, "$path.child")
                when (val operation = source.operation) {
                    is SearchDecoration.Gate -> {
                        SearchProvider.createGate(
                            condition = authoredExpression(operation.condition.authored, scope),
                            guidance = operation.guidance?.let(::stringExpression),
                            child = child,
                        )
                    }

                    is SearchDecoration.Debounce -> {
                        SearchProvider.createDebounce(durationMilliseconds = operation.milliseconds, child = child)
                    }

                    is SearchDecoration.Rank -> {
                        SearchProvider.createRank(
                            fields =
                                operation.fields.map {
                                    SearchRankingField(
                                        expression = authoredExpression(it.first.authored, scope),
                                        weight = it.second,
                                    )
                                },
                            child = child,
                        )
                    }

                    is SearchDecoration.Limit -> {
                        SearchProvider.createLimit(maximum = integerExpression(operation.maximum), child = child)
                    }

                    is SearchDecoration.Cache -> {
                        SearchProvider.createCache(
                            capacity = operation.capacity,
                            retainStaleResults = operation.retainStaleResults,
                            child = child,
                        )
                    }

                    is SearchDecoration.History -> {
                        SearchProvider.createHistory(
                            historyKey = operation.key,
                            label = stringExpression(operation.label),
                            capacity = operation.capacity,
                            child = child,
                        )
                    }

                    is SearchDecoration.Section -> {
                        SearchProvider.createSection(
                            sectionId = operation.id,
                            label = stringExpression(operation.label),
                            child = child,
                        )
                    }

                    SearchDecoration.Distinct -> {
                        SearchProvider.createDistinct(child = child)
                    }
                }
            }

            is SearchProviderSpec.Merged -> {
                SearchProvider.createMerge(
                    children =
                        source.children.mapIndexed {
                            index,
                            item,
                            ->
                            searchProvider(item, resultType, result, scope, "$path.branch.$index")
                        },
                )
            }
        }

    private fun authoredType(type: kotlin.reflect.KClass<*>): SkirTypeExpression =
        SkirTypeCodec.encode(PresentationBuildContext(prototypes).type(type)).getOrThrow()

    private fun searchResult(
        result: SearchResultSpec<*>,
        scope: SearchScope,
        path: String,
    ): SearchResultMapping =
        SearchResultMapping(
            bindingId = BindingId(value = scope.candidate),
            key = authoredExpression(result.key.authored, scope),
            selectedValue = authoredExpression(result.selectedValue.authored, scope),
            presentation = searchLayout(result.presentation, path, scope),
            label = authoredExpression(result.label.authored, scope),
        )

    private fun searchLayout(
        layout: SearchLayout,
        path: String,
        scope: SearchScope,
    ): PresentationNode =
        when (layout) {
            is SearchLayout.Text -> {
                presentationNode(
                    path,
                    PresentationElement.TextWrapper(TextContent.partial(value = authoredExpression(layout.value.authored, scope))),
                )
            }

            is SearchLayout.Icon -> {
                presentationNode(
                    path,
                    PresentationElement.IconWrapper(
                        IconContent(
                            name = authoredExpression(layout.value.authored, scope),
                            semanticLabel = authoredExpression(layout.value.authored, scope),
                            color = null,
                            size = null,
                        ),
                    ),
                )
            }

            is SearchLayout.Axis -> {
                val children =
                    layout.children.mapIndexed { index, child ->
                        val compiled = searchLayout(child.layout, "$path.$index", scope)
                        child.flex?.let {
                            AxisChild.FlexibleWrapper(
                                skirout.editor.v1.presentation
                                    .FlexibleAxisChild(child = compiled, flex = it, fit = WireFlexFit.LOOSE),
                            )
                        } ?: AxisChild.FixedWrapper(compiled)
                    }
                presentationNode(
                    path,
                    PresentationElement.ChildrenWrapper(
                        (
                            if (layout.row) {
                                ChildrenElement.RowWrapper(
                                    AxisChildrenElement(
                                        children = children,
                                        layout =
                                            AxisChildrenLayout(
                                                spacing = layout.spacing,
                                                mainAxisAlignment = MainAxisAlignment.START,
                                                crossAxisAlignment = CrossAxisAlignment.START,
                                            ),
                                    ),
                                )
                            } else {
                                ChildrenElement.ColumnWrapper(
                                    AxisChildrenElement(
                                        children = children,
                                        layout =
                                            AxisChildrenLayout(
                                                spacing = layout.spacing,
                                                mainAxisAlignment = MainAxisAlignment.START,
                                                crossAxisAlignment = CrossAxisAlignment.START,
                                            ),
                                    ),
                                )
                            }
                        ),
                    ),
                )
            }
        }

    private fun realmSearchInput(
        node: AuthoredPresentationNode.RealmSearchInput,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val field = field(node.field)
        val fields = ((if (node.field.input == null) bindingPath else node.field.prefix) + field).filter(String::isNotEmpty)
        return searchControl(
            path = path,
            nodeId = "field:${fields.joinToString(".")}:$path",
            control = boundControl(fields, node.label, node.field.input?.let(::inputId) ?: bindingId),
            maximumExtent = 320,
            placeholder = null,
            summary = { null },
            customValue = { null },
            provider = { scope ->
                val resultValue = bindingExpression(node.capability.resultType, scope.candidate, emptyList())
                val resultKey = stringBindingExpression(scope.candidate, listOf(field(node.resultKey)))
                val resultLabel = stringBindingExpression(scope.candidate, listOf(field(node.resultLabel)))
                val result =
                    SearchResultMapping(
                        bindingId = BindingId(value = scope.candidate),
                        key = resultKey,
                        selectedValue = resultValue,
                        presentation =
                            presentationNode(
                                "search-result:${node.capability.id.value}:$path",
                                PresentationElement.TextWrapper(TextContent.partial(value = resultLabel)),
                            ),
                        label = resultLabel,
                    )
                SearchProvider.createRealmCallback(
                    capabilityId = CapabilityId(value = node.capability.id.value),
                    payload =
                        node.payload?.let { bindingExpression(it.type, inputId(it.input), it.fields) }
                            ?: bindingExpression(node.capability.requestType, bindingId, bindingPath),
                    result = result,
                    selectors = emptyList(),
                )
            },
        )
    }

    private fun polymorphicInput(
        node: AuthoredPresentationNode.PolymorphicInput,
        path: String,
        bindingPath: List<String>,
        bindingId: Long = 0L,
    ): PresentationNode {
        val field = field(node.field)
        val fields = ((if (node.field.input == null) bindingPath else node.field.prefix) + field).filter(String::isNotEmpty)
        val types =
            node.types.mapIndexed { index, type ->
                ConcreteTypePresentation(
                    concreteType = SkirTypeCodec.encode(prototypes.require(type.type).type).getOrThrow(),
                    label = stringExpression(type.label),
                    presentation = compile(type.root, "$path.type.$index", fields, node.field.input?.let(::inputId) ?: bindingId),
                )
            }
        return presentationNode(
            "field:${fields.joinToString(".")}",
            PresentationElement.PolymorphicInputWrapper(
                PolymorphicControl(
                    control = boundControl(fields, null, node.field.input?.let(::inputId) ?: bindingId),
                    concreteTypes = types,
                ),
            ),
        )
    }

    private fun field(reference: FieldReference): String = reference.serializedName

    private fun allocateBindingId(): Long = nextBindingId++

    private fun bindingExpression(
        type: kotlin.reflect.KClass<*>,
        bindingId: Long,
        fields: List<String>,
    ): TypedExpression =
        bindingExpression(
            SkirTypeCodec.encode(PresentationBuildContext(prototypes).type(type)).getOrThrow(),
            bindingId,
            fields,
        )

    private fun authoredExpression(
        expression: AuthoredExpression,
        scope: SearchScope? = null,
    ): TypedExpression =
        when (expression) {
            is AuthoredExpression.ScopedBinding -> {
                val searchScope = checkNotNull(scope) { "Search expression used outside search input." }
                bindingExpression(expression.type, searchScope.binding(expression.binding), emptyList())
            }

            is AuthoredExpression.Field -> {
                TypedExpression(
                    resultType = authoredType(expression.type),
                    expression =
                        Expression.createFieldAccess(
                            target = authoredExpression(expression.target, scope),
                            fieldName = expression.name,
                        ),
                )
            }

            is AuthoredExpression.Record -> {
                TypedExpression(
                    resultType = authoredType(expression.type),
                    expression =
                        Expression.createRecord(
                            fields =
                                expression.fields.map { (name, value) ->
                                    RecordExpressionField(name = name, value = authoredExpression(value, scope))
                                },
                        ),
                )
            }

            is AuthoredExpression.RegexCapture -> {
                TypedExpression(
                    resultType = authoredType(String::class),
                    expression =
                        Expression.createRegex(
                            operation = RegexOperation.CAPTURE,
                            source = authoredExpression(expression.source, scope),
                            pattern = expression.pattern,
                            group = expression.group,
                            replacement = null,
                        ),
                )
            }

            is AuthoredExpression.RegexMatches -> {
                TypedExpression(
                    resultType = authoredType(Boolean::class),
                    expression =
                        Expression.createRegex(
                            operation = RegexOperation.MATCHES,
                            source = authoredExpression(expression.source, scope),
                            pattern = expression.pattern,
                            group = null,
                            replacement = null,
                        ),
                )
            }

            is AuthoredExpression.StringReplace -> {
                TypedExpression(
                    resultType = authoredType(String::class),
                    expression =
                        Expression.createStringOperation(
                            operation = StringOperation.REPLACE,
                            operands =
                                listOf(
                                    authoredExpression(expression.source, scope),
                                    stringExpression(expression.before),
                                    stringExpression(expression.after),
                                ),
                        ),
                )
            }

            is AuthoredExpression.TitleCase -> {
                TypedExpression(
                    resultType = authoredType(String::class),
                    expression =
                        Expression.createStringOperation(
                            operation = StringOperation.TITLE_CASE,
                            operands = listOf(authoredExpression(expression.source, scope)),
                        ),
                )
            }

            is AuthoredExpression.Binding -> {
                bindingExpression(
                    expression.value.type,
                    inputId(expression.value.input),
                    expression.value.fields,
                )
            }

            is AuthoredExpression.StringProjection -> {
                require(resolveBindingType(expression.value) is TypeExpression.StringType) {
                    "String projections require a string catalog representation."
                }
                stringBindingExpression(inputId(expression.value.input), expression.value.fields)
            }

            is AuthoredExpression.BindingPath -> {
                bindingExpression(
                    expression.type,
                    inputId(expression.input),
                    expression.fields,
                )
            }

            is AuthoredExpression.Literal -> {
                when (val value = expression.value) {
                    is String -> stringExpression(value)
                    is Int -> integerExpression(value)
                    else -> error("Unsupported authored expression literal ${value::class.qualifiedName}.")
                }
            }

            is AuthoredExpression.Coalesce -> {
                val value = authoredExpression(expression.value, scope)
                TypedExpression(
                    resultType = value.resultType,
                    expression =
                        Expression.CoalesceWrapper(
                            CoalesceExpression(
                                operands = listOf(value, authoredExpression(expression.fallback, scope)),
                            ),
                        ),
                )
            }

            is AuthoredExpression.Substring -> {
                val value = authoredExpression(expression.value, scope)
                TypedExpression(
                    resultType = SkirTypeExpression.StringWrapper(StringConstraints.partial()),
                    expression =
                        Expression.StringOperationWrapper(
                            StringOperationExpression(
                                operation = StringOperation.SUBSTRING,
                                operands =
                                    listOfNotNull(
                                        value,
                                        authoredExpression(expression.start, scope),
                                        expression.end?.let { authoredExpression(it, scope) },
                                    ),
                            ),
                        ),
                )
            }
        }

    private fun resolveBindingType(value: PresentationValue<*>): TypeExpression {
        var current = PresentationBuildContext(prototypes).type(value.input.type)
        value.fields.forEach { field ->
            val record =
                resolveRepresentation(current) as? TypeExpression.Record
                    ?: error("Binding field $field requires a record representation.")
            current =
                requireNotNull(record.fields.singleOrNull { it.name == field }) {
                    "Binding field $field is unavailable."
                }.type
        }
        return resolveRepresentation(current)
    }

    private fun resolveRepresentation(
        type: TypeExpression,
        visited: Set<ResolvedTypeRef> = emptySet(),
    ): TypeExpression {
        val named = type as? TypeExpression.Named ?: return type
        if (named.reference in visited) return type
        return resolveRepresentation(prototypes.require(named.reference).definition.representation, visited + named.reference)
    }

    private fun stringBindingExpression(
        bindingId: Long,
        fields: List<String>,
    ): TypedExpression = bindingExpression(SkirTypeExpression.StringWrapper(StringConstraints.partial()), bindingId, fields)

    private fun bindingExpression(
        resultType: SkirTypeExpression,
        bindingId: Long,
        fields: List<String>,
    ): TypedExpression =
        TypedExpression(
            resultType = resultType,
            expression =
                Expression.BindingWrapper(
                    BindingRef(
                        path = DataPath(segments = fields.map(::fieldPathSegment)),
                        bindingId = BindingId(value = bindingId),
                    ),
                ),
        )

    private fun boundControl(
        fields: List<String>,
        label: String?,
        bindingId: Long,
    ): BoundControl =
        BoundControl(
            binding =
                BindingRef(
                    path =
                        DataPath(
                            segments = fields.map { DataPathSegment.FieldWrapper(FieldPathSegment(fieldName = it)) },
                        ),
                    bindingId = BindingId(value = bindingId),
                ),
            label = label?.let(::stringExpression),
            description = null,
            prefix = null,
            semanticLabel = null,
        )

    private fun presentationNode(
        id: String,
        element: PresentationElement,
        header: PresentationHeader? = null,
    ): PresentationNode =
        PresentationNode(
            nodeId = id,
            properties = PresentationProperties(enabledIf = null, readOnly = false),
            element = element,
            header = header,
        )
}

private fun fieldPathSegment(field: String): DataPathSegment = DataPathSegment.FieldWrapper(FieldPathSegment(fieldName = field))

private fun stringExpression(value: String): TypedExpression =
    TypedExpression(
        resultType = SkirTypeExpression.StringWrapper(StringConstraints.partial()),
        expression = Expression.LiteralWrapper(TypedValue.StringWrapper(value)),
    )

private fun unboundedNumericConstraints(): NumericConstraints =
    NumericConstraints(
        minimum = null,
        minimumInclusive = true,
        maximum = null,
        maximumInclusive = true,
        multipleOf = null,
    )

private fun integerExpression(value: Int): TypedExpression =
    TypedExpression(
        resultType =
            SkirTypeExpression.createSignedInteger(
                width = IntegerWidth.THIRTY_TWO_BITS,
                constraints = unboundedNumericConstraints(),
            ),
        expression = Expression.LiteralWrapper(TypedValue.SignedThirtyTwoWrapper(value)),
    )

private fun booleanExpression(value: Boolean): TypedExpression =
    TypedExpression(
        resultType = SkirTypeExpression.BOOLEAN,
        expression = Expression.LiteralWrapper(TypedValue.BooleanWrapper(value)),
    )

private fun floatExpression(value: Double): TypedExpression =
    TypedExpression(
        resultType =
            SkirTypeExpression.createFloat(
                width = FloatWidth.SIXTY_FOUR_BITS,
                constraints = unboundedNumericConstraints(),
            ),
        expression = Expression.LiteralWrapper(TypedValue.FloatSixtyFourWrapper(value)),
    )

private fun defaultParagraph(): TextParagraph =
    TextParagraph(
        maxLines = null,
        overflow = PresentationTextOverflow.CLIP,
        softWrap = true,
        selectable = false,
        tone = PresentationTextTone.PRIMARY,
    )
