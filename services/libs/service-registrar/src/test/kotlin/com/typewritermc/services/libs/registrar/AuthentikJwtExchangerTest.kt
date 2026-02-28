package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.HttpResponse
import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import java.io.ByteArrayInputStream

class AuthentikJwtExchangerTest : FunSpec({

    val defaultCredential = Credential(id = "svc-1", name = "service-user", token = "app-password")
    val tokenEndpoint = "https://auth.example.com/token"
    val clientId = "my-client-id"
    val scopes = "openid profile"

    context("Happy Path Scenarios") {

        test("exchangeForJwt returns TokenResponse on successful exchange") {
            val httpClient = mockk<HttpClient>()
            val jsonResponse = """{"access_token":"jwt-token","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            val response = exchanger.exchangeForJwt(defaultCredential)

            response.accessToken shouldBe "jwt-token"
            response.expiresIn shouldBe 3600
            response.tokenType shouldBe "Bearer"
        }

        test("exchangeForJwt includes refresh_token when present in response") {
            val httpClient = mockk<HttpClient>()
            val jsonResponse = """{"access_token":"jwt","refresh_token":"refresh-xyz","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            val response = exchanger.exchangeForJwt(defaultCredential)

            response.refreshToken shouldBe "refresh-xyz"
        }

        test("exchangeForJwt sends correct form data with URL encoding") {
            val httpClient = mockk<HttpClient>()
            val bodySlot = slot<ByteArray>()
            val jsonResponse = """{"access_token":"jwt","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), capture(bodySlot), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            exchanger.exchangeForJwt(defaultCredential)

            val formData = String(bodySlot.captured)
            formData shouldContain "grant_type=client_credentials"
            formData shouldContain "client_id=$clientId"
            formData shouldContain "username=service-user"
            formData shouldContain "password=app-password"
            formData shouldContain "scope=openid+profile"
        }

        test("exchangeForJwt posts to correct token endpoint") {
            val httpClient = mockk<HttpClient>()
            val urlSlot = slot<String>()
            val jsonResponse = """{"access_token":"jwt","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(capture(urlSlot), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            exchanger.exchangeForJwt(defaultCredential)

            urlSlot.captured shouldBe tokenEndpoint
        }

        test("exchangeForJwt sets correct Content-Type header") {
            val httpClient = mockk<HttpClient>()
            val headersSlot = slot<Map<String, String>>()
            val jsonResponse = """{"access_token":"jwt","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), any(), capture(headersSlot)) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            exchanger.exchangeForJwt(defaultCredential)

            headersSlot.captured["Content-Type"] shouldBe "application/x-www-form-urlencoded"
        }
    }

    context("Error and Failure Scenarios") {

        test("exchangeForJwt throws on 401 Unauthorized") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 401,
                body = ByteArrayInputStream("Invalid credentials".toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())

            val exception = shouldThrow<JwtExchangeException> {
                exchanger.exchangeForJwt(defaultCredential)
            }

            exception.message shouldContain "HTTP 401"
            exception.message shouldContain "Invalid credentials"
        }

        test("exchangeForJwt throws on 403 Forbidden") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 403,
                body = ByteArrayInputStream("Forbidden".toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())

            val exception = shouldThrow<JwtExchangeException> {
                exchanger.exchangeForJwt(defaultCredential)
            }

            exception.message shouldContain "HTTP 403"
        }

        test("exchangeForJwt throws on 500 Internal Server Error") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 500,
                body = ByteArrayInputStream("Internal server error".toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())

            val exception = shouldThrow<JwtExchangeException> {
                exchanger.exchangeForJwt(defaultCredential)
            }

            exception.message shouldContain "HTTP 500"
        }

        test("exchangeForJwt throws on malformed JSON response") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream("not valid json".toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())

            val exception = shouldThrow<JwtExchangeException> {
                exchanger.exchangeForJwt(defaultCredential)
            }

            exception.message shouldContain "parse token response"
        }

        test("exchangeForJwt throws when access_token is missing from response") {
            val httpClient = mockk<HttpClient>()
            val jsonResponse = """{"expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())

            val exception = shouldThrow<JwtExchangeException> {
                exchanger.exchangeForJwt(defaultCredential)
            }

            exception.message shouldContain "parse token response"
        }

        test("exchangeForJwt throws on connection failure") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } throws RuntimeException("Connection refused")

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())

            val exception = shouldThrow<JwtExchangeException> {
                exchanger.exchangeForJwt(defaultCredential)
            }

            exception.message shouldContain "Connection refused"
            (exception.cause is RuntimeException) shouldBe true
        }
    }

    context("Edge Cases") {

        test("exchangeForJwt URL-encodes credential with special characters") {
            val httpClient = mockk<HttpClient>()
            val bodySlot = slot<ByteArray>()
            val jsonResponse = """{"access_token":"jwt","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), capture(bodySlot), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val specialCredential = Credential(
                id = "svc",
                name = "user@domain.com",
                token = "p@ss=word&special"
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            exchanger.exchangeForJwt(specialCredential)

            val formData = String(bodySlot.captured)
            formData shouldContain "username=user%40domain.com"
            formData shouldContain "password=p%40ss%3Dword%26special"
        }

        test("exchangeForJwt handles very long JWT tokens") {
            val httpClient = mockk<HttpClient>()
            val longToken = "eyJ" + "a".repeat(5000) + ".payload.signature"
            val jsonResponse = """{"access_token":"$longToken","expires_in":3600,"token_type":"Bearer"}"""

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(jsonResponse.toByteArray())
            )

            val exchanger = AuthentikJwtExchanger(httpClient, tokenEndpoint, clientId, scopes, MockTelemetry.createMockTracer())
            val response = exchanger.exchangeForJwt(defaultCredential)

            response.accessToken shouldBe longToken
        }
    }
})
