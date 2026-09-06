package com.typewritermc.services.libs.http.jdk

import com.sun.net.httpserver.HttpServer
import com.typewritermc.services.libs.http.core.HttpError
import com.typewritermc.services.libs.http.core.HttpMethod
import com.typewritermc.services.libs.http.core.HttpOperation
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.URI
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

val JdkHttpTransportTest by testSuite {
    test("omits HTTP control data from response headers") {
        val headers =
            java.net.http.HttpHeaders.of(
                mapOf(
                    ":status" to listOf("200"),
                    "content-type" to listOf("application/skir"),
                    "x-multi" to listOf("one", "two"),
                ),
            ) { _, _ -> true }

        val converted = headers.toCoreHeaders()

        converted.values(":status") shouldBe emptyList()
        converted.first("content-type") shouldBe "application/skir"
        converted.values("x-multi") shouldBe listOf("one", "two")
    }

    test("sends bodies preserves response status and bounds response collection") {
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
            JdkHttpTransport().use { transport ->
                val uri = URI("http://127.0.0.1:${server.address.port}/echo")
                val request =
                    HttpRequest(
                        HttpOperation("jdk.echo"),
                        ErrorSlug.of("jdk-failed"),
                        HttpMethod.POST,
                        uri,
                        body = byteArrayOf(1, 2, 3),
                        maximumResponseBytes = 10,
                    )
                val response = (transport.execute(request) as HttpResult.Success).response
                response.statusCode shouldBe 503
                response.body.toList() shouldBe listOf<Byte>(1, 2, 3)
                response.headers.values("x-multi").toSet() shouldBe setOf("one", "two")
                transport.execute(
                    HttpRequest(
                        HttpOperation("jdk.limit"),
                        ErrorSlug.of("jdk-failed"),
                        HttpMethod.POST,
                        uri,
                        body = byteArrayOf(1, 2, 3),
                        maximumResponseBytes = 2,
                    ),
                ) shouldBe
                    HttpResult.Failure(HttpError.ResponseTooLarge(2))
            }
        } finally {
            server.stop(0)
        }
    }

    test("redirects are never followed") {
        val server = HttpServer.create(InetSocketAddress(0), 0)
        var targetCalls = 0
        server.createContext("/redirect") { exchange ->
            exchange.responseHeaders.add("Location", "/target")
            exchange.sendResponseHeaders(302, -1)
            exchange.close()
        }
        server.createContext("/target") { exchange ->
            targetCalls++
            exchange.sendResponseHeaders(200, -1)
            exchange.close()
        }
        server.start()
        try {
            JdkHttpTransport().use { transport ->
                (transport.execute(localRequest(server, "/redirect")) as HttpResult.Success).response.statusCode shouldBe 302
                targetCalls shouldBe 0
            }
        } finally {
            server.stop(0)
        }
    }

    test("request timeout maps to Timeout") {
        val server = HttpServer.create(InetSocketAddress(0), 0)
        server.createContext("/slow") { exchange ->
            Thread.sleep(500)
            runCatching {
                exchange.sendResponseHeaders(200, -1)
                exchange.close()
            }
        }
        server.start()
        try {
            JdkHttpTransport().use { transport ->
                withContext(Dispatchers.IO) {
                    withTimeout(2.seconds) {
                        transport.execute(localRequest(server, "/slow", 50.milliseconds)) shouldBe HttpResult.Failure(HttpError.Timeout)
                    }
                }
            }
        } finally {
            server.stop(0)
        }
    }

    test("closed local port maps to Unavailable") {
        val port = ServerSocket(0).use { it.localPort }
        JdkHttpTransport().use { transport ->
            withContext(Dispatchers.IO) {
                withTimeout(2.seconds) {
                    transport.execute(
                        HttpRequest(
                            HttpOperation("jdk.unavailable"),
                            ErrorSlug.of("jdk-failed"),
                            HttpMethod.GET,
                            URI("http://127.0.0.1:$port"),
                            timeout = 1.seconds,
                        ),
                    ) shouldBe HttpResult.Failure(HttpError.Unavailable)
                }
            }
        }
    }

    test("caller cancellation promptly cancels a blocked request") {
        val server = HttpServer.create(InetSocketAddress(0), 0)
        server.createContext("/blocked") { exchange ->
            Thread.sleep(1000)
            runCatching {
                exchange.sendResponseHeaders(200, -1)
                exchange.close()
            }
        }
        server.start()
        try {
            JdkHttpTransport().use { transport ->
                withContext(Dispatchers.IO) {
                    withTimeout(500.milliseconds) {
                        coroutineScope {
                            val call = async { transport.execute(localRequest(server, "/blocked")) }
                            delay(25.milliseconds)
                            call.cancel()
                            call.join()
                            call.isCancelled shouldBe true
                        }
                    }
                }
            }
        } finally {
            server.stop(0)
        }
    }

    test("streaming response overflow returns promptly") {
        val server = HttpServer.create(InetSocketAddress(0), 0)
        server.createContext("/stream") { exchange ->
            runCatching {
                exchange.sendResponseHeaders(200, 0)
                exchange.responseBody.use { output ->
                    repeat(100) {
                        output.write(ByteArray(1024))
                        output.flush()
                    }
                }
            }
        }
        server.start()
        try {
            JdkHttpTransport().use { transport ->
                withContext(Dispatchers.IO) {
                    withTimeout(2.seconds) {
                        val limited =
                            HttpRequest(
                                HttpOperation("jdk.stream"),
                                ErrorSlug.of("jdk-failed"),
                                HttpMethod.GET,
                                URI("http://127.0.0.1:${server.address.port}/stream"),
                                maximumResponseBytes = 1024,
                            )
                        transport.execute(limited) shouldBe HttpResult.Failure(HttpError.ResponseTooLarge(1024))
                    }
                }
            }
        } finally {
            server.stop(0)
        }
    }

    test("close is idempotent and execution after close fails fast") {
        val transport = JdkHttpTransport()
        transport.close()
        transport.close()
        val request =
            HttpRequest(
                HttpOperation("jdk.closed"),
                ErrorSlug.of("jdk-failed"),
                HttpMethod.GET,
                URI("http://127.0.0.1"),
            )
        shouldThrow<IllegalStateException> { transport.execute(request) }
    }
}

private fun localRequest(
    server: HttpServer,
    path: String,
    timeout: kotlin.time.Duration? = null,
) = HttpRequest(
    HttpOperation("jdk.local"),
    ErrorSlug.of("jdk-failed"),
    HttpMethod.GET,
    URI("http://127.0.0.1:${server.address.port}$path"),
    timeout = timeout,
)
