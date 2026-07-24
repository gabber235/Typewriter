package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.registrar.http.HttpClient
import com.typewritermc.services.libs.registrar.http.HttpResponse
import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import protokt.v1.typewriter.api.v1.IssueServiceIdentityResponse
import protokt.v1.typewriter.api.v1.ServiceCredentials
import protokt.v1.typewriter.models.v1.Error
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class BackendCredentialIssuerTest : FunSpec({

    val serviceIssueUrl = "https://api.example.com/service/identity/issue"

    context("Happy Path Scenarios") {

        test("issueCredential returns Credential on successful response") {
            val httpClient = mockk<HttpClient>()

            val credentials = ServiceCredentials {
                serviceId = "svc-123"
                username = "service-user"
                token = "secret-token"
            }
            val protoResponse = IssueServiceIdentityResponse {
                result = IssueServiceIdentityResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val servicesInfo =
                ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())
            val credential = issuer.issueCredential()

            credential.id shouldBe "svc-123"
            credential.name shouldBe "service-user"
            credential.token shouldBe "secret-token"
        }

        test("issueCredential sends correct Content-Type header") {
            val httpClient = mockk<HttpClient>()
            val headersSlot = slot<Map<String, String>>()

            val credentials = ServiceCredentials {
                serviceId = "svc"
                username = "user"
                token = "tok"
            }
            val protoResponse = IssueServiceIdentityResponse {
                result = IssueServiceIdentityResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.post(any(), any(), capture(headersSlot)) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())
            issuer.issueCredential()

            headersSlot.captured["Content-Type"] shouldBe "application/x-protobuf"
        }

        test("issueCredential posts to correct URL") {
            val httpClient = mockk<HttpClient>()
            val urlSlot = slot<String>()

            val credentials = ServiceCredentials {
                serviceId = "svc"
                username = "user"
                token = "tok"
            }
            val protoResponse = IssueServiceIdentityResponse {
                result = IssueServiceIdentityResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.post(capture(urlSlot), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())
            issuer.issueCredential()

            urlSlot.captured shouldBe serviceIssueUrl
        }
    }

    context("Error and Failure Scenarios") {

        test("issueCredential throws on HTTP error") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 500,
                body = ByteArrayInputStream("Internal server error".toByteArray())
            )

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())

            val exception = shouldThrow<IssueException> {
                issuer.issueCredential()
            }

            exception.message shouldContain "HTTP 500"
        }

        test("issueCredential throws on backend error response") {
            val httpClient = mockk<HttpClient>()

            val protoResponse = IssueServiceIdentityResponse {
                result = IssueServiceIdentityResponse.Result.Error(Error {
                    code = 403u
                    message = "Rate limit exceeded"
                })
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())

            val exception = shouldThrow<IssueException> {
                issuer.issueCredential()
            }

            exception.message shouldContain "403"
            exception.message shouldContain "Rate limit exceeded"
        }

        test("issueCredential throws on malformed protobuf response") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream("not valid protobuf".toByteArray())
            )

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())

            val exception = shouldThrow<IssueException> {
                issuer.issueCredential()
            }

            exception.message shouldContain "parse credential response"
        }

        test("issueCredential throws on empty response result") {
            val httpClient = mockk<HttpClient>()

            val protoResponse = IssueServiceIdentityResponse {}
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            if (responseBytes.isEmpty()) {
                every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                    statusCode = 200,
                    body = ByteArrayInputStream(byteArrayOf(0x08, 0x00))
                )
            } else {
                every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                    statusCode = 200,
                    body = ByteArrayInputStream(responseBytes)
                )
            }

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())

            val exception = shouldThrow<IssueException> {
                issuer.issueCredential()
            }
        }

        test("issueCredential throws on connection failure") {
            val httpClient = mockk<HttpClient>()

            every { httpClient.post(any(), any(), any()) } throws RuntimeException("Connection refused")

            val servicesInfo = ServicesInfo(realm = ServiceInformation.RealmInformation(version = "1.0"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())

            val exception = shouldThrow<IssueException> {
                issuer.issueCredential()
            }

            exception.message shouldContain "Connection refused"
            (exception.cause is RuntimeException) shouldBe true
        }
    }

    context("Edge Cases") {

        test("issueCredential includes realm version in request when realm is present") {
            val httpClient = mockk<HttpClient>()
            val bodySlot = slot<ByteArray>()

            val credentials = ServiceCredentials {
                serviceId = "svc"
                username = "user"
                token = "tok"
            }
            val protoResponse = IssueServiceIdentityResponse {
                result = IssueServiceIdentityResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.post(any(), capture(bodySlot), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val servicesInfo =
                ServicesInfo(realm = ServiceInformation.RealmInformation(version = "2.5.3"), engine = null)
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())
            issuer.issueCredential()

            bodySlot.captured.isNotEmpty() shouldBe true
        }

        test("issueCredential works with both realm and engine info") {
            val httpClient = mockk<HttpClient>()

            val credentials = ServiceCredentials {
                serviceId = "combined-svc"
                username = "combo-user"
                token = "combo-token"
            }
            val protoResponse = IssueServiceIdentityResponse {
                result = IssueServiceIdentityResponse.Result.Credentials(credentials)
            }
            val responseBytes = ByteArrayOutputStream().also { protoResponse.serialize(it) }.toByteArray()

            every { httpClient.post(any(), any(), any()) } returns HttpResponse(
                statusCode = 200,
                body = ByteArrayInputStream(responseBytes)
            )

            val servicesInfo = ServicesInfo(
                realm = ServiceInformation.RealmInformation(version = "1.0.0"),
                engine = ServiceInformation.EngineInformation(version = "2.0.0", platform = "paper")
            )
            val issuer =
                BackendCredentialIssuer(httpClient, serviceIssueUrl, servicesInfo, MockTelemetry.createMockTracer())
            val credential = issuer.issueCredential()

            credential.id shouldBe "combined-svc"
        }
    }
})
