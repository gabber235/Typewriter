package com.typewritermc.utils

import com.typewritermc.engine.paper.utils.DurationParser
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class DurationParserTest : FunSpec({
    test("single duration parsing") {
        DurationParser.parse("1ms").inWholeMilliseconds shouldBe 1
        DurationParser.parse("123sec").inWholeSeconds shouldBe 123
        DurationParser.parse("52 m").inWholeMinutes shouldBe 52
        DurationParser.parse("23hr").inWholeHours shouldBe 23
        DurationParser.parse("31d").inWholeDays shouldBe 31
        DurationParser.parse("12 w").inWholeDays / 7 shouldBe 12
        DurationParser.parse("5 months").inWholeDays / 30 shouldBe 5
        DurationParser.parse("2yr").inWholeDays / 365 shouldBe 2
    }

    test("multiple duration sum parsing") {
        // Complex duration sum
        DurationParser.parse("123sec 52 m 23hr 31d 12 w 5 months 2yr").inWholeSeconds shouldBe
            123 + 52 * 60 + 23 * 60 * 60 + 31 * 24 * 60 * 60 +
            12 * 7 * 24 * 60 * 60 + 5 * 30 * 24 * 60 * 60 +
            2 * 365 * 24 * 60 * 60

        // Hour and minutes
        DurationParser.parse("1 hr 20 mins").inWholeMinutes shouldBe 80

        // Compact notation
        DurationParser.parse("1h20m0s").inWholeMinutes shouldBe 80
    }

    test("duration parsing with special characters") {
        DurationParser.parse("27,681 ms").inWholeMilliseconds shouldBe 27681
        DurationParser.parse("27_681 milliseconds").inWholeMilliseconds shouldBe 27681
    }

    test("empty duration string parsing") {
        DurationParser.parse("").inWholeSeconds shouldBe 0
    }

    test("negative duration parsing") {
        DurationParser.parse("-1 hr").inWholeHours shouldBe -1
        DurationParser.parse("-30min").inWholeMinutes shouldBe -30
    }
})