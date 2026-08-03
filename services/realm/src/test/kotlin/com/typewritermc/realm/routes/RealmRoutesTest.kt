package com.typewritermc.realm.routes

import build.skir.Serializer
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.RepositoryResult
import com.typewritermc.realm.repository.TagDeletion
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlin.time.Duration.Companion.seconds
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.library.v1.book.*
import skirout.library.v1.page.*
import skirout.library.v1.tag.*

val RealmRoutesTest by testSuite {
    test("collection watch returns its initial Skir response") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.transport.activeSubscriptionCount shouldBe 17
                fixture.repositories.books += book("one")

                val response = fixture.request(
                    "book.watch",
                    WatchBooksRequest(),
                    WatchBooksRequest.serializer,
                    WatchBooksResponse.serializer,
                )

                response shouldBe WatchBooksResponse.ListWrapper(fixture.repositories.books)
            }
        }
    }

    test("book creation validates input and publishes collection updates") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid = fixture.request(
                    "book.create",
                    CreateBookRequest(title = " ", icon = null, color = null, tagIds = emptyList()),
                    CreateBookRequest.serializer,
                    CreateBookResponse.serializer,
                )
                invalid.kind shouldBe CreateBookResponse.Kind.VALIDATION_ERROR_WRAPPER

                val response = fixture.request(
                    "book.create",
                    CreateBookRequest(title = "display_title", icon = null, color = null, tagIds = emptyList()),
                    CreateBookRequest.serializer,
                    CreateBookResponse.serializer,
                )
                response.kind shouldBe CreateBookResponse.Kind.SUCCESS_WRAPPER
                fixture.publishedTo(
                    "service.from.realm.organization.organization.realm.book.watch",
                ) shouldHaveSize 1
            }
        }
    }

    test("invalid record tables and missing references are typed domain errors") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid = fixture.request(
                    "page.create",
                    CreatePageRequest(
                        bookId = rid("tag", "wrong"),
                        name = "page_name",
                        type = PageType.STATIC,
                        chapter = null,
                        priority = null,
                    ),
                    CreatePageRequest.serializer,
                    CreatePageResponse.serializer,
                )
                invalid.kind shouldBe CreatePageResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER

                val missing = fixture.request(
                    "page.create",
                    CreatePageRequest(
                        bookId = rid("book", "missing"),
                        name = "page_name",
                        type = PageType.STATIC,
                        chapter = null,
                        priority = null,
                    ),
                    CreatePageRequest.serializer,
                    CreatePageResponse.serializer,
                )
                missing.kind shouldBe CreatePageResponse.Kind.BOOK_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("publication failure remains observable after a committed mutation") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.transport.failNextPublish(TransportError.Unavailable())
                val response = fixture.request(
                    "book.create",
                    CreateBookRequest(title = "committed_book", icon = null, color = null, tagIds = emptyList()),
                    CreateBookRequest.serializer,
                    CreateBookResponse.serializer,
                )

                response.kind shouldBe CreateBookResponse.Kind.INTERNAL_ERROR_WRAPPER
                fixture.repositories.books.single().title shouldBe "committed_book"
            }
        }
    }

    test("unexpected repository failures become typed internal responses") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.repositories.failBookListing = true

                val response = fixture.request(
                    "book.watch",
                    WatchBooksRequest(),
                    WatchBooksRequest.serializer,
                    WatchBooksResponse.serializer,
                )

                response.kind shouldBe WatchBooksResponse.Kind.INTERNAL_ERROR_WRAPPER
            }
        }
    }

    test("book resource watch and update use typed responses and both update channels") {
        runTest {
            RouteFixture().use { fixture ->
                val original = book("book_one")
                fixture.repositories.books += original
                val watched = fixture.request(
                    "book.resource.watch",
                    WatchBookRequest(bookId = original.bookId),
                    WatchBookRequest.serializer,
                    WatchBookResponse.serializer,
                )
                watched.kind shouldBe WatchBookResponse.Kind.INITIAL_WRAPPER

                val updated = fixture.request(
                    "book.update",
                    UpdateBookRequest(
                        bookId = original.bookId,
                        title = "updated_book",
                        icon = null,
                        color = null,
                        tagIds = null,
                    ),
                    UpdateBookRequest.serializer,
                    UpdateBookResponse.serializer,
                )
                updated.kind shouldBe UpdateBookResponse.Kind.SUCCESS_WRAPPER
                fixture.publishedTo(
                    "service.from.realm.organization.organization.realm.book.watch",
                ) shouldHaveSize 1
                fixture.publishedTo(
                    "service.from.realm.organization.organization.realm.book.resource.watch",
                ) shouldHaveSize 1
            }
        }
    }

    test("page query, watch, mutation, deletion, and chapter routes are operational") {
        runTest {
            RouteFixture().use { fixture ->
                val book = book("book_one")
                fixture.repositories.books += book
                val created = fixture.request(
                    "page.create",
                    CreatePageRequest(
                        bookId = book.bookId,
                        name = "page_one",
                        type = PageType.STATIC,
                        chapter = "act.one",
                        priority = 1,
                    ),
                    CreatePageRequest.serializer,
                    CreatePageResponse.serializer,
                )
                created.kind shouldBe CreatePageResponse.Kind.SUCCESS_WRAPPER
                val page = fixture.repositories.pages.single()

                fixture.request(
                    "page.search",
                    SearchPagesRequest(bookId = book.bookId, search = "page"),
                    SearchPagesRequest.serializer,
                    SearchPagesResponse.serializer,
                ).kind shouldBe SearchPagesResponse.Kind.SUCCESS_WRAPPER
                fixture.request(
                    "page.watch",
                    WatchPageRequest(pageId = page.pageId),
                    WatchPageRequest.serializer,
                    WatchPageResponse.serializer,
                ).kind shouldBe WatchPageResponse.Kind.INITIAL_WRAPPER
                fixture.request(
                    "page.update",
                    UpdatePageRequest(
                        pageId = page.pageId,
                        name = "page_two",
                        type = PageType.SCENE,
                        chapter = null,
                        priority = 2,
                    ),
                    UpdatePageRequest.serializer,
                    UpdatePageResponse.serializer,
                ).kind shouldBe UpdatePageResponse.Kind.SUCCESS_WRAPPER
                fixture.request(
                    "pages.chapters",
                    ChangePagesChaptersRequest(
                        bookId = book.bookId,
                        oldChapter = "act.one",
                        newChapter = "act.two",
                    ),
                    ChangePagesChaptersRequest.serializer,
                    ChangePagesChaptersResponse.serializer,
                ).kind shouldBe ChangePagesChaptersResponse.Kind.SUCCESS_WRAPPER
                fixture.request(
                    "page.delete",
                    DeletePageRequest(pageId = page.pageId),
                    DeletePageRequest.serializer,
                    DeletePageResponse.serializer,
                ).kind shouldBe DeletePageResponse.Kind.SUCCESS_WRAPPER
            }
        }
    }

    test("tag routes publish removals and every related resource update") {
        runTest {
            RouteFixture().use { fixture ->
                val created = fixture.request(
                    "tag.create",
                    CreateTagRequest(
                        name = "parent_tag",
                        color = Color(argb = 1),
                        parentIds = emptyList(),
                        placement = Placement(x = 0, y = 0, width = 4, height = 1),
                    ),
                    CreateTagRequest.serializer,
                    CreateTagResponse.serializer,
                )
                created.kind shouldBe CreateTagResponse.Kind.SUCCESS_WRAPPER
                val parent = fixture.repositories.tags.single()
                val child = Tag(
                    tagId = rid("tag", "child"),
                    name = "child_tag",
                    color = Color(argb = 2),
                    parentIds = listOf(parent.tagId),
                    placement = Placement(x = 1, y = 1, width = 4, height = 1),
                )
                fixture.repositories.tags += child
                fixture.repositories.books += book("book_one", tagIds = listOf(parent.tagId))

                fixture.request(
                    "tag.watch",
                    WatchTagsRequest(),
                    WatchTagsRequest.serializer,
                    WatchTagsResponse.serializer,
                ).kind shouldBe WatchTagsResponse.Kind.LIST_WRAPPER
                fixture.request(
                    "tag.resource.watch",
                    WatchTagRequest(tagId = parent.tagId),
                    WatchTagRequest.serializer,
                    WatchTagResponse.serializer,
                ).kind shouldBe WatchTagResponse.Kind.INITIAL_WRAPPER
                fixture.request(
                    "tag.update",
                    UpdateTagRequest(
                        tagId = parent.tagId,
                        name = "updated_tag",
                        color = null,
                        parentIds = null,
                        placement = null,
                    ),
                    UpdateTagRequest.serializer,
                    UpdateTagResponse.serializer,
                ).kind shouldBe UpdateTagResponse.Kind.SUCCESS_WRAPPER
                fixture.request(
                    "tag.move",
                    MoveTagRequest(tagId = parent.tagId, x = 4, y = 5),
                    MoveTagRequest.serializer,
                    MoveTagResponse.serializer,
                ).kind shouldBe MoveTagResponse.Kind.SUCCESS_WRAPPER
                fixture.request(
                    "tag.resize",
                    ResizeTagRequest(tagId = parent.tagId, width = 6, height = 2),
                    ResizeTagRequest.serializer,
                    ResizeTagResponse.serializer,
                ).kind shouldBe ResizeTagResponse.Kind.SUCCESS_WRAPPER

                fixture.request(
                    "tag.delete",
                    DeleteTagRequest(tagId = parent.tagId),
                    DeleteTagRequest.serializer,
                    DeleteTagResponse.serializer,
                ).kind shouldBe DeleteTagResponse.Kind.SUCCESS_WRAPPER
                fixture.publishedTo(
                    "service.from.realm.organization.organization.realm.book.watch",
                ) shouldHaveSize 1
                fixture.publishedTo(
                    "service.from.realm.organization.organization.realm.book.resource.watch",
                ) shouldHaveSize 1
                fixture.repositories.tags.single().parentIds shouldBe emptyList()
                fixture.repositories.books.single().tagIds shouldBe emptyList()
            }
        }
    }

    test("book and page mutations classify invalid identifiers and missing resources") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.request(
                    "book.update",
                    UpdateBookRequest(
                        bookId = rid("tag", "wrong"),
                        title = null,
                        icon = null,
                        color = null,
                        tagIds = null,
                    ),
                    UpdateBookRequest.serializer,
                    UpdateBookResponse.serializer,
                ).kind shouldBe UpdateBookResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.request(
                    "book.update",
                    UpdateBookRequest(
                        bookId = rid("book", "missing"),
                        title = null,
                        icon = null,
                        color = null,
                        tagIds = null,
                    ),
                    UpdateBookRequest.serializer,
                    UpdateBookResponse.serializer,
                ).kind shouldBe UpdateBookResponse.Kind.BOOK_NOT_FOUND_ERROR_WRAPPER

                fixture.request(
                    "page.update",
                    UpdatePageRequest(
                        pageId = rid("tag", "wrong"),
                        name = null,
                        type = null,
                        chapter = null,
                        priority = null,
                    ),
                    UpdatePageRequest.serializer,
                    UpdatePageResponse.serializer,
                ).kind shouldBe UpdatePageResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.request(
                    "page.update",
                    UpdatePageRequest(
                        pageId = rid("page", "missing"),
                        name = null,
                        type = null,
                        chapter = null,
                        priority = null,
                    ),
                    UpdatePageRequest.serializer,
                    UpdatePageResponse.serializer,
                ).kind shouldBe UpdatePageResponse.Kind.PAGE_NOT_FOUND_ERROR_WRAPPER
                fixture.request(
                    "page.delete",
                    DeletePageRequest(pageId = rid("page", "missing")),
                    DeletePageRequest.serializer,
                    DeletePageResponse.serializer,
                ).kind shouldBe DeletePageResponse.Kind.PAGE_NOT_FOUND_ERROR_WRAPPER
                fixture.request(
                    "pages.chapters",
                    ChangePagesChaptersRequest(bookId = rid("book", "missing"), oldChapter = "old", newChapter = "new"),
                    ChangePagesChaptersRequest.serializer,
                    ChangePagesChaptersResponse.serializer,
                ).kind shouldBe ChangePagesChaptersResponse.Kind.BOOK_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("tag mutations classify validation, missing parents, and missing resources") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.request(
                    "tag.create",
                    CreateTagRequest(
                        name = "tag_name",
                        color = null,
                        parentIds = listOf(rid("tag", "missing")),
                        placement = Placement(x = 0, y = 0, width = 4, height = 1),
                    ),
                    CreateTagRequest.serializer,
                    CreateTagResponse.serializer,
                ).kind shouldBe CreateTagResponse.Kind.PARENTS_NOT_FOUND_ERROR_WRAPPER
                fixture.request(
                    "tag.update",
                    UpdateTagRequest(
                        tagId = rid("tag", "missing"),
                        name = null,
                        color = null,
                        parentIds = null,
                        placement = null,
                    ),
                    UpdateTagRequest.serializer,
                    UpdateTagResponse.serializer,
                ).kind shouldBe UpdateTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
                fixture.request(
                    "tag.delete",
                    DeleteTagRequest(tagId = rid("tag", "missing")),
                    DeleteTagRequest.serializer,
                    DeleteTagResponse.serializer,
                ).kind shouldBe DeleteTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
                fixture.request(
                    "tag.move",
                    MoveTagRequest(tagId = rid("tag", "missing"), x = null, y = null),
                    MoveTagRequest.serializer,
                    MoveTagResponse.serializer,
                ).kind shouldBe MoveTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.request(
                    "tag.move",
                    MoveTagRequest(tagId = rid("tag", "missing"), x = 1, y = null),
                    MoveTagRequest.serializer,
                    MoveTagResponse.serializer,
                ).kind shouldBe MoveTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
                fixture.request(
                    "tag.resize",
                    ResizeTagRequest(tagId = rid("tag", "missing"), width = 0, height = null),
                    ResizeTagRequest.serializer,
                    ResizeTagResponse.serializer,
                ).kind shouldBe ResizeTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.request(
                    "tag.resize",
                    ResizeTagRequest(tagId = rid("tag", "missing"), width = 1, height = null),
                    ResizeTagRequest.serializer,
                    ResizeTagResponse.serializer,
                ).kind shouldBe ResizeTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }
}

