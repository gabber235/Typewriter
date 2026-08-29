package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.shouldBe

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

            shouldThrowAny {
                fixture.migrate(
                    fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: false };"),
                )
            }

            fixture.database
                .query("SELECT * FROM patch_probe")
                .take(0)
                .getArray()
                .len() shouldBe 1
        }
    }

    test("failed patch rolls back its changes and history record") {
        SchemaFixture().use { fixture ->
            shouldThrowAny {
                fixture.migrate(
                    fixture.resources("0001_invalid" to "CREATE rollback_probe:test; THROW \"rollback\";"),
                )
            }

            fixture.database
                .query("SELECT * FROM _patch")
                .take(0)
                .getArray()
                .len() shouldBe 0
            shouldThrowAny { fixture.database.query("SELECT * FROM rollback_probe").take(0) }
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

    test("migration uses the caller main span and creates only scoped children") {
        SchemaFixture().use { fixture ->
            fixture.migrate(
                fixture.resources("0001_create_probe" to "CREATE patch_probe CONTENT { value: true };"),
            )

            fixture.telemetry.spans {
                count(6)
                roots(1)
                main("test.realm.start") {
                    child("realm.schema.migrate") {
                        childCount(3)
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
