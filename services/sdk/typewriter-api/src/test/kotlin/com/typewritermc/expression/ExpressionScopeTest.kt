package com.typewritermc.expression

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.root
import com.typewritermc.types.listValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ValuePath

val ExpressionScopeTest by testSuite {
    test("a nested lambda that uses an outer item computes with that item") {
        val rows = input<List<Int>>(ExpressionBindingId(value = "rows"))
        val others = input<List<Int>>(ExpressionBindingId(value = "others"))
        val expression =
            rows.map {
                val outer = this
                others.map { this + outer }
            }

        (
            expression.evaluate(
                "rows" to integerList(1, 2),
                "others" to integerList(10, 20),
            ) as Availability.Available
        ).value.integers() shouldBe
            listOf(listOf(11, 21), listOf(12, 22))
    }

    test("a captured builder reused inside another lambda still reads the item it captured") {
        val rows = input<List<Int>>(ExpressionBindingId(value = "rows"))
        val others = input<List<Int>>(ExpressionBindingId(value = "others"))
        val expression =
            rows.map {
                val outer = this
                val nested = others.map { outer }
                others.map { nested }
            }

        (expression.evaluate("rows" to integerList(1, 2), "others" to integerList(7)) as Availability.Available).value.integers() shouldBe
            listOf(listOf(listOf(1)), listOf(listOf(2)))
    }

    test("a local used outside its authoring callback is refused") {
        lateinit var escaped: Expr<Int, MayBeMissing>
        input<List<Int>>(ExpressionBindingId(value = "rows")).map {
            escaped = this
            this
        }

        shouldThrow<IllegalArgumentException> { escaped.toNode() }.message shouldBe "A local expression escaped its declaring lambda"
    }

    test("a raw local node cannot be inserted as an expression") {
        val local = ExpressionNode.createLocal(depth = 0, slot = 0, path = ValuePath.root)

        shouldThrow<IllegalArgumentException> { portableExpression<Int>(local) }.message shouldBe "invalid_expression_local"
    }

    test("literal builders capture caller supplied collections before lowering") {
        val items = mutableListOf(ListItem(id = ItemId(value = "first"), value = DataValue.StringValueWrapper("first")))
        val literal = portableLiteral<List<String>>(DataValue.listValue(items))
        val before = literal.toNode()
        items += ListItem(id = ItemId(value = "second"), value = DataValue.StringValueWrapper("second"))
        literal.toNode() shouldBe before
    }
}