private class RouteFixture : AutoCloseable {
    val repositories = FakeRepositories()
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    private val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val router: CommunicatorRouter = communicator.createRouter(
        RealmRouteFactory(repositories, repositories, repositories).create(RealmAddress("realm", "organization")),
        scope,
    )
    private var replySequence = 0

    init {
        runBlocking { router.start() shouldBe RouterResult.Success }
    }

    suspend fun <Request : Any, Response : Any> request(
        suffix: String,
        request: Request,
        requestSerializer: Serializer<Request>,
        responseSerializer: Serializer<Response>,
    ): Response {
        val reply = MessageAddress.of("test.reply.${replySequence++}")
        transport.deliver(
            TransportDelivery.Message(
                InboundMessage(
                    address = MessageAddress.of(
                        "service.to.realm.organization.organization.realm.$suffix",
                    ),
                    payload = requestSerializer.toBytes(request).toByteArray(),
                    replyTo = reply,
                ),
            ),
        )
        val publication = withTimeout(2.seconds) {
            while (true) {
                transport.actions.filterIsInstance<FakeMessageTransport.Action.Publish>()
                    .lastOrNull { it.message.address == reply }
                    ?.let { return@withTimeout it }
                yield()
            }
            error("Reply wait ended unexpectedly")
        }
        return responseSerializer.fromBytes(publication.message.payload)
    }

