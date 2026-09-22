package com.typewritermc.realm.compiler

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.security.MessageDigest
import java.util.UUID

/** Reports the latest compiled state for one projection and resource root. */
sealed interface RegisteredCompiledState {
    data object NotCompiled : RegisteredCompiledState

    data class Active(
        val manifestId: String,
    ) : RegisteredCompiledState

    data class Blocked(
        val lastActiveManifestId: String?,
        val diagnosticCount: Int,
    ) : RegisteredCompiledState
}

/** Persists projection neutral artifacts, manifests, attempts, and activation pointers. */
interface RegisteredCompiledContentRepository {
    suspend fun activeManifest(): CompiledArtifactManifest?

    suspend fun activeActivation(): CompiledArtifactActivation?

    suspend fun nextActivationRevision(): Long

    suspend fun states(roots: Set<CompilationRoot>): Map<CompilationRoot, RegisteredCompiledState>

    suspend fun recordBlocked(
        sourceRevision: String,
        catalogRevision: String,
        roots: Collection<CompilationRoot>,
        diagnostics: List<CompileDiagnostic>,
    )

    suspend fun publish(
        manifest: CompiledArtifactManifest,
        artifacts: Collection<CompiledArtifact>,
        activation: CompiledArtifactActivation,
    ): Boolean
}

/** Surreal implementation with one immutable artifact table for every projection. */
class SurrealRegisteredCompiledContentRepository(
    private val database: Surreal,
    private val onActivated: suspend (CompiledArtifactActivation) -> Unit = {},
    private val onBlocked: suspend () -> Unit = {},
) : RegisteredCompiledContentRepository {
    override suspend fun activeManifest(): CompiledArtifactManifest? =
        database
            .query("SELECT VALUE manifest.payload FROM ONLY active_compiled_artifact_manifest:current;")
            .take(0)
            .takeUnless { it.isNone || it.isNull }
            ?.getString()
            ?.let { json.decodeFromString(CompiledArtifactManifest.serializer(), it) }

    override suspend fun activeActivation(): CompiledArtifactActivation? =
        database
            .query("SELECT VALUE activation_payload FROM ONLY active_compiled_artifact_manifest:current;")
            .take(0)
            .takeUnless { it.isNone || it.isNull }
            ?.getString()
            ?.let { json.decodeFromString(CompiledArtifactActivation.serializer(), it) }

    override suspend fun nextActivationRevision(): Long {
        val value =
            database
                .query("SELECT VALUE activation_revision FROM ONLY active_compiled_artifact_manifest:current;")
                .take(0)
        return if (value.isNone || value.isNull) 1L else value.getLong() + 1
    }

    override suspend fun states(roots: Set<CompilationRoot>): Map<CompilationRoot, RegisteredCompiledState> {
        if (roots.isEmpty()) return emptyMap()
        val active = activeManifest()
        val activeRoots = active?.artifacts?.associateBy(CompiledArtifactReference::root).orEmpty()
        val resourceIds = roots.map { it.resource.unifiedSurrealId() }
        val rows =
            database
                .query(
                    "SELECT projection, out, in.status AS status, in.diagnostics AS diagnostics, " +
                        "in.completed_at AS completed_at, in.manifest AS manifest " +
                        "FROM compile_attempt_root WHERE out IN \$resources ORDER BY completed_at DESC;",
                    mapOf("resources" to resourceIds),
                ).take(0)
                .getArray()
        val latest =
            rows
                .mapNotNull { row ->
                    val projection = row.getObject().get("projection").getString()
                    val resource =
                        row
                            .getObject()
                            .get("out")
                            .getString()
                            .substringAfter(':')
                    val root = CompilationRoot(com.typewritermc.engine.CompilationProjectionId(projection), ResourceId(resource))
                    root to row.getObject()
                }.groupBy { it.first }
                .mapValues { (_, values) -> values.first().second }
        return roots.associateWith { root ->
            val row = latest[root]
            val activeReference = activeRoots[root]
            when {
                row == null && activeReference == null -> {
                    RegisteredCompiledState.NotCompiled
                }

                row?.get("status")?.getString() == "blocked" -> {
                    val diagnostics = row.get("diagnostics").getString()
                    RegisteredCompiledState.Blocked(active?.digest?.value, diagnostics.count { it == '{' })
                }

                activeReference != null -> {
                    RegisteredCompiledState.Active(active?.digest?.value.orEmpty())
                }

                else -> {
                    RegisteredCompiledState.NotCompiled
                }
            }
        }
    }

    override suspend fun recordBlocked(
        sourceRevision: String,
        catalogRevision: String,
        roots: Collection<CompilationRoot>,
        diagnostics: List<CompileDiagnostic>,
    ) {
        database.inTransaction { transaction ->
            transaction.createRegisteredAttempt(sourceRevision, catalogRevision, roots, "blocked", diagnostics, null)
        }
        onBlocked()
    }

    override suspend fun publish(
        manifest: CompiledArtifactManifest,
        artifacts: Collection<CompiledArtifact>,
        activation: CompiledArtifactActivation,
    ): Boolean {
        val published =
            database.inTransaction { transaction ->
                val sourceRevision =
                    transaction
                        .query("SELECT VALUE revision FROM ONLY authoring_head:current;")
                        .take(0)
                        .getLong()
                        .toString()
                if (sourceRevision != manifest.sourceRevision) return@inTransaction false
                artifacts.forEach { transaction.createImmutableArtifact(it) }
                transaction.createImmutableArtifactManifest(manifest, artifacts)
                val current =
                    transaction
                        .query(
                            "SELECT VALUE activation_revision FROM ONLY active_compiled_artifact_manifest:current;",
                        ).take(0)
                val expectedRevision = if (current.isNone || current.isNull) 1L else current.getLong() + 1
                if (expectedRevision != activation.activationRevision) return@inTransaction false
                transaction
                    .query(
                        "UPSERT ONLY active_compiled_artifact_manifest:current CONTENT { " +
                            "manifest: \$manifest, activation_revision: \$activation_revision, " +
                            "activation_payload: \$activation_payload, activated_at: time::now() };",
                        mapOf(
                            "manifest" to manifest.id(),
                            "activation_revision" to expectedRevision,
                            "activation_payload" to json.encodeToString(CompiledArtifactActivation.serializer(), activation),
                        ),
                    ).take(0)
                transaction.createRegisteredAttempt(
                    manifest.sourceRevision,
                    manifest.catalogRevision,
                    manifest.artifacts.map(CompiledArtifactReference::root),
                    "success",
                    emptyList(),
                    manifest.id(),
                )
                true
            }
        if (published) onActivated(activation)
        return published
    }
}

