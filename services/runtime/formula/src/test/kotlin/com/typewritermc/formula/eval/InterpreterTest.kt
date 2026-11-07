package com.typewritermc.formula.eval

import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.testing.EvaluationWorld
import com.typewritermc.formula.testing.boolean
import com.typewritermc.formula.testing.double
import com.typewritermc.formula.testing.failure
import com.typewritermc.formula.testing.int
import com.typewritermc.formula.testing.listType
import com.typewritermc.formula.testing.nullable
import com.typewritermc.formula.testing.onSmallStack
import com.typewritermc.formula.testing.rewardUse
import com.typewritermc.formula.testing.run
import com.typewritermc.formula.testing.setType
import com.typewritermc.formula.testing.string
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val InterpreterTest by testSuite {
    for ((source, expected, value) in listOf(
        Triple("1 + 2 * 3", int, 7),
        Triple("\"Total: \${1 + 2}\"", string, "Total: 3"),
        Triple("let x = 2\nlet x = x + 1\nx", int, 3),
        Triple("let double(x: Int) = x * 2\ndouble(4)", int, 8),
        Triple("let fact(n: Int): Int = n < 2 ? 1 : n * fact(n - 1)\nfact(5)", int, 120),
        Triple("[1, 2, 3].map { it * 2 }.sumOf { it }", int, 12),
        Triple("[1, 2].filter { it > 1 }", listType(int), listOf(2)),
        Triple("[\"a\": 1][\"a\"]", nullable(int), 1),
        Triple("[\"a\": 1][\"b\"]", nullable(int), null),
        Triple("null ?: 3", int, 3),
        Triple("0 < 1 < 2", boolean, true),
        Triple("0 < 3 < 2", boolean, false),
        Triple("if (true) 1 else 2", int, 1),
        Triple("when (door) { is Open -> 1\n is Closed -> 2 }", int, 1),
        Triple("when (money) { is Money(amount) if amount > 100 -> 1\n else -> 2 }", int, 2),
        Triple("Reward(gold = 5).gold", int, 5),
        Triple("5 in 1..9", boolean, true),
        Triple("\"a\" == \"a\"", boolean, true),
        Triple("Reward(gold = 5) == Reward(gold = 5)", boolean, true),
    )) {
        test("$source evaluates to $value") { run(source, expected) shouldBe Evaluation.Value(value) }
    }

    test("an Int overflow fails with Overflow") { run("2147483647 + 1", int).failure shouldBe FormulaFailure.Overflow }

    test("division by zero fails with DivisionByZero") { run("1 / 0", int).failure shouldBe FormulaFailure.DivisionByZero }

    test("division by zero inside a lambda a provider calls still fails with DivisionByZero") {
        run("[1].map { it / 0 }", listType(int)).failure shouldBe FormulaFailure.DivisionByZero
    }

    test("a non finite result fails with NotFinite") { run("1.0 / 0.0", double).failure shouldBe FormulaFailure.NotFinite }

    test("a provider that throws fails with its message") {
        run("explode()", int).failure shouldBe FormulaFailure.ProviderThrew("The provider broke.")
    }

    test("endless recursion fails with RecursionLimit, not a stack overflow") {
        run("let f(n: Int): Int = f(n)\nf(1)", int).failure shouldBe FormulaFailure.RecursionLimit
    }

    test("a very long computation stops at the step limit") {
        run("(1..1000).sumOf { a -> (1..1000).sumOf { b -> 1 } }", int).failure shouldBe FormulaFailure.StepLimit
    }

    test("a range larger than the step limit fails with StepLimit before it is built") {
        run("(1..2000000000).size", int).failure shouldBe FormulaFailure.StepLimit
    }

    test("a lambda sees the bindings around it when it was written") {
        run("let k = 10\nlet add = { x: Int -> x + k }\nlet k = 20\nadd(1)", int) shouldBe Evaluation.Value(11)
    }

    test("?. stops at null, and ?: only then runs its right side") {
        run("maybe?.plus(explode()) ?: 7", int) shouldBe Evaluation.Value(7)
        run("some ?: explode()", int) shouldBe Evaluation.Value(4)
    }

    test("`and` does not run its right side when the left is false") {
        run("false and explode() > 0", boolean) shouldBe Evaluation.Value(false)
    }

    test("a Kotlin enum case reaches a provider as its constant") { run("winter.isCold()", boolean) shouldBe Evaluation.Value(true) }

    test("a provider over a Ref receives a Ref") { run("smith.targetId()", string) shouldBe Evaluation.Value("smith") }

    test("a provider over a list of references receives Refs, and a lambda it calls reads each one's field") {
        run("[smith, anvil].eachRef { it.name }", listType(string)) shouldBe Evaluation.Value(listOf("Old Smith", "Anvil"))
    }

    test("a provider over a list of code records receives instances built by a formula") {
        run("[Reward(gold = 2), Reward(gold = 3)].totalGold()", int) shouldBe Evaluation.Value(5)
    }

    test("a code record's list of references reads through a lambda as references") {
        run("crew.members.map { it.mood }", listType(int)) shouldBe Evaluation.Value(listOf(3, 2))
    }

    test("a generic provider over List<T> receives each item at its concrete type") {
        run("[Gold(amount = 1)].kinds()", listType(string)) shouldBe Evaluation.Value(listOf("Gold"))
        run("[1].kinds()", listType(string)) shouldBe Evaluation.Value(listOf("Int"))
    }

    test("a user function recursing 256 deep runs on any caller's stack") {
        onSmallStack { run("let down(n: Int): Int = n == 0 ? 0 : 1 + down(n - 1)\ndown(250)", int) } shouldBe Evaluation.Value(250)
    }

    test("a Deferred sibling of a converted field is never resolved") {
        val nothingDeferred = EvaluationWorld(deferred = emptyMap())
        run("wrap(smith.name).x", string, nothingDeferred) shouldBe Evaluation.Value("Old Smith")
    }

    test("a provider over a code record holding a Var receives that record, with each Var as a Var.Value of its evaluated value") {
        run("calm.levelOf()", int) shouldBe Evaluation.Value(4)
    }

    test("a code record a provider returns equals the same record built by a formula constructor") {
        run("reward(5) == Reward(gold = 5)", boolean) shouldBe Evaluation.Value(true)
    }

    test("fun <T> Box<T>.get(): T over a Box of Gold gives a Gold equal to a stored Gold, and a field read on it works") {
        run("wrap(storedGold).get() == storedGold", boolean) shouldBe Evaluation.Value(true)
        run("wrap(storedGold).get().amount", int) shouldBe Evaluation.Value(5)
    }

    test("a content record built through an alias equals the same record read from storage") {
        run("Prize(gold = 5) == storedPrize", boolean) shouldBe Evaluation.Value(true)
    }

    test("a lambda a provider returns unchanged is called as the formula's own") {
        run("let add = pass { x: Int -> x + 1 }\nadd(2)", int) shouldBe Evaluation.Value(3)
    }

    test(
        "fun <T> wrap(x: T): Box<T> called with a content record gives back a Box whose x equals that record, and called with a Gold gives back the same Gold",
    ) {
        run("wrap(storedPrize).x == storedPrize", boolean) shouldBe Evaluation.Value(true)
        run("wrap(storedGold).x == storedGold", boolean) shouldBe Evaluation.Value(true)
    }

    test("a provider that swallows a lambda's failure with runCatching still fails with that failure") {
        run("swallow { 1 / 0 }", int).failure shouldBe FormulaFailure.DivisionByZero
    }

    test("a string template shows a record with its fields as Reward(gold = 5, chest = false)") {
        run("\"\${Reward(gold = 5)}\"", string) shouldBe Evaluation.Value("Reward(gold = 5, chest = false)")
    }

    test("a stored record and the same record built by a formula are one item after distinct()") {
        run("[storedReward, Reward(gold = 5)].distinct().size", int) shouldBe Evaluation.Value(1)
    }

    test(
        "a code record constructor whose init check fails gives that message, and one that omits a defaulted field takes its Kotlin default",
    ) {
        run("Reward(gold = -1)", rewardUse).failure shouldBe FormulaFailure.ProviderThrew("A reward cannot take gold.")
        run("Reward(gold = 5).chest", boolean) shouldBe Evaluation.Value(false)
    }

    test("a fieldless object case read from storage equals the one a provider returns") {
        run("free() == storedFree", boolean) shouldBe Evaluation.Value(true)
    }

    test("a string template shows 1.0 as 1, a Duration, null, a list and a Ref exactly as a rule template shows them") {
        run("\"\${1.0} \${wait} \${maybe} \${[1, 2]} \${smith}\"", string) shouldBe Evaluation.Value("1 PT1M30S null [1, 2] smith")
    }

    test("a lambda a provider calls recursing past depth 256 fails with RecursionLimit") {
        run("let f(n: Int): Int = withZero { f(n + 1) }\nf(0)", int).failure shouldBe FormulaFailure.RecursionLimit
    }

    test("a provider over Set<T> receives a Set, and a set it returns reads as a set") {
        run("tags.again()", setType(int)) shouldBe Evaluation.Value(setOf(1, 2))
    }

    test("a provider that returns a record holding an unevaluated formula fails with its message") {
        run("brokenMood().levelOf()", int).failure shouldBe
            FormulaFailure.ProviderThrew("A provider returned a formula where a value was expected.")
    }
}
