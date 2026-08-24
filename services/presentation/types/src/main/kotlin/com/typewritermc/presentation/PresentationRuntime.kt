package com.typewritermc.presentation

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.types.PresentationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.action.RealmEditorAction
import skirout.editor.v1.binding.BindingId
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.Expression
import skirout.editor.v1.expression.TypedExpression
import skirout.editor.v1.path.DataPath
import skirout.editor.v1.path.DataPathSegment
import skirout.editor.v1.path.FieldPathSegment
import skirout.editor.v1.presentation.AxisChildrenLayout
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.ButtonElement
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.ChildrenLayout
import skirout.editor.v1.presentation.ConcreteTypePresentation
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PolymorphicControl
import skirout.editor.v1.presentation.PresentationDefinition
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeader
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationProperties
import skirout.editor.v1.presentation.SearchControl
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.presentation.SearchResultMapping
import skirout.editor.v1.presentation.SearchSelectionMode
import skirout.editor.v1.presentation.SectionLayout
import skirout.editor.v1.presentation.TextContent
import skirout.editor.v1.presentation.TextControl
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NumericConstraints
import skirout.editor.v1.type_catalog.StringConstraints
import skirout.editor.v1.type_catalog.TypedValue
import skirout.editor.v1.type_catalog.PresentationId as SkirPresentationId
import skirout.editor.v1.type_catalog.TypeExpression as SkirTypeExpression

/** Runtime contribution generated for one annotated presentation function. */
interface PresentationProvider {
    val namespace: String
    val sourcePart: String
    val declarationName: String
    val default: Boolean
    val priority: Int

    fun specification(context: PresentationBuildContext): PresentationSpec<*>
}

data class PresentationDiagnostic(
    val code: String,
    val message: String,
    val namespace: String? = null,
    val sourcePart: String? = null,
    val presentationName: String? = null,
)

