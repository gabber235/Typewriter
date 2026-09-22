package com.typewritermc.engine.runtime

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledElementKey
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedCompiledContent
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.TypeDecodingContext
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.Json

/** Accepts a verified generic activation at the engine content boundary. */
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

    val elements: Map<CompiledElementKey, Element>
        get() = get(Elements) ?: emptyMap()

    companion object {
        val Elements = EngineContentFacet<Map<CompiledElementKey, Element>>("typewriter.elements")
    }
}

/** Decodes and contributes the Page projection without making the generic delivery path Page specific. */
class PageCompiledArtifactConsumer(
    private val catalog: ElementCatalog,
    private val prototypes: TypePrototypeRegistry,
) : CompiledArtifactConsumer {
    override val projection: CompilationProjectionId = CompilationProjectionId("typewriter.page")
    override val mediaType: String = PAGE_MEDIA_TYPE

    private fun decode(
        reference: CompiledArtifactReference,
        payload: ByteArray,
    ): CompiledPageShard {
        val shard = json.decodeFromString(CompiledPageShard.serializer(), payload.decodeToString())
        require(shard.page.id == reference.root.resource) {
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
        val context =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = this@PageCompiledArtifactConsumer.prototypes
            }
        val compiledElements = shards.flatMap(CompiledPageShard::elements)
        require(compiledElements.map { it.key }.distinct().size == compiledElements.size) {
            "Compiled content contains duplicate element keys."
        }
        val elements =
            compiledElements.associate { element ->
                val descriptor =
                    catalog.entries.singleOrNull { it.descriptor.id == element.elementType }?.descriptor
                        ?: error("Element type ${element.elementType.value} is unavailable in the engine catalog.")
                val prototype =
                    prototypes.require(descriptor.type) as? ConcreteTypePrototype<*>
                        ?: error("Element type ${descriptor.type} is not concrete.")
                val decoded = with(context) { prototype.decode(element.value) }
                require(decoded is Element) { "Decoded value for ${descriptor.type} is not an Element." }
                element.key to decoded
            }
        target.set(EngineContentSnapshot.Elements, elements)
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
        require(content.manifest.formatRevision == 1) {
            "Unsupported compiled content format ${content.manifest.formatRevision}."
        }
        val target = EngineContentBuilder()
        consumers.contribute(content, target)
        mutableSnapshot.value = target.build(content.manifest)
    }
}

private val json = Json { ignoreUnknownKeys = true }

/** Reports whether a generic activation became current, was stale, or had no receiving gateway. */
sealed interface ContentApplicationResult {
    data class Applied(
        val activationRevision: Long,
        val manifest: ContentDigest,
    ) : ContentApplicationResult

    data class Ignored(
        val activationRevision: Long,
        val currentManifest: ContentDigest,
    ) : ContentApplicationResult

    data object Unsupported : ContentApplicationResult
}
