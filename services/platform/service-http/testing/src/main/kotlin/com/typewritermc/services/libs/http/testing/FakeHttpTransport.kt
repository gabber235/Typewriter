package com.typewritermc.services.libs.http.testing

import com.typewritermc.services.libs.http.core.HttpHeaders
import com.typewritermc.services.libs.http.core.HttpMethod
import com.typewritermc.services.libs.http.core.HttpOperation
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.http.core.HttpTransport
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Immutable request snapshot captured by [FakeHttpTransport]. */
data class FakeHttpAction(
    val operation: HttpOperation,
    val method: HttpMethod,
    val uri: java.net.URI,
    val headers: HttpHeaders,
    val body: List<Byte>,
) {
    override fun toString(): String =
        "FakeHttpAction(operation=$operation, method=$method, uri=${uri.scheme}://${uri.host}, headers=$headers, bodySize=${body.size})"
}

/** Deterministic scripted HTTP transport. */
class FakeHttpTransport(
    outcomes: Iterable<suspend (HttpRequest) -> HttpResult> = emptyList(),
) : HttpTransport {
    private val mutex = Mutex()
    private val scripted = ArrayDeque(outcomes.toList())
    private val recorded = mutableListOf<FakeHttpAction>()
    val actions: List<FakeHttpAction> get() = synchronized(recorded) { recorded.toList() }

    suspend fun enqueue(outcome: suspend (HttpRequest) -> HttpResult) = mutex.withLock { scripted.addLast(outcome) }

    suspend fun enqueue(result: HttpResult) = enqueue { result }

    override suspend fun execute(request: HttpRequest): HttpResult {
        val outcome =
            mutex.withLock {
                synchronized(recorded) {
                    val body = java.util.Collections.unmodifiableList(request.body.toList())
                    recorded += FakeHttpAction(request.operation, request.method, request.uri, request.headers, body)
                }
                check(scripted.isNotEmpty()) { "No scripted HTTP outcome" }
                scripted.removeFirst()
            }
        return outcome(request)
    }
}
