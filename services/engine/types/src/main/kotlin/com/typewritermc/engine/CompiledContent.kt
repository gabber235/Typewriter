package com.typewritermc.engine

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.library.Page
import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SourceElementKey(
    val element: Ref<Element>,
)

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

@Serializable
data class CompiledElementKey(
    val source: SourceElementKey,
    val context: CompilationContext,
)

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

@Serializable
data class CompiledManifest(
    val formatRevision: Int,
    val digest: ContentDigest,
    val sourceRevision: String,
    val catalogRevision: String,
    val pages: List<CompiledPageReference>,
)

@Serializable
data class CompiledBlobPointer(
    val digest: ContentDigest,
    val size: Long,
) {
    init {
        require(size >= 0) { "Compiled blob size must not be negative." }
    }
}

@Serializable
data class CompiledShardPointer(
    val shard: ContentDigest,
    val blob: CompiledBlobPointer,
)

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
