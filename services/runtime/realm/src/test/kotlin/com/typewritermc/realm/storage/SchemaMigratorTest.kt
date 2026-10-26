package com.typewritermc.realm.storage

import com.surrealdb.Surreal
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.SluggedException
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

private const val TEST_MIGRATION_SCHEMA = """
    DEFINE TABLE OVERWRITE _patch SCHEMAFULL TYPE NORMAL;
    DEFINE FIELD OVERWRITE checksum ON _patch TYPE string;
    DEFINE FIELD OVERWRITE applied_at ON _patch TYPE datetime DEFAULT time::now();
"""

private const val TEST_REALM_SCHEMA = "DEFINE TABLE OVERWRITE realm_probe SCHEMAFULL TYPE NORMAL;"

val SchemaMigratorTest by testSuite {
    test("migration applies every patch once and records its checksum") {
        SchemaFixture().use { fixture ->
            val resources =
                fixture.resources(
                    "0001_create_probe" to "CREATE patch_probe CONTENT { value: true };",
                )

            fixture.migrate(resources)
            fixture.migrate(resources)

            fixture.database
                .query("SELECT * FROM patch_probe")
                .take(0)
                .getArray()
                .len() shouldBe 1
            val history =
                fixture.database
                    .query("SELECT checksum FROM _patch")
                    .take(0)
                    .getArray()
            history.len() shouldBe 1
            history
                .get(0)
                .getObject()
                .get("checksum")
                .getString()
                .length shouldBe 64
        }
    }

    test("migration rejects a modified patch before running it again") {
        SchemaFixture().use { fixture ->
            fixture.migrate(fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: true };"))

            patchRunFailure {
                fixture.migrate(
                    fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: false };"),
                )
            }.message shouldBe "Applied patch was modified: 0001_create_probe"

            fixture.database
                .query("SELECT * FROM patch_probe")
                .take(0)
                .getArray()
                .len() shouldBe 1
        }
    }

    test("failed patch rolls back its changes and history record") {
        SchemaFixture().use { fixture ->
            patchRunFailure {
                fixture.migrate(
                    fixture.resources("0001_invalid" to "CREATE rollback_probe:test; THROW \"rollback\";"),
                )
            }.shouldBeInstanceOf<PatchFailedException>().message shouldBe "Failed to apply patch: 0001_invalid"

            fixture.database
                .query("SELECT * FROM _patch")
                .take(0)
                .getArray()
                .len() shouldBe 0
            shouldThrowAny { fixture.database.query("SELECT * FROM rollback_probe").take(0) }
        }
    }

    test("startup fails when patch history holds a patch missing from the catalog") {
        SchemaFixture().use { fixture ->
            fixture.migrate(fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: true };"))
            fixture.database
                .query("CREATE type::record('_patch', '0002_removed') SET checksum = '${"a".repeat(64)}';")
                .take(0)

            patchRunFailure {
                fixture.migrate(fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: true };"))
            }.message shouldBe "Patch history contains patches missing from the catalog: 0002_removed"
        }
    }

    test("empty forward patch catalog applies the native realm schema") {
        SchemaFixture().use { fixture ->
            fixture.migrate(fixture.resources())

            fixture.database
                .query("INFO FOR TABLE realm_probe")
                .take(0)
                .isObject shouldBe true
            fixture.database
                .query("SELECT * FROM _patch")
                .take(0)
                .getArray()
                .len() shouldBe 0
        }
    }

    test("migration telemetry nests under the caller main span with patch attributes") {
        SchemaFixture().use { fixture ->
            fixture.migrate(
                fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: true };"),
            )

            fixture.telemetry.spans {
                main("test.realm.start") {
                    child("realm.schema.migrate") {
                        child("realm.patch.run") {
                            attribute("patch.total_count", 1L)
                            attribute("patch.pending_count", 1L)
                            child("realm.patch.apply") {
                                attribute("patch.id", "0001_create_probe")
                            }
                        }
                    }
                }
            }
        }
    }
}

/** Runs a migration expected to fail startup as a patch run failure and returns the underlying cause. */
private fun patchRunFailure(block: () -> Unit): Throwable {
    val failure = shouldThrow<SluggedException>(block)
    failure.slug shouldBe ErrorSlug.of("realm-patch-run-failed")
    return requireNotNull(failure.cause)
}

private class SchemaFixture : AutoCloseable {
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
