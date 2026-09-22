package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.AuthoringGraphDelta
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression

/** Declares the graph portion a compilation projection is allowed to inspect. */
internal data class GraphReadRequirement(
    val definitions: Set<ResourceDefinitionId> = emptySet(),
    val relations: Set<RelationId> = emptySet(),
    val incomingReferences: Boolean = false,
    val outgoingReferences: Boolean = false,
    val direction: Direction = Direction.BOTH,
    val maximumDepth: Int = 1,
    val maximumResources: Int = 10_000,
    val maximumEdges: Int = 25_000,
) {
    init {
        require(maximumDepth >= 0) { "Graph read maximum depth cannot be negative." }
        require(maximumResources > 0) { "Graph read maximum resources must be positive." }
        require(maximumEdges > 0) { "Graph read maximum edges must be positive." }
    }

    fun plus(other: GraphReadRequirement): GraphReadRequirement =
        GraphReadRequirement(
            definitions = definitions + other.definitions,
            relations = relations + other.relations,
            incomingReferences = incomingReferences || other.incomingReferences,
            outgoingReferences = outgoingReferences || other.outgoingReferences,
            direction = direction.plus(other.direction),
            maximumDepth = maxOf(maximumDepth, other.maximumDepth),
            maximumResources = minOf(maximumResources, other.maximumResources),
            maximumEdges = minOf(maximumEdges, other.maximumEdges),
        )

    enum class Direction {
        OUTGOING,
        INCOMING,
        BOTH,
        ;

        fun plus(other: Direction): Direction =
            when {
                this == BOTH || other == BOTH -> BOTH
                this == other -> this
                else -> BOTH
            }
    }
}

/** Identifies the exact roots invalidated by one committed graph change. */
internal data class CompilationImpact(
    val roots: Map<CompilationProjectionId, Set<ResourceId>>,
) {
    val isEmpty: Boolean
        get() = roots.values.all(Set<ResourceId>::isEmpty)

    fun rootsFor(projection: CompilationProjectionId): Set<ResourceId> = roots[projection].orEmpty()

    companion object {
        val None = CompilationImpact(emptyMap())
    }
}

/** Owns root discovery, dependency impact, and pure artifact production for one compiled format. */
internal interface AuthoringCompilationProjection {
    val id: CompilationProjectionId
    val root: TypeExpression
    val graphRequirement: GraphReadRequirement

    fun roots(graph: AuthoringWorkingGraph): Set<ResourceId> = emptySet()

    fun affectedRoots(
        change: AuthoringGraphDelta,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId>

    suspend fun compile(
        root: ResourceId,
        graph: AuthoringWorkingGraph,
    ): CompilationResult
}

/** Validates the uniqueness of registrations before Realm starts serving authoring traffic. */
internal class AuthoringCompilationProjectionRegistry(
    projections: Collection<AuthoringCompilationProjection>,
) {
    val projections: List<AuthoringCompilationProjection> = projections.toList()
    private val byId = this.projections.associateBy(AuthoringCompilationProjection::id)

    init {
        require(byId.size == this.projections.size) {
            "Compilation projection ids must be unique."
        }
    }

    operator fun get(id: CompilationProjectionId): AuthoringCompilationProjection? = byId[id]

    fun impact(
        change: AuthoringGraphDelta,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): CompilationImpact =
        CompilationImpact(
            projections
                .associate { projection ->
                    projection.id to projection.affectedRoots(change, before, proposed)
                }.filterValues(Set<ResourceId>::isNotEmpty),
        )
}
