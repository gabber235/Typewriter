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
        factories.create(TextExpressions::class, value).value.node shouldBe value.node
    }

    test("conflicting generated factory identities are rejected") {
        val factories = ExpressionFactories()
        factories.register(TextExpressionsFactory)
        val conflict = object : ExpressionFactory<TextExpressions> by TextExpressionsFactory {}
        shouldThrow<IllegalArgumentException> { factories.register(conflict) }
    }
}
