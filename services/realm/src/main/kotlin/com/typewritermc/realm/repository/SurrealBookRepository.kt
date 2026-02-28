package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.BookRecord
import com.typewritermc.realm.repository.utils.requireValidId
import protokt.v1.typewriter.models.v1.Book

class SurrealBookRepository(
    private val db: Surreal
) : BookRepository {

    override suspend fun listBooks(): List<Book> {
        val result = db.query("SELECT * FROM book")
            .take(0)

        if (result.isNone) return emptyList()

        return BookRecord.parseList(result).map { it.toBook() }
    }

    override suspend fun getBook(id: String): Book? {
        requireValidId("Book", id)

        val result = db.queryBind(
            $$"SELECT * FROM type::thing('book', $id)",
            mapOf("id" to id)
        ).take(0)

        if (result.isNone) return null

        return BookRecord.parseList(result).firstOrNull()?.toBook()
    }

    override suspend fun createBook(title: String, icon: String, color: Int): Book {
        val colorLong = color.toUInt().toLong()
        val result = db.queryBind(
            $$"""
            CREATE book SET
                title = $title, 
                icon = $icon, 
                color = $color
            """.trimIndent(),
            mapOf("title" to title, "icon" to icon, "color" to colorLong)
        ).take(0)

        val records = BookRecord.parseList(result)
        val record = records.firstOrNull() ?: throw IllegalStateException("Failed to create book")

        return record.toBook()
    }

    override suspend fun updateBook(book: Book): Book {
        val colorLong = (book.color?.value ?: 0u).toLong()

        requireValidId("Book", book.id)

        val result = db.queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $book_record = type::thing('book', $id);
                UPDATE $book_record SET 
                    title = $title, 
                    icon = $icon, 
                    color = $color;
                    
                LET $target_tags = $tag_ids.map(|$id| type::thing('tag', $id));
                LET $current_tags = SELECT VALUE ->bears->tag FROM ONLY $book_record;
                
                LET $new_tags = array::complement($target_tags, $current_tags);
                LET $remove_tags = array::complement($current_tags, $target_tags);
                
                FOR $tag IN $new_tags {
                    RELATE $book_record->bears->$tag;
                };
                
                FOR $tag IN $remove_tags {
                    DELETE bears WHERE in = $book_record AND out = $tag;
                };
                
                RETURN SELECT * FROM $book_record;
            
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf(
                "id" to book.id,
                "title" to book.title,
                "icon" to book.icon,
                "color" to colorLong,
                "tag_ids" to book.tags.map { it.id })
        ).take(0)
        return BookRecord.parseList(result).firstOrNull()?.toBook()
            ?: throw IllegalStateException("Failed to update book")
    }

    override suspend fun deleteBook(id: String): Boolean {
        requireValidId("Book", id)

        return db.queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $book_record = type::thing('book', $id);
                
                IF !record::exists($book_record) {
                    RETURN false;
                };
                DELETE bears WHERE in = $book_record;
                DELETE $book_record;
                RETURN true;
                COMMIT TRANSACTION;
                """.trimIndent(),
            mapOf("id" to id)
        ).take(0).boolean
    }

    override suspend fun addTagToBook(bookId: String, tagId: String): Boolean {
        requireValidId("Book", bookId)
        requireValidId("Tag", tagId)

        return db.queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $book_record = type::thing('book', $bookId);
                LET $tag_record = type::thing('tag', $tagId);
                IF !record::exists($book_record) || !record::exists($tag_record) {
                    RETURN false;
                };
                RELATE $book_record->bears->$tag_record;
                RETURN true;
                COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("bookId" to bookId, "tagId" to tagId)
        )
            .take(0).boolean
    }

    override suspend fun removeTagFromBook(bookId: String, tagId: String): Boolean {
        requireValidId("Book", bookId)
        requireValidId("Tag", tagId)

        return db.queryBind(
            $$"""
                BEGIN TRANSACTION;
                LET $book_record = type::thing('book', $bookId);
                LET $tag_record = type::thing('tag', $tagId);
                
                LET $bears = SELECT VALUE id FROM bears WHERE in = $book_record AND out = $tag_record;
                
                IF array::is_empty($bears) {
                    RETURN false;
                };
                
                DELETE array::first($bears);
                RETURN true;
                COMMIT TRANSACTION;
                """.trimIndent(),
            mapOf("bookId" to bookId, "tagId" to tagId)
        ).take(0).boolean
    }
}
