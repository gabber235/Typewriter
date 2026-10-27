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