    fun publishedTo(address: String) = transport.actions.filterIsInstance<FakeMessageTransport.Action.Publish>()
        .filter { it.message.address == MessageAddress.of(address) }

    override fun close() {
        runBlocking { router.stop() }
        scope.cancel()
        transport.close()
        telemetry.close()
    }
}

private class FakeRepositories : BookRepository, PageRepository, TagRepository {
    val books = mutableListOf<Book>()
    val pages = mutableListOf<Page>()
    val tags = mutableListOf<Tag>()
    private var sequence = 0L
    var failBookListing = false

    override suspend fun listBooks() = if (failBookListing) error("Book listing failed") else books.toList()
    override suspend fun getBook(id: RecordId) = books.firstOrNull { it.bookId == id }
    override suspend fun createBook(title: String, icon: String, color: Color, tagIds: List<RecordId>) =
        RepositoryResult.Success(book((++sequence).toString(), title, icon, color, tagIds).also(books::add))

    override suspend fun updateBook(book: Book) = RepositoryResult.Success(book.also { value ->
        books.replaceAll { if (it.bookId == value.bookId) value else it }
    })

    override suspend fun searchPages(bookId: RecordId, search: String?) = pages.filter {
        it.bookId == bookId && (search == null || it.name.contains(search, ignoreCase = true))
    }

