package com.typewritermc.engine

import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.diagnostic.Diagnostic

const val PUBLISHED_CONTENT_FORMAT_REVISION = 1

/*
 * Compiled roots, artifact references, blob pointers and published content descriptors are the generated Skir
 * CompilationRoot, CompiledArtifactReference, CompiledBlobPointer, PublishedOutput and PublishedContent. A published
 * content descriptor is the complete runtime output set selected by one successful Realm publication: it couples
 * immutable blob locations to their semantic artifact identities and the engine implementation that can consume them.
 * Engines fetch and verify every output before applying the set. Its catalog identifies the authoring catalog used to
 * compile it; runtime admission separately checks the declarations and native bindings used by each artifact against
 * the accepted execution catalog. The requireValid checks below run where descriptors enter: from the wire, from
 * storage and when the Realm assembles a publication.
 */

/** Requires a non blank projection and resource. */
fun CompilationRoot.requireValid(): CompilationRoot =
    apply {
        require(projection.value.isNotBlank()) { "Compilation projection ids must not be blank." }
        require(resource.value.isNotBlank()) { "Resource ids must not be blank." }
    }

/** Requires a valid root and a canonical semantic digest. */
fun CompiledArtifactReference.requireValid(): CompiledArtifactReference =
    apply {
        root.requireValid()
        requireContentDigest(semanticDigest)
    }

/** Requires a canonical digest and a size that is not negative; readers verify both before decoding the payload. */
fun CompiledBlobPointer.requireValid(): CompiledBlobPointer =
    apply {
        requireContentDigest(digest)
        require(size >= 0) { "Compiled blob size must not be negative." }
    }

/** Requires valid outputs with distinct roots. */
fun PublishedContent.requireValid(): PublishedContent =
    apply {
        outputs.forEach { output ->
            output.reference.requireValid()
            output.blob.requireValid()
        }
        require(outputs.map { it.reference.root }.distinct().size == outputs.size) {
            "Published content must not contain duplicate roots."
        }
    }

/** Describes an immutable compiled payload before it is written to blob storage. */
data class CompiledArtifact(
    val root: CompilationRoot,
    val formatRevision: Int,
    val mediaType: String,
    val inputFingerprint: ContentDigest,
    val semanticDigest: ContentDigest,
    val payload: ByteArray,
) {
    init {
        require(formatRevision > 0) { "Compiled artifact format revisions must be positive." }
        require(mediaType.isNotBlank()) { "Compiled artifact media types must not be blank." }
    }
}

/** Carries a complete descriptor and verified payloads to the registered engine consumers. */
data class LoadedPublishedContent(
    val descriptor: PublishedContent,
    val artifacts: List<LoadedCompiledArtifact>,
)

/** Carries a verified payload and its published descriptor to a registered runtime consumer. */
data class LoadedCompiledArtifact(
    val reference: CompiledArtifactReference,
    val payload: ByteArray,
)

/** Represents the result of compiling one registered root. */
sealed interface CompilationResult {
    val root: CompilationRoot

    data class Success(
        val artifact: CompiledArtifact,
    ) : CompilationResult {
        override val root: CompilationRoot
            get() = artifact.root
    }

    data class Removed(
        override val root: CompilationRoot,
    ) : CompilationResult

    data class Blocked(
        override val root: CompilationRoot,
        val inputFingerprint: ContentDigest,
        val diagnostics: List<Diagnostic>,
    ) : CompilationResult
}
