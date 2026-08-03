package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.asDeferredProvider
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.library.v1.book.Book
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

val RealmRepositoryTest by testSuite {
    test("book operations preserve display text and reconcile tag relations") {
        runTest {
            RepositoryFixture().use { fixture ->
                val parent = fixture.tags.createTag(
                    "story_hooks",
                    Color(argb = 0xFF336699.toInt()),
                    emptyList(),
                    Placement(x = 1, y = 2, width = 4, height = 1),
                ).successValue()
                val book = fixture.books.createBook(
                    "first_adventure",
                    "menu book",
                    Color(argb = 0xFFAABBCC.toInt()),
                    listOf(parent.tagId),
                ).successValue()

                fixture.books.listBooks().single() shouldBe book
                fixture.books.getBook(book.bookId) shouldBe book

                val updated = fixture.books.updateBook(
                    Book(
                        bookId = book.bookId,
                        title = "better_title",
                        icon = "diamond",
                        color = book.color,
                        tagIds = emptyList(),
                    ),
                ).successValue()
                updated.tagIds shouldBe emptyList()

                fixture.books.listBooks().single() shouldBe updated
                fixture.books.getBook(book.bookId) shouldBe updated
            }
        }
    }

    test("tag operations preserve hierarchy and enforce positive sizes") {
        runTest {
            RepositoryFixture().use { fixture ->
                val parent = fixture.tags.createTag(
                    "parent_tag",
                    Color(argb = 1),
                    emptyList(),
                    Placement(x = 0, y = 0, width = 3, height = 1),
                ).successValue()
                val child = fixture.tags.createTag(
                    "child_tag",
                    Color(argb = 2),
                    listOf(parent.tagId),
                    Placement(x = 4, y = 5, width = 6, height = 2),
                ).successValue()

                fixture.tags.getTag(child.tagId)?.parentIds shouldContainExactly listOf(parent.tagId)
                fixture.tags.moveTag(child.tagId, 8, null).successValue().placement.x shouldBe 8
                fixture.tags.resizeTag(child.tagId, null, 4).successValue().placement.height shouldBe 4

                fixture.tags.updateTag(
                    Tag(
                        tagId = child.tagId,
                        name = child.name,
                        color = child.color,
                        parentIds = child.parentIds,
                        placement = Placement(x = 0, y = 0, width = 0, height = 1),
                    ),
                ).failureSlug() shouldBe "tag-width-invalid-error"
                fixture.tags.deleteTag(parent.tagId).successValue()
                fixture.tags.getTag(parent.tagId).shouldBeNull()
            }
        }
    }

    test("page operations support search, updates, deletion, and chapter batches") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.books.createBook("quest_book", "book", Color(argb = 3), emptyList()).successValue()
                val first = fixture.pages.createPage(book.bookId, "opening_scene", PageType.SCENE, "act.one", 1)
                    .successValue()
                val second = fixture.pages.createPage(book.bookId, "second_scene", PageType.SEQUENCE, "act.one.deep", 2)
                    .successValue()

                fixture.pages.searchPages(book.bookId, "opening") shouldContainExactly listOf(first)
                val updated = fixture.pages.updatePage(
                    Page(
                        pageId = first.pageId,
                        bookId = first.bookId,
                        name = "opening_sequence",
                        type = PageType.SEQUENCE,
                        chapter = first.chapter,
                        priority = 9,
                    ),
                ).successValue()
                fixture.pages.getPage(first.pageId) shouldBe updated
                fixture.pages.changePagesChapters(book.bookId, "act.one", "act.two")
                    .successValue()
                    .map(Page::chapter) shouldContainExactlyInAnyOrder listOf("act.two", "act.two.deep")
                fixture.pages.deletePage(second.pageId).successValue()
                fixture.pages.deletePage(second.pageId).failureSlug() shouldBe "page-not-found-error"
            }
        }
    }

    test("fresh schema rejects blank display fields and missing book references") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books.createBook(" ", "book", Color(argb = 0), emptyList()).failureSlug() shouldBe
                    "book-title-invalid-error"
                fixture.pages.createPage(rid("book", "missing"), "page_name", PageType.STATIC, "", 0)
                    .failureSlug() shouldBe "book-not-found-error"
            }
        }
    }

    test("failed relation mutations roll back their record changes") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.books.createBook(
                    "uncommitted_book",
                    "book",
                    Color(argb = 0),
                    listOf(rid("tag", "missing")),
                ).failureSlug() shouldBe "tags-not-found-error"
                fixture.books.listBooks() shouldBe emptyList()

                val tag = fixture.tags.createTag(
                    "stable_tag",
                    Color(argb = 0),
                    emptyList(),
                    Placement(x = 0, y = 0, width = 4, height = 1),
                ).successValue()
                fixture.tags.updateTag(
                    Tag(
                        tagId = tag.tagId,
                        name = "uncommitted_tag",
                        color = tag.color,
                        parentIds = listOf(rid("tag", "missing")),
                        placement = tag.placement,
                    ),
                ).failureSlug() shouldBe "parents-not-found-error"
                fixture.tags.getTag(tag.tagId) shouldBe tag
            }
        }
    }
}

private class RepositoryFixture : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    private val database = Surreal().apply {
        connect("memory")
        useNs("realm_repository_test").useDb("realm_repository_test")
    }
    val provider = database.asDeferredProvider()
    val books = SurrealBookRepository(provider)
    val pages = SurrealPageRepository(provider)
    val tags = SurrealTagRepository(provider)

    init {
        telemetry.telemetry.mainSpanBlocking(
            name = "test.realm.migrate",
            unhandledFailureSlug = ErrorSlug.of("test-realm-migrate-failed"),
        ) {
            SchemaMigrator(database).migrate()
        }
    }

    override fun close() {
        telemetry.use { _ ->
            database.close()
        }
    }
}

private fun rid(table: String, key: String) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

private fun <Value> RepositoryResult<Value>.successValue(): Value = when (this) {
    is RepositoryResult.Success -> value
    is RepositoryResult.DomainFailure -> error("Expected success but received $slug")
}

private fun RepositoryResult<*>.failureSlug(): String = when (this) {
    is RepositoryResult.Success -> error("Expected domain failure")
    is RepositoryResult.DomainFailure -> slug
}
