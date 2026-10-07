package com.typewritermc.engine

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

/** Identifies the compiler that owns one compiled artifact format. */
@JvmInline
@Serializable
value class CompilationProjectionId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Compilation projection ids must not be blank." }
    }
}

/** Identifies one compiled root without knowing the domain represented by that root. */
@Serializable
data class CompilationRoot(
    val projection: CompilationProjectionId,
    val resource: ResourceId,
)

/** Describes an immutable compiled payload before it is written to blob storage. */
@Serializable
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

/** References an immutable artifact from a published output. */
@Serializable
data class CompiledArtifactReference(
    val root: CompilationRoot,
    val formatRevision: Int,
    val mediaType: String,
    val semanticDigest: ContentDigest,
)

/** Pairs a compiled root descriptor with its verified opaque payload location. */
@Serializable
data class PublishedOutput(
    val reference: CompiledArtifactReference,
    val blob: CompiledBlobPointer,
)

/** Describes the complete output set selected by one successful publication. */
@Serializable
data class PublishedContent(
    val publication: PublicationId,
    val formatRevision: Int,
    val catalog: CatalogGeneration,
    val implementationToken: String,
    val runtimeSignatures: Set<RuntimeMemberSignature>,
    val outputs: List<PublishedOutput>,
) {
    init {
        require(outputs.map { it.reference.root }.distinct().size == outputs.size) {
            "Published content must not contain duplicate roots."
        }
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
        val diagnostics: List<CompileDiagnostic>,
    ) : CompilationResult
}
