package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import com.typewritermc.services.libs.communicator.transport.TransportError
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.Book
import skirout.library.v1.book.CreateBookRequest
import skirout.library.v1.book.CreateBookResponse
import skirout.library.v1.book.UpdateBookRequest
import skirout.library.v1.book.UpdateBookResponse
import skirout.library.v1.book.WatchBookRequest
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooksRequest
import skirout.library.v1.book.WatchBooksResponse

val BookRoutesTest by testSuite {
    test("book collection watch returns an empty initial state") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "book.watch",
                        WatchBooksRequest(),
                        WatchBooksRequest.serializer,
                        WatchBooksResponse.serializer,
                    )

                response shouldBe WatchBooksResponse.ListWrapper(emptyList())
            }
        }
    }

    test("book collection watch returns the persisted initial state") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.transport.activeSubscriptionCount shouldBe 17
                val book =
                    fixture.repositories.books
                        .createBook(
                            "first_book",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()

                val response =
                    fixture.request(
                        "book.watch",
                        WatchBooksRequest(),
                        WatchBooksRequest.serializer,
                        WatchBooksResponse.serializer,
                    )

                response shouldBe WatchBooksResponse.ListWrapper(listOf(book))
            }
        }
    }

    test("book creation rejects a blank title") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(title = " ", icon = null, color = null, tagIds = emptyList()),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )

                response.kind shouldBe CreateBookResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.repositories.books.listBooks() shouldBe emptyList()
            }
        }
    }

    test("book creation applies defaults and publishes the collection update") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(title = "display_title", icon = null, color = null, tagIds = emptyList()),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )

                response.kind shouldBe CreateBookResponse.Kind.SUCCESS_WRAPPER
                val book =
                    fixture.repositories.books
                        .listBooks()
                        .single()
                book.title shouldBe "display_title"
                book.icon shouldBe "book"
                book.color shouldBe Color(argb = 0)
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.AddWrapper(book))
            }
        }
    }

    test("book resource watch classifies invalid and missing identifiers") {
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

    test("book creation preserves explicit fields and tags and publishes the exact addition") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "featured_tag",
                            Color(argb = 1),
                            emptyList(),
                            skirout.library.v1.tag
                                .Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val response =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(
                            title = "explicit_book",
                            icon = "diamond",
                            color = Color(argb = 2),
                            tagIds = listOf(tag.tagId),
                        ),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )

                val book =
                    fixture.repositories.books
                        .listBooks()
                        .single()
                response shouldBe CreateBookResponse.SuccessWrapper(book)
                book.icon shouldBe "diamond"
                book.color shouldBe Color(argb = 2)
                book.tagIds shouldContainExactly listOf(tag.tagId)
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.AddWrapper(book))
            }
        }
    }

    test("book creation classifies invalid and missing tag identifiers") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(
                            title = "invalid_tags_book",
                            icon = null,
                            color = null,
                            tagIds = listOf(recordId("page", "wrong")),
                        ),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )
                val missingId = recordId("tag", "missing")
                val missing =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(
                            title = "missing_tags_book",
                            icon = null,
                            color = null,
                            tagIds = listOf(missingId),
                        ),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )

                invalid.kind shouldBe CreateBookResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe CreateBookResponse.createTagsNotFoundError(tagIds = listOf(missingId))
                fixture.repositories.books.listBooks() shouldBe emptyList()
                fixture.publishedTo("book.watch") shouldBe emptyList()
            }
        }
    }

    test("book creation treats a blank optional icon as the default") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.request(
                    "book.create",
                    CreateBookRequest(title = "default_icon_book", icon = " ", color = null, tagIds = emptyList()),
                    CreateBookRequest.serializer,
                    CreateBookResponse.serializer,
                )

                fixture.repositories.books
                    .listBooks()
                    .single()
                    .icon shouldBe "book"
            }
        }
    }

    test("book resource watch and update publish both update channels") {
        runTest {
            RouteFixture().use { fixture ->
                val original =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()
                val watched =
                    fixture.request(
                        "book.resource.watch",
                        WatchBookRequest(bookId = original.bookId),
                        WatchBookRequest.serializer,
                        WatchBookResponse.serializer,
                    )

                val updated =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = original.bookId,
                            title = "updated_book",
                            icon = null,
                            color = null,
                            tagIds = null,
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                watched.kind shouldBe WatchBookResponse.Kind.INITIAL_WRAPPER
                updated.kind shouldBe UpdateBookResponse.Kind.SUCCESS_WRAPPER
                fixture.repositories.books
                    .getBook(original.bookId)
                    ?.title shouldBe "updated_book"
                val persisted = fixture.repositories.books.getBook(original.bookId) ?: error("Book was not persisted")
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.UpdateWrapper(persisted))
                fixture.publishedTo("book.resource.watch", WatchBookResponse.serializer) shouldContainExactly
                    listOf(WatchBookResponse.UpdateWrapper(persisted))
            }
        }
    }

    test("book updates preserve omitted fields") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            skirout.library.v1.tag
                                .Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.repositories.books
                        .createBook(
                            "stable_book",
                            "diamond",
                            Color(argb = 2),
                            listOf(tag.tagId),
                        ).successValue()

                val response =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            title = null,
                            icon = null,
                            color = null,
                            tagIds = null,
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                response shouldBe UpdateBookResponse.SuccessWrapper(book)
                fixture.repositories.books.getBook(book.bookId) shouldBe book
            }
        }
    }

    test("book updates reconcile tags and publish the exact persisted book") {
        runTest {
            RouteFixture().use { fixture ->
                val firstTag =
                    fixture.repositories.tags
                        .createTag(
                            "first_tag",
                            Color(argb = 1),
                            emptyList(),
                            skirout.library.v1.tag
                                .Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val secondTag =
                    fixture.repositories.tags
                        .createTag(
                            "second_tag",
                            Color(argb = 2),
                            emptyList(),
                            skirout.library.v1.tag
                                .Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.repositories.books
                        .createBook(
                            "changing_book",
                            "book",
                            Color(argb = 3),
                            listOf(firstTag.tagId),
                        ).successValue()

                val response =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            title = null,
                            icon = null,
                            color = null,
                            tagIds = listOf(secondTag.tagId),
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                val updated = fixture.repositories.books.getBook(book.bookId) ?: error("Book was not persisted")
                response shouldBe UpdateBookResponse.SuccessWrapper(updated)
                updated.tagIds shouldContainExactly listOf(secondTag.tagId)
                fixture.publishedTo("book.watch", WatchBooksResponse.serializer) shouldContainExactly
                    listOf(WatchBooksResponse.UpdateWrapper(updated))
                fixture.publishedTo("book.resource.watch", WatchBookResponse.serializer) shouldContainExactly
                    listOf(WatchBookResponse.UpdateWrapper(updated))
            }
        }
    }

    test("book update validation leaves the persisted book unchanged") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook(
                            "stable_book",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()
                val blankTitle =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(bookId = book.bookId, title = " ", icon = null, color = null, tagIds = null),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )
                val blankIcon =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(bookId = book.bookId, title = null, icon = " ", color = null, tagIds = null),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )
                val invalidTags =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            title = null,
                            icon = null,
                            color = null,
                            tagIds = listOf(recordId("page", "wrong")),
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )
                val missingTagId = recordId("tag", "missing")
                val missingTags =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = book.bookId,
                            title = null,
                            icon = null,
                            color = null,
                            tagIds = listOf(missingTagId),
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                blankTitle.kind shouldBe UpdateBookResponse.Kind.VALIDATION_ERROR_WRAPPER
                blankIcon.kind shouldBe UpdateBookResponse.Kind.VALIDATION_ERROR_WRAPPER
                invalidTags.kind shouldBe UpdateBookResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missingTags shouldBe UpdateBookResponse.createTagsNotFoundError(tagIds = listOf(missingTagId))
                fixture.repositories.books.getBook(book.bookId) shouldBe book
                fixture.publishedTo("book.watch") shouldBe emptyList()
                fixture.publishedTo("book.resource.watch") shouldBe emptyList()
            }
        }
    }

    test("book updates classify invalid identifiers and missing books") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = recordId("tag", "wrong"),
                            title = null,
                            icon = null,
                            color = null,
                            tagIds = null,
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )
                val missing =
                    fixture.request(
                        "book.update",
                        UpdateBookRequest(
                            bookId = recordId("book", "missing"),
                            title = null,
                            icon = null,
                            color = null,
                            tagIds = null,
                        ),
                        UpdateBookRequest.serializer,
                        UpdateBookResponse.serializer,
                    )

                invalid.kind shouldBe UpdateBookResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing.kind shouldBe UpdateBookResponse.Kind.BOOK_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("publication failure remains observable after the book is committed") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.transport.failNextPublish(TransportError.Unavailable())

                val response =
                    fixture.request(
                        "book.create",
                        CreateBookRequest(title = "committed_book", icon = null, color = null, tagIds = emptyList()),
                        CreateBookRequest.serializer,
                        CreateBookResponse.serializer,
                    )

                response.kind shouldBe CreateBookResponse.Kind.INTERNAL_ERROR_WRAPPER
                fixture.repositories.books
                    .listBooks()
                    .map(Book::title) shouldContainExactly listOf("committed_book")
            }
        }
    }

    test("unexpected book repository failures become typed internal responses") {
        runTest {
            RouteFixture { delegate ->
                object : BookRepository by delegate {
                    override suspend fun listBooks(): List<Book> = error("Book listing failed")
                }
            }.use { fixture ->
                val response =
                    fixture.request(
                        "book.watch",
                        WatchBooksRequest(),
                        WatchBooksRequest.serializer,
                        WatchBooksResponse.serializer,
                    )

                response.kind shouldBe WatchBooksResponse.Kind.INTERNAL_ERROR_WRAPPER
            }
        }
    }
}
