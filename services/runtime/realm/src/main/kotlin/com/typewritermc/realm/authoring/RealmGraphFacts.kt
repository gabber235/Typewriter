package com.typewritermc.realm.authoring

import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.item
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.AuthoringGraphFacts
import com.typewritermc.operations.Cloneability
import com.typewritermc.operations.LinkCapacity
import com.typewritermc.realm.repository.CounterpartBinding
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.ownsResources
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse

/**
 * Graph facts of one captured working graph, read through [relations] so every fact is recorded as an observation.
 * Ownership, link and clone answers use checked relation contracts, never resource type names.
 */
internal class RealmGraphFacts(
    private val relations: RelationReads,
) : AuthoringGraphFacts {
    private val catalog get() = relations.catalog

    private var memoized: Memo? = null

    /** Answers derived from the whole graph, kept until a staged write changes it. */
    private val memo: Memo
        get() = memoized?.takeIf { it.revision == relations.revision } ?: Memo(relations.revision).also { memoized = it }

    private inner class Memo(
        val revision: Long,
    ) {
        val ownerCandidates = hashMapOf<ResourceId, List<ResourceId>>()
        val owned: Map<ResourceId, List<ResourceId>> by lazy(LazyThreadSafetyMode.NONE) {
            val owning = catalog.ownershipRelationIds
            relations.projections
                .filter { it.contract in owning }
                .groupBy({ it.first }, { it.second })
        }
    }

    override fun ownerOf(id: ResourceId): ResourceId? {
        relations.reads.observeInput(InputIdentity.Incoming(id, null))
        val ownership = catalog.ownershipRelationIds
        return relations.projections
            .filter { it.contract in ownership && it.second == id }
            .map { it.first }
            .distinct()
            .singleOrNull()
    }

    override fun ownerCandidatesOf(id: ResourceId): Sequence<ResourceId> =
        memo.ownerCandidates
            .getOrPut(id) {
                val membership = relations.ownership(id) ?: return@getOrPut emptyList()
                val closure = ownershipClosure(listOf(id))
                relations.reads.observeInput(RESOURCE_SELECTION_INPUT)
                relations.resources.keys
                    .sortedBy { it.value }
                    .filter { candidate -> candidate !in closure }
                    .filter { candidate ->
                        relations.observeForm(candidate)
                        relations.ownerSources(id, membership, candidate, ::candidateItem).isNotEmpty()
                    }
            }.asSequence()

    override fun canBeOwned(id: ResourceId): Boolean {
        val type = typeOf(id) ?: return false
        return catalog.relations.any { it.ownsResources && catalog.checked.isNominalSubtype(type, it.second.resource.definition) }
    }

    override fun isSingleton(id: ResourceId): Boolean {
        val type = typeOf(id) ?: return false
        return type == catalog.realmRoot || catalog.checked.isNominalSubtype(type, RealmSectionDefinition.id)
    }

    override fun linkTargetsOf(ids: List<ResourceId>): Sequence<ResourceId> {
        relations.reads.observeInput(RESOURCE_SELECTION_INPUT)
        return relations.resources.keys
            .sortedBy { it.value }
            .asSequence()
            .filter { candidate -> candidate !in ids }
            .filter { candidate -> ids.all { id -> relations.linkSources(id, candidate, ::candidateItem).isNotEmpty() } }
    }

    override fun linksOf(id: ResourceId): Sequence<ResourceId> =
        relations
            .linksOf(id)
            .map { if (it.source == id) it.target.resource else it.source }
            .distinct()
            .asSequence()

    override fun isLinked(
        id: ResourceId,
        target: ResourceId,
    ): Boolean = relations.linksBetween(id, target).isNotEmpty()

    override fun linkCapacityOf(id: ResourceId): LinkCapacity {
        relations.observeForm(id)
        val actual = (relations.recordOf(id).configuration as? TypeSelection.Complete)?.use ?: return LinkCapacity.None
        val slots = referenceSlots(id).filter { slot -> catalog.checked.isReadableAs(actual.use, slot.target) }
        if (slots.isEmpty()) return LinkCapacity.None
        val current = relations.links.values.associateBy { it.id.location }
        return if (slots.any { it.collection || current[it.at] == null }) LinkCapacity.Available else LinkCapacity.Full
    }

    override fun cloneabilityOf(roots: List<ResourceId>): Cloneability {
        val owning = catalog.ownershipRelationIds
        val closure = ownershipClosure(roots)
        val contracts = catalog.relations.flatMap { listOf(it.first.id to it, it.second.id to it) }.toMap()
        relations.links.values.filter { it.source in closure && it.target.resource !in closure }.forEach { source ->
            val relation = contracts.getValue(source.id.endpoint)
            if (relation.id !in owning && source.id.endpoint != relation.first.id) return@forEach
            val opposite = if (source.id.endpoint == relation.first.id) relation.second.id else relation.first.id
            val record = relations.resources[source.target.resource] ?: return@forEach
            val binding = ResourceValueMapper.counterpartBinding(opposite, source.target.resource, record, catalog.checked)
            if (binding is CounterpartBinding.Scalar) {
                relations.reads.observeInput(InputIdentity.Value(binding.location))
                if (relations.links.values.any { it.id.location == binding.location }) {
                    return Cloneability.Blocked(
                        "An outside scalar inverse cannot retain both the original and its copy: ${binding.location}",
                    )
                }
            }
        }
        return Cloneability.Allowed
    }

    /** [roots] and everything they own, transitively. */
    private fun ownershipClosure(roots: List<ResourceId>): Set<ResourceId> {
        val owned = memo.owned
        val closure = linkedSetOf<ResourceId>()
        val pending = ArrayDeque(roots)
        while (pending.isNotEmpty()) {
            val id = pending.removeFirst()
            if (!closure.add(id)) continue
            relations.reads.observeInput(InputIdentity.Incoming(id, null))
            owned[id].orEmpty().forEach(pending::add)
        }
        return closure
    }

    private fun typeOf(id: ResourceId) =
        relations.resources[id]?.let { record ->
            relations.observeForm(id)
            record.configuration.definition
        }

    /** The non owning reference slots of [id] at their first endpoints, including room for one more collection item. */
    private fun referenceSlots(id: ResourceId): List<ReferenceSlot> {
        val record = relations.recordOf(id)
        val slots = mutableListOf<ReferenceSlot>()
        catalog.relations
            .filterNot { it.ownsResources }
            .forEach { relation ->
                val endpoint = relation.first.id
                val evidence = with(relations) { id.bindingEvidence(endpoint) }
                val binding = ResourceValueMapper.counterpartBinding(endpoint, id, record, catalog.checked)
                val locations = evidence.values.map { it to false }.toMutableList()
                if (binding is CounterpartBinding.Collection) locations += binding.location.item(candidateItem("capacity")) to true
                locations.forEach { (at, collection) ->
                    relations.reads.observeInput(InputIdentity.Value(at))
                    val declared = record.authoredTypeAt(at.path, catalog.checked) ?: return@forEach
                    val resolved =
                        catalog.checked.resolve(
                            if (declared is TypeUse.NullableWrapper) declared.value.value else declared,
                        ) as? Resolution.Ready
                            ?: return@forEach
                    val link = resolved.value.schema.representation as? ResolvedRepresentation.LinkWrapper ?: return@forEach
                    if (link.value.endpoint == endpoint) slots += ReferenceSlot(at, collection, link.value.target)
                }
            }
        return slots
    }

    private data class ReferenceSlot(
        val at: ValueLocation,
        val collection: Boolean,
        val target: TypeUse,
    )
}

/** A collection item that stands for a link a fact only considers, never one that is written. */
private fun candidateItem(key: String): ItemId = ItemId(value = "candidate:$key")
