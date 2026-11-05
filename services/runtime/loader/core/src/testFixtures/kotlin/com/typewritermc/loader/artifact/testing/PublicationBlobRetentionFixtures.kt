package com.typewritermc.loader.artifact.testing

import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.requireStored
import io.kotest.matchers.types.shouldBeInstanceOf
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.FileTime
import java.time.Instant

/** Stores [content] and backdates it past the collection grace period. */
suspend fun FileDigestBlobStore.storeAged(content: ByteArray): ArtifactDigest {
    val digest = store(BlobMetadata(ArtifactDigest.sha256(content), content.size.toLong()), content).requireStored().digest
    Files.setLastModifiedTime(pathFor(digest), FileTime.from(Instant.EPOCH))
    return digest
}

suspend fun FileDigestBlobStore.shouldHold(digest: ArtifactDigest) {
    metadata(digest).shouldBeInstanceOf<BlobResult.Success<*>>()
}

fun Path.ledger(): Path = resolve("publication-pins.cbor")
