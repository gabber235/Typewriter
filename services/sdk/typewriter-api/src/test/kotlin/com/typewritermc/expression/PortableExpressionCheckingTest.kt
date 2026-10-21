package com.typewritermc.expression

import com.typewritermc.authoring.root
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath

val PortableExpressionCheckingTest by testSuite {
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "expression mappings"), emptyList())
    val checker = PortableExpressionChecker(catalog::resolve)
    val candidate = ExpressionBindingId("candidate")
    val parent = ExpressionBindingId("parent")
    val text = ScalarKind.TEXT.use
    val decimal = ScalarKind.DECIMAL.use
    val floating = floatScalar(FloatWidth.THIRTY_TWO).use

    fun read(id: ExpressionBindingId) = testInput(id, ValuePath.root)

    fun round(vararg nodes: ExpressionNode) = ExpressionNode.createNumberRound(source = nodes[0], increment = nodes[1], rounding = nodes[2])

    fun duration(vararg nodes: ExpressionNode) =
        ExpressionNode.createDurationFormat(source = nodes[0], units = nodes[1], fractionDigits = nodes[2])

    test("unused generic ambient bindings do not postpone concrete candidate checking") {
        val parameterOwner =
            TypeDefinitionId.qualified("test", "GenericAmbient")
        val generic =
            ParameterKey(owner = parameterOwner, index = 0).template
        val concrete =
            integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
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
        val unsigned = integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR).use
        val expression = round(read(candidate), read(parent), testLiteral(DataValue.StringValueWrapper("Floor")))
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
                testLiteral(DataValue.DecimalWrapper("0.01")),
                testLiteral(DataValue.StringValueWrapper("NearestTiesToEven")),
            ),
            mapOf(candidate to nominalExpressionType(decimal, false)),
            nominalExpressionType(decimal, false),
        ) shouldBe emptyList()
    }
    test("completion preserves narrow floating candidate family") {
        checker.checkExpressionCodes(
            round(
                read(candidate),
                testLiteral(DataValue.FloatWrapper(0.5)),
                testLiteral(DataValue.StringValueWrapper("Floor")),
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
                    testLiteral(DataValue.DecimalWrapper("0.5")),
                    testLiteral(DataValue.StringValueWrapper("Floor")),
                ),
                mapOf(candidate to nominalExpressionType(floating, false)),
                nominalExpressionType(floating, false),
            ).isNotEmpty() shouldBe true
    }
    test("completion cannot implicitly narrow another declared source width") {
        val wide = floatScalar(FloatWidth.SIXTY_FOUR).use
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
                testLiteral(DataValue.StringValueWrapper("MinutesAndSeconds")),
                testLiteral(DataValue.integer(java.math.BigInteger.ZERO)),
            ),
            mapOf(candidate to nominalExpressionType(ScalarKind.DURATION.use, false)),
            nominalExpressionType(text, false),
        ) shouldBe emptyList()
    }
}
