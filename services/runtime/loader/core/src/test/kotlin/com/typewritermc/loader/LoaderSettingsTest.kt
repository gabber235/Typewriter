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

    test("production profile supplies registration and NATS settings") {
        val configuration = LoaderSettings.fromFile(profile("production")).registrarConfiguration()

        configuration.identityIssueUri shouldBe URI("https://api.typewritermc.com/service/identity/issue")
        configuration.oauthTokenUri shouldBe URI("https://auth.typewritermc.com/application/o/token/")
        configuration.natsServerUri shouldBe URI("nats://nats.seamlezz.com:4222")
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

    listOf(
        Triple("a configured sampler ratio is honoured", "0.25", 0.25),
        Triple("an unparsable sampler ratio samples everything", "abc", 1.0),
        Triple("a sampler ratio above one clamps to one", "2.0", 1.0),
    ).forEach { (name, configured, ratio) ->
        test(name) {
            LoaderSettings(
                configuration =
                    mapOf(
                        "OTEL_TRACES_SAMPLER" to "traceidratio",
                        "OTEL_TRACES_SAMPLER_ARG" to configured,
                    ),
            ).telemetryConfiguration().sampler shouldBe LoaderSamplerConfiguration.TraceIdRatio(ratio)
        }
    }

    test("an unsupported sampler falls back to always on") {
        LoaderSettings(
            configuration = mapOf("OTEL_TRACES_SAMPLER" to "unsupported"),
        ).telemetryConfiguration().sampler shouldBe LoaderSamplerConfiguration.AlwaysOn
    }
}

private fun profile(name: String): Path = Path.of("..", "..", "config", "$name.properties")
