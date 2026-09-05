package com.typewritermc.realm.compiler

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.library.PageId
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.util.UUID

interface CompiledContentRepository {
    suspend fun findShard(inputFingerprint: ContentDigest): CompiledPageShard?

    suspend fun activeManifest(): CompiledManifest?

    suspend fun activeActivation(): CompiledContentActivation?

    suspend fun nextActivationRevision(): Long

    suspend fun recordBlocked(
        sourceRevision: String,
        catalogRevision: String,
        pages: List<PageId>,
        diagnostics: List<CompileDiagnostic>,
    )

    suspend fun publish(
        manifest: CompiledManifest,
        shards: List<CompiledPageShard>,
        activation: CompiledContentActivation,
    ): Boolean
}

class SurrealCompiledContentRepository(
    private val database: Surreal,
    private val onActivated: suspend (CompiledContentActivation) -> Unit = {},
    private val onBlocked: suspend () -> Unit = {},
) : CompiledContentRepository {
    override suspend fun findShard(inputFingerprint: ContentDigest): CompiledPageShard? =
        database
            .query(
                "SELECT VALUE payload FROM compiled_page_shard WHERE input_fingerprint = \$fingerprint LIMIT 1;",
                mapOf("fingerprint" to inputFingerprint.value),
            ).take(0)
            .getArray()
            .firstOrNull()
            ?.getString()
            ?.let(::decodeShard)

    override suspend fun activeManifest(): CompiledManifest? =
        database
            .query("SELECT VALUE manifest.payload FROM ONLY active_compiled_manifest:current;")
            .take(0)
            .takeUnless { it.isNone || it.isNull }
            ?.getString()
            ?.let(::decodeManifest)

    override suspend fun activeActivation(): CompiledContentActivation? =
        database
            .query("SELECT VALUE activation_payload FROM ONLY active_compiled_manifest:current;")
            .take(0)
            .takeUnless { it.isNone || it.isNull }
            ?.getString()
            ?.let { json.decodeFromString(CompiledContentActivation.serializer(), it) }

    override suspend fun nextActivationRevision(): Long {
        val active =
            database
                .query("SELECT VALUE activation_revision FROM ONLY active_compiled_manifest:current;")
                .take(0)
        return if (active.isNone || active.isNull) 1L else active.getLong() + 1
    }

    override suspend fun recordBlocked(
        sourceRevision: String,
        catalogRevision: String,
        pages: List<PageId>,
        diagnostics: List<CompileDiagnostic>,
    ) {
        database.inTransaction { transaction ->
            transaction.createAttempt(sourceRevision, catalogRevision, pages, "blocked", diagnostics, manifest = null)
        }
        onBlocked()
    }

    override suspend fun publish(
        manifest: CompiledManifest,
        shards: List<CompiledPageShard>,
        activation: CompiledContentActivation,
    ): Boolean {
        val published =
            database.inTransaction { transaction ->
                val currentRevision =
                    transaction
                        .query("SELECT VALUE revision FROM ONLY authoring_head:current;")
                        .take(0)
                        .getLong()
                        .toString()
                if (currentRevision != manifest.sourceRevision) return@inTransaction false
                shards.forEach { shard ->
                    val payload = json.encodeToString(CompiledPageShard.serializer(), shard)
                    transaction.createImmutableShard(shard, payload)
                }
                transaction.createImmutableManifest(manifest, shards)
                val active =
                    transaction
                        .query("SELECT VALUE activation_revision FROM ONLY active_compiled_manifest:current;")
                        .take(0)
                val activationRevision = if (active.isNone || active.isNull) 1L else active.getLong() + 1
                if (activationRevision != activation.activationRevision) return@inTransaction false
                transaction
                    .query(
                        "UPSERT ONLY active_compiled_manifest:current CONTENT { manifest: \$manifest, " +
                            "activation_revision: \$activation_revision, activation_payload: \$activation_payload, " +
                            "activated_at: time::now() };",
                        mapOf(
                            "manifest" to manifest.id(),
                            "activation_revision" to activationRevision,
                            "activation_payload" to json.encodeToString(CompiledContentActivation.serializer(), activation),
                        ),
                    ).take(0)
                transaction.createAttempt(
                    manifest.sourceRevision,
                    manifest.catalogRevision,
                    manifest.pages.map { PageId(it.page.id.key) },
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

private fun Transaction.createImmutableShard(
    shard: CompiledPageShard,
    payload: String,
) {
    val current = query("SELECT VALUE payload FROM ONLY \$shard;", mapOf("shard" to shard.id())).take(0)
    if (!current.isNone && !current.isNull) {
        check(current.getString() == payload) { "Compiled shard ${shard.digest.value} is not immutable." }
        return
    }
    query(
        "CREATE ONLY \$shard CONTENT { input_fingerprint: \$fingerprint, page: \$page, payload: \$payload };",
        mapOf(
            "shard" to shard.id(),
            "fingerprint" to shard.inputFingerprint.value,
            "page" to shard.page.surrealId(),
            "payload" to payload,
        ),
    ).take(0)
}

private fun Transaction.createImmutableManifest(
    manifest: CompiledManifest,
    shards: List<CompiledPageShard>,
) {
    val payload = json.encodeToString(CompiledManifest.serializer(), manifest)
    val current = query("SELECT VALUE payload FROM ONLY \$manifest;", mapOf("manifest" to manifest.id())).take(0)
    if (!current.isNone && !current.isNull) {
        check(current.getString() == payload) { "Compiled manifest ${manifest.digest.value} is not immutable." }
        return
    }
    query(
        "CREATE ONLY \$manifest CONTENT { source_revision: \$source_revision, catalog_revision: \$catalog_revision, " +
            "pages: \$pages, payload: \$payload };",
        mapOf(
            "manifest" to manifest.id(),
            "source_revision" to manifest.sourceRevision,
            "catalog_revision" to manifest.catalogRevision,
            "pages" to shards.map(CompiledPageShard::id),
            "payload" to payload,
        ),
    ).take(0)
}

private fun Transaction.createAttempt(
    sourceRevision: String,
    catalogRevision: String,
    pages: List<PageId>,
    status: String,
    diagnostics: List<CompileDiagnostic>,
    manifest: RecordId?,
) {
    val manifestField = if (manifest == null) "" else ", manifest: \$manifest"
    query(
        "CREATE ONLY \$attempt CONTENT { source_revision: \$source_revision, catalog_revision: \$catalog_revision, pages: \$pages, " +
            "compiler_format: \$compiler_format, status: \$status, diagnostics: \$diagnostics" +
            manifestField + ", completed_at: time::now() };",
        mapOf(
            "attempt" to RecordId("compile_attempt", UUID.randomUUID().toString()),
            "source_revision" to sourceRevision,
            "catalog_revision" to catalogRevision,
            "pages" to pages.map(PageId::surrealId),
            "compiler_format" to CURRENT_COMPILER_FORMAT,
            "status" to status,
            "diagnostics" to json.encodeToString(ListSerializer(CompileDiagnostic.serializer()), diagnostics),
            "manifest" to manifest,
        ),
    ).take(0)
}

private fun CompiledPageShard.id(): RecordId = RecordId("compiled_page_shard", digest.value)

private fun CompiledManifest.id(): RecordId = RecordId("compiled_manifest", digest.value)

private fun decodeShard(value: String): CompiledPageShard = json.decodeFromString(CompiledPageShard.serializer(), value)

private fun decodeManifest(value: String): CompiledManifest = json.decodeFromString(CompiledManifest.serializer(), value)

private val json = Json { encodeDefaults = true }
