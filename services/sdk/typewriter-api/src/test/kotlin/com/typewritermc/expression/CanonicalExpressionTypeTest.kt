package com.typewritermc.expression

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.NumberArithmeticOperation
import skirout.editor.v1.type_catalog.ValuePath

val CanonicalExpressionTypeTest by testSuite {
    val catalog = DefaultCheckedCatalog(CatalogGeneration("canonical expressions"), StandardTypes.definitions)
    val checker = PortableExpressionChecker(catalog::resolve)
    val text = TypeUse.Scalar(ScalarKind.Text)
    val wide = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_64))
    val narrow = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_8))
    val rows = ExpressionBindingId("rows")

    test("grouped literal keys retain their numeric evidence inside structural map children") {
        val expression = input<List<String>>(rows).groupBy { literal(1) }.toNode()
        val expected = TypeUse.Named(StandardTypes.map, listOf(narrow, TypeUse.Named(StandardTypes.list, listOf(text))))
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(TypeUse.Named(StandardTypes.list, listOf(text)))),
            nominalExpressionType(expected),
        ) shouldBe emptyList()
    }

    test("a bound numeric collection item cannot masquerade as a narrow literal") {
        val expression = input<List<Long>>(rows).map { this }.toNode()
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(TypeUse.Named(StandardTypes.list, listOf(wide)))),
            nominalExpressionType(TypeUse.Named(StandardTypes.list, listOf(narrow))),
        ) shouldBe
            listOf("incompatible_expression_result_type")
    }

    test("map access returns values while contains accepts keys for a declared mapping alias") {
        val aliasId = TypeDefinitionId(TypeId.Qualified("canonical", "TextToInteger"), 1)
        val alias =
            TypeDefinition(
                aliasId,
                representation =
                    RepresentationTemplate.Mapping(
                        TypeTemplate.Scalar(ScalarKind.Text),
                        TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_64)),
                    ),
            )
        val aliases = DefaultCheckedCatalog(CatalogGeneration("mapping alias"), StandardTypes.definitions + alias)
        val aliasChecker = PortableExpressionChecker(aliases::resolve)
        val source = input<Any?>(rows).toNode()
        val bindings = mapOf(rows to nominalExpressionType(TypeUse.Named(aliasId)))
        val access = ExpressionNode.createCollectionAccess(source = source, index = literal("key").toNode())
        aliasChecker.checkExpressionCodes(access, bindings, nominalExpressionType(wide, true)) shouldBe emptyList()
        val contains = ExpressionNode.createCollectionContains(source = source, value = literal("key").toNode())
        aliasChecker.checkExpressionCodes(contains, bindings, nominalExpressionType(TypeUse.Scalar(ScalarKind.Boolean))) shouldBe
            emptyList()
    }

    test("a literal fold seed takes the declared accumulator width without narrowing bound inputs") {
        val count = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
        val expression = input<List<Int>>(rows).fold(literal(0)) { total, item -> total + item }.toNode()
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(TypeUse.Named(StandardTypes.list, listOf(count)))),
            nominalExpressionType(count),
        ) shouldBe emptyList()
    }

    test("find and reduce represent empty results as nullable values rather than missing input") {
        val source = input<List<String>>(rows).toNode()
        val bindings = mapOf(rows to nominalExpressionType(TypeUse.Named(StandardTypes.list, listOf(text))))
        val find = ExpressionNode.createFind(source = source, body = literal(true).toNode())
        val local = ExpressionNode.createLocal(depth = 0, slot = 0, path = ValuePath(segments = emptyList()))
        val reduce = ExpressionNode.createReduce(source = source, body = local)
        listOf(find, reduce).forEach { node ->
            checker.checkExpressionCodes(node, bindings, nominalExpressionType(TypeUse.Nullable(text))) shouldBe emptyList()
            checker.checkExpressionCodes(node, bindings, nominalExpressionType(text)) shouldBe listOf("incompatible_expression_result_type")
        }
    }

    test("item paths through nullable derived lists remain possibly missing") {
        val path =
            ValuePath(
                segments =
                    listOf(
                        skirout.editor.v1.type_catalog.PathSegment
                            .createItem(
                                id =
                                    skirout.editor.v1.type_catalog
                                        .ItemId(value = "missing"),
                            ),
                    ),
            )
        val read =
            ExpressionNode.createInput(
                binding =
                    skirout.editor.v1.type_catalog
                        .ExpressionBindingId(value = rows.value),
                path = path,
            )
        val optional =
            skirout.editor.v1.expression.ExpressionType(
                value =
                    skirout.editor.v1.expression.ExpressionValueType
                        .NullableWrapper(listExpressionType(nominalExpressionType(text))),
                mayBeMissing = false,
            )
        checker.checkExpressionCodes(read, mapOf(rows to optional), nominalExpressionType(text, true)) shouldBe emptyList()
        checker.checkExpressionCodes(
            read,
            mapOf(rows to listExpressionType(nominalExpressionType(text))),
            nominalExpressionType(text),
        ) shouldBe
            listOf("expression_result_may_be_missing")
    }

    test("unknown wire path segments produce a checking diagnostic") {
        val read =
            ExpressionNode.createInput(
                binding =
                    skirout.editor.v1.type_catalog
                        .ExpressionBindingId(value = rows.value),
                path = ValuePath(segments = listOf(skirout.editor.v1.type_catalog.PathSegment.UNKNOWN)),
            )
        checker.checkExpressionCodes(
            read,
            mapOf(rows to listExpressionType(nominalExpressionType(text))),
            nominalExpressionType(text, true),
        ) shouldBe
            listOf("invalid_expression_path")
    }

    test("unknown operation enums reject during structural checking") {
        val unknown =
            ExpressionNode.createNumberArithmetic(
                operation = NumberArithmeticOperation.UNKNOWN,
                first = literal(1).toNode(),
                second = literal(2).toNode(),
                remaining = emptyList(),
            )
        checker.checkExpressionStructure(unknown, emptySet()) shouldBe listOf("unknown_expression_operation")
        checker.checkExpressionStructure(ExpressionNode.UNKNOWN, emptySet()) shouldBe listOf("unknown_expression")
        val outside = ExpressionNode.createLocal(depth = -1, slot = 0, path = ValuePath(segments = emptyList()))
        checker.checkExpressionStructure(outside, emptySet()) shouldBe listOf("invalid_expression_local")
    }
}
