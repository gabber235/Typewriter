package com.typewritermc.realm.repository

import com.typewritermc.library.BookId
import com.typewritermc.library.Page
import com.typewritermc.library.PageId

interface PageRepository {
    suspend fun searchPages(
        bookId: BookId,
        search: String?,
    ): List<Page>

    suspend fun getPage(id: PageId): Page?
}
