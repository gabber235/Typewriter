package com.typewritermc.engine

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.DataPath
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.authoring.ResourceDefinitionId
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
    val rootType: ResolvedTypeRef,
    val valueWithSlots: DataValue,
)

@Serializable
sealed interface CompiledEdgeOrigin {
    @Serializable
    @SerialName("declared")
    data class Declared(
        val relation: RelationId,
        val sourceIndex: Int? = null,
        val targetIndex: Int? = null,
    ) : CompiledEdgeOrigin

    @Serializable
    @SerialName("reference")
    data class Reference(
        val slot: ReferenceSlotId,
        val path: DataPath,
        val expectedType: TypeExpression,
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

/** A Page rooted typed graph with owned records and incident links. */
@Serializable
data class CompiledPageShard(
    val formatRevision: Int,
    val digest: ContentDigest,
    val inputFingerprint: ContentDigest,
    val root: CompiledResourceKey,
    val resources: List<CompiledResource>,
    val edges: List<CompiledEdge>,
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
    ) : PageCompileResult

    /** A page that produced no publishable shard and retains the input state that generated its diagnostics. */
    @Serializable
    @SerialName("blocked")
    data class Blocked(
        val inputFingerprint: ContentDigest,
        val diagnostics: List<CompileDiagnostic>,
    ) : PageCompileResult
}
