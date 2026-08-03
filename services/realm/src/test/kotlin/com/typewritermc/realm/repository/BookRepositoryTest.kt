package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.Book
import skirout.library.v1.tag.Placement

val BookRepositoryTest by testSuite {
    test("book listing is empty before any books are created") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books.listBooks() shouldBe emptyList()
            }
        }
    }

    test("book listing is ordered by title") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books.createBook("zulu_book", "book", Color(argb = 0), emptyList()).successValue()
                fixture.books.createBook("alpha_book", "book", Color(argb = 0), emptyList()).successValue()

                fixture.books.listBooks().map(Book::title) shouldContainExactly listOf("alpha_book", "zulu_book")
            }
        }
    }

    test("book creation preserves display fields and supports retrieval") {
        runTest {
            RepositoryFixture().use { fixture ->
                val created =
                    fixture.books
                        .createBook(
                            "first_adventure",
                            "menu book",
                            Color(argb = 0xFFAABBCC.toInt()),
                            emptyList(),
                        ).successValue()

                fixture.books.listBooks() shouldContainExactly listOf(created)
                fixture.books.getBook(created.bookId) shouldBe created
            }
        }
    }

    test("book updates replace display fields and reconcile tag relations") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "story_hooks",
                            Color(argb = 0xFF336699.toInt()),
                            emptyList(),
                            Placement(x = 1, y = 2, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.books
                        .createBook(
                            "first_adventure",
                            "menu book",
                            Color(argb = 0xFFAABBCC.toInt()),
                            listOf(tag.tagId),
                        ).successValue()

                val updated =
                    fixture.books
                        .updateBook(
                            Book(
                                bookId = book.bookId,
                                title = "better_title",
                                icon = "diamond",
                                color = book.color,
                                tagIds = emptyList(),
                            ),
                        ).successValue()

                updated.tagIds shouldBe emptyList()
                fixture.books.listBooks() shouldContainExactly listOf(updated)
                fixture.books.getBook(book.bookId) shouldBe updated
            }
        }
    }

    test("book creation rejects blank titles") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books.createBook(" ", "book", Color(argb = 0), emptyList()).failureSlug() shouldBe
                    "book-title-invalid-error"
            }
        }
    }

    test("book creation with missing tags rolls back the record") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books
                    .createBook(
                        "uncommitted_book",
                        "book",
                        Color(argb = 0),
                        listOf(recordId("tag", "missing")),
                    ).failureSlug() shouldBe "tags-not-found-error"

                fixture.books.listBooks() shouldBe emptyList()
            }
        }
    }

    test("missing book retrieval returns null") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books.getBook(recordId("book", "missing")).shouldBeNull()
            }
        }
    }

    test("book creation resolves tags and deduplicates repeated identifiers") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "featured_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val book =
                    fixture.books
                        .createBook(
                            "tagged_book",
                            "book",
                            Color(argb = 2),
                            listOf(tag.tagId, tag.tagId),
                        ).successValue()

                book.tagIds shouldContainExactly listOf(tag.tagId)
                fixture.books.getBook(book.bookId)?.tagIds shouldContainExactly listOf(tag.tagId)
            }
        }
    }

    test("book updates add and replace tag relations") {
        runTest {
            RepositoryFixture().use { fixture ->
                val first =
                    fixture.tags
                        .createTag(
                            "first_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val second =
                    fixture.tags
                        .createTag(
                            "second_tag",
                            Color(argb = 2),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.books
                        .createBook(
                            "changing_book",
                            "book",
                            Color(argb = 3),
                            listOf(first.tagId),
                        ).successValue()

                val withBoth =
                    fixture.books
                        .updateBook(book.copy(tagIds = listOf(first.tagId, second.tagId)))
                        .successValue()
                val withSecond = fixture.books.updateBook(withBoth.copy(tagIds = listOf(second.tagId))).successValue()

                withBoth.tagIds.toSet() shouldBe setOf(first.tagId, second.tagId)
                withSecond.tagIds shouldContainExactly listOf(second.tagId)
                fixture.books.getBook(book.bookId)?.tagIds shouldContainExactly listOf(second.tagId)
            }
        }
    }

    test("book update reports a missing book") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books
                    .updateBook(
                        Book(
                            bookId = recordId("book", "missing"),
                            title = "missing_book",
                            icon = "book",
                            color = Color(argb = 0),
                            tagIds = emptyList(),
                        ),
                    ).failureSlug() shouldBe "book-not-found-error"
            }
        }
    }

    test("book update with missing tags rolls back fields and relations") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.books
                        .createBook(
                            "stable_book",
                            "book",
                            Color(argb = 2),
                            listOf(tag.tagId),
                        ).successValue()

                fixture.books
                    .updateBook(
                        book.copy(
                            title = "changed_book",
                            icon = "diamond",
                            color = Color(argb = 3),
                            tagIds = listOf(recordId("tag", "missing")),
                        ),
                    ).failureSlug() shouldBe "tags-not-found-error"

                fixture.books.getBook(book.bookId) shouldBe book
            }
        }
    }

    test("book creation rejects invalid title variants without persisting records") {
        runTest {
            RepositoryFixture().use { fixture ->
                listOf("ab", "Upper", "has space", "has-dash", "ümlaut", "_leading", "trailing_").forEach { title ->
                    fixture.books.createBook(title, "book", Color(argb = 0), emptyList()).failureSlug() shouldBe
                        "book-title-invalid-error"
                }

                fixture.books.listBooks() shouldBe emptyList()
            }
        }
    }

    test("book creation rejects blank icons without persisting records") {
        runTest {
            RepositoryFixture().use { fixture ->
                listOf("", " ").forEach { icon ->
                    fixture.books.createBook("valid_book", icon, Color(argb = 0), emptyList()).failureSlug() shouldBe
                        "book-icon-required-error"
                }

                fixture.books.listBooks() shouldBe emptyList()
            }
        }
    }
}
