package com.typewritermc.loader.artifact.testing

import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult

/** [this] endpoint, except that it describes every blob as [metadata] and, unless [fetchable], refuses to serve bytes. */
fun BlobEndpoint.describing(
    metadata: BlobMetadata,
    fetchable: Boolean = true,
): BlobEndpoint =
    object : BlobEndpoint by this {
        override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> = BlobResult.Success(metadata)

        override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
            if (fetchable) this@describing.fetch(digest) else error("The artifact bytes must not be fetched.")
    }
