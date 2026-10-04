package com.typewritermc.realm.search

import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.repository.utils.inPreviewTransaction
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import kotlinx.serialization.decodeFromString

internal data class IndexedAuthoringSearchCandidate(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val record: AuthoringRecord,
    val text: String,
    val ownerPath: List<ResourceId>,
    val selectors: Map<SearchSelectorId, Set<String>>,
)

internal sealed interface IndexedSelectorFilter {
    data class Match(
        val facet: SearchSelectorId,
        val normalized: String,
    ) : IndexedSelectorFilter

    data class And(
        val left: IndexedSelectorFilter,
        val right: IndexedSelectorFilter,
    ) : IndexedSelectorFilter

    data class Or(
        val left: IndexedSelectorFilter,
        val right: IndexedSelectorFilter,
    ) : IndexedSelectorFilter

    data class Not(
        val expression: IndexedSelectorFilter,
    ) : IndexedSelectorFilter

    data object All : IndexedSelectorFilter

    data object None : IndexedSelectorFilter
}

internal interface AuthoringSearchRepository {
    fun search(
        snapshot: SnapshotId,
        catalog: CheckedCatalog,
        query: String,
        contexts: Set<ResourceId>,
        selectors: IndexedSelectorFilter,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
        limit: Int,
    ): IndexedAuthoringSearchResult
}

internal sealed interface IndexedAuthoringSearchResult {
    data class Ready(
        val candidates: List<IndexedAuthoringSearchCandidate>,
    ) : IndexedAuthoringSearchResult

    data object SnapshotChanged : IndexedAuthoringSearchResult
}

/** Reads the transactionally maintained search projection and reapplies type constraints from its checked catalog. */
internal class SurrealAuthoringSearchRepository(
    private val database: Surreal,
) : AuthoringSearchRepository {
    override fun search(
        snapshot: SnapshotId,
        catalog: CheckedCatalog,
        query: String,
        contexts: Set<ResourceId>,
        selectors: IndexedSelectorFilter,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
        limit: Int,
    ): IndexedAuthoringSearchResult =
        database.inPreviewTransaction { transaction ->
            val revision =
                transaction
                    .query("SELECT VALUE revision FROM ONLY authoring_acceptance_fence:current;")
                    .take(0)
            if (revision.isNone || revision.isNull || snapshot != SnapshotId("realm:${revision.getLong()}")) {
                return@inPreviewTransaction IndexedAuthoringSearchResult.SnapshotChanged
            }
            IndexedAuthoringSearchResult.Ready(
                transaction.search(query, contexts, selectors, roots, target, limit, catalog),
            )
        }
}

private fun Transaction.search(
    query: String,
    contexts: Set<ResourceId>,
    selectors: IndexedSelectorFilter,
    roots: Set<TypeDefinitionId>,
    target: TypeUse.Named?,
    limit: Int,
    catalog: CheckedCatalog,
): List<IndexedAuthoringSearchCandidate> {
    require(limit > 0) { "Search limit must be positive." }
    val predicates = mutableListOf<String>()
    val bindings = mutableMapOf<String, Any?>()
    if (query.isNotBlank()) {
        predicates += "text @0@ \$query"
        bindings["query"] = query
    }
    if (contexts.isNotEmpty()) {
        predicates += "(resource IN \$context_resources OR owner_path CONTAINSANY \$context_values)"
        bindings["context_resources"] = contexts.map(ResourceId::unifiedSurrealId)
        bindings["context_values"] = contexts.map(ResourceId::value)
    }
    val selector = selectors.toSurrealPredicate()
    if (selector.query != "true") predicates += selector.query
    bindings += selector.bindings
    val where =
        predicates
            .takeIf { it.isNotEmpty() }
            ?.joinToString(" AND ")
            ?.let { " WHERE $it" }
            .orEmpty()
    val score = if (query.isBlank()) "0" else "search::score(0)"
    val candidates = mutableListOf<IndexedAuthoringSearchCandidate>()
    var offset = 0
    val pageSize = maxOf(limit, 256)
    while (candidates.size < limit) {
        val rows =
            this
                .query(
                    "SELECT resource, definition, content, text, owner_path, $score AS score FROM authoring_search$where " +
                        "ORDER BY score DESC, resource LIMIT \$row_limit START \$row_start;",
                    bindings + mapOf("row_limit" to pageSize, "row_start" to offset),
                ).take(0)
                .getArray()
        if (rows.len() == 0) break
        val ids =
            rows.map {
                it
                    .getObject()
                    .get("resource")
                    .getRecordId()
                    .toUnifiedResourceId()
            }
        val facets = selectors(ids)
        rows.forEach { rowValue ->
            val row = rowValue.getObject()
            val resource = row.get("resource").getRecordId().toUnifiedResourceId()
            val record = authoringStorageJson.decodeFromString<AuthoringRecord>(row.get("content").getString())
            if (!record.matches(roots, target, catalog)) return@forEach
            candidates +=
                IndexedAuthoringSearchCandidate(
                    resource,
                    ResourceDefinitionId(row.get("definition").getString()),
                    record,
                    row.get("text").getString(),
                    row.get("owner_path").getArray().map { ResourceId(it.getString()) },
                    facets[resource].orEmpty(),
                )
        }
        if (rows.len() < pageSize) break
        offset += rows.len()
    }
    return candidates.take(limit)
}

