package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.PublicationBlobRoots
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.requireStored
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.attribute.FileTime
import java.time.Instant

val PublicationBlobRetentionTest by testSuite {
    test("selected and pending publication bytes survive collection and process recreation") {
        val root = Files.createTempDirectory("publication-retention")
        val blobs = FileDigestBlobStore(root)
        val retention = blobs.publicationRetention("realm")
        retention.reconcile(null)
        val selected = blobs.storeAged(byteArrayOf(1))
        val pending = blobs.storeAged(byteArrayOf(2))
        blobs.storeAged(byteArrayOf(3))
        retention.protect("selected", setOf(selected))
        retention.selected("selected")
        retention.protect("pending", setOf(pending))
        blobs.collectGarbage(emptySet()) shouldBe 1
        val restarted = FileDigestBlobStore(root)
        restarted.collectGarbage(emptySet()) shouldBe 0
        (restarted.metadata(selected) is BlobResult.Success) shouldBe true
        (restarted.metadata(pending) is BlobResult.Success) shouldBe true
        val recovered = restarted.publicationRetention("realm")
        recovered.reconcile(PublicationBlobRoots("selected", setOf(selected)))
        restarted.collectGarbage(emptySet()) shouldBe 1
        restarted.metadata(pending) shouldBe BlobResult.NotFound
        (restarted.metadata(selected) is BlobResult.Success) shouldBe true
    }
    test("unreconciled active Realm and corrupt retention ledger both prevent deletion") {
        val root = Files.createTempDirectory("publication-retention-failure")
        val blobs = FileDigestBlobStore(root)
        val source = blobs.storeAged(byteArrayOf(4))
        val retention = blobs.publicationRetention("new-realm")
        blobs.collectGarbage(emptySet()) shouldBe 0
        retention.reconcile(null)
        Files.write(root.resolve("publication-pins.cbor"), byteArrayOf(-1, -1))
        shouldThrow<Exception> { blobs.collectGarbage(emptySet()) }
        (blobs.metadata(source) is BlobResult.Success) shouldBe true
    }
    test("different publication bytes cannot replace protected roots") {
        val root = Files.createTempDirectory("publication-retention-identity")
        val blobs = FileDigestBlobStore(root)
        val retention = blobs.publicationRetention("realm")
        retention.reconcile(null)
        val first = ArtifactDigest.sha256(byteArrayOf(1))
        val second = ArtifactDigest.sha256(byteArrayOf(2))
        retention.protect("publication", setOf(first))
        shouldThrow<IllegalStateException> { retention.protect("publication", setOf(second)) }
        retention.selected("publication")
        FilePublicationPins(root.resolve("publication-pins.cbor")).read().getValue("realm").digests shouldBe setOf(first)
    }
}

/** Stores [content] and backdates it past the collection grace period. */
private suspend fun FileDigestBlobStore.storeAged(content: ByteArray): ArtifactDigest {
    val digest = store(BlobMetadata(ArtifactDigest.sha256(content), content.size.toLong()), content).requireStored().digest
    Files.setLastModifiedTime(pathFor(digest), FileTime.from(Instant.EPOCH))
    return digest
}
