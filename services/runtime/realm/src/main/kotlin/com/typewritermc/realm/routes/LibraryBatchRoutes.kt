package com.typewritermc.realm.routes

import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.ref
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.BookCreation
import com.typewritermc.realm.repository.BookDeletion
import com.typewritermc.realm.repository.BookUpdate
import com.typewritermc.realm.repository.CreateBooksCommand
import com.typewritermc.realm.repository.CreatePagesCommand
import com.typewritermc.realm.repository.CreateTagsCommand
import com.typewritermc.realm.repository.DeleteBooksCommand
import com.typewritermc.realm.repository.DeletePagesCommand
import com.typewritermc.realm.repository.DeleteTagsCommand
import com.typewritermc.realm.repository.LibraryBatchRepository
import com.typewritermc.realm.repository.LibraryBatchResult
import com.typewritermc.realm.repository.MovePagesCommand
import com.typewritermc.realm.repository.PageCreation
import com.typewritermc.realm.repository.PageDeletion
import com.typewritermc.realm.repository.PageMove
import com.typewritermc.realm.repository.PageUpdate
import com.typewritermc.realm.repository.TagCreation
import com.typewritermc.realm.repository.TagDeletionItem
import com.typewritermc.realm.repository.TagUpdate
import com.typewritermc.realm.repository.UpdateBooksCommand
import com.typewritermc.realm.repository.UpdatePagesCommand
import com.typewritermc.realm.repository.UpdateTagsCommand
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.Icon
import skirout.library.v2.authoring.BookConflict
import skirout.library.v2.authoring.CreateBooksResponse
import skirout.library.v2.authoring.CreatePagesResponse
import skirout.library.v2.authoring.CreateTagsResponse
import skirout.library.v2.authoring.DeleteBooksResponse
import skirout.library.v2.authoring.DeletePagesResponse
import skirout.library.v2.authoring.DeleteTagsResponse
import skirout.library.v2.authoring.MovePagesResponse
import skirout.library.v2.authoring.PageConflict
import skirout.library.v2.authoring.TagConflict
import skirout.library.v2.authoring.UpdateBooksResponse
import skirout.library.v2.authoring.UpdatePagesResponse
import skirout.library.v2.authoring.UpdateTagsResponse

