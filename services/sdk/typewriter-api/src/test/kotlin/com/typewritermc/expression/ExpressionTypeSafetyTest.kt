package com.typewritermc.expression

import com.typewritermc.authoring.ValuePath
import com.typewritermc.configuration.untypedPortableOperations
import com.typewritermc.library.BookExpressions
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointId
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val ExpressionTypeSafetyTest by testSuite {
    test("handled Boolean composition remains handled") {
        val expression: Expr<Boolean, Handled> = literal(true) and literal(false)

        expression.node.shouldBeInstanceOf<ExpressionNode.And>()
    }

    test("missing composite expressions accept an explicit fallback") {
        val input: Expr<Boolean, MayBeMissing> = portableExpression(ExpressionNode.Read(ExpressionBindingId("input"), ValuePath()))
        val expression: Expr<Boolean, Handled> = (input and literal(true)).orElse(literal(false))

        expression.node.shouldBeInstanceOf<ExpressionNode.OrElse>()
    }

    test("concrete list expressions expose collection size") {
        val input: Expr<List<String>, MayBeMissing> =
            portableExpression(ExpressionNode.Read(ExpressionBindingId("items"), ValuePath()))
        val expression: Expr<Int, MayBeMissing> = input.size

        expression.node.shouldBeInstanceOf<ExpressionNode.Call>()
    }

    test("relationship target projection exposes the resource key") {
        val projected =
            PortableOperationRegistry.Standard.evaluate(
                OperationId("typewriter.link.target"),
                listOf(DataValue.Link(EndpointId("page.elements"), LinkTarget(ResourceId("page:first"), ValuePath()))),
                {},
                {},
            )
        projected shouldBe DataValue.StringValue("page:first")
    }

    test("every executable portable operation has compiler type semantics") {
        untypedPortableOperations().shouldBeEmpty()
    }

    test("generated text fields require an explicit missing fallback for computed output") {
        val expressions =
            object : BookExpressions {
                override val title: Expr<String, MayBeMissing> =
                    portableExpression(ExpressionNode.Read(ExpressionBindingId("book"), ValuePath()))
                override val icon get() = error("unused")
                override val color get() = error("unused")
                override val tags get() = error("unused")
                override val pages get() = error("unused")
            }
        val computed: Expr<String, Handled> = expressions.title.orElse(literal("Untitled"))

        computed.node.shouldBeInstanceOf<ExpressionNode.OrElse>()
    }
}
