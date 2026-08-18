package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey

internal class RepositoryFixture : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    private val database =
        Surreal().apply {
            connect("memory")
            useNs("realm_repository_test").useDb("realm_repository_test")
        }
    val books = SurrealBookRepository(database)
    val pages = SurrealPageRepository(database)
    val tags = SurrealTagRepository(database)

    init {
        telemetry.telemetry.mainSpanBlocking(
            name = "test.realm.migrate",
            unhandledFailureSlug = ErrorSlug.of("test-realm-migrate-failed"),
        ) {
            SchemaMigrator(database).migrate()
        }
    }

    override fun close() {
        try {
            database.close()
        } finally {
            telemetry.close()
        }
    }
}

internal fun recordId(
    table: String,
    key: String,
) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

internal fun <Value> RepositoryResult<Value>.successValue(): Value =
    when (this) {
        is RepositoryResult.Success -> value
        is RepositoryResult.DomainFailure -> error("Expected success but received $slug")
    }

internal fun RepositoryResult<*>.failureSlug(): String =
    when (this) {
        is RepositoryResult.Success -> error("Expected domain failure")
        is RepositoryResult.DomainFailure -> slug
    }

internal fun BookCreateResult.successValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookCreateResult.Success -> book
        BookCreateResult.TitleInvalid -> error("Expected success but title was invalid")
        BookCreateResult.IconRequired -> error("Expected success but icon was required")
        is BookCreateResult.TagsNotFound -> error("Expected success but tags were missing")
    }

internal fun BookUpdateResult.successValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookUpdateResult.Success -> book
        is BookUpdateResult.Conflict -> error("Expected success but received a conflict")
        BookUpdateResult.NotFound -> error("Expected success but the book was missing")
        BookUpdateResult.TitleInvalid -> error("Expected success but title was invalid")
        BookUpdateResult.IconRequired -> error("Expected success but icon was required")
        is BookUpdateResult.TagsNotFound -> error("Expected success but tags were missing")
    }

internal fun BookUpdateResult.conflictValue(): skirout.library.v1.book.Book =
    when (this) {
        is BookUpdateResult.Conflict -> actual
        is BookUpdateResult.Success -> error("Expected conflict but received success")
        BookUpdateResult.NotFound -> error("Expected conflict but the book was missing")
        BookUpdateResult.TitleInvalid -> error("Expected conflict but title was invalid")
        BookUpdateResult.IconRequired -> error("Expected conflict but icon was required")
        is BookUpdateResult.TagsNotFound -> error("Expected conflict but tags were missing")
    }

internal fun TagCreateResult.successValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagCreateResult.Success -> tag
        TagCreateResult.NameInvalid -> error("Expected success but name was invalid")
        TagCreateResult.WidthInvalid -> error("Expected success but width was invalid")
        TagCreateResult.HeightInvalid -> error("Expected success but height was invalid")
        is TagCreateResult.ParentsNotFound -> error("Expected success but parents were missing")
    }

internal fun TagUpdateResult.successValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagUpdateResult.Success -> tag
        is TagUpdateResult.Conflict -> error("Expected success but received a conflict")
        TagUpdateResult.NotFound -> error("Expected success but the tag was missing")
        TagUpdateResult.NameInvalid -> error("Expected success but name was invalid")
        TagUpdateResult.WidthInvalid -> error("Expected success but width was invalid")
        TagUpdateResult.HeightInvalid -> error("Expected success but height was invalid")
        is TagUpdateResult.ParentsNotFound -> error("Expected success but parents were missing")
        TagUpdateResult.InheritanceCycle -> error("Expected success but inheritance had a cycle")
    }

internal fun TagUpdateResult.conflictValue(): skirout.library.v1.tag.Tag =
    when (this) {
        is TagUpdateResult.Conflict -> actual
        is TagUpdateResult.Success -> error("Expected conflict but received success")
        TagUpdateResult.NotFound -> error("Expected conflict but the tag was missing")
        TagUpdateResult.NameInvalid -> error("Expected conflict but name was invalid")
        TagUpdateResult.WidthInvalid -> error("Expected conflict but width was invalid")
        TagUpdateResult.HeightInvalid -> error("Expected conflict but height was invalid")
        is TagUpdateResult.ParentsNotFound -> error("Expected conflict but parents were missing")
        TagUpdateResult.InheritanceCycle -> error("Expected conflict but inheritance had a cycle")
    }

internal fun TagDeleteResult.successValue(): TagDeletion =
    when (this) {
        is TagDeleteResult.Success -> deletion
        TagDeleteResult.NotFound -> error("Expected success but the tag was missing")
    }

internal suspend fun SurrealBookRepository.updateBook(book: skirout.library.v1.book.Book) = updateBook(book.revision, book)

internal suspend fun SurrealTagRepository.updateTag(tag: skirout.library.v1.tag.Tag) = updateTag(tag.revision, tag)
