package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.ChapterPath
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.realm.routes.toLibrary
import com.typewritermc.realm.routes.toSkir
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.page_kind.PageKindRef
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.library.v1.tag.Placement

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
        is RepositoryResult.DomainFailure -> error("Expected success but received $failure")
    }

internal fun RepositoryResult<*>.failureSlug(): String =
    when (this) {
        is RepositoryResult.Success -> error("Expected domain failure")
        is RepositoryResult.DomainFailure -> failure.wireValue
    }

internal fun BookCreateResult.successValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookCreateResult.Success -> book.toSkir()
        BookCreateResult.TitleInvalid -> error("Expected success but title was invalid")
        BookCreateResult.IconRequired -> error("Expected success but icon was required")
        is BookCreateResult.TagsNotFound -> error("Expected success but tags were missing")
    }

internal fun BookUpdateResult.successValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookUpdateResult.Success -> book.toSkir()
        is BookUpdateResult.Conflict -> error("Expected success but received a conflict")
        BookUpdateResult.NotFound -> error("Expected success but the book was missing")
        BookUpdateResult.TitleInvalid -> error("Expected success but title was invalid")
        BookUpdateResult.IconRequired -> error("Expected success but icon was required")
        is BookUpdateResult.TagsNotFound -> error("Expected success but tags were missing")
    }

internal fun BookUpdateResult.conflictValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookUpdateResult.Conflict -> actual.toSkir()
        is BookUpdateResult.Success -> error("Expected conflict but received success")
        BookUpdateResult.NotFound -> error("Expected conflict but the book was missing")
        BookUpdateResult.TitleInvalid -> error("Expected conflict but title was invalid")
        BookUpdateResult.IconRequired -> error("Expected conflict but icon was required")
        is BookUpdateResult.TagsNotFound -> error("Expected conflict but tags were missing")
    }

internal fun TagCreateResult.successValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagCreateResult.Success -> tag.toSkir()
        TagCreateResult.NameInvalid -> error("Expected success but name was invalid")
        TagCreateResult.WidthInvalid -> error("Expected success but width was invalid")
        TagCreateResult.HeightInvalid -> error("Expected success but height was invalid")
        is TagCreateResult.ParentsNotFound -> error("Expected success but parents were missing")
    }

internal fun TagUpdateResult.successValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagUpdateResult.Success -> tag.toSkir()
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
        is TagUpdateResult.Conflict -> actual.toSkir()
        is TagUpdateResult.Success -> error("Expected conflict but received success")
        TagUpdateResult.NotFound -> error("Expected conflict but the tag was missing")
        TagUpdateResult.NameInvalid -> error("Expected conflict but name was invalid")
        TagUpdateResult.WidthInvalid -> error("Expected conflict but width was invalid")
        TagUpdateResult.HeightInvalid -> error("Expected conflict but height was invalid")
        is TagUpdateResult.ParentsNotFound -> error("Expected conflict but parents were missing")
        TagUpdateResult.InheritanceCycle -> error("Expected conflict but inheritance had a cycle")
    }

internal fun TagDeleteResult.successValue(): SkirTagDeletion =
    when (this) {
        is TagDeleteResult.Success -> {
            SkirTagDeletion(
                childTags = deletion.childTags.map { it.toSkir() },
                books = deletion.books.map { it.toSkir() },
            )
        }

        TagDeleteResult.NotFound -> {
            error("Expected success but the tag was missing")
        }
    }

internal fun PageUpdateResult.successValue(): skirout.library.v1.page.Page =
    when (this) {
        is PageUpdateResult.Success -> page.toSkir()
        is PageUpdateResult.Conflict -> error("Expected success but received a conflict")
        PageUpdateResult.NotFound -> error("Expected success but the page was missing")
    }

internal fun PageUpdateResult.conflictValue(): skirout.library.v1.page.Page =
    when (this) {
        is PageUpdateResult.Conflict -> actual.toSkir()
        is PageUpdateResult.Success -> error("Expected conflict but received success")
        PageUpdateResult.NotFound -> error("Expected conflict but the page was missing")
    }

internal suspend fun BookRepository.createBook(
    title: String,
    icon: String,
    color: Color,
    tagIds: List<RecordId>,
    encodeEvents: (skirout.library.v1.book.Book) -> List<OutboxEvent> = { emptyList() },
) = if (icon.isBlank()) {
    BookCreateResult.IconRequired
} else {
    createBook(
        title = com.typewritermc.library.LibraryName(title),
        icon =
            com.typewritermc.types.Icon
                .parse(icon),
        color = com.typewritermc.types.Color(color.argb.toUInt()),
        tagIds = tagIds.mapTo(linkedSetOf()) { it.toTagId() },
        encodeEvents = { encodeEvents(it.toSkir()) },
    )
}

