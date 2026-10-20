@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayout
import com.typewritermc.authoring.GraphLayoutDefinition
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.ownsResources

/** Lays out moved members when their destination is laid out as a graph, without inferring layout from presentation. */
internal class OperationLayoutPreparation(
    private val relations: RelationReads,
) {
    /**
     * Gives these members a collision free graph placement around [anchor] when [destination] is a [GraphLayout].
     *
     * The members must already be owned by the destination. Other destinations, such as timeline pages, keep the
     * members' placements untouched, and so do members whose type publishes no graph placement field.
     */
    context(operation: OperationPreparation)
    suspend fun List<ResourceId>.placeIn(
        destination: ResourceId,
        anchor: PlacementAnchor?,
    ) {
        if (isEmpty() || !destination.isA(GraphLayoutDefinition.id)) return
        val members = destination.ownedMembers(this)
        val moving = mapNotNull { it.graphPlacement() }
        val occupants = members.filterNot { it in this }.mapNotNull { it.graphPlacement() }
        val placed = with(relations.reads) { GraphGroupPlacement.place(moving, occupants, anchor) }
        placed.forEach { (draft, placement) ->
            draft.setX(placement.x)
            draft.setY(placement.y)
        }
    }

    private fun ResourceId.isA(type: TypeDefinitionId): Boolean {
        relations.observeForm(this)
        val record = requireNotNull(relations.resources[this]) { "The destination no longer exists." }
        return relations.catalog.checked.isNominalSubtype(record.configuration.definition, type)
    }

    /** Resources this destination owns, after checking every subject holds one exact membership in it. */
    private fun ResourceId.ownedMembers(subjects: List<ResourceId>): List<ResourceId> {
        val owningEndpoints =
            relations.catalog.relations
                .filter { it.ownsResources }
                .mapTo(hashSetOf()) { it.first.id }
        val memberships = relations.links.values.filter { it.source == this && it.id.endpoint in owningEndpoints }
        subjects.forEach { subject ->
            relations.reads.observeInput(InputIdentity.Incoming(subject, null))
            requireNotNull(memberships.singleOrNull { it.target.resource == subject }) {
                "Place resources in one exact destination ownership occurrence before preparing layout."
            }
        }
        memberships
            .map {
                it.id.location.path
                    .collection()
            }.distinct()
            .forEach { path -> relations.reads.members(boundCollectionPath(ValueLocation(this, path))) }
        memberships.forEach { relations.reads.observeInput(InputIdentity.Value(it.id.location)) }
        return memberships.map { it.target.resource }.distinct()
    }

    private fun ResourceId.graphPlacement(): ValueLocation? =
        relations.resources[this]?.let { record -> relations.catalog.graphPlacementLocation(this, record) }
}

private fun ValuePath.collection(): ValuePath = if (segments.lastOrNull() is PathSegment.Item) ValuePath(segments.dropLast(1)) else this
