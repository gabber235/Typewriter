@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.edit

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.of
import com.typewritermc.library.BookFields
import com.typewritermc.library.BookPages
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.routes.resource
import com.typewritermc.realm.testing.Refusal
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.refusals
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.unfilledRecord
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureTimelinePage
import com.typewritermc.testing.routes.FixtureTimelinePageDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.namedUse
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ValueLocation

val PageCreationTest by testSuite {
    val emptyBook = setup("empty-book") { library { books.book("story") { handle } } }

    val page = ResourceId("page")

    test("a page created without its book is refused as needing an owner and nothing is saved") {
        withSetup(emptyBook, catalog = routeFixtureCatalog) { book ->
            val bookless =
                unfilledRecord(FixtureTimelinePageDefinition.id.use(), FixtureTimelinePage(book = Ref(book.id), name = "Start"), "book")

            expectRefused { create(page, bookless) }.refusals shouldBe listOf(Refusal(page.value, "owner_required"))
        }
    }

    test("the same page created into its book commits and links both ways") {
        withSetup(emptyBook, catalog = routeFixtureCatalog) { book ->
            val bookless =
                unfilledRecord(FixtureTimelinePageDefinition.id.use(), FixtureTimelinePage(book = Ref(book.id), name = "Start"), "book")
            val pageLink =
                BookPages.Book.Definition.id
                    .namedUse(listOf(PageDefinition.id.use()))
                    .use

            commit {
                create(page, bookless)
                insert(
                    boundCollectionPath(ValueLocation.of(book.resource, BookFields.pages.path)),
                    null,
                    encoder.encode(pageLink, Ref<Nothing, Nothing>(page)),
                )
            }.shouldBeCommitted()

            resources.getValue(page.toSkir()).link("book") shouldBe book.resource
            resources.getValue(book.resource).links("pages") shouldBe listOf(page.toSkir())
        }
    }
}
