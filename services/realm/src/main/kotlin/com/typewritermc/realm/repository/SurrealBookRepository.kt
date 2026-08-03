package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.services.libs.utils.DeferredProvider
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.book.Book

class SurrealBookRepository(
    private val database: DeferredProvider<Surreal>,
) : BookRepository {
    override suspend fun listBooks(): List<Book> {
        val result = database.get().query("SELECT * FROM book ORDER BY title, id").take(0)
        return BookRecord.parseList(result).map(BookRecord::toBook)
    }

    override suspend fun getBook(id: RecordId): Book? {
        val result =
            database
                .get()
                .query(
                    $$"SELECT * FROM type::record('book', $id)",
                    mapOf("id" to id.surrealId("book")),
                ).take(0)
        return BookRecord.parseList(result).firstOrNull()?.toBook()
    }

    override suspend fun createBook(
        title: String,
        icon: String,
        color: Color,
        tagIds: List<RecordId>,
    ): RepositoryResult<Book> =
        repositoryMutation(tagIds) {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                LET $distinct_tags = array::distinct($tags);

                IF $distinct_tags.any(|$tag| !record::exists($tag)) {
                    THROW "tags-not-found-error";
                };

                LET $book = CREATE ONLY book SET
                    title = $title,
                    icon = $icon,
                    color = $color;

                FOR $tag IN $distinct_tags {
                    RELATE $book->bears->$tag;
                };

                RETURN SELECT * FROM $book.id;

                COMMIT TRANSACTION;
                        """.trimIndent(),
                        mapOf(
                            "title" to title,
                            "icon" to icon,
                            "color" to color.argb.toUInt().toLong(),
                            "tags" to tagIds.surrealId("tag"),
                        ),
                    ).takeTransaction(5)

            BookRecord.parseList(result).singleOrNull()?.toBook()
                ?: error("Book creation returned no record")
        }

    override suspend fun updateBook(book: Book): RepositoryResult<Book> =
        repositoryMutation(book.tagIds) {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                LET $target_tags = array::distinct($tags);

                IF !record::exists($book) {
                    THROW "book-not-found-error";
                };

                IF $target_tags.any(|$tag| !record::exists($tag)) {
                    THROW "tags-not-found-error";
                };

                UPDATE $book SET
                    title = $title,
                    icon = $icon,
                    color = $color;

                LET $current_tags = SELECT VALUE ->bears->tag FROM ONLY $book;

                FOR $tag IN array::complement($target_tags, $current_tags) {
                    RELATE $book->bears->$tag;
                };

                FOR $tag IN array::complement($current_tags, $target_tags) {
                    DELETE bears WHERE in = $book AND out = $tag;
                };

                RETURN SELECT * FROM $book.id;
                COMMIT TRANSACTION;
                        """.trimIndent(),
                        mapOf(
                            "book" to book.bookId.surrealId("book"),
                            "title" to book.title,
                            "icon" to book.icon,
                            "color" to
                                book.color.argb
                                    .toUInt()
                                    .toLong(),
                            "tags" to book.tagIds.surrealId("tag"),
                        ),
                    ).takeTransaction(8)

            BookRecord.parseList(result).singleOrNull()?.toBook()
                ?: error("Book update returned no record")
        }
}