internal class LibraryBatchRoutes(
    private val repository: LibraryBatchRepository,
    private val pageCatalog: PageCatalog,
    private val contracts: LibraryContracts,
    private val onCommitted: (Boolean) -> Unit = {},
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.createBooksV2) { call ->
                invalidRequest {
                    repository.createBooks(
                        request {
                            CreateBooksCommand(
                                BatchId(call.request.batchId),
                                call.request.books.map { book ->
                                    BookCreation(
                                        book.id.toBookId(),
                                        LibraryName(book.title),
                                        Icon.parse(book.icon),
                                        book.color.toLibrary(),
                                        book.tags.map { it.toTagId().ref() },
                                    )
                                },
                            )
                        },
                    )
                }.also(::notify).toCreateBooksResponse()
            }
            unary(contracts.updateBooksV2) { call ->
                invalidRequest {
                    repository.updateBooks(
                        request {
                            UpdateBooksCommand(
                                BatchId(call.request.batchId),
                                call.request.books.map { book ->
                                    BookUpdate(
                                        book.id.toBookId(),
                                        book.expectedRevision,
                                        LibraryName(book.title),
                                        Icon.parse(book.icon),
                                        book.color.toLibrary(),
                                        book.tags.map { it.toTagId().ref() },
                                    )
                                },
                            )
                        },
                    )
                }.also(::notify).toUpdateBooksResponse()
            }
            unary(contracts.deleteBooksV2) { call ->
                invalidRequest {
                    repository.deleteBooks(
                        request {
                            DeleteBooksCommand(
                                BatchId(call.request.batchId),
                                call.request.books.map { BookDeletion(it.id.toBookId(), it.expectedRevision) },
                            )
                        },
                    )
                }.also(::notify).toDeleteBooksResponse()
            }
            unary(contracts.createPagesV2) { call ->
                invalidRequest {
                    repository.createPages(
                        request {
                            CreatePagesCommand(
                                BatchId(call.request.batchId),
                                call.request.pages.map { page ->
                                    PageCreation(
                                        page.id.toPageId(),
                                        page.book.toBookId().ref(),
                                        LibraryName(page.name),
                                        page.kind.toLibrary(),
                                        ChapterPath.parse(page.chapter),
                                        page.priority,
                                    ).also { requireNotNull(pageCatalog.definition(it.kind)) { "Unknown page kind: ${page.kind.id}" } }
                                },
                            )
                        },
                    )
                }.also(::notify).toCreatePagesResponse()
            }
            unary(contracts.updatePagesV2) { call ->
                invalidRequest {
                    repository.updatePages(
                        request {
                            UpdatePagesCommand(
                                BatchId(call.request.batchId),
                                call.request.pages.map { page ->
                                    PageUpdate(
                                        page.id.toPageId(),
                                        page.expectedRevision,
                                        LibraryName(page.name),
                                        ChapterPath.parse(page.chapter),
                                        page.priority,
                                    )
                                },
                            )
                        },
                    )
                }.also(::notify).toUpdatePagesResponse()
            }
            unary(contracts.movePagesV2) { call ->
                invalidRequest {
                    repository.movePages(
                        request {
                            MovePagesCommand(
                                BatchId(call.request.batchId),
                                call.request.pages.map { page ->
                                    PageMove(
                                        page.id.toPageId(),
                                        page.expectedRevision,
                                        page.book.toBookId().ref(),
                                        ChapterPath.parse(page.chapter),
                                        page.priority,
                                    )
                                },
                            )
                        },
                    )
                }.also(::notify).toMovePagesResponse()
            }
            unary(contracts.deletePagesV2) { call ->
                invalidRequest {
                    repository.deletePages(
                        request {
                            DeletePagesCommand(
                                BatchId(call.request.batchId),
                                call.request.pages.map { PageDeletion(it.id.toPageId(), it.expectedRevision) },
                            )
                        },
                    )
                }.also(::notify).toDeletePagesResponse()
            }
            unary(contracts.createTagsV2) { call ->
                invalidRequest {
                    repository.createTags(
                        request {
                            CreateTagsCommand(
                                BatchId(call.request.batchId),
                                call.request.tags.map { tag ->
                                    TagCreation(
                                        tag.id.toTagId(),
                                        LibraryName(tag.name),
                                        tag.color.toLibrary(),
                                        tag.parents.map { it.toTagId().ref() },
                                        GridPlacement(tag.placement.x, tag.placement.y, tag.placement.width, tag.placement.height),
                                    )
                                },
                            )
                        },
                    )
                }.also(::notify).toCreateTagsResponse()
            }
            unary(contracts.updateTagsV2) { call ->
                invalidRequest {
                    repository.updateTags(
                        request {
                            UpdateTagsCommand(
                                BatchId(call.request.batchId),
                                call.request.tags.map { tag ->
                                    TagUpdate(
                                        tag.id.toTagId(),
                                        tag.expectedRevision,
                                        LibraryName(tag.name),
                                        tag.color.toLibrary(),
                                        tag.parents.map { it.toTagId().ref() },
                                        GridPlacement(tag.placement.x, tag.placement.y, tag.placement.width, tag.placement.height),
                                    )
                                },
                            )
                        },
                    )
                }.also(::notify).toUpdateTagsResponse()
            }
            unary(contracts.deleteTagsV2) { call ->
                invalidRequest {
                    repository.deleteTags(
                        request {
                            DeleteTagsCommand(
                                BatchId(call.request.batchId),
                                call.request.tags.map { TagDeletionItem(it.id.toTagId(), it.expectedRevision) },
                            )
                        },
                    )
                }.also(::notify).toDeleteTagsResponse()
            }
        }

    private fun notify(result: LibraryBatchResult<*>) {
        if (result is LibraryBatchResult.Success) onCommitted(true)
    }

    private suspend fun <T> invalidRequest(block: suspend () -> LibraryBatchResult<T>): LibraryBatchResult<T> =
        try {
            block()
        } catch (error: InvalidLibraryRequestException) {
            LibraryBatchResult.Invalid(listOf(error.cause?.message ?: "Invalid request."))
        }

    private fun <T> request(block: () -> T): T =
        try {
            block()
        } catch (error: IllegalArgumentException) {
            throw InvalidLibraryRequestException(error)
        }
}

private class InvalidLibraryRequestException(
    cause: IllegalArgumentException,
) : RuntimeException(cause)

private fun LibraryBatchResult<*>.errors(): List<String> =
    when (this) {
        is LibraryBatchResult.Conflict -> emptyList()
        is LibraryBatchResult.Invalid -> diagnostics
        is LibraryBatchResult.Success -> emptyList()
    }

