package com.typewritermc.services.libs.filetransfer.blob

import com.typewritermc.services.libs.filetransfer.ByteTransferChunk
import com.typewritermc.services.libs.filetransfer.SequentialByteTransfer
import java.io.ByteArrayOutputStream

/** Reads bounded bytes and verifies metadata, completion, size, and digest. */
suspend fun BlobEndpoint.readVerified(
    digest: ArtifactDigest,
    expectedSize: Long,
    maximumSize: Long = MAXIMUM_BLOB_SIZE,
): ByteArray {
    require(expectedSize in 0..minOf(maximumSize, Int.MAX_VALUE.toLong()))
    val metadata = metadata(digest).requireValue()
    require(metadata.digest == digest && metadata.size == expectedSize)
    val output = ByteArrayOutputStream(expectedSize.toInt())
    SequentialByteTransfer().copy(
        expectedSize,
        0,
        read = { offset, maximum ->
            val chunk = read(digest, offset, maximum).requireValue()
            ByteTransferChunk(chunk.offset, chunk.bytes, chunk.complete)
        },
        write = { offset, chunk ->
            output.write(chunk)
            offset + chunk.size
        },
    )
    return output.toByteArray().also { bytes ->
        require(bytes.size.toLong() == expectedSize && ArtifactDigest.sha256(bytes) == digest)
    }
}
