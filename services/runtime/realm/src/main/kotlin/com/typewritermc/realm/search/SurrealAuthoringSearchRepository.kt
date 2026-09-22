package com.typewritermc.realm.search

import com.surrealdb.Surreal
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.ResourceId

/** One ranked index row with the selector and ownership metadata needed by search policy. */
internal data class IndexedAuthoringSearchCandidate(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val text: String,
    val ownerPath: List<ResourceId>,
    val selectors: Map<String, Set<String>>,
)

internal sealed interface IndexedSelectorFilter {
    data class Match(
        val facet: String,
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

internal val IndexedSelectorFilter.requiresDefinitionUniverse: Boolean
    get() =
        when (this) {
            IndexedSelectorFilter.All,
            IndexedSelectorFilter.None,
            is IndexedSelectorFilter.Match,
            -> false

            is IndexedSelectorFilter.And -> left.requiresDefinitionUniverse || right.requiresDefinitionUniverse

            is IndexedSelectorFilter.Or -> left.requiresDefinitionUniverse || right.requiresDefinitionUniverse

            is IndexedSelectorFilter.Not -> true
        }

/** Retrieves bounded search candidates before typed resource hydration. */
internal fun interface AuthoringSearchRepository {
    fun search(
        query: String,
        definitions: Set<ResourceDefinitionId>,
        allowedResources: Set<ResourceId>?,
        selectors: IndexedSelectorFilter,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate>
}

/** Executes candidate retrieval only against normalized indexed search tables. */
internal class SurrealAuthoringSearchRepository(
    private val database: Surreal,
) : AuthoringSearchRepository {
    override fun search(
        query: String,
        definitions: Set<ResourceDefinitionId>,
        allowedResources: Set<ResourceId>?,
        selectors: IndexedSelectorFilter,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate> {
        if (allowedResources?.isEmpty() == true) return emptyList()
        if (definitions.isEmpty() && selectors.requiresDefinitionUniverse) return emptyList()
        val predicates = mutableListOf<String>()
        val bindings = mutableMapOf<String, Any?>("row_limit" to limit)
        if (query.isNotBlank()) {
            predicates += "(text @0@ \$query OR text @1@ \$query)"
            bindings["query"] = query
        }
        if (definitions.isNotEmpty()) {
            predicates += "definition IN \$definitions"
            bindings["definitions"] = definitions.map(ResourceDefinitionId::value)
        }
        if (allowedResources != null) {
            predicates += "resource IN \$allowed"
            bindings["allowed"] = allowedResources.map(ResourceId::unifiedSurrealId)
        }
        val selectorPredicate = selectors.toSurrealPredicate()
        bindings.putAll(selectorPredicate.bindings)
        selectorPredicate.query.takeUnless { it == "true" }?.let(predicates::add)
        val where =
            predicates
                .takeIf(List<String>::isNotEmpty)
                ?.joinToString(" AND ")
                ?.let { " WHERE $it" }
                .orEmpty()
        val score = if (query.isBlank()) "0" else "search::score(0) + search::score(1)"
        val rows =
            database
                .query(
                    "SELECT resource, definition, text, owner_path, $score AS score " +
                        "FROM authoring_search$where ORDER BY score DESC, resource LIMIT \$row_limit;",
                    bindings,
                ).take(0)
                .getArray()
        val ids =
            rows.map {
                it
                    .getObject()
                    .get("resource")
                    .getRecordId()
                    .toUnifiedResourceId()
            }
        val selectors = selectors(ids)
        return rows.map { value ->
            val row = value.getObject()
            val resource = row.get("resource").getRecordId().toUnifiedResourceId()
            IndexedAuthoringSearchCandidate(
                resource = resource,
                definition = ResourceDefinitionId(row.get("definition").getString()),
                text = row.get("text").getString(),
                ownerPath = row.get("owner_path").getArray().map { ResourceId(it.getString()) },
                selectors = selectors[resource].orEmpty(),
            )
        }
    }

    private fun selectors(resources: List<ResourceId>): Map<ResourceId, Map<String, Set<String>>> {
        if (resources.isEmpty()) return emptyMap()
        val rows =
            database
                .query(
                    "SELECT resource, facet, normalized, display FROM authoring_search_selector " +
                        "WHERE resource IN \$resources ORDER BY resource, facet, normalized;",
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
                values
                    .groupBy { it.getObject().get("facet").getString() }
                    .mapValues { (_, facetRows) -> facetRows.mapTo(linkedSetOf()) { it.getObject().get("display").getString() } }
            }
    }
}

internal data class IndexedSelectorPredicate(
    val query: String,
    val bindings: Map<String, String>,
)

internal fun IndexedSelectorFilter.toSurrealPredicate(): IndexedSelectorPredicate {
    val bindings = linkedMapOf<String, Any?>()
    val query = toSurreal(SelectorBindings(bindings))
    return IndexedSelectorPredicate(query, bindings.mapValues { (_, value) -> value as String })
}

private class SelectorBindings(
    private val values: MutableMap<String, Any?>,
) {
    private var next = 0

    fun bind(
        prefix: String,
        value: String,
    ): String {
        val name = "${prefix}_${next++}"
        values[name] = value
        return "\$$name"
    }
}

private fun IndexedSelectorFilter.toSurreal(bindings: SelectorBindings): String =
    when (this) {
        IndexedSelectorFilter.All -> {
            "true"
        }

        IndexedSelectorFilter.None -> {
            "false"
        }

        is IndexedSelectorFilter.Match -> {
            val facetBinding = bindings.bind("selector_facet", facet)
            val valueBinding = bindings.bind("selector_value", normalized)
            "resource IN (SELECT VALUE resource FROM authoring_search_selector " +
                "WHERE facet = $facetBinding AND normalized = $valueBinding)"
        }

        is IndexedSelectorFilter.And -> {
            "(${left.toSurreal(bindings)} AND ${right.toSurreal(bindings)})"
        }

        is IndexedSelectorFilter.Or -> {
            "(${left.toSurreal(bindings)} OR ${right.toSurreal(bindings)})"
        }

        is IndexedSelectorFilter.Not -> {
            "NOT (${expression.toSurreal(bindings)})"
        }
    }
