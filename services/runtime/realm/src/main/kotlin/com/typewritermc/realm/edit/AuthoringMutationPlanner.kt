package com.typewritermc.realm.edit

import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.LinkSlice
import com.typewritermc.realm.authoring.ProjectionResult
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.after
import com.typewritermc.realm.authoring.boundTypesOver
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.formula.withRealmReferences
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.contentTypesOf
import com.typewritermc.types.catalog.misfiledDeclarations
import com.typewritermc.types.catalog.withoutUnreachableTypes
import com.typewritermc.types.endpoint
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

internal sealed interface MutationPlanningResult {
    data class Accepted(
        val plan: AuthoringMutationPlan,
    ) : MutationPlanningResult

    data class Rejected(
        val problems: List<ValueProblem>,
    ) : MutationPlanningResult
}

/**
 * Replays authored intents and derives the persistent delta for the saved admission owner.
 *
 * Relation values remain canonical: writes synchronize inverse occurrences before projecting declared edges.
 * Consecutive deletions form one deletion request so cascade, restrict, and clear policies see the complete
 * selection. Final validation checks the affected resources' structure, relation bindings, single ownership and
 * endpoint cardinality, the realm structure rules (every resource but the realm root has an owner, and the root and
 * each section exist exactly once), and that no acyclic relation forms a cycle (`relation_cycle`).
 * Expectation comparison and persistence belong to [RealmAuthoringOwner], outside this pure planner.
 */
