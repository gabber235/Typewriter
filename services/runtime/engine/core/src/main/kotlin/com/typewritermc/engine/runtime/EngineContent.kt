package com.typewritermc.engine.runtime

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.engine.ActivatedCompiledContent
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledContentBundle
import com.typewritermc.engine.CompiledElementKey
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.api.artifact.DigestAlgorithm
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.TypeDecodingContext
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.Json
import java.io.ByteArrayOutputStream

/**
 * Accepts a loaded activation at the engine content boundary.
 *
 * Successful return means the implementation applied its own content contract. Ordering and stale revision
 * rejection belong to the runtime invoking this gateway.
 */
fun interface EngineContentGateway {
    suspend fun apply(content: ActivatedCompiledContent)
}

/**
 * Loads the manifest and shards described by an activation.
 *
 * Implementations are responsible for verifying external bytes before returning a usable bundle; failures
 * propagate to delivery.
 */
fun interface CompiledContentSource {
    suspend fun load(activation: CompiledContentActivation): ActivatedCompiledContent
}

/**
 * Loads compiled JSON blobs with exact size, contiguous chunk, and SHA256 verification.
 *
 * Manifest and shard identities must match their descriptors. Shards are cached by semantic digest for reuse
 * across activations. Calls must be serialized because the cache is mutable; each blob is buffered in memory and
 * must fit an Int sized array.
 */
class BlobCompiledContentSource(
    private val blobs: BlobEndpoint,
) : CompiledContentSource {
    private val shards = mutableMapOf<ContentDigest, CompiledPageShard>()

    override suspend fun load(activation: CompiledContentActivation): ActivatedCompiledContent {
        val manifest =
            json.decodeFromString(
                CompiledManifest.serializer(),
                read(activation.manifest).decodeToString(),
            )
        require(manifest.digest == activation.manifestDigest) { "Compiled manifest identity does not match activation." }
        val pointers = activation.shards.associateBy { it.shard }
        val loaded =
            manifest.pages.map { page ->
                shards[page.shard]
                    ?: run {
                        val pointer = requireNotNull(pointers[page.shard]) { "Activation is missing shard ${page.shard.value}." }
                        json
                            .decodeFromString(
                                CompiledPageShard.serializer(),
                                read(pointer.blob).decodeToString(),
                            ).also { shard ->
                                require(shard.digest == page.shard) { "Compiled shard identity does not match its manifest." }
                                require(shard.page == page.page) { "Compiled shard page does not match its manifest." }
                                shards[page.shard] = shard
                            }
                    }
            }
        return ActivatedCompiledContent(activation.activationRevision, CompiledContentBundle(manifest, loaded))
    }

    private suspend fun read(pointer: CompiledBlobPointer): ByteArray {
        require(pointer.size <= Int.MAX_VALUE) { "Compiled blob is too large to buffer." }
        val expected = ArtifactDigest(DigestAlgorithm.SHA_256, pointer.digest.value)
        val metadata = blobs.metadata(expected).success("read compiled blob metadata")
        require(metadata.size == pointer.size) { "Compiled blob size does not match its descriptor." }
        val output = ByteArrayOutputStream(pointer.size.toInt())
        var offset = 0L
        var complete = pointer.size == 0L
        while (offset < pointer.size) {
            val chunk = blobs.read(expected, offset, DEFAULT_CHUNK_SIZE).success("read compiled blob")
            require(chunk.offset == offset) { "Compiled blob returned a noncontiguous chunk." }
            require(chunk.bytes.isNotEmpty()) { "Compiled blob ended before its declared size." }
            require(chunk.bytes.size.toLong() <= pointer.size - offset) { "Compiled blob exceeded its declared size." }
            output.write(chunk.bytes)
            offset += chunk.bytes.size
            require(!chunk.complete || offset == pointer.size) { "Compiled blob ended before its declared size." }
            complete = chunk.complete
        }
        require(complete) { "Compiled blob did not mark its final chunk complete." }
        val bytes = output.toByteArray()
        require(ArtifactDigest.sha256(bytes) == expected) { "Compiled blob digest verification failed." }
        return bytes
    }
}

/**
 * Publishes decoded elements indexed by compiled occurrence together with their manifest.
 *
 * This is decoded content, not a set of attached runtime facets or proof that entries are being executed.
 */
data class EngineContentSnapshot(
    val manifest: CompiledManifest,
    val elements: Map<CompiledElementKey, Element>,
)

/**
 * Decodes compiled elements using the engine catalog and deployment prototypes.
 *
 * Only manifest format revision one is supported. Duplicate compiled keys, missing concrete prototypes, and
 * decoded values that are not elements fail assembly. Decoding follows the catalog descriptor; no schema migration
 * is performed here.
 */
class EngineContentAssembler(
    private val catalog: ElementCatalog,
    private val prototypes: TypePrototypeRegistry,
) {
    fun assemble(content: CompiledContentBundle): EngineContentSnapshot {
        require(content.manifest.formatRevision == 1) {
            "Unsupported compiled content format ${content.manifest.formatRevision}."
        }
        val context =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = this@EngineContentAssembler.prototypes
            }
        val compiledElements =
            content.shards
                .flatMap { it.elements }
        require(compiledElements.map { it.key }.distinct().size == compiledElements.size) {
            "Compiled content contains duplicate element keys."
        }
        val elements =
            compiledElements
                .associate { element ->
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
        return EngineContentSnapshot(content.manifest, elements)
    }
}

/**
 * Replaces the observable decoded snapshot only after complete assembly succeeds.
 *
 * A failed assembly leaves the previous snapshot in place. This gateway does not attach facets, dispatch entries,
 * or provide player execution.
 */
class AssemblingEngineContentGateway(
    private val assembler: EngineContentAssembler,
) : EngineContentGateway {
    private val mutableSnapshot = MutableStateFlow<EngineContentSnapshot?>(null)
    val snapshot: StateFlow<EngineContentSnapshot?> = mutableSnapshot

    override suspend fun apply(content: ActivatedCompiledContent) {
        mutableSnapshot.value = assembler.assemble(content.content)
    }
}

/**
 * Distinguishes newly applied content, a stale activation, and runtimes without a content gateway.
 *
 * Ignored reports the current activation and manifest, not the rejected incoming revision.
 */
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

private fun <T> BlobResult<T>.success(operation: String): T =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("$operation failed because the blob was not found.")
        is BlobResult.Conflict -> error("$operation failed: $reason")
        is BlobResult.Invalid -> error("$operation failed: $reason")
    }

private val json = Json { ignoreUnknownKeys = true }
