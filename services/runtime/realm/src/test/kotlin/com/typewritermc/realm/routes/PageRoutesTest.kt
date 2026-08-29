package com.typewritermc.realm.routes

import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.createPage
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.page.SearchPagesRequest
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.WatchPageRequest
import skirout.library.v1.page.WatchPageResponse

val PageRoutesTest by testSuite {
    test("page search filters within one book") {
        runTest {
            RouteFixture().use { fixture ->
                val firstBook =
                    fixture.repositories.books
                        .createBook("first_book", "Book", Color(argb = 0), emptyList())
                        .successValue()
                val secondBook =
                    fixture.repositories.books
                        .createBook("second_book", "Book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            firstBook.bookId,
                            "opening_scene",
                            TestPageKinds.SCENE,
                            "",
                            0,
                        ).successValue()
                fixture.repositories.pages
                    .createPage(secondBook.bookId, "opening_scene", TestPageKinds.SCENE, "", 0)
                    .successValue()

                val filtered =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = firstBook.bookId, search = "OPENING"),
                        SearchPagesRequest.serializer,
                        SearchPagesResponse.serializer,
                    )
                val empty =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = firstBook.bookId, search = "missing"),
                        SearchPagesRequest.serializer,
                        SearchPagesResponse.serializer,
                    )

                filtered shouldBe SearchPagesResponse.SuccessWrapper(listOf(page))
                empty shouldBe SearchPagesResponse.SuccessWrapper(emptyList())
            }
        }
    }

    test("page search rejects wrong tables and missing books") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = recordId("tag", "wrong"), search = null),
                        SearchPagesRequest.serializer,
                        SearchPagesResponse.serializer,
                    )
                val missingId = recordId("book", "missing")
                val missing =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = missingId, search = null),
                        SearchPagesRequest.serializer,
                        SearchPagesResponse.serializer,
                    )

                invalid.kind shouldBe SearchPagesResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe SearchPagesResponse.createBookNotFoundError(bookId = missingId)
            }
        }
    }

    test("page resource watch returns persisted pages") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("book_one", "Book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(book.bookId, "page_one", TestPageKinds.STATIC, "act.one", 1)
                        .successValue()

                val watched =
                    fixture.request(
                        "page.watch",
                        WatchPageRequest(pageId = page.pageId),
                        WatchPageRequest.serializer,
                        WatchPageResponse.serializer,
                    )

                watched shouldBe WatchPageResponse.InitialWrapper(page)
            }
        }
    }

    test("page resource watch rejects wrong tables and missing pages") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "page.watch",
                        WatchPageRequest(pageId = recordId("tag", "wrong")),
                        WatchPageRequest.serializer,
                        WatchPageResponse.serializer,
                    )
                val missingId = recordId("page", "missing")
                val missing =
                    fixture.request(
                        "page.watch",
                        WatchPageRequest(pageId = missingId),
                        WatchPageRequest.serializer,
                        WatchPageResponse.serializer,
                    )

                invalid.kind shouldBe WatchPageResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe WatchPageResponse.createPageNotFoundError(pageId = missingId)
            }
        }
    }
}