internal class AuthoringMutationPlanner(
    private val saved: AuthoringView,
) {
    /** The saved state's catalog: the code catalog plus what the saved resources declare. */
    private val catalog: CheckedCatalog get() = saved.catalog.checked
    private val contracts: List<RelationContract> get() = saved.catalog.relations

    /**
     * Plans [edit], then [repairs]: realm owned writes that follow it, judged by the same rule, refusing only what the
     * commit made worse. What a client sent for formula references is normalized away between the two.
     */
    fun plan(
        edit: PreparedEdit,
        repairs: List<EditIntent> = emptyList(),
    ): MutationPlanningResult {
        val latestResources = saved.resources
        val resources = latestResources.toMutableMap()
        val removed = linkedSetOf<ResourceId>()
        val problems = replayStaged(resources, removed, edit).toMutableList()
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)
        normalize(resources, latestResources)
        if (repairs.isNotEmpty()) {
            problems += replayStaged(resources, removed, edit.copy(expectations = emptyList(), intents = repairs))
            if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)
        }

        // A misfiled declaration is refused even when unused, so it is judged before unused ones are dropped.
        problems +=
            resources.filter { (id, record) -> latestResources[id] != record }.flatMap { (id, record) -> record.misfiledDeclarations(id) }
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)
        dropUnreachableTypes(resources, latestResources)
        val affected =
            buildSet {
                addAll(removed)
                resources.forEach { (id, record) -> if (latestResources[id] != record) add(id) }
            }
        val final = resources.toMap().let { state -> catalog.withContent(contentTypesOf(state::get, saved.boundTypesOver(state))) }
        val links = TouchedLinks(saved, resources, affected, contracts, final)
        val validator = AuthoringSnapshotValidator(final, catalog, contracts, saved::boundTypesOver)
        problems += validator.validate(latestResources, resources, affected, links) { saved.judged(it).fit }
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)

        val beforeSet = links.savedTouching()
        val afterSet = links.touching.projections.toSet()
        val relations =
            RelationProjectionDelta(
                removals = (beforeSet - afterSet).sortedBy(::projectionKey),
                created = (afterSet - beforeSet).sortedBy(::projectionKey),
            )
        return MutationPlanningResult.Accepted(
            AuthoringMutationPlan(
                resources = resources.filter { (id, value) -> latestResources[id] != value },
                removedResources = removed,
                relations = relations,
            ),
        )
    }

    /**
     * What the realm owns in a record: formula references. [plan] applies it after replay, and the planning session
     * compares against it. A saved record is already normalized, and replay rewrites any record whose reference
     * target it removed, so an untouched record is skipped.
     */
    fun normalize(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        saved: Map<ResourceId, AuthoringRecord>,
    ) {
        val removed = saved.keys - resources.keys
        resources.replaceAll { id, record ->
            if (record === saved[id]) record else record.withRealmReferences(saved[id], removed, resources::containsKey)
        }
    }

    /** Applies ordered mutations to a request owned graph without rebuilding global projections. */
    fun replayStaged(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        removed: MutableSet<ResourceId>,
        edit: PreparedEdit,
    ): List<ValueProblem> {
        val problems = mutableListOf<ValueProblem>()
        var deletionRunEnd = 0
        val batchIdentity by lazy(LazyThreadSafetyMode.NONE) { canonicalPreparedIntentDigest(edit) }

        edit.intents.forEachIndexed { index, intent ->
            if (problems.isNotEmpty()) return@forEachIndexed
            if (index < deletionRunEnd) return@forEachIndexed
            // An overlay caches what it reaches, and any intent can change what a content type means, so each intent reads a fresh one.
            val catalog = this.catalog.withContent(contentTypesOf(resources::get, saved.boundTypesOver(resources)))
            val relations = RelationValueSynchronizer(catalog, contracts)
            when (intent) {
                is EditIntent.CreateResourceWrapper -> {
                    create(resources, removed, intent, problems)
                }

                is EditIntent.DeleteResourceWrapper -> {
                    val requested = linkedSetOf<ResourceId>()
                    deletionRunEnd = index
                    while (deletionRunEnd < edit.intents.size) {
                        val deleting = edit.intents[deletionRunEnd] as? EditIntent.DeleteResourceWrapper ?: break
                        requested += deleting.value.id
                        deletionRunEnd++
                    }
                    delete(resources, removed, requested, catalog, relations, problems)
                }

                is EditIntent.SetValueWrapper -> {
                    val before = resourceLinks(resources, intent.value.at)
                    update(resources, intent.value.at, intent.value.value, problems)
                    relations.synchronizeValueMutation(before, resources, intent.value.at, batchIdentity, index, problems)
                }

                // An insert or a remove changes its item alone, so only the item's links are synchronized.
                is EditIntent.InsertWrapper -> {
                    val item = intent.value.at.item(intent.value.item.id)
                    val before = resourceLinks(resources, item)
                    insert(resources, intent, catalog, problems)
                    relations.synchronizeValueMutation(before, resources, item, batchIdentity, index, problems)
                }

                is EditIntent.RemoveWrapper -> {
                    val item = intent.value.at.item(intent.value.item)
                    val before = resourceLinks(resources, item)
                    remove(resources, intent, problems)
                    relations.synchronizeValueMutation(before, resources, item, batchIdentity, index, problems)
                }

                is EditIntent.MoveWrapper -> {
                    move(resources, intent, problems)
                }

                is EditIntent.ConnectRelationWrapper -> {
                    relations.connect(resources, intent, batchIdentity, index, problems)
                }

                is EditIntent.DisconnectRelationWrapper -> {
                    relations.disconnect(resources, intent.value, problems)
                }

                is EditIntent.RetagWrapper -> {
                    retag(resources, intent, problems)
                }

                is EditIntent.ConfigureResourceWrapper -> {
                    configureResource(resources, intent, problems)
                }

                is EditIntent.SetTypesWrapper -> {
                    setTypes(resources, intent, problems)
                }

                else -> {
                    unknownVariant(intent)
                }
            }
        }
        return problems
    }

    private fun create(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        removed: MutableSet<ResourceId>,
        intent: EditIntent.CreateResourceWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        if (intent.value.id in resources) {
            problems += problem(intent.value.id, "resource_already_exists")
            return
        }
        resources[intent.value.id] = intent.value.record
        removed -= intent.value.id
    }

    private fun delete(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        removed: MutableSet<ResourceId>,
        requested: Set<ResourceId>,
        catalog: CheckedCatalog,
        relations: RelationValueSynchronizer,
        problems: MutableList<ValueProblem>,
    ) {
        val missing = requested.filter { it !in resources && it !in removed }
        if (missing.isNotEmpty()) {
            problems += missing.map { problem(it, "resource_missing") }
            return
        }
        val projection =
            ResourceValueMapper.project(
                ResourceValueMapper.discover(resources),
                resources,
                contracts,
                catalog,
            )
        if (projection.problems.isNotEmpty()) {
            problems += projection.problems
            return
        }
        val byRelation = contracts.associateBy(RelationContract::id)
        val deleting = linkedSetOf<ResourceId>()
        val pending = ArrayDeque<ResourceId>().also { it.addAll(requested.filter(resources::containsKey)) }
        while (pending.isNotEmpty()) {
            val current = pending.removeFirst()
            if (!deleting.add(current)) continue
            projection.projections
                .filter { it.first == current || it.second == current }
                .forEach { link ->
                    val contract = byRelation.getValue(link.contract)
                    val endpoint = if (link.first == current) contract.first else contract.second
                    if (endpoint.onDelete == RelationDeletePolicy.CASCADE) {
                        pending += if (link.first == current) link.second else link.first
                    }
                }
        }
        projection.projections
            .filter { (it.first in deleting) xor (it.second in deleting) }
            .forEach { link ->
                val current = if (link.first in deleting) link.first else link.second
                val contract = byRelation.getValue(link.contract)
                val endpoint = if (link.first == current) contract.first else contract.second
                when (endpoint.onDelete) {
                    RelationDeletePolicy.RESTRICT -> problems += problem(current, "relation_restricts_deletion")
                    RelationDeletePolicy.CASCADE -> error("Cascade closure is incomplete.")
                    RelationDeletePolicy.CLEAR -> relations.clearCounterpart(resources, current, link, problems)
                    else -> unknownVariant(endpoint.onDelete)
                }
            }
        if (problems.isNotEmpty()) return
        deleting.forEach { resource ->
            resources.remove(resource)
            removed += resource
        }
    }

    private fun move(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.MoveWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        if (intent.value.item == intent.value.after) {
            problems += ValueProblem(location = intent.value.at, code = "item_cannot_follow_itself")
            return
        }
        val current = resources[intent.value.at.resource]?.valueAt(intent.value.at.path)
        if (current == null) {
            problems += ValueProblem(location = intent.value.at, code = "item_missing")
            return
        }
        val items = current.itemsOrNull()
        val moving = items?.singleOrNull { it.id == intent.value.item }
        if (items == null || moving == null) {
            problems += ValueProblem(location = intent.value.at, code = "item_missing")
            return
        }
        val without = items.filterNot { it.id == intent.value.item }
        val index = insertionIndex(without, intent.value.after)
        if (index == null) {
            problems += ValueProblem(location = intent.value.at, code = "anchor_missing")
            return
        }
        val next = without.toMutableList().also { it.add(index, moving) }
        update(resources, intent.value.at, current.withItems(next), problems)
    }

    private fun retag(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.RetagWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[intent.value.at.resource]
        if (record == null) {
            problems += ValueProblem(location = intent.value.at, code = "resource_missing")
            return
        }
        if (intent.value.at.path.segments
                .isEmpty()
        ) {
            problems += ValueProblem(location = intent.value.at, code = "resource_configuration_requires_preview")
            return
        }
        val current = record.valueAt(intent.value.at.path) as? DataValue.NamedWrapper
        if (current == null) {
            problems += ValueProblem(location = intent.value.at, code = "expected_named")
            return
        }
        update(resources, intent.value.at, DataValue.named(intent.value.type, current.payload), problems)
    }

    private fun configureResource(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.ConfigureResourceWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        val location = ValueLocation.of(intent.value.resource)
        val record = resources[intent.value.resource]
        if (record == null) {
            problems += ValueProblem(location = location, code = "resource_missing")
            return
        }
        if (record.configuration.definition != intent.value.configuration.definition) {
            problems += ValueProblem(location = location, code = "type_argument_definition_changed")
            return
        }
        resources[intent.value.resource] = record.copy(configuration = intent.value.configuration)
    }

    private fun setTypes(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.SetTypesWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[intent.value.resource]
        if (record == null) {
            problems += problem(intent.value.resource, "resource_missing")
            return
        }
        resources[intent.value.resource] = record.copy(types = intent.value.types)
    }

    /** A declaration nothing a changed record stores reaches any more goes in the same commit. */
    private fun dropUnreachableTypes(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        latest: Map<ResourceId, AuthoringRecord>,
    ) {
        resources.entries.forEach { entry ->
            if (latest[entry.key] != entry.value) entry.setValue(entry.value.withoutUnreachableTypes())
        }
    }
}

