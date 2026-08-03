package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.RepositoryResult
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.*

internal class BookRoutes(
    private val books: BookRepository,
    private val tags: TagRepository,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) = with(builder) {
        watch(contracts.watchBooks) {
            val result = childSpan("db.book.list") { books.listBooks() }
            WatchBooksResponse.ListWrapper(result)
        }
        watch(contracts.watchBook) { call ->
            call.request.bookId.invalidRecordId("book")?.let {
                return@watch WatchBookResponse.InvalidRecordIdErrorWrapper(it)
            }
            val book = childSpan("db.book.get") { books.getBook(call.request.bookId) }
                ?: return@watch WatchBookResponse.createBookNotFoundError(bookId = call.request.bookId)
            WatchBookResponse.InitialWrapper(book)
        }
        unary(contracts.createBook) { call -> create(call) }
        unary(contracts.updateBook) { call -> update(call) }
    }

    context(main: MainSpanScope)
    private suspend fun create(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
                RealmAddress,
                CreateBookRequest,
                CreateBookResponse,
                >,
    ): CreateBookResponse {
        val request = call.request
        if (request.title.isBlank()) {
            return CreateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
        }
        request.tagIds.invalidRecordId("tag")?.let {
            return CreateBookResponse.InvalidRecordIdErrorWrapper(it)
        }
        val missing = childSpan("db.tag.validate") { tags.findMissing(request.tagIds) }
        if (missing.isNotEmpty()) return CreateBookResponse.createTagsNotFoundError(tagIds = missing)
        val result = childSpan("db.book.create") {
            books.createBook(
                title = request.title,
                icon = request.icon?.takeIf(String::isNotBlank) ?: "book",
                color = request.color ?: Color(argb = 0),
                tagIds = request.tagIds,
            )
        }
        val book = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "book-title-invalid-error" ->
                    CreateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
                "book-icon-required-error" ->
                    CreateBookResponse.ValidationErrorWrapper(BookValidationError.ICON_REQUIRED)
                "tags-not-found-error" -> CreateBookResponse.createTagsNotFoundError(tagIds = result.relatedIds)
                else -> error("Unexpected book creation domain error: ${result.slug}")
            }
        }
        call.communicator.publishUpdate(
            contracts.watchBooks,
            realmAddress,
            WatchBooksResponse.AddWrapper(book),
        ).requirePublished()
        return CreateBookResponse.SuccessWrapper(book)
    }

    context(main: MainSpanScope)
    private suspend fun update(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
                RealmAddress,
                UpdateBookRequest,
                UpdateBookResponse,
                >,
    ): UpdateBookResponse {
        val request = call.request
        request.bookId.invalidRecordId("book")?.let {
            return UpdateBookResponse.InvalidRecordIdErrorWrapper(it)
        }
        request.tagIds?.let { ids ->
            ids.invalidRecordId("tag")?.let {
                return UpdateBookResponse.InvalidRecordIdErrorWrapper(it)
            }
        }
        val existing = childSpan("db.book.get") { books.getBook(request.bookId) }
            ?: return UpdateBookResponse.createBookNotFoundError(bookId = request.bookId)
        if (request.title?.isBlank() == true) {
            return UpdateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
        }
        if (request.icon?.isBlank() == true) {
            return UpdateBookResponse.ValidationErrorWrapper(BookValidationError.ICON_REQUIRED)
        }
        val tagIds = request.tagIds ?: existing.tagIds
        val missing = childSpan("db.tag.validate") { tags.findMissing(tagIds) }
        if (missing.isNotEmpty()) return UpdateBookResponse.createTagsNotFoundError(tagIds = missing)
        val result = childSpan("db.book.update") {
            books.updateBook(
                Book(
                    bookId = existing.bookId,
                    title = request.title ?: existing.title,
                    icon = request.icon ?: existing.icon,
                    color = request.color ?: existing.color,
                    tagIds = tagIds,
                ),
            )
        }
        val updated = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "book-not-found-error" -> UpdateBookResponse.createBookNotFoundError(bookId = request.bookId)
                "book-title-invalid-error" ->
                    UpdateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
                "book-icon-required-error" ->
                    UpdateBookResponse.ValidationErrorWrapper(BookValidationError.ICON_REQUIRED)
                "tags-not-found-error" -> UpdateBookResponse.createTagsNotFoundError(tagIds = result.relatedIds)
                else -> error("Unexpected book update domain error: ${result.slug}")
            }
        }
        call.communicator.publishUpdate(
            contracts.watchBooks,
            realmAddress,
            WatchBooksResponse.UpdateWrapper(updated),
        ).requirePublished()
        call.communicator.publishUpdate(
            contracts.watchBook,
            realmAddress,
            WatchBookResponse.UpdateWrapper(updated),
        ).requirePublished()
        return UpdateBookResponse.SuccessWrapper(updated)
    }
}

internal fun CommunicationResult<Unit>.requirePublished() {
    if (this is CommunicationResult.Failure) error("Watch publication failed: $error")
}
