package com.typewritermc.formula.syntax

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.testing.names
import com.typewritermc.formula.testing.render
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.shouldBe

val ParserTest by testSuite {
    for ((source, tree) in listOf(
        "1 + 2 * 3" to "(+ 1 (* 2 3))",
        "0 < x < 10" to "(chain 0 < x < 10)",
        "a ?: b ?: c" to "(?: a (?: b c))",
        "a?.b.c" to "(. (?. a b) c)",
        "a and not b or c" to "(or (and a (not b)) c)",
        "a && !b || c" to "(or (and a (not b)) c)",
        "c ? a : b" to "(if c a b)",
        "if (c) a else b" to "(if c a b)",
        "members.filter(.is_veteran).sumOf(.coins)" to
            "(call (. (call (. members filter) (short is_veteran)) sumOf) (short coins))",
        "items.map { it.gold }" to "(call (. items map) (lambda (. it gold)))",
        "{ (k, v) -> k }" to "(lambda ((k v)) k)",
        "[a, b]" to "(list a b)",
        "[sword: 50]" to "(map (sword 50))",
        "1 in 10..49" to "(in 1 (.. 10 49))",
        "bonus(level = 10)" to "(call bonus (level= 10))",
        "give(\n  sword,\n  amount = 3\n)" to "(call give sword (amount= 3))",
        "`Dragon Quest`.stage" to "(. \"Dragon Quest\" stage)",
        "\"Total: \${total:#,###}\"" to "(template \"Total: \" (hole total \"#,###\"))",
        "\"Find \$needed more\"" to "(template \"Find \" (hole needed) \" more\")",
        "\"\${c ? a : b}\"" to "(template (hole (if c a b)))",
        "let x = 5\nx + 1" to "(block (let x 5) (+ x 1))",
        "let x = 5; x + 1" to "(block (let x 5) (+ x 1))",
        "let double(x: Int) = x * 2\ndouble(2)" to "(block (fun double (x Int) (* x 2)) (call double 2))",
        "let fact(n: Int): Int = n\nfact(2)" to "(block (fun fact (n Int) :Int n) (call fact 2))",
        "let (gold, xp) = split(100)\ngold" to "(block (let (gold xp) (call split 100)) gold)",
        "if let q = find() { q } else { 0 }" to "(if-let q (call find) q 0)",
        "when (door) { is Open -> 1\n is Money(amount) if amount > 100 -> 2\n else -> 3 }" to
            "(when door (is Open 1) (is (Money amount) (> amount 100) 2) (else 3))",
        "when (level) { in 0..9 -> \"Novice\"; else -> \"Hero\" }" to
            "(when level (in (.. 0 9) (string \"Novice\")) (else (string \"Hero\")))",
        "when (let loc = smith.location) { is Spawned -> loc }" to "(when (let loc (. smith location)) (is Spawned loc))",
        "x as? Money" to "(as? x Money)",
        "x is Open" to "(is x Open)",
        "list[0]" to "(index list 0)",
        "a\n  .b\n  ?: c" to "(?: (. a b) c)",
        "1_000 + 0.5 + 1e3" to "(+ (+ 1000 0.5) 1000.0)",
        "\"\"\"raw \$x\"\"\"" to "(string \"raw \$x\")",
        "a // comment\n/* c */" to "a",
    )) {
        test("$source groups as $tree") {
            val parsed = parseExpression(source)
            parsed.root.render() shouldBe tree
            parsed.problems.shouldBeEmpty()
        }
    }

    for ((source, tree) in listOf(
        "Map<Ref<Npc>, Mood>?" to "(? (Map (Ref Npc) Mood))",
        "(level: Int) -> Int" to "(fn () ((level Int)) Int)",
        "context(protagonist: Protagonist) () -> Boolean" to "(fn ((protagonist Protagonist)) () Boolean)",
        "record { gold: Int, xp: Int }" to "(record (gold Int) (xp Int))",
        "union { Spawned(position: Position), NotSpawned }" to "(union (Spawned (position Position)) NotSpawned)",
        "citizens.Npc" to "(citizens Npc)",
    )) {
        test("the type $source parses as $tree") {
            val parsed = parseType(source)
            parsed.root.render() shouldBe tree
            parsed.problems.shouldBeEmpty()
        }
    }

    test("a broken part reports its own span and the rest still parses") {
        val parsed = parseExpression("base_reward + ")
        parsed.problems.single().span shouldBe TextSpan(14, 14)
        parsed.root.render() shouldBe "(+ base_reward (error))"
    }

    test("a broken argument keeps the call and its other arguments") {
        val parsed = parseExpression("give(sword, * , amount = 3)")
        parsed.problems.single().span shouldBe TextSpan(12, 13)
        parsed.root.render() shouldBe "(call give sword (error) (amount= 3))"
    }

    test("a broken line keeps the lines around it") {
        val parsed = parseExpression("let x = )\nx + 1")
        parsed.problems.single().span shouldBe TextSpan(8, 9)
        parsed.root.render() shouldBe "(block (let x (error)) (+ x 1))"
    }

    test("an unclosed bracket is reported where the text ends and keeps what it holds") {
        val parsed = parseExpression("bonus(level")
        parsed.problems.single().span shouldBe TextSpan(11, 11)
        parsed.root.render() shouldBe "(call bonus level)"
    }

    test("a half typed member keeps its target and an empty name where the member goes") {
        val parsed = parseExpression("protagonist.")
        parsed.problems.single().span shouldBe TextSpan(12, 12)
        parsed.root.render() shouldBe "(. protagonist \"\")"
    }

    test("spans count UTF-16 units, so a name after an emoji points at the name") {
        val name = parseExpression("\"😀\" + bonus").root.names().single()
        name.span shouldBe TextSpan(7, 12)
    }

    test("the words change lines use are rejected in this grammar") {
        for (source in listOf("quest.coins += 50", "quest.coins = 50", "quest.title ?= \"Hero\"")) {
            parseExpression(source).problems.shouldNotBeEmpty()
        }
    }

    test("an empty formula is a problem") {
        parseExpression("  ").problems.single().span shouldBe TextSpan(2, 2)
    }

    test("an unterminated string is a problem at the string") {
        parseExpression("\"abc").problems.single().span shouldBe TextSpan(0, 4)
    }

    test("a function type names its parameters") {
        parseType("(Int) -> Int").problems.shouldNotBeEmpty()
    }
}
