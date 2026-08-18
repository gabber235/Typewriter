package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.realm.repository.BookCreateResult
import com.typewritermc.realm.repository.BookUpdateResult
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.Book

internal data class BookRecord(
    val id: RecordId = RecordId("book", ""),
    val revision: Long = 1,
    val title: String = "",
    val icon: String = "",
    val color: Long = 0L,
    val tags: List<RecordId> = emptyList(),
) {
    fun toBook(): Book =
        Book(
            bookId = id.toSkirRecordId(),
            revision = revision,
            title = title,
            icon = icon,
            color = Color(argb = color.toInt()),
            tagIds = tags.map(RecordId::toSkirRecordId),
        )

    companion object {
        fun parseList(result: Value): List<BookRecord> = result.parseRecords(BookRecord::class.java)
    }
}

internal data class BookCreateOutputRecord(
    val kind: String = "",
    val book: BookRecord? = null,
    val tagIds: List<RecordId>? = null,
) {
    fun toResult(): BookCreateResult =
        when (kind) {
            "success" -> BookCreateResult.Success(requireBook().toBook())
            "title_invalid" -> BookCreateResult.TitleInvalid
            "icon_required" -> BookCreateResult.IconRequired
            "tags_not_found" -> BookCreateResult.TagsNotFound(requireTagIds())
            else -> invalidBookOutput("unknown create outcome '$kind'")
        }

    companion object {
        fun parse(result: Value): BookCreateOutputRecord = result.get(BookCreateOutputRecord::class.java)
    }

    private fun requireBook(): BookRecord = book ?: invalidBookOutput("create outcome '$kind' requires a book")

    private fun requireTagIds(): List<skirout.kernel.v1.record_id.RecordId> =
        tagIds
            ?.takeIf(List<*>::isNotEmpty)
            ?.map(RecordId::toSkirRecordId)
            ?: invalidBookOutput("create outcome '$kind' requires tag ids")
}

internal data class BookUpdateOutputRecord(
    val kind: String = "",
    val book: BookRecord? = null,
    val tagIds: List<RecordId>? = null,
) {
    fun toResult(): BookUpdateResult =
        when (kind) {
            "success" -> BookUpdateResult.Success(requireBook().toBook())
            "conflict" -> BookUpdateResult.Conflict(requireBook().toBook())
            "not_found" -> BookUpdateResult.NotFound
            "title_invalid" -> BookUpdateResult.TitleInvalid
            "icon_required" -> BookUpdateResult.IconRequired
            "tags_not_found" -> BookUpdateResult.TagsNotFound(requireTagIds())
            else -> invalidBookOutput("unknown update outcome '$kind'")
        }

    companion object {
        fun parse(result: Value): BookUpdateOutputRecord = result.get(BookUpdateOutputRecord::class.java)
    }

    private fun requireBook(): BookRecord = book ?: invalidBookOutput("update outcome '$kind' requires a book")

    private fun requireTagIds(): List<skirout.kernel.v1.record_id.RecordId> =
        tagIds
            ?.takeIf(List<*>::isNotEmpty)
            ?.map(RecordId::toSkirRecordId)
            ?: invalidBookOutput("update outcome '$kind' requires tag ids")
}

private fun invalidBookOutput(reason: String): Nothing = error("Invalid book mutation output: $reason")
