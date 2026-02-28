package com.typewritermc.realm.repository

import protokt.v1.typewriter.models.v1.Book
import protokt.v1.typewriter.models.v1.Placement

interface BookRepository {
    suspend fun listBooks(): List<Book>
    suspend fun getBook(id: String): Book?
    suspend fun createBook(title: String, icon: String, color: Int): Book
    suspend fun updateBook(book: Book): Book
    suspend fun deleteBook(id: String): Boolean
    suspend fun addTagToBook(bookId: String, tagId: String): Boolean
    suspend fun removeTagFromBook(bookId: String, tagId: String): Boolean
}
