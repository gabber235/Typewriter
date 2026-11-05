package com.typewritermc.realm

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties
import kotlin.io.path.extension
import kotlin.io.path.name
import kotlin.io.path.nameWithoutExtension

val RealmSettingsTest by testSuite {
    val databaseSecrets = listOf("REALM_DB_USERNAME", "REALM_DB_PASSWORD", "REALM_DB_TOKEN")

    test("no shipped profile contains database secrets") {
        val leaks =
            shippedProfiles().flatMap { profile ->
                val settings = RealmSettings.fromFile(profile)
                databaseSecrets.filter { settings.get(it) != null }.map { "${profile.name}: $it" }
            }

        leaks.shouldBeEmpty()
    }

    test("every shipped profile parses into a database configuration once the process supplies its secrets") {
        val failures =
            shippedProfiles().mapNotNull { profile ->
                val settings =
                    RealmSettings(
                        environment = databaseSecrets.associateWith { "supplied" },
                        configuration = readConfiguration(profile),
                    )
                runCatching { settings.databaseConfiguration() }
                    .exceptionOrNull()
                    ?.let { "${profile.nameWithoutExtension}: ${it.message}" }
            }

        failures.shouldBeEmpty()
    }

    test("the diagnostic level setting parses regardless of case") {
        RealmSettings(configuration = mapOf("TYPEWRITER_DIAGNOSTIC_LEVEL" to "error"))
            .applicationConfiguration()
            .diagnosticLevel shouldBe RealmDiagnosticLevel.ERROR
    }

    test("an unknown diagnostic level fails startup naming the setting and the value") {
        shouldThrow<IllegalStateException> {
            RealmSettings(configuration = mapOf("TYPEWRITER_DIAGNOSTIC_LEVEL" to "verbose")).applicationConfiguration()
        }.message shouldBe "Realm setting TYPEWRITER_DIAGNOSTIC_LEVEL has unknown value: verbose"
    }

    test("an absent diagnostic level means WARN") {
        RealmSettings()
            .applicationConfiguration()
            .diagnosticLevel shouldBe RealmDiagnosticLevel.WARN
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
