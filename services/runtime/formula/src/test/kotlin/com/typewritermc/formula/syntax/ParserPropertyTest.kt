package com.typewritermc.formula.syntax

import com.typewritermc.formula.testing.children
import com.typewritermc.formula.testing.descendants
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.choice
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.arbitrary.string
import io.kotest.property.checkAll

/**
 * Parser invariants over generated text: plain strings, and soups of the language's own tokens, which reach far
 * more of the grammar's half typed states. The seed is fixed, so every run checks the same cases; a failure this
 * finds becomes an example in ParserTest.
 */
val ParserPropertyTest by testSuite {
    /** Fixed, so every run checks the same cases; change it only on purpose. */
    val config = PropTestConfig(seed = 7_301_955_120L, iterations = 2_000)
    val tokens =
        listOf(
            "a",
            "it",
            "_",
            "`x y`",
            "1",
            "0.5",
            "1e3",
            "\"s\"",
            "\"\${",
            "\"\$a\"",
            "\"\"\"",
            "}",
            "{",
            "(",
            ")",
            "[",
            "]",
            ",",
            ":",
            ";",
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
            "/",
            "%",
            "<",
            ">",
            "<=",
            "==",
            "!=",
            "!",
            "&&",
            "||",
            "=",
            "+=",
            "let",
            "if",
            "else",
            "when",
            "is",
            "!is",
            "in",
            "as?",
            "and",
            "not",
            "true",
            "null",
            "record",
            "union",
            "context",
            "//",
            "/*",
            "*/",
            "😀",
        )
    val soup = Arb.list(Arb.element(tokens), 0..40).map { it.joinToString(" ") }
    val text = Arb.choice(Arb.string(0..60), soup)

    test("no text makes the parser throw") {
        checkAll(config, text) { source ->
            parseExpression(source)
            parseType(source)
        }
    }

    test("every node's span lies inside its parent's span and inside the text") {
        checkAll(config, text) { source ->
            for (root in listOf(parseExpression(source).root, parseType(source).root)) {
                val outside =
                    root.descendants().flatMap { parent ->
                        parent.children().filterNot {
                            parent.span.start <= it.span.start && it.span.end <= parent.span.end
                        }
                    } + listOf(root).filterNot { 0 <= it.span.start && it.span.end <= source.length }
                outside.shouldBeEmpty()
            }
        }
    }

    test("every problem's span lies inside the text") {
        checkAll(config, text) { source ->
            val problems = parseExpression(source).problems + parseType(source).problems
            problems
                .filterNot { 0 <= it.span.start && it.span.start <= it.span.end && it.span.end <= source.length }
                .shouldBeEmpty()
        }
    }

    test("a very deep expression is a problem, not a stack overflow, and its tree can be walked") {
        val depth = 100_000
        for (source in listOf(
            "(".repeat(depth) + "1" + ")".repeat(depth),
            "-".repeat(depth) + "1",
            "a ?: ".repeat(depth) + "b",
            "a + ".repeat(depth) + "b",
            "a" + ".b".repeat(depth),
            "f" + "(1)".repeat(depth),
            "[".repeat(depth),
            "{ ".repeat(depth),
            "if (c) ".repeat(depth) + "1",
            "\"\${".repeat(depth),
        )) {
            val parsed = parseExpression(source)
            parsed.problems.shouldNotBeEmpty()
            parsed.root.descendants()
        }
        val type = parseType("List<".repeat(depth) + "Int" + ">".repeat(depth))
        type.problems.shouldNotBeEmpty()
        type.root.descendants()
    }
}
