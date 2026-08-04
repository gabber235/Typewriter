package com.typewritermc.realm

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
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
