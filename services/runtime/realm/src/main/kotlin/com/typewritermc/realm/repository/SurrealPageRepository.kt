package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.BookId
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.utils.surrealId

class SurrealPageRepository(
    private val database: Surreal,
) : PageRepository {
    override suspend fun searchPages(
        bookId: BookId,
        search: String?,
    ): List<Page> {
        val query =
            if (search == null) {
                $$"SELECT * FROM page WHERE book = $book ORDER BY priority, name, id"
            } else {
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
}
