package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.createTag
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import com.typewritermc.realm.repository.updateBook
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.CreateBookRequest
import skirout.library.v1.book.CreateBookResponse
import skirout.library.v1.book.UpdateBookRequest
import skirout.library.v1.book.UpdateBookResponse
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.tag.Placement

val BookRoutesTest by testSuite {
    test("book creation starts at revision one and applies defaults") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(
                            title = "display_title",
                            icon = null,
                            color = null,
                            tagIds = emptyList(),
                        ),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )

                val book = (response as CreateBookResponse.SuccessWrapper).value
                book.revision shouldBe 1
                book.icon shouldBe "mdi:book"
                book.color shouldBe Color(argb = 0)
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.AddWrapper(book))
            }
        }
    }

    test("book update replaces the complete editable state") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "featured_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.repositories.books
                        .createBook("original_book", "mdi:book", Color(argb = 2), emptyList())
                        .successValue()

                val response =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            expectedRevision = book.revision,
                            title = "updated_book",
                            icon = "mdi:diamond",
                            color = Color(argb = 3),
                            tagIds = listOf(tag.tagId),
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                val updated = (response as UpdateBookResponse.SuccessWrapper).value
                updated.revision shouldBe 2
                updated.title shouldBe "updated_book"
                updated.icon shouldBe "mdi:diamond"
                updated.color shouldBe Color(argb = 3)
                updated.tagIds shouldContainExactly listOf(tag.tagId)
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.UpdateWrapper(updated))
                fixture.publishedTo("book.resource.watch", WatchBookResponse.serializer) shouldContainExactly
                    listOf(WatchBookResponse.UpdateWrapper(updated))
            }
        }
    }

    test("stale book update returns the canonical entity without writing") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("original_book", "mdi:book", Color(argb = 1), emptyList())
                        .successValue()
                val first =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            expectedRevision = book.revision,
                            title = "first_update",
                            icon = book.icon,
                            color = book.color,
                            tagIds = book.tagIds,
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    ) as UpdateBookResponse.SuccessWrapper

                val conflict =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            expectedRevision = book.revision,
                            title = "stale_update",
                            icon = book.icon,
                            color = book.color,
                            tagIds = book.tagIds,
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                conflict shouldBe
                    UpdateBookResponse.createConflictError(
                        expectedRevision = book.revision,
                        actual = first.value,
                    )
                fixture.repositories.books.getBook(book.bookId) shouldBe first.value
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.UpdateWrapper(first.value))
            }
        }
    }

    test("book update validates identifiers and missing tags without mutation") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("stable_book", "mdi:book", Color(argb = 1), emptyList())
                        .successValue()
                val invalid =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            expectedRevision = book.revision,
                            title = book.title,
                            icon = book.icon,
                            color = book.color,
                            tagIds = listOf(recordId("page", "wrong")),
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )
                val missingId = recordId("tag", "missing")
                val missing =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            expectedRevision = book.revision,
                            title = book.title,
                            icon = book.icon,
                            color = book.color,
                            tagIds = listOf(missingId),
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                invalid.kind shouldBe UpdateBookResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe UpdateBookResponse.createTagsNotFoundError(tagIds = listOf(missingId))
                fixture.repositories.books.getBook(book.bookId) shouldBe book
                fixture.publishedTo("book.watch") shouldBe emptyList()
            }
        }
    }
}
