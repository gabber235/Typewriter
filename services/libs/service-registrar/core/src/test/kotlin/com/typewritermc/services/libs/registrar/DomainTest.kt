package com.typewritermc.services.libs.registrar

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.net.URI
import kotlin.time.Duration.Companion.seconds

val DomainTest by testSuite {
    test("secret diagnostics are redacted") {
        val identity = ServiceIdentity("service", "Service", "user", ServiceRole.Host("1"))
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
    test("configuration validates backend role invariants") {
        shouldThrow<IllegalArgumentException> { ServiceRole.Host(" ") }
        shouldThrow<IllegalArgumentException> { ServiceRole.Custom("Bad", "1") }
        shouldThrow<IllegalArgumentException> { ServiceRole.Custom("valid_name", " 1") }
        configuration(ServiceRole.Custom("valid_name", "3")).role shouldBe ServiceRole.Custom("valid_name", "3")
    }
    test("configuration validates endpoints and binding lease") {
        shouldThrow<IllegalArgumentException> { configuration(ServiceRole.Host("1"), URI("ftp://example.test")) }
        shouldThrow<IllegalArgumentException> { configuration(ServiceRole.Host("1"), bindingSeconds = 150) }
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
