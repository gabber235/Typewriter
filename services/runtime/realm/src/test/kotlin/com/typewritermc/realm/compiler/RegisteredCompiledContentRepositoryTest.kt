package com.typewritermc.realm.compiler

import com.surrealdb.Surreal
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompileDiagnosticSeverity
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactPointer
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RegisteredCompiledContentRepositoryTest by testSuite {
    test("replacement manifest persists preserved and newly compiled artifact rows") {
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("test").useDb("test")
            database.query(
                """
                DEFINE TABLE resource SCHEMALESS;
                DEFINE TABLE authoring_head SCHEMALESS;
                UPSERT ONLY authoring_head:current SET revision = 1;
                DEFINE TABLE compiled_artifact SCHEMALESS;
                DEFINE TABLE compiled_artifact_manifest SCHEMALESS;
                DEFINE TABLE active_compiled_artifact_manifest SCHEMALESS;
                DEFINE TABLE compile_attempt SCHEMALESS;
                DEFINE TABLE compile_attempt_root SCHEMALESS TYPE RELATION IN compile_attempt OUT resource;
                """.trimIndent(),
            )
            val repository = SurrealRegisteredCompiledContentRepository(database)
            val preserved = 'a'.artifact("preserved")
            val firstManifest = 'c'.manifest("1", listOf(preserved))

            repository.publish(
                firstManifest,
                listOf(preserved),
                firstManifest.activation(1, preserved),
            ) shouldBe true

            database.query("UPSERT ONLY authoring_head:current SET revision = 2;")
            val replacement = 'b'.artifact("replacement")
            val secondManifest = 'd'.manifest("2", listOf(preserved, replacement))

            repository.publish(
                secondManifest,
                listOf(replacement),
                secondManifest.activation(2, preserved, replacement),
            ) shouldBe true

            database
                .query(
                    "SELECT VALUE array::len(artifacts) FROM ONLY \$manifest;",
                    mapOf("manifest" to com.surrealdb.RecordId("compiled_artifact_manifest", secondManifest.digest.value)),
                ).take(0)
                .getLong() shouldBe 2L
        }
    }

    test("stale blocked attempts are discarded when the authoring head advanced") {
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("test").useDb("test")
            database.query(
                """
                DEFINE TABLE resource SCHEMAFULL TYPE NORMAL;
                DEFINE TABLE authoring_head SCHEMAFULL TYPE NORMAL;
                DEFINE FIELD revision ON authoring_head TYPE int;
                UPSERT ONLY authoring_head:current SET revision = 2;
                DEFINE TABLE compile_attempt SCHEMAFULL TYPE NORMAL;
                DEFINE FIELD source_revision ON compile_attempt TYPE string;
                DEFINE FIELD catalog_revision ON compile_attempt TYPE string;
                DEFINE FIELD compiler_format ON compile_attempt TYPE int;
                DEFINE FIELD status ON compile_attempt TYPE string;
                DEFINE FIELD diagnostics ON compile_attempt TYPE string;
                DEFINE TABLE compile_attempt_root SCHEMAFULL TYPE RELATION IN compile_attempt OUT resource;
                DEFINE FIELD projection ON compile_attempt_root TYPE string;
                """.trimIndent(),
            )

            var blockedNotifications = 0
            val repository =
                SurrealRegisteredCompiledContentRepository(
                    database = database,
                    onBlocked = { blockedNotifications++ },
                )
            val root = CompilationRoot(CompilationProjectionId("test.projection"), ResourceId("root"))

            repository.recordBlocked(
                sourceRevision = "1",
                catalogRevision = "catalog",
                roots = listOf(root),
                diagnostics =
                    listOf(
                        CompileDiagnostic(
                            code = "blocked",
                            message = "blocked",
                            severity = CompileDiagnosticSeverity.ERROR,
                        ),
                    ),
            ) shouldBe false

            blockedNotifications shouldBe 0
            database
                .query("SELECT * FROM compile_attempt;")
                .take(0)
                .getArray()
                .len() shouldBe 0
        }
    }
}

private fun Char.artifact(resource: String) =
    CompiledArtifact(
        root = CompilationRoot(CompilationProjectionId("test.projection"), ResourceId(resource)),
        formatRevision = 1,
        mediaType = "application/vnd.typewriter.test",
        inputFingerprint = ContentDigest(toString().repeat(64)),
        semanticDigest = ContentDigest(toString().repeat(64)),
        payload = byteArrayOf(code.toByte()),
    )

private fun Char.manifest(
    sourceRevision: String,
    artifacts: List<CompiledArtifact>,
) = CompiledArtifactManifest(
    formatRevision = 1,
    digest = ContentDigest(toString().repeat(64)),
    sourceRevision = sourceRevision,
    catalogRevision = "catalog",
    artifacts =
        artifacts.map { artifact ->
            com.typewritermc.engine.CompiledArtifactReference(
                root = artifact.root,
                formatRevision = artifact.formatRevision,
                mediaType = artifact.mediaType,
                semanticDigest = artifact.semanticDigest,
            )
        },
)

private fun CompiledArtifactManifest.activation(
    revision: Long,
    vararg artifacts: CompiledArtifact,
) = CompiledArtifactActivation(
    activationRevision = revision,
    manifestDigest = digest,
    manifest = CompiledBlobPointer(ContentDigest('e'.toString().repeat(64)), 1),
    artifacts =
        artifacts.map { artifact ->
            CompiledArtifactPointer(
                semanticDigest = artifact.semanticDigest,
                blob = CompiledBlobPointer(ContentDigest(artifact.semanticDigest.value), 1),
            )
        },
)
