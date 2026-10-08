package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.configuration.generatedExpressionScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment
import kotlin.reflect.KClass
import skirout.editor.v1.type_catalog.RelativeFieldPattern as WireRelativeFieldPattern
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

internal fun PresentationLayoutHandler.presentedField(
    name: String,
    scope: KClass<*>,
    nested: Map<NestedPresentationSlot, NestedPresentationScope>,
): PresentedField<*, *> {
    val fieldType = checked.field(name)
    @Suppress("UNCHECKED_CAST")
    return RuntimePresentedField<Any?, Any>(
        state,
        name,
        scope as KClass<Any>,
        nested,
        base.field(name),
        fieldType,
    )
}

internal fun PresentationLayoutHandler.presentedValue(
    scope: KClass<*>,
    nested: Map<NestedPresentationSlot, NestedPresentationScope>,
): PresentedField<*, *> {
    @Suppress("UNCHECKED_CAST")
    return RuntimePresentedField<Any?, Any>(state, "value", scope as KClass<Any>, nested, base, checked)
}

internal fun PresentationLayoutHandler.expressions(scope: KClass<*>): Any =
    generatedExpressionScope(
        scope,
        Expr<Any?, com.typewritermc.expression.MayBeMissing>(
            ExpressionNode.Read(CONFIGURED_VALUE, ValuePath()),
        ),
    )

@Suppress("UNCHECKED_CAST")
internal fun PresentationLayoutHandler.scoped(
    args: Array<out Any?>,
    typed: Boolean,
) {
    val input = args[0] as PresentationInput<*, *>
    val children = mutableListOf<PresentationNode>()
    val scopeBinding = if (typed) null else state.bindingId("scoped.value")
    val receiver =
        if (typed) {
            val factory = input.rebind as? (BindingRef, MutableList<PresentationNode>) -> Any?
            factory?.invoke(input.binding, children) ?: input.scope
        } else {
            val rebound =
                BindingRef(
                    path = WireValuePath(segments = emptyList()),
                    bindingId = requireNotNull(scopeBinding).wire(),
                )
            val factory = input.rebind as? (BindingRef, MutableList<PresentationNode>) -> Any?
            factory?.invoke(rebound, children) ?: input.scope
        }
    state.withTarget(children) { invokeBlock(args[1], requireNotNull(receiver)) }
    val child = state.column(children)
    target +=
        if (typed) {
            val expected = requireNotNull(input.expected) { "A typed presentation input must carry its expected type." }
            state.node(
                PresentationElement.createTypedField(
                    binding = input.binding,
                    expectedType = SkirTypeCodec.encode(expected).getOrThrow(),
                    presentation = child,
                ),
            )
        } else {
            state.node(
                PresentationElement.createScopedBinding(
                    binding = input.binding,
                    scopeBindingId = requireNotNull(scopeBinding).wire(),
                    child = child,
                ),
            )
        }
}

internal fun PresentationLayoutHandler.polymorphicMatch(args: Array<out Any?>) {
    val input = args[0] as PresentationInput<*, *>
    val binding = state.bindingId("match.value")
    val cases = mutableListOf<skirout.editor.v1.presentation.PolymorphicMatchCase>()
    var fallback: PresentationNode? = null
    val scope =
        object : MatchScope<Any?> {
            override fun <Subtype : Any?> case(
                type: AppliedPresentation<Subtype>,
                body: MatchCaseScope<Subtype>.() -> Unit,
            ) {
                state.type(type.type)
                require(cases.none { candidate -> candidate.concreteType == SkirTypeCodec.encode(type.type).getOrThrow() }) {
                    "A polymorphic match may declare one case per concrete type."
                }
                val nodes = mutableListOf<PresentationNode>()
                val layout = state.scope(nodes)
                val caseScope =
                    object : MatchCaseScope<Subtype>, Layout by layout {
                        override val value =
                            Expr<Subtype, com.typewritermc.expression.MayBeMissing>(
                                ExpressionNode.Read(binding, ValuePath()),
                            )
                    }
                state.withTarget(nodes) { caseScope.body() }
                cases +=
                    skirout.editor.v1.presentation.PolymorphicMatchCase(
                        concreteType = SkirTypeCodec.encode(type.type).getOrThrow(),
                        child = state.column(nodes),
                    )
            }

            override fun fallback(body: Layout.() -> Unit) {
                check(fallback == null) { "A polymorphic match may declare fallback content once." }
                fallback = state.presentation(body)
            }
        }
    invokeBlock(args[1], scope)
    require(cases.isNotEmpty()) { "A polymorphic match requires at least one concrete case." }
    target +=
        state.node(
            PresentationElement.createPolymorphicMatch(
                binding = input.binding,
                scopeBindingId = binding.wire(),
                cases = cases,
                fallback = fallback,
            ),
        )
}

