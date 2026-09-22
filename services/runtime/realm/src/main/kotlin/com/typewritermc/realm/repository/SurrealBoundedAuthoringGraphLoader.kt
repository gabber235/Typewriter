package com.typewritermc.realm.repository

import com.surrealdb.Transaction
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataPath
import com.typewritermc.types.ResourceId

/** The rows selected by the database before typed values are hydrated. */
internal data class BoundedGraphSlice(
    val resources: List<StoredTypedResource>,
    val relations: List<StoredResourceRelation>,
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
 * The loader deliberately does not apply type assignability or path prefix semantics. Those checks belong to
 * [AuthoringGraphQueryEngine], which evaluates the bounded candidate slice with the same semantics for every
 * storage implementation.
 */
internal class SurrealBoundedAuthoringGraphLoader(
    private val limits: AuthoringGraphLimits,
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
        selections.forEach { selection ->
            when (val result = loadSelection(transaction, selection, resources, relations)) {
                null -> Unit
                else -> return result
            }
        }
        return BoundedGraphLoadResult.Success(
            BoundedGraphSlice(
                resources = resources.values.sortedBy { it.id.value },
                relations = relations.values.sortedBy { it.id },
            ),
        )
    }

    private fun loadSelection(
        transaction: Transaction,
        selection: GraphSelection,
        resources: MutableMap<ResourceId, StoredTypedResource>,
        relations: MutableMap<String, StoredResourceRelation>,
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
                    selected.forEach { resources[it.id] = it }
                    if (resources.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                    selected.map(StoredTypedResource::id).toSet()
                }

                is ResourceSeed.Scan -> {
                    val selected = transaction.loadResourcesByDefinitions(seed.filter.definitions, limits.maxResources)
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
                    )
                val adjacent =
                    loadedEdges
                        .mapNotNull { it.adjacent(depthFrontier, step.direction) }
                        .filter(visited::add)
                        .toSet()
                val loadedResources =
                    transaction.loadResourcesByIds(
                        adjacent,
                        (limits.maxResources - resources.size).coerceAtLeast(0),
                        step.target?.definitions.orEmpty(),
                    )
                if (loadedResources.size > limits.maxResources - resources.size) {
                    return tooLarge("resource", limits.maxResources)
                }
                val loadedById = loadedResources.associateBy(StoredTypedResource::id)
                val accepted =
                    adjacent.filterTo(linkedSetOf()) { id ->
                        step.target?.matches(loadedById[id]) ?: true
                    }
                accepted.forEach { id -> resources[id] = requireNotNull(loadedById[id]) }
                if (resources.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                loadedEdges
                    .filter { it.adjacent(depthFrontier, step.direction) in accepted }
                    .forEach { relation -> relations[relation.id] = relation }
                if (relations.size > limits.maxEdges) return tooLarge("edge", limits.maxEdges)
                depthFrontier = accepted
                if (depth >= step.minDepth) stepFrontier += accepted
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

    private fun ResourceFilter.matches(resource: StoredTypedResource?): Boolean =
        resource != null && (definitions.isEmpty() || resource.definition in definitions)
}

internal fun Transaction.loadResourcesByIds(
    ids: Collection<ResourceId>,
    limit: Int,
    definitions: Set<ResourceDefinitionId> = emptySet(),
): List<StoredTypedResource> {
    if (ids.isEmpty()) return emptyList()
    val definitionPredicate = if (definitions.isEmpty()) "" else "definition IN \$definitions AND "
    return query(
        "SELECT id, definition, type_id, type_revision, value FROM resource " +
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
): List<StoredTypedResource> =
    query(
        "SELECT id, definition, type_id, type_revision, value FROM resource " +
            "WHERE definition IN \$definitions ORDER BY id LIMIT \$row_limit;",
        mapOf(
            "definitions" to definitions.map { it.value },
            "row_limit" to limit + 1,
        ),
    ).take(0).getArray().map(::parseStoredResource)

internal fun Transaction.loadRelations(
    frontier: Set<ResourceId>,
    direction: RelationDirection,
    filter: RelationFilter,
    limit: Int,
    definitions: Set<ResourceDefinitionId> = emptySet(),
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
        }
    val predicates = listOfNotNull(endpointPredicate, adjacentDefinitionPredicate, filterPredicate)
    val bindings =
        buildMap<String, Any?>(4) {
            put("frontier", frontier.map(ResourceId::unifiedSurrealId))
            put("row_limit", limit + 1)
            if (definitions.isNotEmpty()) put("definitions", definitions.map(ResourceDefinitionId::value))
            if (filter is RelationFilter.Declared && filter.relationIds.isNotEmpty()) {
                put("relation_ids", filter.relationIds.map { it.value })
            }
        }
    return query(
        "SELECT id, in, out, origin FROM resource_relation WHERE ${predicates.joinToString(" AND ")} " +
            "ORDER BY id LIMIT \$row_limit;",
        bindings,
    ).take(0).getArray().map(::parseStoredRelation).filter { relation ->
        when (filter) {
            RelationFilter.Any -> {
                true
            }

            is RelationFilter.Declared -> {
                relation.origin is ResourceRelationOrigin.Declared
            }

            is RelationFilter.OrdinaryReferences -> {
                val reference = relation.origin as? ResourceRelationOrigin.Reference ?: return@filter false
                filter.sourcePathPrefixes.isEmpty() || filter.sourcePathPrefixes.any(reference.sourcePath::startsWith)
            }
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