    override suspend fun getPage(id: RecordId) = pages.firstOrNull { it.pageId == id }
    override suspend fun createPage(
        bookId: RecordId,
        name: String,
        type: PageType,
        chapter: String,
        priority: Int,
    ) = RepositoryResult.Success(
        Page(
            pageId = rid("page", (++sequence).toString()),
            bookId = bookId,
            name = name,
            type = type,
            chapter = chapter,
            priority = priority,
        ).also(pages::add),
    )

    override suspend fun updatePage(page: Page) = RepositoryResult.Success(page.also { value ->
        pages.replaceAll { if (it.pageId == value.pageId) value else it }
    })

    override suspend fun deletePage(id: RecordId) = if (pages.removeIf { it.pageId == id }) {
        RepositoryResult.Success(Unit)
    } else {
        RepositoryResult.DomainFailure("page-not-found-error", listOf(id))
    }

    override suspend fun changePagesChapters(
        bookId: RecordId,
        oldChapter: String,
        newChapter: String,
    ): RepositoryResult<List<Page>> {
        val prefix = "$oldChapter."
        val updated = pages.filter { it.bookId == bookId && (it.chapter == oldChapter || it.chapter.startsWith(prefix)) }
            .map { page ->
                val suffix = page.chapter.removePrefix(oldChapter)
                page.copy(chapter = newChapter + suffix)
            }
        val replacements = updated.associateBy(Page::pageId)
        pages.replaceAll { replacements[it.pageId] ?: it }
        return RepositoryResult.Success(updated)
    }

