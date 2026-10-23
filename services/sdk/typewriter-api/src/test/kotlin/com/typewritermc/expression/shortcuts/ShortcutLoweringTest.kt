package com.typewritermc.expression.shortcuts

import com.typewritermc.authoring.root
import com.typewritermc.expression.Expr
import com.typewritermc.expression.descendants
import com.typewritermc.expression.literal
import com.typewritermc.expression.operations.OperationProfile
import com.typewritermc.expression.operations.PortableOperation
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.types.integer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValuePath
import kotlin.time.Duration
import kotlin.time.Instant

/*
 * The lowering contract of the shortcuts: the comparison shapes DefaultPredicateReasoner reads, a single evaluation of
 * every argument a composition needs twice, and primitive calls of the profile the shortcut promises.
 */
val ShortcutLoweringTest by testSuite {
    val value = subject<Int>()
    val valueNode = ExpressionNode.createInput(binding = SUBJECT, path = ValuePath.root)

    test("comparisons lower to value.compare tested against -1 or 1, negated for the inclusive forms") {
        fun comparedWith(sign: Int) =
            call(
                PortableOperationCatalog.VALUE_EQUALS,
                call(PortableOperationCatalog.VALUE_COMPARE, valueNode, integerLiteral(5)),
                integerLiteral(sign),
            )

        (value gt 5).toNode() shouldBe comparedWith(1)
        (value lt 5).toNode() shouldBe comparedWith(-1)
        (value gte 5).toNode() shouldBe call(PortableOperationCatalog.BOOLEAN_NOT, comparedWith(-1))
        (value lte 5).toNode() shouldBe call(PortableOperationCatalog.BOOLEAN_NOT, comparedWith(1))
    }

    test("inRange binds its subject once with value.let around both inclusive bounds") {
        val lowered = value.inRange(1, 3).toNode()
        val local = ExpressionNode.createLocal(depth = 0, slot = 0, path = ValuePath.root)

        fun bound(
            limit: Int,
            sign: Int,
        ) = call(
            PortableOperationCatalog.BOOLEAN_NOT,
            call(
                PortableOperationCatalog.VALUE_EQUALS,
                call(PortableOperationCatalog.VALUE_COMPARE, local, integerLiteral(limit)),
                integerLiteral(sign),
            ),
        )

        lowered shouldBe
            call(
                PortableOperationCatalog.VALUE_LET,
                valueNode,
                ExpressionNode.createLambda(arity = 1, body = ExpressionNode.createAnd(left = bound(1, -1), right = bound(3, 1))),
            )
    }

    test("compositions that need an argument twice evaluate it once") {
        val text = subject<String>()
        val textNode = valueNode
        listOf<Expr<*, *>>(
            text.endsWith(".json"),
            text.endsWith(literal("x")),
            text.take(2),
            text.dropLast(2),
            text.hasLineBreaks(),
            text.lineCount(),
            text.substringAfterLast("."),
            value.abs(),
            value.clamp(0, 10),
            value.inRange(0, 10),
            subject<Duration>().formatDuration(DurationDisplayUnits.HoursMinutesAndSeconds),
            subject<Instant>().formatTimestamp("yyyy-MM-dd HH:mm:ss.SSS"),
            subject<Instant>().plusMonths(1),
            subject<List<Int>>().lastOrNull(),
            subject<List<Int>>().takeLast(1),
            subject<List<Int>>().unique(),
            template("{0} and {0}", text),
        ).forEach { shortcut -> shortcut.toNode().descendants().count { it == textNode } shouldBe 1 }
    }

    test("shortcuts lower to declared primitives, and rule shortcuts only to rule profile ones") {
        val ruleShortcuts =
            listOf<Expr<*, *>>(
                subject<String>().endsWith(".json"),
                subject<String>().trim(),
                subject<String>().matches("[a-z]+"),
                subject<List<Int>>().distinctBy { this },
                subject<Duration>().formatDuration(),
                subject<Instant>().formatTimestamp("yyyy-MM-dd"),
                value.multipleOf(3),
            )
        ruleShortcuts.forEach { shortcut -> shortcut.operations().filter { it.profile != OperationProfile.RULE }.shouldBeEmpty() }

        subject<Instant>().formatTimestamp("dd MMMM yyyy").operations() shouldContain PortableOperationCatalog.TIMESTAMP_MONTH_NAME
        subject<Instant>().formatTimestamp("HH:mm", zone = "Europe/Amsterdam").operations() shouldContain
            PortableOperationCatalog.TIMESTAMP_ZONE_OFFSET
    }
}

private fun call(
    operation: PortableOperation,
    vararg arguments: ExpressionNode,
): ExpressionNode = ExpressionNode.createCall(operation = operation.id, typeArguments = emptyList(), arguments = arguments.toList())

private fun integerLiteral(value: Int): ExpressionNode = ExpressionNode.LiteralWrapper(DataValue.integer(value.toLong()))

/** The declared operation of every call in the lowered tree; fails for a call no declaration names. */
private fun Expr<*, *>.operations(): List<PortableOperation> =
    toNode()
        .descendants()
        .filterIsInstance<ExpressionNode.CallWrapper>()
        .map { call -> requireNotNull(PortableOperationCatalog.declaration(call.value.operation)) { "Undeclared ${call.value.operation}" } }
        .toList()
