package com.typewritermc.expression

import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.expression.operations.CheckFailure
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.ExpressionValueType
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import java.math.BigInteger

val CanonicalExpressionTypeTest by testSuite {
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "canonical expressions"), StandardTypes.definitions)
    val checker = PortableExpressionChecker(catalog::resolve)
    val text = ScalarKind.TEXT.use
    val wide = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use
    val narrow = integerScalar(IntegerWidth.SIGNED_EIGHT).use
    val count = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
    val rows = ExpressionBindingId(value = "rows")
    val source = checkInput(rows)

    fun listType(item: TypeUse) = StandardTypes.list.use(listOf(item))

    fun integerLiteral(value: Long) = checkLiteral(DataValue.integer(BigInteger.valueOf(value)))

    test("grouped literal keys keep their numeric evidence inside structural map children") {
        val expression = checkCall("collection.group_by", source, checkLambda(1, integerLiteral(1)))
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(listType(text))),
            nominalExpressionType(StandardTypes.map.use(listOf(narrow, listType(text)))),
        ) shouldBe emptyList()
    }

    test("a bound numeric item cannot masquerade as a narrow literal") {
        val expression = checkCall("collection.map", source, checkLambda(1, checkLocal(0)))
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(listType(wide))),
            nominalExpressionType(listType(narrow)),
        ) shouldBe listOf(CheckFailure.IncompatibleExpressionResultType)
    }

    test("a declared mapping alias reads values by key") {
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
        val bindings = mapOf(rows to nominalExpressionType(aliasId.use()))
        val key = checkLiteral(DataValue.StringValueWrapper("key"))
        aliasChecker.checkExpressionCodes(checkCall("map.get", source, key), bindings, nominalExpressionType(wide, true)) shouldBe
            emptyList()
        aliasChecker.checkExpressionCodes(
            checkCall("map.contains_key", source, key),
            bindings,
            nominalExpressionType(ScalarKind.BOOLEAN.use),
        ) shouldBe emptyList()
        aliasChecker.checkExpressionCodes(
            checkCall("map.contains_key", source, integerLiteral(1)),
            bindings,
            nominalExpressionType(ScalarKind.BOOLEAN.use),
        ) shouldBe listOf(CheckFailure.InvalidOperandType)
    }

    test("a literal fold seed takes the accumulator width of the step without narrowing bound inputs") {
        val step = checkLambda(2, checkCall("number.add", checkLocal(0), checkLocal(1)))
        val expression = checkCall("collection.fold", source, integerLiteral(0), step)
        checker.checkExpressionCodes(
            expression,
            mapOf(rows to nominalExpressionType(listType(count))),
            nominalExpressionType(count),
        ) shouldBe emptyList()
    }

    test("an item read by index may be missing") {
        val bindings = mapOf(rows to nominalExpressionType(listType(text)))
        val first = checkCall("list.at", source, integerLiteral(0))
        checker.checkExpressionCodes(first, bindings, nominalExpressionType(text, true)) shouldBe emptyList()
        checker.checkExpressionCodes(first, bindings, nominalExpressionType(text)) shouldBe
            listOf(CheckFailure.ExpressionResultMayBeMissing)
    }

    test("an each lambda sees the item type and a comparator returns an integer") {
        val bindings = mapOf(rows to nominalExpressionType(listType(text)))
        val isA = checkCall("value.equals", checkLocal(0), checkLiteral(DataValue.StringValueWrapper("a")))
        val kept = checkCall("collection.filter", source, checkLambda(1, isA))
        checker.checkExpressionCodes(kept, bindings, nominalExpressionType(listType(text))) shouldBe emptyList()
        val lengths = checkCall("collection.map", source, checkLambda(1, checkCall("text.length", checkLocal(0))))
        checker.checkExpressionCodes(lengths, bindings, nominalExpressionType(listType(count))) shouldBe emptyList()
        val ordered = checkCall("collection.sort_with", source, checkLambda(2, checkCall("value.compare", checkLocal(0), checkLocal(1))))
        checker.checkExpressionCodes(ordered, bindings, nominalExpressionType(listType(text))) shouldBe emptyList()
        val unordered = checkCall("collection.sort_with", source, checkLambda(2, checkLocal(0)))
        checker.checkExpressionCodes(unordered, bindings, nominalExpressionType(listType(text))) shouldBe
            listOf(CheckFailure.InvalidOperandType)
    }

    test("an item path through a nullable derived list may be missing") {
        val read = checkInput(rows, ValuePath(segments = listOf(PathSegment.createItem(id = ItemId(value = "missing")))))
        val optional =
            ExpressionType(
                value = ExpressionValueType.NullableWrapper(listExpressionType(nominalExpressionType(text))),
                mayBeMissing = false,
            )
        checker.checkExpressionCodes(read, mapOf(rows to optional), nominalExpressionType(text, true)) shouldBe emptyList()
        val required = mapOf(rows to listExpressionType(nominalExpressionType(text)))
        checker.checkExpressionCodes(read, required, nominalExpressionType(text)) shouldBe
            listOf(CheckFailure.ExpressionResultMayBeMissing)
    }

    test("an unknown wire path segment is an invalid path") {
        val read = checkInput(rows, ValuePath(segments = listOf(PathSegment.UNKNOWN)))
        val bindings = mapOf(rows to listExpressionType(nominalExpressionType(text)))
        checker.checkExpressionCodes(read, bindings, nominalExpressionType(text, true)) shouldBe
            listOf(CheckFailure.InvalidExpressionPath)
    }

    test("structural checking rejects unknown nodes and locals outside their lambda") {
        checker.checkExpressionStructure(ExpressionNode.UNKNOWN, emptySet()) shouldBe listOf(CheckFailure.UnknownExpression)
        checker.checkExpressionStructure(checkLocal(0, depth = -1), emptySet()) shouldBe
            listOf(CheckFailure.InvalidExpressionLocal)
        checker.checkExpressionStructure(checkLocal(0), emptySet()) shouldBe listOf(CheckFailure.InvalidExpressionLocal)
        checker.checkExpressionStructure(checkCall("collection.map", source, checkLambda(1, checkLocal(1))), setOf(rows)) shouldBe
            listOf(CheckFailure.InvalidExpressionLocal)
    }
}
