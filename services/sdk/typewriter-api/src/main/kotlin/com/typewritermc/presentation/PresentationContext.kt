package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.MayBeMissing
import kotlin.reflect.KClass

/** A typed caller supplied observation. Canonical resource facts are queried separately. */
class PresentationContextKey<Value : Any>
    @PublishedApi
    internal constructor(
        val binding: ExpressionBindingId,
        val valueClass: KClass<Value>,
    )

inline fun <reified Value : Any> presentationContextKey(id: String): PresentationContextKey<Value> {
    require(id.isNotBlank()) { "Caller input identity must not be blank." }
    return PresentationContextKey(ExpressionBindingId("context:$id"), Value::class)
}

internal class RuntimePresentationContext(
    private val state: PresentationBuildState,
) : PresentationContextExpressions {
    override val selectionCount =
        Expr<Int, MayBeMissing>(
            ExpressionNode.Read(ExpressionBindingId("presentation.context.selection_count"), ValuePath()),
        )

    override fun <Value : Any> read(key: PresentationContextKey<Value>): Expr<Value, MayBeMissing> = state.readContext(key)
}
