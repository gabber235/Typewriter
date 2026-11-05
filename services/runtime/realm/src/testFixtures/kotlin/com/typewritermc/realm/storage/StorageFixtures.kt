package com.typewritermc.realm.storage

import com.surrealdb.NotAllowedException
import com.surrealdb.Surreal
import com.surrealdb.signin.RootCredential
import com.typewritermc.realm.SURREALDB_EMBEDDED_VERSION
import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.SluggedException
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import java.net.URI
import java.nio.file.Files

/** An embedded database with one root user, standing in for a remote server that checks credentials. */
internal fun signInDatabase(): Surreal =
    Surreal().apply {
        connect(DatabaseEndpoint.Embedded.Memory().connectionString)
        useNs("sign_in").useDb("sign_in")
        query("DEFINE USER realm_root ON ROOT PASSWORD 'secret' ROLES OWNER;").take(0)
    }

internal fun remoteConfiguration(authentication: DatabaseAuthentication) =
    RealmDatabaseConfiguration(
        endpoint = DatabaseEndpoint.Remote(URI("wss://database.example.com")),
        authentication = authentication,
        namespace = "sign_in",
        database = "sign_in",
        expectedVersion = SURREALDB_SERVER_VERSION,
    )

internal fun Surreal.signedInUser(): String? = query("RETURN \$token.ID;").take(0).takeUnless { it.isNone || it.isNull }?.getString()

/** Runs a migration expected to fail startup as a patch run failure and returns the underlying cause. */
internal fun patchRunFailure(block: () -> Unit): Throwable {
    val failure = shouldThrow<SluggedException>(block)
    failure.slug shouldBe ErrorSlug.of("realm-patch-run-failed")
    return requireNotNull(failure.cause)
}

internal class SchemaFixture : AutoCloseable {
    val database =
        Surreal().apply {
            connect("memory")
            useNs("test").useDb("test")
        }
    val telemetry = TelemetryTestHarness.create()

    fun resources(vararg patches: Pair<String, String>): MigrationResources {
        val patchFiles = patches.map { (id, _) -> "$id.surql" }
        val content =
            buildMap {
                put("schema/migration.surql", TEST_MIGRATION_SCHEMA)
                put("schema/realm/_index.txt", "realm_probe.surql")
                put("schema/realm/realm_probe.surql", TEST_REALM_SCHEMA)
                put("schema/patches/_index.txt", patchFiles.joinToString("\n"))
                patches.forEach { (id, script) -> put("schema/patches/$id.surql", script) }
            }
        return MigrationResources(content::get)
    }

    fun migrate(resources: MigrationResources) {
        telemetry.telemetry.mainSpanBlocking(
            name = "test.realm.start",
            unhandledFailureSlug = ErrorSlug.of("test-realm-start-failed"),
        ) {
            SchemaMigrator(database, resources).migrate()
        }
    }

    override fun close() {
        try {
            database.close()
        } finally {
            telemetry.close()
        }
    }
}

internal const val TEST_MIGRATION_SCHEMA = """
    DEFINE TABLE OVERWRITE _patch SCHEMAFULL TYPE NORMAL;
    DEFINE FIELD OVERWRITE checksum ON _patch TYPE string;
    DEFINE FIELD OVERWRITE applied_at ON _patch TYPE datetime DEFAULT time::now();
"""

internal const val TEST_REALM_SCHEMA = "DEFINE TABLE OVERWRITE realm_probe SCHEMAFULL TYPE NORMAL;"
