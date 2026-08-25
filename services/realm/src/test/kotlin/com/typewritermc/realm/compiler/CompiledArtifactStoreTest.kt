package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.CompiledPageReference
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.library.Page
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobChunk
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.BlobWriteSession
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.types.Ref
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val CompiledArtifactStoreTest by testSuite {
    test("publication writes content addressed artifacts once") {
        runTest {
            val blobs = RecordingBlobEndpoint()
            val store = CompiledArtifactStore(blobs)
            val shard = compiledShard()
            val manifest = compiledManifest(shard)

            val first = store.store(1, manifest, listOf(shard))
            val second = store.store(2, manifest, listOf(shard))

            first.manifest shouldBe second.manifest
            first.shards shouldBe second.shards
            blobs.completedWrites shouldBe 2
            blobs.storedArtifacts shouldBe 2
        }
    }
}

private fun compiledShard() =
    CompiledPageShard(
        formatRevision = 1,
        digest = ContentDigest("1".repeat(64)),
        inputFingerprint = ContentDigest("2".repeat(64)),
        page = Ref<Page>("page", "artifact_test"),
        elements = emptyList(),
    )

private fun compiledManifest(shard: CompiledPageShard) =
    CompiledManifest(
        formatRevision = 1,
        digest = ContentDigest("3".repeat(64)),
        sourceRevision = "1",
        catalogRevision = "catalog:1",
        pages = listOf(CompiledPageReference(shard.page, shard.digest)),
    )

private class RecordingBlobEndpoint : BlobEndpoint {
    private val artifacts = mutableMapOf<ArtifactDigest, ByteArray>()
    private val writes = mutableMapOf<TransferId, PendingWrite>()
    var completedWrites = 0
        private set
    val storedArtifacts: Int
        get() = artifacts.size

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        artifacts[digest]
            ?.let { BlobResult.Success(BlobMetadata(digest, it.size.toLong())) }
            ?: BlobResult.NotFound

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> = error("Reads are not used by artifact publication tests.")

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> {
        writes[transfer] = PendingWrite(expected)
        return BlobResult.Success(BlobWriteSession(transfer, expected, 0))
    }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> {
        val pending = writes.getValue(transfer)
        if (offset != pending.bytes.size.toLong()) return BlobResult.Conflict("Unexpected write offset.")
        pending.bytes += bytes
        return BlobResult.Success(pending.bytes.size.toLong())
    }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> {
        val pending = writes.remove(transfer) ?: return BlobResult.NotFound
        if (ArtifactDigest.sha256(pending.bytes) != pending.expected.digest) {
            return BlobResult.Invalid("Digest mismatch.")
        }
        artifacts[pending.expected.digest] = pending.bytes
        completedWrites++
        return BlobResult.Success(pending.expected)
    }

    private data class PendingWrite(
        val expected: BlobMetadata,
        var bytes: ByteArray = byteArrayOf(),
    )
}
