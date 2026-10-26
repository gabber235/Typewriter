package com.typewritermc.expression

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.root
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.library.BookExpressions
import com.typewritermc.types.ResourceId
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ValuePath

val ExpressionTypeSafetyTest by testSuite {
    test("handled Boolean composition evaluates without a fallback") {
        val expression: Expr<Boolean, Handled> = literal(true) and literal(false)

        expression.evaluate() shouldBe Availability.Available(DataValue.BooleanWrapper(false))
    }

    test("missing composite expressions accept an explicit fallback") {
        val input: Expr<Boolean, MayBeMissing> = portableExpression(testInput(ExpressionBindingId(value = "input"), ValuePath.root))
        val expression: Expr<Boolean, Handled> = (input and literal(true)).orElse(literal(false))

        expression.evaluate("input" to null) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
        expression.evaluate("input" to DataValue.BooleanWrapper(true)) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
    }

    test("concrete list expressions expose collection size") {
        val input: Expr<List<String>, MayBeMissing> =
            portableExpression(testInput(ExpressionBindingId(value = "items"), ValuePath.root))
        val expression: Expr<Int, MayBeMissing> = input.size

        expression.evaluate("items" to integerList(4, 5, 6)) shouldBe Availability.Available(DataValue.integer(3L))
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
                DefaultExpressionEvaluator(ExpressionValueReader { error("No authored read expected") }, testPortableTypes()).evaluate(
                    ExpressionNode.createCall(
                        operation = PortableOperationCatalog.LINK_TARGET.id,
                        typeArguments = emptyList(),
                        arguments = listOf(source),
                    ),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(maxSteps = 20, maxCollectionItems = 20),
                )
            }
        projected shouldBe
            com.typewritermc.authoring.Availability.Available(
                DataValue.named(com.typewritermc.types.ResourceIdDefinition.use, DataValue.StringValueWrapper("page:first")),
            )
    }

    test("generated text fields require an explicit missing fallback for computed output") {
        val title: Expr<String, MayBeMissing> = portableExpression(testInput(ExpressionBindingId(value = "title"), ValuePath.root))
        val expressions =
            object : BookExpressions {
                override val library get() = error("unused")
                override val title = title
                override val icon get() = error("unused")
                override val color get() = error("unused")
                override val tags get() = error("unused")
                override val pages get() = error("unused")
            }
        val computed: Expr<String, Handled> = expressions.title.orElse(literal("Untitled"))

        computed.evaluate("title" to null) shouldBe Availability.Available(DataValue.StringValueWrapper("Untitled"))
        computed.evaluate("title" to DataValue.StringValueWrapper("Atlas")) shouldBe
            Availability.Available(DataValue.StringValueWrapper("Atlas"))
    }
}