    override suspend fun listTags() = tags.toList()
    override suspend fun getTag(id: RecordId) = tags.firstOrNull { it.tagId == id }
    override suspend fun findMissing(ids: List<RecordId>) = ids.filter { id -> tags.none { it.tagId == id } }
    override suspend fun createTag(name: String, color: Color, parentIds: List<RecordId>, placement: Placement) =
        RepositoryResult.Success(
            Tag(
                tagId = rid("tag", (++sequence).toString()),
                name = name,
                color = color,
                parentIds = parentIds,
                placement = placement,
            ).also(tags::add),
        )

    override suspend fun updateTag(tag: Tag) = RepositoryResult.Success(tag.also { value ->
        tags.replaceAll { if (it.tagId == value.tagId) value else it }
    })

    override suspend fun deleteTag(id: RecordId): RepositoryResult<TagDeletion> {
        if (tags.none { it.tagId == id }) return RepositoryResult.DomainFailure("tag-not-found-error", listOf(id))
        val affectedTags = tags.filter { id in it.parentIds }.map(Tag::tagId)
        val affectedBooks = books.filter { id in it.tagIds }.map(Book::bookId)
        tags.removeIf { it.tagId == id }
        tags.replaceAll { tag -> tag.copy(parentIds = tag.parentIds - id) }
        books.replaceAll { book -> book.copy(tagIds = book.tagIds - id) }
        return RepositoryResult.Success(TagDeletion(affectedTags, affectedBooks))
    }

    override suspend fun moveTag(id: RecordId, x: Int?, y: Int?) = tagMutation(id) { tag ->
        tag.copy(placement = tag.placement.copy(x = x ?: tag.placement.x, y = y ?: tag.placement.y))
    }

    override suspend fun resizeTag(id: RecordId, width: Int?, height: Int?) = tagMutation(id) { tag ->
        tag.copy(
            placement = tag.placement.copy(
                width = width ?: tag.placement.width,
                height = height ?: tag.placement.height,
            ),
        )
    }

    private fun tagMutation(id: RecordId, mutation: (Tag) -> Tag): RepositoryResult<Tag> {
        val current = tags.firstOrNull { it.tagId == id }
            ?: return RepositoryResult.DomainFailure("tag-not-found-error", listOf(id))
        val updated = mutation(current)
        tags.replaceAll { if (it.tagId == id) updated else it }
        return RepositoryResult.Success(updated)
    }
}

private fun book(
    key: String,
    title: String = "Book $key",
    icon: String = "book",
    color: Color = Color(argb = 0),
    tagIds: List<RecordId> = emptyList(),
) = Book(bookId = rid("book", key), title = title, icon = icon, color = color, tagIds = tagIds)

private fun rid(table: String, key: String) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))
