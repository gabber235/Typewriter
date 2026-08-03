package com.typewritermc.realm.repository

import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.book.Book

interface BookRepository {
    suspend fun listBooks(): List<Book>
    suspend fun getBook(id: RecordId): Book?
    suspend fun createBook(title: String, icon: String, color: Color, tagIds: List<RecordId>): RepositoryResult<Book>
    suspend fun updateBook(book: Book): RepositoryResult<Book>
}
