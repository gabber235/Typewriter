package com.typewritermc.engine.runtime

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactPointer
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
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
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

val BlobCompiledArtifactSourceTest by testSuite {
    test("loads a generic manifest and its opaque artifacts") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("a", "page")
            val activation = activation(1, listOf(shard), blobs)

            val loaded = BlobCompiledArtifactSource(blobs).load(activation)

            loaded.activationRevision shouldBe 1
            loaded.manifest.artifacts
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
            blobs.remove(activation.artifacts.single().blob)

            shouldThrow<IllegalStateException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("corrupt blobs are rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("c", "corrupt")
            val activation = activation(1, listOf(shard), blobs)
            blobs.corrupt(activation.artifacts.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("premature final chunks are rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("d", "truncated")
            val activation = activation(1, listOf(shard), blobs)
            blobs.truncate(activation.artifacts.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
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
    page = Ref<Page>(ResourceId(pageKey)),
    elements = emptyList(),
)

private fun activation(
    revision: Long,
    shards: List<CompiledPageShard>,
    blobs: FakeBlobEndpoint,
): CompiledArtifactActivation {
    val references =
        shards.map { shard ->
            CompiledArtifactReference(
                root = CompilationRoot(CompilationProjectionId("typewriter.page"), shard.page.id),
                formatRevision = shard.formatRevision,
                mediaType = PageCompiledArtifactConsumer.PAGE_MEDIA_TYPE,
                semanticDigest = shard.digest,
            )
        }
    val manifest =
        CompiledArtifactManifest(
            formatRevision = 1,
            digest = ContentDigest(revision.toString().repeat(64).take(64)),
            sourceRevision = "realm:$revision",
            catalogRevision = "catalog:1",
            artifacts = references,
        )
    return CompiledArtifactActivation(
        activationRevision = revision,
        manifestDigest = manifest.digest,
        manifest = blobs.put(Json.encodeToString(manifest).encodeToByteArray()),
        artifacts =
            shards.map { shard ->
                CompiledArtifactPointer(
                    semanticDigest = shard.digest,
                    blob = blobs.put(Json.encodeToString(shard).encodeToByteArray()),
                )
            },
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
