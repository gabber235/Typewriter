package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindRef
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.outbox.RealmOutbox
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.records.PageUpdateOutputRecord
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction

class SurrealPageRepository(
    private val database: Surreal,
    private val outbox: RealmOutbox = SurrealRealmOutbox(database),
) : PageRepository {
    override suspend fun searchPages(
        bookId: BookId,
        search: String?,
    ): List<Page> {
        val query =
            if (search == null) {
                $$"SELECT * FROM page WHERE book = $book ORDER BY priority, name, id"
            } else {
                // TODO make this a full text search properly, including chapters.
                $$"SELECT * FROM page WHERE book = $book AND string::lowercase(name) CONTAINS $search ORDER BY priority, name, id"
            }
        val bindings =
            buildMap {
                put("book", bookId.surrealId())
                if (search != null) put("search", search.lowercase())
            }
        val result = database.query(query, bindings).take(0)
        return PageRecord.parseList(result).map(PageRecord::toPage)
    }

    override suspend fun getPage(id: PageId): Page? {
        val result =
            database
                .query(
                    $$"SELECT * FROM $page",
                    mapOf("page" to id.surrealId()),
                ).take(0)

        return PageRecord.parseList(result).firstOrNull()?.toPage()
    }

    override suspend fun createPage(
        bookId: BookId,
        name: LibraryName,
        kind: PageKindRef,
        chapter: ChapterPath,
        priority: Int,
        encodeEvents: (Page) -> List<OutboxEvent>,
    ): RepositoryResult<Page> =
        repositoryMutation {
            database
                .inTransaction { transaction ->
                    val result =
                        transaction
                            .query(
                                $$"""
                CREATE ONLY page SET
                    book = $book,
                    name = $name,
                    kind = { id: $kind_id, revision: $kind_revision },
                    chapter = $chapter,
                    priority = $priority
                                """.trimIndent(),
                                mapOf(
                                    "book" to bookId.surrealId(),
                                    "name" to name.value,
                                    "kind_id" to kind.id.value.toString(),
                                    "kind_revision" to kind.revision,
                                    "chapter" to chapter.value,
                                    "priority" to priority,
                                ),
                            ).take(0)

                    val page =
                        PageRecord.parseList(result).singleOrNull()?.toPage()
                            ?: error("Page creation returned no record")
                    outbox.enqueue(transaction, encodeEvents(page))
                    page
                }.also { outbox.signalPending() }
        }

    override suspend fun updatePage(
        page: Page,
        encodeEvents: (Page) -> List<OutboxEvent>,
    ): PageUpdateResult {
        val mutation =
            database.inTransaction { transaction ->
                val result =
                    transaction
                        .query(
                            $$"""
                LET $actual = SELECT * FROM ONLY $page;
                LET $result = IF $actual = NONE {
                    { kind: "not_found" };
                } ELSE IF $actual.revision != $expected_revision {
                    { kind: "conflict", page: $actual };
                } ELSE {
                    UPDATE ONLY $page SET
                        revision += 1,
                        name = $name,
                        chapter = $chapter,
                        priority = $priority;
                    { kind: "success", page: (SELECT * FROM ONLY $page) };
                };
                RETURN $result;
                            """.trimIndent(),
                            mapOf(
                                "page" to page.id.surrealId(),
                                "expected_revision" to page.revision.value,
                                "name" to page.name.value,
                                "chapter" to page.chapter.value,
                                "priority" to page.priority,
                            ),
                        ).takeTransaction(2)
                PageUpdateOutputRecord.parse(result).toResult().also { update ->
                    if (update is PageUpdateResult.Success) outbox.enqueue(transaction, encodeEvents(update.page))
                }
            }
        if (mutation is PageUpdateResult.Success) outbox.signalPending()
        return mutation
    }

    override suspend fun deletePage(
        id: PageId,
        encodeEvents: (PageId) -> List<OutboxEvent>,
    ): RepositoryResult<Unit> =
        repositoryMutation {
            database
                .inTransaction { transaction ->
                    transaction
                        .query(
                            $$"""
                        IF !record::exists($page) {
                            THROW "page-not-found-error";
                        };

                        DELETE $page;
                            """.trimIndent(),
                            mapOf("page" to id.surrealId()),
                        ).takeTransaction(1)
                    outbox.enqueue(transaction, encodeEvents(id))
                }.also { outbox.signalPending() }
        }

    override suspend fun changePagesChapters(
        bookId: BookId,
        oldChapter: ChapterPath,
        newChapter: ChapterPath,
        encodeEvents: (List<Page>) -> List<OutboxEvent>,
    ): RepositoryResult<List<Page>> {
        if (oldChapter == newChapter) return RepositoryResult.Success(emptyList())

        return repositoryMutation {
            database
                .inTransaction { transaction ->
                    val result =
                        transaction
                            .query(
                                $$"""
                    IF !record::exists($book) {
                        THROW "book-not-found-error";
                    };

                    LET $prefix = string::concat($old_chapter, '.');

                    -- Update exact matches
                    LET $exact = (UPDATE page
                        SET chapter = $new_chapter, revision += 1
                        WHERE book = $book AND chapter = $old_chapter
                        RETURN AFTER);

                    -- Update prefix matches (old_chapter.xxx -> new_chapter.xxx)
                    LET $prefixed = (UPDATE page
                        SET chapter = IF $new_chapter == ""
                            THEN string::slice(chapter, string::len($old_chapter) + 1)
                            ELSE string::concat($new_chapter, string::slice(chapter, string::len($old_chapter)))
                        END, revision += 1
                        WHERE book = $book AND string::starts_with(chapter, $prefix)
                        RETURN AFTER);

                    RETURN ($exact + $prefixed);
                                """.trimIndent(),
                                mapOf(
                                    "book" to bookId.surrealId(),
                                    "old_chapter" to oldChapter.value,
                                    "new_chapter" to newChapter.value,
                                ),
                            ).takeTransaction(4)

                    val pages = PageRecord.parseList(result).map(PageRecord::toPage)
                    outbox.enqueue(transaction, encodeEvents(pages))
                    pages
                }.also { outbox.signalPending() }
        }
    }
}
