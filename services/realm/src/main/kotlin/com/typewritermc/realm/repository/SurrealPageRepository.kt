package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.databaseValue
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.services.libs.utils.DeferredProvider
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType

class SurrealPageRepository(
    private val database: DeferredProvider<Surreal>,
) : PageRepository {
    override suspend fun searchPages(bookId: RecordId, search: String?): List<Page> {
        val query = if (search == null) {
            $$"SELECT * FROM page WHERE book = $book ORDER BY priority, name, id"
        } else {
            // TODO make this a full text search properly, including chapters.
            $$"SELECT * FROM page WHERE book = $book AND string::lowercase(name) CONTAINS $search ORDER BY priority, name, id"
        }
        val bindings = buildMap {
            put("book", bookId.surrealId("book"))
            if (search != null) put("search", search.lowercase())
        }
        val result = database.get().query(query, bindings).take(0)
        return PageRecord.parseList(result).map(PageRecord::toPage)
    }

    override suspend fun getPage(id: RecordId): Page? {
        val result = database.get().query(
            $$"SELECT * FROM $page",
            mapOf("page" to id.surrealId("page")),
        ).take(0)

        return PageRecord.parseList(result).firstOrNull()?.toPage()
    }

    override suspend fun createPage(
        bookId: RecordId,
        name: String,
        type: PageType,
        chapter: String,
        priority: Int,
    ): RepositoryResult<Page> = repositoryMutation(listOf(bookId)) {
        val result = database.get().query(
            $$"""
                CREATE ONLY page SET
                    book = $book,
                    name = $name,
                    type = $type,
                    chapter = $chapter,
                    priority = $priority
            """.trimIndent(),
            mapOf(
                "book" to bookId.surrealId("book"),
                "name" to name,
                "type" to type.databaseValue(),
                "chapter" to chapter,
                "priority" to priority,
            ),
        ).take(0)

        PageRecord.parseList(result).singleOrNull()?.toPage()
            ?: error("Page creation returned no record")
    }

    override suspend fun updatePage(page: Page): RepositoryResult<Page> = repositoryMutation {
        val result = database.get().query(
            $$"""
                BEGIN TRANSACTION;
                IF !record::exists($page) {
                    THROW "page-not-found-error";
                };

                UPDATE ONLY $page SET
                    name = $name,
                    type = $type,
                    chapter = $chapter,
                    priority = $priority;

                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf(
                "page" to page.pageId.surrealId("page"),
                "name" to page.name,
                "type" to page.type.databaseValue(),
                "chapter" to page.chapter,
                "priority" to page.priority,
            ),
        ).takeTransaction(2)

        PageRecord.parseList(result).singleOrNull()?.toPage()
            ?: error("Page update returned no record")
    }

    override suspend fun deletePage(id: RecordId): RepositoryResult<Unit> = repositoryMutation {
        database.get().query(
            $$"""
                BEGIN TRANSACTION;

                IF !record::exists($page) {
                    THROW "page-not-found-error";
                };

                DELETE $page;

                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("page" to id.surrealId("page")),
        ).takeTransaction(2)
    }

    override suspend fun changePagesChapters(
        bookId: RecordId,
        oldChapter: String,
        newChapter: String,
    ): RepositoryResult<List<Page>> {
        if (oldChapter == newChapter) return RepositoryResult.Success(emptyList())

        return repositoryMutation(listOf(bookId)) {
            val result = database.get().query(
                $$"""
                    BEGIN TRANSACTION;

                    IF !record::exists($book) {
                        THROW "book-not-found-error";
                    };

                    LET $prefix = string::concat($old_chapter, '.');

                    -- Update exact matches
                    LET $exact = (UPDATE page
                        SET chapter = $new_chapter
                        WHERE book = $book AND chapter = $old_chapter
                        RETURN AFTER);

                    -- Update prefix matches (old_chapter.xxx -> new_chapter.xxx)
                    LET $prefixed = (UPDATE page
                        SET chapter = IF $new_chapter == ""
                            THEN string::slice(chapter, string::len($old_chapter) + 1)
                            ELSE string::concat($new_chapter, string::slice(chapter, string::len($old_chapter)))
                        END
                        WHERE book = $book AND string::starts_with(chapter, $prefix)
                        RETURN AFTER);

                    RETURN ($exact + $prefixed);
                    COMMIT TRANSACTION;
                """.trimIndent(),
                mapOf(
                    "book" to bookId.surrealId("book"),
                    "old_chapter" to oldChapter,
                    "new_chapter" to newChapter,
                ),
            ).takeTransaction(5)

            PageRecord.parseList(result).map(PageRecord::toPage)
        }
    }
}
