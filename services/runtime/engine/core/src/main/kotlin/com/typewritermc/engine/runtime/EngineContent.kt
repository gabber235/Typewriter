package com.typewritermc.engine.runtime

import com.typewritermc.elements.Element
import com.typewritermc.elements.Cue
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedCompiledContent
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.RelationDefinition
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.Json

/**
 * Accepts loaded compiled content at the engine content boundary.
 *
 * Successful return means the implementation applied its own content contract. Ordering and stale revision
 * rejection belong to the runtime invoking this gateway.
 */
fun interface EngineContentGateway {
    suspend fun apply(content: LoadedCompiledContent)
}

/** Typed identity for one independently contributed engine content facet. */
class EngineContentFacet<Value : Any>(
    val id: String,
) {
    init {
        require(id.isNotBlank()) { "Engine content facet ids must not be blank." }
    }

    override fun equals(other: Any?): Boolean = other is EngineContentFacet<*> && id == other.id

    override fun hashCode(): Int = id.hashCode()
}

/** Mutable assembly target that rejects competing owners for one content facet. */
class EngineContentBuilder {
    private val values = linkedMapOf<EngineContentFacet<*>, Any>()

    fun <Value : Any> set(
        facet: EngineContentFacet<Value>,
        value: Value,
    ) {
        require(values.put(facet, value) == null) { "Engine content facet ${facet.id} was contributed more than once." }
    }

    internal fun build(manifest: CompiledArtifactManifest): EngineContentSnapshot = EngineContentSnapshot(manifest, values.toMap())
}

/** Publishes all registered content facets after every consumer assembles successfully. */
data class EngineContentSnapshot(
    val manifest: CompiledArtifactManifest,
    private val facets: Map<EngineContentFacet<*>, Any>,
) {
    @Suppress("UNCHECKED_CAST")
    operator fun <Value : Any> get(facet: EngineContentFacet<Value>): Value? = facets[facet] as? Value

    val graph: CompiledResourceGraph?
        get() = get(Resources)

    val elements: Map<CompiledResourceKey, Element>
        get() = graph?.elements.orEmpty()

    val cues: Map<CompiledResourceKey, Cue>
        get() = graph?.cues.orEmpty()

    companion object {
        val Resources = EngineContentFacet<CompiledResourceGraph>("typewriter.resources")
    }
}

/** Decodes and contributes the Page projection without making the generic delivery path Page specific. */
class PageCompiledArtifactConsumer(
    private val prototypes: TypePrototypeRegistry,
    private val relations: Collection<RelationDefinition>,
) : CompiledArtifactConsumer {
    override val projection: CompilationProjectionId = CompilationProjectionId("typewriter.page")
    override val mediaType: String = PAGE_MEDIA_TYPE

    private fun decode(
        reference: CompiledArtifactReference,
        payload: ByteArray,
    ): CompiledPageShard {
        val shard = json.decodeFromString(CompiledPageShard.serializer(), payload.decodeToString())
        require(shard.root.source == reference.root.resource) {
            "Compiled Page artifact root does not match its payload."
        }
        require(shard.digest == reference.semanticDigest) {
            "Compiled Page artifact identity does not match its manifest."
        }
        require(shard.formatRevision == reference.formatRevision) {
            "Compiled Page artifact format does not match its manifest."
        }
        return shard
    }

    override fun contribute(
        artifacts: List<LoadedCompiledArtifact>,
        target: EngineContentBuilder,
    ) {
        val shards = artifacts.map { decode(it.reference, it.payload) }
        require(shards.all { it.formatRevision == 2 }) {
            "Unsupported compiled Page graph format."
        }
        target.set(
            EngineContentSnapshot.Resources,
            CompiledResourceGraph.assemble(shards, relations, prototypes),
        )
    }

    companion object {
        const val PAGE_MEDIA_TYPE = "application/vnd.typewriter.page+json"
    }
}

/** Applies a generic activation only after every registered artifact has been decoded and assembled. */
class AssemblingEngineContentGateway(
    consumers: Collection<CompiledArtifactConsumer>,
) : EngineContentGateway {
    private val consumers = CompiledArtifactConsumerRegistry(consumers)
    private val mutableSnapshot = MutableStateFlow<EngineContentSnapshot?>(null)
    val snapshot: StateFlow<EngineContentSnapshot?> = mutableSnapshot

    override suspend fun apply(content: LoadedCompiledContent) {
        require(content.manifest.formatRevision == 2) {
            "Unsupported compiled content format ${content.manifest.formatRevision}."
        }
        val target = EngineContentBuilder()
        consumers.contribute(content, target)
        mutableSnapshot.value = target.build(content.manifest)
    }
}

private val json = Json { ignoreUnknownKeys = true }

/**
 * Distinguishes newly applied content, a stale activation, and runtimes without a content gateway.
 *
 * Ignored reports the current activation and manifest, not the rejected incoming revision.
 */
sealed interface ContentApplicationResult {
    /** The gateway accepted the incoming activation and it became the current content. */
    data class Applied(
        val activationRevision: Long,
        val manifest: ContentDigest,
    ) : ContentApplicationResult

    /** The activation was stale or repeated; the current content remains authoritative. */
    data class Ignored(
        val activationRevision: Long,
        val currentManifest: ContentDigest,
    ) : ContentApplicationResult

    /** No content gateway is configured, so the activation could not be applied. */
    data object Unsupported : ContentApplicationResult
}
