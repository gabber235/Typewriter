package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.WatchBookRequest
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooksRequest
import skirout.library.v1.book.WatchBooksResponse

val BookRoutesTest by testSuite {
    test("book read watches return persisted resources") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("book_one", "Book", Color(argb = 0), emptyList())
                        .successValue()

                val books =
                    fixture.request(
                        "book.watch",
                        WatchBooksRequest(),
                        WatchBooksRequest.serializer,
                        WatchBooksResponse.serializer,
                    )
                val resource =
                    fixture.request(
                        "book.resource.watch",
                        WatchBookRequest(bookId = book.bookId),
                        WatchBookRequest.serializer,
                        WatchBookResponse.serializer,
                    )

                books shouldBe WatchBooksResponse.ListWrapper(listOf(book))
                resource shouldBe WatchBookResponse.InitialWrapper(book)
            }
        }
    }

    test("book resource watch rejects wrong tables and missing records") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "book.resource.watch",
                        WatchBookRequest(bookId = recordId("tag", "wrong")),
                        WatchBookRequest.serializer,
                        WatchBookResponse.serializer,
                    )
                val missingId = recordId("book", "missing")
                val missing =
                    fixture.request(
                        "book.resource.watch",
                        WatchBookRequest(bookId = missingId),
                        WatchBookRequest.serializer,
                        WatchBookResponse.serializer,
                    )

                invalid.kind shouldBe WatchBookResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe WatchBookResponse.createBookNotFoundError(bookId = missingId)
            }
        }
    }
}
