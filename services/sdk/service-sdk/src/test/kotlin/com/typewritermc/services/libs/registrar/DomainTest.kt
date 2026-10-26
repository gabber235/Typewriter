package com.typewritermc.services.libs.registrar

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.net.URI
import kotlin.time.Duration.Companion.seconds

val DomainTest by testSuite {
    test("secret diagnostics are redacted") {
        val identity = ServiceIdentity(ServiceId("service"), "Service", "user", ServiceRole.Host("1"))
        val credentials = IdentityCredentials(identity, RedactedSecret.AppPassword("password"))
        credentials.toString().contains("password") shouldBe false
        RegistrationToken("token").toString().contains("token") shouldBe false
        RedactedSecret.AccessToken("access").toString() shouldBe "[REDACTED]"
    }
    test("registrar causes preserve throwable identity and redact diagnostics") {
        val failure = IllegalStateException("sensitive-token")
        val cause = checkNotNull(RegistrarCause.from(failure))
        val messaging = RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT, cause = cause)

        cause.reveal() shouldBe failure
        cause.toString() shouldBe "[REDACTED]"
        messaging.toString().contains("sensitive-token") shouldBe false
    }
    listOf(
        Rejection("a blank service id", "serviceId must be trimmed and nonblank") { ServiceId(" ") },
        Rejection("an untrimmed service id", "serviceId must be trimmed and nonblank") { ServiceId(" service") },
        Rejection("a blank host version", "version must be trimmed and nonblank") { ServiceRole.Host(" ") },
        Rejection("a custom role name that is no backend identifier", "name must be a backend identifier") {
            ServiceRole.Custom("Bad", "1")
        },
        Rejection("an untrimmed custom role version", "version must be trimmed and nonblank") {
            ServiceRole.Custom("valid_name", " 1")
        },
        Rejection("an identity endpoint with an unsupported scheme", "invalid endpoint URI") {
            configuration(ServiceRole.Host("1"), URI("ftp://example.test"))
        },
        Rejection("a binding refresh that reaches the registration lease", "binding refresh must be below the registration lease") {
            configuration(ServiceRole.Host("1"), bindingSeconds = 150)
        },
    ).forEach { rejection ->
        test("configuration refuses ${rejection.input}") {
            shouldThrow<IllegalArgumentException> { rejection.build() }.message shouldBe rejection.message
        }
    }
}

private fun configuration(
    role: ServiceRole,
    identityUri: URI = URI("https://example.test/issue"),
    bindingSeconds: Int = 120,
) = RegistrarConfiguration(
    identityIssueUri = identityUri,
    sentinelCredentialsUri = URI("https://example.test/sentinel"),
    oauthTokenUri = URI("https://example.test/token"),
    oauthClientId = "client",
    oauthScopes = setOf("openid"),
    natsServerUri = URI("nats://example.test"),
    role = role,
    bindingRefreshInterval = bindingSeconds.seconds,
)

private class Rejection(
    val input: String,
    val message: String,
    val build: () -> Any,
)
