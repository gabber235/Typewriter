package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.PublicationBlobRoots
import com.typewritermc.loader.artifact.testing.ledger
import com.typewritermc.loader.artifact.testing.shouldHold
import com.typewritermc.loader.artifact.testing.storeAged
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.serialization.SerializationException
import java.nio.file.Files

val PublicationBlobRetentionTest by testSuite {
    test("collection deletes old blobs no publication protects and keeps the selected and pending ones") {
        val blobs = FileDigestBlobStore(Files.createTempDirectory("publication-retention"))
        val retention = blobs.publicationRetention("realm")
        retention.reconcile(null)
        val selected = blobs.storeAged(byteArrayOf(1))
        val pending = blobs.storeAged(byteArrayOf(2))
        val unprotected = blobs.storeAged(byteArrayOf(3))
        retention.protect("selected", setOf(selected))
        retention.selected("selected")
        retention.protect("pending", setOf(pending))

        blobs.collectGarbage(emptySet())

        blobs.shouldHold(selected)
        blobs.shouldHold(pending)
        blobs.metadata(unprotected) shouldBe BlobResult.NotFound
    }

    test("publication protection survives a process restart") {
        val root = Files.createTempDirectory("publication-retention-restart")
        val blobs = FileDigestBlobStore(root)
        val retention = blobs.publicationRetention("realm")
        retention.reconcile(null)
        val selected = blobs.storeAged(byteArrayOf(1))
        val pending = blobs.storeAged(byteArrayOf(2))
        retention.protect("selected", setOf(selected))
        retention.selected("selected")
        retention.protect("pending", setOf(pending))

        val restarted = FileDigestBlobStore(root)
        restarted.collectGarbage(emptySet())

        restarted.shouldHold(selected)
        restarted.shouldHold(pending)
    }

    test("reconciling with the Realm's selection releases pending blobs it did not select") {
        val root = Files.createTempDirectory("publication-retention-reconcile")
        val blobs = FileDigestBlobStore(root)
        blobs.publicationRetention("realm").apply {
            reconcile(null)
            protect("pending", setOf(blobs.storeAged(byteArrayOf(2))))
        }
        val selected = blobs.storeAged(byteArrayOf(1))
        val pending = ArtifactDigest.sha256(byteArrayOf(2))

        val restarted = FileDigestBlobStore(root)
        restarted.publicationRetention("realm").reconcile(PublicationBlobRoots("selected", setOf(selected)))
        restarted.collectGarbage(emptySet())

        restarted.shouldHold(selected)
        restarted.metadata(pending) shouldBe BlobResult.NotFound
    }

    test("collection deletes nothing while an active Realm has not reconciled its publications") {
        val blobs = FileDigestBlobStore(Files.createTempDirectory("publication-retention-unreconciled"))
        val source = blobs.storeAged(byteArrayOf(4))
        blobs.publicationRetention("new-realm")

        blobs.collectGarbage(emptySet())

        blobs.shouldHold(source)
    }

    test("a corrupt retention ledger fails collection and deletes nothing") {
        val root = Files.createTempDirectory("publication-retention-corrupt")
        val blobs = FileDigestBlobStore(root)
        val source = blobs.storeAged(byteArrayOf(4))
        blobs.publicationRetention("realm").reconcile(null)
        Files.write(root.ledger(), byteArrayOf(-1, -1))

        shouldThrow<SerializationException> { blobs.collectGarbage(emptySet()) }

        blobs.shouldHold(source)
    }

    test("different bytes cannot replace a protected publication") {
        val blobs = FileDigestBlobStore(Files.createTempDirectory("publication-retention-identity"))
        val retention = blobs.publicationRetention("realm")
        retention.reconcile(null)
        val first = blobs.storeAged(byteArrayOf(1))
        val second = blobs.storeAged(byteArrayOf(2))
        retention.protect("publication", setOf(first))

        shouldThrow<IllegalStateException> { retention.protect("publication", setOf(second)) }.message shouldBe
            "Publication bytes changed"
        retention.selected("publication")
        blobs.collectGarbage(emptySet())

        blobs.shouldHold(first)
        blobs.metadata(second) shouldBe BlobResult.NotFound
    }
}
