package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.HttpResponse
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import protokt.v1.typewriter.api.v1.GetSentinelCredentialsResponse
import protokt.v1.typewriter.api.v1.SentinelCredentials as ProtoSentinelCredentials
import protokt.v1.typewriter.models.v1.Error
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class SentinelCredentialsFetcherTest : FunSpec({

    val sentinelUrl = "https://api.example.com/auth/sentinel"

    context("Happy Path Scenarios") {

        test("fetchCredentials returns SentinelCredentials on successful response") {
            val httpClient = mockk<HttpClient>()

            val credentials = ProtoSentinelCredentials {
                jwt = "sentinel-jwt-token"
                seed = "SUABC123SEED456"
            }
            val protoResponse = GetSentinelCredentialsResponse {
                result = GetSentinelCredentialsResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.get(any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)
            val result = fetcher.fetchCredentials()

            result.jwt shouldBe "sentinel-jwt-token"
            result.seed shouldBe "SUABC123SEED456"
        }

        test("fetchCredentials sets correct Accept header") {
            val httpClient = mockk<HttpClient>()
            val headersSlot = slot<Map<String, String>>()

            val credentials = ProtoSentinelCredentials {
                jwt = "jwt"
                seed = "seed"
            }
            val protoResponse = GetSentinelCredentialsResponse {
                result = GetSentinelCredentialsResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.get(any(), capture(headersSlot)) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)
            fetcher.fetchCredentials()

            headersSlot.captured["Accept"] shouldBe "application/x-protobuf"
        }

        test("fetchCredentials calls correct URL") {
            val httpClient = mockk<HttpClient>()
            val urlSlot = slot<String>()

            val credentials = ProtoSentinelCredentials {
                jwt = "jwt"
                seed = "seed"
            }
            val protoResponse = GetSentinelCredentialsResponse {
                result = GetSentinelCredentialsResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.get(capture(urlSlot), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)
            fetcher.fetchCredentials()

            urlSlot.captured shouldBe sentinelUrl
        }
    }

    context("Error and Failure Scenarios") {

        test("fetchCredentials throws on HTTP error") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.get(any(), any()) } returns HttpResponse(
                statusCode = 503,
                body = ByteArrayInputStream("Service unavailable".toByteArray())
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)

            val exception = shouldThrow<SentinelCredentialsException> {
                fetcher.fetchCredentials()
            }

            exception.message shouldContain "HTTP 503"
        }

        test("fetchCredentials throws on backend error response") {
            val httpClient = mockk<HttpClient>()

            val protoResponse = GetSentinelCredentialsResponse {
                result = GetSentinelCredentialsResponse.Result.Error(Error {
                    code = 429u
                    message = "Rate limit exceeded"
                })
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.get(any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)

            val exception = shouldThrow<SentinelCredentialsException> {
                fetcher.fetchCredentials()
            }

            exception.message shouldContain "429"
            exception.message shouldContain "Rate limit exceeded"
        }

        test("fetchCredentials throws on malformed protobuf response") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.get(any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream("not valid protobuf".toByteArray())
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)

            val exception = shouldThrow<SentinelCredentialsException> {
                fetcher.fetchCredentials()
            }

            exception.message shouldContain "parse sentinel credentials response"
        }

        test("fetchCredentials throws on empty response result") {
            val httpClient = mockk<HttpClient>()

            val protoResponse = GetSentinelCredentialsResponse {}
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            if (responseBytes.isEmpty()) {
                every { httpClient.get(any(), any()) } returns HttpResponse(
                    statusCode = 200,
                    body = ByteArrayInputStream(byteArrayOf(0x08, 0x00))
                )
            } else {
                every { httpClient.get(any(), any()) } returns HttpResponse(
                    statusCode = 200,
                    body = ByteArrayInputStream(responseBytes)
                )
            }

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)

            val exception = shouldThrow<SentinelCredentialsException> {
                fetcher.fetchCredentials()
            }

            exception.message shouldContain "Empty response"
        }

        test("fetchCredentials throws on connection failure") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.get(any(), any()) } throws RuntimeException("Connection refused")

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)

            val exception = shouldThrow<SentinelCredentialsException> {
                fetcher.fetchCredentials()
            }

            exception.message shouldContain "Connection refused"
            (exception.cause is RuntimeException) shouldBe true
        }
    }

    context("Edge Cases") {

        test("fetchCredentials handles very long JWT tokens") {
            val httpClient = mockk<HttpClient>()

            val longJwt = "eyJ" + "a".repeat(5000) + ".payload.signature"
            val credentials = ProtoSentinelCredentials {
                jwt = longJwt
                seed = "SEED"
            }
            val protoResponse = GetSentinelCredentialsResponse {
                result = GetSentinelCredentialsResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.get(any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val fetcher = SentinelCredentialsFetcher(httpClient, sentinelUrl)
            val result = fetcher.fetchCredentials()

            result.jwt shouldBe longJwt
        }
    }
})
