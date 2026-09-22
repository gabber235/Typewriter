package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactPointer
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.api.artifact.TransferId
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/** Stores generic manifest and projection owned payloads without interpreting their media type. */
class RegisteredCompiledArtifactStore(
    private val blobs: BlobEndpoint,
) {
    suspend fun store(
        activationRevision: Long,
        manifest: CompiledArtifactManifest,
        artifacts: Collection<CompiledArtifact>,
        previousActivation: CompiledArtifactActivation?,
    ): CompiledArtifactActivation {
        val manifestBlob = write(json.encodeToString(manifest).encodeToByteArray())
        val freshPointers =
            artifacts
                .groupBy(CompiledArtifact::semanticDigest)
                .map { (semanticDigest, matching) ->
                    val artifact = matching.first()
                    require(matching.all { it.payload.contentEquals(artifact.payload) }) {
                        "Compiled artifacts with semantic digest ${semanticDigest.value} must have identical payloads."
                    }
                    CompiledArtifactPointer(
                        semanticDigest = semanticDigest,
                        blob = write(artifact.payload),
                    )
                }
        val availablePointers =
            (previousActivation?.artifacts.orEmpty() + freshPointers)
                .associateBy(CompiledArtifactPointer::semanticDigest)
        val requiredDigests = manifest.artifacts.mapTo(linkedSetOf(), CompiledArtifactReference::semanticDigest)
        require(requiredDigests.all(availablePointers::containsKey)) {
            "Compiled activation is missing preserved artifact payloads."
        }
        val artifactPointers = requiredDigests.map(availablePointers::getValue)
        return CompiledArtifactActivation(
            activationRevision = activationRevision,
            manifestDigest = manifest.digest,
            manifest = manifestBlob,
            artifacts = artifactPointers,
        )
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
        val session = blobs.beginWrite(transfer, expected).success("begin compiled artifact write")
        var offset = session.offset
        while (offset < bytes.size) {
            val end = minOf(bytes.size, offset.toInt() + DEFAULT_CHUNK_SIZE)
            offset = blobs.write(transfer, offset, bytes.copyOfRange(offset.toInt(), end)).success("write compiled artifact")
        }
        return blobs.complete(transfer).success("complete compiled artifact write").pointer()
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
