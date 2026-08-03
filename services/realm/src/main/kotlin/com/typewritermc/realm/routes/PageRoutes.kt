package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.RepositoryResult
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.library.v1.page.ChangePagesChaptersResponse
import skirout.library.v1.page.CreatePageResponse
import skirout.library.v1.page.DeletePageResponse
import skirout.library.v1.page.Page
import skirout.library.v1.page.PageType
import skirout.library.v1.page.PageValidationError
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.UpdatePageResponse
import skirout.library.v1.page.WatchPageResponse

internal class PageRoutes(
    private val pages: PageRepository,
    private val books: BookRepository,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) = with(builder) {
        unary(contracts.searchPages) { call ->
            call.request.bookId.invalidRecordId("book")?.let {
                return@unary SearchPagesResponse.InvalidRecordIdErrorWrapper(it)
            }
            val book = childSpan("db.book.get") { books.getBook(call.request.bookId) }
                ?: return@unary SearchPagesResponse.createBookNotFoundError(bookId = call.request.bookId)
            val result = childSpan("db.page.search") {
                pages.searchPages(book.bookId, call.request.search?.takeIf(String::isNotBlank))
            }
            SearchPagesResponse.SuccessWrapper(result)
        }
        watch(contracts.watchPage) { call ->
            call.request.pageId.invalidRecordId("page")?.let {
                return@watch WatchPageResponse.InvalidRecordIdErrorWrapper(it)
            }
            val page = childSpan("db.page.get") { pages.getPage(call.request.pageId) }
                ?: return@watch WatchPageResponse.createPageNotFoundError(pageId = call.request.pageId)
            WatchPageResponse.InitialWrapper(page)
        }
        unary(contracts.createPage) { call -> create(call) }
        unary(contracts.updatePage) { call -> update(call) }
        unary(contracts.deletePage) { call -> delete(call) }
        unary(contracts.changePagesChapters) { call -> changeChapters(call) }
    }

    context(main: MainSpanScope)
    private suspend fun create(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.page.CreatePageRequest,
            CreatePageResponse,
            >,
    ): CreatePageResponse {
        val request = call.request
        request.bookId.invalidRecordId("book")?.let {
            return CreatePageResponse.InvalidRecordIdErrorWrapper(it)
        }
        validate(request.name, request.type)?.let { return CreatePageResponse.ValidationErrorWrapper(it) }
        val book = childSpan("db.book.get") { books.getBook(request.bookId) }
            ?: return CreatePageResponse.createBookNotFoundError(bookId = request.bookId)
        val result = childSpan("db.page.create") {
            pages.createPage(
                bookId = book.bookId,
                name = request.name,
                type = request.type,
                chapter = request.chapter.orEmpty(),
                priority = request.priority ?: 0,
            )
        }
        val page = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "book-not-found-error" -> CreatePageResponse.createBookNotFoundError(bookId = request.bookId)
                "page-name-invalid-error" ->
                    CreatePageResponse.ValidationErrorWrapper(PageValidationError.NAME_REQUIRED)
                else -> error("Unexpected page creation domain error: ${result.slug}")
            }
        }
        publishPage(call.communicator, WatchPageResponse.UpdateWrapper(page))
        return CreatePageResponse.SuccessWrapper(page)
    }

    context(main: MainSpanScope)
    private suspend fun update(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.page.UpdatePageRequest,
            UpdatePageResponse,
            >,
    ): UpdatePageResponse {
        val request = call.request
        request.pageId.invalidRecordId("page")?.let {
            return UpdatePageResponse.InvalidRecordIdErrorWrapper(it)
        }
        val existing = childSpan("db.page.get") { pages.getPage(request.pageId) }
            ?: return UpdatePageResponse.createPageNotFoundError(pageId = request.pageId)
        validate(request.name ?: existing.name, request.type ?: existing.type)?.let {
            return UpdatePageResponse.ValidationErrorWrapper(it)
        }
        val result = childSpan("db.page.update") {
            pages.updatePage(
                Page(
                    pageId = existing.pageId,
                    bookId = existing.bookId,
                    name = request.name ?: existing.name,
                    type = request.type ?: existing.type,
                    chapter = request.chapter ?: existing.chapter,
                    priority = request.priority ?: existing.priority,
                ),
            )
        }
        val page = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "page-not-found-error" -> UpdatePageResponse.createPageNotFoundError(pageId = request.pageId)
                "page-name-invalid-error" ->
                    UpdatePageResponse.ValidationErrorWrapper(PageValidationError.NAME_REQUIRED)
                else -> error("Unexpected page update domain error: ${result.slug}")
            }
        }
        publishPage(call.communicator, WatchPageResponse.UpdateWrapper(page))
        return UpdatePageResponse.SuccessWrapper(page)
    }

    context(main: MainSpanScope)
    private suspend fun delete(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.page.DeletePageRequest,
            DeletePageResponse,
            >,
    ): DeletePageResponse {
        val id = call.request.pageId
        id.invalidRecordId("page")?.let {
            return DeletePageResponse.InvalidRecordIdErrorWrapper(it)
        }
        when (val result = childSpan("db.page.delete") { pages.deletePage(id) }) {
            is RepositoryResult.Success -> Unit
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "page-not-found-error" -> DeletePageResponse.createPageNotFoundError(pageId = id)
                else -> error("Unexpected page deletion domain error: ${result.slug}")
            }
        }
        publishPage(call.communicator, WatchPageResponse.RemoveWrapper(id))
        return DeletePageResponse.createSuccess()
    }

    context(main: MainSpanScope)
    private suspend fun changeChapters(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.page.ChangePagesChaptersRequest,
            ChangePagesChaptersResponse,
            >,
    ): ChangePagesChaptersResponse {
        val request = call.request
        request.bookId.invalidRecordId("book")?.let {
            return ChangePagesChaptersResponse.InvalidRecordIdErrorWrapper(it)
        }
        val book = childSpan("db.book.get") { books.getBook(request.bookId) }
            ?: return ChangePagesChaptersResponse.createBookNotFoundError(bookId = request.bookId)
        val result = childSpan("db.page.change_chapters") {
            pages.changePagesChapters(book.bookId, request.oldChapter, request.newChapter)
        }
        val updated = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "book-not-found-error" ->
                    ChangePagesChaptersResponse.createBookNotFoundError(bookId = request.bookId)
                else -> error("Unexpected chapter mutation domain error: ${result.slug}")
            }
        }
        for (page in updated) publishPage(call.communicator, WatchPageResponse.UpdateWrapper(page))
        return ChangePagesChaptersResponse.createSuccess(updatedCount = updated.size)
    }

    private suspend fun publishPage(
        communicator: com.typewritermc.services.libs.communicator.client.Communicator,
        response: WatchPageResponse,
    ) {
        communicator.publishUpdate(contracts.watchPage, realmAddress, response).requirePublished()
    }

    private fun validate(name: String, type: PageType): PageValidationError? = when {
        name.isBlank() -> PageValidationError.NAME_REQUIRED
        type is PageType.Unknown -> PageValidationError.PAGE_TYPE_UNKNOWN
        else -> null
    }
}
