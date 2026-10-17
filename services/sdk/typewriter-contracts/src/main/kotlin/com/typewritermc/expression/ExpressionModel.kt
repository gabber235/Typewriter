package com.typewritermc.expression

import com.typewritermc.authoring.ValueLocation
import com.typewritermc.types.TypeUse
import kotlinx.serialization.Serializable

@JvmInline @Serializable
value class OperationId(
    val value: String,
)

@JvmInline @Serializable
value class ExpressionBindingId(
    val value: String,
)

@Serializable
data class ExpressionType(
    val value: TypeUse,
    val mayBeMissing: Boolean,
)

@Serializable
data class EvaluationBudget(
    val maxSteps: Long,
    val maxCollectionItems: Long,
)

@Serializable
data class ExpressionBindings(
    val locations: Map<ExpressionBindingId, ValueLocation>,
)

@Serializable
data class EvaluationDiagnostic(
    val code: String,
    val message: String,
    val locations: List<ValueLocation>,
)
