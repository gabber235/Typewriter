package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.telemetry.timed
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.opentelemetry.api.trace.StatusCode
import protokt.v1.typewriter.api.v1.*
import protokt.v1.typewriter.models.v1.Error

class BookRoutes(
    private val bookRepository: BookRepository,
    private val credentials: DeferredProvider<Credential>,
    private val registrationStateProvider: StateProvider<RegistrationState>,
) {
    fun configure(): NatsRouting.() -> Unit = {
        val serviceId = credentials.require { "BookRoutes requires the credentials to be set to register" }.id
        val orgId = when (val state = registrationStateProvider.get()) {
            is RegistrationState.Bound -> state.organizationId
            else -> error("Service must be bound to an organization before routes can be configured")
        }
        route("realm.to.${serviceId}.organization.${orgId}") {
            handle("book.list") {
                receive(ListBooksRequest)
                span.setAttribute("operation", "book.list")

                val books = span.timed("db.book.list") {
                    bookRepository.listBooks()
                }
                span.setAttribute("result.count", books.size.toLong())

                val response = ListBooksResponse {
                    result = ListBooksResponse.Result.Books(ListBooks { this.books = books })
                }
                reply(response)
            }

            handle("book.get") {
                val request = receive(GetBookRequest)
                span.setAttribute("operation", "book.get")

                val bookId = request.bookId.ifBlank {
                    return@handle reply(GetBookResponse {
                        result = GetBookResponse.Result.Error(Error { message = "book id is required" })
                    })
                }
                span.setAttribute("book.id", bookId)

                val book = span.timed("db.book.get") {
                    bookRepository.getBook(bookId)
                }

                val response = if (book != null) {
                    GetBookResponse { result = GetBookResponse.Result.Book(book) }
                } else {
                    span.setStatus(StatusCode.ERROR, "Book not found: $bookId")
                    GetBookResponse {
                        result = GetBookResponse.Result.Error(Error { message = "Book not found: $bookId" })
                    }
                }
                reply(response)
            }

            handle("book.update") {
                val request = receive(UpdateBookRequest)
                span.setAttribute("operation", "book.update")

                val book = request.book
                if (book == null) {
                    span.setStatus(StatusCode.ERROR, "Book is required")
                    val response = UpdateBookResponse {
                        result = UpdateBookResponse.Result.Error(Error { message = "Book is required" })
                    }
                    reply(response)
                    return@handle
                }
                span.setAttribute("book.id", book.bookId)

                val updatedBook = span.timed("db.book.update") {
                    bookRepository.updateBook(book)
                }
                val response = UpdateBookResponse { result = UpdateBookResponse.Result.Book(updatedBook) }
                reply(response)
            }

            handle("book.create") {
                val request = receive(CreateBookRequest)

                span.setAttribute("operation", "book.create")

                val title = request.title
                    ?: return@handle reply(CreateBookResponse {
                        result = CreateBookResponse.Result.Error(Error { message = "title is required" })
                    })
                val icon = request.icon?.ifEmpty { "book" } ?: "book"
                val colorValue = request.color?.value?.toInt() ?: 0

                span.setAttribute("book.title", title)
                span.setAttribute("book.icon", icon)
                span.setAttribute("book.has_color", request.color != null)
                request.color?.let {
                    span.setAttribute("book.color", (it.value ?: 0u).toLong())
                }
                span.setAttribute("book.tag_count", request.tagIds.size.toLong())

                try {
                    val book = span.timed("db.book.create") {
                        bookRepository.createBook(
                            title = title,
                            icon = icon,
                            color = colorValue,
                            tagIds = request.tagIds
                        )
                    }

                    span.setAttribute("book.id", book.bookId)
                    span.setAttribute("result.tag_count", book.tagIds.size.toLong())

                    val response = CreateBookResponse {
                        result = CreateBookResponse.Result.Book(book)
                    }
                    reply(response)
                } catch (e: Exception) {
                    span.setStatus(StatusCode.ERROR, e.message ?: "Failed to create book")
                    val response = CreateBookResponse {
                        result =
                            CreateBookResponse.Result.Error(Error { message = e.message ?: "Failed to create book" })
                    }
                    reply(response)
                }
            }
        }
    }
}
