package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.mockk
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

    fun serialize(message: protokt.v1.AbstractMessage): ByteArray {
        return ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
    }

    context("list books") {
        test("returns all books from repository") {
            val mockRepo = mockk<BookRepository>()
            val books = listOf(
                Book { id = "book:1"; title = "Book One"; icon = "book"; color = Color { value = 0xFF0000u } },
                Book { id = "book:2"; title = "Book Two"; icon = "star"; color = Color { value = 0x00FF00u } }
            )
            coEvery { mockRepo.listBooks() } returns books

            val routes = BookRoutes(mockRepo)
            val request = ListBooksRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.book.list",
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

            val routes = BookRoutes(mockRepo)
            val request = ListBooksRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.book.list",
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
            val book = Book { id = "book:123"; title = "Test Book"; icon = "diamond"; color = Color { value = 0xFF0000u } }
            coEvery { mockRepo.getBook("book:123") } returns book

            val routes = BookRoutes(mockRepo)
            val request = GetBookRequest { id = "book:123" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.book.get",
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
            coEvery { mockRepo.getBook("book:missing") } returns null

            val routes = BookRoutes(mockRepo)
            val request = GetBookRequest { id = "book:missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.book.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<GetBookResponse.Result.Error>()
            bookResult.error.message shouldBe "Book not found: book:missing"
        }
    }

    context("update book") {
        test("updates book and returns it") {
            val mockRepo = mockk<BookRepository>()
            val updatedBook = Book {
                id = "book:existing"
                title = "Updated Title"
                icon = "new_icon"
                color = Color { value = 0xFFFFFFu }
            }
            coEvery { mockRepo.updateBook(any()) } returns updatedBook

            val routes = BookRoutes(mockRepo)
            val request = UpdateBookRequest {
                book = Book {
                    id = "book:existing"
                    title = "Updated Title"
                    icon = "new_icon"
                    color = Color { value = 0xFFFFFFu }
                }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.book.update",
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
            val routes = BookRoutes(mockRepo)
            val request = UpdateBookRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.book.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdateBookResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val bookResult = response.result
            bookResult.shouldBeInstanceOf<UpdateBookResponse.Result.Error>()
            bookResult.error.message shouldBe "Book is required"
        }
    }
})
