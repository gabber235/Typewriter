package com.typewritermc.engine

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.library.Page
import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Identifies the authored source of compiled content independently of its expansion context.
 *
 * A source can appear in more than one compiled instance; use [CompiledElementKey] when indexing runtime elements.
 */
@Serializable
data class SourceElementKey(
    val element: Ref<Element>,
)

/**
 * Distinguishes an instance within compiled expansion using an ordered sequence of segments.
 *
 * [Root] represents content without an expansion path. Segment syntax is not validated by this value object.
 */
@Serializable
data class InstancePath(
    val segments: List<String>,
) {
    companion object {
        val Root = InstancePath(emptyList())
    }
}

/**
 * Carries the instance context that distinguishes compilations of the same authored source.
 *
 * The root context is used when no instancing path is required.
 */
@Serializable
data class CompilationContext(
    val instancePath: InstancePath,
) {
    companion object {
        val Root = CompilationContext(InstancePath.Root)
    }
}

/**
 * Identifies one compiled occurrence by source and compilation context.
 *
 * Runtime maps must use this complete key so expanded occurrences do not overwrite one another.
 */
@Serializable
data class CompiledElementKey(
    val source: SourceElementKey,
    val context: CompilationContext,
)

/**
 * Carries a logical element payload prepared for engine decoding.
 *
 * The source identity and schema revision retain authoring provenance, while [key] distinguishes compiled
 * occurrences. Values have already passed compiler projection; this data class does not repeat validation.
 */
@Serializable
data class CompiledElement(
    val key: CompiledElementKey,
    val sourceId: ElementInstanceId,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val name: String,
    val value: DataValue,
    val placement: CompiledPlacement,
)

/**
 * Retains placement information relevant to execution.
 *
 * Graph coordinates and dimensions are intentionally absent. Timeline placements retain track or frame positions;
 * these data classes do not validate scheduling bounds.
 */
@Serializable
sealed interface CompiledPlacement {
    @Serializable
    @SerialName("graph_v1")
    data object Graph : CompiledPlacement

    @Serializable
    @SerialName("timeline_entry_v1")
    data class TimelineEntry(
        val trackIndex: Int,
    ) : CompiledPlacement

    @Serializable
    @SerialName("timeline_segment_v1")
    data class TimelineSegment(
        val startFrame: Int,
        val endFrame: Int,
    ) : CompiledPlacement

    @Serializable
    @SerialName("timeline_keyframe_v1")
    data class TimelineKeyframe(
        val frame: Int,
    ) : CompiledPlacement
}

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

/**
 * Packages the compiled elements of one page with its semantic digest and input fingerprint.
 *
 * The fingerprint supports reuse when compiler inputs are unchanged. The shard digest identifies compiled output;
 * the blob pointer separately identifies its serialized bytes.
 */
@Serializable
data class CompiledPageShard(
    val formatRevision: Int,
    val digest: ContentDigest,
    val inputFingerprint: ContentDigest,
    val page: Ref<Page>,
    val elements: List<CompiledElement>,
)

@Serializable
data class CompiledPageReference(
    val page: Ref<Page>,
    val shard: ContentDigest,
)

/**
 * Selects the page shards forming one compiled content revision.
 *
 * Source and catalog revisions record compilation inputs. The manifest is metadata, so loading requires the
 * referenced shards and validation of their page identities.
 */
@Serializable
data class CompiledManifest(
    val formatRevision: Int,
    val digest: ContentDigest,
    val sourceRevision: String,
    val catalogRevision: String,
    val pages: List<CompiledPageReference>,
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

/**
 * Maps a semantic shard digest to the blob containing its serialized representation.
 *
 * Keep the two identities distinct when resolving manifest pages and verifying downloaded bytes.
 */
@Serializable
data class CompiledShardPointer(
    val shard: ContentDigest,
    val blob: CompiledBlobPointer,
)

/**
 * Announces a positive activation revision and the blob pointers needed to load it.
 *
 * Shard identities must be unique. [manifestDigest] is the semantic manifest identity, while [manifest] verifies
 * its serialized blob. Consumers use activation revision to reject stale delivery.
 */
@Serializable
data class CompiledContentActivation(
    val activationRevision: Long,
    val manifestDigest: ContentDigest,
    val manifest: CompiledBlobPointer,
    val shards: List<CompiledShardPointer>,
) {
    init {
        require(activationRevision > 0) { "Compiled content activation revisions must be positive." }
        require(shards.map(CompiledShardPointer::shard).distinct().size == shards.size) {
            "Compiled content activation must not contain duplicate shards."
        }
    }
}

/**
 * Groups a decoded manifest with all page shards it references.
 *
 * Construction rejects duplicate shard digests and missing or mismatched page shards. It does not recompute
 * content digests or forbid extra unreferenced shards.
 */
@Serializable
data class CompiledContentBundle(
    val manifest: CompiledManifest,
    val shards: List<CompiledPageShard>,
) {
    init {
        val byDigest = shards.associateBy(CompiledPageShard::digest)
        require(byDigest.size == shards.size) { "Compiled content bundles must not contain duplicate shards." }
        require(manifest.pages.all { page -> byDigest[page.shard]?.page == page.page }) {
            "Compiled content bundles must contain every manifest shard with matching page identity."
        }
    }
}

/**
 * Pairs loaded content with the positive delivery revision used to order runtime application.
 *
 * The revision describes activation order, not the schema or file format revision.
 */
@Serializable
data class ActivatedCompiledContent(
    val activationRevision: Long,
    val content: CompiledContentBundle,
) {
    init {
        require(activationRevision > 0) { "Compiled content activation revisions must be positive." }
    }
}

@Serializable
enum class CompileDiagnosticSeverity {
    ERROR,
    WARNING,
}

@Serializable
data class CompileDiagnostic(
    val code: String,
    val message: String,
    val severity: CompileDiagnosticSeverity,
    val source: ElementInstanceId? = null,
    val target: com.typewritermc.types.ResourceId? = null,
)

/**
 * Returns a reusable page shard or diagnostics that block publication of that page.
 *
 * Blocked output retains its input fingerprint so the coordinator can track which authoring state failed.
 */
@Serializable
sealed interface PageCompileResult {
    @Serializable
    @SerialName("success")
    data class Success(
        val shard: CompiledPageShard,
    ) : PageCompileResult

    @Serializable
    @SerialName("blocked")
    data class Blocked(
        val inputFingerprint: ContentDigest,
        val diagnostics: List<CompileDiagnostic>,
    ) : PageCompileResult
}
