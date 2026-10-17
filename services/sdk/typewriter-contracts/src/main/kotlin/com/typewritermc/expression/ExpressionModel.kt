package com.typewritermc.expression

import com.typewritermc.authoring.ValueLocation
import kotlinx.serialization.Serializable

@JvmInline @Serializable
value class ExpressionBindingId(
    val value: String,
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
