package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledShardPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.api.artifact.TransferId
import kotlinx.serialization.json.Json

/**
 * Stores serialized manifest and shard bytes before their activation is published.
 *
 * The returned pointers must address complete immutable blobs. Storage alone does not advance the active compiled
 * manifest.
 */
fun interface CompiledArtifactPublisher {
    suspend fun store(
        activationRevision: Long,
        manifest: CompiledManifest,
        shards: List<CompiledPageShard>,
    ): CompiledContentActivation
}

/**
 * Writes compiled JSON payloads into digest addressed blob storage and returns activation pointers.
 *
 * Semantic manifest and shard identities remain distinct from serialized blob digests. Existing blobs are reused;
 * failures propagate before repository activation, potentially leaving reusable unreferenced bytes.
 */
class CompiledArtifactStore(
    private val blobs: BlobEndpoint,
) : CompiledArtifactPublisher {
    override suspend fun store(
        activationRevision: Long,
        manifest: CompiledManifest,
        shards: List<CompiledPageShard>,
    ): CompiledContentActivation {
        val manifestBlob = write(json.encodeToString(CompiledManifest.serializer(), manifest).encodeToByteArray())
        val shardBlobs =
            shards.map { shard ->
                CompiledShardPointer(
                    shard = shard.digest,
                    blob = write(json.encodeToString(CompiledPageShard.serializer(), shard).encodeToByteArray()),
                )
            }
        return CompiledContentActivation(activationRevision, manifest.digest, manifestBlob, shardBlobs)
    }

    private suspend fun write(bytes: ByteArray): CompiledBlobPointer {
        val digest = ArtifactDigest.sha256(bytes)
        val expected = BlobMetadata(digest, bytes.size.toLong())
        when (val existing = blobs.metadata(digest)) {
            is BlobResult.Success -> return existing.value.pointer()
            BlobResult.NotFound -> Unit
            is BlobResult.Conflict -> error(existing.reason)
            is BlobResult.Invalid -> error(existing.reason)
        }
        val transfer = TransferId.create()
        val session = blobs.beginWrite(transfer, expected).success("begin compiled blob write")
        var offset = session.offset
        while (offset < bytes.size) {
            val end = minOf(bytes.size, offset.toInt() + DEFAULT_CHUNK_SIZE)
            offset = blobs.write(transfer, offset, bytes.copyOfRange(offset.toInt(), end)).success("write compiled blob")
        }
        return blobs.complete(transfer).success("complete compiled blob write").pointer()
    }
}

private fun BlobMetadata.pointer() = CompiledBlobPointer(ContentDigest(digest.value), size)

private fun <T> BlobResult<T>.success(operation: String): T =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("$operation failed because the blob was not found.")
        is BlobResult.Conflict -> error("$operation failed: $reason")
        is BlobResult.Invalid -> error("$operation failed: $reason")
    }

private val json = Json { encodeDefaults = true }
