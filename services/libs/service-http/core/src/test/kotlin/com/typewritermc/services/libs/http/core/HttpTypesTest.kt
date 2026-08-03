package com.typewritermc.services.libs.http.core

import com.typewritermc.services.libs.telemetry.ErrorSlug
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import java.net.URI

val HttpTypesTest by testSuite {
    test("headers are case insensitive and multi value") {
        val headers = HttpHeaders.of("X-Test" to "one", "x-test" to "two")
        headers.values("X-TEST").shouldContainExactly("one", "two")
        headers.set("x-TEST", "three").values("X-Test").shouldContainExactly("three")
    }
    test("header values reject C0 and DEL except HTAB and allow visible and extended characters") {
        ((0..31).filter { it != 9 } + 127).forEach { code ->
            shouldThrow<IllegalArgumentException> { HttpHeaders.of("safe" to "before${code.toChar()}after") }
        }
        HttpHeaders.of("safe" to "tab\t visible ~ extended é").first("safe") shouldBe "tab\t visible ~ extended é"
        shouldThrow<IllegalArgumentException> { HttpHeaders.of("safe" to "value€") }
        shouldThrow<IllegalArgumentException> { HttpHeaders.of("safe" to "value😀") }
    }
    test("header iteration cannot mutate the collection") {
        val headers = HttpHeaders.of("X-First" to "one", "X-Second" to "two")
        val iterator = headers.iterator() as MutableIterator<Pair<String, String>>
        iterator.next()
        iterator.remove()
        headers.toList().shouldContainExactly("X-First" to "one", "X-Second" to "two")
    }
    test("requests reject restricted headers case insensitively") {
        listOf("connection", "Content-Length", "EXPECT", "Host", "upgrade").forEach { name ->
            shouldThrow<IllegalArgumentException> {
                HttpRequest(
                    HttpOperation("test"),
                    ErrorSlug.of("test"),
                    HttpMethod.GET,
                    URI("https://example.test"),
                    HttpHeaders.of(name to "value"),
                )
            }
        }
    }
    test("request and response bodies are defensively copied") {
        val source = byteArrayOf(1, 2)
        val request =
            HttpRequest(
                HttpOperation("test.get"),
                ErrorSlug.of("test-failure"),
                HttpMethod.POST,
                URI("https://example.test"),
                body = source,
            )
        source[0] = 9
        request.body[1] = 9
        request.body.toList() shouldBe listOf<Byte>(1, 2)
        val response = HttpResponse(200, HttpHeaders.Empty, source)
        source[1] = 8
        response.body.toList() shouldBe listOf<Byte>(9, 2)
    }
    test("diagnostics redact URI query headers body and error details") {
        val request =
            HttpRequest(
                HttpOperation("test"),
                ErrorSlug.of("test"),
                HttpMethod.POST,
                URI("https://example.test/path?token=query-secret"),
                HttpHeaders.of("authorization" to "header-secret"),
                "body-secret".toByteArray(),
            )
        val diagnostics =
            listOf(
                request,
                HttpResponse(200, request.headers, "response-secret".toByteArray()),
                HttpError.Invalid("token-secret"),
                HttpError.Transport("secret.Transport"),
                HttpResult.Failure(HttpError.Invalid("secret")),
            ).joinToString()
        listOf("query-secret", "header-secret", "body-secret", "response-secret", "token-secret", "secret.Transport").forEach {
            diagnostics.contains(it) shouldBe false
        }
    }
    test("requests validate URI body timeout and limits") {
        shouldThrow<IllegalArgumentException> {
            HttpRequest(HttpOperation("test"), ErrorSlug.of("test"), HttpMethod.GET, URI("ftp://example.test"))
        }
        shouldThrow<IllegalArgumentException> {
            HttpRequest(HttpOperation("test"), ErrorSlug.of("test"), HttpMethod.GET, URI("https://example.test"), body = byteArrayOf(1))
        }
        shouldThrow<IllegalArgumentException> {
            HttpRequest(HttpOperation("test"), ErrorSlug.of("test"), HttpMethod.GET, URI("https://example.test"), maximumResponseBytes = 0)
        }
    }
}