private fun Transaction.selectors(resources: List<ResourceId>): Map<ResourceId, Map<SearchSelectorId, Set<String>>> {
    if (resources.isEmpty()) return emptyMap()
    val rows =
        query(
            "SELECT resource, facet, display, normalized FROM authoring_search_selector WHERE resource IN \$resources " +
                "ORDER BY resource, facet, normalized;",
            mapOf("resources" to resources.map(ResourceId::unifiedSurrealId)),
        ).take(0)
            .getArray()
    return rows
        .groupBy {
            it
                .getObject()
                .get("resource")
                .getRecordId()
                .toUnifiedResourceId()
        }.mapValues { (_, values) ->
            values.groupBy { SearchSelectorId(it.getObject().get("facet").getString()) }.mapValues { (_, facetRows) ->
                facetRows.mapTo(linkedSetOf()) { it.getObject().get("display").getString() }
            }
        }
}

private fun AuthoringRecord.matches(
    roots: Set<TypeDefinitionId>,
    target: TypeUse.Named?,
    catalog: CheckedCatalog,
): Boolean {
    val actualDefinition =
        when (val selected = configuration) {
            is TypeSelection.Complete -> selected.use.definition
            is TypeSelection.Pending -> selected.definition
        }
    if (roots.isNotEmpty() && roots.none { catalog.isNominalSubtype(actualDefinition, it) }) return false
    if (target == null) return true
    return when (val selected = configuration) {
        is TypeSelection.Complete -> catalog.isReadableAs(selected.use, target)
        is TypeSelection.Pending -> catalog.knownApplications(selected).any { catalog.isReadableAs(it, target) }
    }
}

private data class SelectorPredicate(
    val query: String,
    val bindings: Map<String, Any?>,
)

private fun IndexedSelectorFilter.toSurrealPredicate(): SelectorPredicate {
    val bindings = linkedMapOf<String, Any?>()
    var next = 0

    fun bind(
        prefix: String,
        value: String,
    ): String {
        val name = "${prefix}_${next++}"
        bindings[name] = value
        return "\$$name"
    }

    fun IndexedSelectorFilter.render(): String =
        when (this) {
            IndexedSelectorFilter.All -> {
                "true"
            }

            IndexedSelectorFilter.None -> {
                "false"
            }

            is IndexedSelectorFilter.Match -> {
                val facetBinding = bind("selector_facet", facet.value)
                val valueBinding = bind("selector_value", normalized)
                "resource IN (SELECT VALUE resource FROM authoring_search_selector " +
                    "WHERE facet = $facetBinding AND normalized = $valueBinding)"
            }

            is IndexedSelectorFilter.And -> {
                "(${left.render()} AND ${right.render()})"
            }

            is IndexedSelectorFilter.Or -> {
                "(${left.render()} OR ${right.render()})"
            }

            is IndexedSelectorFilter.Not -> {
                "NOT (${expression.render()})"
            }
        }
    return SelectorPredicate(render(), bindings)
}
