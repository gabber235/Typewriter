package com.typewritermc.expression

import com.typewritermc.authoring.root
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.integerScalar
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.NumberArithmeticOperation
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath

val CanonicalExpressionTypeTest by testSuite {
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "canonical expressions"), StandardTypes.definitions)
    val checker = PortableExpressionChecker(catalog::resolve)
    val text = ScalarKind.TEXT.use
    val wide = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use
    val narrow = integerScalar(IntegerWidth.SIGNED_EIGHT).use
    val rows = ExpressionBindingId(value = "rows")

    test("grouped literal keys retain their numeric evidence inside structural map children") {
        val expression = input<List<String>>(rows).groupBy { literal(1) }.toNode()
        val expected = StandardTypes.map.use(listOf(narrow, StandardTypes.list.use(listOf(text))))
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(StandardTypes.list.use(listOf(text)))),
            nominalExpressionType(expected),
        ) shouldBe emptyList()
    }

    test("a bound numeric collection item cannot masquerade as a narrow literal") {
        val expression = input<List<Long>>(rows).map { this }.toNode()
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(StandardTypes.list.use(listOf(wide)))),
            nominalExpressionType(StandardTypes.list.use(listOf(narrow))),
        ) shouldBe
            listOf("incompatible_expression_result_type")
    }

    test("map access returns values while contains accepts keys for a declared mapping alias") {
        val aliasId = TypeDefinitionId.qualified("canonical", "TextToInteger")
        val alias =
            TypeDefinition.partial(
                id = aliasId,
                representation =
                    RepresentationTemplate.createMapping(
                        key = ScalarKind.TEXT.template,
                        value = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).template,
                    ),
            )
        val aliases = DefaultCheckedCatalog(CatalogGeneration(value = "mapping alias"), StandardTypes.definitions + alias)
        val aliasChecker = PortableExpressionChecker(aliases::resolve)
        val source = input<Any?>(rows).toNode()
        val bindings = mapOf(rows to nominalExpressionType(aliasId.use()))
        val access = ExpressionNode.createCollectionAccess(source = source, index = literal("key").toNode())
        aliasChecker.checkExpressionCodes(access, bindings, nominalExpressionType(wide, true)) shouldBe emptyList()
        val contains = ExpressionNode.createCollectionContains(source = source, value = literal("key").toNode())
        aliasChecker.checkExpressionCodes(contains, bindings, nominalExpressionType(ScalarKind.BOOLEAN.use)) shouldBe
            emptyList()
    }

    test("a literal fold seed takes the declared accumulator width without narrowing bound inputs") {
        val count = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
        val expression = input<List<Int>>(rows).fold(literal(0)) { total, item -> total + item }.toNode()
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(StandardTypes.list.use(listOf(count)))),
            nominalExpressionType(count),
        ) shouldBe emptyList()
    }

    test("find and reduce represent empty results as nullable values rather than missing input") {
        val source = input<List<String>>(rows).toNode()
        val bindings = mapOf(rows to nominalExpressionType(StandardTypes.list.use(listOf(text))))
        val find = ExpressionNode.createFind(source = source, body = literal(true).toNode())
        val local = ExpressionNode.createLocal(depth = 0, slot = 0, path = ValuePath.root)
        val reduce = ExpressionNode.createReduce(source = source, body = local)
        listOf(find, reduce).forEach { node ->
            checker.checkExpressionCodes(node, bindings, nominalExpressionType(text.nullable())) shouldBe emptyList()
            checker.checkExpressionCodes(node, bindings, nominalExpressionType(text)) shouldBe listOf("incompatible_expression_result_type")
        }
    }

    test("item paths through nullable derived lists remain possibly missing") {
        val path =
            ValuePath(
                segments =
                    listOf(
                        PathSegment.createItem(
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
                path = ValuePath(segments = listOf(PathSegment.UNKNOWN)),
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
        val outside = ExpressionNode.createLocal(depth = -1, slot = 0, path = ValuePath.root)
        checker.checkExpressionStructure(outside, emptySet()) shouldBe listOf("invalid_expression_local")
    }
}
