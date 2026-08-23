package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val VisualValuesTest by testSuite {
    test("icon parser distinguishes iconify names from SVG sources") {
        Icon.parse("material-symbols:science") shouldBe Icon.Iconify("material-symbols:science")
        Icon.parse("<svg></svg>") shouldBe Icon.Svg("<svg></svg>")
    }

    test("icon values reject malformed input") {
        shouldThrow<IllegalArgumentException> { Icon.Iconify("science") }
        shouldThrow<IllegalArgumentException> { Icon.Svg(" ") }
    }

    test("RGB colors become opaque ARGB values") {
        Color.parseRgb("#7C4DFF") shouldBe Color(0xFF7C4DFFu)
    }

    test("colors reject malformed RGB input") {
        shouldThrow<IllegalArgumentException> { Color.parseRgb("7C4DFF") }
        shouldThrow<IllegalArgumentException> { Color.parseRgb("#12345678") }
    }
}
