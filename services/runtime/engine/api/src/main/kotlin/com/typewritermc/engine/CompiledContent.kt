package com.typewritermc.engine

import com.typewritermc.types.unknownVariant
import kotlinx.serialization.Serializable
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledEdge
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.InstancePath
import skirout.editor.v1.compiled_content.ResourceGraphShard
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RelationId

const val RESOURCE_GRAPH_FORMAT_REVISION = 1

/** The single compiled format for authored resource graphs, shared by the Realm producer and engine consumers. */
val RESOURCE_GRAPH_PROJECTION = CompilationProjectionId(value = "typewriter.resource-graph")

/** Names the serialized resource graph shard format. */
const val RESOURCE_GRAPH_MEDIA_TYPE = "application/vnd.typewriter.resource-graph+json"

/** The root occurrence of an authored resource, which has no instance path segments. */
val InstancePath.Companion.Root: InstancePath get() = ROOT_INSTANCE_PATH

/** The context of resources compiled at their root occurrence. */
val CompilationContext.Companion.Root: CompilationContext get() = ROOT_COMPILATION_CONTEXT

private val ROOT_INSTANCE_PATH = InstancePath(segments = emptyList())

private val ROOT_COMPILATION_CONTEXT = CompilationContext(instancePath = ROOT_INSTANCE_PATH)

/** The compiled value of this resource as the named data value native bindings decode. */
val CompiledResource.dataValue: DataValue get() = DataValue.NamedWrapper(value)

/** The declared relation this edge projects. */
val CompiledEdge.relation: RelationId
    get() =
        when (val origin = origin) {
            is CompiledEdgeOrigin.RelationWrapper -> origin.value.relation
            else -> unknownVariant(origin)
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
        requireContentDigest(value)
    }
}

/** Requires the 64 lowercase SHA256 hexadecimal characters of a content digest. */
internal fun requireContentDigest(value: String) {
    require(CONTENT_DIGEST.matches(value)) { "Content digests must be lowercase SHA256 values." }
}

private val CONTENT_DIGEST = Regex("[0-9a-f]{64}")

/** The semantic digest of the facts of this shard. */
val ResourceGraphShard.semanticDigest: ContentDigest get() = ContentDigest(digest)

/**
 * Returns a reusable shard or diagnostics that block publication of that compilation unit.
 *
 * Blocked output retains its input fingerprint so the coordinator can track which authoring state failed.
 */
sealed interface ResourceGraphCompileResult {
    /** A complete shard that may be reused or included in a publication. */
    data class Success(
        val shard: ResourceGraphShard,
        val inputFingerprint: ContentDigest,
    ) : ResourceGraphCompileResult

    /** A compilation unit that produced no publishable shard and retains the input state behind its diagnostics. */
    data class Blocked(
        val inputFingerprint: ContentDigest,
        val diagnostics: List<Diagnostic>,
    ) : ResourceGraphCompileResult
}
