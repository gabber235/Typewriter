package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.http.core.HttpHeaders
import com.typewritermc.services.libs.http.core.HttpResponse
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.http.core.ServiceHttpClient
import com.typewritermc.services.libs.http.testing.FakeHttpTransport
import com.typewritermc.services.libs.registrar.AccessTokenFailureReason
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.IdentityIssueError
import com.typewritermc.services.libs.registrar.IdentityIssueResult
import com.typewritermc.services.libs.registrar.IdentityRejectionReason
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.SentinelFailureReason
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import skirout.access.v1.sentinel.GetSentinelCredentialsResponse
import skirout.service.v1.identity.IssueServiceIdentityRequest
import skirout.service.v1.identity.IssueServiceIdentityResponse
import skirout.service.v1.service.ServiceRole as SkirRole
import java.net.URI

private val httpCredentials = IdentityCredentials(
    ServiceIdentity("service-id", "Service Name", "service-user", listOf(ServiceRole.Realm("1.0"))),
    RedactedSecret.AppPassword("app-password"),
)

private val mediaHeaders = HttpHeaders.of(
    "Content-Type" to "application/octet-stream",
    "X-Typewriter-Format" to "skir-binary",
)

private fun httpResponse(status: Int, body: ByteArray, headers: HttpHeaders = mediaHeaders) =
    HttpResult.Success(HttpResponse(status, headers, body))

private data class HttpFixture(
    val transport: FakeHttpTransport,
    val harness: TelemetryTestHarness,
    val client: ServiceHttpClient,
) : AutoCloseable {
    override fun close() = harness.close()
}

private fun httpFixture(vararg outcomes: HttpResult): HttpFixture {
    val transport = FakeHttpTransport(outcomes.map { result -> suspend { _: com.typewritermc.services.libs.http.core.HttpRequest -> result } })
    val harness = TelemetryTestHarness.create()
    return HttpFixture(transport, harness, ServiceHttpClient(transport, harness.telemetry, harness.openTelemetry.propagators))
}

