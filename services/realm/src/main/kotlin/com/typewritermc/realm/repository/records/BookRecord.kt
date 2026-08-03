package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.Book

internal data class BookRecord(
    val id: RecordId = RecordId("book", ""),
    val title: String = "",
    val icon: String = "",
    val color: Long = 0L,
    val tags: List<RecordId> = emptyList(),
) {
    fun toBook(): Book = Book(
        bookId = id.toSkirRecordId(),
        title = title,
        icon = icon,
        color = Color(argb = color.toInt()),
        tagIds = tags.map(RecordId::toSkirRecordId),
    )

    companion object {
        fun parseList(result: Value): List<BookRecord> = result.parseRecords(BookRecord::class.java)
    }
}
