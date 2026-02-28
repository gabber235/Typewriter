package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.mockk
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
import protokt.v1.typewriter.models.v1.Page
import protokt.v1.typewriter.models.v1.PageType
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class PageRoutesTest : FunSpec({

    fun serialize(message: protokt.v1.AbstractMessage): ByteArray {
        return ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
    }

    context("search pages") {
        test("returns matching pages") {
            val mockRepo = mockk<PageRepository>()
            val pages = listOf(
                Page { id = "page:1"; bookId = "book:1"; name = "Test Page"; type = PageType.SEQUENCE },
                Page { id = "page:2"; bookId = "book:1"; name = "Test Another"; type = PageType.SCENE }
            )
            coEvery { mockRepo.searchPages("book:1", "Test") } returns pages

            val routes = PageRoutes(mockRepo)
            val request = SearchPagesRequest { bookId = "book:1"; search = "Test" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.search",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = SearchPagesResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pagesResult = response.result
            pagesResult.shouldBeInstanceOf<SearchPagesResponse.Result.Pages>()
            pagesResult.pages.pages.size shouldBe 2
        }

        test("returns empty for no matches") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.searchPages("book:1", "nonexistent") } returns emptyList()

            val routes = PageRoutes(mockRepo)
            val request = SearchPagesRequest { bookId = "book:1"; search = "nonexistent" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.search",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = SearchPagesResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pagesResult = response.result
            pagesResult.shouldBeInstanceOf<SearchPagesResponse.Result.Pages>()
            pagesResult.pages.pages.size shouldBe 0
        }
    }

    context("get page") {
        test("returns page when found") {
            val mockRepo = mockk<PageRepository>()
            val page = Page { id = "page:123"; bookId = "book:1"; name = "Found Page"; type = PageType.SEQUENCE }
            coEvery { mockRepo.getPage("page:123") } returns page

            val routes = PageRoutes(mockRepo)
            val request = GetPageRequest { id = "page:123" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetPageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageResult = response.result
            pageResult.shouldBeInstanceOf<GetPageResponse.Result.Page>()
            pageResult.page.name shouldBe "Found Page"
        }

        test("returns error when not found") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.getPage("page:missing") } returns null

            val routes = PageRoutes(mockRepo)
            val request = GetPageRequest { id = "page:missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetPageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageResult = response.result
            pageResult.shouldBeInstanceOf<GetPageResponse.Result.Error>()
            pageResult.error.message shouldBe "Page not found: page:missing"
        }
    }

    context("create page") {
        test("creates and returns page") {
            val mockRepo = mockk<PageRepository>()
            val createdPage = Page {
                id = "page:new"
                bookId = "book:1"
                name = "New Page"
                type = PageType.SCENE
                chapter = "intro"
                priority = 5
            }
            coEvery {
                mockRepo.createPage("book:1", "New Page", PageType.SCENE, "intro", 5)
            } returns createdPage

            val routes = PageRoutes(mockRepo)
            val request = CreatePageRequest {
                bookId = "book:1"
                name = "New Page"
                type = PageType.SCENE
                chapter = "intro"
                priority = 5
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreatePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageIdResult = response.result
            pageIdResult.shouldBeInstanceOf<CreatePageResponse.Result.PageId>()
            pageIdResult.pageId shouldBe "page:new"
        }
    }

    context("update page") {
        test("updates and returns page") {
            val mockRepo = mockk<PageRepository>()
            val updatedPage = Page {
                id = "page:existing"
                bookId = "book:1"
                name = "Updated"
                type = PageType.STATIC
            }
            coEvery { mockRepo.updatePage(any()) } returns updatedPage

            val routes = PageRoutes(mockRepo)
            val request = UpdatePageRequest {
                page = Page {
                    id = "page:existing"
                    bookId = "book:1"
                    name = "Updated"
                    type = PageType.STATIC
                }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdatePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageResult = response.result
            pageResult.shouldBeInstanceOf<UpdatePageResponse.Result.Page>()
            pageResult.page.name shouldBe "Updated"
        }

        test("returns error when page null") {
            val mockRepo = mockk<PageRepository>()
            val routes = PageRoutes(mockRepo)
            val request = UpdatePageRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdatePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageResult = response.result
            pageResult.shouldBeInstanceOf<UpdatePageResponse.Result.Error>()
            pageResult.error.message shouldBe "Page is required"
        }
    }

    context("delete page") {
        test("returns true on success") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.deletePage("page:to-delete") } returns true

            val routes = PageRoutes(mockRepo)
            val request = DeletePageRequest { pageId = "page:to-delete" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.delete",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = DeletePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val deleteResult = response.result
            deleteResult.shouldBeInstanceOf<DeletePageResponse.Result.Success>()
            deleteResult.success shouldBe true
        }

        test("returns false when not found") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.deletePage("page:missing") } returns false

            val routes = PageRoutes(mockRepo)
            val request = DeletePageRequest { pageId = "page:missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.delete",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = DeletePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val deleteResult = response.result
            deleteResult.shouldBeInstanceOf<DeletePageResponse.Result.Success>()
            deleteResult.success shouldBe false
        }
    }

    context("change page chapter") {
        test("updates chapter") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePageChapter("page:ch", "new.chapter") } returns true

            val routes = PageRoutes(mockRepo)
            val request = ChangePageChapterRequest { pageId = "page:ch"; chapter = "new.chapter" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.chapter",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePageChapterResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chapterResult = response.result
            chapterResult.shouldBeInstanceOf<ChangePageChapterResponse.Result.Success>()
            chapterResult.success shouldBe true
        }

        test("returns error when not found") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePageChapter("page:missing", "any") } returns false

            val routes = PageRoutes(mockRepo)
            val request = ChangePageChapterRequest { pageId = "page:missing"; chapter = "any" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.chapter",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePageChapterResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chapterResult = response.result
            chapterResult.shouldBeInstanceOf<ChangePageChapterResponse.Result.Success>()
            chapterResult.success shouldBe false
        }
    }

    context("change page priority") {
        test("updates priority") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePagePriority("page:prio", 99) } returns true

            val routes = PageRoutes(mockRepo)
            val request = ChangePagePriorityRequest { pageId = "page:prio"; priority = 99 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.priority",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePagePriorityResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val priorityResult = response.result
            priorityResult.shouldBeInstanceOf<ChangePagePriorityResponse.Result.Success>()
            priorityResult.success shouldBe true
        }
    }

    context("rename page") {
        test("updates name") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.renamePage("page:rn", "New Name") } returns true

            val routes = PageRoutes(mockRepo)
            val request = RenamePageRequest { pageId = "page:rn"; name = "New Name" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.page.rename",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = RenamePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val renameResult = response.result
            renameResult.shouldBeInstanceOf<RenamePageResponse.Result.Success>()
            renameResult.success shouldBe true
        }
    }

    context("batch change chapters") {
        test("updates with prefix matching and returns count") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePagesChapters("book:1", "old.prefix", "new.prefix") } returns 5

            val routes = PageRoutes(mockRepo)
            val request = ChangePagesChaptersRequest {
                bookId = "book:1"
                oldChapter = "old.prefix"
                newChapter = "new.prefix"
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.pages.chapters",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePagesChaptersResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chaptersResult = response.result
            chaptersResult.shouldBeInstanceOf<ChangePagesChaptersResponse.Result.Success>()
            chaptersResult.success shouldBe true
        }
    }
})
