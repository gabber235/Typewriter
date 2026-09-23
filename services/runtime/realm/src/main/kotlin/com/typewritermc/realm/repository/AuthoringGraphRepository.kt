package com.typewritermc.realm.repository

import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.types.DataPath
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypedValueEnvelope

@kotlinx.serialization.Serializable
data class AuthoringGraphResource(
    val id: ResourceId,
    val definition: ResourceDefinitionId,
    val content: TypedValueEnvelope,
)

internal sealed interface ResourceSeed {
    data class Ids(
        val values: List<ResourceId>,
        val requireAssignableTo: TypeExpression? = null,
    ) : ResourceSeed

    data class Scan(
        val filter: ResourceFilter = ResourceFilter(),
    ) : ResourceSeed
}

internal data class ResourceFilter(
    val definitions: Set<ResourceDefinitionId> = emptySet(),
    val assignableTo: TypeExpression? = null,
)

internal sealed interface RelationFilter {
    data object Any : RelationFilter

    data class OrdinaryReferences(
        val sourcePathPrefixes: List<DataPath> = emptyList(),
        val expectedTarget: TypeExpression? = null,
    ) : RelationFilter

    data class Declared(
        val relationIds: Set<com.typewritermc.types.RelationId> = emptySet(),
    ) : RelationFilter

    /** One unordered policy dependency set evaluated from every depth frontier. */
    data class PolicyDependencies(
        val declaredRelationIds: Set<com.typewritermc.types.RelationId>,
        val declaredDirection: RelationDirection,
        val incomingReferences: Boolean,
        val outgoingReferences: Boolean,
    ) : RelationFilter
}

internal enum class RelationDirection {
    OUTGOING,
    INCOMING,
    BOTH,
}

internal data class RelationStep(
    val relations: RelationFilter = RelationFilter.Any,
    val direction: RelationDirection,
    val minDepth: Int = 1,
    val maxDepth: Int = 1,
    val target: ResourceFilter? = null,
) {
    init {
        require(minDepth >= 0) { "Relation traversal minimum depth cannot be negative." }
        require(maxDepth >= minDepth) { "Relation traversal maximum depth must cover its minimum depth." }
    }
}

internal data class GraphSelection(
    val key: String,
    val seed: ResourceSeed,
    val steps: List<RelationStep> = emptyList(),
) {
    init {
        require(key.isNotBlank()) { "Graph selection keys must not be blank." }
    }
}

internal data class GraphSelectionResult(
    val key: String,
    val resourceIds: List<ResourceId>,
    val edgeIds: List<String>,
    val missingIds: List<ResourceId>,
    val incompatibleIds: List<ResourceId> = emptyList(),
)

internal data class AuthoringGraphSnapshot(
    val generation: String,
    val sequence: Long,
    val resources: List<AuthoringGraphResource>,
    val edges: List<StoredResourceRelation>,
    val selections: List<GraphSelectionResult>,
)

internal sealed interface AuthoringGraphQueryResult {
    data class Success(
        val snapshot: AuthoringGraphSnapshot,
    ) : AuthoringGraphQueryResult

    data class Invalid(
        val code: String,
        val message: String,
    ) : AuthoringGraphQueryResult

    data class CatalogChanged(
        val actualGeneration: String,
    ) : AuthoringGraphQueryResult
}

internal interface AuthoringGraphRepository {
    suspend fun query(
        generation: String,
        selections: List<GraphSelection>,
    ): AuthoringGraphQueryResult
}

internal data class AuthoringGraphLimits(
    val maxSelections: Int = 32,
    val maxRoots: Int = 10_000,
    val maxDepth: Int = 256,
    val maxResources: Int = 100_000,
    val maxEdges: Int = 250_000,
)

