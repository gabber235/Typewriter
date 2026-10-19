package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.item
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.BuiltinResourceOperation
import com.typewritermc.operations.OperationAvailability
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.repository.CounterpartBinding
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation

/** Built in policy uses checked reference contracts, rather than resource family names. */
internal class BuiltinOperationAvailability(
    private val baseline: AuthoringView,
    private val reads: CapturedAuthoringReads,
) {
    fun availability(
        kind: BuiltinResourceOperation,
        targets: List<ResourceId>,
    ): OperationAvailability =
        when (kind) {
            BuiltinResourceOperation.LinkWithDuplicate -> {
                selfLink(targets.single()).let { state ->
                    if (state ==
                        OperationAvailability.Enabled
                    ) {
                        cloneAvailability(targets)
                    } else {
                        state
                    }
                }
            }

            BuiltinResourceOperation.Duplicate -> {
                cloneAvailability(targets)
            }

            BuiltinResourceOperation.LinkWith -> {
                if (targets.all { referenceSlots(it).isNotEmpty() }) OperationAvailability.Enabled else OperationAvailability.Hidden
            }

            BuiltinResourceOperation.MoveToPage, BuiltinResourceOperation.MoveToBook -> {
                val owned =
                    baseline.projection.projections.filter { edge ->
                        baseline.catalog.relations.any {
                            it.id == edge.contract &&
                                it.families.any { family -> family.value == RESOURCE_OWNERSHIP_FAMILY_ID }
                        }
                    }
                targets.forEach { reads.observeInput(InputIdentity.Incoming(it, null)) }
                if (targets.all { target -> owned.count { it.second == target } == 1 }) {
                    OperationAvailability.Enabled
                } else {
                    OperationAvailability.Disabled("Each selected resource must have one exact owner")
                }
            }

            else -> {
                OperationAvailability.Enabled
            }
        }

    private fun cloneAvailability(roots: List<ResourceId>): OperationAvailability {
        val owning =
            baseline.catalog.relations
                .filter {
                    it.families.any { family ->
                        family.value == RESOURCE_OWNERSHIP_FAMILY_ID
                    }
                }.mapTo(hashSetOf()) { it.id }
        val closure = linkedSetOf<ResourceId>()
        val pending = ArrayDeque(roots)
        val ownership =
            baseline.projection.projections
                .filter { it.contract in owning }
                .groupBy({ it.first }, { it.second })
        while (pending.isNotEmpty()) {
            val id = pending.removeFirst()
            if (!closure.add(id)) continue
            reads.observeInput(InputIdentity.Incoming(id, null))
            ownership[id].orEmpty().forEach(pending::add)
        }
        val contracts =
            baseline.catalog.relations
                .flatMap { listOf(it.first.id to it, it.second.id to it) }
                .toMap()
        baseline.links.values.filter { it.source in closure && it.target.resource !in closure }.forEach { source ->
            val relation = contracts.getValue(source.id.endpoint)
            if (relation.id !in owning && source.id.endpoint != relation.first.id) return@forEach
            val opposite = if (source.id.endpoint == relation.first.id) relation.second.id else relation.first.id
            val record = baseline.resources[source.target.resource] ?: return@forEach
            val binding = ResourceValueMapper.counterpartBinding(opposite, source.target.resource, record, baseline.catalog.checked)
            if (binding is CounterpartBinding.Scalar) {
                reads.observeInput(InputIdentity.Value(binding.location))
                if (baseline.links.values.any { it.id.location == binding.location }) {
                    return OperationAvailability.Disabled(
                        "An outside scalar inverse cannot retain both the original and its copy: ${binding.location}",
                    )
                }
            }
        }
        return OperationAvailability.Enabled
    }

    private fun selfLink(id: ResourceId): OperationAvailability {
        val actual =
            (baseline.resources.getValue(id).configuration as? TypeSelection.Complete)?.use
                ?: return OperationAvailability.Disabled("Complete the resource type configuration first")
        val slots = referenceSlots(id).filter { (_, _, target) -> baseline.catalog.checked.isReadableAs(actual, target) }
        if (slots.isEmpty()) return OperationAvailability.Hidden
        val current = baseline.links.values.associateBy { it.id.location }
        return if (slots.any { (at, collection, _) -> collection || current[at] == null }) {
            OperationAvailability.Enabled
        } else {
            OperationAvailability.Disabled("No compatible outgoing reference has room for another link")
        }
    }

    private fun referenceSlots(id: ResourceId): List<Triple<ValueLocation, Boolean, TypeUse>> {
        val record = baseline.resources.getValue(id)
        val slots = mutableListOf<Triple<ValueLocation, Boolean, TypeUse>>()
        baseline.catalog.relations
            .filterNot {
                it.families.any { family ->
                    family.value == RESOURCE_OWNERSHIP_FAMILY_ID
                }
            }.forEach { relation ->
                listOf(relation.first.id).forEach { endpoint ->
                    val evidence = ResourceValueMapper.declaredEvidence(endpoint, id, record, baseline.catalog.checked)
                    evidence.forms.forEach { reads.observeInput(InputIdentity.Form(it)) }
                    evidence.memberships.forEach { reads.observeInput(InputIdentity.Membership(it)) }
                    val binding = ResourceValueMapper.counterpartBinding(endpoint, id, record, baseline.catalog.checked)
                    val locations = evidence.values.map { it to false }.toMutableList()
                    if (binding is CounterpartBinding.Collection) {
                        locations +=
                            binding.location.item(ItemId("availability")) to true
                    }
                    locations.forEach { (at, collection) ->
                        reads.observeInput(InputIdentity.Value(at))
                        val declared = record.authoredTypeAt(at.path, baseline.catalog.checked) ?: return@forEach
                        val resolved =
                            baseline.catalog.checked.resolve(
                                if (declared is TypeUse.Nullable) declared.value else declared,
                            ) as? Resolution.Ready
                                ?: return@forEach
                        val link = resolved.value.schema.representation as? ResolvedRepresentation.Link ?: return@forEach
                        if (link.endpoint == endpoint) slots += Triple(at, collection, link.target)
                    }
                }
            }
        return slots
    }
}