private fun LibraryBatchResult<com.typewritermc.library.Book>.toCreateBooksResponse(): CreateBooksResponse =
    when (this) {
        is LibraryBatchResult.Success -> CreateBooksResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> CreateBooksResponse.ConflictWrapper(bookConflicts())
        is LibraryBatchResult.Invalid -> CreateBooksResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Book>.toUpdateBooksResponse(): UpdateBooksResponse =
    when (this) {
        is LibraryBatchResult.Success -> UpdateBooksResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> UpdateBooksResponse.ConflictWrapper(bookConflicts())
        is LibraryBatchResult.Invalid -> UpdateBooksResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Book>.toDeleteBooksResponse(): DeleteBooksResponse =
    when (this) {
        is LibraryBatchResult.Success -> {
            DeleteBooksResponse.createSuccess(
                batchId = batchId.value,
                affectedPages =
                    affectedPages.map {
                        it.toSkirRecordId()
                    },
            )
        }

        is LibraryBatchResult.Conflict -> {
            DeleteBooksResponse.ConflictWrapper(bookConflicts())
        }

        is LibraryBatchResult.Invalid -> {
            DeleteBooksResponse.InvalidWrapper(errors())
        }
    }

private fun LibraryBatchResult<com.typewritermc.library.Page>.toCreatePagesResponse(): CreatePagesResponse =
    when (this) {
        is LibraryBatchResult.Success -> CreatePagesResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> CreatePagesResponse.ConflictWrapper(pageConflicts())
        is LibraryBatchResult.Invalid -> CreatePagesResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Page>.toUpdatePagesResponse(): UpdatePagesResponse =
    when (this) {
        is LibraryBatchResult.Success -> UpdatePagesResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> UpdatePagesResponse.ConflictWrapper(pageConflicts())
        is LibraryBatchResult.Invalid -> UpdatePagesResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Page>.toMovePagesResponse(): MovePagesResponse =
    when (this) {
        is LibraryBatchResult.Success -> MovePagesResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> MovePagesResponse.ConflictWrapper(pageConflicts())
        is LibraryBatchResult.Invalid -> MovePagesResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Page>.toDeletePagesResponse(): DeletePagesResponse =
    when (this) {
        is LibraryBatchResult.Success -> {
            DeletePagesResponse.createSuccess(
                batchId = batchId.value,
                affectedPages =
                    affectedPages.map {
                        it.toSkirRecordId()
                    },
            )
        }

        is LibraryBatchResult.Conflict -> {
            DeletePagesResponse.ConflictWrapper(pageConflicts())
        }

        is LibraryBatchResult.Invalid -> {
            DeletePagesResponse.InvalidWrapper(errors())
        }
    }

private fun LibraryBatchResult<com.typewritermc.library.Tag>.toCreateTagsResponse(): CreateTagsResponse =
    when (this) {
        is LibraryBatchResult.Success -> CreateTagsResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> CreateTagsResponse.ConflictWrapper(tagConflicts())
        is LibraryBatchResult.Invalid -> CreateTagsResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Tag>.toUpdateTagsResponse(): UpdateTagsResponse =
    when (this) {
        is LibraryBatchResult.Success -> UpdateTagsResponse.SuccessWrapper(values.map { it.toV2Wire() })
        is LibraryBatchResult.Conflict -> UpdateTagsResponse.ConflictWrapper(tagConflicts())
        is LibraryBatchResult.Invalid -> UpdateTagsResponse.InvalidWrapper(errors())
    }

private fun LibraryBatchResult<com.typewritermc.library.Tag>.toDeleteTagsResponse(): DeleteTagsResponse =
    when (this) {
        is LibraryBatchResult.Success -> {
            DeleteTagsResponse.createSuccess(
                batchId = batchId.value,
                affectedPages =
                    affectedPages.map {
                        it.toSkirRecordId()
                    },
            )
        }

        is LibraryBatchResult.Conflict -> {
            DeleteTagsResponse.ConflictWrapper(tagConflicts())
        }

        is LibraryBatchResult.Invalid -> {
            DeleteTagsResponse.InvalidWrapper(errors())
        }
    }

private fun LibraryBatchResult.Conflict<com.typewritermc.library.Book>.bookConflicts() =
    conflicts.map { BookConflict(id = it.id.toSkirRecordId(), expectedRevision = it.expectedRevision, actual = it.actual?.toV2Wire()) }

private fun LibraryBatchResult.Conflict<com.typewritermc.library.Page>.pageConflicts() =
    conflicts.map { PageConflict(id = it.id.toSkirRecordId(), expectedRevision = it.expectedRevision, actual = it.actual?.toV2Wire()) }

private fun LibraryBatchResult.Conflict<com.typewritermc.library.Tag>.tagConflicts() =
    conflicts.map { TagConflict(id = it.id.toSkirRecordId(), expectedRevision = it.expectedRevision, actual = it.actual?.toV2Wire()) }
