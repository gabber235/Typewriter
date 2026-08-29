package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.library.ref
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.realm.routes.toLibrary
import com.typewritermc.realm.routes.toSkir
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.Icon
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.page_kind.PageKindRef
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.library.v1.tag.Placement
import java.util.UUID

internal class RepositoryFixture : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    internal val database =
        Surreal().apply {
            connect("memory")
            useNs("realm_repository_test").useDb("realm_repository_test")
        }
    val outbox = SurrealRealmOutbox(database)
    val books = TestBookRepository(SurrealBookRepository(database), database, outbox)
    val pages = TestPageRepository(SurrealPageRepository(database), database, outbox)
    val tags = TestTagRepository(SurrealTagRepository(database), database, outbox)
    val elementTypeGraphs = { mapOf(TEST_ELEMENT_TYPE to TypeGraph(TypeExpression.Any, emptyList())) }
    val elements = SurrealElementRepository(database, typeGraph = elementTypeGraphs)

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

internal class TestBookRepository(
    private val reads: BookRepository,
    private val database: Surreal,
    private val outbox: SurrealRealmOutbox,
) : BookRepository by reads {
    suspend fun seedBook(
        title: String,
        icon: String,
        color: Color,
        tagIds: List<RecordId>,
        encodeEvents: (skirout.library.v1.book.Book) -> List<OutboxEvent> = { emptyList() },
    ): TestMutation<skirout.library.v1.book.Book> {
        val id = BookId(title)
        val expected =
            Book(
                id,
                com.typewritermc.library.ResourceRevision(1),
                LibraryName(title),
                Icon.parse(icon),
                com.typewritermc.types.Color(color.argb.toUInt()),
                tagIds.mapTo(linkedSetOf()) { it.toTagId().ref() },
            )
        val repository =
            SurrealLibraryBatchRepository(
                database,
                outbox,
                encodeLibraryEvents = { encodeEvents(expected.toSkir()) },
            )
        val result =
            repository.createBooks(
                CreateBooksCommand(
                    BatchId("test_book_create_$title"),
                    listOf(
                        BookCreation(
                            id,
                            expected.title,
                            expected.icon,
                            expected.color,
                            expected.tags.toList(),
                        ),
                    ),
                ),
            )
        return TestMutation(result.requireSuccess().single().toSkir())
    }

    suspend fun getBook(id: RecordId): skirout.library.v1.book.Book? = reads.getBook(id.toBookId())?.toSkir()
}

internal class TestPageRepository(
    private val reads: PageRepository,
    database: Surreal,
    outbox: SurrealRealmOutbox,
) : PageRepository by reads {
    private val batches = SurrealLibraryBatchRepository(database, outbox)

    suspend fun seedPage(
        bookId: RecordId,
        name: String,
        kind: PageKindRef,
        chapter: String,
        priority: Int,
    ): TestMutation<skirout.library.v1.page.Page> {
        val result =
            batches.createPages(
                CreatePagesCommand(
                    BatchId("test_page_create_${UUID.randomUUID()}"),
                    listOf(
                        PageCreation(
                            PageId(UUID.randomUUID().toString()),
                            bookId.toBookId().ref(),
                            LibraryName(name),
                            kind.toLibrary(),
                            ChapterPath.parse(chapter),
                            priority,
                        ),
                    ),
                ),
            )
        val page = result.requireSuccess().single().toSkir()
        return TestMutation(page)
    }

    suspend fun searchPages(
        bookId: RecordId,
        search: String?,
    ): List<skirout.library.v1.page.Page> = reads.searchPages(bookId.toBookId(), search).map(Page::toSkir)

    suspend fun getPage(id: RecordId): skirout.library.v1.page.Page? = reads.getPage(id.toPageId())?.toSkir()
}

internal class TestTagRepository(
    private val reads: TagRepository,
    database: Surreal,
    outbox: SurrealRealmOutbox,
) : TagRepository by reads {
    private val batches = SurrealLibraryBatchRepository(database, outbox)

    suspend fun seedTag(
        name: String,
        color: Color,
        parentIds: List<RecordId>,
        placement: Placement,
    ): TestMutation<skirout.library.v1.tag.Tag> {
        val result =
            batches.createTags(
                CreateTagsCommand(
                    BatchId("test_tag_create_$name"),
                    listOf(
                        TagCreation(
                            TagId(name),
                            LibraryName(name),
                            com.typewritermc.types.Color(color.argb.toUInt()),
                            parentIds.map { it.toTagId().ref() },
                            placement.toLibrary(),
                        ),
                    ),
                ),
            )
        return TestMutation(result.requireSuccess().single().toSkir())
    }

    suspend fun getTag(id: RecordId): skirout.library.v1.tag.Tag? = reads.getTag(id.toTagId())?.toSkir()
}

internal data class TestMutation<T>(
    val value: T,
)

internal fun <T> TestMutation<T>.successValue(): T = value

internal suspend fun TestBookRepository.createBook(
    title: String,
    icon: String,
    color: Color,
    tagIds: List<RecordId>,
    encodeEvents: (skirout.library.v1.book.Book) -> List<OutboxEvent> = { emptyList() },
) = seedBook(title, icon, color, tagIds, encodeEvents)

internal suspend fun TestPageRepository.createPage(
    bookId: RecordId,
    name: String,
    kind: PageKindRef,
    chapter: String,
    priority: Int,
) = seedPage(bookId, name, kind, chapter, priority)

internal suspend fun TestTagRepository.createTag(
    name: String,
    color: Color,
    parentIds: List<RecordId>,
    placement: Placement,
) = seedTag(name, color, parentIds, placement)

private fun <T> LibraryBatchResult<T>.requireSuccess(): List<T> =
    when (this) {
        is LibraryBatchResult.Success -> values
        is LibraryBatchResult.Conflict -> error("Expected success but received conflicts: $conflicts")
        is LibraryBatchResult.Invalid -> error("Expected success but received validation errors: $diagnostics")
    }

internal val TEST_ELEMENT_TYPE =
    com.typewritermc.elements.ElementTypeId(
        com.typewritermc.types.DeclaredTypeId
            .parse("20000000000000000000000000000001"),
    )

internal fun recordId(
    table: String,
    key: String,
) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))
