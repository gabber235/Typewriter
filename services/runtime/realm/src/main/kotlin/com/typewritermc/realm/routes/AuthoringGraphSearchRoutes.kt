package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.AuthoringSearchMatch
import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringGraphSnapshot
import com.typewritermc.realm.repository.ResourceFilter
import com.typewritermc.realm.repository.ResourceSeed
import com.typewritermc.realm.repository.toSelection
import com.typewritermc.realm.search.AuthoringSearchMetadata
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.realm.search.IndexedSelectorFilter
import com.typewritermc.realm.search.requiresDefinitionUniverse
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.ResourceId
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringSearchHit
import skirout.editor.v1.authoring.SearchAuthoringGraphRequest
import skirout.editor.v1.authoring.SearchAuthoringGraphResponse
import skirout.editor.v1.authoring.SearchFacetRequest
import skirout.editor.v1.authoring.SearchFacetResult
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.editor.v1.type_catalog.CatalogGeneration

/** Retrieves bounded indexed candidates, then hydrates only resources returned to the panel. */
internal class AuthoringGraphSearchRoutes(
    private val graph: AuthoringGraphRepository,
    private val search: AuthoringSearchRepository,
    private val contracts: EditorContracts,
    private val subjects: AuthoringPresentationProjector,
    private val metadata: AuthoringSearchMetadata,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchAuthoringGraph) { call ->
                runCatching { search(call.request) }.getOrElse { it.toInvalidSearchResponse() }
            }
        }

    private suspend fun search(request: SearchAuthoringGraphRequest): SearchAuthoringGraphResponse {
        val filter = request.resources.toDomain().withTarget(request.referenceTarget)
        val selectors = request.query.toIndexedSelectorFilter(metadata)
        if (filter.definitions.isEmpty() && selectors.requiresDefinitionUniverse) {
            return SearchAuthoringGraphResponse.createInvalid(
                diagnostics =
                    listOf(
                        AuthoringDiagnostic(
                            code = "negated-search-requires-definition-scope",
                            message = "Negated authoring search requires at least one resource definition.",
                            resource = null,
                            path = null,
                        ),
                    ),
            )
        }
        val candidates =
            search
                .search(
                    query = request.query.terms.joinToString(" "),
                    definitions = filter.definitions,
                    contexts = request.contexts.mapTo(linkedSetOf()) { ResourceId(it.value) },
                    selectors = selectors,
                    assignableTo = filter.assignableTo,
                    limit = MAX_SEARCH_RESULTS,
                )
        val selections =
            buildList {
                add(
                    com.typewritermc.realm.repository.GraphSelection(
                        SEARCH_SELECTION,
                        ResourceSeed.Ids(candidates.map(IndexedAuthoringSearchCandidate::resource), filter.assignableTo),
                    ),
                )
                add(
                    com.typewritermc.realm.repository.GraphSelection(
                        SEARCH_OWNER_SELECTION,
                        ResourceSeed.Ids(candidates.flatMap(IndexedAuthoringSearchCandidate::ownerPath).distinct()),
                    ),
                )
                candidates
                    .groupBy(IndexedAuthoringSearchCandidate::definition)
                    .forEach { (definition, definitionCandidates) ->
                        val requirement = subjects.graphRequirement(definition)
                        add(
                            requirement.toSelection(
                                key = "search-presentation-${definition.value}",
                                seed = ResourceSeed.Ids(definitionCandidates.map(IndexedAuthoringSearchCandidate::resource)),
                            ),
                        )
                    }
            }
        return when (val result = graph.query(request.generation.value, selections)) {
            is AuthoringGraphQueryResult.CatalogChanged -> {
                result.toWire()
            }

            is AuthoringGraphQueryResult.Invalid -> {
                result.toWire()
            }

            is AuthoringGraphQueryResult.Success -> {
                result.toSearchResponse(candidates, request.query.terms, request.facets)
            }
        }
    }

    private fun AuthoringGraphQueryResult.Success.toSearchResponse(
        candidates: List<IndexedAuthoringSearchCandidate>,
        terms: List<String>,
        facetRequests: List<SearchFacetRequest>,
    ): SearchAuthoringGraphResponse {
        val resources = snapshot.resources.associateBy(AuthoringGraphResource::id)
        val compatible = snapshot.compatibleSearchCandidateIds()
        val compatibleCandidates = candidates.filter { it.resource in compatible }
        val hits =
            compatibleCandidates
                .mapNotNull { candidate ->
                    val resource = resources[candidate.resource] ?: return@mapNotNull null
                    AuthoringSearchHit(
                        resource = resource.id.toWire(),
                        definition = resource.definition.toWire(),
                        subject = subjects.toWire(subjects.project(resource, candidate.ownerPath, snapshot.toWorkingGraph())),
                        context = subjects.encode(candidate.context(terms)),
                        ownerPath = candidate.ownerPath.map(ResourceId::toWire),
                    )
                }.take(MAX_SEARCH_RESULTS)
        return SearchAuthoringGraphResponse.createSuccess(
            generation = CatalogGeneration(value = snapshot.generation),
            sequence = snapshot.sequence,
            hits = hits,
            facets = facetRequests.map { it.resolve(compatibleCandidates, metadata) },
            diagnostics = emptyList(),
        )
    }
}

