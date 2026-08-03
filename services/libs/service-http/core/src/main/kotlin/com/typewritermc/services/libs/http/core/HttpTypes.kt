package com.typewritermc.services.libs.http.core

import com.typewritermc.services.libs.telemetry.ErrorSlug
import java.net.URI
import kotlin.time.Duration

/** Immutable case-insensitive HTTP header collection preserving all values. */
class HttpHeaders private constructor(
    private val entries: List<Pair<String, String>>,
) : Iterable<Pair<String, String>> {
    override fun iterator(): Iterator<Pair<String, String>> = entries.toList().iterator()

    fun values(name: String): List<String> = entries.filter { it.first.equals(name, true) }.map { it.second }

    fun first(name: String): String? = values(name).firstOrNull()

    fun add(
        name: String,
        value: String,
    ): HttpHeaders = of(entries + (name to value))

    fun set(
        name: String,
        value: String,
    ): HttpHeaders = of(entries.filterNot { it.first.equals(name, true) } + (name to value))

    fun remove(name: String): HttpHeaders = of(entries.filterNot { it.first.equals(name, true) })

    override fun equals(other: Any?): Boolean = other is HttpHeaders && normalized() == other.normalized()

    override fun hashCode(): Int = normalized().hashCode()

    override fun toString(): String = "HttpHeaders(size=${entries.size})"

    private fun normalized() = entries.map { it.first.lowercase() to it.second }

    companion object {
        val Empty = HttpHeaders(emptyList())

        fun of(vararg entries: Pair<String, String>): HttpHeaders = of(entries.asList())

        fun of(entries: Iterable<Pair<String, String>>): HttpHeaders {
            val copy = entries.toList()
            copy.forEach { (name, value) ->
                require(
                    name.isNotEmpty() && name.all { it.code in 33..126 && it !in "():<>@,;\\\"/[]?={} \t" },
                ) { "Invalid HTTP header name" }
                require(value.all { it == '\t' || it.code in 32..126 || it.code in 128..255 }) {
                    "Invalid HTTP header value"
                }
            }
            return if (copy.isEmpty()) Empty else HttpHeaders(copy)
        }
    }
}

@JvmInline value class HttpOperation(
    val value: String,
) {
    init {
        require(Regex("[a-z0-9]+(?:[.-][a-z0-9]+)*").matches(value)) { "Invalid HTTP operation" }
    }
}

enum class HttpMethod(
    val permitsBody: Boolean,
) {
    GET(false),
    HEAD(false),
    POST(true),
    PUT(true),
    PATCH(true),
    DELETE(true),
    OPTIONS(true),
}

class HttpRequest(
    val operation: HttpOperation,
    val failureSlug: ErrorSlug,
    val method: HttpMethod,
    val uri: URI,
    val headers: HttpHeaders = HttpHeaders.Empty,
    body: ByteArray = byteArrayOf(),
    val timeout: Duration? = null,
    val maximumRequestBytes: Long? = null,
    val maximumResponseBytes: Long? = null,
) {
    private val bodyBytes = body.copyOf()
    val body: ByteArray get() = bodyBytes.copyOf()

    init {
        require(uri.scheme.equals("http", true) || uri.scheme.equals("https", true)) { "HTTP URI scheme is required" }
        require(!uri.host.isNullOrBlank() && !uri.isOpaque && uri.userInfo == null) { "HTTP URI must have a host and no user info" }
        require(method.permitsBody || body.isEmpty()) { "$method requests cannot have a body" }
        require(headers.none { (name) -> name.lowercase() in RestrictedRequestHeaders }) { "Restricted HTTP request header name" }
        timeout?.let { require(it.isFinite() && it.isPositive()) { "Timeout must be positive and finite" } }
        maximumRequestBytes?.let { require(it > 0) { "Maximum request bytes must be positive" } }
        maximumResponseBytes?.let { require(it > 0) { "Maximum response bytes must be positive" } }
    }

    override fun toString(): String =
        "HttpRequest(operation=$operation, method=$method, uri=${uri.scheme}://${uri.host}, headers=$headers, bodySize=${bodyBytes.size})"

    private companion object {
        val RestrictedRequestHeaders = setOf("connection", "content-length", "expect", "host", "upgrade")
    }
}

class HttpResponse(
    val statusCode: Int,
    val headers: HttpHeaders,
    body: ByteArray,
) {
    private val bodyBytes = body.copyOf()
    val body: ByteArray get() = bodyBytes.copyOf()

    init {
        require(statusCode in 100..599) { "Invalid HTTP status code" }
    }

    override fun toString(): String = "HttpResponse(statusCode=$statusCode, headers=$headers, bodySize=${bodyBytes.size})"
}

sealed interface HttpError {
    data class RequestTooLarge(
        val maximumBytes: Long,
        val actualBytes: Long,
    ) : HttpError

    data class ResponseTooLarge(
        val maximumBytes: Long,
    ) : HttpError

    data object Timeout : HttpError

    data object Unavailable : HttpError

    data class Transport(
        val type: String,
    ) : HttpError {
        override fun toString(): String = "HttpError.Transport"
    }

    data class Invalid(
        val reason: String,
    ) : HttpError {
        override fun toString(): String = "HttpError.Invalid"
    }
}

sealed interface HttpResult {
    data class Success(
        val response: HttpResponse,
    ) : HttpResult

    class Failure(
        val error: HttpError,
    ) : HttpResult {
        override fun equals(other: Any?): Boolean = other is Failure && error == other.error

        override fun hashCode(): Int = error.hashCode()

        override fun toString(): String = "HttpResult.Failure(error=${error::class.simpleName})"
    }
}

fun interface HttpTransport {
    suspend fun execute(request: HttpRequest): HttpResult
}
