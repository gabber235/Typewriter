package com.typewritermc.expression.shortcuts

import com.typewritermc.authoring.Availability
import com.typewritermc.expression.eq
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.operations.KernelFailure
import com.typewritermc.expression.plus
import com.typewritermc.expression.rem
import com.typewritermc.expression.split
import com.typewritermc.expression.times
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.duration
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.timestamp
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.DataValue
import java.math.BigDecimal
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

val ShortcutEvaluationTest by testSuite {
    test("text shortcuts compare code points at the ends without failing on short text") {
        evaluate(subject<String>().endsWith(".json"), text("config.json")) shouldBe available(true)
        evaluate(subject<String>().endsWith(".json"), text("json")) shouldBe available(false)
        evaluate(subject<String>().endsWith("😀"), text("a😀")) shouldBe available(true)
        evaluate(subject<String>().endsWith(literal("")), text("")) shouldBe available(true)
        evaluate(subject<String>().startsWith("pre"), text("prefix")) shouldBe available(true)
        evaluate(subject<String>().startsWith("prefix"), text("pre")) shouldBe available(false)
        evaluate(subject<String>().contains("fix"), text("prefix")) shouldBe available(true)
        evaluate(subject<String>().contains("x!"), text("prefix")) shouldBe available(false)
    }

    test("text shortcuts trim portable whitespace and detect blank text") {
        evaluate(subject<String>().trim(), text("　 value ")) shouldBe available("value")
        evaluate(subject<String>().isBlank(), text("  \n")) shouldBe available(true)
        evaluate(subject<String>().isNotBlank(), text(" x ")) shouldBe available(true)
        evaluate(subject<String>().isEmpty(), text("")) shouldBe available(true)
    }

    test("text shortcuts replace, slice and pad by code point") {
        evaluate(subject<String>().replace("-", "_"), text("a-b--c")) shouldBe available("a_b__c")
        evaluate(subject<String>().take(2), text("😀bc")) shouldBe available("😀b")
        evaluate(subject<String>().take(10), text("abc")) shouldBe available("abc")
        evaluate(subject<String>().drop(1), text("abc")) shouldBe available("bc")
        evaluate(subject<String>().takeLast(2), text("abc")) shouldBe available("bc")
        evaluate(subject<String>().dropLast(5), text("abc")) shouldBe available("")
        evaluate(subject<String>().padStart(3, '0'), text("7")) shouldBe available("007")
        evaluate(subject<String>().padEnd(2, '.'), text("abc")) shouldBe available("abc")
        evaluate(subject<String>().substringBefore("."), text("a.b.c")) shouldBe available("a")
        evaluate(subject<String>().substringAfterLast("."), text("a.b.c")) shouldBe available("c")
        evaluate(subject<String>().substringAfter("?"), text("a.b")) shouldBe available("a.b")
        evaluate(subject<String>().removePrefix("re"), text("redo")) shouldBe available("do")
        evaluate(subject<String>().removeSuffix(".kt"), text("Main.java")) shouldBe available("Main.java")
        evaluate(subject<String>().capitalize(), text("ǆemal")) shouldBe available("ǅemal")
        evaluate(subject<String>().equalsIgnoreCase("STRASSE"), text("Straße")) shouldBe available(true)
        evaluate(subject<String>().truncate(5), text("abcdefgh")) shouldBe available("abcd…")
        evaluate(subject<String>().reversed(), text("ab😀")) shouldBe available("😀ba")
    }

    test("line shortcuts treat CR LF as one break and the empty text as no line") {
        evaluate(subject<String>().hasLineBreaks(), text("a b")) shouldBe available(true)
        evaluate(subject<String>().isSingleLine(), text("one line")) shouldBe available(true)
        evaluate(subject<String>().lineCount(), text("a\r\nb\nc")) shouldBe available(3L)
        evaluate(subject<String>().lineCount(), text("")) shouldBe available(0L)
    }

    test("template interpolates the canonical text of its arguments") {
        val name = subject<String>()
        evaluate(template("Hello {0}, {1}{0}!", name, literal(2)), text("Ada")) shouldBe available("Hello Ada, 2Ada!")
        evaluate(concat(name, literal(" "), name), text("x")) shouldBe available("x x")
    }

    test("comparison shortcuts order numbers, durations, timestamps and text") {
        evaluate(subject<Int>() gt 3, number(5)) shouldBe available(true)
        evaluate(subject<Int>() gte 5, number(5)) shouldBe available(true)
        evaluate(subject<Int>() lt 5, number(5)) shouldBe available(false)
        evaluate(subject<Int>() lte 4, number(5)) shouldBe available(false)
        evaluate(subject<Duration>() gt 1.hours, DataValue.duration(90.milliseconds)) shouldBe available(false)
        evaluate(
            subject<Instant>().isBefore(Instant.parse("2024-01-01T00:00:00Z")),
            DataValue.timestamp(Instant.parse("2023-12-31T23:59:59Z")),
        ) shouldBe available(true)
        evaluate(subject<String>() lt "b", text("a")) shouldBe available(true)
        evaluate(subject<Int>() neq literal(5), number(5)) shouldBe available(false)
    }

    test("number shortcuts negate, take absolute values, clamp and use floored modulo") {
        evaluate(-subject<Int>(), number(5)) shouldBe available(-5L)
        evaluate(subject<Long>().abs(), number(-7)) shouldBe available(7L)
        evaluate(subject<Double>().abs(), DataValue.FloatWrapper(-1.5)) shouldBe Availability.Available(DataValue.FloatWrapper(1.5))
        evaluate(subject<Int>().mod(3), number(-7)) shouldBe available(2L)
        evaluate(subject<Int>().clamp(0, 10), number(15)) shouldBe available(10L)
        evaluate(min(subject<Int>(), 3), number(15)) shouldBe available(3L)
        evaluate(max(subject<Int>(), 3), number(-1)) shouldBe available(3L)
        evaluate(subject<Int>().sign(), number(-4)) shouldBe available(-1L)
        evaluate(subject<Long>().isEven(), number(10)) shouldBe available(true)
        evaluate(subject<Long>().lcm(literal(6L)), number(-4)) shouldBe available(12L)
        evaluate(subject<BigDecimal>().floor(), DataValue.DecimalWrapper("-1.5")) shouldBe
            Availability.Available(DataValue.DecimalWrapper("-2"))
    }

    test("collection predicates evaluate every item and count matches") {
        val values = numbers(3, 1, 3, 2)
        evaluate(subject<List<Long>>().count { this gt 1L }, values) shouldBe available(3L)
        evaluate(subject<List<Long>>().any { this gt 3L }, values) shouldBe available(false)
        evaluate(subject<List<Long>>().all { this gte 1L }, values) shouldBe available(true)
        evaluate(subject<List<Long>>().none { this eq literal(5L) }, values) shouldBe available(true)
        evaluate(subject<List<Long>>().find { this gt 2L }, values) shouldBe available(3L)
        evaluate(subject<List<Long>>().find { this gt 5L }, values) shouldBe Availability.Available(DataValue.NULL)
        evaluate(subject<List<Long>>().indexOfLast { this eq literal(3L) }, values) shouldBe available(2L)
    }

    test("distinct keeps the first occurrence of each item with its identity") {
        val values = list(number(3), number(1), number(3), number(2), ids = listOf("a", "b", "c", "d"))
        evaluate(subject<List<Long>>().distinct(), values) shouldBe
            Availability.Available(list(number(3), number(1), number(2), ids = listOf("a", "b", "d")))
        evaluate(subject<List<Long>>().distinctBy { this % 2L }, values) shouldBe
            Availability.Available(list(number(3), number(2), ids = listOf("a", "d")))
        evaluate(subject<List<Long>>().uniqueBy { this }, values) shouldBe available(false)
        evaluate(subject<List<Long>>().unique(), numbers(1, 2)) shouldBe available(true)
    }

    test("list slicing shortcuts clamp to the list and keep item identities") {
        val values = list(number(3), number(1), number(2), ids = listOf("a", "b", "c"))
        evaluate(subject<List<Long>>().take(2), values) shouldBe Availability.Available(list(number(3), number(1), ids = listOf("a", "b")))
        evaluate(subject<List<Long>>().drop(2), values) shouldBe Availability.Available(list(number(2), ids = listOf("c")))
        evaluate(subject<List<Long>>().takeLast(5), values) shouldBe Availability.Available(values)
        evaluate(subject<List<Long>>().dropLast(5), values) shouldBe Availability.Available(list())
        evaluate(subject<List<Long>>().last(), values) shouldBe available(2L)
        evaluate(subject<List<Long>>().firstOrNull(), list()) shouldBe Availability.Available(DataValue.NULL)
    }

    test("extreme shortcuts pick the first smallest or largest key and fail or are null when empty") {
        val values = list(text("bb"), text("a"), text("cc"), text("d"), ids = listOf("p", "q", "r", "s"))
        evaluate(subject<List<String>>().minBy { length }, values) shouldBe available("a")
        evaluate(subject<List<String>>().maxBy { length }, values) shouldBe available("bb")
        evaluate(subject<List<String>>().minOf { length }, values) shouldBe available(1L)
        evaluate(subject<List<String>>().maxOf { length }, values) shouldBe available(2L)
        evaluate(subject<List<String>>().minByOrNull { length }, list()) shouldBe Availability.Available(DataValue.NULL)
        evaluate(subject<List<String>>().maxByOrNull { length }, values) shouldBe available("bb")
        val empty = evaluate(subject<List<String>>().minBy { length }, list())
        (empty as Availability.Failed).diagnostic.failure shouldBe KernelFailure.CollectionKeyAbsent
    }

    test("folding shortcuts reduce, sum and join") {
        evaluate(subject<List<Long>>().reduce { total, item -> total + item }, numbers(1, 2, 3)) shouldBe available(6L)
        evaluate(subject<List<Long>>().reduceOrNull { total, item -> total + item }, list()) shouldBe Availability.Available(DataValue.NULL)
        evaluate(subject<List<Long>>().sum(), numbers(1, 2, 3)) shouldBe available(6L)
        evaluate(subject<List<Long>>().sumOf { this * 2L }, numbers(1, 2, 3)) shouldBe available(12L)
        evaluate(subject<List<Long>>().joinToString(prefix = "[", postfix = "]"), numbers(1, 2)) shouldBe available("[1, 2]")
        evaluate(subject<List<String>>().flatMap { split(",") }.joinToString("|"), texts("a,b", "c")) shouldBe available("a|b|c")
    }

    test("duration formatting writes minutes, seconds and fraction digits as clock text") {
        val duration = subject<Duration>()
        evaluate(duration.formatDuration(), DataValue.duration(187_250.milliseconds)) shouldBe available("3:07.250")
        evaluate(duration.formatDuration(fractionalSecondDigits = 0), DataValue.duration(187_250.milliseconds)) shouldBe available("3:07")
        evaluate(duration.formatDuration(fractionalSecondDigits = 1), DataValue.duration(187_250.milliseconds)) shouldBe available("3:07.2")
        evaluate(duration.formatDuration(fractionalSecondDigits = 2), DataValue.duration(1_005.milliseconds)) shouldBe available("0:01.00")
        evaluate(duration.formatDuration(fractionalSecondDigits = 0), DataValue.duration(7_200_000.milliseconds)) shouldBe
            available("120:00")
        evaluate(duration.formatDuration(), DataValue.duration((-1_500).milliseconds)) shouldBe available("-0:01.500")
        evaluate(
            duration.formatDuration(DurationDisplayUnits.HoursMinutesAndSeconds),
            DataValue.duration(3_787_000.milliseconds),
        ) shouldBe available("1:03:07.000")
    }

    test("timestamp formatting expands numeric tokens over the calendar fields") {
        evaluate(
            subject<Instant>().formatTimestamp("yyyy-MM-dd HH:mm:ss.SSS"),
            DataValue.timestamp(Instant.parse("2024-03-05T07:08:09.012Z")),
        ) shouldBe available("2024-03-05 07:08:09.012")
        evaluate(
            subject<Instant>().formatTimestamp("yyyy/MM/dd"),
            DataValue.timestamp(Instant.parse("0099-12-31T23:59:59.999Z")),
        ) shouldBe available("0099/12/31")
    }

    test("calendar shortcuts clamp the day of month and honor the offset") {
        fun plusMonths(
            start: String,
            months: Int,
            offset: Duration = Duration.ZERO,
        ) = evaluate(subject<Instant>().plusMonths(months, offset), DataValue.timestamp(Instant.parse(start)))

        plusMonths("2024-01-31T10:00:00Z", 1) shouldBe Availability.Available(DataValue.timestamp(Instant.parse("2024-02-29T10:00:00Z")))
        plusMonths("2023-01-31T10:00:00Z", 1) shouldBe Availability.Available(DataValue.timestamp(Instant.parse("2023-02-28T10:00:00Z")))
        plusMonths("2024-03-31T10:00:00Z", -1) shouldBe Availability.Available(DataValue.timestamp(Instant.parse("2024-02-29T10:00:00Z")))
        plusMonths("2024-11-15T10:00:00Z", 3) shouldBe Availability.Available(DataValue.timestamp(Instant.parse("2025-02-15T10:00:00Z")))
        plusMonths("2024-01-31T23:00:00Z", 1, 2.hours) shouldBe
            Availability.Available(DataValue.timestamp(Instant.parse("2024-02-29T23:00:00Z")))
        evaluate(
            subject<Instant>().startOfDay(2.hours),
            DataValue.timestamp(Instant.parse("2024-03-05T23:30:00Z")),
        ) shouldBe Availability.Available(DataValue.timestamp(Instant.parse("2024-03-05T22:00:00Z")))
        evaluate(subject<Instant>().daysInMonth(), DataValue.timestamp(Instant.parse("1900-02-10T00:00:00Z"))) shouldBe available(28L)
    }

    test("regex shortcuts match the whole text and find captures") {
        evaluate(subject<String>().matches("[a-z]+"), text("abc")) shouldBe available(true)
        evaluate(subject<String>().matches("[a-z]+"), text("abc1")) shouldBe available(false)
        evaluate(subject<String>().matches("a|ab"), text("ab")) shouldBe available(true)
        evaluate(subject<String>().containsMatchIn("[0-9]"), text("abc1")) shouldBe available(true)
        evaluate(subject<String>().capture("([a-z]+)=([0-9]+)", 2), text("x key=42")) shouldBe available("42")
        evaluate(subject<String>().escapeRegex(), text("a.b*c")) shouldBe available("a\\.b\\*c")
    }

    test("raw regex shortcut patterns are validated alone when the expression is built") {
        shouldThrow<IllegalArgumentException> { subject<String>().matches("a)|(b") }
        shouldThrow<IllegalArgumentException> { subject<String>().matches("(?=a)") }
        shouldThrow<IllegalArgumentException> { subject<String>().containsMatchIn("(") }
    }

    test("rule shortcuts bound, divide and choose among allowed values") {
        evaluate(subject<Int>().positive(), number(0)) shouldBe available(false)
        evaluate(subject<Int>().nonNegative(), number(0)) shouldBe available(true)
        evaluate(subject<Int>().inRange(1, 3), number(3)) shouldBe available(true)
        evaluate(subject<Int>().inRange(1, 3), number(4)) shouldBe available(false)
        evaluate(subject<Int>().multipleOf(5), number(15)) shouldBe available(true)
        evaluate(subject<BigDecimal>().multipleOf(BigDecimal("0.25")), DataValue.DecimalWrapper("1.5")) shouldBe available(true)
        evaluate(subject<Double>().multipleOf(2.0), DataValue.FloatWrapper(-4.0)) shouldBe available(true)
        evaluate(subject<Double>().multipleOf(literal(2.0).lift()), DataValue.FloatWrapper(-4.0)) shouldBe available(true)
        evaluate(subject<Double>().multipleOf(2.0), DataValue.FloatWrapper(-3.0)) shouldBe available(false)
        evaluate(subject<BigDecimal>().maximumScale(2), DataValue.DecimalWrapper("1.250")) shouldBe available(true)
        evaluate(subject<String>().oneOf(literal("a"), literal("b")), text("c")) shouldBe available(false)
    }

    test("color shortcuts apply to color literals as to authored colors") {
        val color = literal(Color(0xFF123456u))
        evaluate(color.red) shouldBe available(0x12L)
        evaluate(color.opaque()) shouldBe available(true)
        evaluate(color.toHexString()) shouldBe available("#123456")
        evaluate(color.withAlpha(0x80)) shouldBe
            Availability.Available(DataValue.named(ColorDefinition.use, DataValue.integer(0x80123456L)))
    }

    test("color shortcuts read and replace channels of the ARGB word") {
        val color = DataValue.named(ColorDefinition.use, DataValue.integer(0xFF123456L))
        evaluate(subject<Color>().opaque(), color) shouldBe available(true)
        evaluate(subject<Color>().red, color) shouldBe available(0x12L)
        evaluate(subject<Color>().withAlpha(0x80), color) shouldBe
            Availability.Available(DataValue.named(ColorDefinition.use, DataValue.integer(0x80123456L)))
        evaluate(subject<Color>().toHexString(), color) shouldBe available("#123456")
        evaluate(subject<String>().toColorOrNull(), text("#zz0000")) shouldBe Availability.Available(DataValue.NULL)
        val outOfRange = evaluate(subject<Color>().withAlpha(literal(300u)), color)
        outOfRange.shouldBeInstanceOf<Availability.Failed>().diagnostic.failure shouldBe KernelFailure.InexactConversion
    }
}