internal fun PresentationLayoutHandler.invokePresentation(args: Array<out Any?>) {
    val reference = args[0] as PresentationReference
    val id =
        requireNotNull(state.presentationId(reference, checked)) {
            "The invoked presentation reference was not registered by its generated provider."
        }
    val arguments = mutableListOf<skirout.editor.v1.presentation.PresentationArgument>()
    val scope =
        object : PresentationArguments {
            override fun <Value> bind(
                parameter: PresentationParameter<Value>,
                value: PresentationInput<out Value, *>,
            ) {
                require(arguments.none { it.input.value == parameter.binding.value }) {
                    "A presentation parameter may be bound once per invocation."
                }
                arguments +=
                    skirout.editor.v1.presentation.PresentationArgument(
                        input = parameter.binding.wire(),
                        binding = value.binding,
                    )
            }
        }
    invokeBlock(args[1], scope)
    target +=
        state.node(
            PresentationElement.createInvocation(
                presentationId =
                    skirout.editor.v1.type_catalog
                        .PresentationId(namespace = id.namespace, name = id.name),
                arguments = arguments,
            ),
        )
}

internal fun PresentationLayoutHandler.conditional(
    condition: Expr<Boolean, Handled>,
    whenFalse: Any?,
    body: Any?,
) {
    val whenTrueNodes = mutableListOf<PresentationNode>()
    state.withTarget(whenTrueNodes) { invokeBlock(body, state.scope(whenTrueNodes)) }
    val whenFalseNode =
        if (whenFalse == null) {
            null
        } else {
            val whenFalseNodes = mutableListOf<PresentationNode>()
            state.withTarget(whenFalseNodes) { invokeBlock(whenFalse, state.scope(whenFalseNodes)) }
            state.column(whenFalseNodes)
        }
    target +=
        state.node(
            PresentationElement.createConditional(
                condition = SkirTypeCodec.encode(condition.node).getOrThrow(),
                whenTrue = state.column(whenTrueNodes),
                whenFalse = whenFalseNode,
            ),
        )
}

internal fun PresentationLayoutHandler.remainingFields(configuration: Any?) {
    val excluded = mutableListOf<String>()
    val scope =
        object : RemainingFields {
            override fun exclude(field: PresentedField<*, *>) {
                excluded += (field as RuntimePresentedField<*, *>).name
            }
        }
    invokeBlock(configuration, scope)
    val patterns =
        excluded.map { name ->
            WireRelativeFieldPattern(
                segments =
                    listOf(
                        FieldPatternSegment.FieldWrapper(
                            NamedFieldPatternSegment(name = name),
                        ),
                    ),
            )
        }
    target += state.node(PresentationElement.createRemainingFields(excluded = patterns))
}

private class RuntimePresentedField<V, S : Any>(
    private val state: PresentationBuildState,
    val name: String,
    private val scope: KClass<S>,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val binding: BindingRef,
    private val checked: CheckedPresentationTemplate,
) : PresentedField<V, S> {
    override val input: PresentationInput<V, S>
        get() {
            val createScope: (BindingRef, MutableList<PresentationNode>) -> S = { rebound, children ->
                proxy(
                    scope,
                    PresentationControlHandler(
                        state = state,
                        target = children,
                        field = name,
                        fieldBinding = rebound,
                        checked = checked,
                        nested = nested,
                        selectedPresentation = null,
                    ),
                )
            }
            return PresentationInput(
                binding = binding,
                scope = createScope(binding, state.currentTarget),
                expected = checked.type,
                rebind = createScope,
            )
        }

    override fun invoke(
        using: PresentationReference?,
        configure: S.() -> Unit,
    ) {
        val presentationId =
            using?.let { state.presentationId(it, checked) }?.let { id ->
                skirout.editor.v1.type_catalog
                    .PresentationId(namespace = id.namespace, name = id.name)
            }
        require(using == null || presentationId != null) {
            "The selected presentation reference was not registered by its generated provider."
        }
        val handler = PresentationControlHandler(state, state.currentTarget, name, binding, checked, nested, presentationId)
        val control = proxy(scope, handler)
        control.configure()
        if (!handler.emitted) handler.defaultPresentation()
    }
}
