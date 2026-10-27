package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.activation
import com.typewritermc.engine.runtime.testing.blobDigest
import com.typewritermc.engine.runtime.testing.shard
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.compiled_content.ResourceGraphShard
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

    test("a blob whose bytes changed is refused by its digest") {
        runTest {
            val blobs = InMemoryBlobEndpoint()
            val shard = shard("c", "corrupt")
            val activation = activation(1, listOf(shard), blobs)
            val digest = activation.blobDigest()
            // Still a well formed shard of the same size, so only the digest check can refuse it.
            blobs.replace(
                digest,
                blobs
                    .content(digest)
                    .decodeToString()
                    .replace("corrupt", "corrupu")
                    .encodeToByteArray(),
            )

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }.message shouldBe
                "Compiled artifact $digest does not match its descriptor."
        }
    }

    test("a truncated blob is refused against its descriptor") {
        runTest {
            val blobs = InMemoryBlobEndpoint()
            val shard = shard("d", "truncated")
            val activation = activation(1, listOf(shard), blobs)
            val digest = activation.blobDigest()
            blobs.replace(digest, blobs.content(digest).copyOf(1))

            shouldThrow<IllegalArgumentException> { BlobCompiledArtifactSource(blobs).load(activation) }.message shouldBe
                "Compiled artifact $digest does not match its descriptor."
        }
    }
}
