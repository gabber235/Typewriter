package com.typewritermc.services.libs.http.testing

import com.typewritermc.services.libs.http.core.HttpError
import com.typewritermc.services.libs.http.core.HttpHeaders
import com.typewritermc.services.libs.http.core.HttpMethod
import com.typewritermc.services.libs.http.core.HttpOperation
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.net.URI

val FakeHttpTransportTest by testSuite {
    test("records immutable ordered redacted actions and scripted failures") {
        val fake = FakeHttpTransport(listOf({ HttpResult.Failure(HttpError.Timeout) }, { HttpResult.Failure(HttpError.Unavailable) }))
        val body = byteArrayOf(1, 2)
        val request =
            HttpRequest(
                HttpOperation("fake.call"),
                ErrorSlug.of("fake-failed"),
                HttpMethod.POST,
                URI("https://example.test/path?token=secret"),
                HttpHeaders.of("authorization" to "secret"),
                body,
            )
        fake.execute(request) shouldBe HttpResult.Failure(HttpError.Timeout)
        body[0] = 9
        fake.execute(request) shouldBe HttpResult.Failure(HttpError.Unavailable)
        fake.actions.map { it.body } shouldBe listOf(listOf<Byte>(1, 2), listOf<Byte>(1, 2))
        shouldThrow<UnsupportedOperationException> { (fake.actions.first().body as MutableList<Byte>)[0] = 8 }
        val actionCopy = fake.actions as MutableList<FakeHttpAction>
        actionCopy.clear()
        fake.actions.size shouldBe 2
        fake.actions
            .first()
            .headers
            .first("authorization") shouldBe "secret"
        fake.actions.joinToString().contains("secret") shouldBe false
    }

    test("fails when the script is exhausted") {
        val fake = FakeHttpTransport()
        val request =
            HttpRequest(
                HttpOperation("fake.call"),
                ErrorSlug.of("fake-failed"),
                HttpMethod.GET,
                URI("https://example.test"),
            )
        shouldThrow<IllegalStateException> { fake.execute(request) }
    }
}
