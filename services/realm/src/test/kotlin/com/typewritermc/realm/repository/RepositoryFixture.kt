package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

internal class RepositoryFixture : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    private val database =
        Surreal().apply {
            connect("memory")
            useNs("realm_repository_test").useDb("realm_repository_test")
        }
    val outbox = SurrealRealmOutbox(database)
    val books = SurrealBookRepository(database, outbox)
    val pages = SurrealPageRepository(database, outbox)
    val tags = SurrealTagRepository(database, outbox)

    init {
        telemetry.telemetry.mainSpanBlocking(
            name = "test.realm.migrate",
            unhandledFailureSlug = ErrorSlug.of("test-realm-migrate-failed"),
        ) {
            SchemaMigrator(database).migrate()
        }
    }

    override fun close() {
        try {
            database.close()
        } finally {
            telemetry.close()
        }
    }
}

internal fun recordId(
    table: String,
    key: String,
) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

internal fun <Value> RepositoryResult<Value>.successValue(): Value =
    when (this) {
        is RepositoryResult.Success -> value
        is RepositoryResult.DomainFailure -> error("Expected success but received $slug")
    }

internal fun RepositoryResult<*>.failureSlug(): String =
    when (this) {
        is RepositoryResult.Success -> error("Expected domain failure")
        is RepositoryResult.DomainFailure -> slug
    }

internal fun BookCreateResult.successValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookCreateResult.Success -> book
        BookCreateResult.TitleInvalid -> error("Expected success but title was invalid")
        BookCreateResult.IconRequired -> error("Expected success but icon was required")
        is BookCreateResult.TagsNotFound -> error("Expected success but tags were missing")
    }

internal fun BookUpdateResult.successValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookUpdateResult.Success -> book
        is BookUpdateResult.Conflict -> error("Expected success but received a conflict")
        BookUpdateResult.NotFound -> error("Expected success but the book was missing")
        BookUpdateResult.TitleInvalid -> error("Expected success but title was invalid")
        BookUpdateResult.IconRequired -> error("Expected success but icon was required")
        is BookUpdateResult.TagsNotFound -> error("Expected success but tags were missing")
    }

internal fun BookUpdateResult.conflictValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookUpdateResult.Conflict -> actual
        is BookUpdateResult.Success -> error("Expected conflict but received success")
        BookUpdateResult.NotFound -> error("Expected conflict but the book was missing")
        BookUpdateResult.TitleInvalid -> error("Expected conflict but title was invalid")
        BookUpdateResult.IconRequired -> error("Expected conflict but icon was required")
        is BookUpdateResult.TagsNotFound -> error("Expected conflict but tags were missing")
    }

internal fun TagCreateResult.successValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagCreateResult.Success -> tag
        TagCreateResult.NameInvalid -> error("Expected success but name was invalid")
        TagCreateResult.WidthInvalid -> error("Expected success but width was invalid")
        TagCreateResult.HeightInvalid -> error("Expected success but height was invalid")
        is TagCreateResult.ParentsNotFound -> error("Expected success but parents were missing")
    }

internal fun TagUpdateResult.successValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagUpdateResult.Success -> tag
        is TagUpdateResult.Conflict -> error("Expected success but received a conflict")
        TagUpdateResult.NotFound -> error("Expected success but the tag was missing")
        TagUpdateResult.NameInvalid -> error("Expected success but name was invalid")
        TagUpdateResult.WidthInvalid -> error("Expected success but width was invalid")
        TagUpdateResult.HeightInvalid -> error("Expected success but height was invalid")
        is TagUpdateResult.ParentsNotFound -> error("Expected success but parents were missing")
        TagUpdateResult.InheritanceCycle -> error("Expected success but inheritance had a cycle")
    }

internal fun TagUpdateResult.conflictValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagUpdateResult.Conflict -> actual
        is TagUpdateResult.Success -> error("Expected conflict but received success")
        TagUpdateResult.NotFound -> error("Expected conflict but the tag was missing")
        TagUpdateResult.NameInvalid -> error("Expected conflict but name was invalid")
        TagUpdateResult.WidthInvalid -> error("Expected conflict but width was invalid")
        TagUpdateResult.HeightInvalid -> error("Expected conflict but height was invalid")
        is TagUpdateResult.ParentsNotFound -> error("Expected conflict but parents were missing")
        TagUpdateResult.InheritanceCycle -> error("Expected conflict but inheritance had a cycle")
    }

internal fun TagDeleteResult.successValue(): TagDeletion =
    when (this) {
        is TagDeleteResult.Success -> deletion
        TagDeleteResult.NotFound -> error("Expected success but the tag was missing")
    }

internal suspend fun BookRepository.createBook(
    title: String,
    icon: String,
    color: Color,
    tagIds: List<RecordId>,
) = createBook(title, icon, color, tagIds) { emptyList() }

internal suspend fun BookRepository.updateBook(
    expectedRevision: Long,
    book: skirout.library.v1.book.Book,
) = updateBook(expectedRevision, book) { emptyList() }

internal suspend fun BookRepository.updateBook(book: skirout.library.v1.book.Book) = updateBook(book.revision, book) { emptyList() }

internal suspend fun PageRepository.createPage(
    bookId: RecordId,
    name: String,
    type: PageType,
    chapter: String,
    priority: Int,
) = createPage(bookId, name, type, chapter, priority) { emptyList() }

internal suspend fun PageRepository.updatePage(page: Page) = updatePage(page) { emptyList() }

internal suspend fun PageRepository.deletePage(id: RecordId) = deletePage(id) { emptyList() }

internal suspend fun PageRepository.changePagesChapters(
    bookId: RecordId,
    oldChapter: String,
    newChapter: String,
) = changePagesChapters(bookId, oldChapter, newChapter) { emptyList() }

internal suspend fun TagRepository.createTag(
    name: String,
    color: Color,
    parentIds: List<RecordId>,
    placement: Placement,
) = createTag(name, color, parentIds, placement) { emptyList() }

internal suspend fun TagRepository.updateTag(
    expectedRevision: Long,
    tag: Tag,
) = updateTag(expectedRevision, tag) { emptyList() }

internal suspend fun TagRepository.updateTag(tag: Tag) = updateTag(tag.revision, tag) { emptyList() }

internal suspend fun TagRepository.deleteTag(id: RecordId) = deleteTag(id) { emptyList() }
