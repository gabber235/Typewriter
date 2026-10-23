package com.typewritermc.realm.checking

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.operations.CatalogPortableTypes
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.HostFailure
import com.typewritermc.types.unwrapNamed
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ValueLocation

internal class RealmExpressionRuntime(
    private val budget: EvaluationBudget = EvaluationBudget(maxSteps = 100_000, maxCollectionItems = 100_000),
) {
    fun evaluateBoolean(
        expression: ExpressionNode,
        location: ValueLocation,
        reads: AuthoredReads,
    ): Availability<Boolean> {
        val snapshot =
            reads as? CapturedAuthoringReads
                ?: return Availability.Failed(
                    EvaluationDiagnostic(
                        failure = HostFailure.UntrackedExpressionReads,
                        message = "Portable expressions require Realm snapshot reads.",
                        locations = listOf(location),
                    ),
                )
        val evaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader { requested -> snapshot.authoredValue(requested) },
                CatalogPortableTypes(snapshot.view.original.catalog.checked),
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
                    result.value.unwrapNamed() as? DataValue.BooleanWrapper
                        ?: return Availability.Failed(
                            EvaluationDiagnostic(
                                failure = EvaluatorFailure.ExpressionResultNotBoolean,
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

private val CONFIGURED_VALUE = ExpressionBindingId(value = "configured_value")
