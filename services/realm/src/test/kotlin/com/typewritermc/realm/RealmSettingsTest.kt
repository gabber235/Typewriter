package com.typewritermc.realm

import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.net.URI
import java.nio.file.Path

val RealmSettingsTest by testSuite {
    test("local profile supplies local service settings") {
        val settings = RealmSettings.fromFile(profile("local"))

        settings.get("API_BASE_URL") shouldBe "https://api.tw.seamlezz.net"
        settings.get("AUTH_BASE_URL") shouldBe "https://auth.tw.seamlezz.net"
        settings.get("JWT_CLIENT_ID") shouldBe "typewriter-services"
        settings.get("JWT_SCOPES") shouldBe "openid profile entitlements"
        settings.get("NATS_URL") shouldBe "tls://nats.local.seamlezz.net:4222"
        settings.get("OTEL_EXPORTER_OTLP_ENDPOINT") shouldBe "https://otlp.local.seamlezz.net"
        settings.get("OTEL_TRACES_SAMPLER") shouldBe "always_on"
        settings.get("OTEL_TRACES_SAMPLER_ARG") shouldBe "1.0"
        settings.get("REALM_DB_ENDPOINT_TYPE") shouldBe "embedded"
        settings.get("REALM_DB_ENGINE") shouldBe "surrealkv"
        settings.get("REALM_DB_PATH") shouldBe "database/realm"
        settings.get("REALM_DB_NAMESPACE") shouldBe "typewriter"
        settings.get("REALM_DB_DATABASE") shouldBe "realm"
        settings.get("REALM_DB_AUTHENTICATION") shouldBe "none"
    }

    test("production profile supplies production service settings") {
        val settings = RealmSettings.fromFile(profile("production"))

        settings.get("API_BASE_URL") shouldBe "https://api.typewritermc.com"
        settings.get("AUTH_BASE_URL") shouldBe "https://auth.typewritermc.com"
        settings.get("JWT_CLIENT_ID") shouldBe "typewriter-services"
        settings.get("JWT_SCOPES") shouldBe "openid profile entitlements"
        settings.get("NATS_URL") shouldBe "nats://nats.seamlezz.com:4222"
        settings.get("OTEL_EXPORTER_OTLP_ENDPOINT") shouldBe "https://otlp.seamlezz.com"
        settings.get("OTEL_TRACES_SAMPLER") shouldBe "parentbased_traceidratio"
        settings.get("OTEL_TRACES_SAMPLER_ARG") shouldBe "0.1"
    }

    test("application configuration parses typed slices") {
        val configuration = RealmSettings.fromFile(profile("production")).applicationConfiguration()

        configuration.diagnosticLevel shouldBe RealmDiagnosticLevel.WARN
        configuration.telemetry shouldBe
            RealmTelemetryConfiguration(
                otlpEndpoint = "https://otlp.seamlezz.com",
                sampler = RealmSamplerConfiguration.ParentBasedTraceIdRatio(0.1),
            )
        configuration.registrar.identityIssueUri shouldBe URI("https://api.typewritermc.com/service/identity/issue")
        configuration.registrar.sentinelCredentialsUri shouldBe URI("https://api.typewritermc.com/auth/sentinel")
        configuration.registrar.oauthTokenUri shouldBe URI("https://auth.typewritermc.com/application/o/token/")
        configuration.registrar.oauthClientId shouldBe "typewriter-services"
        configuration.registrar.oauthScopes shouldBe setOf("openid", "profile", "entitlements")
        configuration.registrar.natsServerUri shouldBe URI("nats://nats.seamlezz.com:4222")
        configuration.registrar.roles shouldBe listOf(ServiceRole.Realm(REALM_VERSION))
    }

    test("telemetry sampler preserves fallback and ratio bounds") {
        RealmSettings(
            configuration =
                mapOf(
                    "OTEL_TRACES_SAMPLER" to "traceidratio",
                    "OTEL_TRACES_SAMPLER_ARG" to "2.0",
                ),
        ).applicationConfiguration().telemetry.sampler shouldBe RealmSamplerConfiguration.TraceIdRatio(1.0)

        RealmSettings(
            configuration = mapOf("OTEL_TRACES_SAMPLER" to "unsupported"),
        ).applicationConfiguration().telemetry.sampler shouldBe RealmSamplerConfiguration.AlwaysOn
    }

    test("process settings override the selected profile") {
        val settings =
            RealmSettings(
                systemProperties = mapOf("API_BASE_URL" to "https://system.example.test"),
                environment = mapOf("AUTH_BASE_URL" to "https://environment.example.test"),
                configuration =
                    mapOf(
                        "API_BASE_URL" to "https://profile.example.test",
                        "AUTH_BASE_URL" to "https://profile.example.test",
                        "NATS_URL" to "nats://profile.example.test:4222",
                    ),
            )

        settings.get("API_BASE_URL") shouldBe "https://system.example.test"
        settings.get("AUTH_BASE_URL") shouldBe "https://environment.example.test"
        settings.get("NATS_URL") shouldBe "nats://profile.example.test:4222"
    }

    test("blank process settings fall back to the selected profile") {
        val settings =
            RealmSettings(
                systemProperties = mapOf("API_BASE_URL" to " "),
                environment = mapOf("API_BASE_URL" to ""),
                configuration = mapOf("API_BASE_URL" to "https://profile.example.test"),
            )

        settings.get("API_BASE_URL") shouldBe "https://profile.example.test"
    }
}

private fun profile(name: String): Path = Path.of("config", "$name.properties")
