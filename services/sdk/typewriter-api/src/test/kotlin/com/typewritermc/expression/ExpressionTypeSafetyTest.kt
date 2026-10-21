package com.typewritermc.expression

import com.typewritermc.authoring.root
import com.typewritermc.library.BookExpressions
import com.typewritermc.types.ResourceId
import com.typewritermc.types.named
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ValuePath

val ExpressionTypeSafetyTest by testSuite {
    test("handled Boolean composition remains handled") {
        val expression: Expr<Boolean, Handled> = literal(true) and literal(false)

        expression.toNode().shouldBeInstanceOf<ExpressionNode.AndWrapper>()
    }

    test("missing composite expressions accept an explicit fallback") {
        val input: Expr<Boolean, MayBeMissing> = portableExpression(testInput(ExpressionBindingId("input"), ValuePath.root))
        val expression: Expr<Boolean, Handled> = (input and literal(true)).orElse(literal(false))

        expression.toNode().shouldBeInstanceOf<ExpressionNode.OrElseWrapper>()
    }

    test("concrete list expressions expose collection size") {
        val input: Expr<List<String>, MayBeMissing> =
            portableExpression(testInput(ExpressionBindingId("items"), ValuePath.root))
        val expression: Expr<Int, MayBeMissing> = input.size

        expression.toNode().shouldBeInstanceOf<ExpressionNode.CollectionSizeWrapper>()
    }

    test("relationship target projection exposes the resource key") {
        val source =
            testLiteral(
                DataValue.createLink(
                    endpoint = EndpointId(value = "page.elements"),
                    target = LinkTarget(resource = ResourceId("page:first").toSkir(), opposite = ValuePath.root),
                ),
            )
        val projected =
            with(FixtureReads) {
                DefaultExpressionEvaluator(ExpressionValueReader { error("No authored read expected") }).evaluate(
                    ExpressionNode.LinkTargetWrapper(source),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(20, 20),
                )
            }
        projected shouldBe
            com.typewritermc.authoring.Availability.Available(
                DataValue.named(com.typewritermc.types.ResourceIdDefinition.use, DataValue.StringValueWrapper("page:first")),
            )
    }

    test("generated text fields require an explicit missing fallback for computed output") {
        val expressions =
            object : BookExpressions {
                override val library get() = error("unused")
                override val title: Expr<String, MayBeMissing> =
                    portableExpression(testInput(ExpressionBindingId("book"), ValuePath.root))
                override val icon get() = error("unused")
                override val color get() = error("unused")
                override val tags get() = error("unused")
                override val pages get() = error("unused")
            }
        val computed: Expr<String, Handled> = expressions.title.orElse(literal("Untitled"))

        computed.toNode().shouldBeInstanceOf<ExpressionNode.OrElseWrapper>()
    }
}
