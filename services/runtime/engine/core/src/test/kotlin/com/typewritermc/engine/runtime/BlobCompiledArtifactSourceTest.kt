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
import com.typewritermc.engine.RuntimeCompilationFacts
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobChunk
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.BlobWriteSession
import com.typewritermc.services.libs.filetransfer.blob.TransferId
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

    test("metadata size disagreement is rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val activation = activation(1, listOf(shard("e", "size")), blobs)
            blobs.misreportSize(activation.outputs.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("empty chunk progress is rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val activation = activation(1, listOf(shard("f", "empty")), blobs)
            blobs.returnEmptyChunk(activation.outputs.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("chunk offset disagreement is rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val activation = activation(1, listOf(shard("a", "offset")), blobs)
            blobs.shiftChunkOffset(activation.outputs.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("missing final completion is rejected") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val activation = activation(1, listOf(shard("b", "completion")), blobs)
            blobs.omitCompletion(activation.outputs.single().blob)

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }
}

private fun shard(
    digestCharacter: String,
    pageKey: String,
) = CompiledPageShard(
    digest = ContentDigest(digestCharacter.repeat(64)),
    facts =
        RuntimeCompilationFacts(
            formatRevision = 2,
            root = CompiledResourceKey(ResourceId(pageKey), CompilationContext.Root),
            resources = emptyList(),
            edges = emptyList(),
            types = emptyList(),
            relations = emptyList(),
        ),
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
                    CompilationRoot(CompilationProjectionId("typewriter.page"), shard.facts.root.source),
                    shard.facts.formatRevision,
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
    private val emptyChunks = mutableSetOf<ArtifactDigest>()
    private val shiftedOffsets = mutableSetOf<ArtifactDigest>()
    private val missingCompletions = mutableSetOf<ArtifactDigest>()

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

    fun misreportSize(pointer: CompiledBlobPointer) {
        val digest = pointer.artifactDigest()
        declaredSizes[digest] = declaredSizes.getValue(digest) + 1
    }

    fun returnEmptyChunk(pointer: CompiledBlobPointer) {
        emptyChunks += pointer.artifactDigest()
    }

    fun shiftChunkOffset(pointer: CompiledBlobPointer) {
        shiftedOffsets += pointer.artifactDigest()
    }

    fun omitCompletion(pointer: CompiledBlobPointer) {
        missingCompletions += pointer.artifactDigest()
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
        if (digest in emptyChunks) return BlobResult.Success(BlobChunk(offset, byteArrayOf(), complete = false))
        val start = offset.toInt().coerceAtMost(value.size)
        val end = (start + maximumBytes).coerceAtMost(value.size)
        val reportedOffset = if (digest in shiftedOffsets) offset + 1 else offset
        val complete = end == value.size && digest !in missingCompletions
        return BlobResult.Success(BlobChunk(reportedOffset, value.copyOfRange(start, end), complete))
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
        com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256,
        digest.value,
    )
