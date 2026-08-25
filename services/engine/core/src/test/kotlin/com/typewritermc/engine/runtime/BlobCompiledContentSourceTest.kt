package com.typewritermc.engine.runtime

import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.CompiledPageReference
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledShardPointer
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
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

val BlobCompiledContentSourceTest by testSuite {
    test("successive activations fetch only uncached shards") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val firstShard = shard("a", "first")
            val secondShard = shard("b", "second")
            val first = activation(1, listOf(firstShard), blobs)
            val second = activation(2, listOf(firstShard, secondShard), blobs)
            val source = BlobCompiledContentSource(blobs)

            source.load(first).content.shards shouldBe listOf(firstShard)
            source.load(second).content.shards shouldBe listOf(firstShard, secondShard)

            blobs.readCount(blobs.digest(firstShard)) shouldBe 1
            blobs.readCount(blobs.digest(secondShard)) shouldBe 1
        }
    }

    test("missing blobs fail without poisoning the shard cache") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val pageShard = shard("c", "missing")
            val activation = activation(1, listOf(pageShard), blobs)
            val shardPointer = activation.shards.single().blob
            blobs.remove(shardPointer)
            val source = BlobCompiledContentSource(blobs)

            shouldThrow<IllegalStateException> { source.load(activation) }

            blobs.put(pageShard)
            source.load(activation).content.shards shouldBe listOf(pageShard)
        }
    }

    test("corrupt blobs are rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val pageShard = shard("d", "corrupt")
            val activation = activation(1, listOf(pageShard), blobs)
            val pointer = activation.shards.single().blob
            blobs.corrupt(pointer)

            shouldThrow<IllegalArgumentException> {
                BlobCompiledContentSource(blobs).load(activation)
            }
        }
    }

    test("premature final chunks are rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val pageShard = shard("e", "truncated")
            val activation = activation(1, listOf(pageShard), blobs)
            blobs.truncate(activation.shards.single().blob)

            shouldThrow<IllegalArgumentException> {
                BlobCompiledContentSource(blobs).load(activation)
            }
        }
    }
}

private fun shard(
    digestCharacter: String,
    pageKey: String,
) = CompiledPageShard(
    formatRevision = 1,
    digest = ContentDigest(digestCharacter.repeat(64)),
    inputFingerprint = ContentDigest("f".repeat(64)),
    page = Ref<Page>("page", pageKey),
    elements = emptyList(),
)

private fun activation(
    revision: Long,
    shards: List<CompiledPageShard>,
    blobs: FakeBlobEndpoint,
): CompiledContentActivation {
    val manifest =
        CompiledManifest(
            formatRevision = 1,
            digest = ContentDigest(revision.toString().repeat(64).take(64)),
            sourceRevision = "realm:$revision",
            catalogRevision = "catalog:1",
            pages = shards.map { CompiledPageReference(it.page, it.digest) },
        )
    return CompiledContentActivation(
        activationRevision = revision,
        manifestDigest = manifest.digest,
        manifest = blobs.put(manifest),
        shards = shards.map { CompiledShardPointer(it.digest, blobs.put(it)) },
    )
}

private class FakeBlobEndpoint : BlobEndpoint {
    private val bytes = mutableMapOf<ArtifactDigest, ByteArray>()
    private val declaredSizes = mutableMapOf<ArtifactDigest, Long>()
    private val reads = mutableMapOf<ArtifactDigest, Int>()

    fun put(value: CompiledPageShard): CompiledBlobPointer = put(Json.encodeToString(value).encodeToByteArray())

    fun put(value: CompiledManifest): CompiledBlobPointer = put(Json.encodeToString(value).encodeToByteArray())

    fun digest(value: CompiledPageShard): ArtifactDigest = ArtifactDigest.sha256(Json.encodeToString(value).encodeToByteArray())

    fun readCount(digest: ArtifactDigest): Int = reads[digest] ?: 0

    fun remove(pointer: CompiledBlobPointer) {
        bytes.remove(pointer.artifactDigest())
    }

    fun corrupt(pointer: CompiledBlobPointer) {
        val digest = pointer.artifactDigest()
        bytes[digest] = bytes.getValue(digest).copyOf().also { it[it.lastIndex] = (it.last() + 1).toByte() }
    }

    fun truncate(pointer: CompiledBlobPointer) {
        val digest = pointer.artifactDigest()
        bytes[digest] = bytes.getValue(digest).copyOf(1)
    }

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> {
        if (digest !in bytes) return BlobResult.NotFound
        return BlobResult.Success(BlobMetadata(digest, declaredSizes.getValue(digest)))
    }

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> {
        val value = bytes[digest] ?: return BlobResult.NotFound
        reads[digest] = (reads[digest] ?: 0) + 1
        val start = offset.toInt().coerceAtMost(value.size)
        val end = (start + maximumBytes).coerceAtMost(value.size)
        return BlobResult.Success(
            BlobChunk(offset, value.copyOfRange(start, end), complete = end == value.size),
        )
    }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> = error("Writes are unsupported in this fixture.")

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> = error("Writes are unsupported in this fixture.")

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> = error("Writes are unsupported in this fixture.")

    private fun put(value: ByteArray): CompiledBlobPointer {
        val digest = ArtifactDigest.sha256(value)
        bytes[digest] = value
        declaredSizes[digest] = value.size.toLong()
        return CompiledBlobPointer(ContentDigest(digest.value), value.size.toLong())
    }
}

private fun CompiledBlobPointer.artifactDigest() =
    com.typewritermc.loader.api.artifact.ArtifactDigest(
        com.typewritermc.loader.api.artifact.DigestAlgorithm.SHA_256,
        digest.value,
    )
