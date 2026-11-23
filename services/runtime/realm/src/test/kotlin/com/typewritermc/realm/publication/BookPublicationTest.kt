package com.typewritermc.realm.publication

import com.typewritermc.engine.pages.staticPage
import com.typewritermc.formula.Formula
import com.typewritermc.formula.Var
import com.typewritermc.library.Book
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.publishToEngine
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

/** What an engine needs of a book to decide whom its pages apply to arrives with the pages. */
val BookPublicationTest by testSuite {
    test("a published page brings its book's condition to the engine") {
        val gated =
            setup("gated-book") {
                library {
                    books.book("gated") {
                        condition = Var.Computed(Formula("protagonist.principal.id == \"sam\""))
                        pages.staticPage("start") { }
                        handle
                    }
                }
            }
        withSetup(gated, catalog = routeFixtureCatalog) { book ->
            publishToEngine().getValue(book.id.toSkir()).shouldBeInstanceOf<Book>().condition shouldBe
                Var.Computed(Formula("protagonist.principal.id == \"sam\""))
        }
    }
}
