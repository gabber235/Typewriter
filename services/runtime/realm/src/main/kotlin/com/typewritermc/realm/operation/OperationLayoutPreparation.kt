@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.operation

import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayoutDefinition
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.name
import com.typewritermc.authoring.of
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.realm.authoring.RelationReads
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.ownsResources
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** Lays out moved members when their destination is laid out as a graph, without inferring layout from presentation. */
internal class OperationLayoutPreparation(
    private val relations: RelationReads,
) {
    /**
     * Gives these members a collision free graph placement around [anchor] when [destination] is a [GraphLayout].
     *
     * The members must already be owned by the destination. A member holding another placement kind, such as a
     * timeline entry placement, first receives a fresh graph placement when its placement field accepts one. Other
     * destinations, such as timeline pages, keep the members' placements untouched, and so do members whose type
     * publishes no placement field that can hold a graph placement.
     */
    context(operation: OperationPreparation)
    suspend fun List<ResourceId>.placeIn(
        destination: ResourceId,
        anchor: PlacementAnchor?,
    ) {
        if (isEmpty() || !destination.isA(GraphLayoutDefinition.id)) return
        val members = destination.ownedMembers(this)
        val moving = mapNotNull { it.graphPlacement() ?: it.freshGraphPlacement() }
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
            .forEach { path -> relations.reads.members(boundCollectionPath(ValueLocation.of(this, path))) }
        memberships.forEach { relations.reads.observeInput(InputIdentity.Value(it.id.location)) }
        return memberships.map { it.target.resource }.distinct()
    }

    /** Writes a default graph placement into this resource's placement field, when that field accepts one. */
    context(operation: OperationPreparation)
    private suspend fun ResourceId.freshGraphPlacement(): ValueLocation? {
        val catalog = relations.catalog
        val record = relations.resources[this] ?: return null
        val location = catalog.placementLocation(this, record) ?: return null
        // The authored value carries its actual placement kind, so the declared type comes from the containing record.
        val field = location.path.segments.lastOrNull() as? PathSegment.FieldWrapper ?: return null
        val container = record.authoredTypeAt(ValuePath(segments = location.path.segments.dropLast(1)), catalog.checked) ?: return null
        val schema = (catalog.checked.resolve(container) as? Resolution.Ready)?.value?.schema ?: return null
        val declared = schema.fields.singleOrNull { it.key == field.name }?.type ?: return null
        if (!catalog.checked.isReadableAs(GraphPlacementDefinition.use.use, declared)) return null
        val checked = (catalog.checked.resolve(GraphPlacementDefinition.use.use) as Resolution.Ready).value
        val value = catalog.nativeBindings.bind(checked).encodeGeneratedDefault(GraphPlacement())
        val written = operation.checkedSet(location, value)
        check(written == CheckedWriteResult.Applied) { "The graph placement of $this was rejected: $written" }
        return location
    }

    private fun ResourceId.graphPlacement(): ValueLocation? =
        relations.resources[this]?.let { record -> relations.catalog.graphPlacementLocation(this, record) }
}

private fun ValuePath.collection(): ValuePath =
    if (segments.lastOrNull() is PathSegment.ItemWrapper) ValuePath(segments = segments.dropLast(1)) else this
