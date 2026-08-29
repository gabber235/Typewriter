package com.typewritermc.realm.routes

import com.typewritermc.library.Book
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooksResponse

internal class BookRoutes(
    private val books: BookRepository,
    private val contracts: LibraryContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchBooks) {
                val result = childSpan("db.book.list") { books.listBooks() }
                WatchBooksResponse.ListWrapper(result.map(Book::toSkir))
            }
            watch(contracts.watchBook) { call ->
                call.request.bookId.invalidRecordId("book")?.let {
                    return@watch WatchBookResponse.InvalidRecordIdErrorWrapper(it)
                }
                val book =
                    childSpan("db.book.get") { books.getBook(call.request.bookId.toBookId()) }
                        ?: return@watch WatchBookResponse.createBookNotFoundError(bookId = call.request.bookId)
                WatchBookResponse.InitialWrapper(book.toSkir())
            }
        }
}
