package com.typewritermc.authoring

import com.typewritermc.types.DataPath
import com.typewritermc.types.RelationId
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypedValueEnvelope

/** Declares the graph portion a Realm policy is allowed to inspect. */
data class GraphReadRequirement(
    val definitions: Set<ResourceDefinitionId> = emptySet(),
    val incomingReferences: Boolean = false,
    val outgoingReferences: Boolean = false,
    val declaredRelations: Set<RelationId> = emptySet(),
    val relationFamilies: Set<RelationFamilyId> = emptySet(),
    val includeIncidentEdges: Boolean = false,
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

    enum class Direction {
        OUTGOING,
        INCOMING,
        BOTH,
    }
}

/** One typed resource visible to an authoring policy. */
data class AuthoringGraphResource(
    val id: ResourceId,
    val definition: ResourceDefinitionId,
    val content: TypedValueEnvelope,
)

/** One normalized edge visible to an authoring policy. */
data class AuthoringGraphRelation(
    val id: String,
    val source: ResourceId,
    val target: ResourceId,
    val origin: AuthoringRelationOrigin,
)

/** The source of a normalized authoring edge. */
sealed interface AuthoringRelationOrigin {
    data class Reference(
        val slot: String,
        val sourcePath: DataPath,
        val expectedTarget: TypeExpression,
    ) : AuthoringRelationOrigin

    data class Declared(
        val relationId: RelationId,
        val sourceIndex: Int? = null,
        val targetIndex: Int? = null,
    ) : AuthoringRelationOrigin
}

/** A bounded, internally consistent graph supplied to one policy invocation. */
data class AuthoringWorkingGraph(
    val resources: Map<ResourceId, AuthoringGraphResource>,
    val relations: Map<String, AuthoringGraphRelation>,
) {
    init {
        require(resources.keys.all { it.value.isNotBlank() }) { "Graph resource ids must not be blank." }
        require(relations.keys == relations.values.mapTo(linkedSetOf()) { it.id }) {
            "Graph relation map keys must match relation ids."
        }
    }
}

/** Describes the part of a mutation that policy rules must validate. */
data class AuthoringChangeSummary(
    val changedResources: Set<ResourceId>,
    val changedEdges: Set<String>,
    val deletedResources: Set<ResourceId>,
)
