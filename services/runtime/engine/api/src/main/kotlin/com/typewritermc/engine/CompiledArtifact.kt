package com.typewritermc.engine

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

/** References an immutable artifact from a compiled manifest. */
@Serializable
data class CompiledArtifactReference(
    val root: CompilationRoot,
    val formatRevision: Int,
    val mediaType: String,
    val semanticDigest: ContentDigest,
)

/** Lists the immutable artifact descriptors active for one source revision. */
@Serializable
data class CompiledArtifactManifest(
    val formatRevision: Int,
    val digest: ContentDigest,
    val sourceRevision: String,
    val catalogRevision: String,
    val artifacts: List<CompiledArtifactReference>,
) {
    init {
        require(artifacts.map(CompiledArtifactReference::root).distinct().size == artifacts.size) {
            "Compiled artifact manifests must not contain duplicate roots."
        }
    }
}

/** Points to the serialized manifest and each opaque artifact payload for one activation. */
@Serializable
data class CompiledArtifactActivation(
    val activationRevision: Long,
    val manifestDigest: ContentDigest,
    val manifest: CompiledBlobPointer,
    val artifacts: List<CompiledArtifactPointer>,
) {
    init {
        require(activationRevision > 0) { "Compiled artifact activation revisions must be positive." }
        require(artifacts.map(CompiledArtifactPointer::semanticDigest).distinct().size == artifacts.size) {
            "Compiled artifact activations must not contain duplicate artifacts."
        }
    }
}

/** Points to one immutable opaque artifact payload. */
@Serializable
data class CompiledArtifactPointer(
    val semanticDigest: ContentDigest,
    val blob: CompiledBlobPointer,
)

/** Carries a verified payload and its manifest descriptor to a registered runtime consumer. */
data class LoadedCompiledArtifact(
    val reference: CompiledArtifactReference,
    val payload: ByteArray,
)

/** Generic loaded activation. Payload meaning remains behind consumer registration. */
data class LoadedCompiledContent(
    val activationRevision: Long,
    val manifest: CompiledArtifactManifest,
    val artifacts: List<LoadedCompiledArtifact>,
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
