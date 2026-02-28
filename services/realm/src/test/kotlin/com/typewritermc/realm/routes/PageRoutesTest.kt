package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.StateProvider
import com.typewritermc.services.libs.utils.asDeferredProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.mockk
import protokt.v1.typewriter.api.v1.*
import protokt.v1.typewriter.models.v1.Page
import protokt.v1.typewriter.models.v1.PageType
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class PageRoutesTest : FunSpec({

    val credentials = Credential(id = "test-service", name = "Test Service", token = "test-token").asDeferredProvider()
    val registrationStateProvider = StateProvider<RegistrationState>(
        RegistrationState.Bound(organizationId = "test-org", organizationName = "Test Organization")
    )

    fun serialize(message: protokt.v1.AbstractMessage): ByteArray {
        return ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
    }

    context("search pages") {
        test("returns matching pages") {
            val mockRepo = mockk<PageRepository>()
            val pages = listOf(
                Page { pageId = "1"; bookId = "book:1"; name = "Test Page"; type = PageType.SEQUENCE },
                Page { pageId = "2"; bookId = "book:1"; name = "Test Another"; type = PageType.SCENE }
            )
            coEvery { mockRepo.searchPages("book:1", "Test") } returns pages

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = SearchPagesRequest { bookId = "book:1"; search = "Test" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.search",
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

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = SearchPagesRequest { bookId = "book:1"; search = "nonexistent" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.search",
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
            val page = Page { pageId = "123"; bookId = "book:1"; name = "Found Page"; type = PageType.SEQUENCE }
            coEvery { mockRepo.getPage("123") } returns page

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = GetPageRequest { pageId = "123" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.get",
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
            coEvery { mockRepo.getPage("missing") } returns null

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = GetPageRequest { pageId = "missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetPageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageResult = response.result
            pageResult.shouldBeInstanceOf<GetPageResponse.Result.Error>()
            pageResult.error.message shouldBe "Page not found: missing"
        }
    }

    context("create page") {
        test("creates and returns page") {
            val mockRepo = mockk<PageRepository>()
            val createdPage = Page {
                pageId = "new"
                bookId = "book:1"
                name = "New Page"
                type = PageType.SCENE
                chapter = "intro"
                priority = 5
            }
            coEvery {
                mockRepo.createPage("book:1", "New Page", PageType.SCENE, "intro", 5)
            } returns createdPage

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreatePageRequest {
                bookId = "book:1"
                name = "New Page"
                type = PageType.SCENE
                chapter = "intro"
                priority = 5
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreatePageResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val pageIdResult = response.result
            pageIdResult.shouldBeInstanceOf<CreatePageResponse.Result.PageId>()
            pageIdResult.pageId shouldBe "new"
        }
    }

    context("update page") {
        test("updates and returns page") {
            val mockRepo = mockk<PageRepository>()
            val updatedPage = Page {
                pageId = "existing"
                bookId = "book:1"
                name = "Updated"
                type = PageType.STATIC
            }
            coEvery { mockRepo.updatePage(any()) } returns updatedPage

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = UpdatePageRequest {
                page = Page {
                    pageId = "existing"
                    bookId = "book:1"
                    name = "Updated"
                    type = PageType.STATIC
                }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.update",
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
            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = UpdatePageRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.update",
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
            coEvery { mockRepo.deletePage("to-delete") } returns true

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = DeletePageRequest { pageId = "to-delete" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.delete",
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
            coEvery { mockRepo.deletePage("missing") } returns false

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = DeletePageRequest { pageId = "missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.delete",
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
            coEvery { mockRepo.changePageChapter("ch", "new.chapter") } returns true

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePageChapterRequest { pageId = "ch"; chapter = "new.chapter" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.chapter",
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
            coEvery { mockRepo.changePageChapter("missing", "any") } returns false

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePageChapterRequest { pageId = "missing"; chapter = "any" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.chapter",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePageChapterResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chapterResult = response.result
            chapterResult.shouldBeInstanceOf<ChangePageChapterResponse.Result.Success>()
            chapterResult.success shouldBe false
        }

        test("changes chapter to empty string") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePageChapter("page_in_book", "") } returns true

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePageChapterRequest { pageId = "page_in_book"; chapter = "" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.chapter",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePageChapterResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chapterResult = response.result
            chapterResult.shouldBeInstanceOf<ChangePageChapterResponse.Result.Success>()
            chapterResult.success shouldBe true
        }
    }

    context("change page priority") {
        test("updates priority") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePagePriority("prio", 99) } returns true

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePagePriorityRequest { pageId = "prio"; priority = 99 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.priority",
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
            coEvery { mockRepo.renamePage("rn", "New Name") } returns true

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = RenamePageRequest { pageId = "rn"; name = "New Name" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.page.rename",
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
            coEvery { mockRepo.changePagesChapters("1", "old.prefix", "new.prefix") } returns 5

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePagesChaptersRequest {
                bookId = "1"
                oldChapter = "old.prefix"
                newChapter = "new.prefix"
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.pages.chapters",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePagesChaptersResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chaptersResult = response.result
            chaptersResult.shouldBeInstanceOf<ChangePagesChaptersResponse.Result.Success>()
            chaptersResult.success shouldBe true
        }

        test("changes pages chapters with empty old chapter") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePagesChapters("book_with_pages", "", "new_chapter") } returns 3

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePagesChaptersRequest {
                bookId = "book_with_pages"
                oldChapter = ""
                newChapter = "new_chapter"
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.pages.chapters",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePagesChaptersResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chaptersResult = response.result
            chaptersResult.shouldBeInstanceOf<ChangePagesChaptersResponse.Result.Success>()
            chaptersResult.success shouldBe true
        }

        test("changes pages chapters with empty new chapter") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePagesChapters("book_with_pages", "old_chapter", "") } returns 2

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePagesChaptersRequest {
                bookId = "book_with_pages"
                oldChapter = "old_chapter"
                newChapter = ""
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.pages.chapters",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePagesChaptersResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chaptersResult = response.result
            chaptersResult.shouldBeInstanceOf<ChangePagesChaptersResponse.Result.Success>()
            chaptersResult.success shouldBe true
        }

        test("changes pages chapters from empty to empty") {
            val mockRepo = mockk<PageRepository>()
            coEvery { mockRepo.changePagesChapters("book_with_pages", "", "") } returns 0

            val routes = PageRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ChangePagesChaptersRequest {
                bookId = "book_with_pages"
                oldChapter = ""
                newChapter = ""
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.pages.chapters",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ChangePagesChaptersResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val chaptersResult = response.result
            chaptersResult.shouldBeInstanceOf<ChangePagesChaptersResponse.Result.Success>()
            chaptersResult.success shouldBe false
        }
    }
})
