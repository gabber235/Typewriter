package com.typewritermc.realm.routes

import com.typewritermc.library.Book
import com.typewritermc.library.LibraryName
import com.typewritermc.library.ResourceRevision
import com.typewritermc.realm.repository.BookCreateResult
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.BookUpdateResult
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import skirout.library.v1.book.BookValidationError
import skirout.library.v1.book.CreateBookRequest
import skirout.library.v1.book.CreateBookResponse
import skirout.library.v1.book.UpdateBookRequest
import skirout.library.v1.book.UpdateBookResponse
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooksResponse

internal class BookRoutes(
    private val books: BookRepository,
    private val tags: TagRepository,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
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
        val title = runCatching { LibraryName(request.title) }.getOrNull()
        if (title == null) {
            return CreateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
        }
        request.tagIds.invalidRecordId("tag")?.let {
            return CreateBookResponse.InvalidRecordIdErrorWrapper(it)
        }
        val tagIds = request.tagIds.mapTo(linkedSetOf()) { it.toTagId() }
        val missing = childSpan("db.tag.validate") { tags.findMissing(tagIds) }
        if (missing.isNotEmpty()) {
            return CreateBookResponse.createTagsNotFoundError(tagIds = missing.map { it.toSkirRecordId() })
        }
        val result =
            childSpan("db.book.create") {
                books.createBook(
                    title = title,
                    icon = Icon.parse(request.icon?.takeIf(String::isNotBlank) ?: "mdi:book"),
                    color = request.color?.toLibrary() ?: Color(argb = 0u),
                    tagIds = tagIds,
                    encodeEvents = { book ->
                        listOf(
                            contracts.watchBooks.encodeUpdate(
                                realmAddress,
                                WatchBooksResponse.AddWrapper(book.toSkir()),
                            ),
                        )
                    },
                )
            }
        val book =
            when (result) {
                is BookCreateResult.Success -> {
                    result.book
                }

                BookCreateResult.TitleInvalid -> {
                    return CreateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
                }

                BookCreateResult.IconRequired -> {
                    return CreateBookResponse.ValidationErrorWrapper(BookValidationError.ICON_REQUIRED)
                }

                is BookCreateResult.TagsNotFound -> {
                    return CreateBookResponse.createTagsNotFoundError(
                        tagIds = result.tagIds.map { it.toSkirRecordId() },
                    )
                }
            }
        return CreateBookResponse.SuccessWrapper(book.toSkir())
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
        request.tagIds.invalidRecordId("tag")?.let {
            return UpdateBookResponse.InvalidRecordIdErrorWrapper(it)
        }
        val title =
            runCatching { LibraryName(request.title) }.getOrNull()
                ?: return UpdateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
        val result =
            childSpan("db.book.update") {
                books.updateBook(
                    expectedRevision = request.expectedRevision,
                    Book(
                        id = request.bookId.toBookId(),
                        revision = ResourceRevision(request.expectedRevision),
                        title = title,
                        icon = Icon.parse(request.icon),
                        color = request.color.toLibrary(),
                        tags = request.tagIds.mapTo(linkedSetOf()) { it.toTagId() },
                    ),
                    encodeEvents = { updated ->
                        listOf(
                            contracts.watchBooks.encodeUpdate(
                                realmAddress,
                                WatchBooksResponse.UpdateWrapper(updated.toSkir()),
                            ),
                            contracts.watchBook.encodeUpdate(
                                realmAddress,
                                WatchBookResponse.UpdateWrapper(updated.toSkir()),
                            ),
                        )
                    },
                )
            }
        val updated =
            when (result) {
                is BookUpdateResult.Success -> {
                    result.book
                }

                is BookUpdateResult.Conflict -> {
                    return UpdateBookResponse.createConflictError(
                        expectedRevision = request.expectedRevision,
                        actual = result.actual.toSkir(),
                    )
                }

                BookUpdateResult.NotFound -> {
                    return UpdateBookResponse.createBookNotFoundError(bookId = request.bookId)
                }

                BookUpdateResult.TitleInvalid -> {
                    return UpdateBookResponse.ValidationErrorWrapper(BookValidationError.TITLE_REQUIRED)
                }

                BookUpdateResult.IconRequired -> {
                    return UpdateBookResponse.ValidationErrorWrapper(BookValidationError.ICON_REQUIRED)
                }

                is BookUpdateResult.TagsNotFound -> {
                    return UpdateBookResponse.createTagsNotFoundError(
                        tagIds = result.tagIds.map { it.toSkirRecordId() },
                    )
                }
            }
        return UpdateBookResponse.SuccessWrapper(updated.toSkir())
    }
}
