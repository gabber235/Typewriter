package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypedValueEnvelope
import kotlinx.serialization.Serializable

/** The generic subject emitted by a registered presentation policy. */
@Serializable
data class AuthoringPresentationSubject(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val content: TypedValueEnvelope,
    val descriptor: ResourceTypeDescriptor,
    val identity: ResourceIdentity = ResourceIdentity(resource),
    val ownerPath: List<ResourceId> = emptyList(),
)

/** Provides a visual descriptor and subject projection for one open resource definition. */
interface AuthoringPresentationProjection {
    val resourceDefinition: ResourceDefinitionId
    val graphRequirement: GraphReadRequirement

    fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringWorkingGraph,
    ): AuthoringPresentationSubject

    /** Returns subjects whose presentation can change when this graph mutation is applied. */
    fun affectedResources(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> =
        (
            change.changedResources +
                change.changedEdges.flatMap { edgeId ->
                    listOfNotNull(before.relations[edgeId], proposed.relations[edgeId]).flatMap { relation ->
                        listOf(relation.source, relation.target)
                    }
                }
        ).let { roots ->
            (before.dependents(roots) + proposed.dependents(roots)).filterTo(linkedSetOf()) { id ->
                before.resources[id]?.definition == resourceDefinition || proposed.resources[id]?.definition == resourceDefinition
            }
        }
}

private fun AuthoringWorkingGraph.dependents(roots: Set<ResourceId>): Set<ResourceId> {
    val affected = roots.toMutableSet()
    val pending = ArrayDeque(roots)
    while (pending.isNotEmpty()) {
        val target = pending.removeFirst()
        relations.values
            .filter { it.target == target }
            .map { it.source }
            .filter(affected::add)
            .forEach(pending::addLast)
    }
    return affected
}
