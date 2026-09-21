package com.typewritermc.realm.compiler

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.library.Page
import com.typewritermc.library.PageCompileStatus
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentDiagnostic
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageId
import com.typewritermc.library.PageReference
import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.realm.repository.AuthoringResourceKind
import com.typewritermc.realm.repository.GraphSelection
import com.typewritermc.realm.repository.RelationDirection
import com.typewritermc.realm.repository.RelationFilter
import com.typewritermc.realm.repository.RelationStep
import com.typewritermc.realm.repository.ResourceFilter
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.ResourceSeed
import com.typewritermc.types.RelationId
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry

interface AuthoringCompilationSource {
    suspend fun snapshot(): AuthoringCompilationSnapshot
}

data class AuthoringCompilationSnapshot(
    val revision: String,
    val documents: List<PageDocument>,
)

/** Projects compiler documents from the canonical hydrated graph without table specific loaders. */
internal class GraphAuthoringCompilationSource(
    private val graph: AuthoringGraphRepository,
    private val prototypes: TypePrototypeRegistry,
    private val generation: () -> String,
) : AuthoringCompilationSource {
    override suspend fun snapshot(): AuthoringCompilationSnapshot {
        val result =
            graph.query(
                generation(),
                listOf(
                    GraphSelection(
                        key = "compiler",
                        seed = ResourceSeed.Scan(ResourceFilter()),
                        steps = listOf(RelationStep(RelationFilter.Any, RelationDirection.BOTH, 1, 1)),
                    ),
                ),
            )
        val snapshot =
            (result as? AuthoringGraphQueryResult.Success)?.snapshot
                ?: error("Authoring graph changed while preparing compiler input.")
        val resources = snapshot.resources.associateBy { it.id }
        val pageElements = RelationId(PAGE_ELEMENTS_RELATION_ID)
        val documents =
            snapshot.resources
                .asSequence()
                .filter { it.kind == AuthoringResourceKind.PAGE }
                .map { pageResource ->
                    val page = prototypes.decodeAs<Page>(pageResource.content)
                    val pageId = PageId(pageResource.id)
                    val elementIds =
                        snapshot.edges.mapNotNull { edge ->
                            val declared = edge.origin as? ResourceRelationOrigin.Declared ?: return@mapNotNull null
                            edge.target.takeIf { declared.relationId == pageElements && edge.source == pageResource.id }
                        }
                    val elements =
                        elementIds.map { id ->
                            val resource = resources[id] ?: error("Page element $id is missing from the compiler graph.")
                            val decoded = prototypes.decodeAs<Element>(resource.content)
                            val root = (resource.content.rootType as TypeExpression.Named).reference
                            val declared = root.id as TypeId.Declared
                            PageDocumentElement(
                                id = resource.id,
                                elementType = ElementTypeId(declared.id),
                                schemaRevision = root.revision,
                                value = resource.content.rootValue,
                                placement = decoded.placement,
                            )
                        }
                    val localElementIds = elementIds.toSet()
                    val references =
                        snapshot.edges.mapNotNull { edge ->
                            val origin = edge.origin as? ResourceRelationOrigin.Reference ?: return@mapNotNull null
                            if (edge.source !in localElementIds) return@mapNotNull null
                            PageReference(edge.source, origin.slot, edge.target, origin.expectedTarget)
                        }
                    val incoming =
                        snapshot.edges.mapNotNull { edge ->
                            val origin = edge.origin as? ResourceRelationOrigin.Reference ?: return@mapNotNull null
                            if (edge.target !in localElementIds + pageResource.id || edge.source in localElementIds) return@mapNotNull null
                            if (resources[edge.source]?.kind != AuthoringResourceKind.ELEMENT) return@mapNotNull null
                            PageReference(edge.source, origin.slot, edge.target, origin.expectedTarget)
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
                    PageDocument(
                        page = Resource(pageId, page),
                        elements = elements,
                        references = references,
                        incomingReferences = incoming,
                        crossPageTargets = emptyList(),
                        crossPageSources = emptyList(),
                        diagnostics = diagnostics,
                        compileStatus = PageCompileStatus.NotCompiled,
                    )
                }.sortedBy { it.page.id.value.value }
                .toList()
        return AuthoringCompilationSnapshot(snapshot.sequence.toString(), documents)
    }
}
