package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompileDiagnosticSeverity
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.CompiledPageReference
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.realm.repository.AuthoringSnapshot
import java.security.MessageDigest

/**
 * Compiles a full authoring snapshot and reuses shards by input fingerprint.
 *
 * Any error diagnostic blocks publication while retaining active content. Otherwise blobs are stored first and
 * repository publication checks freshness. Stale publication requests a fresh snapshot; already stored bytes
 * remain reusable.
 */
class RealmCompiler(
    private val content: CompiledContentRepository,
    private val artifacts: CompiledArtifactPublisher,
    private val compiler: PageCompiler = PageCompiler(),
) {
    suspend fun compile(
        snapshot: AuthoringSnapshot,
        catalogRevision: String,
    ): RealmCompileResult {
        val shards = mutableListOf<CompiledPageShard>()
        val diagnostics = mutableListOf<CompileDiagnostic>()
        var reused = 0
        for (document in snapshot.documents) {
            when (val result = compiler.compile(document, catalogRevision)) {
                is PageCompileResult.Blocked -> {
                    diagnostics += result.diagnostics
                }

                is PageCompileResult.Success -> {
                    val cached = content.findShard(result.shard.inputFingerprint)
                    if (cached != null) reused++
                    shards += cached ?: result.shard
                }
            }
        }
        if (diagnostics.any { it.severity == CompileDiagnosticSeverity.ERROR }) {
            content.recordBlocked(snapshot.revision, catalogRevision, snapshot.documents.map { it.page.id }, diagnostics)
            return RealmCompileResult.Blocked(diagnostics, content.activeManifest())
        }
        val ordered = shards.sortedBy { it.page.id.referenceString() }
        val pageReferences = ordered.map { CompiledPageReference(it.page, it.digest) }
        val digest = manifestDigest(snapshot.revision, catalogRevision, pageReferences)
        val manifest =
            CompiledManifest(
                formatRevision = CURRENT_COMPILER_FORMAT,
                digest = digest,
                sourceRevision = snapshot.revision,
                catalogRevision = catalogRevision,
                pages = pageReferences,
            )
        val activation = artifacts.store(content.nextActivationRevision(), manifest, ordered)
        if (!content.publish(manifest, ordered, activation)) return RealmCompileResult.Stale
        return RealmCompileResult.Activated(manifest, ordered, reused)
    }
}

/**
 * Distinguishes activation, blocked input, and a stale publication race.
 *
 * Blocked may carry the previous active manifest. Reuse counts describe shard caching, not omission of document
 * validation.
 */
sealed interface RealmCompileResult {
    data object Stale : RealmCompileResult

    data class Activated(
        val manifest: CompiledManifest,
        val shards: List<CompiledPageShard>,
        val reusedShardCount: Int,
    ) : RealmCompileResult

    data class Blocked(
        val diagnostics: List<CompileDiagnostic>,
        val activeManifest: CompiledManifest?,
    ) : RealmCompileResult
}

private fun manifestDigest(
    sourceRevision: String,
    catalogRevision: String,
    pages: List<CompiledPageReference>,
): ContentDigest {
    val facts =
        buildString {
            append("format:").append(CURRENT_COMPILER_FORMAT)
            append("|source:").append(sourceRevision)
            append("|catalog:").append(catalogRevision)
            pages.forEach { append("|page:").append(it.page.id.referenceString()).append(':').append(it.shard.value) }
        }
    return ContentDigest(
        MessageDigest.getInstance("SHA-256").digest(facts.toByteArray()).joinToString("") {
            "%02x".format(it.toInt() and 0xff)
        },
    )
}
