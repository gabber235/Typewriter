package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.records.BookMutationRecord
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toSkirRecordId
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
                    revision = 1,
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

    override suspend fun updateBook(
        expectedRevision: Long,
        book: Book,
    ): RevisionedRepositoryResult<Book> =
        revisionedRepositoryMutation {
            val result =
                database
                    .get()
                    .query(
                        $$"""
                BEGIN TRANSACTION;

                LET $actual = SELECT * FROM ONLY $book;
                LET $result = IF $actual = NONE {
                    THROW "book-not-found-error";
                } ELSE IF $actual.revision != $expected_revision {
                    { conflict: true, actual: $actual, errorSlug: "", relatedIds: [] };
                } ELSE {
                    LET $target_tags = array::distinct($tags);
                    LET $missing_tags = $target_tags.filter(|$tag| !record::exists($tag));

                    IF $missing_tags != [] {
                        {
                            conflict: false,
                            actual: $actual,
                            errorSlug: "tags-not-found-error",
                            relatedIds: $missing_tags,
                        };
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

                        {
                            conflict: false,
                            actual: (SELECT * FROM ONLY $book),
                            errorSlug: "",
                            relatedIds: [],
                        };
                    };
                };

                RETURN $result;
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

            val mutation = BookMutationRecord.parse(result)
            val actual = mutation.actual.toBook()
            when {
                mutation.conflict -> {
                    RevisionedRepositoryResult.Conflict(actual)
                }

                mutation.errorSlug.isNotEmpty() -> {
                    RevisionedRepositoryResult.DomainFailure(
                        mutation.errorSlug,
                        mutation.relatedIds.map { it.toSkirRecordId() },
                    )
                }

                else -> {
                    RevisionedRepositoryResult.Success(actual)
                }
            }
        }
}
