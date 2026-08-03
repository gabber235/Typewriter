package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType

val PageRepositoryTest by testSuite {
    test("page listing is ordered by priority and name") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("ordered_book", "book", Color(argb = 0), emptyList()).successValue()
                fixture.pages.createPage(book.bookId, "zulu_page", PageType.STATIC, "", 2).successValue()
                fixture.pages.createPage(book.bookId, "bravo_page", PageType.STATIC, "", 1).successValue()
                fixture.pages.createPage(book.bookId, "alpha_page", PageType.STATIC, "", 1).successValue()

                fixture.pages.searchPages(book.bookId, null).map(Page::name) shouldContainExactly
                    listOf("alpha_page", "bravo_page", "zulu_page")
            }
        }
    }

    test("page listing and search remain isolated to one book") {
        runTest {
            RepositoryFixture().use { fixture ->
                val firstBook =
                    fixture.books
                        .createBook("first_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val secondBook =
                    fixture.books
                        .createBook("second_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val firstPage =
                    fixture.pages
                        .createPage(
                            firstBook.bookId,
                            "shared_page",
                            PageType.STATIC,
                            "",
                            0,
                        ).successValue()
                fixture.pages.createPage(secondBook.bookId, "shared_page", PageType.STATIC, "", 0).successValue()

                fixture.pages.searchPages(firstBook.bookId, null) shouldContainExactly listOf(firstPage)
                fixture.pages.searchPages(firstBook.bookId, "shared") shouldContainExactly listOf(firstPage)
            }
        }
    }

    test("page search is case insensitive and returns empty results for no match") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("search_book", "book", Color(argb = 0), emptyList()).successValue()
                val page =
                    fixture.pages
                        .createPage(book.bookId, "opening_scene", PageType.SCENE, "", 0)
                        .successValue()

                fixture.pages.searchPages(book.bookId, "OPENING") shouldContainExactly listOf(page)
                fixture.pages.searchPages(book.bookId, "scene") shouldContainExactly listOf(page)
                fixture.pages.searchPages(book.bookId, "missing") shouldBe emptyList()
            }
        }
    }

    test("page creation supports search and retrieval") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("quest_book", "book", Color(argb = 3), emptyList()).successValue()
                val page =
                    fixture.pages
                        .createPage(book.bookId, "opening_scene", PageType.SCENE, "act.one", 1)
                        .successValue()

                page.bookId shouldBe book.bookId
                fixture.pages.searchPages(book.bookId, "opening") shouldContainExactly listOf(page)
                fixture.pages.getPage(page.pageId) shouldBe page
            }
        }
    }

    test("page updates preserve identity and replace editable fields") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("quest_book", "book", Color(argb = 3), emptyList()).successValue()
                val page =
                    fixture.pages
                        .createPage(book.bookId, "opening_scene", PageType.SCENE, "act.one", 1)
                        .successValue()

                val updated =
                    fixture.pages
                        .updatePage(
                            Page(
                                pageId = page.pageId,
                                bookId = page.bookId,
                                name = "opening_sequence",
                                type = PageType.SEQUENCE,
                                chapter = page.chapter,
                                priority = 9,
                            ),
                        ).successValue()

                fixture.pages.getPage(page.pageId) shouldBe updated
            }
        }
    }

    test("chapter changes update exact and nested chapter paths") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("quest_book", "book", Color(argb = 3), emptyList()).successValue()
                fixture.pages.createPage(book.bookId, "opening_scene", PageType.SCENE, "act.one", 1).successValue()
                fixture.pages
                    .createPage(book.bookId, "second_scene", PageType.SEQUENCE, "act.one.deep", 2)
                    .successValue()

                fixture.pages
                    .changePagesChapters(book.bookId, "act.one", "act.two")
                    .successValue()
                    .map(Page::chapter) shouldContainExactlyInAnyOrder listOf("act.two", "act.two.deep")
            }
        }
    }

    test("page deletion removes existing pages and reports missing pages") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("quest_book", "book", Color(argb = 3), emptyList()).successValue()
                val page =
                    fixture.pages
                        .createPage(book.bookId, "opening_scene", PageType.SCENE, "act.one", 1)
                        .successValue()

                fixture.pages.deletePage(page.pageId).successValue()

                fixture.pages.getPage(page.pageId).shouldBeNull()
                fixture.pages.deletePage(page.pageId).failureSlug() shouldBe "page-not-found-error"
            }
        }
    }

    test("page creation rejects missing book references") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.pages
                    .createPage(recordId("book", "missing"), "page_name", PageType.STATIC, "", 0)
                    .failureSlug() shouldBe "book-not-found-error"
            }
        }
    }

    test("missing page retrieval returns null") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.pages.getPage(recordId("page", "missing")).shouldBeNull()
            }
        }
    }

    test("page creation generates unique identifiers and preserves every page type") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("typed_book", "book", Color(argb = 0), emptyList()).successValue()
                val types = listOf(PageType.SEQUENCE, PageType.SCENE, PageType.MANIFEST, PageType.STATIC)
                val pages =
                    types.mapIndexed { index, type ->
                        fixture.pages.createPage(book.bookId, "typed_page_$index", type, "", index).successValue()
                    }

                pages.map(Page::pageId).distinct().size shouldBe types.size
                pages.map(Page::type) shouldContainExactly types
            }
        }
    }

    test("page update preserves the original book association") {
        runTest {
            RepositoryFixture().use { fixture ->
                val originalBook =
                    fixture.books
                        .createBook("original_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val otherBook =
                    fixture.books
                        .createBook("other_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.pages
                        .createPage(originalBook.bookId, "stable_page", PageType.STATIC, "", 0)
                        .successValue()

                val updated =
                    fixture.pages
                        .updatePage(
                            page.copy(bookId = otherBook.bookId, name = "updated_page"),
                        ).successValue()

                updated.bookId shouldBe originalBook.bookId
                fixture.pages.getPage(page.pageId)?.bookId shouldBe originalBook.bookId
            }
        }
    }

    test("page update reports a missing page") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.pages
                    .updatePage(
                        Page(
                            pageId = recordId("page", "missing"),
                            bookId = recordId("book", "missing"),
                            name = "missing_page",
                            type = PageType.STATIC,
                            chapter = "",
                            priority = 0,
                        ),
                    ).failureSlug() shouldBe "page-not-found-error"
            }
        }
    }

    test("page creation rejects invalid name variants without persisting records") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("valid_book", "book", Color(argb = 0), emptyList()).successValue()

                listOf("ab", "Upper", "has space", "has-dash", "ümlaut", "_leading", "trailing_").forEach { name ->
                    fixture.pages.createPage(book.bookId, name, PageType.STATIC, "", 0).failureSlug() shouldBe
                        "page-name-invalid-error"
                }

                fixture.pages.searchPages(book.bookId, null) shouldBe emptyList()
            }
        }
    }

    test("page creation rejects invalid chapter variants without persisting records") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("valid_book", "book", Color(argb = 0), emptyList()).successValue()

                listOf("Upper", ".leading", "trailing.", "_leading", "trailing_", "has space").forEachIndexed {
                    index,
                    chapter,
                    ->
                    fixture.pages
                        .createPage(book.bookId, "valid_page_$index", PageType.STATIC, chapter, 0)
                        .failureSlug() shouldBe "page-chapter-invalid-error"
                }

                fixture.pages.searchPages(book.bookId, null) shouldBe emptyList()
            }
        }
    }

    test("page creation rejects unknown page types without persisting records") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("valid_book", "book", Color(argb = 0), emptyList()).successValue()

                shouldThrow<IllegalStateException> {
                    fixture.pages.createPage(book.bookId, "valid_page", PageType.UNKNOWN, "", 0)
                }

                fixture.pages.searchPages(book.bookId, null) shouldBe emptyList()
            }
        }
    }

    test("chapter changes leave parent and similar chapter prefixes untouched") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("chapter_book", "book", Color(argb = 0), emptyList()).successValue()
                val parent =
                    fixture.pages
                        .createPage(book.bookId, "parent_page", PageType.STATIC, "act", 0)
                        .successValue()
                val similar =
                    fixture.pages
                        .createPage(book.bookId, "similar_page", PageType.STATIC, "act.onerous", 0)
                        .successValue()
                val exact =
                    fixture.pages
                        .createPage(book.bookId, "exact_page", PageType.STATIC, "act.one", 0)
                        .successValue()

                fixture.pages.changePagesChapters(book.bookId, "act.one", "act.two").successValue()

                fixture.pages.getPage(parent.pageId)?.chapter shouldBe "act"
                fixture.pages.getPage(similar.pageId)?.chapter shouldBe "act.onerous"
                fixture.pages.getPage(exact.pageId)?.chapter shouldBe "act.two"
            }
        }
    }

    test("chapter changes remain isolated to one book and report zero matches") {
        runTest {
            RepositoryFixture().use { fixture ->
                val firstBook =
                    fixture.books
                        .createBook("first_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val secondBook =
                    fixture.books
                        .createBook("second_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val secondPage =
                    fixture.pages
                        .createPage(
                            secondBook.bookId,
                            "second_page",
                            PageType.STATIC,
                            "act.one",
                            0,
                        ).successValue()

                fixture.pages.changePagesChapters(firstBook.bookId, "missing", "changed").successValue() shouldBe
                    emptyList()
                fixture.pages.changePagesChapters(firstBook.bookId, "act.one", "act.two").successValue() shouldBe
                    emptyList()
                fixture.pages.getPage(secondPage.pageId)?.chapter shouldBe "act.one"
            }
        }
    }

    test("chapter changes support empty source and destination chapters") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("chapter_book", "book", Color(argb = 0), emptyList()).successValue()
                val ungrouped =
                    fixture.pages
                        .createPage(book.bookId, "ungrouped_page", PageType.STATIC, "", 0)
                        .successValue()
                val nested =
                    fixture.pages
                        .createPage(book.bookId, "nested_page", PageType.STATIC, "act.one.deep", 0)
                        .successValue()

                fixture.pages.changePagesChapters(book.bookId, "", "prologue").successValue()
                fixture.pages.changePagesChapters(book.bookId, "act.one", "").successValue()

                fixture.pages.getPage(ungrouped.pageId)?.chapter shouldBe "prologue"
                fixture.pages.getPage(nested.pageId)?.chapter shouldBe "deep"
            }
        }
    }

    test("equal chapter changes are a no operation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("chapter_book", "book", Color(argb = 0), emptyList()).successValue()
                val page =
                    fixture.pages
                        .createPage(book.bookId, "stable_page", PageType.STATIC, "act.one", 0)
                        .successValue()

                fixture.pages.changePagesChapters(book.bookId, "act.one", "act.one").successValue() shouldBe emptyList()
                fixture.pages.getPage(page.pageId) shouldBe page
            }
        }
    }
}