internal fun AuthoringGraphSnapshot.compatibleSearchCandidateIds(): Set<ResourceId> =
    selections
        .single { selection -> selection.key == SEARCH_SELECTION }
        .resourceIds
        .toSet()

private fun AuthoringGraphQueryResult.CatalogChanged.toWire(): SearchAuthoringGraphResponse =
    SearchAuthoringGraphResponse.createCatalogChanged(actualGeneration = CatalogGeneration(value = actualGeneration))

private fun AuthoringGraphQueryResult.Invalid.toWire(): SearchAuthoringGraphResponse =
    SearchAuthoringGraphResponse.createInvalid(
        diagnostics = listOf(AuthoringDiagnostic(code = code, message = message, resource = null, path = null)),
    )

private fun Throwable.toInvalidSearchResponse(): SearchAuthoringGraphResponse =
    SearchAuthoringGraphResponse.createInvalid(
        diagnostics =
            listOf(
                AuthoringDiagnostic(
                    code = "invalid-search",
                    message = message ?: "Invalid authoring graph search.",
                    resource = null,
                    path = null,
                ),
            ),
    )

private fun skirout.editor.v1.search.RealmSearchQuery.toIndexedSelectorFilter(metadata: AuthoringSearchMetadata): IndexedSelectorFilter =
    selectorExpression?.toIndexedSelectorFilter(metadata)
        ?: selectors
            .map { it.toIndexedSelectorFilter(metadata) }
            .fold<IndexedSelectorFilter, IndexedSelectorFilter>(IndexedSelectorFilter.All, IndexedSelectorFilter::And)

private fun RealmSearchSelector.toIndexedSelectorFilter(metadata: AuthoringSearchMetadata): IndexedSelectorFilter =
    value
        ?.trim()
        ?.takeIf(String::isNotEmpty)
        ?.let { IndexedSelectorFilter.Match(selectorId, metadata.normalize(selectorId, it)) }
        ?: IndexedSelectorFilter.All

private fun RealmSearchSelectorExpression.toIndexedSelectorFilter(metadata: AuthoringSearchMetadata): IndexedSelectorFilter =
    when (this) {
        is RealmSearchSelectorExpression.SelectorWrapper -> {
            value.toIndexedSelectorFilter(metadata)
        }

        is RealmSearchSelectorExpression.BinaryWrapper -> {
            when (value.operator_) {
                RealmSearchSelectorOperator.AND -> {
                    IndexedSelectorFilter.And(
                        value.left.toIndexedSelectorFilter(metadata),
                        value.right.toIndexedSelectorFilter(metadata),
                    )
                }

                RealmSearchSelectorOperator.OR -> {
                    IndexedSelectorFilter.Or(
                        value.left.toIndexedSelectorFilter(metadata),
                        value.right.toIndexedSelectorFilter(metadata),
                    )
                }

                else -> {
                    IndexedSelectorFilter.None
                }
            }
        }

        is RealmSearchSelectorExpression.NotWrapper -> {
            IndexedSelectorFilter.Not(value.expression.toIndexedSelectorFilter(metadata))
        }

        else -> {
            IndexedSelectorFilter.None
        }
    }

private fun SearchFacetRequest.resolve(
    candidates: List<IndexedAuthoringSearchCandidate>,
    metadata: AuthoringSearchMetadata,
): SearchFacetResult {
    val selector = metadata.selectorForFacet(facetId.value)
    val values = candidates.flatMap { it.selectors[selector].orEmpty() }.distinct().sorted()
    val normalized = values.map { metadata.normalize(selector, it) }.toSet()
    val prefix = partial?.let { metadata.normalize(selector, it) }.orEmpty()
    return SearchFacetResult(
        facetId = facetId,
        suggestions =
            values.filter { prefix.isEmpty() || metadata.normalize(selector, it).startsWith(prefix) }.take(MAX_FACET_RESULTS),
        accepted = validate.filter { metadata.normalize(selector, it) in normalized },
        rejected = validate.filterNot { metadata.normalize(selector, it) in normalized },
    )
}

private fun IndexedAuthoringSearchCandidate.context(terms: List<String>): AuthoringSearchContext =
    AuthoringSearchContext(
        ownerPath = ownerPath,
        match =
            terms.firstNotNullOfOrNull { term ->
                text.indexOf(term, ignoreCase = true).takeIf { it >= 0 }?.let { start ->
                    AuthoringSearchMatch(text, start, start + term.length)
                }
            },
    )

private fun ResourceFilter.withTarget(target: skirout.editor.v1.type_catalog.TypeExpression?): ResourceFilter =
    if (target == null) this else copy(assignableTo = SkirTypeCodec.decode(target).getOrThrow())

private const val SEARCH_SELECTION = "search"
private const val SEARCH_OWNER_SELECTION = "search:owners"
private const val MAX_SEARCH_RESULTS = 100
private const val MAX_FACET_RESULTS = 20
