package com.typewritermc.expression

import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ValueLocation

@JvmInline @Serializable
value class ExpressionBindingId(
    val value: String,
)

@Serializable
data class EvaluationBudget(
    val maxSteps: Long,
    val maxCollectionItems: Long,
)

data class ExpressionBindings(
    val locations: Map<ExpressionBindingId, ValueLocation>,
)

data class EvaluationDiagnostic(
    val code: String,
    val message: String,
    val locations: List<ValueLocation>,
)
