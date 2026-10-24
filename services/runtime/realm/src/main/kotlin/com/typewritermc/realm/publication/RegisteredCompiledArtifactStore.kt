package com.typewritermc.realm.publication

import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.engine.requireValid
import com.typewritermc.loader.api.artifact.PublicationBlobRetention
import com.typewritermc.loader.api.artifact.PublicationBlobRoots
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.requireStored
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId

/** Writes protected publication payloads and repairs missing selected bytes only when reproduced exactly. */
class RegisteredCompiledArtifactStore(
    private val blobs: BlobEndpoint,
    private val retention: PublicationBlobRetention,
) {
    suspend fun store(
        publication: PublicationId,
        catalog: CatalogGeneration,
        implementationToken: String,
        artifacts: Collection<CompiledArtifact>,
    ): PublishedContent {
        val sources = artifacts.map { it to it.payload.blobMetadata() }
        retention.protect(publication.value, sources.mapTo(linkedSetOf()) { it.second.digest })
        val outputs =
            sources.map { (artifact, metadata) ->
                PublishedOutput(
                    reference =
                        CompiledArtifactReference(
                            root = artifact.root,
                            formatRevision = artifact.formatRevision,
                            mediaType = artifact.mediaType,
                            semanticDigest = artifact.semanticDigest.value,
                        ),
                    blob = blobs.storeVerified(metadata, artifact.payload).pointer(),
                )
            }
        return PublishedContent(
            publication = publication,
            formatRevision = PUBLISHED_CONTENT_FORMAT_REVISION,
            catalog = catalog,
            implementationToken = implementationToken,
            outputs = outputs,
        ).requireValid()
    }

    suspend fun selected(content: PublishedContent) = retention.selected(content.publication.value)

    suspend fun reconcile(content: PublishedContent?) =
        retention.reconcile(
            content?.let {
                PublicationBlobRoots(
                    it.publication.value,
                    it.outputs.mapTo(linkedSetOf()) { output -> output.blob.digest.artifactDigest() },
                )
            },
        )

    // Called only for a fully successful, semantically unchanged assessment.
    suspend fun restoreSelected(
        content: PublishedContent,
        compiled: List<CompiledArtifact>,
    ) {
        val expected = content.outputs.associateBy { it.reference.root }
        check(expected.size == content.outputs.size)
        val roots = compiled.map { it.root }
        check(roots.size == roots.toSet().size && roots.toSet() == expected.keys)
        val missing =
            compiled.mapNotNull { artifact ->
                val output = expected.getValue(artifact.root)
                val reference =
                    CompiledArtifactReference(
                        root = artifact.root,
                        formatRevision = artifact.formatRevision,
                        mediaType = artifact.mediaType,
                        semanticDigest = artifact.semanticDigest.value,
                    )
                check(output.reference == reference)
                val digest = output.blob.digest.artifactDigest()
                when (val metadata = blobs.metadata(digest)) {
                    is BlobResult.Success -> {
                        check(metadata.value == BlobMetadata(digest, output.blob.size)) {
                            "Selected blob metadata disagrees with its descriptor"
                        }
                        null
                    }

                    BlobResult.NotFound -> {
                        val rebuilt = artifact.payload.blobMetadata()
                        check(rebuilt == BlobMetadata(digest, output.blob.size)) {
                            "Missing selected publication bytes cannot be rebuilt identically"
                        }
                        rebuilt to artifact.payload
                    }

                    is BlobResult.Invalid -> {
                        error(metadata.reason)
                    }
                }
            }
        // Read metadata and validate all missing replacements before any writes.
        // Existing selected roots stay in place throughout repair.
        for ((metadata, payload) in missing) blobs.storeVerified(metadata, payload)
    }
}

private fun String.artifactDigest() = ArtifactDigest(DigestAlgorithm.SHA_256, this)

private fun BlobMetadata.pointer() = CompiledBlobPointer(digest = digest.value, size = size)

private fun ByteArray.blobMetadata() = BlobMetadata(ArtifactDigest.sha256(this), size.toLong())

/**
 * Stores [content] unless the endpoint already holds it, so unchanged outputs never travel again. Compiled payloads
 * are produced locally, so a rejected store is a bug and fails with the store's reason.
 */
private suspend fun BlobEndpoint.storeVerified(
    expected: BlobMetadata,
    content: ByteArray,
): BlobMetadata {
    when (val present = metadata(expected.digest)) {
        is BlobResult.Success -> {
            check(present.value == expected) { "Stored blob metadata disagrees with its content" }
            return present.value
        }

        BlobResult.NotFound -> {}

        is BlobResult.Invalid -> {
            error(present.reason)
        }
    }
    return store(expected, content).requireStored()
}
