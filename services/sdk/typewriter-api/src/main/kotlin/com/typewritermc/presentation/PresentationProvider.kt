package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.Handled
import com.typewritermc.types.Resource
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationNode

interface PresentationProvider {
    fun build(binding: PresentationBuildBinding): PresentationBuildResult
}

data class PresentationBuildResult(
    val layout: PresentationNode,
    val dependencies: PresentationDependencies,
)

interface PresentationRuntime {
    fun register(
        reference: PresentationReference,
        descriptor: PresentationDescriptor,
    )

    fun build(
        binding: PresentationBuildBinding,
        content: (PresentationBuildScope) -> Unit,
    ): PresentationBuildResult
}

interface PresentationBuildScope : Layout {
    /** Generated scope builders register nested receiver declarations in the same presentation runtime. */
    fun registerExpressions(factory: ExpressionFactory<*>)

    fun <V, S : Any> value(
        scope: kotlin.reflect.KClass<S>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope> = emptyMap(),
    ): PresentedField<V, S>

    fun <V, S : Any> field(
        name: String,
        scope: kotlin.reflect.KClass<S>,
        nested: Map<NestedPresentationSlot, NestedPresentationScope> = emptyMap(),
    ): PresentedField<V, S>

    fun <S : Any> expressions(scope: kotlin.reflect.KClass<S>): S

    fun conditional(
        condition: Expr<Boolean, Handled>,
        whenFalse: ((PresentationBuildScope) -> Unit)? = null,
        body: (PresentationBuildScope) -> Unit,
    )

    fun <R : Resource> resourceCollection(
        id: String,
        resource: kotlin.reflect.KClass<R>,
        appearance: PresentationReference? = null,
        configure: ResourceCollectionSourceScope<R>.() -> Unit = {},
    ): CollectionSource<R, com.typewritermc.types.ResourceId>
}

inline fun <reified R : Resource> PresentationBuildScope.resourceCollection(
    id: String,
    appearance: PresentationReference? = null,
    noinline configure: ResourceCollectionSourceScope<R>.() -> Unit = {},
): CollectionSource<R, com.typewritermc.types.ResourceId> = resourceCollection(id, R::class, appearance, configure)

enum class NestedPresentationSlot { Payload, Fields, Items, Keys, Values }

class NestedPresentationScope(
    val control: kotlin.reflect.KClass<*>,
    val create: ((PresentationBuildScope) -> Any)? = null,
    val nested: Map<NestedPresentationSlot, NestedPresentationScope> = emptyMap(),
)
