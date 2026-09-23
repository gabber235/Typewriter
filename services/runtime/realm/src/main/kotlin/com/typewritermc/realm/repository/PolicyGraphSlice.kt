package com.typewritermc.realm.repository

import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.types.ResourceId

internal sealed interface PolicyGraphSliceResult {
    data class Success(
        val graph: AuthoringWorkingGraph,
    ) : PolicyGraphSliceResult

    data class LimitExceeded(
        val dimension: String,
        val limit: Int,
    ) : PolicyGraphSliceResult
}

/** Restricts a loaded graph to exactly the dependencies declared by one policy. */
internal fun AuthoringWorkingGraph.sliceForPolicy(
    roots: Set<ResourceId>,
    requirement: GraphReadRequirement,
): PolicyGraphSliceResult {
    if (roots.size > requirement.maximumResources) {
        return PolicyGraphSliceResult.LimitExceeded("resource", requirement.maximumResources)
    }
    val selectedResources = linkedMapOf<ResourceId, StoredTypedResource>()
    roots.mapNotNull(resources::get).forEach { selectedResources[it.id] = it }
    val selectedRelations = linkedMapOf<String, StoredResourceRelation>()
    var frontier = selectedResources.keys.toSet()
    val visited = frontier.toMutableSet()
    var depth = 0
    while (frontier.isNotEmpty() && depth < requirement.maximumDepth) {
        val next = linkedSetOf<ResourceId>()
        relations.values.forEach { relation ->
            val adjacent = relation.policyAdjacent(frontier, requirement) ?: return@forEach
            val resource = resources[adjacent] ?: return@forEach
            if (requirement.definitions.isNotEmpty() && resource.definition !in requirement.definitions) {
                return@forEach
            }
            selectedRelations[relation.id] = relation
            selectedResources[resource.id] = resource
            if (visited.add(resource.id)) next += resource.id
        }
        if (selectedResources.size > requirement.maximumResources) {
            return PolicyGraphSliceResult.LimitExceeded("resource", requirement.maximumResources)
        }
        if (selectedRelations.size > requirement.maximumEdges) {
            return PolicyGraphSliceResult.LimitExceeded("edge", requirement.maximumEdges)
        }
        frontier = next
        depth++
    }
    if (
        frontier.isNotEmpty() &&
        relations.values.any { relation ->
            relation.policyAdjacent(frontier, requirement)?.let { it !in visited } == true
        }
    ) {
        return PolicyGraphSliceResult.LimitExceeded("depth", requirement.maximumDepth)
    }
    if (requirement.includeIncidentEdges) {
        val selected = selectedResources.keys
        relations.values.forEach { relation ->
            if (relation.source in selected || relation.target in selected) {
                selectedRelations[relation.id] = relation
            }
        }
        if (selectedRelations.size > requirement.maximumEdges) {
            return PolicyGraphSliceResult.LimitExceeded("edge", requirement.maximumEdges)
        }
    }
    return PolicyGraphSliceResult.Success(AuthoringWorkingGraph(selectedResources, selectedRelations))
}

private fun StoredResourceRelation.policyAdjacent(
    frontier: Set<ResourceId>,
    requirement: GraphReadRequirement,
): ResourceId? =
    when (val relationOrigin = origin) {
        is ResourceRelationOrigin.Declared -> {
            if (relationOrigin.relationId !in requirement.relations) return null
            when (requirement.direction) {
                GraphReadRequirement.Direction.OUTGOING -> {
                    target.takeIf { source in frontier }
                }

                GraphReadRequirement.Direction.INCOMING -> {
                    source.takeIf { target in frontier }
                }

                GraphReadRequirement.Direction.BOTH -> {
                    when {
                        source in frontier -> target
                        target in frontier -> source
                        else -> null
                    }
                }
            }
        }

        is ResourceRelationOrigin.Reference -> {
            when {
                requirement.outgoingReferences && source in frontier -> target
                requirement.incomingReferences && target in frontier -> source
                else -> null
            }
        }
    }
