package com.typewritermc.services.libs.registrar

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.net.URI
import kotlin.time.Duration.Companion.seconds

val DomainTest by testSuite {
    test("secret diagnostics are redacted") {
        val identity = ServiceIdentity("service", "Service", "user", listOf(ServiceRole.Engine("1")))
        val credentials = IdentityCredentials(identity, RedactedSecret.AppPassword("password"))
        credentials.toString().contains("password") shouldBe false
        RegistrationToken("token").toString().contains("token") shouldBe false
        RedactedSecret.AccessToken("access").toString() shouldBe "[REDACTED]"
    }
    test("configuration validates backend role invariants") {
        shouldThrow<IllegalArgumentException> { configuration(emptyList()) }
        shouldThrow<IllegalArgumentException> { configuration(listOf(ServiceRole.Engine("1"), ServiceRole.Engine("2"))) }
        shouldThrow<IllegalArgumentException> { configuration(listOf(ServiceRole.Custom("Bad", "1"))) }
        shouldThrow<IllegalArgumentException> { configuration(listOf(ServiceRole.Custom("valid_name", " 1"))) }
        configuration(listOf(ServiceRole.Engine("1"), ServiceRole.Realm("2"), ServiceRole.Custom("valid_name", "3"))).roles.size shouldBe 3
    }
    test("configuration validates endpoints and binding lease") {
        shouldThrow<IllegalArgumentException> { configuration(listOf(ServiceRole.Engine("1")), URI("ftp://example.test")) }
        shouldThrow<IllegalArgumentException> { configuration(listOf(ServiceRole.Engine("1")), bindingSeconds = 150) }
    }
}

private fun configuration(roles: List<ServiceRole>, identityUri: URI = URI("https://example.test/issue"), bindingSeconds: Int = 120) = RegistrarConfiguration(
    identityIssueUri = identityUri,
    sentinelCredentialsUri = URI("https://example.test/sentinel"),
    oauthTokenUri = URI("https://example.test/token"),
    oauthClientId = "client",
    oauthScopes = setOf("openid"),
    natsServerUri = URI("nats://example.test"),
    roles = roles,
    bindingRefreshInterval = bindingSeconds.seconds,
)
