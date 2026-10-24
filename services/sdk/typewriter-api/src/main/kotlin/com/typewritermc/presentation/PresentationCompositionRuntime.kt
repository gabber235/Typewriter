package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import kotlin.reflect.KClass
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

internal class RuntimePresentationData(
    val state: PresentationBuildState,
    val target: MutableList<PresentationNode>,
    private val checked: CheckedPresentationTemplate,
) : PresentationData {
    override fun showIf(
        condition: Expr<Boolean, Handled>,
        whenFalse: (Layout.() -> Unit)?,
        body: Layout.() -> Unit,
    ) {
        val nodes = mutableListOf<PresentationNode>()
        state.withTarget(nodes) { state.scope(nodes).body() }
        val falseNode = whenFalse?.let(state::presentation)
        target +=
            state.node(
                PresentationElement.createConditional(
                    condition = state.lower(condition, BOOLEAN_SLOT),
                    whenTrue = state.column(nodes),
                    whenFalse = falseNode,
                ),
            )
    }

    override fun <V, ItemScope> repeated(
        source: Expr<List<V>, Handled>,
        items: SequenceScope<ItemScope>.() -> Unit,
    ) = renderRepeated(source, items)

    override fun <V, Scope> scoped(
        binding: PresentationInput<V, Scope>,
        body: Scope.() -> Unit,
    ) = scopedContents(binding, false, body)

    override fun <V, Scope> typedField(
        binding: PresentationInput<V, Scope>,
        body: Scope.() -> Unit,
    ) = scopedContents(binding, true, body)

    override fun <Row, Key> collectionLookup(
        source: CollectionSource<Row, Key>,
        key: PresentationInput<Key, *>,
        configure: LookupScope<Row>.() -> Unit,
    ) = renderCollectionLookup(source, key, configure)

    override fun <Row, Key> collectionGraph(
        source: CollectionSource<Row, Key>,
        configure: GraphScope<Row, Key>.() -> Unit,
    ) = renderCollectionGraph(source, configure)

    private fun <V, Scope> scopedContents(
        input: PresentationInput<V, Scope>,
        typed: Boolean,
        body: Scope.() -> Unit,
    ) {
        if (typed) {
            val expected = requireNotNull(input.expected) { "A typed presentation input must carry its expected type." }
            val children = mutableListOf<PresentationNode>()
            val session = input.rebind?.invoke(input.binding, children) ?: input.session
            val child = scopedChild(session, body, children)
            target +=
                state.node(PresentationElement.createTypedField(binding = input.binding, expectedType = expected, presentation = child))
            return
        }
        state.introduce("scoped.value", state.typeOf(input.binding)) { scope ->
            val children = mutableListOf<PresentationNode>()
            val local = BindingRef(path = WireValuePath(segments = emptyList()), bindingId = scope.id)
            val session = input.rebind?.invoke(local, children) ?: input.session
            val child = scopedChild(session, body, children)
            target += state.node(PresentationElement.createScopedBinding(binding = input.binding, scopeBinding = scope, child = child))
        }
    }

    private fun <Scope> scopedChild(
        session: ControlScopeSession<Scope>,
        body: Scope.() -> Unit,
        children: MutableList<PresentationNode> = mutableListOf(),
    ): PresentationNode {
        state.withTarget(children) {
            session.receiver.body()
            session.finishInto(children)
        }
        return state.column(children)
    }

    override fun <V> polymorphicMatch(
        binding: PresentationInput<V, *>,
        cases: MatchScope<V>.() -> Unit,
    ) {
        state.introduce("match.value", state.typeOf(binding.binding)) { scope -> renderMatch(binding, scope, cases) }
    }

    /** Each case sees the matched value through [scope], typed as the case's concrete type. */
    private fun <V> renderMatch(
        binding: PresentationInput<V, *>,
        scope: skirout.editor.v1.presentation.BindingDeclaration,
        cases: MatchScope<V>.() -> Unit,
    ) {
        val wireCases = mutableListOf<skirout.editor.v1.presentation.PolymorphicMatchCase>()
        var fallback: PresentationNode? = null
        val matchScope =
            object : MatchScope<V> {
                override fun <Subtype : V> case(
                    type: AppliedPresentation<Subtype>,
                    body: MatchCaseScope<Subtype>.() -> Unit,
                ) {
                    state.type(type.type.use)
                    require(wireCases.none { candidate -> candidate.concreteType == type.type }) {
                        "A polymorphic match may declare one case per concrete type."
                    }
                    val nodes = mutableListOf<PresentationNode>()
                    val layout = state.scope(nodes)
                    val caseScope =
                        object : MatchCaseScope<Subtype>, Layout by layout {
                            override val value =
                                com.typewritermc.expression.inputExpression<Subtype, com.typewritermc.expression.MayBeMissing>(scope.id)
                        }
                    state.declare(scope.id, type.type.use.toTemplate()) { state.withTarget(nodes) { caseScope.body() } }
                    wireCases +=
                        skirout.editor.v1.presentation.PolymorphicMatchCase(
                            concreteType = type.type.use,
                            child = state.column(nodes),
                        )
                }

                override fun fallback(body: Layout.() -> Unit) {
                    check(fallback == null) { "A polymorphic match may declare fallback content once." }
                    fallback = state.presentation(body)
                }
            }
        matchScope.cases()
        require(wireCases.isNotEmpty()) { "A polymorphic match requires at least one concrete case." }
        target +=
            state.node(
                PresentationElement.createPolymorphicMatch(
                    binding = binding.binding,
                    scopeBinding = scope,
                    cases = wireCases,
                    fallback = fallback,
                ),
            )
    }

    override fun invoke(
        presentation: PresentationReference,
        arguments: PresentationArguments.() -> Unit,
    ) {
        val id =
            requireNotNull(state.presentationId(presentation, checked)) {
                "The invoked presentation reference was not registered by its generated provider."
            }
        val wireArguments = mutableListOf<skirout.editor.v1.presentation.PresentationArgument>()
        val scope =
            object : PresentationArguments {
                override fun <Value> bind(
                    parameter: PresentationParameter<Value>,
                    value: PresentationInput<out Value, *>,
                ) {
                    require(!parameter.binding.value.startsWith("context:")) { "Presentation parameters cannot shadow caller inputs." }
                    require(wireArguments.none { it.input.value == parameter.binding.value }) {
                        "A presentation parameter may be bound once per invocation."
                    }
                    wireArguments +=
                        skirout.editor.v1.presentation.PresentationArgument(
                            input = parameter.binding,
                            binding = value.binding,
                        )
                }
            }
        scope.arguments()
        target +=
            state.node(
                PresentationElement.createInvocation(
                    presentationId = id,
                    arguments = wireArguments,
                ),
            )
    }
}

