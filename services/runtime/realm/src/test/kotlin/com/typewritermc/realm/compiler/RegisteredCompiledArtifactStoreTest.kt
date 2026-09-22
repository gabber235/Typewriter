package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobChunk
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.BlobWriteSession
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RegisteredCompiledArtifactStoreTest by testSuite {
    test("replacement activation retains preserved artifact pointers") {
        val store = RegisteredCompiledArtifactStore(InMemoryBlobEndpoint())
        val preserved = 'a'.compiledArtifact("preserved")
        val firstManifest = 'c'.compiledManifest("1", listOf(preserved))
        val first = store.store(1, firstManifest, listOf(preserved), previousActivation = null)
        val replacement = 'b'.compiledArtifact("replacement")
        val secondManifest = 'd'.compiledManifest("2", listOf(preserved, replacement))

        val second = store.store(2, secondManifest, listOf(replacement), previousActivation = first)

        second.artifacts.mapTo(linkedSetOf()) { it.semanticDigest } shouldBe
            setOf(preserved.semanticDigest, replacement.semanticDigest)
    }
}

private fun Char.compiledArtifact(resource: String) =
    CompiledArtifact(
        root = CompilationRoot(CompilationProjectionId("test.projection"), ResourceId(resource)),
        formatRevision = 1,
        mediaType = "application/vnd.typewriter.test",
        inputFingerprint = ContentDigest(toString().repeat(64)),
        semanticDigest = ContentDigest(toString().repeat(64)),
        payload = byteArrayOf(code.toByte()),
    )

private fun Char.compiledManifest(
    sourceRevision: String,
    artifacts: List<CompiledArtifact>,
) = CompiledArtifactManifest(
    formatRevision = 1,
    digest = ContentDigest(toString().repeat(64)),
    sourceRevision = sourceRevision,
    catalogRevision = "catalog",
    artifacts =
        artifacts.map { artifact ->
            CompiledArtifactReference(
                root = artifact.root,
                formatRevision = artifact.formatRevision,
                mediaType = artifact.mediaType,
                semanticDigest = artifact.semanticDigest,
            )
        },
)

private class InMemoryBlobEndpoint : BlobEndpoint {
    private data class PendingWrite(
        val expected: BlobMetadata,
        var bytes: ByteArray = byteArrayOf(),
    )

    private val blobs = mutableMapOf<ArtifactDigest, ByteArray>()
    private val writes = mutableMapOf<TransferId, PendingWrite>()

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        blobs[digest]?.let { BlobResult.Success(BlobMetadata(digest, it.size.toLong())) } ?: BlobResult.NotFound

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> {
        val bytes = blobs[digest] ?: return BlobResult.NotFound
        val start = offset.toInt()
        val end = minOf(bytes.size, start + maximumBytes)
        return BlobResult.Success(BlobChunk(offset, bytes.copyOfRange(start, end), end == bytes.size))
    }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> {
        val existing = blobs[expected.digest]
        if (existing != null) return BlobResult.Success(BlobWriteSession(transfer, expected, existing.size.toLong()))
        val pending = writes.getOrPut(transfer) { PendingWrite(expected) }
        return BlobResult.Success(BlobWriteSession(transfer, expected, pending.bytes.size.toLong()))
    }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> {
        val pending = writes[transfer] ?: return BlobResult.NotFound
        if (offset != pending.bytes.size.toLong()) return BlobResult.Conflict("Unexpected write offset.")
        pending.bytes += bytes
        return BlobResult.Success(pending.bytes.size.toLong())
    }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> {
        val pending = writes.remove(transfer) ?: return BlobResult.NotFound
        if (pending.bytes.size.toLong() != pending.expected.size) return BlobResult.Invalid("Unexpected blob size.")
        if (ArtifactDigest.sha256(pending.bytes) != pending.expected.digest) {
            return BlobResult.Invalid("Unexpected blob digest.")
        }
        blobs[pending.expected.digest] = pending.bytes
        return BlobResult.Success(pending.expected)
    }
}
