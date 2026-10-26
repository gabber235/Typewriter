package com.typewritermc.setup

import com.typewritermc.library.book
import com.typewritermc.library.library
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val SetupTest by testSuite {
    test("the same setup gives the same resource ids in every run") {
        setup("a") { library { books.book("x") { } } }.resources shouldBe
            setup("a") { library { books.book("x") { } } }.resources
    }

    test("keys that join to the same path still get different ids") {
        // A book keyed "x/pages y" and a page "y" in book "x" spell the same text when the steps are joined by "/".
        stableId(listOf("library", "books x/pages y")) shouldNotBe stableId(listOf("library", "books x", "pages y"))
    }

    test("two different parts under one id are refused when merged") {
        shouldThrow<IllegalArgumentException> {
            setup("a") { library { books.book("x") { title = "One" } } } +
                setup("b") { library { books.book("x") { title = "Two" } } }
        }
    }

    test("setup names are lowercase words joined by dashes") {
        shouldThrow<IllegalArgumentException> { SetupName("Quest Log") }
    }
}
