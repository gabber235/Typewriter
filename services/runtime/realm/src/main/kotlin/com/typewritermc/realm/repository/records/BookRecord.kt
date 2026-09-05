package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.library.Book
import com.typewritermc.library.LibraryName
import com.typewritermc.library.ref
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.Color
import com.typewritermc.types.Icon

internal data class BookRecord(
    val id: RecordId = RecordId("book", ""),
    val title: String = "",
    val icon: String = "",
    val color: Long = 0L,
    val tags: List<RecordId> = emptyList(),
) {
    fun toBook(): Book =
        Book(
            id = id.toBookId(),
            title = LibraryName(title),
            icon = Icon.parse(icon),
            color = Color(argb = color.toUInt()),
            tags = tags.mapTo(linkedSetOf()) { it.toTagId().ref() },
        )

    companion object {
        fun parseList(result: Value): List<BookRecord> = result.parseRecords(BookRecord::class.java)
    }
}
