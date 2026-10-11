package com.typewritermc.realm.checking

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.EvaluationBudget
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue

internal class RealmExpressionRuntime(
    private val budget: EvaluationBudget = EvaluationBudget(maxSteps = 100_000, maxCollectionItems = 100_000),
) {
    fun evaluateBoolean(
        expression: ExpressionNode,
        location: com.typewritermc.authoring.ValueLocation,
        reads: AuthoredReads,
    ): Availability<Boolean> {
        val snapshot =
            reads as? CapturedAuthoringReads
                ?: return Availability.Failed(
                    EvaluationDiagnostic(
                        code = "untracked_expression_reads",
                        message = "Portable expressions require Realm snapshot reads.",
                        locations = listOf(location),
                    ),
                )
        val evaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader { requested -> snapshot.authoredValue(requested) },
            )
        val result =
            with(reads) {
                evaluator.evaluate(
                    expression,
                    ExpressionBindings(mapOf(CONFIGURED_VALUE to location)),
                    budget,
                )
            }
        return when (result) {
            is Availability.Available -> {
                val boolean =
                    result.value.unwrapNamed() as? DataValue.Boolean
                        ?: return Availability.Failed(
                            EvaluationDiagnostic(
                                code = "expression_result_not_boolean",
                                message = "The portable predicate did not produce a boolean value.",
                                locations = listOf(location),
                            ),
                        )
                Availability.Available(boolean.value)
            }

            is Availability.Unavailable -> {
                result
            }

            is Availability.Failed -> {
                result
            }
        }
    }
}

internal class RealmSelectionPredicateEvaluator(
    private val expressions: RealmExpressionRuntime = RealmExpressionRuntime(),
) : SelectionPredicateEvaluator {
    override fun evaluate(
        predicate: ExpressionNode,
        subject: DraftBinding,
        reads: AuthoredReads,
    ): Availability<Boolean> = expressions.evaluateBoolean(predicate, subject.location, reads)
}

private val CONFIGURED_VALUE = ExpressionBindingId("configured_value")

private fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.Named) payload.unwrapNamed() else this
