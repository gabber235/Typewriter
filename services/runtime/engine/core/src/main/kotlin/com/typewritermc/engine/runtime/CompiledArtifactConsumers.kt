package com.typewritermc.engine.runtime

import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedCompiledContent
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.api.artifact.DigestAlgorithm
import kotlinx.serialization.json.Json
import java.io.ByteArrayOutputStream

/** Decodes one projection and media type without leaking its payload model into generic delivery. */
interface CompiledArtifactConsumer<out Value : Any> {
    val projection: com.typewritermc.engine.CompilationProjectionId
    val mediaType: String

    fun decode(
        reference: CompiledArtifactReference,
        payload: ByteArray,
    ): Value
}

/** Dispatches opaque artifact descriptors to exactly one registered consumer. */
class CompiledArtifactConsumerRegistry(
    consumers: Collection<CompiledArtifactConsumer<*>>,
) {
    private val consumersByKey =
        consumers.associateBy { it.projection to it.mediaType }.also { values ->
            require(values.size == consumers.size) {
                "Compiled artifact consumers must have unique projection and media type pairs."
            }
        }

    fun decode(
        reference: CompiledArtifactReference,
        payload: ByteArray,
    ): Any =
        requireNotNull(consumersByKey[reference.root.projection to reference.mediaType]) {
            "No compiled artifact consumer for ${reference.root.projection.value} and ${reference.mediaType}."
        }.decode(reference, payload)
}

/** Loads and verifies generic compiled artifacts while leaving their payloads opaque. */
class BlobCompiledArtifactSource(
    private val blobs: BlobEndpoint,
) {
    suspend fun load(activation: CompiledArtifactActivation): LoadedCompiledContent {
        val manifest =
            json.decodeFromString(
                com.typewritermc.engine.CompiledArtifactManifest
                    .serializer(),
                read(activation.manifest).decodeToString(),
            )
        require(manifest.digest == activation.manifestDigest) {
            "Compiled artifact manifest identity does not match activation."
        }
        val pointers = activation.artifacts.associateBy { it.semanticDigest }
        require(pointers.keys == manifest.artifacts.mapTo(linkedSetOf(), CompiledArtifactReference::semanticDigest)) {
            "Compiled artifact activation does not match its manifest."
        }
        val artifacts =
            manifest.artifacts.map { reference ->
                val pointer =
                    requireNotNull(pointers[reference.semanticDigest]) {
                        "Activation is missing artifact ${reference.semanticDigest.value}."
                    }
                LoadedCompiledArtifact(reference, read(pointer.blob))
            }
        return LoadedCompiledContent(activation.activationRevision, manifest, artifacts)
    }

    private suspend fun read(pointer: CompiledBlobPointer): ByteArray {
        require(pointer.size <= Int.MAX_VALUE) { "Compiled blob is too large to buffer." }
        val expected = ArtifactDigest(DigestAlgorithm.SHA_256, pointer.digest.value)
        val metadata = blobs.metadata(expected).success("read compiled blob metadata")
        require(metadata.size == pointer.size) { "Compiled blob size does not match its descriptor." }
        val output = ByteArrayOutputStream(pointer.size.toInt())
        var offset = 0L
        var complete = pointer.size == 0L
        while (offset < pointer.size) {
            val chunk = blobs.read(expected, offset, DEFAULT_CHUNK_SIZE).success("read compiled blob")
            require(chunk.offset == offset) { "Compiled blob returned a noncontiguous chunk." }
            require(chunk.bytes.isNotEmpty()) { "Compiled blob ended before its declared size." }
            require(chunk.bytes.size.toLong() <= pointer.size - offset) {
                "Compiled blob exceeded its declared size."
            }
            output.write(chunk.bytes)
            offset += chunk.bytes.size
            require(!chunk.complete || offset == pointer.size) { "Compiled blob ended before its declared size." }
            complete = chunk.complete
        }
        require(complete) { "Compiled blob did not mark its final chunk complete." }
        val bytes = output.toByteArray()
        require(ArtifactDigest.sha256(bytes) == expected) { "Compiled blob digest verification failed." }
        return bytes
    }
}

private fun <T> BlobResult<T>.success(operation: String): T =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("$operation failed because the blob was not found.")
        is BlobResult.Conflict -> error("$operation failed: $reason")
        is BlobResult.Invalid -> error("$operation failed: $reason")
    }

private val json = Json { ignoreUnknownKeys = true }