internal class RuntimePresentedField<V, S : Any>(
    private val state: PresentationBuildState,
    val name: String,
    private val scope: KClass<S>,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val binding: BindingRef,
    private val checked: CheckedPresentationTemplate,
    private val authorScope: RuntimePresentationBuildScope,
) : PresentedField<V, S> {
    override val input: PresentationInput<V, S>
        get() {
            val createScope: (BindingRef, MutableList<PresentationNode>) -> ControlScopeSession<S> = { rebound, children ->
                val runtime =
                    RuntimeControlBinding(
                        state,
                        children,
                        name,
                        rebound,
                        checked,
                        nested,
                        null,
                        authorScope,
                    )
                ControlScopeSession(
                    receiver = state.controls.create(scope, runtime),
                    finish = runtime::finishInto,
                )
            }
            return PresentationInput(
                binding = binding,
                session = createScope(binding, state.currentTarget),
                expected = checked.type,
                rebind = createScope,
            )
        }

    override fun invoke(
        using: PresentationReference?,
        configure: S.() -> Unit,
    ) {
        val presentationId =
            using?.let { state.presentationId(it, checked) }
        require(using == null || presentationId != null) {
            "The selected presentation reference was not registered by its generated provider."
        }
        val controlBinding = RuntimeControlBinding(state, state.currentTarget, name, binding, checked, nested, presentationId, authorScope)
        val control = state.controls.create(scope, controlBinding)
        control.configure()
        controlBinding.finishInto(state.currentTarget)
    }
}
