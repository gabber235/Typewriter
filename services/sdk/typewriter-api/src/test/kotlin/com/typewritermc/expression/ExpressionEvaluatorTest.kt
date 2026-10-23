package com.typewritermc.expression

import com.typewritermc.authoring.Availability
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.PortableOperationCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue

val ExpressionEvaluatorTest by testSuite {
    val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No authored reads expected.") })
    val budget = EvaluationBudget(maxSteps = 100, maxCollectionItems = 100)

    test("Realm fails a profile panel call instead of evaluating it") {
        val format =
            ExpressionNode.createCall(
                operation = PortableOperationCatalog.NUMBER_FORMAT.id,
                typeArguments = emptyList(),
                arguments =
                    listOf(
                        ExpressionNode.LiteralWrapper(DataValue.DecimalWrapper("1.5")),
                        ExpressionNode.LiteralWrapper(DataValue.IntegerWrapper("2")),
                        ExpressionNode.LiteralWrapper(DataValue.StringValueWrapper("en")),
                    ),
            )
        val result = with(FixtureReads) { evaluator.evaluate(format, ExpressionBindings(emptyMap()), budget) }
        (result as Availability.Failed).diagnostic.failure shouldBe EvaluatorFailure.OutsideRuleProfile
    }
}
