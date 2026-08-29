package com.typewritermc.realm

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.nio.file.Path

val RealmSettingsTest by testSuite {
    test("local profile supplies Realm settings") {
        val settings = RealmSettings.fromFile(profile("local"))

        settings.get("REALM_DB_ENDPOINT_TYPE") shouldBe "embedded"
        settings.get("REALM_DB_ENGINE") shouldBe "surrealkv"
        settings.get("REALM_DB_PATH") shouldBe "database/realm"
        settings.get("REALM_DB_NAMESPACE") shouldBe "typewriter"
        settings.get("REALM_DB_DATABASE") shouldBe "realm"
        settings.get("REALM_DB_AUTHENTICATION") shouldBe "none"
    }

    test("application configuration parses typed slices") {
        val configuration = RealmSettings.fromFile(profile("local")).applicationConfiguration()

        configuration.diagnosticLevel shouldBe RealmDiagnosticLevel.WARN
    }

    test("process settings override the selected profile") {
        val settings =
            RealmSettings(
                systemProperties = mapOf("REALM_DB_NAMESPACE" to "system"),
                environment = mapOf("REALM_DB_DATABASE" to "environment"),
                configuration =
                    mapOf(
                        "REALM_DB_NAMESPACE" to "profile",
                        "REALM_DB_DATABASE" to "profile",
                    ),
            )

        settings.get("REALM_DB_NAMESPACE") shouldBe "system"
        settings.get("REALM_DB_DATABASE") shouldBe "environment"
    }

    test("blank process settings fall back to the selected profile") {
        val settings =
            RealmSettings(
                systemProperties = mapOf("REALM_DB_NAMESPACE" to " "),
                environment = mapOf("REALM_DB_NAMESPACE" to ""),
                configuration = mapOf("REALM_DB_NAMESPACE" to "profile"),
            )

        settings.get("REALM_DB_NAMESPACE") shouldBe "profile"
    }
}

private fun profile(name: String): Path = Path.of("config", "$name.properties")
