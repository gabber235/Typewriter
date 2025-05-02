package com.typewritermc.utils

import com.typewritermc.engine.paper.utils.parseDoubleFlexible
import io.kotest.core.spec.style.FunSpec
import io.kotest.datatest.withData
import io.kotest.matchers.shouldBe

class StringParseFlexibleFullTest : FunSpec({
    val standardCases = listOf(
        "1,234,567.89" to 1234567.89,
        "1.234.567,89" to 1234567.89,
        "12345.67" to 12345.67,
        "12345,67" to 12345.67,
        "999.5" to 999.5,
        "999,5" to 999.5,
        "1234567" to 1234567.0,
        "1.23e4" to 12300.0,
        "-5.67E-3" to -0.00567,
        " -1,234.56 " to -1234.56,
        " -1.234,56 " to -1234.56,
        "+123.45" to 123.45,
        "+1,234.56" to 1234.56,
        "+1.234,56" to 1234.56,
        "0" to 0.0,
        "0.0" to 0.0,
        "0,0" to 0.0,
        "-0.0" to -0.0
    )

    val separatorEdgeCases = listOf(
        ",123.45" to 123.45,
        ".123,45" to 123.45,
        "123," to 123.0,
        "123." to 123.0,
        "1,,234.56" to 1234.56,
        "1..234,56" to 1234.56,
        "1.,234.56" to null,
        "1,.234,56" to null,
        "-,123.45" to -123.45,
        "-.123,45" to -123.45,
        "1.2e3,4" to null,
        "1,2E3.4" to null
    )

    val signEdgeCases = listOf(
        "++123.45" to null,
        "--123.45" to null,
        "+-123.45" to null,
        "12+3.45" to null,
        "1.2e5+" to null
    )

    val scientificNotationEdgeCases = listOf(
        "1.2e3e4" to null,
        "1.2e" to null,
        "1.2e+" to null,
        "1.2e-" to null,
        "e5" to null,
        "1.e" to null,
        "1,234e5" to 123400.0
    )

    val mixedContentEdgeCases = listOf(
        "123a45.67" to null,
        "123$45.67" to null,
        "(123.45)" to null,
        "1 234.56" to null,
        "1.234 567,89" to null,
        "1. 234, 56" to null
    )

    val ambiguityAndInvalidEdgeCases = listOf(
        "1,000" to 1.0,
        "1.000" to 1.0,
        "." to null,
        "," to null,
        ".." to null,
        ",," to null,
        ".," to null,
        ",." to null,
        "1.2.3" to 123.0,
        "1,2,3" to 123.0,
        "1.2,3.4" to null,
        "1,2.3,4" to null,
        "invalid" to null,
        "" to null,
        "   " to null
    )

    val boundaryCases = listOf(
        "1.79e308" to 1.79e308,
        "1,79e308" to 1.79e308,
        "1.8e308" to Double.POSITIVE_INFINITY,
        "1,8e308" to Double.POSITIVE_INFINITY,
        "-1.79e308" to -1.79e308,
        "-1,79e308" to -1.79e308,
        "-1.8e308" to Double.NEGATIVE_INFINITY,
        "-1,8e308" to Double.NEGATIVE_INFINITY,
        "1e-324" to 0.0,
        "1,0e-324" to 0.0
    )

    val allTestData = standardCases +
            separatorEdgeCases +
            signEdgeCases +
            scientificNotationEdgeCases +
            mixedContentEdgeCases +
            ambiguityAndInvalidEdgeCases +
            boundaryCases

    context("String.parseDoubleFlexible() Full Test Suite") {
        withData(
            nameFn = { (input, expected) ->
                "Input: \"${input.padEnd(15)}\" should parse to: $expected"
            },
            allTestData
        ) { (input, expected) ->
            val result = input.parseDoubleFlexible()
            result shouldBe expected
        }
    }
})
