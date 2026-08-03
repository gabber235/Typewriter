package com.typewritermc.realm.repository

import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType

interface PageRepository {
    suspend fun searchPages(bookId: RecordId, search: String?): List<Page>
    suspend fun getPage(id: RecordId): Page?
    suspend fun createPage(
        bookId: RecordId,
        name: String,
        type: PageType,
        chapter: String,
        priority: Int,
    ): RepositoryResult<Page>
    suspend fun updatePage(page: Page): RepositoryResult<Page>
    suspend fun deletePage(id: RecordId): RepositoryResult<Unit>
    suspend fun changePagesChapters(
        bookId: RecordId,
        oldChapter: String,
        newChapter: String,
    ): RepositoryResult<List<Page>>
}
