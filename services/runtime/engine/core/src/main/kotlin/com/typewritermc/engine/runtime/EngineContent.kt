package com.typewritermc.engine.runtime

import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.decodeResourceGraphShard
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.toSkir
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.PublicationId

/**
 * Accepts loaded compiled content at the engine content boundary.
 *
 * Successful return means the implementation applied its own content contract. The delivery owner serializes current state fetches and application.
 */
fun interface EngineContentGateway {
    suspend fun apply(content: LoadedPublishedContent)
}

/**
 * Admits complete resource graph publications and holds the compiled resource graph of the last accepted one.
 *
 * Every artifact must be a resource graph shard whose payload matches its manifest and passes admission against the
 * execution catalog. [graph] changes only after the whole publication is admitted, so any decoding or admission
 * failure retains the previous graph. The delivery owner serializes [apply].
 */
class ResourceGraphContentGateway(
    private val catalog: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
    private val relations: Collection<RelationContract>,
) : EngineContentGateway {
    @Volatile
    var graph: CompiledResourceGraph? = null
        private set

    override suspend fun apply(content: LoadedPublishedContent) {
        require(content.descriptor.formatRevision == PUBLISHED_CONTENT_FORMAT_REVISION) {
            "Unsupported compiled content format ${content.descriptor.formatRevision}."
        }
        val facts = content.artifacts.map { it.admittedFacts() }
        graph = CompiledResourceGraph.assemble(facts, relations, catalog, bindings)
    }

    private fun LoadedCompiledArtifact.admittedFacts(): RuntimeCompilationFacts {
        require(reference.root.projection == RESOURCE_GRAPH_PROJECTION && reference.mediaType == RESOURCE_GRAPH_MEDIA_TYPE) {
            "Engine content does not support ${reference.root.projection.value} and ${reference.mediaType}."
        }
        val shard = payload.decodeResourceGraphShard()
        require(shard.digest == reference.semanticDigest) {
            "Compiled resource graph artifact identity does not match its manifest."
        }
        val facts = shard.facts
        require(facts.root.source == reference.root.resource) {
            "Compiled resource graph artifact root does not match its payload."
        }
        require(facts.formatRevision == reference.formatRevision && facts.formatRevision == RESOURCE_GRAPH_FORMAT_REVISION) {
            "Compiled resource graph artifact format does not match its manifest."
        }
        facts.requireAccepted(catalog, relations)
        return facts
    }
}

/** Reports whether the complete publication was installed or was already current. */
sealed interface ContentApplicationResult {
    data class Applied(
        val publication: PublicationId,
    ) : ContentApplicationResult

    data class Unchanged(
        val publication: PublicationId,
    ) : ContentApplicationResult

    data object Unsupported : ContentApplicationResult
}
