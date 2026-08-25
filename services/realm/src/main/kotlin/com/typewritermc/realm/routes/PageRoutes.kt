package com.typewritermc.realm.routes

import com.typewritermc.library.Page
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.WatchPageResponse

internal class PageRoutes(
    private val pages: PageRepository,
    private val books: BookRepository,
    private val contracts: LibraryContracts,
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
        }
}
