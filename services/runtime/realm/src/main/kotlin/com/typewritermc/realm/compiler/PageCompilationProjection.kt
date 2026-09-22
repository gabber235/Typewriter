package com.typewritermc.realm.compiler

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.ContentDigest
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.library.Page
import com.typewritermc.library.PageCompileStatus
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentDiagnostic
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageId
import com.typewritermc.library.PageReference
import com.typewritermc.realm.CoreResourceDefinitionIds
import com.typewritermc.realm.repository.AuthoringGraphDelta
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/** Compiles Pages through the generic projection boundary. */
internal class PageCompilationProjection(
    private val prototypes: TypePrototypeRegistry,
    private val compiler: PageCompiler = PageCompiler(),
    private val catalogRevision: () -> String,
) : AuthoringCompilationProjection {
    override val id: CompilationProjectionId = CompilationProjectionId("typewriter.page")

    override val root: TypeExpression = TypeExpression.Named(prototypes.require(Page::class).type)

    override val graphRequirement: GraphReadRequirement =
        GraphReadRequirement(
            definitions = setOf(CoreResourceDefinitionIds.PAGE, CoreResourceDefinitionIds.ELEMENT),
            relations = setOf(RelationId(PAGE_ELEMENTS_RELATION_ID)),
            outgoingReferences = true,
        )

    override fun roots(graph: AuthoringWorkingGraph): Set<ResourceId> =
        graph.resources.values
            .filter { it.definition == CoreResourceDefinitionIds.PAGE }
            .mapTo(linkedSetOf(), StoredTypedResource::id)

    override fun affectedRoots(
        change: AuthoringGraphDelta,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> {
        val changed =
            change.resourceUpserts.keys + change.resourceRemovals +
                change.relationUpserts.values.flatMap { listOf(it.source, it.target) } +
                change.relationRemovals.flatMap { edgeId ->
                    listOfNotNull(before.relations[edgeId]?.source, before.relations[edgeId]?.target)
                }
        return (before.pageRoots(changed) + proposed.pageRoots(changed)).toSet()
    }

    override suspend fun compile(
        root: ResourceId,
        graph: AuthoringWorkingGraph,
    ): CompilationResult {
        val page =
            graph.resources[root]?.takeIf { it.definition == CoreResourceDefinitionIds.PAGE }
                ?: return CompilationResult.Removed(com.typewritermc.engine.CompilationRoot(id, root))
        val document = graph.pageDocument(page, prototypes)
        return when (val result = compiler.compile(document, catalogRevision())) {
            is com.typewritermc.engine.PageCompileResult.Blocked -> {
                CompilationResult.Blocked(
                    root = com.typewritermc.engine.CompilationRoot(id, root),
                    inputFingerprint = result.inputFingerprint,
                    diagnostics = result.diagnostics,
                )
            }

            is com.typewritermc.engine.PageCompileResult.Success -> {
                val payload = json.encodeToString(result.shard).encodeToByteArray()
                CompilationResult.Success(
                    com.typewritermc.engine.CompiledArtifact(
                        root = com.typewritermc.engine.CompilationRoot(id, root),
                        formatRevision = result.shard.formatRevision,
                        mediaType = MEDIA_TYPE,
                        inputFingerprint = result.shard.inputFingerprint,
                        semanticDigest = result.shard.digest,
                        payload = payload,
                    ),
                )
            }
        }
    }

    private fun AuthoringWorkingGraph.pageDocument(
        page: StoredTypedResource,
        prototypes: TypePrototypeRegistry,
    ): PageDocument {
        val pageElements = RelationId(PAGE_ELEMENTS_RELATION_ID)
        val resources = resources
        val elements =
            relations.values
                .filter { it.source == page.id && (it.origin as? ResourceRelationOrigin.Declared)?.relationId == pageElements }
                .map { relation -> resources[relation.target] ?: error("Page element ${relation.target} is missing.") }
                .map { resource -> resource.toPageElement(prototypes) }
        val elementIds = elements.mapTo(linkedSetOf(), PageDocumentElement::id)
        val references =
            relations.values.mapNotNull { relation ->
                val origin = relation.origin as? ResourceRelationOrigin.Reference ?: return@mapNotNull null
                relation.takeIf { it.source in elementIds }?.let {
                    PageReference(it.source, origin.slot, it.target, origin.expectedTarget)
                }
            }
        val known = resources.keys
        val diagnostics =
            references.filter { it.target !in known }.map { reference ->
                PageDocumentDiagnostic(
                    code = "dangling-reference",
                    message = "Reference target ${reference.target.value} does not exist.",
                    element = reference.source,
                    slot = reference.slot,
                    target = reference.target,
                )
            }
        return PageDocument(
            page = com.typewritermc.types.Resource(PageId(page.id), prototypes.decodeAs<Page>(page.content())),
            elements = elements,
            references = references,
            incomingReferences = emptyList(),
            crossPageTargets = emptyList(),
            crossPageSources = emptyList(),
            diagnostics = diagnostics,
            compileStatus = PageCompileStatus.NotCompiled,
        )
    }

    private fun StoredTypedResource.content(): com.typewritermc.types.TypedValueEnvelope =
        com.typewritermc.types.TypedValueEnvelope(TypeExpression.Named(root), valueWithSlots)

    private fun StoredTypedResource.toPageElement(prototypes: TypePrototypeRegistry): PageDocumentElement {
        val root = root.id as? TypeId.Declared ?: error("Page element root must be declared: $root")
        val decoded = prototypes.decodeAs<Element>(content())
        return PageDocumentElement(
            id = id,
            elementType = ElementTypeId(root.id),
            schemaRevision = this.root.revision,
            value = valueWithSlots,
            placement = decoded.placement,
        )
    }

    private fun AuthoringWorkingGraph.pageRoots(changed: Collection<ResourceId>): Set<ResourceId> =
        buildSet {
            changed.forEach { id ->
                val resource = resources[id]
                when (resource?.definition) {
                    CoreResourceDefinitionIds.PAGE -> {
                        add(id)
                    }

                    CoreResourceDefinitionIds.ELEMENT -> {
                        relations.values
                            .filter { it.target == id && it.isPageElements() }
                            .mapTo(this) { it.source }
                    }

                    else -> {}
                }
            }
        }

    private fun StoredResourceRelation.isPageElements(): Boolean =
        (origin as? ResourceRelationOrigin.Declared)?.relationId == RelationId(PAGE_ELEMENTS_RELATION_ID)

    private companion object {
        const val MEDIA_TYPE = "application/vnd.typewriter.page+json"
        val json = Json { encodeDefaults = true }
    }
}
