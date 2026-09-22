package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.AuthoringSearchMatch
import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.GraphSelection
import com.typewritermc.realm.repository.ResourceFilter
import com.typewritermc.realm.repository.ResourceSeed
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
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchAuthoringGraph) { call ->
                runCatching { search(call.request) }.getOrElse { it.toInvalidSearchResponse() }
            }
        }

    private suspend fun search(request: SearchAuthoringGraphRequest): SearchAuthoringGraphResponse {
        val filter = request.resources.toDomain().withTarget(request.referenceTarget)
        val selectors = request.query.toIndexedSelectorFilter()
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
        val scope = request.scope?.toDomain()?.let { resolveScope(request.generation.value, it, filter) }
        if (scope is ScopeResolution.Response) return scope.value

        val candidates =
            search
                .search(
                    query = request.query.terms.joinToString(" "),
                    definitions = filter.definitions,
                    allowedResources = (scope as? ScopeResolution.Resources)?.ids,
                    selectors = selectors,
                    limit = MAX_SEARCH_CANDIDATES,
                ).take(MAX_SEARCH_RESULTS)
        val facets = request.facets.map { it.resolve(candidates) }
        val selections =
            listOf(
                GraphSelection(
                    SEARCH_SELECTION,
                    ResourceSeed.Ids(candidates.map(IndexedAuthoringSearchCandidate::resource), filter.assignableTo),
                ),
                GraphSelection(
                    SEARCH_OWNER_SELECTION,
                    ResourceSeed.Ids(candidates.flatMap(IndexedAuthoringSearchCandidate::ownerPath).distinct()),
                ),
            )
        return when (val result = graph.query(request.generation.value, selections)) {
            is AuthoringGraphQueryResult.CatalogChanged -> result.toWire()
            is AuthoringGraphQueryResult.Invalid -> result.toWire()
            is AuthoringGraphQueryResult.Success -> result.toSearchResponse(candidates, request.query.terms, facets)
        }
    }

    private suspend fun resolveScope(
        generation: String,
        scope: GraphSelection,
        filter: ResourceFilter,
    ): ScopeResolution {
        val constrained =
            scope.copy(
                seed =
                    when (val seed = scope.seed) {
                        is ResourceSeed.Ids -> seed
                        is ResourceSeed.Scan -> ResourceSeed.Scan(seed.filter.intersect(filter))
                    },
            )
        return when (val result = graph.query(generation, listOf(constrained))) {
            is AuthoringGraphQueryResult.CatalogChanged -> {
                ScopeResolution.Response(result.toWire())
            }

            is AuthoringGraphQueryResult.Invalid -> {
                ScopeResolution.Response(result.toWire())
            }

            is AuthoringGraphQueryResult.Success -> {
                ScopeResolution.Resources(
                    result.snapshot.selections
                        .single()
                        .resourceIds
                        .toSet(),
                )
            }
        }
    }

    private fun AuthoringGraphQueryResult.Success.toSearchResponse(
        candidates: List<IndexedAuthoringSearchCandidate>,
        terms: List<String>,
        facets: List<SearchFacetResult>,
    ): SearchAuthoringGraphResponse {
        val resources = snapshot.resources.associateBy(AuthoringGraphResource::id)
        val hits =
            candidates.mapNotNull { candidate ->
                val resource = resources[candidate.resource] ?: return@mapNotNull null
                AuthoringSearchHit(
                    resource = resource.id.toWire(),
                    definition = resource.definition.toWire(),
                    subject = subjects.toWire(subjects.project(resource, candidate.ownerPath, snapshot.toWorkingGraph())),
                    context = subjects.encode(candidate.context(terms)),
                    ownerPath = candidate.ownerPath.map(ResourceId::toWire),
                )
            }
        return SearchAuthoringGraphResponse.createSuccess(
            generation = CatalogGeneration(value = snapshot.generation),
            sequence = snapshot.sequence,
            hits = hits,
            facets = facets,
            diagnostics = emptyList(),
        )
    }
}

private sealed interface ScopeResolution {
    data class Resources(
        val ids: Set<ResourceId>,
    ) : ScopeResolution

    data class Response(
        val value: SearchAuthoringGraphResponse,
    ) : ScopeResolution
}

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

private fun skirout.editor.v1.search.RealmSearchQuery.toIndexedSelectorFilter(): IndexedSelectorFilter =
    selectorExpression?.toIndexedSelectorFilter()
        ?: selectors
            .map(RealmSearchSelector::toIndexedSelectorFilter)
            .fold<IndexedSelectorFilter, IndexedSelectorFilter>(IndexedSelectorFilter.All, IndexedSelectorFilter::And)

private fun RealmSearchSelector.toIndexedSelectorFilter(): IndexedSelectorFilter =
    value
        ?.trim()
        ?.lowercase()
        ?.takeIf(String::isNotEmpty)
        ?.let { IndexedSelectorFilter.Match(selectorId, it) }
        ?: IndexedSelectorFilter.All

private fun RealmSearchSelectorExpression.toIndexedSelectorFilter(): IndexedSelectorFilter =
    when (this) {
        is RealmSearchSelectorExpression.SelectorWrapper -> {
            value.toIndexedSelectorFilter()
        }

        is RealmSearchSelectorExpression.BinaryWrapper -> {
            when (value.operator_) {
                RealmSearchSelectorOperator.AND -> {
                    IndexedSelectorFilter.And(
                        value.left.toIndexedSelectorFilter(),
                        value.right.toIndexedSelectorFilter(),
                    )
                }

                RealmSearchSelectorOperator.OR -> {
                    IndexedSelectorFilter.Or(
                        value.left.toIndexedSelectorFilter(),
                        value.right.toIndexedSelectorFilter(),
                    )
                }

                else -> {
                    IndexedSelectorFilter.None
                }
            }
        }

        is RealmSearchSelectorExpression.NotWrapper -> {
            IndexedSelectorFilter.Not(value.expression.toIndexedSelectorFilter())
        }

        else -> {
            IndexedSelectorFilter.None
        }
    }

private fun SearchFacetRequest.resolve(candidates: List<IndexedAuthoringSearchCandidate>): SearchFacetResult {
    val values = candidates.flatMap { it.selectors[facetId.value].orEmpty() }.distinct().sorted()
    val normalized = values.map(String::lowercase).toSet()
    val prefix = partial?.trim()?.lowercase().orEmpty()
    return SearchFacetResult(
        facetId = facetId,
        suggestions = values.filter { prefix.isEmpty() || it.lowercase().startsWith(prefix) }.take(MAX_FACET_RESULTS),
        accepted = validate.filter { it.lowercase() in normalized },
        rejected = validate.filterNot { it.lowercase() in normalized },
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

private fun ResourceFilter.intersect(other: ResourceFilter): ResourceFilter =
    ResourceFilter(
        when {
            definitions.isEmpty() -> other.definitions
            other.definitions.isEmpty() -> definitions
            else -> definitions intersect other.definitions
        },
        other.assignableTo ?: assignableTo,
    )

private const val SEARCH_SELECTION = "search"
private const val SEARCH_OWNER_SELECTION = "search:owners"
private const val MAX_SEARCH_CANDIDATES = 256
private const val MAX_SEARCH_RESULTS = 100
private const val MAX_FACET_RESULTS = 20
