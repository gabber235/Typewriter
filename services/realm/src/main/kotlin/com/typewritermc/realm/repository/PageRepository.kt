package com.typewritermc.realm.repository

import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindRef
import com.typewritermc.realm.outbox.OutboxEvent

interface PageRepository {
    suspend fun searchPages(
        bookId: BookId,
        search: String?,
    ): List<Page>

    suspend fun getPage(id: PageId): Page?

    suspend fun createPage(
        bookId: BookId,
        name: LibraryName,
        kind: PageKindRef,
        chapter: ChapterPath,
        priority: Int,
        encodeEvents: (Page) -> List<OutboxEvent>,
    ): RepositoryResult<Page>

    suspend fun updatePage(
        page: Page,
        encodeEvents: (Page) -> List<OutboxEvent>,
    ): PageUpdateResult

    suspend fun deletePage(
        id: PageId,
        encodeEvents: (PageId) -> List<OutboxEvent>,
    ): RepositoryResult<Unit>

    suspend fun changePagesChapters(
        bookId: BookId,
        oldChapter: ChapterPath,
        newChapter: ChapterPath,
        encodeEvents: (List<Page>) -> List<OutboxEvent>,
    ): RepositoryResult<List<Page>>
}

sealed interface PageUpdateResult {
    data class Success(
        val page: Page,
    ) : PageUpdateResult

    data class Conflict(
        val actual: Page,
    ) : PageUpdateResult

    data object NotFound : PageUpdateResult
}
