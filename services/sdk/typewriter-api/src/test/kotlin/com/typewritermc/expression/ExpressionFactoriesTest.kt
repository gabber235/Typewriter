package com.typewritermc.expression

import com.typewritermc.configuration.TextExpressions
import com.typewritermc.configuration.TextExpressionsFactory
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val ExpressionFactoriesTest by testSuite {
    test("repeated generated declarations preserve the same expression output") {
        val factories = ExpressionFactories()
        factories.register(TextExpressionsFactory)
        factories.register(TextExpressionsFactory)
        val value = literal("unchanged")
        factories.create(TextExpressions::class, value).value.toNode() shouldBe value.toNode()
    }

    test("nested collection lowering captures outer locals without allocating serialized names") {
        val source =
            portableLiteral<List<Int>>(
                com.typewritermc.types.DataValue.ListValue(
                    listOf(1, 2).map { value ->
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("item:$value"),
                            com.typewritermc.types.DataValue
                                .Integer(value.toBigInteger()),
                        )
                    },
                ),
            )

        fun nested() =
            source.map {
                val outer = this
                source.map { this + outer }
            }
        val first = nested().toNode()
        first shouldBe nested().toNode()
        val depths = mutableListOf<Int>()

        fun inspect(node: skirout.editor.v1.expression.ExpressionNode) {
            if (node is skirout.editor.v1.expression.ExpressionNode.LocalWrapper) depths += node.value.depth
            node.children().forEach { inspect(it.node) }
        }
        inspect(first)
        depths.toSet() shouldBe setOf(0, 1)
        val result =
            with(FixtureReads) {
                DefaultExpressionEvaluator(ExpressionValueReader { error("Literal program has no authored inputs") }).evaluate(
                    first,
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(100, 100),
                )
            } as com.typewritermc.authoring.Availability.Available<com.typewritermc.types.DataValue>
        val rows =
            (result.value as com.typewritermc.types.DataValue.ListValue).items.map { row ->
                (row.value as com.typewritermc.types.DataValue.ListValue).items.map {
                    (it.value as com.typewritermc.types.DataValue.Integer)
                        .value
                        .toInt()
                }
            }
        rows shouldBe listOf(listOf(2, 3), listOf(3, 4))
        var escaped: Expr<Int, MayBeMissing>? = null
        source.map {
            escaped = this
            this
        }
        shouldThrow<IllegalArgumentException> { escaped!!.toNode() }
    }
    test("nested fold captures accumulator and outer item using lexical depth") {
        val source =
            portableLiteral<List<Int>>(
                com.typewritermc.types.DataValue.ListValue(
                    listOf(1, 2).map { value ->
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("item:$value"),
                            com.typewritermc.types.DataValue
                                .Integer(value.toBigInteger()),
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
                DefaultExpressionEvaluator(ExpressionValueReader { error("Literal program has no authored inputs") }).evaluate(
                    expression.toNode(),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(100, 100),
                )
            }
        result shouldBe
            com.typewritermc.authoring.Availability
                .Available(
                    com.typewritermc.types.DataValue
                        .Integer(12.toBigInteger()),
                )
    }

    test("conflicting generated factory identities are rejected") {
        val factories = ExpressionFactories()
        factories.register(TextExpressionsFactory)
        val conflict = object : ExpressionFactory<TextExpressions> by TextExpressionsFactory {}
        shouldThrow<IllegalArgumentException> { factories.register(conflict) }
    }
}
