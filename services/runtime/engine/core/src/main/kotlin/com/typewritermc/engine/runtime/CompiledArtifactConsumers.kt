package com.typewritermc.engine.runtime

import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PublishedContent
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.api.artifact.DigestAlgorithm
import java.io.ByteArrayOutputStream

/** Contributes every artifact for one projection and media type to an atomic engine content snapshot. */
interface CompiledArtifactConsumer {
    val projection: com.typewritermc.engine.CompilationProjectionId
    val mediaType: String

    fun contribute(
        artifacts: List<LoadedCompiledArtifact>,
        target: EngineContentBuilder,
    )
}

/** Dispatches opaque artifacts to exactly one registered consumer before publishing any contributed state. */
class CompiledArtifactConsumerRegistry(
    consumers: Collection<CompiledArtifactConsumer>,
) {
    private val consumersByKey =
        consumers.associateBy { it.projection to it.mediaType }.also { values ->
            require(values.size == consumers.size) {
                "Compiled artifact consumers must have unique projection and media type pairs."
            }
        }

    fun contribute(
        content: LoadedPublishedContent,
        target: EngineContentBuilder,
    ) {
        val grouped =
            content.artifacts.groupBy { artifact ->
                requireNotNull(consumersByKey[artifact.reference.root.projection to artifact.reference.mediaType]) {
                    "No compiled artifact consumer for ${artifact.reference.root.projection.value} and " +
                        "${artifact.reference.mediaType}."
                }
            }
        grouped.forEach { (consumer, artifacts) -> consumer.contribute(artifacts, target) }
    }
}

/** Loads and verifies generic compiled artifacts while leaving their payloads opaque. */
class BlobCompiledArtifactSource(
    private val blobs: BlobEndpoint,
) {
    suspend fun load(content: PublishedContent): LoadedPublishedContent =
        LoadedPublishedContent(
            content,
            content.outputs.map { output -> LoadedCompiledArtifact(output.reference, read(output.blob)) },
        )

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
