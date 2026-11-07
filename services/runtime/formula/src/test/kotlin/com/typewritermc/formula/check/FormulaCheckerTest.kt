package com.typewritermc.formula.check

import com.typewritermc.formula.testing.EvaluationWorld
import com.typewritermc.formula.testing.awardUse
import com.typewritermc.formula.testing.boolean
import com.typewritermc.formula.testing.check
import com.typewritermc.formula.testing.checkWithEmptied
import com.typewritermc.formula.testing.checkWithTargetsGone
import com.typewritermc.formula.testing.decimal
import com.typewritermc.formula.testing.door
import com.typewritermc.formula.testing.function
import com.typewritermc.formula.testing.int
import com.typewritermc.formula.testing.item
import com.typewritermc.formula.testing.listType
import com.typewritermc.formula.testing.npc
import com.typewritermc.formula.testing.nullable
import com.typewritermc.formula.testing.player
import com.typewritermc.formula.testing.prizeAliasUse
import com.typewritermc.formula.testing.prizeUse
import com.typewritermc.formula.testing.problem
import com.typewritermc.formula.testing.reward
import com.typewritermc.formula.testing.row
import com.typewritermc.formula.testing.shouldAnswer
import com.typewritermc.formula.testing.shown
import com.typewritermc.formula.testing.string
import com.typewritermc.formula.testing.type
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.choice
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.arbitrary.string
import io.kotest.property.checkAll

