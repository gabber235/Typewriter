package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import protokt.v1.typewriter.api.v1.ChangePageChapterRequest
import protokt.v1.typewriter.api.v1.ChangePageChapterResponse
import protokt.v1.typewriter.api.v1.ChangePagePriorityRequest
import protokt.v1.typewriter.api.v1.ChangePagePriorityResponse
import protokt.v1.typewriter.api.v1.ChangePagesChaptersRequest
import protokt.v1.typewriter.api.v1.ChangePagesChaptersResponse
import protokt.v1.typewriter.api.v1.CreatePageRequest
import protokt.v1.typewriter.api.v1.CreatePageResponse
import protokt.v1.typewriter.api.v1.DeletePageRequest
import protokt.v1.typewriter.api.v1.DeletePageResponse
import protokt.v1.typewriter.api.v1.GetPageRequest
import protokt.v1.typewriter.api.v1.GetPageResponse
import protokt.v1.typewriter.api.v1.RenamePageRequest
import protokt.v1.typewriter.api.v1.RenamePageResponse
import protokt.v1.typewriter.api.v1.SearchPagesRequest
import protokt.v1.typewriter.api.v1.SearchPagesResponse
import protokt.v1.typewriter.api.v1.SearchPagesResult
import protokt.v1.typewriter.api.v1.UpdatePageRequest
import protokt.v1.typewriter.api.v1.UpdatePageResponse
import protokt.v1.typewriter.models.v1.Error

class PageRoutes(
    private val pageRepository: PageRepository
) {
    fun configure(): NatsRouting.() -> Unit = {
        route("realm.in.{serviceId}") {
            handle("page.search") {
                val request = receive<SearchPagesRequest>(SearchPagesRequest)
                val pages = pageRepository.searchPages(request.bookId, request.search)
                val response = SearchPagesResponse {
                    result = SearchPagesResponse.Result.Pages(SearchPagesResult { this.pages = pages })
                }
                reply(response)
            }

            handle("page.get") {
                val request = receive<GetPageRequest>(GetPageRequest)
                val page = pageRepository.getPage(request.id)
                val response = if (page != null) {
                    GetPageResponse { result = GetPageResponse.Result.Page(page) }
                } else {
                    GetPageResponse {
                        result = GetPageResponse.Result.Error(Error { message = "Page not found: ${request.id}" })
                    }
                }
                reply(response)
            }

            handle("page.create") {
                val request = receive<CreatePageRequest>(CreatePageRequest)
                val page = pageRepository.createPage(
                    bookId = request.bookId,
                    name = request.name,
                    type = request.type,
                    chapter = request.chapter,
                    priority = request.priority
                )
                val response = CreatePageResponse { result = CreatePageResponse.Result.PageId(page.id) }
                reply(response)
            }

            handle("page.update") {
                val request = receive<UpdatePageRequest>(UpdatePageRequest)
                val page = request.page
                if (page == null) {
                    val response = UpdatePageResponse {
                        result = UpdatePageResponse.Result.Error(Error { message = "Page is required" })
                    }
                    reply(response)
                    return@handle
                }
                val updatedPage = pageRepository.updatePage(page)
                val response = UpdatePageResponse { result = UpdatePageResponse.Result.Page(updatedPage) }
                reply(response)
            }

            handle("page.delete") {
                val request = receive<DeletePageRequest>(DeletePageRequest)
                val success = pageRepository.deletePage(request.pageId)
                val response = DeletePageResponse { result = DeletePageResponse.Result.Success(success) }
                reply(response)
            }

            handle("page.chapter") {
                val request = receive<ChangePageChapterRequest>(ChangePageChapterRequest)
                val success = pageRepository.changePageChapter(request.pageId, request.chapter)
                val response = ChangePageChapterResponse { result = ChangePageChapterResponse.Result.Success(success) }
                reply(response)
            }

            handle("page.priority") {
                val request = receive<ChangePagePriorityRequest>(ChangePagePriorityRequest)
                val success = pageRepository.changePagePriority(request.pageId, request.priority)
                val response = ChangePagePriorityResponse { result = ChangePagePriorityResponse.Result.Success(success) }
                reply(response)
            }

            handle("page.rename") {
                val request = receive<RenamePageRequest>(RenamePageRequest)
                val success = pageRepository.renamePage(request.pageId, request.name)
                val response = RenamePageResponse { result = RenamePageResponse.Result.Success(success) }
                reply(response)
            }

            handle("pages.chapters") {
                val request = receive<ChangePagesChaptersRequest>(ChangePagesChaptersRequest)
                val count = pageRepository.changePagesChapters(request.bookId, request.oldChapter, request.newChapter)
                val response = ChangePagesChaptersResponse { result = ChangePagesChaptersResponse.Result.Success(count > 0) }
                reply(response)
            }
        }
    }
}
