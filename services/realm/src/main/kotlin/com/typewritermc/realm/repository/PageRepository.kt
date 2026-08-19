package com.typewritermc.realm.repository

import com.typewritermc.realm.outbox.OutboxEvent
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType

interface PageRepository {
    suspend fun searchPages(
        bookId: RecordId,
        search: String?,
    ): List<Page>

    suspend fun getPage(id: RecordId): Page?

    suspend fun createPage(
        bookId: RecordId,
        name: String,
        type: PageType,
        chapter: String,
        priority: Int,
        encodeEvents: (Page) -> List<OutboxEvent>,
    ): RepositoryResult<Page>

    suspend fun updatePage(
        page: Page,
        encodeEvents: (Page) -> List<OutboxEvent>,
    ): RepositoryResult<Page>

    suspend fun deletePage(
        id: RecordId,
        encodeEvents: (RecordId) -> List<OutboxEvent>,
    ): RepositoryResult<Unit>

    suspend fun changePagesChapters(
        bookId: RecordId,
        oldChapter: String,
        newChapter: String,
        encodeEvents: (List<Page>) -> List<OutboxEvent>,
    ): RepositoryResult<List<Page>>
}
