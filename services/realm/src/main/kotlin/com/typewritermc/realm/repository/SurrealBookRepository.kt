package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.LibraryName
import com.typewritermc.library.TagId
import com.typewritermc.realm.outbox.RealmOutbox
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.records.BookCreateOutputRecord
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.records.BookUpdateOutputRecord
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.surrealTagIds
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.types.Color
import com.typewritermc.types.Icon

class SurrealBookRepository(
    private val database: Surreal,
    private val outbox: RealmOutbox = SurrealRealmOutbox(database),
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

    override suspend fun createBook(
        title: LibraryName,
        icon: Icon,
        color: Color,
        tagIds: Set<TagId>,
        encodeEvents: (Book) -> List<com.typewritermc.realm.outbox.OutboxEvent>,
    ): BookCreateResult {
        val mutation =
            database.inTransaction { transaction ->
                val result =
                    transaction
                        .query(
                            $$"""
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

                            """.trimIndent(),
                            mapOf(
                                "title" to title.value,
                                "icon" to icon.wireValue,
                                "color" to color.argb.toLong(),
                                "tags" to tagIds.surrealTagIds(),
                            ),
                        ).takeTransaction(3)
                BookCreateOutputRecord.parse(result).toResult().also { mutation ->
                    if (mutation is BookCreateResult.Success) outbox.enqueue(transaction, encodeEvents(mutation.book))
                }
            }
        if (mutation is BookCreateResult.Success) outbox.signalPending()
        return mutation
    }

    override suspend fun updateBook(
        expectedRevision: Long,
        book: Book,
        encodeEvents: (Book) -> List<com.typewritermc.realm.outbox.OutboxEvent>,
    ): BookUpdateResult {
        val mutation =
            database.inTransaction { transaction ->
                val result =
                    transaction
                        .query(
                            $$"""
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
                            """.trimIndent(),
                            mapOf(
                                "book" to book.id.surrealId(),
                                "expected_revision" to expectedRevision,
                                "title" to book.title.value,
                                "icon" to book.icon.wireValue,
                                "color" to book.color.argb.toLong(),
                                "tags" to book.tags.surrealTagIds(),
                            ),
                        ).takeTransaction(2)
                BookUpdateOutputRecord.parse(result).toResult().also { mutation ->
                    if (mutation is BookUpdateResult.Success) outbox.enqueue(transaction, encodeEvents(mutation.book))
                }
            }
        if (mutation is BookUpdateResult.Success) outbox.signalPending()
        return mutation
    }
}
