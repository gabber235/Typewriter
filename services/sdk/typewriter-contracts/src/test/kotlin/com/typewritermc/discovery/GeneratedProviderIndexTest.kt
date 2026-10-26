package com.typewritermc.discovery

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val GeneratedProviderIndexTest by testSuite {
    val book = GeneratedProviderIndexEntry(GeneratedProviderKind.Type, "com.example.Book\$Provider", "main")
    val tag = GeneratedProviderIndexEntry(GeneratedProviderKind.Presentation, "com.example.TagPresentation", "main")

    test("a rendered index parses back to its rows") {
        GeneratedProviderIndex.parse(GeneratedProviderIndex.render(listOf(book, tag))) shouldBe listOf(tag, book)
    }

    test("rendering ignores input order and duplicates so every build writes the same bytes") {
        GeneratedProviderIndex.render(listOf(tag, book, tag)) shouldBe GeneratedProviderIndex.render(listOf(book, tag))
        GeneratedProviderIndex.render(listOf(book, tag)) shouldBe
            "presentation\tcom.example.TagPresentation\tmain\ntype\tcom.example.Book\$Provider\tmain\n"
    }

    test("parsing skips blank lines and surrounding whitespace") {
        GeneratedProviderIndex.parse("\n  type\tcom.example.Book\$Provider\tmain  \n\n") shouldBe listOf(book)
    }

    mapOf(
        "a line with two columns" to
            ("type\tcom.example.Book" to "Generated provider index line 1 must contain kind, provider class, and source part."),
        "a line with a blank column" to
            ("type\t \tmain" to "Generated provider index line 1 must contain kind, provider class, and source part."),
        "an unknown kind" to ("widget\tcom.example.Book\tmain" to "Generated provider index line 1 uses unknown kind widget."),
        "an unqualified provider class" to ("type\tBook\tmain" to "Generated provider index line 1 has an invalid provider class."),
        "a source part with a dash" to
            ("type\tcom.example.Book\tmain-part" to "Generated provider index line 1 has an invalid source part."),
        "a duplicate row" to
            ("type\tcom.example.Book\tmain\ntype\tcom.example.Book\tmain" to "Generated provider index contains duplicate rows."),
    ).forEach { (case, rejection) ->
        test("parsing refuses $case") {
            shouldThrow<IllegalArgumentException> { GeneratedProviderIndex.parse(rejection.first) }.message shouldBe rejection.second
        }
    }

    test("rendering refuses a row the parser would refuse") {
        shouldThrow<IllegalArgumentException> {
            GeneratedProviderIndex.render(listOf(book.copy(sourcePart = "1main")))
        }.message shouldBe "Invalid source part 1main."
        shouldThrow<IllegalArgumentException> {
            GeneratedProviderIndex.render(listOf(book.copy(providerClass = "Book")))
        }.message shouldBe "Invalid provider class Book."
    }

    test("a runtime registrar id must be one safe path segment") {
        listOf("core", "core.library_2").map(RuntimeRegistrarId::isValid) shouldBe listOf(true, true)
        listOf("", "../core", "core/library", ".core", "core library").map(RuntimeRegistrarId::isValid) shouldBe List(5) { false }
        shouldThrow<IllegalArgumentException> { RuntimeRegistrarId("../core") }.message shouldBe
            "Runtime registrar ids must be safe path segments."
    }
}
