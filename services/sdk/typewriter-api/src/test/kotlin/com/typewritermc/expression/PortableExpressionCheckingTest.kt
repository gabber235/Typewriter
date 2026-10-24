package com.typewritermc.expression

import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.types.DataValue
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.resolve
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode

val PortableExpressionCheckingTest by testSuite {
    val catalog = DefaultCheckedCatalog(CatalogGeneration("expression mappings"), emptyList())
    val checker = PortableExpressionChecker(catalog::resolve)
    val candidate = ExpressionBindingId("candidate")
    val parent = ExpressionBindingId("parent")
    val text = TypeUse.Scalar(ScalarKind.Text)
    val decimal = TypeUse.Scalar(ScalarKind.Decimal)
    val floating = TypeUse.Scalar(ScalarKind.Float(FloatWidth.FLOAT_32))

    fun read(id: ExpressionBindingId) = testInput(id, ValuePath())

    fun round(vararg nodes: ExpressionNode) = ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2])

    fun duration(vararg nodes: ExpressionNode) =
        ExpressionNode.createDurationFormat(source = nodes[0], units = nodes[1], fractionDigits = nodes[2])

    test("unused generic ambient bindings do not postpone concrete candidate checking") {
        val parameterOwner =
            com.typewritermc.types.TypeDefinitionId(
                com.typewritermc.types.TypeId
                    .Qualified("test", "GenericAmbient"),
                1,
            )
        val generic =
            com.typewritermc.types.TypeTemplate
                .Parameter(com.typewritermc.types.ParameterKey(parameterOwner, 0))
        val concrete =
            com.typewritermc.types.TypeTemplate
                .Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32))
        val bindings = mapOf(parent to generic, candidate to concrete)
        com.typewritermc.presentation.checkPresentationExpression(
            read(candidate),
            bindings,
            concrete,
            setOf(candidate),
            catalog::resolve,
        ) shouldBe
            emptyList()
        com.typewritermc.presentation
            .checkPresentationExpression(
                ExpressionNode.createTextUnary(operation = skirout.editor.v1.expression.TextUnaryOperation.TRIM, source = read(candidate)),
                bindings,
                concrete,
                setOf(candidate),
                catalog::resolve,
            ).isNotEmpty() shouldBe
            true
    }
    test("typed numeric rounding preserves declared unsigned width and missing input") {
        val unsigned = TypeUse.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.UNSIGNED_64))
        val expression = round(read(candidate), read(parent), testLiteral(DataValue.StringValue("Floor")))
        val inputs = mapOf(candidate to nominalExpressionType(unsigned), parent to nominalExpressionType(unsigned, true))
        checker.checkExpressionCodes(expression, inputs, nominalExpressionType(unsigned, true)) shouldBe emptyList()
        checker
            .checkExpressionCodes(
                expression,
                inputs,
                nominalExpressionType(unsigned),
            ).contains("expression_result_may_be_missing") shouldBe
            true
    }
    test("completion preserves decimal candidate family") {
        checker.checkExpressionCodes(
            round(
                read(candidate),
                testLiteral(DataValue.Decimal("0.01")),
                testLiteral(DataValue.StringValue("NearestTiesToEven")),
            ),
            mapOf(candidate to nominalExpressionType(decimal, false)),
            nominalExpressionType(decimal, false),
        ) shouldBe emptyList()
    }
    test("completion preserves narrow floating candidate family") {
        checker.checkExpressionCodes(
            round(
                read(candidate),
                testLiteral(DataValue.Float(0.5)),
                testLiteral(DataValue.StringValue("Floor")),
            ),
            mapOf(candidate to nominalExpressionType(floating, false)),
            nominalExpressionType(floating, false),
        ) shouldBe emptyList()
    }
    test("floating candidates reject decimal increments") {
        checker
            .checkExpressionCodes(
                round(
                    read(candidate),
                    testLiteral(DataValue.Decimal("0.5")),
                    testLiteral(DataValue.StringValue("Floor")),
                ),
                mapOf(candidate to nominalExpressionType(floating, false)),
                nominalExpressionType(floating, false),
            ).isNotEmpty() shouldBe true
    }
    test("completion cannot implicitly narrow another declared source width") {
        val wide = TypeUse.Scalar(ScalarKind.Float(FloatWidth.FLOAT_64))
        checker
            .checkExpressionCodes(
                read(parent),
                mapOf(parent to nominalExpressionType(wide, false)),
                nominalExpressionType(floating, false),
            ).isNotEmpty() shouldBe
            true
    }
    test("completion requires parent absence to be handled explicitly") {
        val bindings = mapOf(candidate to nominalExpressionType(text, false), parent to nominalExpressionType(text, true))
        checker
            .checkExpressionCodes(
                read(parent),
                bindings,
                nominalExpressionType(text, false),
            ).contains("expression_result_may_be_missing") shouldBe
            true
        checker.checkExpressionCodes(
            ExpressionNode.createOrElse(input = read(parent), fallback = read(candidate)),
            bindings,
            nominalExpressionType(text, false),
        ) shouldBe
            emptyList()
    }
    test("unknown local candidate aliases cannot escape their scope") {
        checker.checkExpressionCodes(read(candidate), emptyMap(), nominalExpressionType(text, false)).isNotEmpty() shouldBe true
    }
    test("duration display uses the shared text operation contract") {
        checker.checkExpressionCodes(
            duration(
                read(candidate),
                testLiteral(DataValue.StringValue("MinutesAndSeconds")),
                testLiteral(DataValue.Integer(java.math.BigInteger.ZERO)),
            ),
            mapOf(candidate to nominalExpressionType(TypeUse.Scalar(ScalarKind.Duration), false)),
            nominalExpressionType(text, false),
        ) shouldBe emptyList()
    }
}
