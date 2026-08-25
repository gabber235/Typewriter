package com.typewritermc.realm.repository

import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.LibraryName
import com.typewritermc.library.TagId
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.types.Color
import com.typewritermc.types.Icon

interface BookRepository {
    suspend fun listBooks(): List<Book>

    suspend fun getBook(id: BookId): Book?

    suspend fun createBook(
        title: LibraryName,
        icon: Icon,
        color: Color,
        tagIds: Set<TagId>,
        encodeEvents: (Book) -> List<OutboxEvent>,
    ): BookCreateResult

    suspend fun updateBook(
        expectedRevision: Long,
        book: Book,
        encodeEvents: (Book) -> List<OutboxEvent>,
    ): BookUpdateResult
}

sealed interface BookCreateResult {
    data class Success(
        val book: Book,
    ) : BookCreateResult

    data object TitleInvalid : BookCreateResult

    data object IconRequired : BookCreateResult

    data class TagsNotFound(
        val tagIds: Set<TagId>,
    ) : BookCreateResult
}

sealed interface BookUpdateResult {
    data class Success(
        val book: Book,
    ) : BookUpdateResult

    data class Conflict(
        val actual: Book,
    ) : BookUpdateResult

    data object NotFound : BookUpdateResult

    data object TitleInvalid : BookUpdateResult

    data object IconRequired : BookUpdateResult

    data class TagsNotFound(
        val tagIds: Set<TagId>,
    ) : BookUpdateResult
}
