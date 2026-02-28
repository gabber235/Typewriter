package com.typewritermc.realm.repository

import protokt.v1.typewriter.models.v1.Page
import protokt.v1.typewriter.models.v1.PageType

interface PageRepository {
    suspend fun listPages(bookId: String): List<Page>
    suspend fun searchPages(bookId: String, search: String): List<Page>
    suspend fun getPage(id: String): Page?
    suspend fun createPage(bookId: String, name: String, type: PageType, chapter: String, priority: Int): Page
    suspend fun updatePage(page: Page): Page
    suspend fun deletePage(id: String): Boolean
    suspend fun changePageChapter(pageId: String, chapter: String): Boolean
    suspend fun changePagePriority(pageId: String, priority: Int): Boolean
    suspend fun renamePage(pageId: String, name: String): Boolean
    suspend fun changePagesChapters(bookId: String, oldChapter: String, newChapter: String): Int
}
