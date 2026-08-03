package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.page.ChangePagesChaptersRequest
import skirout.library.v1.page.ChangePagesChaptersResponse
import skirout.library.v1.page.CreatePageRequest
import skirout.library.v1.page.CreatePageResponse
import skirout.library.v1.page.DeletePageRequest
import skirout.library.v1.page.DeletePageResponse
import skirout.library.v1.page.PageType
import skirout.library.v1.page.SearchPagesRequest
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.UpdatePageRequest
import skirout.library.v1.page.UpdatePageResponse
import skirout.library.v1.page.WatchPageRequest
import skirout.library.v1.page.WatchPageResponse

val PageRoutesTest by testSuite {
    test("page search classifies invalid book identifiers and missing books") {
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

    test("page search supports filtering, empty search, book isolation, and empty results") {
        runTest {
            RouteFixture().use { fixture ->
                val firstBook =
                    fixture.repositories.books
                        .createBook("first_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val secondBook =
                    fixture.repositories.books
                        .createBook("second_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            firstBook.bookId,
                            "opening_scene",
                            PageType.SCENE,
                            "",
                            0,
                        ).successValue()
                fixture.repositories.pages
                    .createPage(
                        secondBook.bookId,
                        "opening_scene",
                        PageType.SCENE,
                        "",
                        0,
                    ).successValue()

                val filtered =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = firstBook.bookId, search = "OPENING"),
                        SearchPagesRequest.serializer,
                        SearchPagesResponse.serializer,
                    )
                val blank =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = firstBook.bookId, search = " "),
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
                blank shouldBe SearchPagesResponse.SuccessWrapper(listOf(page))
                empty shouldBe SearchPagesResponse.SuccessWrapper(emptyList())
            }
        }
    }

    test("page creation classifies invalid book identifiers and missing books") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = recordId("tag", "wrong"),
                            name = "page_name",
                            type = PageType.STATIC,
                            chapter = null,
                            priority = null,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )
                val missing =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = recordId("book", "missing"),
                            name = "page_name",
                            type = PageType.STATIC,
                            chapter = null,
                            priority = null,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )

                invalid.kind shouldBe CreatePageResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing.kind shouldBe CreatePageResponse.Kind.BOOK_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("page creation persists the page and publishes its resource update") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()

                val response =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = book.bookId,
                            name = "page_one",
                            type = PageType.STATIC,
                            chapter = "act.one",
                            priority = 1,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )

                response.kind shouldBe CreatePageResponse.Kind.SUCCESS_WRAPPER
                val page =
                    fixture.repositories.pages
                        .searchPages(book.bookId, null)
                        .single()
                page.name shouldBe "page_one"
                fixture.publishedTo("page.watch", WatchPageResponse.serializer) shouldContainExactly
                    listOf(WatchPageResponse.UpdateWrapper(page))
            }
        }
    }

    test("page creation applies default chapter and priority") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("default_book", "book", Color(argb = 0), emptyList())
                        .successValue()

                val response =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = book.bookId,
                            name = "default_page",
                            type = PageType.SEQUENCE,
                            chapter = null,
                            priority = null,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )

                val page =
                    fixture.repositories.pages
                        .searchPages(book.bookId, null)
                        .single()
                response shouldBe CreatePageResponse.SuccessWrapper(page)
                page.chapter shouldBe ""
                page.priority shouldBe 0
                page.bookId shouldBe book.bookId
            }
        }
    }

    test("page creation classifies blank names and unknown types without mutation") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("stable_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val blankName =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = book.bookId,
                            name = " ",
                            type = PageType.STATIC,
                            chapter = null,
                            priority = null,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )
                val unknownType =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = book.bookId,
                            name = "valid_page",
                            type = PageType.UNKNOWN,
                            chapter = null,
                            priority = null,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )

                blankName.kind shouldBe CreatePageResponse.Kind.VALIDATION_ERROR_WRAPPER
                unknownType.kind shouldBe CreatePageResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.repositories.pages.searchPages(book.bookId, null) shouldBe emptyList()
                fixture.publishedTo("page.watch") shouldBe emptyList()
            }
        }
    }

    test("page search and resource watch return persisted pages") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "page_one",
                            PageType.STATIC,
                            "act.one",
                            1,
                        ).successValue()

                val searched =
                    fixture.request(
                        "page.search",
                        SearchPagesRequest(bookId = book.bookId, search = "page"),
                        SearchPagesRequest.serializer,
                        SearchPagesResponse.serializer,
                    )
                val watched =
                    fixture.request(
                        "page.watch",
                        WatchPageRequest(pageId = page.pageId),
                        WatchPageRequest.serializer,
                        WatchPageResponse.serializer,
                    )

                searched.kind shouldBe SearchPagesResponse.Kind.SUCCESS_WRAPPER
                watched.kind shouldBe WatchPageResponse.Kind.INITIAL_WRAPPER
            }
        }
    }

    test("page resource watch classifies invalid and missing identifiers") {
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

    test("page updates persist changes and publish the resource update") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "page_one",
                            PageType.STATIC,
                            "act.one",
                            1,
                        ).successValue()

                val response =
                    fixture.request(
                        "page.update",
                        UpdatePageRequest(
                            pageId = page.pageId,
                            name = "page_two",
                            type = PageType.SCENE,
                            chapter = null,
                            priority = 2,
                        ),
                        UpdatePageRequest.serializer,
                        UpdatePageResponse.serializer,
                    )

                response.kind shouldBe UpdatePageResponse.Kind.SUCCESS_WRAPPER
                val persisted = fixture.repositories.pages.getPage(page.pageId) ?: error("Page was not persisted")
                persisted.name shouldBe "page_two"
                fixture.publishedTo("page.watch", WatchPageResponse.serializer) shouldContainExactly
                    listOf(WatchPageResponse.UpdateWrapper(persisted))
            }
        }
    }

    test("page updates preserve omitted fields") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("stable_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "stable_page",
                            PageType.SCENE,
                            "act.one",
                            7,
                        ).successValue()

                val response =
                    fixture.request(
                        "page.update",
                        UpdatePageRequest(
                            pageId = page.pageId,
                            name = null,
                            type = null,
                            chapter = null,
                            priority = null,
                        ),
                        UpdatePageRequest.serializer,
                        UpdatePageResponse.serializer,
                    )

                response shouldBe UpdatePageResponse.SuccessWrapper(page)
                fixture.repositories.pages.getPage(page.pageId) shouldBe page
            }
        }
    }

    test("page update validation leaves the persisted page unchanged") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("stable_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "stable_page",
                            PageType.SCENE,
                            "act.one",
                            7,
                        ).successValue()
                val blankName =
                    fixture.request(
                        "page.update",
                        UpdatePageRequest(
                            pageId = page.pageId,
                            name = " ",
                            type = null,
                            chapter = null,
                            priority = null,
                        ),
                        UpdatePageRequest.serializer,
                        UpdatePageResponse.serializer,
                    )
                val unknownType =
                    fixture.request(
                        "page.update",
                        UpdatePageRequest(
                            pageId = page.pageId,
                            name = null,
                            type = PageType.UNKNOWN,
                            chapter = null,
                            priority = null,
                        ),
                        UpdatePageRequest.serializer,
                        UpdatePageResponse.serializer,
                    )

                blankName.kind shouldBe UpdatePageResponse.Kind.VALIDATION_ERROR_WRAPPER
                unknownType.kind shouldBe UpdatePageResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.repositories.pages.getPage(page.pageId) shouldBe page
                fixture.publishedTo("page.watch") shouldBe emptyList()
            }
        }
    }

    test("chapter changes update matching pages and publish each resource") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()
                fixture.repositories.pages
                    .createPage(book.bookId, "one", PageType.STATIC, "act.one", 1)
                    .successValue()
                fixture.repositories.pages
                    .createPage(book.bookId, "two", PageType.SCENE, "act.one.deep", 2)
                    .successValue()

                val response =
                    fixture.request(
                        "pages.chapters",
                        ChangePagesChaptersRequest(
                            bookId = book.bookId,
                            oldChapter = "act.one",
                            newChapter = "act.two",
                        ),
                        ChangePagesChaptersRequest.serializer,
                        ChangePagesChaptersResponse.serializer,
                    )

                response.kind shouldBe ChangePagesChaptersResponse.Kind.SUCCESS_WRAPPER
                fixture.repositories.pages
                    .searchPages(book.bookId, null)
                    .map { it.chapter }
                    .toSet() shouldBe
                    setOf("act.two", "act.two.deep")
                val updated = fixture.repositories.pages.searchPages(book.bookId, null)
                fixture.publishedTo("page.watch", WatchPageResponse.serializer).toSet() shouldBe
                    updated.map { WatchPageResponse.UpdateWrapper(it) }.toSet()
            }
        }
    }

    test("chapter changes classify invalid book identifiers") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "pages.chapters",
                        ChangePagesChaptersRequest(
                            bookId = recordId("tag", "wrong"),
                            oldChapter = "old",
                            newChapter = "new",
                        ),
                        ChangePagesChaptersRequest.serializer,
                        ChangePagesChaptersResponse.serializer,
                    )

                response.kind shouldBe ChangePagesChaptersResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
            }
        }
    }

    test("chapter changes with no matches report zero changes and publish nothing") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("stable_book", "book", Color(argb = 0), emptyList())
                        .successValue()

                val response =
                    fixture.request(
                        "pages.chapters",
                        ChangePagesChaptersRequest(
                            bookId = book.bookId,
                            oldChapter = "missing",
                            newChapter = "changed",
                        ),
                        ChangePagesChaptersRequest.serializer,
                        ChangePagesChaptersResponse.serializer,
                    )

                response shouldBe ChangePagesChaptersResponse.createSuccess(updatedCount = 0)
                fixture.publishedTo("page.watch") shouldBe emptyList()
            }
        }
    }

    test("chapter changes support empty source and destination chapters") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("chapter_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val ungrouped =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "ungrouped_page",
                            PageType.STATIC,
                            "",
                            0,
                        ).successValue()
                val nested =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "nested_page",
                            PageType.STATIC,
                            "act.one.deep",
                            0,
                        ).successValue()

                val fromEmpty =
                    fixture.request(
                        "pages.chapters",
                        ChangePagesChaptersRequest(
                            bookId = book.bookId,
                            oldChapter = "",
                            newChapter = "prologue",
                        ),
                        ChangePagesChaptersRequest.serializer,
                        ChangePagesChaptersResponse.serializer,
                    )
                val toEmpty =
                    fixture.request(
                        "pages.chapters",
                        ChangePagesChaptersRequest(
                            bookId = book.bookId,
                            oldChapter = "act.one",
                            newChapter = "",
                        ),
                        ChangePagesChaptersRequest.serializer,
                        ChangePagesChaptersResponse.serializer,
                    )

                fromEmpty shouldBe ChangePagesChaptersResponse.createSuccess(updatedCount = 1)
                toEmpty shouldBe ChangePagesChaptersResponse.createSuccess(updatedCount = 1)
                fixture.repositories.pages
                    .getPage(ungrouped.pageId)
                    ?.chapter shouldBe "prologue"
                fixture.repositories.pages
                    .getPage(nested.pageId)
                    ?.chapter shouldBe "deep"
                fixture.publishedTo("page.watch", WatchPageResponse.serializer) shouldHaveSize 2
            }
        }
    }

    test("page deletion removes the page and publishes its removal") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            emptyList(),
                        ).successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(
                            book.bookId,
                            "page_one",
                            PageType.STATIC,
                            "act.one",
                            1,
                        ).successValue()

                val response =
                    fixture.request(
                        "page.delete",
                        DeletePageRequest(pageId = page.pageId),
                        DeletePageRequest.serializer,
                        DeletePageResponse.serializer,
                    )

                response.kind shouldBe DeletePageResponse.Kind.SUCCESS_WRAPPER
                fixture.repositories.pages
                    .getPage(page.pageId)
                    .shouldBeNull()
                fixture.publishedTo("page.watch", WatchPageResponse.serializer) shouldContainExactly
                    listOf(WatchPageResponse.RemoveWrapper(page.pageId))
            }
        }
    }

    test("page deletion classifies invalid identifiers") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "page.delete",
                        DeletePageRequest(pageId = recordId("tag", "wrong")),
                        DeletePageRequest.serializer,
                        DeletePageResponse.serializer,
                    )

                response.kind shouldBe DeletePageResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.publishedTo("page.watch") shouldBe emptyList()
            }
        }
    }

    test("page publication failure remains observable after the page is committed") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("committed_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                fixture.transport.failNextPublish(
                    com.typewritermc.services.libs.communicator.transport.TransportError
                        .Unavailable(),
                )

                val response =
                    fixture.request(
                        "page.create",
                        CreatePageRequest(
                            bookId = book.bookId,
                            name = "committed_page",
                            type = PageType.STATIC,
                            chapter = null,
                            priority = null,
                        ),
                        CreatePageRequest.serializer,
                        CreatePageResponse.serializer,
                    )

                response.kind shouldBe CreatePageResponse.Kind.INTERNAL_ERROR_WRAPPER
                fixture.repositories.pages
                    .searchPages(book.bookId, null)
                    .single()
                    .name shouldBe "committed_page"
            }
        }
    }

    test("page mutations classify invalid identifiers and missing resources") {
        runTest {
            RouteFixture().use { fixture ->
                val invalidUpdate =
                    fixture.request(
                        "page.update",
                        UpdatePageRequest(
                            pageId = recordId("tag", "wrong"),
                            name = null,
                            type = null,
                            chapter = null,
                            priority = null,
                        ),
                        UpdatePageRequest.serializer,
                        UpdatePageResponse.serializer,
                    )
                val missingUpdate =
                    fixture.request(
                        "page.update",
                        UpdatePageRequest(
                            pageId = recordId("page", "missing"),
                            name = null,
                            type = null,
                            chapter = null,
                            priority = null,
                        ),
                        UpdatePageRequest.serializer,
                        UpdatePageResponse.serializer,
                    )
                val missingDelete =
                    fixture.request(
                        "page.delete",
                        DeletePageRequest(pageId = recordId("page", "missing")),
                        DeletePageRequest.serializer,
                        DeletePageResponse.serializer,
                    )
                val missingBook =
                    fixture.request(
                        "pages.chapters",
                        ChangePagesChaptersRequest(
                            bookId = recordId("book", "missing"),
                            oldChapter = "old",
                            newChapter = "new",
                        ),
                        ChangePagesChaptersRequest.serializer,
                        ChangePagesChaptersResponse.serializer,
                    )

                invalidUpdate.kind shouldBe UpdatePageResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missingUpdate.kind shouldBe UpdatePageResponse.Kind.PAGE_NOT_FOUND_ERROR_WRAPPER
                missingDelete.kind shouldBe DeletePageResponse.Kind.PAGE_NOT_FOUND_ERROR_WRAPPER
                missingBook.kind shouldBe ChangePagesChaptersResponse.Kind.BOOK_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }
}
