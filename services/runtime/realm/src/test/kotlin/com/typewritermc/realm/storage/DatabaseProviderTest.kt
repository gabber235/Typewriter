package com.typewritermc.realm.storage

import com.surrealdb.NotAllowedException
import com.surrealdb.Surreal
import com.surrealdb.signin.RootCredential
import com.typewritermc.realm.SURREALDB_EMBEDDED_VERSION
import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.net.URI
import java.nio.file.Files

val DatabaseProviderTest by testSuite {
    testSuite("database version") {
        test("exact configured versions are accepted") {
            requireSupportedDatabaseVersion(SURREALDB_SERVER_VERSION, SURREALDB_SERVER_VERSION)
            requireSupportedDatabaseVersion("surrealdb-$SURREALDB_EMBEDDED_VERSION", SURREALDB_EMBEDDED_VERSION)
            requireSupportedDatabaseVersion(
                "$SURREALDB_SERVER_VERSION+20260721.40522d1",
                SURREALDB_SERVER_VERSION,
            )
        }

        test("different database version is rejected") {
            val error =
                shouldThrow<UnsupportedDatabaseVersionException> {
                    requireSupportedDatabaseVersion("3.1.5", "3.2.3")
                }

            error.message shouldBe "Realm requires SurrealDB 3.2.3 but connected to 3.1.5"
        }
    }

    test("unavailable embedded engine is rejected") {
        val error =
            shouldThrow<UnsupportedDatabaseEngineException> {
                requireSupportedEmbeddedEngine(
                    DatabaseEndpoint.Embedded.RocksDb(
                        java.nio.file.Path
                            .of("database"),
                    ),
                )
            }

        error.message shouldBe "RocksDB is not available in the configured SurrealDB Java SDK"
    }

    test("versioned embedded engine matches the configured version") {
        Surreal().use { database ->
            database.connect(DatabaseEndpoint.Embedded.Memory().connectionString)
            database.version() shouldBe SURREALDB_EMBEDDED_VERSION
        }
    }

    test("root credentials sign the connection in as the configured user") {
        signInDatabase().use { database ->
            database.authenticate(remoteConfiguration(DatabaseAuthentication.Root("realm_root", "secret")))

            database.signedInUser() shouldBe "realm_root"
        }
    }

    test("wrong root credentials are refused by the database") {
        signInDatabase().use { database ->
            shouldThrow<NotAllowedException> {
                database.authenticate(remoteConfiguration(DatabaseAuthentication.Root("realm_root", "wrong")))
            }
            database.signedInUser() shouldBe null
        }
    }

    test("a bearer token signs the connection in as the user it was issued to") {
        signInDatabase().use { database ->
            val token = database.signin(RootCredential("realm_root", "secret")).access
            database.invalidate()

            database.authenticate(remoteConfiguration(DatabaseAuthentication.Bearer(token)))

            database.signedInUser() shouldBe "realm_root"
        }
    }

    test("versioned SurrealKV reopens after the previous native handle closes") {
        val directory = Files.createTempDirectory("realm_surrealkv_reopen")
        val telemetry = TelemetryTestHarness.create()
        val provider =
            DatabaseProvider(
                RealmDatabaseConfiguration(
                    endpoint = DatabaseEndpoint.Embedded.SurrealKv(directory),
                    authentication = DatabaseAuthentication.None,
                    namespace = "reopen",
                    database = "reopen",
                    expectedVersion = SURREALDB_EMBEDDED_VERSION,
                ),
            )

        fun connect() =
            telemetry.telemetry.mainSpanBlocking(
                name = "test.realm.database.reopen",
                unhandledFailureSlug = ErrorSlug.of("test-realm-database-reopen-failed"),
            ) {
                provider.connect()
            }

        try {
            val first = connect()
            first.query("UPSERT probe:state SET value = 'preserved';")
            provider.close(first)

            val reopened = connect()
            try {
                reopened.query("SELECT VALUE value FROM ONLY probe:state;").take(0).getString() shouldBe "preserved"
            } finally {
                provider.close(reopened)
            }
        } finally {
            telemetry.close()
            directory.toFile().deleteRecursively()
        }
    }
}

/** An embedded database with one root user, standing in for a remote server that checks credentials. */
private fun signInDatabase(): Surreal =
    Surreal().apply {
        connect(DatabaseEndpoint.Embedded.Memory().connectionString)
        useNs("sign_in").useDb("sign_in")
        query("DEFINE USER realm_root ON ROOT PASSWORD 'secret' ROLES OWNER;").take(0)
    }

private fun remoteConfiguration(authentication: DatabaseAuthentication) =
    RealmDatabaseConfiguration(
        endpoint = DatabaseEndpoint.Remote(URI("wss://database.example.com")),
        authentication = authentication,
        namespace = "sign_in",
        database = "sign_in",
        expectedVersion = SURREALDB_SERVER_VERSION,
    )

private fun Surreal.signedInUser(): String? = query("RETURN \$token.ID;").take(0).takeUnless { it.isNone || it.isNull }?.getString()
