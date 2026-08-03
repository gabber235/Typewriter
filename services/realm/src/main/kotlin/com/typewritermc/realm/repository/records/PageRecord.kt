package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.realm.repository.utils.toPageType
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.library.v1.page.Page

internal data class PageRecord(
    val id: RecordId = RecordId("page", ""),
    val book: RecordId = RecordId("book", ""),
    val name: String = "",
    val type: String = "sequence",
    val chapter: String = "",
    val priority: Int = 0,
) {
    fun toPage(): Page =
        Page(
            pageId = id.toSkirRecordId(),
            bookId = book.toSkirRecordId(),
            name = name,
            type = type.toPageType(),
            chapter = chapter,
            priority = priority,
        )

    companion object {
        fun parseList(result: Value): List<PageRecord> = result.parseRecords(PageRecord::class.java)
    }
}
