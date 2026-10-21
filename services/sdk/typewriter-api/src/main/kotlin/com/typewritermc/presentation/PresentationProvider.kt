@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.Handled
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationNode

/**
 * Builds portable layout and dependency declarations for a checked type template and presentation role.
 * Providers describe behavior for editor consumers; rendering, interaction state, and authored edits live in the
 * consuming runtime. Catalog assembly invokes providers to publish reusable materials, including generic templates.
 */
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

    @GeneratedSdkApi
    fun build(
        binding: PresentationBuildBinding,
        content: (PresentationBuildScope) -> Unit,
    ): PresentationBuildResult
}

@GeneratedSdkApi
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

    /**
     * The evaluated display of the presented resource, which editors bind whenever they present one. Generated
     * resource presentation scopes expose it as `appearance`.
     */
    fun resourceAppearance(): Expr<skirout.editor.v1.catalog.ResourceAppearance, Handled>

    fun conditional(
        condition: Expr<Boolean, Handled>,
        whenFalse: ((PresentationBuildScope) -> Unit)? = null,
        body: (PresentationBuildScope) -> Unit,
    )
}

enum class NestedPresentationSlot { Payload, Fields, Items, Keys, Values }

class NestedPresentationScope(
    val control: kotlin.reflect.KClass<*>,
    val create: ((PresentationBuildScope) -> Any)? = null,
    val nested: Map<NestedPresentationSlot, NestedPresentationScope> = emptyMap(),
)
