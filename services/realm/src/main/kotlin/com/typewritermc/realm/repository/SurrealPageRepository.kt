package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.PageRecord
import com.typewritermc.realm.repository.utils.name
import com.typewritermc.realm.repository.utils.requireValidId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.services.libs.utils.DeferredProvider
import protokt.v1.typewriter.models.v1.Page
import protokt.v1.typewriter.models.v1.PageType

class SurrealPageRepository(
    private val db: DeferredProvider<Surreal>
) : PageRepository {

    override suspend fun listPages(bookId: String): List<Page> {
        requireValidId("Book", bookId)

        val result = db.get().queryBind(
            $$"SELECT * FROM page WHERE book_id = type::thing('book', $bookId) ORDER BY priority ASC, name ASC",
            mapOf("bookId" to bookId)
        ).take(0)

        return PageRecord.parseList(result).map { it.toPage() }
    }

    override suspend fun searchPages(bookId: String, search: String): List<Page> {
        requireValidId("Book", bookId)

        val searchLower = search.lowercase()
        val result = db.get().queryBind(
            $$"SELECT * FROM page WHERE book_id = type::thing('book', $bookId) AND string::lowercase(name) CONTAINS $search ORDER BY priority ASC",
            mapOf("bookId" to bookId, "search" to searchLower)
        ).take(0)

        return PageRecord.parseList(result).map { it.toPage() }
    }

    override suspend fun getPage(id: String): Page? {
        requireValidId("Page", id)

        val result = db.get().queryBind(
            $$"SELECT * FROM type::thing('page', $id)",
            mapOf("id" to id)
        ).take(0)

        if (result.isNone) return null

        val records = PageRecord.parseList(result)
        return records.firstOrNull()?.toPage()
    }

    override suspend fun createPage(
        bookId: String,
        name: String,
        type: PageType,
        chapter: String,
        priority: Int
    ): Page {
        requireValidId("Book", bookId)

        val typeStr = type.name()
        val result = db.get().queryBind(
            $$"""
            CREATE page SET 
                name = $name, 
                book_id = type::thing('book', $bookId), 
                type = $type, 
                chapter = $chapter, 
                priority = $priority
            """.trimIndent(),
            mapOf(
                "name" to name,
                "bookId" to bookId,
                "type" to typeStr,
                "chapter" to chapter,
                "priority" to priority
            )
        ).take(0)

        val records = PageRecord.parseList(result)
        val record = records.firstOrNull() ?: throw IllegalStateException("Failed to create page")
        return record.toPage()
    }

    override suspend fun updatePage(page: Page): Page {
        requireValidId("Page", page.pageId)

        val typeStr = page.type.name()

        val result = db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $page_record = type::thing('page', $id);
                UPDATE $page_record SET 
                    name = $name, 
                    type = $type, 
                    chapter = $chapter, 
                    priority = $priority;
                RETURN SELECT * FROM $page_record;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf(
                "id" to page.pageId,
                "name" to page.name.orEmpty(),
                "type" to typeStr,
                "chapter" to page.chapter.orEmpty(),
                "priority" to (page.priority ?: 0)
            )
        ).takeTransaction(0)

        return PageRecord.parseList(result).firstOrNull()?.toPage()
            ?: throw IllegalStateException("Failed to update page")
    }

    override suspend fun deletePage(id: String): Boolean {
        requireValidId("Page", id)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $page_record = type::thing('page', $id);
                
                IF !record::exists($page_record) {
                    RETURN false;
                };
                
                DELETE $page_record;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to id)
        ).takeTransaction(0).boolean
    }

    override suspend fun changePageChapter(pageId: String, chapter: String): Boolean {
        requireValidId("Page", pageId)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $page_record = type::thing('page', $id);
                
                IF !record::exists($page_record) {
                    RETURN false;
                };
                
                UPDATE $page_record SET chapter = $chapter;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to pageId, "chapter" to chapter)
        ).takeTransaction(0).boolean
    }

    override suspend fun changePagePriority(pageId: String, priority: Int): Boolean {
        requireValidId("Page", pageId)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $page_record = type::thing('page', $id);
                
                IF !record::exists($page_record) {
                    RETURN false;
                };
                
                UPDATE $page_record SET priority = $priority;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to pageId, "priority" to priority)
        ).takeTransaction(0).boolean
    }

    override suspend fun renamePage(pageId: String, name: String): Boolean {
        requireValidId("Page", pageId)

        return db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $page_record = type::thing('page', $id);
                
                IF !record::exists($page_record) {
                    RETURN false;
                };
                
                UPDATE $page_record SET name = $name;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("id" to pageId, "name" to name)
        ).takeTransaction(0).boolean
    }

    override suspend fun changePagesChapters(bookId: String, oldChapter: String, newChapter: String): Int {
        requireValidId("Book", bookId)

        if (oldChapter == newChapter) return 0

        val result = db.get().queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $book_record = type::thing('book', $book_id);
                LET $prefix = string::concat($old_chapter, '.');

                -- Update exact matches
                LET $exact = (UPDATE page 
                    SET chapter = $new_chapter 
                    WHERE book_id = $book_record AND chapter = $old_chapter
                    RETURN id);

                -- Update prefix matches (old_chapter.xxx -> new_chapter.xxx)
                LET $prefixed = (UPDATE page 
                    SET chapter = IF $new_chapter == "" 
                        THEN string::slice(chapter, string::len($old_chapter) + 1) 
                        ELSE string::concat($new_chapter, string::slice(chapter, string::len($old_chapter))) 
                    END
                    WHERE book_id = $book_record AND string::starts_with(chapter, $prefix)
                    RETURN id);

                RETURN array::len($exact) + array::len($prefixed);
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf(
                "book_id" to bookId,
                "old_chapter" to oldChapter,
                "new_chapter" to newChapter
            )
        ).takeTransaction(0)

        return result.long.toInt()
    }
}
