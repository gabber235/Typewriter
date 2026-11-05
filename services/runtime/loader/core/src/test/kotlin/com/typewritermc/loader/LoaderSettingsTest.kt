package com.typewritermc.loader

import com.typewritermc.loader.testing.shippedProfiles
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import java.net.URI

val LoaderSettingsTest by testSuite {
    val requiredProfileSettings = listOf("API_BASE_URL", "AUTH_BASE_URL", "NATS_URL", "OTEL_EXPORTER_OTLP_ENDPOINT")

    shippedProfiles().forEach { profile ->
        test("the shipped ${profile.fileName} profile names its own backend, broker and telemetry endpoint") {
            val settings = LoaderSettings.fromFile(profile)
            val configuration = settings.registrarConfiguration()

            // A shipped profile must never fall back to the production defaults for a value it leaves out.
            requiredProfileSettings.forEach { name -> settings.getOrNull(name).shouldNotBeNull() }
            configuration.identityIssueUri.host shouldBe URI(settings.get("API_BASE_URL", "")).host
            configuration.oauthTokenUri.host shouldBe URI(settings.get("AUTH_BASE_URL", "")).host
            configuration.natsServerUri shouldBe URI(settings.get("NATS_URL", ""))
            settings.telemetryConfiguration().otlpEndpoint.shouldNotBeNull()
        }
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
