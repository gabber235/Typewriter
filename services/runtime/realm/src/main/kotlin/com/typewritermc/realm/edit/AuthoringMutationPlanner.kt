package com.typewritermc.realm.edit

import com.typewritermc.authoring.definition
import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.endpoint
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

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
    private val catalog: CheckedCatalog,
    private val contracts: List<RelationContract>,
) {
    private val validator = AuthoringSnapshotValidator(catalog, contracts)
    private val relations = RelationValueSynchronizer(catalog, contracts)

    fun plan(
        latestResources: Map<ResourceId, AuthoringRecord>,
        edit: PreparedEdit,
    ): MutationPlanningResult {
        val resources = latestResources.toMutableMap()
        val removed = linkedSetOf<ResourceId>()
        val problems = replayStaged(resources, removed, edit).toMutableList()
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)

        val affected =
            buildSet {
                addAll(removed)
                resources.forEach { (id, record) -> if (latestResources[id] != record) add(id) }
            }
        val proposedLinks = ResourceValueMapper.discover(resources)
        val projection = ResourceValueMapper.project(proposedLinks, resources, contracts, catalog)
        problems += validator.validate(latestResources, resources, affected, projection)
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)

        val beforeLinks =
            ResourceValueMapper
                .project(ResourceValueMapper.discover(latestResources), latestResources, contracts, catalog)
                .projections
        val beforeSet = beforeLinks.toSet()
        val afterSet = projection.projections.toSet()
        val relations =
            RelationProjectionDelta(
                removals = (beforeSet - afterSet).sortedBy(::projectionKey),
                created = (afterSet - beforeSet).sortedBy(::projectionKey),
                metadataChanged = emptyList(),
            )
        return MutationPlanningResult.Accepted(
            AuthoringMutationPlan(
                resources = resources.filter { (id, value) -> latestResources[id] != value },
                removedResources = removed,
                relations = relations,
            ),
        )
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
                    delete(resources, removed, requested, problems)
                }

                is EditIntent.SetValueWrapper -> {
                    val before = resourceLinks(resources, intent.value.at.resource)
                    update(resources, intent.value.at, intent.value.value, problems)
                    relations.synchronizeValueMutation(before, resources, intent.value.at.resource, batchIdentity, index, problems)
                }

                is EditIntent.InsertWrapper -> {
                    val before = resourceLinks(resources, intent.value.at.resource)
                    insert(resources, intent, catalog, problems)
                    relations.synchronizeValueMutation(before, resources, intent.value.at.resource, batchIdentity, index, problems)
                }

                is EditIntent.RemoveWrapper -> {
                    val before = resourceLinks(resources, intent.value.at.resource)
                    remove(resources, intent, problems)
                    relations.synchronizeValueMutation(before, resources, intent.value.at.resource, batchIdentity, index, problems)
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
}

private fun projectionKey(value: LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}:" +
        "${value.firstLocation?.let(ValuePath.serializer::toJsonCode)}:${value.secondLocation?.let(ValuePath.serializer::toJsonCode)}"
