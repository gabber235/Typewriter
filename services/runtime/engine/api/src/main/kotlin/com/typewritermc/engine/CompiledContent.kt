package com.typewritermc.engine

import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ValuePath
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeUse
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Distinguishes one generated occurrence of an authored resource. */
@Serializable
data class InstancePath(
    val segments: List<String>,
) {
    companion object {
        val Root = InstancePath(emptyList())
    }
}

@Serializable
data class CompilationContext(
    val instancePath: InstancePath,
) {
    companion object {
        val Root = CompilationContext(InstancePath.Root)
    }
}

/** Identifies a resource in a compiled occurrence. */
@Serializable
data class CompiledResourceKey(
    val source: ResourceId,
    val context: CompilationContext,
)

/** Retains the typed scalar record before graph hydration. */
@Serializable
data class CompiledResource(
    val key: CompiledResourceKey,
    val definition: ResourceDefinitionId,
    val actualType: TypeUse.Named,
    val bindingProvider: NativeBindingId,
    val bindingSignature: String,
    val value: DataValue.Named,
)

@Serializable
sealed interface CompiledEdgeOrigin {
    @Serializable
    @SerialName("relation")
    data class Relation(
        val relation: RelationId,
        val firstLocation: ValuePath?,
        val secondLocation: ValuePath?,
    ) : CompiledEdgeOrigin
}

/** A link between compiled keys, including keys outside this shard. */
@Serializable
data class CompiledEdge(
    val source: CompiledResourceKey,
    val target: CompiledResourceKey,
    val origin: CompiledEdgeOrigin,
)

/**
 * Identifies compiled content using 64 lowercase SHA256 hexadecimal characters.
 *
 * Compiled semantic identities and serialized blob digests use the same shape but may represent different bytes.
 * Consult the containing pointer before fetching content.
 */
@JvmInline
@Serializable
value class ContentDigest(
    val value: String,
) {
    init {
        require(value.matches(Regex("[0-9a-f]{64}"))) { "Content digests must be lowercase SHA256 values." }
    }
}

@Serializable
data class RuntimeRelationFact(
    val relation: RelationId,
    val ownsResources: Boolean,
)

@Serializable
data class RuntimeCompilationFacts(
    val formatRevision: Int,
    val root: CompiledResourceKey,
    val resources: List<CompiledResource>,
    val edges: List<CompiledEdge>,
    val types: List<TypeDefinition>,
    val relations: List<RuntimeRelationFact>,
)

/** A canonical Page rooted graph and its semantic identity. */
@Serializable
data class CompiledPageShard(
    val digest: ContentDigest,
    val facts: RuntimeCompilationFacts,
)

/**
 * Addresses serialized compiled bytes by digest and exact size in bytes.
 *
 * Size must be nonnegative. Readers verify both size and digest before decoding the payload.
 */
@Serializable
data class CompiledBlobPointer(
    val digest: ContentDigest,
    val size: Long,
) {
    init {
        require(size >= 0) { "Compiled blob size must not be negative." }
    }
}

/** Classifies whether a compilation diagnostic blocks publication. */
@Serializable
enum class CompileDiagnosticSeverity {
    /** A compiler condition that prevents the affected output from being published. */
    ERROR,

    /** A compiler condition that is reported without blocking publication. */
    WARNING,
}

/**
 * Records a stable compiler finding for authoring or deployment consumers.
 *
 * [source] and [target] are optional because some findings describe the compilation as a whole. The code is the
 * machine readable category; [message] is diagnostic context rather than a recovery instruction.
 */
@Serializable
data class CompileDiagnostic(
    val code: String,
    val message: String,
    val severity: CompileDiagnosticSeverity,
    val source: ResourceId? = null,
    val target: ResourceId? = null,
)

/**
 * Returns a reusable page shard or diagnostics that block publication of that page.
 *
 * Blocked output retains its input fingerprint so the coordinator can track which authoring state failed.
 */
@Serializable
sealed interface PageCompileResult {
    /** A complete shard that may be reused or included in a publication. */
    @Serializable
    @SerialName("success")
    data class Success(
        val shard: CompiledPageShard,
        val inputFingerprint: ContentDigest,
    ) : PageCompileResult

    /** A page that produced no publishable shard and retains the input state that generated its diagnostics. */
    @Serializable
    @SerialName("blocked")
    data class Blocked(
        val inputFingerprint: ContentDigest,
        val diagnostics: List<CompileDiagnostic>,
    ) : PageCompileResult
}
