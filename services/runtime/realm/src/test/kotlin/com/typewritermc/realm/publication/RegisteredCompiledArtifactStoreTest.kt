package com.typewritermc.realm.publication

import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId

val RegisteredCompiledArtifactStoreTest by testSuite {
    test("a payload stored for one publication is reused by the next without another upload") {
        val blobs = InMemoryBlobEndpoint()
        val store = RegisteredCompiledArtifactStore(blobs, TestPublicationRetention())
        val artifact = compiledArtifact(compilationRoot("test.projection", "first"))

        val first = store.store(PublicationId(value = "first"), CatalogGeneration(value = "catalog"), "implementation", listOf(artifact))
        val second = store.store(PublicationId(value = "second"), CatalogGeneration(value = "catalog"), "implementation", listOf(artifact))

        second.outputs.single().blob shouldBe first.outputs.single().blob
        blobs.stores shouldBe 1
    }
    test("a stored publication has one output for each compiled root, and none for no roots") {
        val store = RegisteredCompiledArtifactStore(InMemoryBlobEndpoint(), TestPublicationRetention())
        val replacement = compiledArtifact(compilationRoot("test.projection", "replacement"))

        val stored =
            store.store(
                PublicationId(value = "third"),
                CatalogGeneration(value = "catalog"),
                "implementation",
                listOf(replacement),
            )
        val empty = store.store(PublicationId(value = "empty"), CatalogGeneration(value = "catalog"), "implementation", emptyList())

        stored.publication shouldBe PublicationId(value = "third")
        stored.outputs.map { it.reference.root } shouldBe listOf(replacement.root)
        empty.outputs shouldBe emptyList()
    }
    test("unchanged selected output restores missing exact bytes without a new publication") {
        val blobs = InMemoryBlobEndpoint()
        val pins = TestPublicationRetention()
        val store = RegisteredCompiledArtifactStore(blobs, pins)
        val artifact = compiledArtifact(compilationRoot("test.projection", "root"))
        val selected =
            store.store(
                PublicationId(value = "selected"),
                CatalogGeneration(value = "catalog"),
                "implementation",
                listOf(artifact),
            )
        store.selected(selected)
        val digest =
            selected.outputs
                .single()
                .blob.digest
        blobs.remove(ArtifactDigest(com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256, digest))
        store.restoreSelected(selected, listOf(artifact))
        (
            blobs.metadata(
                ArtifactDigest(com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256, digest),
            ) is BlobResult.Success
        ) shouldBe
            true
        pins.selected shouldBe "selected"
    }
    test("missing selected output cannot be silently replaced by semantically equal different bytes") {
        val blobs = InMemoryBlobEndpoint()
        val store = RegisteredCompiledArtifactStore(blobs, TestPublicationRetention())
        val artifact = compiledArtifact(compilationRoot("test.projection", "root"))
        val selected =
            store.store(
                PublicationId(value = "selected"),
                CatalogGeneration(value = "catalog"),
                "implementation",
                listOf(artifact),
            )
        val digest =
            ArtifactDigest(
                com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256,
                selected.outputs
                    .single()
                    .blob.digest,
            )
        blobs.remove(digest)
        shouldThrow<IllegalStateException> {
            store.restoreSelected(
                selected,
                listOf(artifact.copy(payload = byteArrayOf(2))),
            )
        }.message shouldBe
            "Missing selected publication bytes cannot be rebuilt identically"
        blobs.metadata(digest) shouldBe BlobResult.NotFound
    }
}
