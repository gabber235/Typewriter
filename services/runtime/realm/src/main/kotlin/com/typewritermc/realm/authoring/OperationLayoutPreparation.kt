package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.checking.InputIdentity
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.operations.DestinationPlacementRequest
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.operations.PlacementAnchor
import com.typewritermc.operations.PlacementPreparation
import com.typewritermc.operations.ResourceLayoutPreparation
import com.typewritermc.operations.UnavailableAuthoredValue
import com.typewritermc.operations.asClosedUse
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.ownsResources

/** Selects declared destination policy without inferring domain layout from presentation. */
internal class OperationLayoutPreparation(
    private val edit: WorkingViewEditContext,
    private val baseline: AuthoringView,
) : ResourceLayoutPreparation {
    context(operation: OperationPreparation)
    override suspend fun prepareMove(
        subjects: List<ResourceDraft>,
        destination: ResourceId,
        anchor: PlacementAnchor?,
    ): PlacementPreparation {
        val root = ValueLocation(destination, ValuePath())
        edit.capturedReads.observeInput(InputIdentity.Form(root))
        val record = requireNotNull(edit.session.resources[destination]) { "The destination no longer exists." }
        val type =
            (record.configuration as? TypeSelection.Complete)?.use
                ?: error("Configure the destination type before moving resources.")
        val requiresPlacement = baseline.catalog.checked.isNominalSubtype(type.definition, PAGE_CONTRACT_TYPE)
        val destinationPolicies =
            baseline.catalog.operations.placements.filter {
                baseline.catalog.checked.isReadableAs(type, it.target.asClosedUse())
            }
        if (destinationPolicies.isEmpty()) {
            require(!requiresPlacement) { "The destination does not declare placement for these resources." }
            return PlacementPreparation { }
        }
        val owningEndpoints =
            baseline.catalog.relations
                .filter { it.ownsResources }
                .mapTo(hashSetOf()) { it.first.id }
        val memberships =
            ResourceValueMapper.discover(edit.session.resources).filter {
                it.source == destination && it.id.endpoint in owningEndpoints
            }
        val byCollection =
            subjects.groupBy { subject ->
                edit.capturedReads.observeInput(InputIdentity.Incoming(subject.id, null))
                val membership =
                    requireNotNull(memberships.singleOrNull { it.target.resource == subject.id }) {
                        "Place resources in one exact destination ownership occurrence before preparing layout."
                    }
                edit.capturedReads.observeInput(InputIdentity.Value(membership.id.location))
                val path = membership.id.location.path
                if (path.segments.lastOrNull() is PathSegment.Item) ValuePath(path.segments.dropLast(1)) else path
            }
        val preparations =
            byCollection.map { (path, selected) ->
                val policies =
                    destinationPolicies.filter { it.collection.path == path }
                val mostSpecific =
                    policies.filter { candidate ->
                        policies.none { other ->
                            candidate.target != other.target &&
                                baseline.catalog.checked.isNominalSubtype(other.target.definition, candidate.target.definition)
                        }
                    }
                if (mostSpecific.isEmpty()) {
                    require(!requiresPlacement) {
                        "The destination does not declare placement for these resources."
                    }
                    return@map PlacementPreparation { }
                }
                require(mostSpecific.size == 1) { "The destination has ambiguous placement policies for this ownership collection." }
                val declaration = mostSpecific.single()
                val collection = ValueLocation(destination, path)
                edit.capturedReads.members(boundCollectionPath(collection))
                val members =
                    memberships.filter {
                        it.id.location.path.segments
                            .dropLast(1) == path.segments &&
                            it.id.location.path.segments
                                .lastOrNull() is PathSegment.Item
                    }
                members.forEach { edit.capturedReads.observeInput(InputIdentity.Value(it.id.location)) }
                val occupants = members.map { it.target.resource }.distinct().map(::draft)
                with(edit.capturedReads) {
                    declaration.policy.prepare(DestinationPlacementRequest(destination, collection, selected, anchor, occupants))
                }
            }
        return PlacementPreparation { preparations.forEach { it.apply() } }
    }

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
