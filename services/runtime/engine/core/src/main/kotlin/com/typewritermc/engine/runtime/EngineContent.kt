package com.typewritermc.engine.runtime

import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PAGE_COMPILATION_FORMAT_REVISION
import com.typewritermc.engine.PAGE_COMPILATION_MEDIA_TYPE
import com.typewritermc.engine.PAGE_COMPILATION_PROJECTION
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.engine.RuntimeCompilationFacts
import com.typewritermc.engine.decodeCompiledPageShard
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.catalog.CheckedCatalog

/**
 * Accepts loaded compiled content at the engine content boundary.
 *
 * Successful return means the implementation applied its own content contract. The delivery owner serializes current state fetches and application.
 */
fun interface EngineContentGateway {
    suspend fun apply(content: LoadedPublishedContent)
}

/**
 * Admits complete Page publications and holds the compiled resource graph of the last accepted one.
 *
 * Every artifact must be a Page shard whose payload matches its manifest and passes admission against the
 * execution catalog. [graph] changes only after the whole publication is admitted, so any decoding or admission
 * failure retains the previous graph. The delivery owner serializes [apply].
 */
class PageContentGateway(
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
        val facts = content.artifacts.map { it.admittedPageFacts() }
        graph = CompiledResourceGraph.assemble(facts, relations, catalog, bindings)
    }

    private fun LoadedCompiledArtifact.admittedPageFacts(): RuntimeCompilationFacts {
        require(reference.root.projection == PAGE_COMPILATION_PROJECTION && reference.mediaType == PAGE_COMPILATION_MEDIA_TYPE) {
            "Engine content does not support ${reference.root.projection.value} and ${reference.mediaType}."
        }
        val shard = payload.decodeCompiledPageShard()
        require(shard.digest == reference.semanticDigest) {
            "Compiled Page artifact identity does not match its manifest."
        }
        val facts = shard.facts
        require(facts.root.source == reference.root.resource) {
            "Compiled Page artifact root does not match its payload."
        }
        require(facts.formatRevision == reference.formatRevision && facts.formatRevision == PAGE_COMPILATION_FORMAT_REVISION) {
            "Compiled Page artifact format does not match its manifest."
        }
        facts.requireAccepted(catalog, relations)
        return facts
    }
}

/** Reports whether the complete publication was installed or was already current. */
sealed interface ContentApplicationResult {
    data class Applied(
        val publication: com.typewritermc.authoring.PublicationId,
    ) : ContentApplicationResult

    data class Unchanged(
        val publication: com.typewritermc.authoring.PublicationId,
    ) : ContentApplicationResult

    data object Unsupported : ContentApplicationResult
}
