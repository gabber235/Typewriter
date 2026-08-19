package com.typewritermc.realm.repository

import com.typewritermc.realm.outbox.OutboxEvent
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.book.Book

interface BookRepository {
    suspend fun listBooks(): List<Book>

    suspend fun getBook(id: RecordId): Book?

    suspend fun createBook(
        title: String,
        icon: String,
        color: Color,
        tagIds: List<RecordId>,
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
        val tagIds: List<RecordId>,
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
        val tagIds: List<RecordId>,
    ) : BookUpdateResult
}
