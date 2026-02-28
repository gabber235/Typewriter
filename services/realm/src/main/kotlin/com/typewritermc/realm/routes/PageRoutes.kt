package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.telemetry.timed
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import com.typewritermc.services.libs.utils.extensions.nullIfBlank
import io.opentelemetry.api.trace.StatusCode
import protokt.v1.typewriter.api.v1.*
import protokt.v1.typewriter.models.v1.Error

class PageRoutes(
    private val pageRepository: PageRepository,
    private val credentials: DeferredProvider<Credential>,
    private val registrationStateProvider: StateProvider<RegistrationState>,
) {
    fun configure(): NatsRouting.() -> Unit = {
        val serviceId = credentials.require { "PageRoutes requires the credentials to be set to register" }.id
        val orgId = when (val state = registrationStateProvider.get()) {
            is RegistrationState.Bound -> state.organizationId
            else -> error("Service must be bound to an organization before routes can be configured")
        }
        route("realm.to.${serviceId}.organization.${orgId}") {
            handle("page.search") {
                val request = receive(SearchPagesRequest)
                span.setAttribute("operation", "page.search")

                val bookId = request.bookId.ifBlank {
                    return@handle reply(SearchPagesResponse {
                        result = SearchPagesResponse.Result.Error(Error { message = "bookId is required" })
                    })
                }
                span.setAttribute("book.id", bookId)
                val search = request.search?.nullIfBlank()
                span.setAttribute("search.query", search)

                val pages = if (search != null) span.timed("db.page.search") {
                    pageRepository.searchPages(bookId, search)
                } else span.timed("db.page.list") {
                    pageRepository.listPages(bookId)
                }
                span.setAttribute("result.count", pages.size.toLong())

                val response = SearchPagesResponse {
                    result = SearchPagesResponse.Result.Pages(SearchPagesResult { this.pages = pages })
                }
                reply(response)
            }

            handle("page.get") {
                val request = receive(GetPageRequest)
                span.setAttribute("operation", "page.get")

                val pageId = request.pageId.ifBlank {
                    return@handle reply(GetPageResponse {
                        result = GetPageResponse.Result.Error(Error { message = "page id is required" })
                    })
                }

                span.setAttribute("page.id", pageId)

                val page = span.timed("db.page.get") {
                    pageRepository.getPage(pageId)
                }

                val response = if (page != null) {
                    span.setAttribute("page.book_id", page.bookId)
                    GetPageResponse { result = GetPageResponse.Result.Page(page) }
                } else {
                    span.setStatus(StatusCode.ERROR, "Page not found: ${request.pageId}")
                    GetPageResponse {
                        result = GetPageResponse.Result.Error(Error { message = "Page not found: ${request.pageId}" })
                    }
                }
                reply(response)
            }

            handle("page.create") {
                val request = receive(CreatePageRequest)
                span.setAttribute("operation", "page.create")

                val bookId = request.bookId.ifBlank {
                    return@handle reply(CreatePageResponse {
                        result = CreatePageResponse.Result.Error(Error { message = "bookId is required" })
                    })
                }
                val name = request.name?.nullIfBlank()
                    ?: return@handle reply(CreatePageResponse {
                        result = CreatePageResponse.Result.Error(Error { message = "name is required" })
                    })
                val chapter = request.chapter ?: ""
                val priority = request.priority ?: 0

                span.setAttribute("book.id", bookId)
                span.setAttribute("page.name", name)
                span.setAttribute("page.type", request.type.name)

                val page = span.timed("db.page.create") {
                    pageRepository.createPage(
                        bookId = bookId,
                        name = name,
                        type = request.type,
                        chapter = chapter,
                        priority = priority
                    )
                }
                span.setAttribute("page.id", page.pageId)

                val response = CreatePageResponse { result = CreatePageResponse.Result.PageId(page.pageId) }
                reply(response)
            }

            handle("page.update") {
                val request = receive(UpdatePageRequest)
                span.setAttribute("operation", "page.update")

                val page = request.page
                if (page == null) {
                    span.setStatus(StatusCode.ERROR, "Page is required")
                    val response = UpdatePageResponse {
                        result = UpdatePageResponse.Result.Error(Error { message = "Page is required" })
                    }
                    reply(response)
                    return@handle
                }
                span.setAttribute("page.id", page.pageId)

                val updatedPage = span.timed("db.page.update") {
                    pageRepository.updatePage(page)
                }
                val response = UpdatePageResponse { result = UpdatePageResponse.Result.Page(updatedPage) }
                reply(response)
            }

            handle("page.delete") {
                val request = receive(DeletePageRequest)
                span.setAttribute("operation", "page.delete")

                val pageId = request.pageId.ifBlank {
                    return@handle reply(DeletePageResponse {
                        result = DeletePageResponse.Result.Error(Error { message = "pageId is required" })
                    })
                }

                span.setAttribute("page.id", pageId)

                val success = span.timed("db.page.delete") {
                    pageRepository.deletePage(pageId)
                }
                span.setAttribute("result.success", success)

                val response = DeletePageResponse { result = DeletePageResponse.Result.Success(success) }
                reply(response)
            }

            handle("page.chapter") {
                val request = receive(ChangePageChapterRequest)
                span.setAttribute("operation", "page.chapter")

                val pageId = request.pageId.ifBlank {
                    return@handle reply(ChangePageChapterResponse {
                        result = ChangePageChapterResponse.Result.Error(Error { message = "pageId is required" })
                    })
                }
                val chapter = request.chapter

                span.setAttribute("page.id", pageId)
                span.setAttribute("chapter", chapter)

                val success = span.timed("db.page.change_chapter") {
                    pageRepository.changePageChapter(pageId, chapter)
                }
                span.setAttribute("result.success", success)

                val response = ChangePageChapterResponse { result = ChangePageChapterResponse.Result.Success(success) }
                reply(response)
            }

            handle("page.priority") {
                val request = receive(ChangePagePriorityRequest)
                span.setAttribute("operation", "page.priority")

                val pageId = request.pageId.ifBlank {
                    return@handle reply(ChangePagePriorityResponse {
                        result = ChangePagePriorityResponse.Result.Error(Error { message = "pageId is required" })
                    })
                }
                val priority = request.priority

                span.setAttribute("page.id", pageId)
                span.setAttribute("priority", priority.toLong())

                val success = span.timed("db.page.change_priority") {
                    pageRepository.changePagePriority(pageId, priority)
                }
                span.setAttribute("result.success", success)

                val response =
                    ChangePagePriorityResponse { result = ChangePagePriorityResponse.Result.Success(success) }
                reply(response)
            }

            handle("page.rename") {
                val request = receive(RenamePageRequest)
                span.setAttribute("operation", "page.rename")

                val pageId = request.pageId.ifBlank {
                    return@handle reply(RenamePageResponse {
                        result = RenamePageResponse.Result.Error(Error { message = "pageId is required" })
                    })
                }
                val name = request.name

                span.setAttribute("page.id", pageId)
                span.setAttribute("page.name", name)

                val success = span.timed("db.page.rename") {
                    pageRepository.renamePage(pageId, name)
                }
                span.setAttribute("result.success", success)

                val response = RenamePageResponse { result = RenamePageResponse.Result.Success(success) }
                reply(response)
            }

            handle("pages.chapters") {
                val request = receive(ChangePagesChaptersRequest)
                span.setAttribute("operation", "pages.chapters")

                val bookId = request.bookId.ifBlank {
                    return@handle reply(ChangePagesChaptersResponse {
                        result = ChangePagesChaptersResponse.Result.Error(Error { message = "bookId is required" })
                    })
                }
                val oldChapter = request.oldChapter
                val newChapter = request.newChapter

                span.setAttribute("book.id", bookId)
                span.setAttribute("old_chapter", oldChapter)
                span.setAttribute("new_chapter", newChapter)

                val count = span.timed("db.pages.change_chapters") {
                    pageRepository.changePagesChapters(bookId, oldChapter, newChapter)
                }
                span.setAttribute("result.count", count.toLong())

                val response =
                    ChangePagesChaptersResponse { result = ChangePagesChaptersResponse.Result.Success(count > 0) }
                reply(response)
            }
        }
    }
}
