@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.edit

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.of
import com.typewritermc.library.Book
import com.typewritermc.library.BookFields
import com.typewritermc.library.BookPages
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.routes.resource
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.SetupHandle
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureTimelinePage
import com.typewritermc.testing.routes.fixtureTimelinePage
import com.typewritermc.types.Ref
import com.typewritermc.types.namedUse
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ValueLocation

/** A page held by the first of two books. */
private data class TwoBooks(
    val first: SetupHandle<Book>,
    val second: SetupHandle<Book>,
    val page: SetupHandle<FixtureTimelinePage>,
)

private val twoBooks =
    setup("two-books") {
        library {
            val (first, page) =
                books.book("first") {
                    handle to
                        pages.fixtureTimelinePage("start") {
                            name = "Start"
                            handle
                        }
                }
            TwoBooks(first, books.book("second") { handle }, page)
        }
    }

val ResourceOwnershipTest by testSuite {
    test("a committed page links to its book and the book lists the page") {
        withSetup(twoBooks, catalog = routeFixtureCatalog) { (first, _, page) ->
            resources.getValue(page.resource).link("book") shouldBe first.resource
            resources.getValue(first.resource).links("pages") shouldBe listOf(page.resource)
        }
    }

    test("listing a page in a second book moves it there so it keeps one owner") {
        withSetup(twoBooks, catalog = routeFixtureCatalog) { (first, second, page) ->
            val pages = boundCollectionPath(ValueLocation.of(second.resource, BookFields.pages.path))
            val pageLink =
                BookPages.Book.Definition.id
                    .namedUse(listOf(PageDefinition.id.use()))
                    .use

            commit { insert(pages, null, encoder.encode(pageLink, Ref<Nothing, Nothing>(page.id))) }.shouldBeCommitted()

            resources.getValue(page.resource).link("book") shouldBe second.resource
            resources.getValue(second.resource).links("pages") shouldBe listOf(page.resource)
            resources.getValue(first.resource).links("pages") shouldBe emptyList()
        }
    }
}
