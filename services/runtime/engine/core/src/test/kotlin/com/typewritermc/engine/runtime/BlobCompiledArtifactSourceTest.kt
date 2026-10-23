package com.typewritermc.engine.runtime

import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.Root
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.compiled_content.ResourceGraphShard
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId

val BlobCompiledArtifactSourceTest by testSuite {
    test("loads a complete publication and its opaque artifacts") {
        runTest {
            val blobs = FakeBlobEndpoint()
            val shard = shard("a", "page")
            val activation = activation(1, listOf(shard), blobs)

            val loaded = BlobCompiledArtifactSource(blobs).load(activation)

            loaded.descriptor.publication shouldBe PublicationId(value = "publication:1")
            loaded.descriptor.outputs
                .map { it.reference }
                .single()
                .root.resource shouldBe ResourceId("page").toSkir()
            ResourceGraphShard.serializer.fromJsonCode(
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

    test("truncated content is rejected") {
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
) = ResourceGraphShard(
    digest = ContentDigest(digestCharacter.repeat(64)).value,
    facts =
        RuntimeCompilationFacts(
            formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
            root = CompiledResourceKey(source = ResourceId(pageKey).toSkir(), context = CompilationContext.Root),
            resources = emptyList(),
            edges = emptyList(),
            types = emptyList(),
            relations = emptyList(),
        ),
)

private fun activation(
    revision: Long,
    shards: List<ResourceGraphShard>,
    blobs: FakeBlobEndpoint,
): PublishedContent {
    val outputs =
        shards.map { shard ->
            PublishedOutput(
                reference =
                    CompiledArtifactReference(
                        root =
                            CompilationRoot(
                                projection = RESOURCE_GRAPH_PROJECTION,
                                resource = shard.facts.root.source,
                            ),
                        formatRevision = shard.facts.formatRevision,
                        mediaType = RESOURCE_GRAPH_MEDIA_TYPE,
                        semanticDigest = shard.digest,
                    ),
                blob = blobs.put(ResourceGraphShard.serializer.toJsonCode(shard).encodeToByteArray()),
            )
        }
    return PublishedContent(
        publication = PublicationId(value = "publication:$revision"),
        formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
        catalog = CatalogGeneration(value = "catalog:1"),
        implementationToken = "implementation",
        outputs = outputs,
    )
}

private class FakeBlobEndpoint : BlobEndpoint {
    private val bytes = mutableMapOf<ArtifactDigest, ByteArray>()

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
        val value = bytes[digest] ?: return BlobResult.NotFound
        return BlobResult.Success(BlobMetadata(digest, value.size.toLong()))
    }

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        bytes[digest]?.let { BlobResult.Success(it.copyOf()) } ?: BlobResult.NotFound

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult = error("Writes are unsupported in this fixture.")

    fun put(value: ByteArray): CompiledBlobPointer {
        val digest = ArtifactDigest.sha256(value)
        bytes[digest] = value
        return CompiledBlobPointer(digest = ContentDigest(digest.value).value, size = value.size.toLong())
    }
}

private fun CompiledBlobPointer.artifactDigest() =
    ArtifactDigest(
        com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256,
        digest,
    )
