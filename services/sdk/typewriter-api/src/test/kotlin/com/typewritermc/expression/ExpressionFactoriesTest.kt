package com.typewritermc.expression

import com.typewritermc.configuration.TextExpressions
import com.typewritermc.configuration.TextExpressionsFactory
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.EvaluationBudget

val ExpressionFactoriesTest by testSuite {
    test("repeated generated declarations preserve the same expression output") {
        val factories = ExpressionFactories()
        factories.register(TextExpressionsFactory)
        factories.register(TextExpressionsFactory)
        val value = literal("unchanged")
        factories.create(TextExpressions::class, value).value.toNode() shouldBe value.toNode()
    }

    test("nested collection maps add each inner item to the outer item") {
        val source =
            portableLiteral<List<Int>>(
                skirout.editor.v1.type_catalog.DataValue.listValue(
                    listOf(1, 2).map { value ->
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "item:$value"),
                            value =
                                skirout.editor.v1.type_catalog.DataValue
                                    .integer(value.toBigInteger()),
                        )
                    },
                ),
            )

        fun nested() =
            source.map {
                val outer = this
                source.map { this + outer }
            }

        (nested().evaluate() as com.typewritermc.authoring.Availability.Available).value.integers() shouldBe
            listOf(listOf(2, 3), listOf(3, 4))
    }

    test("nested fold captures accumulator and outer item using lexical depth") {
        val source =
            portableLiteral<List<Int>>(
                skirout.editor.v1.type_catalog.DataValue.listValue(
                    listOf(1, 2).map { value ->
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "item:$value"),
                            value =
                                skirout.editor.v1.type_catalog.DataValue
                                    .integer(value.toBigInteger()),
                        )
                    },
                ),
            )
        val expression =
            source.fold(literal(0)) { accumulator, outer ->
                source.fold(accumulator) { inner, item -> inner + outer + item }
            }
        val result =
            with(FixtureReads) {
                DefaultExpressionEvaluator(
                    ExpressionValueReader { error("Literal program has no authored inputs") },
                    testPortableTypes(),
                ).evaluate(
                    expression.toNode(),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(maxSteps = 100, maxCollectionItems = 100),
                )
            }
        result shouldBe
            com.typewritermc.authoring.Availability
                .Available(
                    skirout.editor.v1.type_catalog.DataValue
                        .integer(12.toBigInteger()),
                )
    }

    test("conflicting generated factory identities are rejected") {
        val factories = ExpressionFactories()
        factories.register(TextExpressionsFactory)
        val conflict = object : ExpressionFactory<TextExpressions> by TextExpressionsFactory {}
        shouldThrow<IllegalArgumentException> { factories.register(conflict) }.message shouldBe
            "One expression scope cannot have conflicting factory declarations in one presentation runtime."
    }
}
