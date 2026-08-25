package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.utils.surrealId

class SurrealBookRepository(
    private val database: Surreal,
) : BookRepository {
    override suspend fun listBooks(): List<Book> {
        val result = database.query("SELECT * FROM book ORDER BY title, id").take(0)
        return BookRecord.parseList(result).map(BookRecord::toBook)
    }

    override suspend fun getBook(id: BookId): Book? {
        val result =
            database
                .query(
                    $$"SELECT * FROM type::record('book', $id)",
                    mapOf("id" to id.surrealId()),
                ).take(0)
        return BookRecord.parseList(result).firstOrNull()?.toBook()
    }
}
