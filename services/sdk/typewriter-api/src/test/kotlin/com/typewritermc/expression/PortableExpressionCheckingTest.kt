package com.typewritermc.expression

import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.resolve
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val PortableExpressionCheckingTest by testSuite {
    val catalog = DefaultCheckedCatalog(CatalogGeneration("expression mappings"), emptyList())
    val checker = PortableExpressionChecker(catalog::resolve)
    val candidate = ExpressionBindingId("candidate")
    val parent = ExpressionBindingId("parent")
    val text = TypeUse.Scalar(ScalarKind.Text)
    val decimal = TypeUse.Scalar(ScalarKind.Decimal)
    val floating = TypeUse.Scalar(ScalarKind.Float(FloatWidth.FLOAT_32))
    fun read(id: ExpressionBindingId) = ExpressionNode.Read(id, ValuePath())
    fun call(id: String, vararg nodes: ExpressionNode) = ExpressionNode.Call(OperationId(id), nodes.toList())

    test("unused generic ambient bindings do not postpone concrete candidate checking") {
        val parameterOwner = com.typewritermc.types.TypeDefinitionId(com.typewritermc.types.TypeId.Qualified("test", "GenericAmbient"), 1)
        val generic = com.typewritermc.types.TypeTemplate.Parameter(com.typewritermc.types.ParameterKey(parameterOwner, 0))
        val concrete = com.typewritermc.types.TypeTemplate.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32))
        val bindings = mapOf(parent to generic, candidate to concrete)
        com.typewritermc.presentation.checkPresentationExpression(read(candidate), bindings, concrete, setOf(candidate), catalog::resolve) shouldBe emptyList()
        com.typewritermc.presentation.checkPresentationExpression(call("typewriter.text.trim", read(candidate)), bindings, concrete, setOf(candidate), catalog::resolve).isNotEmpty() shouldBe true
    }
    test("operation descriptors preserve unsigned widths and missing availability") {
        val unsigned = TypeUse.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.UNSIGNED_64))
        val inputs = listOf(ExpressionType(unsigned, false), ExpressionType(unsigned, true), ExpressionType(text, false))
        SharedOperationSignatures.resolveOrNull(OperationId("typewriter.number.round_to"), inputs)?.result shouldBe ExpressionType(unsigned, true)
        SharedOperationSignatures.resolveOrNull(OperationId("typewriter.number.round_to"), listOf(ExpressionType(floating, false), ExpressionType(decimal, false), ExpressionType(text, false))) shouldBe null
    }
    test("completion preserves decimal candidate family") {
        checker.checkExpressionCodes(
            call("typewriter.number.round_to", read(candidate), ExpressionNode.Literal(DataValue.Decimal("0.01")), ExpressionNode.Literal(DataValue.StringValue("NearestTiesToEven"))),
            mapOf(candidate to ExpressionType(decimal, false)), ExpressionType(decimal, false),
        ) shouldBe emptyList()
    }
    test("completion preserves narrow floating candidate family") {
        checker.checkExpressionCodes(
            call("typewriter.number.round_to", read(candidate), ExpressionNode.Literal(DataValue.Float(0.5)), ExpressionNode.Literal(DataValue.StringValue("Floor"))),
            mapOf(candidate to ExpressionType(floating, false)), ExpressionType(floating, false),
        ) shouldBe emptyList()
    }
    test("floating candidates reject decimal increments") {
        checker.checkExpressionCodes(
            call("typewriter.number.round_to", read(candidate), ExpressionNode.Literal(DataValue.Decimal("0.5")), ExpressionNode.Literal(DataValue.StringValue("Floor"))),
            mapOf(candidate to ExpressionType(floating, false)), ExpressionType(floating, false),
        ).isNotEmpty() shouldBe true
    }
    test("completion cannot implicitly narrow another declared source width") {
        val wide = TypeUse.Scalar(ScalarKind.Float(FloatWidth.FLOAT_64))
        checker.checkExpressionCodes(read(parent), mapOf(parent to ExpressionType(wide, false)), ExpressionType(floating, false)).isNotEmpty() shouldBe true
    }
    test("completion requires parent absence to be handled explicitly") {
        val bindings = mapOf(candidate to ExpressionType(text, false), parent to ExpressionType(text, true))
        checker.checkExpressionCodes(read(parent), bindings, ExpressionType(text, false)).contains("expression_result_may_be_missing") shouldBe true
        checker.checkExpressionCodes(ExpressionNode.OrElse(read(parent), read(candidate)), bindings, ExpressionType(text, false)) shouldBe emptyList()
    }
    test("unknown local candidate aliases cannot escape their scope") {
        checker.checkExpressionCodes(read(candidate), emptyMap(), ExpressionType(text, false)).isNotEmpty() shouldBe true
    }
    test("duration display uses the shared text operation contract") {
        checker.checkExpressionCodes(
            call("typewriter.duration.format", read(candidate), ExpressionNode.Literal(DataValue.StringValue("MinutesAndSeconds")), ExpressionNode.Literal(DataValue.Integer(java.math.BigInteger.ZERO))),
            mapOf(candidate to ExpressionType(TypeUse.Scalar(ScalarKind.Duration), false)), ExpressionType(text, false),
        ) shouldBe emptyList()
    }
}
