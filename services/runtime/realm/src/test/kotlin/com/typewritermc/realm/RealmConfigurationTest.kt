package com.typewritermc.realm

import com.typewritermc.realm.storage.DatabaseAuthentication
import com.typewritermc.realm.storage.DatabaseEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import java.net.URI

val RealmConfigurationTest by testSuite {
    test("the default configuration opens a versioned embedded SurrealKV database") {
        val endpoint = RealmSettings().databaseConfiguration().endpoint

        endpoint.shouldBeInstanceOf<DatabaseEndpoint.Embedded.SurrealKv>()
        endpoint.connectionString shouldContain "versioned=true"
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

    listOf(
        "REALM_DB_ENDPOINT_TYPE",
        "REALM_DB_ENGINE",
        "REALM_DB_AUTHENTICATION",
    ).forEach { setting ->
        test("an unknown $setting value is rejected naming the setting and the value") {
            shouldThrow<IllegalStateException> {
                settings(setting to "other").databaseConfiguration()
            }.message shouldBe "Realm setting $setting has unknown value: other"
        }
    }

    test("a remote configuration without a URL is rejected naming REALM_DB_URL") {
        shouldThrow<IllegalArgumentException> {
            settings("REALM_DB_ENDPOINT_TYPE" to "remote").databaseConfiguration()
        }.message shouldBe "Realm setting REALM_DB_URL must be configured"
    }

    test("remote credentials without a username are rejected naming REALM_DB_USERNAME") {
        shouldThrow<IllegalArgumentException> {
            settings(
                "REALM_DB_ENDPOINT_TYPE" to "remote",
                "REALM_DB_URL" to "ws://localhost:8235",
                "REALM_DB_AUTHENTICATION" to "database",
            ).databaseConfiguration()
        }.message shouldBe "Realm setting REALM_DB_USERNAME must be configured"
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