data class PresentationCatalog(
    val types: TypeCatalog,
    val definitions: List<PresentationDefinition>,
    val diagnostics: List<PresentationDiagnostic>,
)

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
        val byTarget = unique.groupBy(CompiledPresentation::target)
        val updatedTypes =
            types.definitions.map { definition ->
                val candidates = byTarget[definition.id].orEmpty()
                val default = select(candidates.filter(CompiledPresentation::default), "default", diagnostics)
                val named =
                    candidates
                        .groupBy { it.specificationName }
                        .mapNotNull { (name, values) -> select(values, "named presentation $name", diagnostics)?.let { name to it.id } }
                        .toMap()
                definition.copy(defaultPresentationId = default?.id, namedPresentations = named)
            }
        return PresentationCatalog(
            types = TypeCatalog(updatedTypes),
            definitions =
                unique
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
            val target = prototypes.require(specification.target).type
            val compiler = NodeCompiler(prototypes)
            val root = compiler.compile(specification.root, "root", emptyList())
            assertUniqueNodeIds(root)
            val id = PresentationId(provider.namespace, specification.name)
            val dependencies = collectPresentationDependencies(root, target)
            CompiledPresentation(
                id = id,
                target = target,
                specificationName = specification.name,
                default = provider.default,
                priority = provider.priority,
                provider = provider,
                definition =
                    PresentationDefinition(
                        presentationId = SkirPresentationId(namespace = id.namespace, name = id.name),
                        target = SkirTypeCodec.encode(TypeExpression.Named(target)).getOrThrow(),
                        root = root,
                        dependencies = dependencies.toWire(),
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
    val target: ResolvedTypeRef,
    val specificationName: String,
    val default: Boolean,
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
) {
    private var nextBindingId = 1L

    fun compile(
        node: AuthoredPresentationNode,
        path: String,
        bindingPath: List<String>,
    ): PresentationNode =
        when (node) {
            is AuthoredPresentationNode.Column -> column(node, path, bindingPath)
            is AuthoredPresentationNode.Section -> section(node, path, bindingPath)
            is AuthoredPresentationNode.TextInput -> textInput(node, path, bindingPath)
            is AuthoredPresentationNode.NumericInput -> numericInput(node, path, bindingPath)
            is AuthoredPresentationNode.CommandButton -> commandButton(node, path, bindingPath)
            is AuthoredPresentationNode.RealmSearchInput -> realmSearchInput(node, path, bindingPath)
            is AuthoredPresentationNode.PolymorphicInput -> polymorphicInput(node, path, bindingPath)
            is AuthoredPresentationNode.Wire -> node.node
        }

    private fun column(
        node: AuthoredPresentationNode.Column,
        path: String,
        bindingPath: List<String>,
    ): PresentationNode =
        presentationNode(
            path,
            PresentationElement.ChildrenWrapper(
                ChildrenElement(
                    children = node.children.mapIndexed { index, child -> compile(child, "$path.$index", bindingPath) },
                    layout =
                        ChildrenLayout.ColumnWrapper(
                            AxisChildrenLayout(
                                spacing = 8.0,
                                mainAxisAlignment = MainAxisAlignment.START,
                                crossAxisAlignment = CrossAxisAlignment.STRETCH,
                            ),
                        ),
                ),
            ),
        )

    private fun section(
        node: AuthoredPresentationNode.Section,
        path: String,
        bindingPath: List<String>,
    ): PresentationNode =
        presentationNode(
            node.key,
            PresentationElement.SectionWrapper(
                SectionLayout(child = compile(node.child, "$path.content", bindingPath), border = null),
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
    ): PresentationNode {
        val field = field(node.field)
        val fields = bindingPath + field
        val control = boundControl(fields, node.label)
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
    ): PresentationNode {
        val field = field(node.field)
        val fields = bindingPath + field
        return presentationNode(
            "field:${fields.joinToString(".")}:$path",
            PresentationElement.NumericInputWrapper(boundControl(fields, node.label)),
        )
    }

    private fun commandButton(
        node: AuthoredPresentationNode.CommandButton,
        path: String,
        bindingPath: List<String>,
    ): PresentationNode {
        val payload = bindingExpression(node.capability.requestType, 0L, bindingPath)
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

    private fun realmSearchInput(
        node: AuthoredPresentationNode.RealmSearchInput,
        path: String,
        bindingPath: List<String>,
    ): PresentationNode {
        val field = field(node.field)
        val fields = bindingPath + field
        val queryBindingId = allocateBindingId()
        val summaryBindingId = allocateBindingId()
        val resultBindingId = allocateBindingId()
        val resultValue = bindingExpression(node.capability.resultType, resultBindingId, emptyList())
        val resultKey = stringBindingExpression(resultBindingId, listOf(field(node.resultKey)))
        val resultLabel = stringBindingExpression(resultBindingId, listOf(field(node.resultLabel)))
        val resultPresentation =
            presentationNode(
                "search-result:${node.capability.id.value}:$path",
                PresentationElement.TextWrapper(TextContent.partial(value = resultLabel)),
            )
        val result =
            SearchResultMapping(
                bindingId = BindingId(value = resultBindingId),
                key = resultKey,
                selectedValue = resultValue,
                presentation = resultPresentation,
                label = resultLabel,
            )
        val provider =
            SearchProvider.createRealmCallback(
                capabilityId = CapabilityId(value = node.capability.id.value),
                payload = bindingExpression(node.capability.requestType, 0L, bindingPath),
                result = result,
                selectors = emptyList(),
            )
        return presentationNode(
            "field:${fields.joinToString(".")}:$path",
            PresentationElement.SearchInputWrapper(
                SearchControl(
                    control = boundControl(fields, node.label),
                    selectionMode = SearchSelectionMode.SINGLE,
                    queryBindingId = BindingId(value = queryBindingId),
                    summaryBindingId = BindingId(value = summaryBindingId),
                    maximumExtent = integerExpression(320),
                    provider = provider,
                    summary = null,
                    placeholder = null,
                    customValue = null,
                    initialQuery = null,
                ),
            ),
        )
    }

    private fun polymorphicInput(
        node: AuthoredPresentationNode.PolymorphicInput,
        path: String,
        bindingPath: List<String>,
    ): PresentationNode {
        val field = field(node.field)
        val fields = bindingPath + field
        val types =
            node.types.mapIndexed { index, type ->
                ConcreteTypePresentation(
                    concreteType = SkirTypeCodec.encode(prototypes.require(type.type).type).getOrThrow(),
                    label = stringExpression(type.label),
                    presentation = compile(type.root, "$path.type.$index", fields),
                )
            }
        return presentationNode(
            "field:${fields.joinToString(".")}",
            PresentationElement.PolymorphicInputWrapper(
                PolymorphicControl(control = boundControl(fields, null), concreteTypes = types),
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
            SkirTypeCodec.encode(TypeExpression.Named(prototypes.require(type).type)).getOrThrow(),
            bindingId,
            fields,
        )

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
    ): BoundControl =
        BoundControl(
            binding =
                BindingRef(
                    path =
                        DataPath(
                            segments = fields.map { DataPathSegment.FieldWrapper(FieldPathSegment(fieldName = it)) },
                        ),
                    bindingId = BindingId(value = 0),
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

private fun integerExpression(value: Int): TypedExpression =
    TypedExpression(
        resultType =
            SkirTypeExpression.createSignedInteger(
                width = IntegerWidth.THIRTY_TWO_BITS,
                constraints = NumericConstraints.partial(),
            ),
        expression = Expression.LiteralWrapper(TypedValue.SignedThirtyTwoWrapper(value)),
    )
