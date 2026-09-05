package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.ref
import com.typewritermc.realm.repository.utils.pageKindRef
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId

internal data class PageRecord(
    val id: RecordId = RecordId("page", ""),
    val book: RecordId = RecordId("book", ""),
    val name: String = "",
    val kind: PageKindRecord = PageKindRecord(),
    val chapter: String = "",
    val priority: Int = 0,
) {
    fun toPage(): Page =
        Page(
            id = id.toPageId(),
            book = book.toBookId().ref(),
            name = LibraryName(name),
            kind = kind.toPageKindRef(),
            chapter = ChapterPath.parse(chapter),
            priority = priority,
        )

    companion object {
        fun parseList(result: Value): List<PageRecord> = result.parseRecords(PageRecord::class.java)
    }
}

internal data class PageKindRecord(
    val id: String = "",
    val revision: Int = 0,
) {
    fun toPageKindRef() = pageKindRef(id, revision)
}
