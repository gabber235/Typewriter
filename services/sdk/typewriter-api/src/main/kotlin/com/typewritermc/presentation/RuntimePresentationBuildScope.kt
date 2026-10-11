package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import kotlin.reflect.KClass

internal class RuntimePresentationBuildScope(
    private val state: PresentationBuildState,
    layout: AxisLayout,
    private val target: MutableList<PresentationNode>,
    private val checked: CheckedPresentationTemplate,
    private val base: BindingRef,
) : PresentationBuildScope,
    AxisLayout by layout {
    override fun <V, S : Any> field(
        name: String,
        scope: KClass<S>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    ): PresentedField<V, S> = presentedField(name, scope, nested)

    override fun <V, S : Any> value(
        scope: KClass<S>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    ): PresentedField<V, S> = presentedValue(scope, nested)

    private fun <V, S : Any> presentedField(
        name: String,
        scope: KClass<S>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    ): PresentedField<V, S> = RuntimePresentedField(state, name, scope, nested, base.field(name), checked.field(name))

    private fun <V, S : Any> presentedValue(
        scope: KClass<S>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    ): PresentedField<V, S> = RuntimePresentedField(state, "value", scope, nested, base, checked)

    override fun registerExpressions(factory: ExpressionFactory<*>) = state.expressions.register(factory)

    override fun <S : Any> expressions(scope: KClass<S>): S =
        state.expressions.create(scope, Expr<Any?, MayBeMissing>(ExpressionNode.Read(CONFIGURED_VALUE, ValuePath())))

    override fun conditional(
        condition: Expr<Boolean, Handled>,
        whenFalse: ((PresentationBuildScope) -> Unit)?,
        body: (PresentationBuildScope) -> Unit,
    ) {
        val whenTrueNodes = mutableListOf<PresentationNode>()
        state.withTarget(whenTrueNodes) { body(state.scope(whenTrueNodes)) }
        val whenFalseNode =
            whenFalse?.let { content ->
                val nodes = mutableListOf<PresentationNode>()
                state.withTarget(nodes) { content(state.scope(nodes)) }
                state.column(nodes)
            }
        target +=
            state.node(
                PresentationElement.createConditional(
                    condition = expression(condition),
                    whenTrue = state.column(whenTrueNodes),
                    whenFalse = whenFalseNode,
                ),
            )
    }

    override fun <R : Resource> resourceCollection(
        id: String,
        resource: KClass<R>,
        appearance: PresentationReference?,
        configure: ResourceCollectionSourceScope<R>.() -> Unit,
    ): CollectionSource<R, ResourceId> = resourceCollectionSource(id, state.resourceType(resource), appearance, configure)
}
