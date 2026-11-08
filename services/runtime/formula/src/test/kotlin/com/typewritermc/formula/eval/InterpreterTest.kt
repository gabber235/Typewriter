package com.typewritermc.formula.eval

import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.testing.EvaluationWorld
import com.typewritermc.formula.testing.boolean
import com.typewritermc.formula.testing.decimal
import com.typewritermc.formula.testing.double
import com.typewritermc.formula.testing.failure
import com.typewritermc.formula.testing.float
import com.typewritermc.formula.testing.int
import com.typewritermc.formula.testing.listType
import com.typewritermc.formula.testing.long
import com.typewritermc.formula.testing.nullable
import com.typewritermc.formula.testing.onSmallStack
import com.typewritermc.formula.testing.rewardUse
import com.typewritermc.formula.testing.run
import com.typewritermc.formula.testing.setType
import com.typewritermc.formula.testing.string
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.math.BigDecimal

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
        Triple("5 in 0..2_000_000", boolean, true),
        Triple("10 in 0..9", boolean, false),
        Triple("(1..4).toList()", listType(int), listOf(1, 2, 3, 4)),
        Triple("(3..2).toList()", listType(int), emptyList<Int>()),
        Triple("(1..0).isEmpty()", boolean, true),
        Triple("2 in 3..1", boolean, false),
        Triple("(5..2).first + (5..2).last", int, 7),
        Triple("(1..5).map { it * 2 } == [2, 4, 6, 8, 10]", boolean, true),
        Triple("(1..5).filter { it > 3 }", listType(int), listOf(4, 5)),
        Triple("(1..4).fold(0) { total, item -> total + item }", int, 10),
        Triple("let r: IntRange = 1..3\n2 in r", boolean, true),
        Triple("1..3 == 1..3", boolean, true),
        Triple("1..3 == 1..4", boolean, false),
        Triple("\"\${1..3}\"", string, "1..3"),
        Triple("when (7) { in 0..9 -> \"Novice\"\n else -> \"Hero\" }", string, "Novice"),
        Triple("when (42) { in 0..9 -> \"Novice\"\n else -> \"Hero\" }", string, "Hero"),
        Triple("[0..2_000_000_000: \"all\"][0..2_000_000_000]", nullable(string), "all"),
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

    test("a range costs no steps until it is walked, and walking it costs a step per item") {
        val small = EvaluationLimits(maxSteps = 100)
        run("5 in 0..2_000_000", boolean, limits = small) shouldBe Evaluation.Value(true)
        run("(1..1000).count { true }", int, limits = small).failure shouldBe FormulaFailure.StepLimit
        run("(1..1000).map { it }", listType(int), limits = small).failure shouldBe FormulaFailure.StepLimit
    }

    test("a range longer than the steps left fails with StepLimit before its list is built") {
        run("(1..2000000000).toList()", listType(int)).failure shouldBe FormulaFailure.StepLimit
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

    test("a provider typed with a code record receives that record when given a value through an alias of it") {
        run("bonusOf(storedBounty) + [storedBounty].totalGold() + storedChest.get().gold", int) shouldBe Evaluation.Value(22)
    }

    test("each Var in a list is worked out when read, also a Var inside a record inside a list") {
        run("tallies.sumOf { it.counts.sumOf { c -> c } }", int) shouldBe Evaluation.Value(10)
        run("scores.sumOf { it }", int) shouldBe Evaluation.Value(3)
        run("scores == [1, 2]", boolean) shouldBe Evaluation.Value(true)
        run("\"\${scores}\"", string) shouldBe Evaluation.Value("[1, 2]")
    }

    test("a Var holding a list, inside a list, is worked out before its items are read") {
        run("rounds.map { r -> r.sumOf { x -> x } }", listType(int)) shouldBe Evaluation.Value(listOf(5, 0))
        val nested = run("tallies.map { it.rounds.map { r -> r.sumOf { x -> x } } }", listType(listType(int)))
        nested shouldBe Evaluation.Value(listOf(listOf(5), emptyList()))
    }

    test("a list with one failing Var fails with that Var's failure when its items are read") {
        run("brokenScores.sumOf { it }", int).failure shouldBe FormulaFailure.DivisionByZero
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

    test("a Float literal is the Float a stored value of that number is, in ==, is, a record and a provider call") {
        run("storedMeasure.ratio == 0.5", boolean) shouldBe Evaluation.Value(true)
        run("let r: Float = 0.5\nr is Float", boolean) shouldBe Evaluation.Value(true)
        run("Measure(ratio = 0.5) == storedMeasure", boolean) shouldBe Evaluation.Value(true)
        run("half(0.5)", float) shouldBe Evaluation.Value(0.25f)
    }

    test("a Decimal literal keeps the digits and scale it is written with, as a stored Decimal does") {
        run("price == 1.10", boolean) shouldBe Evaluation.Value(true)
        run("12345678901234567890.123456789", decimal) shouldBe Evaluation.Value(BigDecimal("12345678901234567890.123456789"))
    }

    test("a Long literal beyond 2^53 keeps every digit") {
        run("9007199254740993", long) shouldBe Evaluation.Value(9_007_199_254_740_993L)
    }

    test("Double == and < follow IEEE 754, so -0.0 equals 0.0 and is not below it") {
        run("let x = 0.0\n-x == 0.0", boolean) shouldBe Evaluation.Value(true)
        run("let x = 0.0\n-x < 0.0", boolean) shouldBe Evaluation.Value(false)
        run("let x = 0.0\n-x >= 0.0", boolean) shouldBe Evaluation.Value(true)
    }

    test("a range longer than the default step limit is built when the evaluation's own limit allows it") {
        run("(1..1500000).toList().size", int, limits = EvaluationLimits(maxSteps = 2_000_000)) shouldBe Evaluation.Value(1_500_000)
    }
}
