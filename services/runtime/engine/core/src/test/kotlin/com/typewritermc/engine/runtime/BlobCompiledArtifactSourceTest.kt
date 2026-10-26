package com.typewritermc.engine.runtime

import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.Root
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
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
            val blobs = InMemoryBlobEndpoint()
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
            val blobs = InMemoryBlobEndpoint()
            val shard = shard("b", "missing")
            val activation = activation(1, listOf(shard), blobs)
            blobs.remove(activation.blobDigest())

            shouldThrow<IllegalStateException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("corrupt blobs are rejected") {
        runTest {
            val blobs = InMemoryBlobEndpoint()
            val shard = shard("c", "corrupt")
            val activation = activation(1, listOf(shard), blobs)
            val digest = activation.blobDigest()
            blobs.replace(digest, blobs.content(digest).also { it[it.lastIndex] = (it.last() + 1).toByte() })

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }
        }
    }

    test("truncated content is rejected") {
        runTest {
            val blobs = InMemoryBlobEndpoint()
            val shard = shard("d", "truncated")
            val activation = activation(1, listOf(shard), blobs)
            val digest = activation.blobDigest()
            blobs.replace(digest, blobs.content(digest).copyOf(1))

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
    blobs: InMemoryBlobEndpoint,
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
                blob = blobs.put(ResourceGraphShard.serializer.toJsonCode(shard).encodeToByteArray()).toPointer(),
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

private fun PublishedContent.blobDigest() = outputs.single().blob.artifactDigest()

private fun CompiledBlobPointer.artifactDigest() =
    ArtifactDigest(
        com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256,
        digest,
    )

private fun BlobMetadata.toPointer() = CompiledBlobPointer(digest = ContentDigest(digest.value).value, size = size)
