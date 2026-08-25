package com.typewritermc.realm.routes

import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.ResourceRevision
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.PageUpdateResult
import com.typewritermc.realm.repository.RepositoryFailure
import com.typewritermc.realm.repository.RepositoryResult
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.library.v1.page.ChangePageKindResponse
import skirout.library.v1.page.ChangePagesChaptersResponse
import skirout.library.v1.page.CreatePageResponse
import skirout.library.v1.page.DeletePageResponse
import skirout.library.v1.page.PageValidationError
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.UpdatePageResponse
import skirout.library.v1.page.WatchPageResponse

internal class PageRoutes(
    private val pages: PageRepository,
    private val books: BookRepository,
    private val pageCatalog: PageCatalog,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchPages) { call ->
                call.request.bookId.invalidRecordId("book")?.let {
                    return@unary SearchPagesResponse.InvalidRecordIdErrorWrapper(it)
                }
                val book =
                    childSpan("db.book.get") { books.getBook(call.request.bookId.toBookId()) }
                        ?: return@unary SearchPagesResponse.createBookNotFoundError(bookId = call.request.bookId)
                val result =
                    childSpan("db.page.search") {
                        pages.searchPages(book.id, call.request.search?.takeIf(String::isNotBlank))
                    }
                SearchPagesResponse.SuccessWrapper(result.map(Page::toSkir))
            }
            watch(contracts.watchPage) { call ->
                call.request.pageId.invalidRecordId("page")?.let {
                    return@watch WatchPageResponse.InvalidRecordIdErrorWrapper(it)
                }
                val page =
                    childSpan("db.page.get") { pages.getPage(call.request.pageId.toPageId()) }
                        ?: return@watch WatchPageResponse.createPageNotFoundError(pageId = call.request.pageId)
                WatchPageResponse.InitialWrapper(page.toSkir())
            }
            unary(contracts.createPage) { call -> create(call) }
            unary(contracts.updatePage) { call -> update(call) }
            unary(contracts.deletePage) { call -> delete(call) }
            unary(contracts.changePagesChapters) { call -> changeChapters(call) }
            unary(contracts.changePageKind) { call -> changeKind(call) }
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
        validate(request.name, request.kind)?.let { return CreatePageResponse.ValidationErrorWrapper(it) }
        val book =
            childSpan("db.book.get") { books.getBook(request.bookId.toBookId()) }
                ?: return CreatePageResponse.createBookNotFoundError(bookId = request.bookId)
        val result =
            childSpan("db.page.create") {
                pages.createPage(
                    bookId = book.id,
                    name = LibraryName(request.name),
                    kind = request.kind.toLibrary(),
                    chapter = ChapterPath.parse(request.chapter.orEmpty()),
                    priority = request.priority ?: 0,
                    encodeEvents = { page -> pageEvents(WatchPageResponse.UpdateWrapper(page.toSkir())) },
                )
            }
        val page =
            when (result) {
                is RepositoryResult.Success -> result.value

                is RepositoryResult.DomainFailure -> return when (result.failure) {
                    RepositoryFailure.BOOK_NOT_FOUND -> {
                        CreatePageResponse.createBookNotFoundError(bookId = request.bookId)
                    }

                    RepositoryFailure.PAGE_NAME_INVALID -> {
                        CreatePageResponse.ValidationErrorWrapper(PageValidationError.NAME_REQUIRED)
                    }

                    RepositoryFailure.PAGE_NOT_FOUND,
                    RepositoryFailure.PAGE_CHAPTER_INVALID,
                    -> {
                        error("Unexpected page creation domain error: ${result.failure}")
                    }
                }
            }
        return CreatePageResponse.SuccessWrapper(page.toSkir())
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
        val existing =
            childSpan("db.page.get") { pages.getPage(request.pageId.toPageId()) }
                ?: return UpdatePageResponse.createPageNotFoundError(pageId = request.pageId)
        validateName(request.name ?: existing.name.value)?.let {
            return UpdatePageResponse.ValidationErrorWrapper(it)
        }
        val result =
            childSpan("db.page.update") {
                pages.updatePage(
                    existing.copy(
                        revision = ResourceRevision(request.expectedRevision),
                        name = LibraryName(request.name ?: existing.name.value),
                        chapter = ChapterPath.parse(request.chapter ?: existing.chapter.value),
                        priority = request.priority ?: existing.priority,
                    ),
                    encodeEvents = { page -> pageEvents(WatchPageResponse.UpdateWrapper(page.toSkir())) },
                )
            }
        val page =
            when (result) {
                is PageUpdateResult.Success -> {
                    result.page
                }

                is PageUpdateResult.Conflict -> {
                    return UpdatePageResponse.createConflictError(
                        expectedRevision = request.expectedRevision,
                        actual = result.actual.toSkir(),
                    )
                }

                PageUpdateResult.NotFound -> {
                    return UpdatePageResponse.createPageNotFoundError(pageId = request.pageId)
                }
            }
        return UpdatePageResponse.SuccessWrapper(page.toSkir())
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
        when (
            val result =
                childSpan("db.page.delete") {
                    pages.deletePage(id.toPageId()) { pageId ->
                        pageEvents(WatchPageResponse.RemoveWrapper(pageId.toSkirRecordId()))
                    }
                }
        ) {
            is RepositoryResult.Success -> Unit

            is RepositoryResult.DomainFailure -> return when (result.failure) {
                RepositoryFailure.PAGE_NOT_FOUND -> DeletePageResponse.createPageNotFoundError(pageId = id)

                RepositoryFailure.BOOK_NOT_FOUND,
                RepositoryFailure.PAGE_NAME_INVALID,
                RepositoryFailure.PAGE_CHAPTER_INVALID,
                -> error("Unexpected page deletion domain error: ${result.failure}")
            }
        }
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
        val book =
            childSpan("db.book.get") { books.getBook(request.bookId.toBookId()) }
                ?: return ChangePagesChaptersResponse.createBookNotFoundError(bookId = request.bookId)
        val result =
            childSpan("db.page.change_chapters") {
                pages.changePagesChapters(
                    book.id,
                    ChapterPath.parse(request.oldChapter),
                    ChapterPath.parse(request.newChapter),
                ) { changed ->
                    changed.map { page ->
                        contracts.watchPage.encodeUpdate(realmAddress, WatchPageResponse.UpdateWrapper(page.toSkir()))
                    }
                }
            }
        val updated =
            when (result) {
                is RepositoryResult.Success -> result.value

                is RepositoryResult.DomainFailure -> return when (result.failure) {
                    RepositoryFailure.BOOK_NOT_FOUND -> {
                        ChangePagesChaptersResponse.createBookNotFoundError(bookId = request.bookId)
                    }

                    RepositoryFailure.PAGE_NOT_FOUND,
                    RepositoryFailure.PAGE_NAME_INVALID,
                    RepositoryFailure.PAGE_CHAPTER_INVALID,
                    -> {
                        error("Unexpected chapter mutation domain error: ${result.failure}")
                    }
                }
            }
        return ChangePagesChaptersResponse.createSuccess(updatedCount = updated.size)
    }

    private fun pageEvents(response: WatchPageResponse) = listOf(contracts.watchPage.encodeUpdate(realmAddress, response))

    private fun validate(
        name: String,
        kind: skirout.kernel.v1.page_kind.PageKindRef,
    ): PageValidationError? = validateName(name) ?: validateKind(kind)

    private fun validateName(name: String): PageValidationError? = PageValidationError.NAME_REQUIRED.takeIf { name.isBlank() }

    private fun validateKind(kind: skirout.kernel.v1.page_kind.PageKindRef): PageValidationError? {
        val definition =
            pageCatalog.definitions.singleOrNull {
                it.kind.id.value
                    .toString() == kind.id.value
            }
                ?: return PageValidationError.PAGE_KIND_UNKNOWN
        return PageValidationError.PAGE_KIND_REVISION_UNKNOWN.takeIf { definition.kind.revision != kind.revision }
    }

    context(main: MainSpanScope)
    private suspend fun changeKind(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.page.ChangePageKindRequest,
            ChangePageKindResponse,
        >,
    ): ChangePageKindResponse {
        val request = call.request
        request.pageId.invalidRecordId("page")?.let {
            return ChangePageKindResponse.InvalidRecordIdErrorWrapper(it)
        }
        childSpan("db.page.get") { pages.getPage(request.pageId.toPageId()) }
            ?: return ChangePageKindResponse.createPageNotFoundError(pageId = request.pageId)
        validateKind(request.target)?.let { return ChangePageKindResponse.ValidationErrorWrapper(it) }
        return ChangePageKindResponse.createConversionUnavailable()
    }
}
