package com.typewritermc.engine.runtime

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompilationContext
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.PublishedOutput
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobChunk
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.BlobWriteSession
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

val BlobCompiledArtifactSourceTest by testSuite {
    test("loads a complete publication and its opaque artifacts") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("a", "page")
            val activation = activation(1, listOf(shard), blobs)

            val loaded = BlobCompiledArtifactSource(blobs).load(activation)

            loaded.descriptor.publication shouldBe PublicationId("publication:1")
            loaded.descriptor.outputs
                .map { it.reference }
                .single()
                .root.resource shouldBe ResourceId("page")
            Json.decodeFromString(
                CompiledPageShard.serializer(),
                loaded.artifacts
                    .single()
                    .payload
                    .decodeToString(),
            ) shouldBe shard
        }
    }

    test("missing blobs fail without returning a partial activation") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("b", "missing")
            val activation = activation(1, listOf(shard), blobs)
            blobs.remove(activation.outputs.single().blob)

            shouldThrow<IllegalStateException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("corrupt blobs are rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("c", "corrupt")
            val activation = activation(1, listOf(shard), blobs)
            blobs.corrupt(activation.outputs.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("premature final chunks are rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("d", "truncated")
            val activation = activation(1, listOf(shard), blobs)
            blobs.truncate(activation.outputs.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }
}

private fun shard(
    digestCharacter: String,
    pageKey: String,
) = CompiledPageShard(
    formatRevision = 2,
    digest = ContentDigest(digestCharacter.repeat(64)),
    inputFingerprint = ContentDigest("f".repeat(64)),
    root = CompiledResourceKey(ResourceId(pageKey), CompilationContext.Root),
    resources = emptyList(),
    edges = emptyList(),
)

private fun activation(
    revision: Long,
    shards: List<CompiledPageShard>,
    blobs: FakeBlobEndpoint,
): PublishedContent {
    val outputs =
        shards.map { shard ->
            PublishedOutput(
                CompiledArtifactReference(
                    CompilationRoot(CompilationProjectionId("typewriter.page"), shard.root.source),
                    shard.formatRevision,
                    PageCompiledArtifactConsumer.PAGE_MEDIA_TYPE,
                    shard.digest,
                ),
                blobs.put(Json.encodeToString(shard).encodeToByteArray()),
            )
        }
    return PublishedContent(
        PublicationId("publication:$revision"),
        2,
        CatalogGeneration("catalog:1"),
        "implementation",
        emptySet(),
        outputs,
    )
}

private class FakeBlobEndpoint : BlobEndpoint {
    private val bytes = mutableMapOf<ArtifactDigest, ByteArray>()
    private val declaredSizes = mutableMapOf<ArtifactDigest, Long>()

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
        val start = offset.toInt().coerceAtMost(value.size)
        val end = (start + maximumBytes).coerceAtMost(value.size)
        return BlobResult.Success(BlobChunk(offset, value.copyOfRange(start, end), complete = end == value.size))
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

    fun put(value: ByteArray): CompiledBlobPointer {
        val digest = ArtifactDigest.sha256(value)
        bytes[digest] = value
        declaredSizes[digest] = value.size.toLong()
        return CompiledBlobPointer(ContentDigest(digest.value), value.size.toLong())
    }
}

private fun CompiledBlobPointer.artifactDigest() =
    ArtifactDigest(
        com.typewritermc.loader.api.artifact.DigestAlgorithm.SHA_256,
        digest.value,
    )
