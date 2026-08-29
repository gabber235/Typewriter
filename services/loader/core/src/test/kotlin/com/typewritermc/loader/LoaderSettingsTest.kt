package com.typewritermc.loader

import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.net.URI
import java.nio.file.Path

val LoaderSettingsTest by testSuite {
    test("local profile supplies registration and NATS settings") {
        val configuration = LoaderSettings.fromFile(profile("local")).registrarConfiguration()

        configuration.identityIssueUri shouldBe URI("https://api.tw.seamlezz.net/service/identity/issue")
        configuration.sentinelCredentialsUri shouldBe URI("https://api.tw.seamlezz.net/auth/sentinel")
        configuration.oauthTokenUri shouldBe URI("https://auth.tw.seamlezz.net/application/o/token/")
        configuration.oauthClientId shouldBe "typewriter-services"
        configuration.oauthScopes shouldBe setOf("openid", "profile", "entitlements")
        configuration.natsServerUri shouldBe URI("tls://nats.local.seamlezz.net:4222")
        configuration.role shouldBe ServiceRole.Host(LOADER_VERSION)
        LoaderSettings.fromFile(profile("local")).telemetryConfiguration() shouldBe
            LoaderTelemetryConfiguration(
                "https://otlp.local.seamlezz.net",
                LoaderSamplerConfiguration.AlwaysOn,
            )
    }

    test("process settings override the loader profile") {
        val settings =
            LoaderSettings(
                properties = mapOf("API_BASE_URL" to "https://system.example.test"),
                environment = mapOf("AUTH_BASE_URL" to "https://environment.example.test"),
                configuration = mapOf("NATS_URL" to "nats://profile.example.test:4222"),
            )
        val configuration = settings.registrarConfiguration()

        configuration.identityIssueUri shouldBe URI("https://system.example.test/service/identity/issue")
        configuration.oauthTokenUri shouldBe URI("https://environment.example.test/application/o/token/")
        configuration.natsServerUri shouldBe URI("nats://profile.example.test:4222")
    }

    test("telemetry sampler preserves fallback and ratio bounds") {
        LoaderSettings(
            configuration =
                mapOf(
                    "OTEL_TRACES_SAMPLER" to "traceidratio",
                    "OTEL_TRACES_SAMPLER_ARG" to "2.0",
                ),
        ).telemetryConfiguration().sampler shouldBe LoaderSamplerConfiguration.TraceIdRatio(1.0)

        LoaderSettings(
            configuration = mapOf("OTEL_TRACES_SAMPLER" to "unsupported"),
        ).telemetryConfiguration().sampler shouldBe LoaderSamplerConfiguration.AlwaysOn
    }
}

private fun profile(name: String): Path = Path.of("..", "standalone", "config", "$name.properties")
