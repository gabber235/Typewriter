package com.typewritermc.services.libs.http.jdk

import com.sun.net.httpserver.HttpServer
import com.typewritermc.services.libs.http.core.HttpMethod
import com.typewritermc.services.libs.http.core.HttpOperation
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.telemetry.ErrorSlug
import java.net.InetSocketAddress
import java.net.URI
import kotlin.time.Duration

/** A POST of three bytes to [uri] that accepts at most [maximumResponseBytes] back. */
fun echo(
    uri: URI,
    maximumResponseBytes: Long,
) = HttpRequest(
    HttpOperation("jdk.echo"),
    ErrorSlug.of("jdk-failed"),
    HttpMethod.POST,
    uri,
    body = byteArrayOf(1, 2, 3),
    maximumResponseBytes = maximumResponseBytes,
)

/** A GET of [path] on a local test [server], with an optional [timeout]. */
fun localRequest(
    server: HttpServer,
    path: String,
    timeout: Duration? = null,
) = HttpRequest(
    HttpOperation("jdk.local"),
    ErrorSlug.of("jdk-failed"),
    HttpMethod.GET,
    URI("http://127.0.0.1:${server.address.port}$path"),
    timeout = timeout,
)

/** Runs [block] against a local server that echoes the request body with a 503 and two `X-Multi` headers. */
suspend fun withEchoServer(block: suspend (URI) -> Unit) {
    val server = HttpServer.create(InetSocketAddress(0), 0)
    server.createContext("/echo") { exchange ->
        val body = exchange.requestBody.readAllBytes()
        exchange.responseHeaders.add("X-Multi", "one")
        exchange.responseHeaders.add("X-Multi", "two")
        exchange.sendResponseHeaders(503, body.size.toLong())
        exchange.responseBody.use { it.write(body) }
    }
    server.start()
    try {
        block(URI("http://127.0.0.1:${server.address.port}/echo"))
    } finally {
        server.stop(0)
    }
}
