@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayout
import com.typewritermc.authoring.GraphLayoutDefinition
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.operations.PlacementAnchor
import com.typewritermc.operations.PlacementPreparation
import com.typewritermc.operations.ResourceLayoutPreparation
import com.typewritermc.operations.UnavailableAuthoredValue
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.ownsResources

/** Lays out moved members when their destination declares a layout, without inferring layout from presentation. */
internal class OperationLayoutPreparation(
    private val edit: WorkingViewEditContext,
    private val baseline: AuthoringView,
) : ResourceLayoutPreparation {
    /**
     * Gives moved members a collision free graph placement when [destination] is a [GraphLayout].
     *
     * Members must already be owned by the destination. Other destinations, such as timeline pages, keep the
     * members' placements untouched.
     */
    context(operation: OperationPreparation)
    override suspend fun prepareMove(
        subjects: List<ResourceDraft>,
        destination: ResourceId,
        anchor: PlacementAnchor?,
    ): PlacementPreparation {
        edit.capturedReads.observeInput(InputIdentity.Form(ValueLocation(destination, ValuePath())))
        val record = requireNotNull(edit.session.resources[destination]) { "The destination no longer exists." }
        val type =
            (record.configuration as? TypeSelection.Complete)?.use
                ?: error("Configure the destination type before moving resources.")
        if (!baseline.catalog.checked.isNominalSubtype(type.definition, GraphLayoutDefinition.id)) return PlacementPreparation { }
        val members = destination.ownedMembers(subjects.map { it.id })
        val moving = subjects.mapNotNull { it.id.graphPlacement() }
        val occupants = members.filterNot { member -> subjects.any { it.id == member } }.mapNotNull { it.graphPlacement() }
        val placed = with(edit.capturedReads) { GraphGroupPlacement.place(moving, occupants, anchor) }
        return PlacementPreparation {
            placed.forEach { (draft, placement) ->
                draft.setX(placement.x)
                draft.setY(placement.y)
            }
        }
    }

    /** Resources this destination owns, after checking every subject holds one exact membership in it. */
    private fun ResourceId.ownedMembers(subjects: List<ResourceId>): List<ResourceId> {
        val owningEndpoints =
            baseline.catalog.relations
                .filter { it.ownsResources }
                .mapTo(hashSetOf()) { it.first.id }
        val memberships =
            ResourceValueMapper.discover(edit.session.resources).filter {
                it.source == this && it.id.endpoint in owningEndpoints
            }
        subjects.forEach { subject ->
            edit.capturedReads.observeInput(InputIdentity.Incoming(subject, null))
            requireNotNull(memberships.singleOrNull { it.target.resource == subject }) {
                "Place resources in one exact destination ownership occurrence before preparing layout."
            }
        }
        memberships
            .map {
                it.id.location.path
                    .collection()
            }.distinct()
            .forEach { path -> edit.capturedReads.members(boundCollectionPath(ValueLocation(this, path))) }
        memberships.forEach { edit.capturedReads.observeInput(InputIdentity.Value(it.id.location)) }
        return memberships.map { it.target.resource }.distinct()
    }

    private fun ResourceId.graphPlacement(): ValueLocation? =
        edit.session.resources[this]?.let { record -> baseline.catalog.graphPlacementLocation(this, record) }

    internal fun draft(id: ResourceId): ResourceDraft {
        val binding =
            when (val read = edit.capturedReads.resourceBinding(id)) {
                is Availability.Available -> read.value
                is Availability.Unavailable -> throw UnavailableAuthoredValue(read.locations)
                is Availability.Failed -> error(read.diagnostic.toString())
            }
        return object : ResourceDraft {
            override val id = id
            override val catalog = binding.catalog
            override val readContext = binding.readContext
            override val location = binding.location
            override val actualType: Availability<TypeUse.Named> =
                when (val configuration = binding.actual) {
                    is TypeSelection.Complete -> Availability.Available(configuration.use)
                    is TypeSelection.Pending -> Availability.Unavailable(listOf(binding.location))
                }
        }
    }
}

private fun ValuePath.collection(): ValuePath = if (segments.lastOrNull() is PathSegment.Item) ValuePath(segments.dropLast(1)) else this
