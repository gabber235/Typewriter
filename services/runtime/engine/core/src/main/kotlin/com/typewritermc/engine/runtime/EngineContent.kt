package com.typewritermc.engine.runtime

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledElementKey
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
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

/** Publishes decoded elements after all registered compiled artifacts assemble successfully. */
data class EngineContentSnapshot(
    val manifest: CompiledArtifactManifest,
    val elements: Map<CompiledElementKey, Element>,
)

/** Decodes the Page projection without making the generic delivery path Page specific. */
class EngineContentAssembler(
    private val catalog: ElementCatalog,
    private val prototypes: TypePrototypeRegistry,
) : CompiledArtifactConsumer<CompiledPageShard> {
    override val projection: CompilationProjectionId = CompilationProjectionId("typewriter.page")
    override val mediaType: String = PAGE_MEDIA_TYPE

    override fun decode(
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
        return shard
    }

    fun assemble(
        manifest: CompiledArtifactManifest,
        shards: List<CompiledPageShard>,
    ): EngineContentSnapshot {
        require(manifest.formatRevision == 1) {
            "Unsupported compiled content format ${manifest.formatRevision}."
        }
        val context =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = this@EngineContentAssembler.prototypes
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
        return EngineContentSnapshot(manifest, elements)
    }

    companion object {
        const val PAGE_MEDIA_TYPE = "application/vnd.typewriter.page+json"
    }
}

/** Applies a generic activation only after every registered artifact has been decoded and assembled. */
class AssemblingEngineContentGateway(
    private val assembler: EngineContentAssembler,
    private val consumers: CompiledArtifactConsumerRegistry =
        CompiledArtifactConsumerRegistry(listOf(assembler)),
) : EngineContentGateway {
    private val mutableSnapshot = MutableStateFlow<EngineContentSnapshot?>(null)
    val snapshot: StateFlow<EngineContentSnapshot?> = mutableSnapshot

    override suspend fun apply(content: LoadedCompiledContent) {
        val decoded =
            content.artifacts.map { artifact ->
                consumers.decode(artifact.reference, artifact.payload)
            }
        val shards =
            decoded.map { value ->
                value as? CompiledPageShard
                    ?: error("Engine content consumer returned an unsupported value.")
            }
        mutableSnapshot.value = assembler.assemble(content.manifest, shards)
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
