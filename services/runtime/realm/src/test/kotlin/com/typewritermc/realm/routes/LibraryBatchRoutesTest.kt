package com.typewritermc.realm.routes

import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v2.authoring.BookUpdate
import skirout.library.v2.authoring.CreateBooksRequest
import skirout.library.v2.authoring.CreateBooksResponse
import skirout.library.v2.authoring.CreatePagesRequest
import skirout.library.v2.authoring.CreatePagesResponse
import skirout.library.v2.authoring.PageCreate
import skirout.library.v2.authoring.UpdateBooksRequest
import skirout.library.v2.authoring.UpdateBooksResponse

val LibraryBatchRoutesTest by testSuite {
    test("empty library batches return typed invalid responses") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "book.create.v2",
                        CreateBooksRequest(batchId = "empty_books", books = emptyList()),
                        CreateBooksRequest.serializer,
                        CreateBooksResponse.serializer,
                    )

                response shouldBe
                    CreateBooksResponse.InvalidWrapper(
                        listOf("Create books batches must not be empty."),
                    )
            }
        }
    }

    test("page creation rejects kinds absent from the current catalog") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("kind_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val response =
                    fixture.request(
                        "page.create.v2",
                        CreatePagesRequest(
                            batchId = "unknown_page_kind",
                            pages =
                                listOf(
                                    PageCreate(
                                        id = recordId("page", "40000000000000000000000000000001"),
                                        book = book.bookId,
                                        name = "page",
                                        kind = TestPageKinds.UNKNOWN,
                                        chapter = "",
                                        priority = 0,
                                    ),
                                ),
                        ),
                        CreatePagesRequest.serializer,
                        CreatePagesResponse.serializer,
                    )

                response shouldBe
                    CreatePagesResponse.InvalidWrapper(
                        listOf("Unknown page kind: ${TestPageKinds.UNKNOWN.id}"),
                    )
            }
        }
    }

    test("book conflicts include canonical server state") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("conflict_book", "book", Color(argb = 0), emptyList())
                        .successValue()

                val response =
                    fixture.request(
                        "book.update.v2",
                        UpdateBooksRequest(
                            batchId = "typed_book_conflict",
                            books =
                                listOf(
                                    BookUpdate(
                                        id = book.bookId,
                                        expectedRevision = 2,
                                        title = "changed",
                                        icon = book.icon,
                                        color = book.color,
                                        tags = book.tagIds,
                                    ),
                                ),
                        ),
                        UpdateBooksRequest.serializer,
                        UpdateBooksResponse.serializer,
                    )

                val conflict = (response as UpdateBooksResponse.ConflictWrapper).value.single()
                conflict.id shouldBe book.bookId
                conflict.expectedRevision shouldBe 2
                conflict.actual?.let {
                    it.revision shouldBe 1
                    it.title shouldBe "conflict_book"
                }
            }
        }
    }
}