val HttpAdaptersTest by testSuite {
    test("identity issuer sends canonical roles headers and maps success") {
        val response = IssueServiceIdentityResponse.createSuccess(
            serviceId = "service-id",
            displayName = "Service Name",
            username = "service-user",
            token = "private-token",
        )
        val fixture = httpFixture(httpResponse(200, IssueServiceIdentityResponse.serializer.toBytes(response).toByteArray()))
        try {
            val roles = listOf(
                ServiceRole.Engine("1.0"),
                ServiceRole.Realm("2.0"),
                ServiceRole.Custom("custom_role", "3.0"),
            )
            val result = TypewriterIdentityIssuer(fixture.client, URI("https://api.example.test/service/identity/issue"))
                .issue(roles) as IdentityIssueResult.Success
            result.credentials.identity.serviceId shouldBe "service-id"
            result.credentials.revealAppPassword() shouldBe "private-token"
            val action = fixture.transport.actions.single()
            action.headers.first("Content-Type") shouldBe "application/octet-stream"
            action.headers.first("X-Typewriter-Format") shouldBe "skir-binary"
            val request = IssueServiceIdentityRequest.serializer.fromBytes(action.body.toByteArray())
            request.roles.map { it.kind }.shouldContainExactly(
                SkirRole.Kind.ENGINE_WRAPPER,
                SkirRole.Kind.REALM_WRAPPER,
                SkirRole.Kind.CUSTOM_WRAPPER,
            )
        } finally {
            fixture.close()
        }
    }

    test("identity issuer decodes typed provider unavailable at 503") {
        val response = IssueServiceIdentityResponse.createIdentityProviderUnavailableError()
        val fixture = httpFixture(httpResponse(503, IssueServiceIdentityResponse.serializer.toBytes(response).toByteArray()))
        try {
            val result = TypewriterIdentityIssuer(fixture.client, URI("https://api.example.test/issue"))
                .issue(listOf(ServiceRole.Realm("1.0"))) as IdentityIssueResult.Failure
            result.error shouldBe IdentityIssueError.Unavailable(false)
        } finally {
            fixture.close()
        }
    }

    test("identity issuer maps typed rejection and wrong media") {
        val rejection = IssueServiceIdentityResponse.createUnknownRoleError()
        val fixture = httpFixture(
            httpResponse(400, IssueServiceIdentityResponse.serializer.toBytes(rejection).toByteArray()),
            httpResponse(200, byteArrayOf(1), HttpHeaders.of("Content-Type" to "text/plain")),
        )
        try {
            val issuer = TypewriterIdentityIssuer(fixture.client, URI("https://api.example.test/issue"))
            (issuer.issue(listOf(ServiceRole.Realm("1.0"))) as IdentityIssueResult.Failure).error shouldBe
                IdentityIssueError.Rejected(IdentityRejectionReason.UNKNOWN_ROLE)
            val protocol = issuer.issue(listOf(ServiceRole.Realm("1.0"))) as IdentityIssueResult.Failure
            protocol.error shouldBe IdentityIssueError.Protocol("unexpected_media_type", true)
        } finally {
            fixture.close()
        }
    }

    test("oauth exchanger sends exact encoded form and parses bearer token") {
        val fixture = httpFixture(
            httpResponse(
                200,
                """{"access_token":"access-token","expires_in":3600,"token_type":"Bearer","extra":true}"""
                    .encodeToByteArray(),
                HttpHeaders.of("Content-Type" to "application/json"),
            )
        )
        try {
            val result = AuthentikTokenExchanger(
                fixture.client,
                URI("https://auth.example.test/application/o/token/"),
                "typewriter-services",
                setOf("profile", "openid"),
            ).exchange(httpCredentials) as AccessTokenResult.Success
            result.token.reveal() shouldBe "access-token"
            result.expiresInSeconds shouldBe 3600
            fixture.transport.actions.single().body.toByteArray().decodeToString() shouldBe
                "grant_type=client_credentials&client_id=typewriter-services&username=service-user&password=app-password&scope=openid%20profile"
        } finally {
            fixture.close()
        }
    }

    test("oauth rejects malformed token type and distinguishes statuses") {
        val fixture = httpFixture(
            httpResponse(200, """{"access_token":"token","expires_in":1,"token_type":"MAC"}""".encodeToByteArray()),
            httpResponse(401, byteArrayOf()),
            httpResponse(503, byteArrayOf()),
        )
        try {
            val exchanger = AuthentikTokenExchanger(
                fixture.client,
                URI("https://auth.example.test/token"),
                "client",
                setOf("openid"),
            )
            (exchanger.exchange(httpCredentials) as AccessTokenResult.Failure).failure.reason shouldBe
                AccessTokenFailureReason.PROTOCOL
            (exchanger.exchange(httpCredentials) as AccessTokenResult.Failure).failure.reason shouldBe
                AccessTokenFailureReason.REJECTED
            (exchanger.exchange(httpCredentials) as AccessTokenResult.Failure).failure.reason shouldBe
                AccessTokenFailureReason.UNAVAILABLE
        } finally {
            fixture.close()
        }
    }

    test("sentinel provider decodes canonical response") {
        val response = GetSentinelCredentialsResponse.createSuccess(jwt = "sentinel-jwt", seed = "sentinel-seed")
        val fixture = httpFixture(
            httpResponse(200, GetSentinelCredentialsResponse.serializer.toBytes(response).toByteArray())
        )
        try {
            val result = TypewriterSentinelProvider(fixture.client, URI("https://api.example.test/auth/sentinel"))
                .fetch() as SentinelResult.Success
            result.credentials.jwt.reveal() shouldBe "sentinel-jwt"
            result.credentials.seed.reveal() shouldBe "sentinel-seed"
        } finally {
            fixture.close()
        }
    }

    test("sentinel internal error is recoverable and wrong media is protocol") {
        val internal = GetSentinelCredentialsResponse.createInternalError()
        val fixture = httpFixture(
            httpResponse(500, GetSentinelCredentialsResponse.serializer.toBytes(internal).toByteArray()),
            httpResponse(200, byteArrayOf(), HttpHeaders.of("Content-Type" to "text/plain")),
        )
        try {
            val provider = TypewriterSentinelProvider(fixture.client, URI("https://api.example.test/auth/sentinel"))
            (provider.fetch() as SentinelResult.Failure).failure.reason shouldBe SentinelFailureReason.UNAVAILABLE
            (provider.fetch() as SentinelResult.Failure).failure.reason shouldBe SentinelFailureReason.PROTOCOL
        } finally {
            fixture.close()
        }
    }

    test("secret wrappers never disclose adapter credentials") {
        val secrets = listOf(
            RedactedSecret.AccessToken("access-token"),
            SentinelCredentials(
                RedactedSecret.SentinelJwt("sentinel-jwt"),
                RedactedSecret.SentinelSeed("sentinel-seed"),
            ),
        ).joinToString()
        secrets.contains("access-token") shouldBe false
        secrets.contains("sentinel-jwt") shouldBe false
        secrets.contains("sentinel-seed") shouldBe false
    }
}
