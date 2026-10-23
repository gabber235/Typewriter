package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobChunk
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.BlobWriteSession
import com.typewritermc.services.libs.filetransfer.blob.TransferId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId
import skirout.kernel.v1.resource_id.ResourceId

val RegisteredCompiledArtifactStoreTest by testSuite {
    test("publication outputs are complete and reuse verified payload blobs") {
        val blobs = InMemoryBlobEndpoint()
        val store = RegisteredCompiledArtifactStore(blobs, TestPublicationRetention())
        val firstArtifact = 'a'.compiledArtifact("first")
        val first =
            store.store(
                PublicationId(value = "first"),
                CatalogGeneration(value = "catalog"),
                "implementation",
                listOf(firstArtifact),
            )
        val second =
            store.store(
                PublicationId(value = "second"),
                CatalogGeneration(value = "catalog"),
                "implementation",
                listOf(firstArtifact),
            )
        first.outputs.single().blob shouldBe second.outputs.single().blob
        val replacement = 'b'.compiledArtifact("replacement")
        val third = store.store(PublicationId(value = "third"), CatalogGeneration(value = "catalog"), "implementation", listOf(replacement))
        third.outputs.map { it.reference.root } shouldBe listOf(replacement.root)
        third.publication shouldBe PublicationId(value = "third")
        third.formatRevision shouldBe com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
        val empty = store.store(PublicationId(value = "empty"), CatalogGeneration(value = "catalog"), "implementation", emptyList())
        empty.outputs shouldBe emptyList()
    }
    test("unchanged selected output restores missing exact bytes without a new publication") {
        val blobs = InMemoryBlobEndpoint()
        val pins = TestPublicationRetention()
        val store = RegisteredCompiledArtifactStore(blobs, pins)
        val artifact = 'a'.compiledArtifact("root")
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
        val artifact = 'a'.compiledArtifact("root")
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
        shouldThrow<IllegalStateException> { store.restoreSelected(selected, listOf(artifact.copy(payload = byteArrayOf(2)))) }
        blobs.metadata(digest) shouldBe BlobResult.NotFound
    }
}

private fun Char.compiledArtifact(resource: String) =
    CompiledArtifact(
        root = CompilationRoot(projection = CompilationProjectionId(value = "test.projection"), resource = ResourceId(value = resource)),
        formatRevision = 1,
        mediaType = "application/vnd.typewriter.test",
        inputFingerprint = ContentDigest(toString().repeat(64)),
        semanticDigest = ContentDigest(toString().repeat(64)),
        payload = byteArrayOf(code.toByte()),
    )

internal class InMemoryBlobEndpoint : BlobEndpoint {
    private data class PendingWrite(
        val expected: BlobMetadata,
        var bytes: ByteArray = byteArrayOf(),
    )

    private val blobs = mutableMapOf<ArtifactDigest, ByteArray>()
    private val writes = mutableMapOf<TransferId, PendingWrite>()

    fun remove(digest: ArtifactDigest) {
        blobs.remove(digest)
    }

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        blobs[digest]?.let { BlobResult.Success(BlobMetadata(digest, it.size.toLong())) } ?: BlobResult.NotFound

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> {
        val bytes = blobs[digest] ?: return BlobResult.NotFound
        val start = offset.toInt()
        val end = minOf(bytes.size, start + maximumBytes)
        return BlobResult.Success(BlobChunk(offset, bytes.copyOfRange(start, end), end == bytes.size))
    }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> {
        val existing = blobs[expected.digest]
        if (existing != null) return BlobResult.Success(BlobWriteSession(transfer, expected, existing.size.toLong()))
        val pending = writes.getOrPut(transfer) { PendingWrite(expected) }
        return BlobResult.Success(BlobWriteSession(transfer, expected, pending.bytes.size.toLong()))
    }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> {
        val pending = writes[transfer] ?: return BlobResult.NotFound
        if (offset != pending.bytes.size.toLong()) return BlobResult.Conflict("Unexpected write offset.")
        pending.bytes += bytes
        return BlobResult.Success(pending.bytes.size.toLong())
    }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> {
        val pending = writes.remove(transfer) ?: return BlobResult.NotFound
        if (pending.bytes.size.toLong() != pending.expected.size) return BlobResult.Invalid("Unexpected blob size.")
        if (ArtifactDigest.sha256(pending.bytes) != pending.expected.digest) {
            return BlobResult.Invalid("Unexpected blob digest.")
        }
        blobs[pending.expected.digest] = pending.bytes
        return BlobResult.Success(pending.expected)
    }
}

internal class TestPublicationRetention : com.typewritermc.loader.api.artifact.PublicationBlobRetention {
    val publications = mutableMapOf<String, Set<ArtifactDigest>>()
    var selected: String? = null

    override suspend fun protect(
        publication: String,
        digests: Set<ArtifactDigest>,
    ) {
        check(publications[publication]?.let { it == digests } != false)
        publications[publication] = digests
    }

    override suspend fun selected(publication: String) {
        check(publication in publications)
        selected = publication
    }

    override suspend fun reconcile(selected: com.typewritermc.loader.api.artifact.PublicationBlobRoots?) {
        publications.clear()
        this.selected = selected?.publication
        selected?.let { publications[it.publication] = it.digests }
    }
}