private fun Transaction.createImmutableArtifact(artifact: CompiledArtifact) {
    val id = artifact.id()
    val payload = artifact.payload.encodeBase64()
    val current = query("SELECT VALUE payload FROM ONLY \$artifact;", mapOf("artifact" to id)).take(0)
    if (!current.isNone && !current.isNull) {
        check(current.getString() == payload) { "Compiled artifact ${artifact.semanticDigest.value} is not immutable." }
        return
    }
    query(
        "CREATE ONLY \$artifact CONTENT { projection: \$projection, root: \$root, format_revision: \$format, " +
            "media_type: \$media_type, input_fingerprint: \$input, semantic_digest: \$semantic, payload: \$payload };",
        mapOf(
            "artifact" to id,
            "projection" to artifact.root.projection.value,
            "root" to artifact.root.resource.unifiedSurrealId(),
            "format" to artifact.formatRevision,
            "media_type" to artifact.mediaType,
            "input" to artifact.inputFingerprint.value,
            "semantic" to artifact.semanticDigest.value,
            "payload" to payload,
        ),
    ).take(0)
}

private fun Transaction.createImmutableArtifactManifest(
    manifest: CompiledArtifactManifest,
    artifacts: Collection<CompiledArtifact>,
) {
    val payload = json.encodeToString(CompiledArtifactManifest.serializer(), manifest)
    val current = query("SELECT VALUE payload FROM ONLY \$manifest;", mapOf("manifest" to manifest.id())).take(0)
    if (!current.isNone && !current.isNull) {
        check(current.getString() == payload) { "Compiled manifest ${manifest.digest.value} is not immutable." }
        return
    }
    query(
        "CREATE ONLY \$manifest CONTENT { source_revision: \$source, catalog_revision: \$catalog, " +
            "artifacts: \$artifacts, payload: \$payload };",
        mapOf(
            "manifest" to manifest.id(),
            "source" to manifest.sourceRevision,
            "catalog" to manifest.catalogRevision,
            "artifacts" to artifacts.map { it.id() },
            "payload" to payload,
        ),
    ).take(0)
}

private fun Transaction.createRegisteredAttempt(
    sourceRevision: String,
    catalogRevision: String,
    roots: Collection<CompilationRoot>,
    status: String,
    diagnostics: List<CompileDiagnostic>,
    manifest: RecordId?,
) {
    val attempt = RecordId("compile_attempt", UUID.randomUUID().toString())
    val manifestField = if (manifest == null) "" else ", artifact_manifest: \$manifest"
    query(
        "CREATE ONLY \$attempt CONTENT { source_revision: \$source, catalog_revision: \$catalog, " +
            "compiler_format: 1, status: \$status, diagnostics: \$diagnostics" +
            manifestField + ", completed_at: time::now() };",
        mapOf(
            "attempt" to attempt,
            "source" to sourceRevision,
            "catalog" to catalogRevision,
            "status" to status,
            "diagnostics" to json.encodeToString(ListSerializer(CompileDiagnostic.serializer()), diagnostics),
            "manifest" to manifest,
        ),
    ).take(0)
    roots.forEach { root ->
        query(
            "RELATE \$attempt->compile_attempt_root->\$resource SET projection = \$projection;",
            mapOf(
                "attempt" to attempt,
                "resource" to root.resource.unifiedSurrealId(),
                "projection" to root.projection.value,
            ),
        ).take(0)
    }
}

private fun CompiledArtifact.id(): RecordId =
    RecordId("compiled_artifact", stableId(root.projection.value, root.resource.value, inputFingerprint.value))

private fun CompiledArtifactManifest.id(): RecordId = RecordId("compiled_artifact_manifest", digest.value)

private fun stableId(vararg values: String): String =
    MessageDigest.getInstance("SHA-256").digest(values.joinToString("|").encodeToByteArray()).joinToString("") {
        "%02x".format(it.toInt() and 0xff)
    }

private fun ByteArray.encodeBase64(): String =
    java.util.Base64
        .getEncoder()
        .encodeToString(this)

private val json = Json { encodeDefaults = true }
