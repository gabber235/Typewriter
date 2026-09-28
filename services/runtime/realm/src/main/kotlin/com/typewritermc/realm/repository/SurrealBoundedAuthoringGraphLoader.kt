package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataPath
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression

/** The rows selected by the database before typed values are hydrated. */
internal data class BoundedGraphSlice(
    val resources: List<StoredTypedResource>,
    val relations: List<StoredResourceRelation>,
    val diagnosticResources: List<StoredTypedResource> = emptyList(),
)

internal sealed interface BoundedGraphLoadResult {
    data class Success(
        val slice: BoundedGraphSlice,
    ) : BoundedGraphLoadResult

    data class Invalid(
        val result: AuthoringGraphQueryResult.Invalid,
    ) : BoundedGraphLoadResult
}

/**
 * Compiles graph selections into bounded database reads.
 *
 * The loader applies type compatibility and path prefix filters before accounting for graph budgets. The query
 * engine repeats those checks after hydration so every storage implementation has the same final semantics.
 */
internal class SurrealBoundedAuthoringGraphLoader(
    private val limits: AuthoringGraphLimits,
    private val catalog: TypeCatalog,
) {
    fun load(
        transaction: Transaction,
        selections: List<GraphSelection>,
    ): BoundedGraphLoadResult {
        if (selections.size > limits.maxSelections) return tooLarge("selection", limits.maxSelections)
        if (selections.map(GraphSelection::key).distinct().size != selections.size) {
            return invalid("duplicate-selection", "Graph selection keys must be unique.")
        }
        if (selections.any { selection -> selection.steps.any { it.maxDepth > limits.maxDepth } }) {
            return tooLarge("depth", limits.maxDepth)
        }

        val resources = linkedMapOf<ResourceId, StoredTypedResource>()
        val relations = linkedMapOf<String, StoredResourceRelation>()
        val diagnosticResources = linkedMapOf<ResourceId, StoredTypedResource>()
        selections.forEach { selection ->
            when (val result = loadSelection(transaction, selection, resources, relations, diagnosticResources)) {
                null -> Unit
                else -> return result
            }
        }
        return BoundedGraphLoadResult.Success(
            BoundedGraphSlice(
                resources = resources.values.sortedBy { it.id.value },
                relations = relations.values.sortedBy { it.id },
                diagnosticResources =
                    diagnosticResources.values
                        .filterNot { it.id in resources }
                        .sortedBy { it.id.value },
            ),
        )
    }

    private fun loadSelection(
        transaction: Transaction,
        selection: GraphSelection,
        resources: MutableMap<ResourceId, StoredTypedResource>,
        relations: MutableMap<String, StoredResourceRelation>,
        diagnosticResources: MutableMap<ResourceId, StoredTypedResource>,
    ): BoundedGraphLoadResult.Invalid? {
        val seed = selection.seed
        if (seed is ResourceSeed.Scan && seed.filter.definitions.isEmpty()) {
            return invalid(
                "unbounded-scan",
                "Graph scan ${selection.key} requires at least one resource definition.",
            )
        }

        val frontier =
            when (seed) {
                is ResourceSeed.Ids -> {
                    if (seed.values.size > limits.maxRoots) return tooLarge("root", limits.maxRoots)
                    val selected = transaction.loadResourcesByIds(seed.values, limits.maxRoots)
                    if (selected.size > limits.maxRoots) return tooLarge("root", limits.maxRoots)
                    val accepted =
                        selected.filter { resource ->
                            seed.requireAssignableTo == null ||
                                ResourceFilter(assignableTo = seed.requireAssignableTo).matches(resource, catalog)
                        }
                    selected
                        .filterNot { it in accepted }
                        .forEach { diagnosticResources[it.id] = it }
                    accepted.forEach { resources[it.id] = it }
                    if (resources.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                    accepted.map(StoredTypedResource::id).toSet()
                }

                is ResourceSeed.Scan -> {
                    val selected =
                        transaction.loadResourcesByDefinitions(
                            definitions = seed.filter.definitions,
                            limit = limits.maxResources,
                            assignableTo = seed.filter.assignableTo,
                            catalog = catalog,
                        )
                    if (selected.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                    selected.forEach { resources[it.id] = it }
                    if (resources.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                    selected.map(StoredTypedResource::id).toSet()
                }
            }

        var current = frontier
        selection.steps.forEach { step ->
            var depthFrontier = current
            val visited = current.toMutableSet()
            val stepFrontier = linkedSetOf<ResourceId>()
            for (depth in 1..step.maxDepth) {
                if (depthFrontier.isEmpty()) break
                val loadedEdges =
                    transaction.loadRelations(
                        frontier = depthFrontier,
                        direction = step.direction,
                        filter = step.relations,
                        limit = (limits.maxEdges - relations.size).coerceAtLeast(0),
                        definitions = step.target?.definitions.orEmpty(),
                        catalog = catalog,
                    )
                val adjacent =
                    loadedEdges
                        .mapNotNull { it.adjacent(depthFrontier, step) }
                        .toSet()
                val unvisited = adjacent - visited
                val loadedResources =
                    transaction.loadResourcesByIds(
                        unvisited,
                        unvisited.size,
                        step.target?.definitions.orEmpty(),
                    )
                val loadedById = loadedResources.associateBy(StoredTypedResource::id)
                val accepted =
                    adjacent.filterTo(linkedSetOf()) { id ->
                        step.target?.matches(resources[id] ?: loadedById[id], catalog) ?: true
                    }
                val next = accepted.filterTo(linkedSetOf()) { it !in visited }
                val newResources = next.count { it !in resources }
                if (newResources > limits.maxResources - resources.size) {
                    return tooLarge("resource", limits.maxResources)
                }
                next.forEach(visited::add)
                next.forEach { id -> resources[id] = requireNotNull(loadedById[id]) }
                if (resources.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                loadedEdges
                    .filter { it.adjacent(depthFrontier, step) in accepted }
                    .forEach { relation -> relations[relation.id] = relation }
                if (relations.size > limits.maxEdges) return tooLarge("edge", limits.maxEdges)
                depthFrontier = next
                if (depth >= step.minDepth) stepFrontier += next
            }
            if (step.relations is RelationFilter.PolicyDependencies && depthFrontier.isNotEmpty()) {
                val overflowEdges =
                    transaction.loadRelations(
                        frontier = depthFrontier,
                        direction = step.direction,
                        filter = step.relations,
                        limit = limits.maxEdges,
                        definitions = step.target?.definitions.orEmpty(),
                        catalog = catalog,
                    )
                val overflowIds =
                    overflowEdges
                        .mapNotNull { relation -> relation.adjacent(depthFrontier, step) }
                        .filterTo(linkedSetOf()) { it !in visited }
                val overflowResources =
                    transaction
                        .loadResourcesByIds(
                            overflowIds,
                            overflowIds.size,
                            step.target?.definitions.orEmpty(),
                        ).associateBy(StoredTypedResource::id)
                if (
                    overflowIds.any { id ->
                        step.target?.matches(resources[id] ?: overflowResources[id], catalog) ?: true
                    }
                ) {
                    return tooLarge("depth", step.maxDepth)
                }
            }
            current = stepFrontier
        }
        return null
    }

    private fun tooLarge(
        dimension: String,
        limit: Int,
    ): BoundedGraphLoadResult.Invalid = invalid("query-too-large", "Authoring graph $dimension limit $limit was exceeded.")

    private fun invalid(
        code: String,
        message: String,
    ): BoundedGraphLoadResult.Invalid = BoundedGraphLoadResult.Invalid(AuthoringGraphQueryResult.Invalid(code, message))

    private fun ResourceFilter.matches(
        resource: StoredTypedResource?,
        catalog: TypeCatalog,
    ): Boolean =
        resource != null &&
            (definitions.isEmpty() || resource.definition in definitions) &&
            (assignableTo == null || catalog.isAssignable(TypeExpression.Named(resource.root), assignableTo))
}

internal fun Transaction.loadResourcesByIds(
    ids: Collection<ResourceId>,
    limit: Int,
    definitions: Set<ResourceDefinitionId> = emptySet(),
): List<StoredTypedResource> {
    if (ids.isEmpty()) return emptyList()
    val definitionPredicate = if (definitions.isEmpty()) "" else "definition IN \$definitions AND "
    return query(
        "SELECT id, definition, root, value FROM resource " +
            "WHERE $definitionPredicate id IN \$ids ORDER BY id LIMIT \$row_limit;",
        mapOf(
            "ids" to ids.map(ResourceId::unifiedSurrealId),
            "row_limit" to limit + 1,
        ) +
            if (definitions.isEmpty()) {
                emptyMap()
            } else {
                mapOf("definitions" to definitions.map(ResourceDefinitionId::value))
            },
    ).take(0).getArray().map(::parseStoredResource)
}

internal fun Transaction.loadResourcesByDefinitions(
    definitions: Set<ResourceDefinitionId>,
    limit: Int,
    assignableTo: TypeExpression? = null,
    catalog: TypeCatalog = TypeCatalog(emptyList()),
): List<StoredTypedResource> {
    if (assignableTo == null) {
        return loadResourcePageByDefinitions(definitions, limit + 1)
    }
    val accepted = mutableListOf<StoredTypedResource>()
    var after: ResourceId? = null
    val pageSize = maxOf(limit + 1, MINIMUM_FILTER_PAGE_SIZE)
    while (accepted.size <= limit) {
        val page = loadResourcePageByDefinitions(definitions, pageSize, after)
        accepted +=
            page.filter { resource ->
                catalog.isAssignable(TypeExpression.Named(resource.root), assignableTo)
            }
        if (page.size < pageSize) break
        after = page.last().id
    }
    return accepted.take(limit + 1)
}

private fun Transaction.loadResourcePageByDefinitions(
    definitions: Set<ResourceDefinitionId>,
    limit: Int,
    after: ResourceId? = null,
): List<StoredTypedResource> {
    val cursorPredicate = if (after == null) "" else " AND id > \$after"
    return query(
        "SELECT id, definition, root, value FROM resource " +
            "WHERE definition IN \$definitions$cursorPredicate ORDER BY id LIMIT \$row_limit;",
        mapOf(
            "definitions" to definitions.map(ResourceDefinitionId::value),
            "row_limit" to limit,
        ) + (after?.let { mapOf("after" to it.unifiedSurrealId()) } ?: emptyMap()),
    ).take(0).getArray().map(::parseStoredResource)
}

private const val MINIMUM_FILTER_PAGE_SIZE = 256

internal fun Transaction.loadRelations(
    frontier: Set<ResourceId>,
    direction: RelationDirection,
    filter: RelationFilter,
    limit: Int,
    definitions: Set<ResourceDefinitionId> = emptySet(),
    catalog: TypeCatalog = TypeCatalog(emptyList()),
): List<StoredResourceRelation> {
    val endpointPredicate =
        when (direction) {
            RelationDirection.OUTGOING -> "in IN \$frontier"
            RelationDirection.INCOMING -> "out IN \$frontier"
            RelationDirection.BOTH -> "(in IN \$frontier OR out IN \$frontier)"
        }
    val adjacentDefinitionPredicate =
        if (definitions.isEmpty()) {
            null
        } else {
            when (direction) {
                RelationDirection.OUTGOING -> {
                    "out IN (SELECT VALUE id FROM resource WHERE definition IN \$definitions)"
                }

                RelationDirection.INCOMING -> {
                    "in IN (SELECT VALUE id FROM resource WHERE definition IN \$definitions)"
                }

                RelationDirection.BOTH -> {
                    "((in IN \$frontier AND out IN (SELECT VALUE id FROM resource WHERE definition IN \$definitions)) OR " +
                        "(out IN \$frontier AND in IN (SELECT VALUE id FROM resource WHERE definition IN \$definitions)))"
                }
            }
        }
    val filterPredicate =
        when (filter) {
            RelationFilter.Any -> {
                null
            }

            is RelationFilter.Declared -> {
                if (filter.relationIds.isEmpty()) {
                    "origin_kind = 'declared'"
                } else {
                    "origin_kind = 'declared' AND relation_id IN \$relation_ids"
                }
            }

            is RelationFilter.OrdinaryReferences -> {
                "origin_kind = 'reference'"
            }

            is RelationFilter.PolicyDependencies -> {
                filter.databasePredicate()
            }
        }
    val predicates = listOfNotNull(endpointPredicate, adjacentDefinitionPredicate, filterPredicate)
    val baseBindings =
        buildMap<String, Any?>(4) {
            put("frontier", frontier.map(ResourceId::unifiedSurrealId))
            if (definitions.isNotEmpty()) put("definitions", definitions.map(ResourceDefinitionId::value))
            if (filter is RelationFilter.Declared && filter.relationIds.isNotEmpty()) {
                put("relation_ids", filter.relationIds.map { it.value })
            }
            if (filter is RelationFilter.PolicyDependencies && filter.declaredRelationIds.isNotEmpty()) {
                put("relation_ids", filter.declaredRelationIds.map { it.value })
            }
        }
    val accepted = mutableListOf<StoredResourceRelation>()
    var after: String? = null
    val pageSize = maxOf(limit + 1, MINIMUM_FILTER_PAGE_SIZE)
    while (accepted.size <= limit) {
        val cursorPredicate = if (after == null) "" else " AND id > \$after"
        val page =
            query(
                "SELECT id, in, out, origin FROM resource_relation " +
                    "WHERE ${predicates.joinToString(" AND ")}$cursorPredicate " +
                    "ORDER BY id LIMIT \$row_limit;",
                baseBindings +
                    mapOf("row_limit" to pageSize) +
                    (after?.let { mapOf("after" to RecordId("resource_relation", it)) } ?: emptyMap()),
            ).take(0).getArray().map(::parseStoredRelation)
        accepted += page.filter { relation -> relation.matches(filter, frontier, catalog) }
        if (page.size < pageSize) break
        after = page.last().id
    }
    return accepted.take(limit + 1)
}

private fun StoredResourceRelation.matches(
    filter: RelationFilter,
    frontier: Set<ResourceId>,
    catalog: TypeCatalog,
): Boolean =
    when (filter) {
        RelationFilter.Any -> {
            true
        }

        is RelationFilter.Declared -> {
            origin is ResourceRelationOrigin.Declared
        }

        is RelationFilter.OrdinaryReferences -> {
            val reference = origin as? ResourceRelationOrigin.Reference ?: return false
            (filter.sourcePathPrefixes.isEmpty() || filter.sourcePathPrefixes.any(reference.sourcePath::startsWith)) &&
                (filter.expectedTarget == null || catalog.isAssignable(reference.expectedTarget, filter.expectedTarget))
        }

        is RelationFilter.PolicyDependencies -> {
            when (val relationOrigin = origin) {
                is ResourceRelationOrigin.Declared -> relationOrigin.relationId in filter.declaredRelationIds
                is ResourceRelationOrigin.Reference -> adjacent(frontier, filter) != null
            }
        }
    }

private fun RelationFilter.PolicyDependencies.databasePredicate(): String {
    val predicates =
        buildList {
            if (declaredRelationIds.isNotEmpty()) {
                val endpoint =
                    when (declaredDirection) {
                        RelationDirection.OUTGOING -> "in IN \$frontier"
                        RelationDirection.INCOMING -> "out IN \$frontier"
                        RelationDirection.BOTH -> "(in IN \$frontier OR out IN \$frontier)"
                    }
                add("(origin_kind = 'declared' AND relation_id IN \$relation_ids AND $endpoint)")
            }
            if (outgoingReferences) add("(origin_kind = 'reference' AND in IN \$frontier)")
            if (incomingReferences) add("(origin_kind = 'reference' AND out IN \$frontier)")
        }
    return predicates.joinToString(" OR ", prefix = "(", postfix = ")")
}

private fun StoredResourceRelation.adjacent(
    frontier: Set<ResourceId>,
    step: RelationStep,
): ResourceId? =
    when (val filter = step.relations) {
        is RelationFilter.PolicyDependencies -> adjacent(frontier, filter)
        else -> adjacent(frontier, step.direction)
    }

private fun StoredResourceRelation.adjacent(
    frontier: Set<ResourceId>,
    filter: RelationFilter.PolicyDependencies,
): ResourceId? =
    when (origin) {
        is ResourceRelationOrigin.Declared -> {
            adjacent(frontier, filter.declaredDirection)
        }

        is ResourceRelationOrigin.Reference -> {
            when {
                filter.outgoingReferences && source in frontier -> target
                filter.incomingReferences && target in frontier -> source
                else -> null
            }
        }
    }

private fun StoredResourceRelation.adjacent(
    frontier: Set<ResourceId>,
    direction: RelationDirection,
): ResourceId? =
    when (direction) {
        RelationDirection.OUTGOING -> {
            target.takeIf { source in frontier }
        }

        RelationDirection.INCOMING -> {
            source.takeIf { target in frontier }
        }

        RelationDirection.BOTH -> {
            when {
                source in frontier -> target
                target in frontier -> source
                else -> null
            }
        }
    }

private fun DataPath.startsWith(prefix: DataPath): Boolean =
    segments.size >= prefix.segments.size && segments.take(prefix.segments.size) == prefix.segments
