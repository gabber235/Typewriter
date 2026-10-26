package com.typewritermc.expression

import com.typewritermc.authoring.Availability
import com.typewritermc.configuration.ExpressionInference
import com.typewritermc.configuration.PortableExpressionChecker
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeIn
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.checkAll

val ExpressionCorpusTest by testSuite {
    test("every generated expression type checks, and evaluating it fails only for a runtime reason") {
        val checker = PortableExpressionChecker(testCatalog()::resolve)
        val evaluator = DefaultExpressionEvaluator({ error("A closed expression reads nothing.") }, testPortableTypes())
        checkAll(PropTestConfig(seed = CORPUS_SEED, iterations = 500), Arb.closedExpression(depth = 5)) { expression ->
            checker.inferExpression(expression, emptyMap()).shouldBeInstanceOf<ExpressionInference.Typed>()
            val outcome = with(FixtureReads) { evaluator.evaluate(expression, ExpressionBindings(emptyMap()), CORPUS_BUDGET) }
            if (outcome is Availability.Failed) outcome.diagnostic.failure.value shouldBeIn RUNTIME_FAILURES
        }
    }

    test("the corpus is the same in every run") {
        renderExpressionCorpus() shouldBe renderExpressionCorpus()
    }
}

/** The failures a well typed closed expression over integers and text may still meet at run time. */
private val RUNTIME_FAILURES = setOf("division_by_zero", "budget_exhausted")
