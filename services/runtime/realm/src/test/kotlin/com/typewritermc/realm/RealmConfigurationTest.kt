package com.typewritermc.realm

import com.typewritermc.realm.storage.DatabaseAuthentication
import com.typewritermc.realm.storage.DatabaseEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import java.net.URI
import java.nio.file.Path

val RealmConfigurationTest by testSuite {
    test("default configuration uses versioned SurrealKV") {
        val configuration = RealmSettings().databaseConfiguration()

        configuration.endpoint shouldBe DatabaseEndpoint.Embedded.SurrealKv(Path.of("database/realm"))
        configuration.endpoint.connectionString shouldBe "surrealkv://database/realm?versioned=true"
        configuration.authentication shouldBe DatabaseAuthentication.None
        configuration.namespace shouldBe "typewriter"
        configuration.database shouldBe "realm"
        configuration.expectedVersion shouldBe SURREALDB_EMBEDDED_VERSION
    }

    test("remote configuration supports database credentials") {
        val configuration =
            settings(
                "REALM_DB_ENDPOINT_TYPE" to "remote",
                "REALM_DB_URL" to "wss://database.example.com",
                "REALM_DB_AUTHENTICATION" to "database",
                "REALM_DB_USERNAME" to "realm",
                "REALM_DB_PASSWORD" to "secret",
            ).databaseConfiguration()

        configuration.endpoint shouldBe DatabaseEndpoint.Remote(URI("wss://database.example.com"))
        configuration.authentication shouldBe DatabaseAuthentication.Database("realm", "secret")
        configuration.expectedVersion shouldBe SURREALDB_SERVER_VERSION
    }

    test("remote configuration supports namespace credentials") {
        val configuration =
            settings(
                "REALM_DB_ENDPOINT_TYPE" to "remote",
                "REALM_DB_URL" to "https://database.example.com",
                "REALM_DB_AUTHENTICATION" to "namespace",
                "REALM_DB_USERNAME" to "realm",
                "REALM_DB_PASSWORD" to "secret",
            ).databaseConfiguration()

        configuration.authentication shouldBe DatabaseAuthentication.Namespace("realm", "secret")
    }

    test("remote configuration supports root and bearer credentials") {
        settings(
            "REALM_DB_ENDPOINT_TYPE" to "remote",
            "REALM_DB_URL" to "ws://localhost:8235",
            "REALM_DB_AUTHENTICATION" to "root",
            "REALM_DB_USERNAME" to "root",
            "REALM_DB_PASSWORD" to "secret",
        ).databaseConfiguration().authentication shouldBe DatabaseAuthentication.Root("root", "secret")

        settings(
            "REALM_DB_ENDPOINT_TYPE" to "remote",
            "REALM_DB_URL" to "ws://localhost:8235",
            "REALM_DB_AUTHENTICATION" to "bearer",
            "REALM_DB_TOKEN" to "token",
        ).databaseConfiguration().authentication shouldBe DatabaseAuthentication.Bearer("token")
    }

    test("invalid endpoint and authentication types are rejected") {
        shouldThrow<IllegalStateException> {
            settings("REALM_DB_ENDPOINT_TYPE" to "other").databaseConfiguration()
        }
        shouldThrow<IllegalStateException> {
            settings("REALM_DB_ENGINE" to "other").databaseConfiguration()
        }
        shouldThrow<IllegalStateException> {
            settings("REALM_DB_AUTHENTICATION" to "other").databaseConfiguration()
        }
    }

    test("remote URL and credentials are required when selected") {
        shouldThrow<IllegalArgumentException> {
            settings("REALM_DB_ENDPOINT_TYPE" to "remote").databaseConfiguration()
        }
        shouldThrow<IllegalArgumentException> {
            settings(
                "REALM_DB_ENDPOINT_TYPE" to "remote",
                "REALM_DB_URL" to "ws://localhost:8235",
                "REALM_DB_AUTHENTICATION" to "database",
            ).databaseConfiguration()
        }
    }

    test("configuration variants retain their concrete types") {
        settings("REALM_DB_ENGINE" to "memory")
            .databaseConfiguration()
            .endpoint
            .shouldBeInstanceOf<DatabaseEndpoint.Embedded.Memory>()
        settings("REALM_DB_ENGINE" to "rocksdb")
            .databaseConfiguration()
            .endpoint
            .shouldBeInstanceOf<DatabaseEndpoint.Embedded.RocksDb>()
    }
}

private fun settings(vararg values: Pair<String, String>): RealmSettings = RealmSettings(configuration = mapOf(*values))
