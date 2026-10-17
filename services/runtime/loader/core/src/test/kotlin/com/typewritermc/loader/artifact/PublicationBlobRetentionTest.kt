package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.PublicationBlobRoots
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.BlobTransfer
import com.typewritermc.services.libs.filetransfer.blob.ByteArrayBlobSource
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
        val selected = ByteArrayBlobSource(byteArrayOf(1))
        val pending = ByteArrayBlobSource(byteArrayOf(2))
        val abandoned = ByteArrayBlobSource(byteArrayOf(3))
        for (source in listOf(selected, pending, abandoned)) {
            BlobTransfer().copyVerified(source, blobs, source.digest)
            Files.setLastModifiedTime(blobs.pathFor(source.digest), FileTime.from(Instant.EPOCH))
        }
        retention.protect("selected", setOf(selected.digest))
        retention.selected("selected")
        retention.protect("pending", setOf(pending.digest))
        blobs.collectGarbage(emptySet()) shouldBe 1
        val restarted = FileDigestBlobStore(root)
        restarted.collectGarbage(emptySet()) shouldBe 0
        (restarted.metadata(selected.digest) is BlobResult.Success) shouldBe true
        (restarted.metadata(pending.digest) is BlobResult.Success) shouldBe true
        val recovered = restarted.publicationRetention("realm")
        recovered.reconcile(PublicationBlobRoots("selected", setOf(selected.digest)))
        restarted.collectGarbage(emptySet()) shouldBe 1
        restarted.metadata(pending.digest) shouldBe BlobResult.NotFound
        (restarted.metadata(selected.digest) is BlobResult.Success) shouldBe true
    }
    test("unreconciled active Realm and corrupt retention ledger both prevent deletion") {
        val root = Files.createTempDirectory("publication-retention-failure")
        val blobs = FileDigestBlobStore(root)
        val source = ByteArrayBlobSource(byteArrayOf(4))
        BlobTransfer().copyVerified(source, blobs, source.digest)
        Files.setLastModifiedTime(blobs.pathFor(source.digest), FileTime.from(Instant.EPOCH))
        val retention = blobs.publicationRetention("new-realm")
        blobs.collectGarbage(emptySet()) shouldBe 0
        retention.reconcile(null)
        Files.write(root.resolve("publication-pins.cbor"), byteArrayOf(-1, -1))
        shouldThrow<Exception> { blobs.collectGarbage(emptySet()) }
        (blobs.metadata(source.digest) is BlobResult.Success) shouldBe true
    }
    test("different publication bytes cannot replace protected roots") {
        val root = Files.createTempDirectory("publication-retention-identity")
        val blobs = FileDigestBlobStore(root)
        val retention = blobs.publicationRetention("realm")
        retention.reconcile(null)
        val first = ByteArrayBlobSource(byteArrayOf(1)).digest
        val second = ByteArrayBlobSource(byteArrayOf(2)).digest
        retention.protect("publication", setOf(first))
        shouldThrow<IllegalStateException> { retention.protect("publication", setOf(second)) }
        retention.selected("publication")
        FilePublicationPins(root.resolve("publication-pins.cbor")).read().getValue("realm").digests shouldBe setOf(first)
    }
}
