package com.typewritermc.expression

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
    test("nested capture lowers against its actual lexical placement without rerunning callbacks") {
        var callbacks = 0
        val rows = input<List<Int>>(ExpressionBindingId(value = "rows"))
        val others = input<List<Int>>(ExpressionBindingId(value = "others"))
        val expression =
            rows.map {
                callbacks += 1
                val outer = this
                others.map {
                    callbacks += 1
                    this + outer
                }
            }
        callbacks shouldBe 2
        val frozen = expression.toNode()
        expression.toNode() shouldBe frozen
        callbacks shouldBe 2
        val outer = frozen as ExpressionNode.MapWrapper
        val inner = outer.value.body as ExpressionNode.MapWrapper
        val addition = inner.value.body as ExpressionNode.NumberArithmeticWrapper
        (addition.value.first as ExpressionNode.LocalWrapper).value.depth shouldBe 0
        (addition.value.second as ExpressionNode.LocalWrapper).value.depth shouldBe 1
    }

    test("reused captured builders resolve their frame at the insertion site") {
        val rows = input<List<Int>>(ExpressionBindingId(value = "rows"))
        val others = input<List<Int>>(ExpressionBindingId(value = "others"))
        val tree =
            rows
                .map {
                    val outer = this
                    val nested = others.map { outer }
                    others.map { nested }
                }.toNode() as ExpressionNode.MapWrapper
        val middle = tree.value.body as ExpressionNode.MapWrapper
        val nested = middle.value.body as ExpressionNode.MapWrapper
        (nested.value.body as ExpressionNode.LocalWrapper).value.depth shouldBe 2
    }

    test("a local cannot escape its authoring callback or bind through raw subtree insertion") {
        lateinit var escaped: Expr<Int, MayBeMissing>
        input<List<Int>>(ExpressionBindingId(value = "rows")).map {
            escaped = this
            this
        }
        shouldThrow<IllegalArgumentException> { escaped.toNode() }
        val local = ExpressionNode.createLocal(depth = 0, slot = 0, path = ValuePath.root)
        shouldThrow<IllegalArgumentException> { portableExpression<Int>(local) }
    }

    test("literal builders capture caller supplied collections before lowering") {
        val items = mutableListOf(ListItem(id = ItemId(value = "first"), value = DataValue.StringValueWrapper("first")))
        val literal = portableLiteral<List<String>>(DataValue.listValue(items))
        val before = literal.toNode()
        items += ListItem(id = ItemId(value = "second"), value = DataValue.StringValueWrapper("second"))
        literal.toNode() shouldBe before
    }
}
