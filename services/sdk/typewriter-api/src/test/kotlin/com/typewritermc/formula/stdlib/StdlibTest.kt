package com.typewritermc.formula.stdlib

import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFailureException
import com.typewritermc.formula.callFormula
import com.typewritermc.formula.formulaFunctions
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe

val StdlibTest by testSuite {
    test("Int overflow fails instead of wrapping") { shouldThrow<ArithmeticException> { callFormula("plus", Int.MAX_VALUE, 1) } }
    test("Long overflow fails instead of wrapping") { shouldThrow<ArithmeticException> { callFormula("times", Long.MAX_VALUE, 2L) } }
    test("division by zero fails") { shouldThrow<ArithmeticException> { callFormula("div", 1, 0) } }
    test("a Double result that is not finite fails") {
        shouldThrow<FormulaFailureException> { callFormula("div", 1.0, 0.0) }.reason shouldBe FormulaFailure.NotFinite
    }
    test("toInt fails when the value does not fit") { shouldThrow<ArithmeticException> { callFormula("toInt", Long.MAX_VALUE) } }
    test("sumOf fails on overflow instead of wrapping") {
        shouldThrow<ArithmeticException> { callFormula("sumOf", listOf(Int.MAX_VALUE, 1), { item: Any? -> item }) }
    }
    test("map and filter keep the order of the list") {
        callFormula("map", listOf(1, 2, 3), { item: Any? -> (item as Int) * 10 }) shouldBe listOf(10, 20, 30)
        callFormula("filter", listOf(3, 1, 2), { item: Any? -> (item as Int) > 1 }) shouldBe listOf(3, 2)
    }
    test("a set and a map answer whether they hold an item or key") {
        callFormula("contains", setOf("a", "b"), "b") shouldBe true
        callFormula("contains", setOf("a"), "c") shouldBe false
        callFormula("contains", mapOf("sword" to 50), "sword") shouldBe true
        callFormula("contains", mapOf("sword" to 50), 50) shouldBe false
    }
    test(
        "distinct keeps the first of each equal item, in order",
    ) { callFormula("distinct", listOf(2, 1, 2, 3, 1)) shouldBe listOf(2, 1, 3) }
    test("String length counts code points, like portable text") { callFormula("length", "😀a") shouldBe 2 }
    test("substring counts code points, like portable text") { callFormula("substring", "😀ab", 1, 2) shouldBe "a" }
    test("a template joins its parts") { callFormula("template", listOf("Total: ", "3")) shouldBe "Total: 3" }
    test("the provider index lists the stdlib, and it loads") {
        formulaFunctions.map { it.name } shouldContainAll listOf("plus", "minus", "sumOf", "filter", "map", "template")
    }
}
