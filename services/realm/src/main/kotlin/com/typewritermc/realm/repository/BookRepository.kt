package com.typewritermc.realm.repository

import com.typewritermc.library.Book
import com.typewritermc.library.BookId

interface BookRepository {
    suspend fun listBooks(): List<Book>

    suspend fun getBook(id: BookId): Book?
}
