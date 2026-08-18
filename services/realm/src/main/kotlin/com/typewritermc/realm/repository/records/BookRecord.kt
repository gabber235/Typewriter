package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
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

internal data class BookMutationRecord(
    val conflict: Boolean = false,
    val actual: BookRecord = BookRecord(),
    val errorSlug: String = "",
    val relatedIds: List<RecordId> = emptyList(),
) {
    companion object {
        fun parse(result: Value): BookMutationRecord = result.get(BookMutationRecord::class.java)
    }
}
