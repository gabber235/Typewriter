package com.typewritermc.loader.artifact

import com.typewritermc.loader.artifact.testing.describing
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import java.nio.file.Files

val VerifiedArtifactCacheTest by testSuite {
    val artifactBytes = "artifact bytes".encodeToByteArray()

    test("a fetched artifact is cached locally with its verified bytes") {
        runTest {
            val source = InMemoryBlobEndpoint()
            val digest = source.put(artifactBytes).digest
            val cache = FileDigestBlobStore(Files.createTempDirectory("artifact-cache"))

            val path = VerifiedArtifactCache(source, cache).fetch(digest)

            Files.readAllBytes(path).toList() shouldBe artifactBytes.toList()
        }
    }

    test("an artifact whose source describes another digest is refused and nothing is cached") {
        runTest {
            val source = InMemoryBlobEndpoint()
            val digest = source.put(artifactBytes).digest
            val other = ArtifactDigest.sha256("other artifact".encodeToByteArray())
            val cache = FileDigestBlobStore(Files.createTempDirectory("artifact-cache-digest"))

            shouldThrow<IllegalArgumentException> {
                VerifiedArtifactCache(source.describing(BlobMetadata(other, artifactBytes.size.toLong())), cache).fetch(digest)
            }.message shouldBe "Artifact $digest cannot be transferred."

            cache.metadata(digest) shouldBe BlobResult.NotFound
        }
    }

    test("an artifact above the transfer ceiling is refused before its bytes are fetched") {
        runTest {
            val source = InMemoryBlobEndpoint()
            val digest = source.put(artifactBytes).digest
            val cache = FileDigestBlobStore(Files.createTempDirectory("artifact-cache-ceiling"))
            val oversized = source.describing(BlobMetadata(digest, TRANSFERRED_BLOB_MAX_BYTES + 1), fetchable = false)

            shouldThrow<IllegalArgumentException> { VerifiedArtifactCache(oversized, cache).fetch(digest) }.message shouldBe
                "Artifact $digest cannot be transferred."

            cache.metadata(digest) shouldBe BlobResult.NotFound
        }
    }

    test("an artifact whose fetched bytes do not match leaves nothing cached") {
        runTest {
            val source = InMemoryBlobEndpoint()
            val digest = source.put(artifactBytes).digest
            source.replace(digest, "damaged artifact".encodeToByteArray())
            val cache = FileDigestBlobStore(Files.createTempDirectory("artifact-cache-damaged"))

            shouldThrow<IllegalStateException> { VerifiedArtifactCache(source, cache).fetch(digest) }

            cache.metadata(digest) shouldBe BlobResult.NotFound
        }
    }
}
