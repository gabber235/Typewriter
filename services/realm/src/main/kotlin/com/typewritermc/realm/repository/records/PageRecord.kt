package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.ResourceRevision
import com.typewritermc.realm.repository.PageUpdateResult
import com.typewritermc.realm.repository.utils.pageKindRef
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId

internal data class PageRecord(
    val id: RecordId = RecordId("page", ""),
    val revision: Long = 1,
    val book: RecordId = RecordId("book", ""),
    val name: String = "",
    val kind: PageKindRecord = PageKindRecord(),
    val chapter: String = "",
    val priority: Int = 0,
) {
    fun toPage(): Page =
        Page(
            id = id.toPageId(),
            revision = ResourceRevision(revision),
            bookId = book.toBookId(),
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

internal data class PageUpdateOutputRecord(
    val kind: String = "",
    val page: PageRecord? = null,
) {
    fun toResult(): PageUpdateResult =
        when (kind) {
            "success" -> PageUpdateResult.Success(requirePage())
            "conflict" -> PageUpdateResult.Conflict(requirePage())
            "not_found" -> PageUpdateResult.NotFound
            else -> error("Invalid page update outcome '$kind'.")
        }

    private fun requirePage(): Page = page?.toPage() ?: error("Page update outcome '$kind' requires a page.")

    companion object {
        fun parse(result: Value): PageUpdateOutputRecord = result.get(PageUpdateOutputRecord::class.java)
    }
}
