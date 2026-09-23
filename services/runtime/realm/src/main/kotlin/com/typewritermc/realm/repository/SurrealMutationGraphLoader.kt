package com.typewritermc.realm.repository

import com.surrealdb.Transaction
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.types.ResourceId

/** Loads only the connected graph component that a mutation can change or invalidate. */
internal class SurrealMutationGraphLoader {
    fun load(
        transaction: Transaction,
        roots: Set<ResourceId>,
        requirement: GraphReadRequirement,
    ): MutationGraphLoadResult {
        if (roots.size > requirement.maximumResources) {
            return tooLarge("root", requirement.maximumResources)
        }
        val resources = linkedMapOf<ResourceId, StoredTypedResource>()
        val relations = linkedMapOf<String, StoredResourceRelation>()
        val initial = transaction.loadResourcesByIds(roots, requirement.maximumResources)
        if (initial.size > requirement.maximumResources) {
            return tooLarge("resource", requirement.maximumResources)
        }
        initial.forEach { resources[it.id] = it }

        var frontier = initial.mapTo(linkedSetOf(), StoredTypedResource::id)
        var depth = 0
        while (frontier.isNotEmpty()) {
            if (depth >= requirement.maximumDepth) {
                val remaining = loadRelations(transaction, frontier, requirement, 1)
                if (remaining.any { it.id !in relations }) {
                    return tooLarge("depth", requirement.maximumDepth)
                }
                break
            }

            val loaded =
                loadRelations(
                    transaction = transaction,
                    frontier = frontier,
                    requirement = requirement,
                    limit = (requirement.maximumEdges - relations.size).coerceAtLeast(0),
                )
            loaded.forEach { relations[it.id] = it }
            if (relations.size > requirement.maximumEdges) {
                return tooLarge("edge", requirement.maximumEdges)
            }

            val adjacent =
                loaded
                    .flatMap { relation -> listOf(relation.source, relation.target) }
                    .filter { it !in resources }
                    .toSet()
            if (resources.size + adjacent.size > requirement.maximumResources) {
                return tooLarge("resource", requirement.maximumResources)
            }
            val loadedResources =
                transaction.loadResourcesByIds(
                    ids = adjacent,
                    limit = requirement.maximumResources - resources.size,
                    definitions = requirement.definitions,
                )
            if (loadedResources.size > requirement.maximumResources - resources.size) {
                return tooLarge("resource", requirement.maximumResources)
            }
            loadedResources.forEach { resources[it.id] = it }
            frontier = loadedResources.mapTo(linkedSetOf(), StoredTypedResource::id)
            depth += 1
        }
        if (requirement.includeIncidentEdges) {
            transaction.loadRelations(
                frontier = resources.keys,
                direction = RelationDirection.BOTH,
                filter = RelationFilter.Any,
                limit = requirement.maximumEdges - relations.size + 1,
            ).forEach { relations[it.id] = it }
            if (relations.size > requirement.maximumEdges) {
                return tooLarge("edge", requirement.maximumEdges)
            }
        }
        return MutationGraphLoadResult.Success(
            AuthoringWorkingGraph(
                resources = resources,
                relations = relations,
            ),
        )
    }

    private fun tooLarge(
        dimension: String,
        limit: Int,
    ): MutationGraphLoadResult.Invalid =
        MutationGraphLoadResult.Invalid(
            AuthoringDiagnostic(
                code = "mutation-graph-$dimension-limit-exceeded",
                message = "Authoring mutation graph $dimension limit $limit was exceeded.",
            ),
        )
}

private fun loadRelations(
    transaction: Transaction,
    frontier: Set<ResourceId>,
    requirement: GraphReadRequirement,
    limit: Int,
): List<StoredResourceRelation> {
    if (limit <= 0) return emptyList()
    val relations = linkedMapOf<String, StoredResourceRelation>()
    val remaining = {
        (limit - relations.size).coerceAtLeast(0)
    }
    if (requirement.relations.isNotEmpty()) {
        transaction
            .loadRelations(
                frontier = frontier,
                direction = requirement.direction.toRelationDirection(),
                filter = RelationFilter.Declared(requirement.relations),
                limit = remaining(),
                definitions = requirement.definitions,
            ).forEach { relations[it.id] = it }
    }
    if (requirement.outgoingReferences && relations.size < limit) {
        transaction
            .loadRelations(
                frontier = frontier,
                direction = RelationDirection.OUTGOING,
                filter = RelationFilter.OrdinaryReferences(),
                limit = remaining(),
                definitions = requirement.definitions,
            ).forEach { relations[it.id] = it }
    }
    if (requirement.incomingReferences && relations.size < limit) {
        transaction
            .loadRelations(
                frontier = frontier,
                direction = RelationDirection.INCOMING,
                filter = RelationFilter.OrdinaryReferences(),
                limit = remaining(),
                definitions = requirement.definitions,
            ).forEach { relations[it.id] = it }
    }
    return relations.values.toList()
}

private fun GraphReadRequirement.Direction.toRelationDirection(): RelationDirection =
    when (this) {
        GraphReadRequirement.Direction.OUTGOING -> RelationDirection.OUTGOING
        GraphReadRequirement.Direction.INCOMING -> RelationDirection.INCOMING
        GraphReadRequirement.Direction.BOTH -> RelationDirection.BOTH
    }

internal sealed interface MutationGraphLoadResult {
    data class Success(
        val graph: AuthoringWorkingGraph,
    ) : MutationGraphLoadResult

    data class Invalid(
        val diagnostic: AuthoringDiagnostic,
    ) : MutationGraphLoadResult
}
