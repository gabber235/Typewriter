package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import protokt.v1.typewriter.api.v1.GetBookRequest
import protokt.v1.typewriter.api.v1.GetBookResponse
import protokt.v1.typewriter.api.v1.ListBooks
import protokt.v1.typewriter.api.v1.ListBooksRequest
import protokt.v1.typewriter.api.v1.ListBooksResponse
import protokt.v1.typewriter.api.v1.UpdateBookRequest
import protokt.v1.typewriter.api.v1.UpdateBookResponse
import protokt.v1.typewriter.models.v1.Error

class BookRoutes(
    private val bookRepository: BookRepository
) {
    fun configure(): NatsRouting.() -> Unit = {
        route("realm.in.{serviceId}") {
            handle("book.list") {
                receive<ListBooksRequest>(ListBooksRequest)
                val books = bookRepository.listBooks()
                val response = ListBooksResponse {
                    result = ListBooksResponse.Result.Books(ListBooks { this.books = books })
                }
                reply(response)
            }

            handle("book.get") {
                val request = receive<GetBookRequest>(GetBookRequest)
                val book = bookRepository.getBook(request.id)
                val response = if (book != null) {
                    GetBookResponse { result = GetBookResponse.Result.Book(book) }
                } else {
                    GetBookResponse {
                        result = GetBookResponse.Result.Error(Error { message = "Book not found: ${request.id}" })
                    }
                }
                reply(response)
            }

            handle("book.update") {
                val request = receive<UpdateBookRequest>(UpdateBookRequest)
                val book = request.book
                if (book == null) {
                    val response = UpdateBookResponse {
                        result = UpdateBookResponse.Result.Error(Error { message = "Book is required" })
                    }
                    reply(response)
                    return@handle
                }
                val updatedBook = bookRepository.updateBook(book)
                val response = UpdateBookResponse { result = UpdateBookResponse.Result.Book(updatedBook) }
                reply(response)
            }
        }
    }
}