private fun projectionKey(value: LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}:" +
        "${value.firstLocation?.let(ValuePath.serializer::toJsonCode)}:${value.secondLocation?.let(ValuePath.serializer::toJsonCode)}"

/**
 * The links of the state a plan proposes, judged only where the plan touched them: a link can change only when one of
 * its ends is [affected], so the slices of the affected resources are judged once, before and after. A rule that needs
 * another resource's links of one relation at one end judges just those, on first read.
 */
private class TouchedLinks(
    private val saved: AuthoringView,
    private val resources: Map<ResourceId, AuthoringRecord>,
    private val affected: Set<ResourceId>,
    private val contracts: List<RelationContract>,
    private val catalog: CheckedCatalog,
) : PlannedLinks {
    private val slices = saved.linkSlices.after(affected, ResourceValueMapper.discover(resources.filterKeys { it in affected }))
    private val endpoints = contracts.flatMap { listOf(it.first.id to it.first.slot, it.second.id to it.second.slot) }.toMap()
    private val asked = hashMapOf<Triple<ResourceId, RelationId, EndpointSlot>, List<LinkProjection>>()

    override val touching: ProjectionResult = judge(affected.flatMap { slice(it).let { slice -> slice.own + slice.into } })

    /** The links with an affected end in the saved state: what [touching] replaces. */
    fun savedTouching(): Set<LinkProjection> = affected.flatMapTo(hashSetOf()) { saved.judged(it).projections }

    override fun at(
        resource: ResourceId,
        contract: RelationId,
        slot: EndpointSlot,
    ): List<LinkProjection> =
        if (resource in affected) {
            touchingByEnd[Triple(resource, contract, slot)].orEmpty()
        } else {
            asked.getOrPut(Triple(resource, contract, slot)) {
                // Only the occurrences that can form such a link: of this relation, with [resource] at [slot].
                val held = slice(resource).let { it.own + it.into }
                judge(held.filter { endOf(it, resource) == slot && it.id.endpoint in contractEndpoints(contract) })
                    .projections
                    .filter { it.contract == contract && (if (slot == EndpointSlot.FIRST) it.first else it.second) == resource }
            }
        }

    /** [touching] by each link's end, so asking for one affected resource's links does not scan every touching link. */
    private val touchingByEnd by lazy(LazyThreadSafetyMode.NONE) {
        buildMap<Triple<ResourceId, RelationId, EndpointSlot>, MutableList<LinkProjection>> {
            touching.projections.forEach { link ->
                getOrPut(Triple(link.first, link.contract, EndpointSlot.FIRST)) { mutableListOf() } += link
                getOrPut(Triple(link.second, link.contract, EndpointSlot.SECOND)) { mutableListOf() } += link
            }
        }
    }

    private fun slice(resource: ResourceId): LinkSlice = slices[resource] ?: LinkSlice.EMPTY

    private fun contractEndpoints(contract: RelationId): Set<EndpointId> =
        contracts.filter { it.id == contract }.flatMapTo(hashSetOf()) { listOf(it.first.id, it.second.id) }

    /** The end [resource] would be of the link [occurrence] forms: its holder sits at its endpoint's slot, its target at the other. */
    private fun endOf(
        occurrence: LinkOccurrence,
        resource: ResourceId,
    ): EndpointSlot? {
        val held = endpoints[occurrence.id.endpoint] ?: return null
        return if (occurrence.source == resource) {
            held
        } else if (held == EndpointSlot.FIRST) {
            EndpointSlot.SECOND
        } else {
            EndpointSlot.FIRST
        }
    }

    private fun judge(occurrences: List<LinkOccurrence>): ProjectionResult {
        val distinct = occurrences.distinctBy { it.id }
        val ends = distinct.flatMap { listOf(it.source, it.target.resource) }.distinct()
        return ResourceValueMapper.project(distinct, ends.mapNotNull { id -> resources[id]?.let { id to it } }.toMap(), contracts, catalog)
    }
}
