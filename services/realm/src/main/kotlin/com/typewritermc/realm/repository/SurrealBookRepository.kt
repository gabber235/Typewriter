package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.records.BookCreateOutputRecord
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.records.BookUpdateOutputRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.book.Book

class SurrealBookRepository(
    private val database: Surreal,
) : BookRepository {
    override suspend fun listBooks(): List<Book> {
        val result = database.query("SELECT * FROM book ORDER BY title, id").take(0)
        return BookRecord.parseList(result).map(BookRecord::toBook)
    }

    override suspend fun getBook(id: RecordId): Book? {
        val result =
            database
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
    ): BookCreateResult {
        val result =
            database
                .query(
                    $$"""
                BEGIN TRANSACTION;

                LET $distinct_tags = array::distinct($tags);
                LET $missing_tags = $distinct_tags.filter(|$tag| !record::exists($tag));
                LET $result = IF $missing_tags != [] {
                    { kind: "tags_not_found", tagIds: $missing_tags };
                } ELSE IF !fn::is_id($title) {
                    { kind: "title_invalid" };
                } ELSE IF string::trim($icon) == "" {
                    { kind: "icon_required" };
                } ELSE {
                    LET $book = CREATE ONLY book SET
                        revision = 1,
                        title = $title,
                        icon = $icon,
                        color = $color;

                    FOR $tag IN $distinct_tags {
                        RELATE $book->bears->$tag;
                    };

                    { kind: "success", bookId: $book.id };
                };

                RETURN IF $result.kind = "success" {
                    { kind: "success", book: (SELECT * FROM ONLY $result.bookId) };
                } ELSE {
                    $result;
                };

                COMMIT TRANSACTION;
                    """.trimIndent(),
                    mapOf(
                        "title" to title,
                        "icon" to icon,
                        "color" to color.argb.toUInt().toLong(),
                        "tags" to tagIds.surrealId("tag"),
                    ),
                ).takeTransaction(4)

        return BookCreateOutputRecord.parse(result).toResult()
    }

    override suspend fun updateBook(
        expectedRevision: Long,
        book: Book,
    ): BookUpdateResult {
        val result =
            database
                .query(
                    $$"""
                BEGIN TRANSACTION;

                LET $actual = SELECT * FROM ONLY $book;
                LET $result = IF $actual = NONE {
                    { kind: "not_found" };
                } ELSE IF $actual.revision != $expected_revision {
                    { kind: "conflict", book: $actual };
                } ELSE {
                    LET $target_tags = array::distinct($tags);
                    LET $missing_tags = $target_tags.filter(|$tag| !record::exists($tag));

                    IF $missing_tags != [] {
                        { kind: "tags_not_found", tagIds: $missing_tags };
                    } ELSE IF !fn::is_id($title) {
                        { kind: "title_invalid" };
                    } ELSE IF string::trim($icon) == "" {
                        { kind: "icon_required" };
                    } ELSE {
                        UPDATE ONLY $book SET
                            revision += 1,
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

                        { kind: "success", bookId: $book };
                    };
                };

                RETURN IF $result.kind = "success" {
                    { kind: "success", book: (SELECT * FROM ONLY $result.bookId) };
                } ELSE {
                    $result;
                };
                COMMIT TRANSACTION;
                    """.trimIndent(),
                    mapOf(
                        "book" to book.bookId.surrealId("book"),
                        "expected_revision" to expectedRevision,
                        "title" to book.title,
                        "icon" to book.icon,
                        "color" to
                            book.color.argb
                                .toUInt()
                                .toLong(),
                        "tags" to book.tagIds.surrealId("tag"),
                    ),
                ).takeTransaction(3)

        return BookUpdateOutputRecord.parse(result).toResult()
    }
}
