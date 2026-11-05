package com.typewritermc.expression.shortcuts

import com.typewritermc.configuration.ruleProfileViolations
import com.typewritermc.expression.Expr
import com.typewritermc.expression.literal
import com.typewritermc.types.duration
import com.typewritermc.types.timestamp
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.DataValue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/*
 * The lowering contract of the shortcuts: a single read of every argument a composition needs twice, and primitive
 * calls of the profile the shortcut promises.
 */
val ShortcutLoweringTest by testSuite {
    val value = subject<Int>()

    test("compositions that need an argument twice read it once") {
        val text = subject<String>()
        val sample = text("a.json\nline")
        val list = com.typewritermc.expression.integerList(3, 1, 3)
        listOf<Pair<Expr<*, *>, DataValue>>(
            text.endsWith(".json") to sample,
            text.endsWith(literal("x")) to sample,
            text.take(2) to sample,
            text.dropLast(2) to sample,
            text.hasLineBreaks() to sample,
            text.lineCount() to sample,
            text.substringAfterLast(".") to sample,
            value.abs() to number(-4),
            value.clamp(0, 10) to number(12),
            value.inRange(0, 10) to number(5),
            subject<Duration>().formatDuration(DurationDisplayUnits.HoursMinutesAndSeconds) to DataValue.duration(3_723.seconds),
            subject<Instant>().formatTimestamp("yyyy-MM-dd HH:mm:ss.SSS") to DataValue.timestamp(Instant.fromEpochMilliseconds(1_000)),
            subject<Instant>().plusMonths(1) to DataValue.timestamp(Instant.fromEpochMilliseconds(1_000)),
            subject<List<Int>>().lastOrNull() to list,
            subject<List<Int>>().takeLast(1) to list,
            subject<List<Int>>().unique() to list,
            template("{0} and {0}", text) to sample,
        ).forEach { (shortcut, input) ->
            val reads = mutableListOf<skirout.editor.v1.type_catalog.ValueLocation>()
            com.typewritermc.expression
                .evaluate(shortcut.toNode(), SUBJECT.value to input, reads = reads)
                .shouldBeInstanceOf<com.typewritermc.authoring.Availability.Available<*>>()
            reads shouldHaveSize 1
        }
    }

    test("rule shortcuts lower only to rule profile operations") {
        listOf<Expr<*, *>>(
            subject<String>().endsWith(".json"),
            subject<String>().trim(),
            subject<String>().matches("[a-z]+"),
            subject<List<Int>>().distinctBy { this },
            subject<Duration>().formatDuration(),
            subject<Instant>().formatTimestamp("yyyy-MM-dd"),
            value.multipleOf(3),
        ).forEach { shortcut -> shortcut.toNode().ruleProfileViolations().shouldBeEmpty() }
    }
}
