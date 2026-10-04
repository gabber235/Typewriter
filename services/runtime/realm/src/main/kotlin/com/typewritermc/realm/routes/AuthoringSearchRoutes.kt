package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import com.typewritermc.realm.search.IndexedAuthoringSearchResult
import com.typewritermc.realm.search.IndexedSelectorFilter
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringSearchHit
import skirout.editor.v1.authoring.PresentationSubject
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.authoring.SearchFacetRequest
import skirout.editor.v1.authoring.SearchFacetResult
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.editor.v1.catalog.ResourceDefinitionId as SkirResourceDefinitionId
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.editor.v1.type_catalog.SnapshotId as SkirSnapshotId
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse
import skirout.editor.v1.typed_value.PortableValue as SkirPortableValue

internal class AuthoringSearchRoutes(
    private val repository: AuthoringSearchRepository,
    private val snapshots: AuthoringSnapshotStore,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchAuthoring) { call -> search(call.request) }
        }

    private fun search(request: SearchAuthoringRequest): SearchAuthoringResponse {
        val requestedSnapshot = SnapshotId(request.snapshot.value)
        val lease =
            try {
                snapshots.retain(requestedSnapshot)
            } catch (_: IllegalArgumentException) {
                return invalidSearch("snapshot_missing", "The requested authoring snapshot is no longer retained.")
            }
        lease.use { snapshot ->
            val root = snapshot.root
            if (root.catalog.generation.value != request.generation.value) {
                return SearchAuthoringResponse.createCatalogChanged(
                    actualGeneration = SkirCatalogGeneration(value = root.catalog.generation.value),
                )
            }
            val prepared =
                try {
                    PreparedSearch(
                        contexts = request.contexts.mapTo(linkedSetOf()) { ResourceId(it.value) },
                        selectors = request.query.toIndexedSelectorFilter(),
                        roots = request.roots.mapTo(linkedSetOf()) { it.toDomain() },
                        target = request.target?.toDomain(),
                    )
                } catch (_: IllegalArgumentException) {
                    return invalidSearch("invalid_search", "The search request contains invalid type or selector data.")
                }
            val result =
                repository.search(
                    snapshot = root.id,
                    catalog = root.catalog.checked,
                    query = request.query.normalizedQuery,
                    contexts = prepared.contexts,
                    selectors = prepared.selectors,
                    roots = prepared.roots,
                    target = prepared.target,
                    limit = MAX_SEARCH_CANDIDATES,
                )
            if (result is IndexedAuthoringSearchResult.SnapshotChanged) {
                return invalidSearch("snapshot_changed", "The authoring snapshot changed before search completed.")
            }
            val candidates = (result as IndexedAuthoringSearchResult.Ready).candidates
            val hits =
                candidates.take(MAX_SEARCH_RESULTS).mapNotNull { candidate ->
                    val record = root.resources[candidate.resource] ?: return@mapNotNull null
                    val definition = root.resourceDefinitions[candidate.resource] ?: return@mapNotNull null
                    candidate.toWire(record, definition.value)
                }
            return SearchAuthoringResponse.createSuccess(
                snapshot = SkirSnapshotId(value = root.id.value),
                generation = SkirCatalogGeneration(value = root.catalog.generation.value),
                hits = hits,
                facets = request.facets.map { it.resolve(candidates) },
                diagnostics = emptyList(),
            )
        }
    }
}

private data class PreparedSearch(
    val contexts: Set<ResourceId>,
    val selectors: IndexedSelectorFilter,
    val roots: Set<TypeDefinitionId>,
    val target: TypeUse.Named?,
)

private fun invalidSearch(
    code: String,
    message: String,
): SearchAuthoringResponse =
    SearchAuthoringResponse.createInvalid(
        diagnostics = listOf(AuthoringDiagnostic(code = code, message = message, resource = null, path = null)),
    )

private fun IndexedAuthoringSearchCandidate.toWire(
    record: AuthoringRecord,
    definition: String,
): AuthoringSearchHit {
    val wireResource = SkirResourceId(value = resource.value)
    val resourceDefinition = SkirResourceDefinitionId(value = definition)
    return AuthoringSearchHit(
        resource = wireResource,
        definition = resourceDefinition,
        subject =
            PresentationSubject(
                resource = wireResource,
                definition = resourceDefinition,
                content = SkirAuthoringValueCodec.encode(record).getOrThrow(),
                descriptor = SkirDataValueCodec.encode(DataValue.StringValue(record.displayName(this.resource))).getOrThrow(),
            ),
        context =
            SkirPortableValue(
                actualType = SkirTypeCodec.encode(TypeUse.Scalar(ScalarKind.Text)).getOrThrow(),
                payload = SkirDataValueCodec.encode(DataValue.StringValue(text)).getOrThrow(),
            ),
    )
}

private fun AuthoringRecord.displayName(resource: ResourceId): String =
    sequenceOf("name", "title")
        .mapNotNull(fields::get)
        .mapNotNull { it.displayText() }
        .firstOrNull(String::isNotBlank)
        ?: resource.value

private fun DataValue.displayText(): String? =
    when (this) {
        is DataValue.StringValue -> value
        is DataValue.EnumCase -> key
        is DataValue.Named -> payload.displayText()
        else -> null
    }

private fun skirout.editor.v1.search.RealmSearchQuery.toIndexedSelectorFilter(): IndexedSelectorFilter =
    selectorExpression?.toIndexedSelectorFilter()
        ?: selectors
            .map(RealmSearchSelector::toIndexedSelectorFilter)
            .reduceOrNull(IndexedSelectorFilter::And)
        ?: IndexedSelectorFilter.All

private fun RealmSearchSelector.toIndexedSelectorFilter(): IndexedSelectorFilter =
    value
        ?.trim()
        ?.lowercase()
        ?.takeIf(String::isNotEmpty)
        ?.let { IndexedSelectorFilter.Match(SearchSelectorId(selectorId), it) }
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
    val values = candidates.flatMap { it.selectors[SearchSelectorId(facetId.value)].orEmpty() }.distinct().sorted()
    val normalized = values.map(String::lowercase).toSet()
    val prefix = partial?.trim()?.lowercase().orEmpty()
    return SearchFacetResult(
        facetId = facetId,
        suggestions = values.filter { prefix.isEmpty() || it.lowercase().startsWith(prefix) }.take(MAX_FACET_RESULTS),
        accepted = validate.filter { it.lowercase() in normalized },
        rejected = validate.filterNot { it.lowercase() in normalized },
    )
}

private fun skirout.editor.v1.type_catalog.TypeDefinitionId.toDomain(): TypeDefinitionId =
    (
        SkirTypeCodec
            .decode(SkirTypeUse.NamedWrapper(SkirNamedTypeUse(definition = this, arguments = emptyList())))
            .getOrThrow() as TypeUse.Named
    ).definition

private fun SkirNamedTypeUse.toDomain(): TypeUse.Named = SkirTypeCodec.decode(SkirTypeUse.NamedWrapper(this)).getOrThrow() as TypeUse.Named

private const val MAX_SEARCH_CANDIDATES = 256
private const val MAX_SEARCH_RESULTS = 100
private const val MAX_FACET_RESULTS = 20