internal suspend fun BookRepository.getBook(id: RecordId): skirout.library.v1.book.Book? = getBook(id.toBookId())?.toSkir()

internal suspend fun BookRepository.updateBook(
    expectedRevision: Long,
    book: skirout.library.v1.book.Book,
) = if (book.icon.isBlank()) BookUpdateResult.IconRequired else updateBook(expectedRevision, book.toLibrary()) { emptyList() }

internal suspend fun BookRepository.updateBook(book: skirout.library.v1.book.Book) =
    if (book.icon.isBlank()) BookUpdateResult.IconRequired else updateBook(book.revision, book.toLibrary()) { emptyList() }

internal suspend fun PageRepository.createPage(
    bookId: RecordId,
    name: String,
    kind: PageKindRef,
    chapter: String,
    priority: Int,
    encodeEvents: (skirout.library.v1.page.Page) -> List<OutboxEvent> = { emptyList() },
) = when (
    val result =
        createPage(
            bookId = bookId.toBookId(),
            name = com.typewritermc.library.LibraryName(name),
            kind = kind.toLibrary(),
            chapter = ChapterPath.parse(chapter),
            priority = priority,
        ) { encodeEvents(it.toSkir()) }
) {
    is RepositoryResult.Success -> RepositoryResult.Success(result.value.toSkir())
    is RepositoryResult.DomainFailure -> result
}

internal suspend fun PageRepository.searchPages(
    bookId: RecordId,
    search: String?,
): List<skirout.library.v1.page.Page> = searchPages(bookId.toBookId(), search).map { it.toSkir() }

internal suspend fun PageRepository.getPage(id: RecordId): skirout.library.v1.page.Page? = getPage(id.toPageId())?.toSkir()

internal suspend fun PageRepository.updatePage(page: skirout.library.v1.page.Page) = updatePage(page.toLibrary()) { emptyList() }

internal suspend fun PageRepository.deletePage(id: RecordId) = deletePage(id.toPageId()) { emptyList() }

internal suspend fun PageRepository.changePagesChapters(
    bookId: RecordId,
    oldChapter: String,
    newChapter: String,
) = when (
    val result =
        changePagesChapters(
            bookId.toBookId(),
            ChapterPath.parse(oldChapter),
            ChapterPath.parse(newChapter),
        ) { emptyList() }
) {
    is RepositoryResult.Success -> RepositoryResult.Success(result.value.map { it.toSkir() })
    is RepositoryResult.DomainFailure -> result
}

internal suspend fun TagRepository.createTag(
    name: String,
    color: Color,
    parentIds: List<RecordId>,
    placement: Placement,
    encodeEvents: (skirout.library.v1.tag.Tag) -> List<OutboxEvent> = { emptyList() },
) = createTag(
    name = com.typewritermc.library.LibraryName(name),
    color = com.typewritermc.types.Color(color.argb.toUInt()),
    parentIds = parentIds.mapTo(linkedSetOf()) { it.toTagId() },
    placement = placement.toLibrary(),
) { encodeEvents(it.toSkir()) }

internal suspend fun TagRepository.getTag(id: RecordId): skirout.library.v1.tag.Tag? = getTag(id.toTagId())?.toSkir()

internal suspend fun TagRepository.findMissing(ids: List<RecordId>): List<RecordId> =
    findMissing(ids.mapTo(linkedSetOf()) { it.toTagId() }).map { it.toSkirRecordId() }

internal suspend fun TagRepository.updateTag(
    expectedRevision: Long,
    tag: skirout.library.v1.tag.Tag,
) = updateTag(expectedRevision, tag.toLibrary()) { emptyList() }

internal suspend fun TagRepository.updateTag(tag: skirout.library.v1.tag.Tag) = updateTag(tag.revision, tag.toLibrary()) { emptyList() }

internal suspend fun TagRepository.deleteTag(
    id: RecordId,
    encodeEvents: (SkirTagDeletion) -> List<OutboxEvent> = { emptyList() },
) = deleteTag(id.toTagId()) { deletion ->
    encodeEvents(
        SkirTagDeletion(
            childTags = deletion.childTags.map { it.toSkir() },
            books = deletion.books.map { it.toSkir() },
        ),
    )
}

internal data class SkirTagDeletion(
    val childTags: List<skirout.library.v1.tag.Tag>,
    val books: List<skirout.library.v1.book.Book>,
)
