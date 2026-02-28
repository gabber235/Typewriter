package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.BookRecord
import com.typewritermc.realm.repository.utils.requireValidId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.services.libs.utils.DeferredProvider
import protokt.v1.typewriter.models.v1.Book

class SurrealBookRepository(
    private val db: DeferredProvider<Surreal>
) : BookRepository {

    override suspend fun listBooks(): List<Book> {
        val result = db.get().query("SELECT * FROM book")
            .takeTransaction(0)

        if (result.isNone) return emptyList()

        return BookRecord.parseList(result).map { it.toBook() }
    }

    override suspend fun getBook(id: String): Book? {
        requireValidId("Book", id)

        val result = db.get().queryBind(
            $$"SELECT * FROM type::thing('book', $id)",
            mapOf("id" to id)
        ).takeTransaction(0)

        if (result.isNone) return null

        return BookRecord.parseList(result).firstOrNull()?.toBook()
    }

    override suspend fun createBook(
        title: String,
        icon: String,
        color: Int,
        tagIds: List<String>
    ): Book {
        val colorLong = color.toUInt().toLong()

        // Create book and relationships in a single transaction
        val result = db.get().queryBind(
            $$"""
            BEGIN TRANSACTION;
            LET $book = CREATE book SET
                title = $title, 
                icon = $icon, 
                color = $color;
            
            LET $tags = $tag_ids.map(|$id| type::thing('tag', $id));
            FOR $tag IN $tags {
                IF record::exists($tag) {
                    RELATE $book->bears->$tag;
                };
            };
            
            RETURN SELECT * FROM $book.id;
            COMMIT TRANSACTION;
            """.trimIndent(),
            mapOf("title" to title, "icon" to icon, "color" to colorLong, "tag_ids" to tagIds)
        ).takeTransaction(0)

        if (result.isNone) {
            throw IllegalStateException("Failed to create book: no result returned")
        }

        val records = BookRecord.parseList(result)
        return records.firstOrNull()?.toBook()
            ?: throw IllegalStateException("Failed to create book: no book record returned")

    }

    override suspend fun updateBook(book: Book): Book {
        val colorLong = (book.color?.value ?: 0u).toLong()

        requireValidId("Book", book.bookId)

        val result = db.get().queryBind(
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
                "id" to book.bookId,
                "title" to book.title.orEmpty(),
                "icon" to book.icon.orEmpty(),
                "color" to colorLong,
                "tag_ids" to book.tagIds
            )
        ).takeTransaction(0)
        return BookRecord.parseList(result).firstOrNull()?.toBook()
            ?: throw IllegalStateException("Failed to update book")
    }

    override suspend fun deleteBook(id: String): Boolean {
        requireValidId("Book", id)

        return db.get().queryBind(
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
        ).takeTransaction(0).boolean
    }

    override suspend fun addTagToBook(bookId: String, tagId: String): Boolean {
        requireValidId("Book", bookId)
        requireValidId("Tag", tagId)

        return db.get().queryBind(
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
            .takeTransaction(0).boolean
    }

    override suspend fun removeTagFromBook(bookId: String, tagId: String): Boolean {
        requireValidId("Book", bookId)
        requireValidId("Tag", tagId)

        return db.get().queryBind(
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
        ).takeTransaction(0).boolean
    }
}