val FormulaCheckerTest by testSuite {
    // Rows: source, expected type, what the checker must answer.
    for ((source, expected, answer) in listOf(
        row("1 + 2", int, type(int)),
        row("\"a\" + 1", int, problem("formula_type_mismatch", at = 0..7)),
        row("1", decimal, type(decimal)),
        row("let needed = 5 - 2\nneeded", int, type(int)),
        row("let x = 1\nlet x = \"a\"\nx", string, type(string)),
        row("if (flag) 1", int, problem("formula_if_needs_else")),
        row("flag ? 1 : \"a\"", int, problem("formula_type_mismatch")),
        row("maybe ?: 0", int, type(int)),
        row("maybe + 1", int, problem("formula_nullable_read")),
        row("maybe?.plus(1)", nullable(int), type(nullable(int))),
        row("items.map { it + 1 }", listType(int), type(listType(int))),
        row("emptyList()", listType(int), type(listType(int))),
        row("emptyList()", null, problem("formula_cannot_infer")),
        row("bonus(10)", int, type(int)),
        row("bonus(level = 10)", int, type(int)),
        row("bonus(rank = 10)", int, problem("formula_unknown_parameter")),
        row("bonus()", int, problem("formula_missing_argument")),
        row("items.sumOf(bonus)", int, type(int)),
        row("stock.filter(.is_ok)", listType(item), type(listType(item))),
        row("double", int, problem("formula_missing_argument")),
        row("distanceTo(npc)", int, type(int)),
        row("tie(npc)", int, problem("formula_ambiguous_function")),
        row("unknown_thing", int, problem("formula_unknown_name", at = 0..13)),
        row("twin", int, problem("formula_ambiguous_name")),
        row("needsPlayer()", int, problem("formula_context_unfillable")),
        row("{ x -> x }", null, problem("formula_cannot_infer")),
        row("\"Total: \${1 + 2}\"", string, type(string)),
        row("\"Maybe: \${maybe}\"", string, type(string)),
        row("\"Total: \${missing}\"", string, problem("formula_unknown_name")),
        row("let f(n: Int) = f(n)\nf(1)", int, problem("formula_recursive_needs_result")),
        row("let f(n: Int): Int = f(n)\nf(1)", int, type(int)),
        row("Open", door, type(door)),
        row("Open", int, problem("formula_unknown_name")),
        row("0 < 1 < 2", boolean, type(boolean)),
        row("a == 1", boolean, problem("formula_type_mismatch")),
        row("let f(n: Missing) = 1\nf(1)", int, problem("formula_unknown_type")),
        row("let f(xs: List<Int>?, g: (n: Int) -> Int): Int = 1\n1", int, type(int)),
        row("let f(n: Ref<Town>) = n\n1", int, type(int)),
        row("smith.name", string, type(string)),
        row("smith.missing", string, problem("formula_unknown_member")),
        row("Reward(gold = 1)", reward, type(reward)),
        row("Reward()", reward, problem("formula_missing_argument")),
        row("Reward(chest = true)", reward, problem("formula_missing_argument")),
        row("Reward(gold = 1, chest = true)", reward, type(reward)),
        row("5 in 1..9", boolean, type(boolean)),
        row("[\"a\": 1][\"a\"]", nullable(int), type(nullable(int))),
        row("[1, 2].distinct()", listType(int), type(listType(int))),
        row("npc.rank()", int, type(int)), // T : Entity, and an Npc is an Entity
        row("pet.rank()", int, problem("formula_type_bound")),
        row("loudest([npc])", npc, type(npc)),
        row("loudest(stock)", int, problem("formula_type_bound")),
        row("stock.rankAll()", int, problem("formula_type_bound")),
    )) {
        test("$source against ${expected.shown} gives $answer") { check(source, expected) shouldAnswer answer }
    }

    // An alias stands for the type it names, in both directions, inside type arguments and through another alias.
    // Rows: what the expected type is, source, expected type, what the checker must answer.
    for ((wanted, case) in listOf(
        "the alias Prize" to row("let p: Prize = storedPrize\np", prizeAliasUse, type(prizeAliasUse)),
        "the alias Prize" to row("storedPrize", prizeAliasUse, type(prizeAliasUse)),
        "the record Prize names" to row("aliasedPrize", prizeUse, type(prizeUse)),
        "a List of the record Prize names" to row("let ps = [aliasedPrize]\nps", listType(prizeUse), type(listType(prizeUse))),
        "a List of the alias Prize" to row("let ps = [storedPrize]\nps", listType(prizeAliasUse), type(listType(prizeAliasUse))),
        "the record the alias of an alias names" to row("let a: Award = storedPrize\na", prizeUse, type(prizeUse)),
        "Int, read through the alias of an alias" to row("let a: Award = aliasedPrize\na.gold", int, type(int)),
        "the alias Prize" to row("let p: Prize = storedGold\np", prizeAliasUse, problem("formula_type_mismatch")),
        "a List of the alias Prize" to row("let ps = [storedGold]\nps", listType(prizeAliasUse), problem("formula_type_mismatch")),
    )) {
        val (source, expected, answer) = case
        test("$source against $wanted gives $answer") { check(source, expected, EvaluationWorld().checking) shouldAnswer answer }
    }

    test("level is in scope in a function body") {
        check("level * 2", function("level" to int, result = int)) shouldAnswer type(int)
    }

    test("a constant is a valid function body") {
        check("12", function("level" to int, result = int)) shouldAnswer type(int)
    }

    test("lambda levels win over every other level") {
        check("items.map { bonus -> bonus + 1 }", listType(int)) shouldAnswer type(listType(int))
    }

    test("a when over a closed union with every case needs no else") {
        check("when (door) { is Open -> 1\n is Closed -> 2 }", int) shouldAnswer type(int)
    }

    test("a when over a closed union missing a case names the case") {
        check("when (door) { is Open -> 1 }", int).problems.single().message shouldContain "Closed"
    }

    test("a when over an open type needs else") {
        check("when (pet) { is Cat -> 1 }", int) shouldAnswer problem("formula_when_needs_else")
        check("when (pet) { is Cat -> 1\n else -> 2 }", int) shouldAnswer type(int)
    }

    test("is narrows the subject in its arm") {
        check("when (payment) { is Money -> payment.amount\n else -> 0 }", int) shouldAnswer type(int)
        check("when (payment) { is Free -> payment.amount\n else -> 0 }", int) shouldAnswer problem("formula_unknown_member")
    }

    test("is Money(amount) binds amount with its field type") {
        check("when (payment) { is Money(amount) -> amount\n is Free -> 0 }", int) shouldAnswer type(int)
        check("when (payment) { is Money(amount) -> amount\n is Free -> 0 }", string) shouldAnswer problem("formula_type_mismatch")
    }

    test("a guard does not count toward exhaustiveness") {
        val checked = check("when (payment) { is Money(amount) if amount > 100 -> 1\n is Free -> 0 }", int)
        checked shouldAnswer problem("formula_when_not_exhaustive")
        checked.problems.single().message shouldContain "Money"
    }

    test("an emptied reference is silent here and gives no cascade") {
        checkWithEmptied("smith.name", string).problems shouldBe emptyList()
        checkWithEmptied("smith.name + 1", string).problems shouldBe emptyList()
    }

    test("an emptied reference means a deleted name and offers what scope has for its text") {
        val answer = checkWithEmptied("smith.name", string).names.single()
        answer.meaning shouldBe NameMeaning.Deleted("smith")
        answer.candidates.map { it.value } shouldBe listOf("smith")
    }

    test("a filled reference whose target gives no type keeps its target and is silent") {
        val checked = checkWithTargetsGone("smith.name", string)
        checked.problems shouldBe emptyList()
        (checked.names.single().meaning as NameMeaning.Resource).id.value shouldBe "smith"
    }

    test("a name whose type is gone is silent and gives no cascade") {
        check("ghost.name", string).problems shouldBe emptyList()
    }

    test("a function parameter wins over an element of that name, and no candidate is offered") {
        val checked = check("level", function("level" to int, result = int))
        checked shouldAnswer type(int)
        checked.names.single().meaning shouldBe NameMeaning.Parameter
        checked.names
            .single()
            .candidates
            .shouldBeEmpty()
    }

    test("a name that resolves through a stored reference means that resource and offers no candidate") {
        val answer = check("smith.name", string).names.single()
        (answer.meaning as NameMeaning.Resource).id.value shouldBe "smith"
        answer.candidates.shouldBeEmpty()
    }

    test("a name in a Definition<Type> resource reads as a type and calls as a constructor") {
        check("let e: Energy = Energy(amount = 3)\ne.amount", int) shouldAnswer type(int)
    }

    test("a Definition<Type> holding a formula instead of a plain type is an error") {
        check("Shape(size = 1)", null) shouldAnswer problem("formula_type_not_plain")
        check("let s: Shape = 1\n1", int) shouldAnswer problem("formula_type_not_plain")
    }

    test("a Var field read through a Ref has its T as type") {
        check("smith.mood + 1", int) shouldAnswer type(int)
    }

    test("a two hop Ref chain types through both") {
        check("smith.home.name", string) shouldAnswer type(string)
    }

    test("one broken name still type checks the rest of the formula") {
        val codes = check("let x = unknown_thing\n1 + \"a\"", int).problems.map { it.code }
        codes shouldContainAll listOf("formula_unknown_name", "formula_type_mismatch")
    }

    test("a formula with no context reads has the pure kind") {
        check("1 + 2", int).reads.isPure shouldBe true
    }

    test("a provider's context read shows in reads") {
        val checked = check("needsPlayer()", function(context = listOf("protagonist" to player), result = int))
        checked shouldAnswer type(int)
        checked.reads.context shouldBe setOf("protagonist")
        checked.reads.isPure shouldBe false
    }

    test("the checker never throws on any parsed text, against any expected type") {
        val tokens =
            listOf(
                "smith",
                "items",
                "maybe",
                "door",
                "payment",
                "bonus",
                "it",
                "_",
                "1",
                "0.5",
                "\"s\"",
                "\"\${",
                "}",
                "{",
                "(",
                ")",
                "[",
                "]",
                ",",
                ":",
                "\n",
                ".",
                "?.",
                "?:",
                "?",
                "..",
                "->",
                "+",
                "-",
                "*",
                "<",
                "==",
                "!",
                "&&",
                "let",
                "if",
                "else",
                "when",
                "is",
                "in",
                "as?",
                "true",
                "null",
                "Open",
                "Money",
                "Reward",
                "map",
                "filter",
                "f",
                "=",
                "Int",
                "List<",
                ">",
            )
        val soup = Arb.list(Arb.element(tokens), 0..30).map { it.joinToString(" ") }
        val expected =
            Arb.element(
                listOf(null, int, string, boolean, door, nullable(int), listType(int), function("level" to int, result = int)),
            )
        checkAll(PropTestConfig(seed = 4_119_337_802L, iterations = 2_000), Arb.choice(Arb.string(0..40), soup), expected) { source, type ->
            check(source, type)
        }
    }
}
