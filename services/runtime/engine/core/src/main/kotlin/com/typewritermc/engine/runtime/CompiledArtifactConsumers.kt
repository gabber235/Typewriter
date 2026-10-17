package com.typewritermc.engine.runtime

import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PublishedContent
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.readVerified

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
            content.outputs.map { output ->
                LoadedCompiledArtifact(
                    output.reference,
                    blobs.readVerified(output.blob.digest.asArtifactDigest(), output.blob.size),
                )
            },
        )
}

private fun ContentDigest.asArtifactDigest(): ArtifactDigest = ArtifactDigest(DigestAlgorithm.SHA_256, value)
