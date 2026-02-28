package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.StateProvider
import com.typewritermc.services.libs.utils.asDeferredProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import protokt.v1.typewriter.api.v1.CreateBookRequest
import protokt.v1.typewriter.api.v1.CreateBookResponse
import protokt.v1.typewriter.api.v1.GetBookRequest
import protokt.v1.typewriter.api.v1.GetBookResponse
import protokt.v1.typewriter.api.v1.ListBooks
import protokt.v1.typewriter.api.v1.ListBooksRequest
import protokt.v1.typewriter.api.v1.ListBooksResponse
import protokt.v1.typewriter.api.v1.UpdateBookRequest
import protokt.v1.typewriter.api.v1.UpdateBookResponse
import protokt.v1.typewriter.models.v1.Book
import protokt.v1.typewriter.models.v1.Color
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class BookRoutesTest : FunSpec({

    val credentials = Credential(id = "test-service", name = "Test Service", token = "test-token").asDeferredProvider()
    val registrationStateProvider = StateProvider<RegistrationState>(
        RegistrationState.Bound(organizationId = "test-org", organizationName = "Test Organization")
    )

    fun serialize(message: protokt.v1.AbstractMessage): ByteArray {
        return ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
    }

    context("list books") {
        test("returns all books from repository") {
            val mockRepo = mockk<BookRepository>()
            val books = listOf(
                Book { bookId = "1"; title = "Book One"; icon = "book"; color = Color { value = 0xFF0000u } },
                Book { bookId = "2"; title = "Book Two"; icon = "star"; color = Color { value = 0x00FF00u } }
            )
            coEvery { mockRepo.listBooks() } returns books

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ListBooksRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.list",
                data = serialize(request)
            )

            result.success shouldBe true
            result.replies.size shouldBe 1

            val response = ListBooksResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val booksResult = response.result
            booksResult.shouldBeInstanceOf<ListBooksResponse.Result.Books>()
            booksResult.books.books.size shouldBe 2
            booksResult.books.books[0].title shouldBe "Book One"
            booksResult.books.books[1].title shouldBe "Book Two"
        }

        test("returns empty list when no books exist") {
            val mockRepo = mockk<BookRepository>()
            coEvery { mockRepo.listBooks() } returns emptyList()

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ListBooksRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.list",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ListBooksResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val booksResult = response.result
            booksResult.shouldBeInstanceOf<ListBooksResponse.Result.Books>()
            booksResult.books.books.size shouldBe 0
        }
    }

    context("get book") {
        test("returns book when found") {
            val mockRepo = mockk<BookRepository>()
            val book = Book { bookId = "123"; title = "Test Book"; icon = "diamond"; color = Color { value = 0xFF0000u } }
            coEvery { mockRepo.getBook("123") } returns book

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = GetBookRequest { bookId = "123" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<GetBookResponse.Result.Book>()
            bookResult.book.title shouldBe "Test Book"
        }

        test("returns error when book not found") {
            val mockRepo = mockk<BookRepository>()
            coEvery { mockRepo.getBook("missing") } returns null

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = GetBookRequest { bookId = "missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<GetBookResponse.Result.Error>()
            bookResult.error.message!! shouldBe "Book not found: missing"
        }
    }

    context("update book") {
        test("updates book and returns it") {
            val mockRepo = mockk<BookRepository>()
            val updatedBook = Book {
                bookId = "existing"
                title = "Updated Title"
                icon = "new_icon"
                color = Color { value = 0xFFFFFFu }
            }
            coEvery { mockRepo.updateBook(any()) } returns updatedBook

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = UpdateBookRequest {
                book = Book {
                    bookId = "existing"
                    title = "Updated Title"
                    icon = "new_icon"
                    color = Color { value = 0xFFFFFFu }
                }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdateBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<UpdateBookResponse.Result.Book>()
            bookResult.book.title shouldBe "Updated Title"
        }

        test("returns error when book is null in request") {
            val mockRepo = mockk<BookRepository>()
            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = UpdateBookRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdateBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<UpdateBookResponse.Result.Error>()
            bookResult.error.message!! shouldBe "Book is required"
        }
    }

    context("create book") {
        test("createBook returns created book with all fields and tags") {
            val mockRepo = mockk<BookRepository>()
            val expectedBook = Book {
                bookId = "book-1"
                title = "My Book"
                icon = "star"
                color = Color { value = 12345u }
                tagIds = listOf("tag-1", "tag-2")
            }
            coEvery {
                mockRepo.createBook("My Book", "star", 12345, listOf("tag-1", "tag-2"))
            } returns expectedBook

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreateBookRequest {
                title = "My Book"
                icon = "star"
                color = Color { value = 12345u }
                tagIds = listOf("tag-1", "tag-2")
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<CreateBookResponse.Result.Book>()
            bookResult.book.bookId shouldBe "book-1"
            bookResult.book.title shouldBe "My Book"
            bookResult.book.icon shouldBe "star"
            bookResult.book.tagIds shouldContainExactlyInAnyOrder listOf("tag-1", "tag-2")
            coVerify { mockRepo.createBook("My Book", "star", 12345, listOf("tag-1", "tag-2")) }
        }

        test("createBook with only title returns book with defaults") {
            val mockRepo = mockk<BookRepository>()
            val expectedBook = Book {
                bookId = "book-2"
                title = "Simple Book"
                icon = "book"
                color = Color { value = 0u }
                tagIds = emptyList()
            }
            coEvery {
                mockRepo.createBook("Simple Book", "book", 0, emptyList())
            } returns expectedBook

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreateBookRequest { title = "Simple Book" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<CreateBookResponse.Result.Book>()
            bookResult.book.title shouldBe "Simple Book"
            bookResult.book.icon shouldBe "book"
            bookResult.book.tagIds.shouldBeEmpty()
        }

        test("createBook when repository throws returns error") {
            val mockRepo = mockk<BookRepository>()
            coEvery {
                mockRepo.createBook(any(), any(), any(), any())
            } throws RuntimeException("Database error")

            val routes = BookRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreateBookRequest { title = "Failing Book" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.book.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<CreateBookResponse.Result.Error>()
            bookResult.error.message!! shouldContain "Database error"
        }
    }
})
