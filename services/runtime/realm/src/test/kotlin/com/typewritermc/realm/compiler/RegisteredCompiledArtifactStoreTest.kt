package com.typewritermc.realm.compiler

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobChunk
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.BlobWriteSession
import com.typewritermc.services.libs.filetransfer.blob.TransferId
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RegisteredCompiledArtifactStoreTest by testSuite {
    test("publication outputs are complete and reuse verified payload blobs") {
        val blobs = InMemoryBlobEndpoint()
        val store = RegisteredCompiledArtifactStore(blobs)
        val firstArtifact = 'a'.compiledArtifact("first")
        val first = store.store(PublicationId("first"), CatalogGeneration("catalog"), "implementation", emptySet(), listOf(firstArtifact))
        val second = store.store(PublicationId("second"), CatalogGeneration("catalog"), "implementation", emptySet(), listOf(firstArtifact))
        first.outputs.single().blob shouldBe second.outputs.single().blob
        val replacement = 'b'.compiledArtifact("replacement")
        val third = store.store(PublicationId("third"), CatalogGeneration("catalog"), "implementation", emptySet(), listOf(replacement))
        third.outputs.map { it.reference.root } shouldBe listOf(replacement.root)
        third.publication shouldBe PublicationId("third")
        third.formatRevision shouldBe 2
        val empty = store.store(PublicationId("empty"), CatalogGeneration("catalog"), "implementation", emptySet(), emptyList())
        empty.outputs shouldBe emptyList()
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

internal class InMemoryBlobEndpoint : BlobEndpoint {
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