/** Evaluates complete named selections over one already consistent hydrated graph. */
internal class AuthoringGraphQueryEngine(
    private val catalog: TypeCatalog,
    private val limits: AuthoringGraphLimits = AuthoringGraphLimits(),
) {
    fun evaluate(
        generation: String,
        sequence: Long,
        resources: Collection<AuthoringGraphResource>,
        edges: Collection<StoredResourceRelation>,
        selections: List<GraphSelection>,
    ): AuthoringGraphQueryResult {
        if (selections.size > limits.maxSelections) return tooLarge("selection", limits.maxSelections)
        if (selections.map(GraphSelection::key).distinct().size != selections.size) {
            return AuthoringGraphQueryResult.Invalid("duplicate-selection", "Graph selection keys must be unique.")
        }
        if (selections.any { selection -> selection.steps.any { it.maxDepth > limits.maxDepth } }) {
            return tooLarge("depth", limits.maxDepth)
        }
        val byId = resources.associateBy(AuthoringGraphResource::id)
        val orderedResources = resources.sortedBy { it.id.value }
        val orderedEdges = edges.sortedBy(StoredResourceRelation::id)
        val selectedResourceIds = linkedSetOf<ResourceId>()
        val selectedEdgeIds = linkedSetOf<String>()
        val results = mutableListOf<GraphSelectionResult>()

        for (selection in selections) {
            val missing = mutableListOf<ResourceId>()
            val incompatible = mutableListOf<ResourceId>()
            var frontier =
                when (val seed = selection.seed) {
                    is ResourceSeed.Ids -> {
                        if (seed.values.size > limits.maxRoots) return tooLarge("root", limits.maxRoots)
                        seed.values.mapNotNullTo(linkedSetOf()) { id ->
                            val resource = byId[id]
                            when {
                                resource == null -> {
                                    missing += id
                                    null
                                }

                                seed.requireAssignableTo != null &&
                                    !resource.matches(ResourceFilter(assignableTo = seed.requireAssignableTo)) -> {
                                    incompatible += id
                                    null
                                }

                                else -> {
                                    id
                                }
                            }
                        }
                    }

                    is ResourceSeed.Scan -> {
                        orderedResources.filterTo(linkedSetOf()) { it.matches(seed.filter) }.mapTo(linkedSetOf()) { it.id }
                    }
                }
            val membership = linkedSetOf<ResourceId>().apply { addAll(frontier) }
            val traversedEdges = linkedSetOf<String>()
            for (step in selection.steps) {
                val stepFrontier = linkedSetOf<ResourceId>()
                var depthFrontier = frontier
                val visitedAtStep = linkedSetOf<ResourceId>().apply { addAll(frontier) }
                for (depth in 1..step.maxDepth) {
                    val next = linkedSetOf<ResourceId>()
                    for (edge in orderedEdges) {
                        if (!edge.matches(step.relations)) continue
                        val adjacent = edge.adjacent(depthFrontier, step) ?: continue
                        val target = byId[adjacent] ?: continue
                        if (step.target != null && !target.matches(step.target)) continue
                        traversedEdges += edge.id
                        if (visitedAtStep.add(adjacent)) next += adjacent
                    }
                    if (depth >= step.minDepth) stepFrontier += next
                    depthFrontier = next
                    if (depthFrontier.isEmpty()) break
                }
                if (
                    step.relations is RelationFilter.PolicyDependencies &&
                    depthFrontier.isNotEmpty() &&
                    orderedEdges.any { edge ->
                        edge.matches(step.relations) &&
                            edge.adjacent(depthFrontier, step)?.let { adjacent ->
                                if (adjacent in visitedAtStep) return@let false
                                val target = byId[adjacent] ?: return@let false
                                step.target == null || target.matches(step.target)
                            } == true
                    }
                ) {
                    return tooLarge("depth", step.maxDepth)
                }
                frontier = stepFrontier
                membership += stepFrontier
                if (membership.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
                if (traversedEdges.size > limits.maxEdges) return tooLarge("edge", limits.maxEdges)
            }
            selectedResourceIds += membership
            selectedEdgeIds += traversedEdges
            results +=
                GraphSelectionResult(
                    key = selection.key,
                    resourceIds = membership.toList(),
                    edgeIds = traversedEdges.toList(),
                    missingIds = missing,
                    incompatibleIds = incompatible,
                )
        }
        if (selectedResourceIds.size > limits.maxResources) return tooLarge("resource", limits.maxResources)
        if (selectedEdgeIds.size > limits.maxEdges) return tooLarge("edge", limits.maxEdges)
        return AuthoringGraphQueryResult.Success(
            AuthoringGraphSnapshot(
                generation = generation,
                sequence = sequence,
                resources = orderedResources.filter { it.id in selectedResourceIds },
                edges = orderedEdges.filter { it.id in selectedEdgeIds },
                selections = results,
            ),
        )
    }

    private fun AuthoringGraphResource.matches(filter: ResourceFilter): Boolean {
        if (filter.definitions.isNotEmpty() && definition !in filter.definitions) return false
        val target = filter.assignableTo ?: return true
        return catalog.isAssignable(content.rootType, target)
    }

    private fun StoredResourceRelation.matches(filter: RelationFilter): Boolean =
        when (filter) {
            RelationFilter.Any -> {
                true
            }

            is RelationFilter.Declared -> {
                val id = (origin as? ResourceRelationOrigin.Declared)?.relationId ?: return false
                filter.relationIds.isEmpty() || id in filter.relationIds
            }

            is RelationFilter.OrdinaryReferences -> {
                val reference = origin as? ResourceRelationOrigin.Reference ?: return false
                val pathMatches =
                    filter.sourcePathPrefixes.isEmpty() ||
                        filter.sourcePathPrefixes.any { prefix -> reference.sourcePath.startsWith(prefix) }
                pathMatches &&
                    (filter.expectedTarget == null || catalog.isAssignable(reference.expectedTarget, filter.expectedTarget))
            }

            is RelationFilter.PolicyDependencies -> {
                when (origin) {
                    is ResourceRelationOrigin.Declared -> origin.relationId in filter.declaredRelationIds
                    is ResourceRelationOrigin.Reference -> filter.incomingReferences || filter.outgoingReferences
                }
            }
        }
}

private fun StoredResourceRelation.adjacent(
    frontier: Set<ResourceId>,
    step: RelationStep,
): ResourceId? =
    when (val filter = step.relations) {
        is RelationFilter.PolicyDependencies -> {
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
        }

        else -> {
            adjacent(frontier, step.direction)
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

internal fun TypeCatalog.isAssignable(
    candidate: TypeExpression,
    target: TypeExpression,
): Boolean = isAssignableExactly(candidate, target)

private fun tooLarge(
    dimension: String,
    limit: Int,
): AuthoringGraphQueryResult.Invalid =
    AuthoringGraphQueryResult.Invalid(
        code = "query-too-large",
        message = "Authoring graph $dimension limit $limit was exceeded.",
    )
