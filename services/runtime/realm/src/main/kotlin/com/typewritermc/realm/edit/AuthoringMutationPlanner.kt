package com.typewritermc.realm.edit

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.ValueReplacement
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.authoring.validateStructure
import com.typewritermc.authoring.writeField
import com.typewritermc.realm.authoring.CounterpartBinding
import com.typewritermc.realm.authoring.ProjectionResult
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.fields
import com.typewritermc.types.isAcyclic
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.ownsResources
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.SequenceResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
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

private data class AuthoredCollection(
    val type: NamedTypeUse,
    val representation: SequenceResolvedRepresentation,
)

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
        problems += validateSnapshot(latestResources, resources, affected, projection)
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
                    synchronizeValueMutation(before, resources, intent.value.at.resource, batchIdentity, index, problems)
                }

                is EditIntent.InsertWrapper -> {
                    val before = resourceLinks(resources, intent.value.at.resource)
                    insert(resources, intent, problems)
                    synchronizeValueMutation(before, resources, intent.value.at.resource, batchIdentity, index, problems)
                }

                is EditIntent.RemoveWrapper -> {
                    val before = resourceLinks(resources, intent.value.at.resource)
                    remove(resources, intent, problems)
                    synchronizeValueMutation(before, resources, intent.value.at.resource, batchIdentity, index, problems)
                }

                is EditIntent.MoveWrapper -> {
                    move(resources, intent, problems)
                }

                is EditIntent.ConnectRelationWrapper -> {
                    connect(resources, intent, batchIdentity, index, problems)
                }

                is EditIntent.DisconnectRelationWrapper -> {
                    disconnect(resources, intent.value, problems)
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

    /**
     * Validates the same affected graph boundary for replay and caller supplied working overlays. [before] holds the
     * resources the change started from, so removing the realm root or a realm section is detected.
     */
    fun validateSnapshot(
        before: Map<ResourceId, AuthoringRecord>,
        resources: Map<ResourceId, AuthoringRecord>,
        affected: Set<ResourceId>,
        projection: ProjectionResult = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, contracts, catalog),
    ): List<ValueProblem> {
        val problems = mutableListOf<ValueProblem>()
        resources.filterKeys { it in affected }.forEach { (id, record) ->
            when (val structural = record.validateStructure(catalog)) {
                StructuralResult.VALID -> Unit
                is StructuralResult.InvalidWrapper -> problems += structural.value.map { it.on(id) }
                else -> unknownVariant(structural)
            }
        }
        val affectedLocations =
            ResourceValueMapper
                .discover(resources)
                .filter { it.source in affected || it.target.resource in affected }
                .mapTo(hashSetOf()) { it.id.location }
        problems += projection.problems.filter { it.location in affectedLocations }
        validateOwnership(projection.projections, contracts, affected, problems)
        validateRealmStructure(before, resources, affected, projection.projections, contracts, catalog, problems)
        validateCardinality(projection.projections, contracts, affected, problems)
        validateAcyclic(projection.projections, contracts, affected, problems)
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
                    RelationDeletePolicy.CLEAR -> clearCounterpart(resources, current, link, problems)
                    else -> unknownVariant(endpoint.onDelete)
                }
            }
        if (problems.isNotEmpty()) return
        deleting.forEach { resource ->
            resources.remove(resource)
            removed += resource
        }
    }

    private fun update(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        location: ValueLocation,
        value: DataValue,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[location.resource]
        if (record == null) {
            problems += ValueProblem(location = location, code = "resource_missing")
            return
        }
        val updated = record.set(location.path, value)
        if (updated == null) {
            problems += ValueProblem(location = location, code = "location_missing")
        } else {
            resources[location.resource] = updated
        }
    }

    private fun insert(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.InsertWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[intent.value.at.resource]
        if (record == null) {
            problems += ValueProblem(location = intent.value.at, code = "expected_collection")
            return
        }
        val current = record.collectionValue(intent.value.at, problems) ?: return
        val items = current.itemsOrNull() ?: return
        if (items.any { it.id == intent.value.item.id }) {
            problems += ValueProblem(location = intent.value.at, code = "duplicate_item_id")
            return
        }
        val index = insertionIndex(items, intent.value.after)
        if (index == null) {
            problems += ValueProblem(location = intent.value.at, code = "anchor_missing")
            return
        }
        val next = items.toMutableList().also { it.add(index, intent.value.item) }
        update(resources, intent.value.at, current.withItems(next), problems)
    }

    private fun remove(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.RemoveWrapper,
        problems: MutableList<ValueProblem>,
    ) {
        val current = resources[intent.value.at.resource]?.valueAt(intent.value.at.path)
        if (current == null) {
            problems += ValueProblem(location = intent.value.at, code = "expected_collection")
            return
        }
        val items = current.itemsOrNull()
        if (items == null) {
            problems += ValueProblem(location = intent.value.at, code = "expected_collection")
            return
        }
        if (items.none { it.id == intent.value.item }) {
            problems += ValueProblem(location = intent.value.at, code = "item_missing")
            return
        }
        update(resources, intent.value.at, current.withItems(items.filterNot { it.id == intent.value.item }), problems)
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

    private fun connect(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.ConnectRelationWrapper,
        batch: String,
        ordinal: Int,
        problems: MutableList<ValueProblem>,
    ) {
        val source = intent.value.source
        if (source.source != source.id.location.resource) {
            problems += ValueProblem(location = source.id.location, code = "source_location_resource_mismatch")
            return
        }
        val contract = contracts.singleOrNull { it.first.id == source.id.endpoint || it.second.id == source.id.endpoint }
        if (contract == null) {
            problems += ValueProblem(location = source.id.location, code = "unknown_endpoint")
            return
        }
        val oppositeEndpoint = if (contract.first.id == source.id.endpoint) contract.second.id else contract.first.id
        val counterpartLocation =
            when (val counterpart = intent.value.counterpart) {
                null -> {
                    val targetRecord = resources[intent.value.target]
                    val binding =
                        targetRecord?.let {
                            ResourceValueMapper.counterpartBinding(
                                oppositeEndpoint,
                                intent.value.target,
                                it,
                                catalog,
                            )
                        } ?: CounterpartBinding.Missing
                    when (binding) {
                        is CounterpartBinding.Scalar -> {
                            val target = LinkTarget(resource = source.source, opposite = source.id.location.path)
                            clearPreviousOpposite(
                                resources,
                                LinkOccurrence(
                                    id = LinkOccurrenceId(endpoint = oppositeEndpoint, location = binding.location),
                                    source = intent.value.target,
                                    target = target,
                                ),
                                target,
                                problems,
                            )
                            writeLink(resources, binding.location, oppositeEndpoint, target, problems)
                            binding.location
                        }

                        is CounterpartBinding.Collection -> {
                            appendDirectLink(
                                resources,
                                binding.location,
                                oppositeEndpoint,
                                LinkTarget(resource = source.source, opposite = source.id.location.path),
                                batch,
                                ordinal,
                                problems,
                            )
                        }

                        CounterpartBinding.ExplicitChoice -> {
                            problems += ValueProblem(location = source.id.location, code = "counterpart_choice_required")
                            return
                        }

                        CounterpartBinding.Missing -> {
                            null
                        }
                    }
                }

                is CounterpartChoice.ExistingWrapper -> {
                    val existing = counterpart.value
                    val target = intent.value.target
                    if (existing.source != target || existing.id.location.resource != target) {
                        problems += ValueProblem(location = existing.id.location, code = "counterpart_resource_mismatch")
                        return
                    }
                    if (existing.id.endpoint != oppositeEndpoint) {
                        problems += ValueProblem(location = existing.id.location, code = "counterpart_endpoint_mismatch")
                        return
                    }
                    if (existing.id.location == source.id.location) {
                        problems += ValueProblem(location = existing.id.location, code = "self_link_requires_distinct_occurrences")
                        return
                    }
                    clearPreviousOpposite(
                        resources,
                        existing,
                        LinkTarget(resource = source.source, opposite = source.id.location.path),
                        problems,
                    )
                    if (problems.isNotEmpty()) return
                    writeLink(
                        resources,
                        existing.id.location,
                        existing.id.endpoint,
                        LinkTarget(resource = source.source, opposite = source.id.location.path),
                        problems,
                    )
                    existing.id.location
                }

                is CounterpartChoice.NewWrapper -> {
                    if (counterpart.value.containing.resource != intent.value.target) {
                        problems += ValueProblem(location = counterpart.value.containing, code = "counterpart_resource_mismatch")
                        return
                    }
                    val prepared =
                        (counterpart.value.prepared.content as? PreparedContent.RecordWrapper)?.record
                            ?: run {
                                problems += ValueProblem(location = counterpart.value.containing, code = "counterpart_requires_record")
                                return
                            }
                    val actual = (prepared.configuration as? TypeSelection.CompleteWrapper)?.use
                    if (actual == null) {
                        problems += ValueProblem(location = counterpart.value.containing, code = "counterpart_type_pending")
                        return
                    }
                    val materialized = DataValue.named(actual, DataValue.RecordWrapper(prepared.payload))
                    val targetRecord = resources[intent.value.target]
                    val collection = targetRecord?.declaredCollection(counterpart.value.containing)
                    val embedded =
                        if (collection != null) {
                            val current = targetRecord.collectionValue(counterpart.value.containing, problems) ?: return
                            val item = deterministicItem(batch, ordinal, counterpart.value.containing)
                            insert(
                                resources,
                                EditIntent.createInsert(
                                    at = counterpart.value.containing,
                                    after = current.itemsOrNull()?.lastOrNull()?.id,
                                    item = ListItem(id = item, value = materialized),
                                ),
                                problems,
                            )
                            counterpart.value.containing.item(item)
                        } else {
                            update(resources, counterpart.value.containing, materialized, problems)
                            counterpart.value.containing
                        }
                    if (problems.isNotEmpty()) return
                    val resolvedTargetRecord = targetRecord ?: return
                    val locations =
                        ResourceValueMapper
                            .declaredLocations(
                                oppositeEndpoint,
                                intent.value.target,
                                resolvedTargetRecord,
                                catalog,
                            ).filter { it.path.startsWith(embedded.path) }
                    if (locations.size != 1) {
                        problems += ValueProblem(location = counterpart.value.containing, code = "new_counterpart_location_ambiguous")
                        return
                    }
                    val location = locations.single()
                    writeLink(
                        resources,
                        location,
                        oppositeEndpoint,
                        LinkTarget(resource = source.source, opposite = source.id.location.path),
                        problems,
                    )
                    location
                }

                else -> {
                    unknownVariant(counterpart)
                }
            }
        if (problems.isNotEmpty()) return
        val sourceTarget = LinkTarget(resource = intent.value.target, opposite = counterpartLocation?.path)
        clearPreviousOpposite(resources, source, sourceTarget, problems)
        if (problems.isNotEmpty()) return
        writeLink(
            resources,
            source.id.location,
            source.id.endpoint,
            sourceTarget,
            problems,
        )
    }

    private fun synchronizeValueMutation(
        before: List<LinkOccurrence>,
        resources: MutableMap<ResourceId, AuthoringRecord>,
        source: ResourceId,
        batch: String,
        ordinal: Int,
        problems: MutableList<ValueProblem>,
    ) {
        if (problems.isNotEmpty()) return
        val intended = resourceLinks(resources, source).associateBy(LinkOccurrence::id)
        val previous = before.associateBy(LinkOccurrence::id)
        previous.values.filter { intended[it.id] != it }.forEach { occurrence ->
            clearOppositeIfPresent(resources, occurrence, problems)
        }
        if (problems.isNotEmpty()) return
        intended.values.filter { previous[it.id] != it }.forEachIndexed { offset, occurrence ->
            val contract = contracts.singleOrNull { it.first.id == occurrence.id.endpoint || it.second.id == occurrence.id.endpoint }
            if (contract == null) {
                problems += ValueProblem(location = occurrence.id.location, code = "unknown_endpoint")
                return@forEachIndexed
            }
            val oppositeEndpoint = if (contract.first.id == occurrence.id.endpoint) contract.second.id else contract.first.id
            val counterpart =
                occurrence.target.opposite?.let { path ->
                    val location = ValueLocation(resource = occurrence.target.resource, path = path)
                    CounterpartChoice.ExistingWrapper(
                        LinkOccurrence(
                            id = LinkOccurrenceId(endpoint = oppositeEndpoint, location = location),
                            source = occurrence.target.resource,
                            target = LinkTarget(resource = occurrence.source, opposite = occurrence.id.location.path),
                        ),
                    )
                }
            connect(
                resources,
                EditIntent.ConnectRelationWrapper(
                    ConnectIntent(source = occurrence, target = occurrence.target.resource, counterpart = counterpart),
                ),
                batch,
                ordinal + offset,
                problems,
            )
        }
    }

    private fun clearOppositeIfPresent(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        occurrence: LinkOccurrence,
        problems: MutableList<ValueProblem>,
    ) {
        val opposite = occurrence.target.opposite ?: return
        val location = ValueLocation(resource = occurrence.target.resource, path = opposite)
        val current = resourceLinks(resources, location.resource).singleOrNull { it.id.location == location } ?: return
        if (current.target.resource == occurrence.source && current.target.opposite == occurrence.id.location.path) {
            clearLocation(resources, location, problems)
        }
    }

    private fun clearPreviousOpposite(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        proposed: LinkOccurrence,
        target: LinkTarget,
        problems: MutableList<ValueProblem>,
    ) {
        val current = resourceLinks(resources, proposed.source).singleOrNull { it.id == proposed.id } ?: return
        if (current.target == target) return
        val opposite = current.target.opposite ?: return
        val location = ValueLocation(resource = current.target.resource, path = opposite)
        val other =
            resourceLinks(resources, location.resource).singleOrNull {
                it.id.location == location && it.target.resource == current.source
            }
        if (other != null) clearLocation(resources, location, problems)
    }

    private fun writeLink(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        location: ValueLocation,
        endpoint: EndpointId,
        target: LinkTarget,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[location.resource]
        if (record == null) {
            problems += ValueProblem(location = location, code = "resource_missing")
            return
        }
        val current = record.valueAt(location.path)
        if (current == null) {
            val item = location.path.segments.lastOrNull() as? PathSegment.ItemWrapper
            val collection = location.copy(path = ValuePath(segments = location.path.segments.dropLast(1)))
            val binding =
                ResourceValueMapper.counterpartBinding(
                    endpoint,
                    location.resource,
                    record,
                    catalog,
                )
            if (item != null && binding is CounterpartBinding.Collection && binding.location == collection) {
                val named = record.authoredTypeAt(location.path, catalog).namedType()
                val values = record.collectionValue(collection, problems)?.itemsOrNull()
                if (named == null) {
                    problems += ValueProblem(location = location, code = "expected_named_link")
                    return
                }
                if (values == null) return
                insert(
                    resources,
                    EditIntent.createInsert(
                        at = collection,
                        after = values.lastOrNull()?.id,
                        item =
                            ListItem(
                                id = item.id,
                                value = DataValue.named(named, DataValue.createLink(endpoint = endpoint, target = target)),
                            ),
                    ),
                    problems,
                )
                return
            }
        }
        val named = current?.namedType() ?: record.authoredTypeAt(location.path, catalog).namedType()
        if (named == null) {
            problems += ValueProblem(location = location, code = "expected_named_link")
            return
        }
        update(resources, location, DataValue.named(named, DataValue.createLink(endpoint = endpoint, target = target)), problems)
    }

    private fun appendDirectLink(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        collection: ValueLocation,
        endpoint: EndpointId,
        target: LinkTarget,
        batch: String,
        ordinal: Int,
        problems: MutableList<ValueProblem>,
    ): ValueLocation? {
        val record = resources[collection.resource]
        if (record == null) {
            problems += ValueProblem(location = collection, code = "expected_collection")
            return null
        }
        val current = record.collectionValue(collection, problems) ?: return null
        val items = current.itemsOrNull() ?: return null
        val item = deterministicItem(batch, ordinal, collection)
        val location = collection.item(item)
        val named = record.authoredTypeAt(location.path, catalog).namedType()
        if (named == null) {
            problems += ValueProblem(location = location, code = "expected_named_link")
            return null
        }
        insert(
            resources,
            EditIntent.createInsert(
                at = collection,
                after = items.lastOrNull()?.id,
                item = ListItem(id = item, value = DataValue.named(named, DataValue.createLink(endpoint = endpoint, target = target))),
            ),
            problems,
        )
        return location.takeIf { problems.isEmpty() }
    }

    private fun AuthoringRecord.collectionValue(
        location: ValueLocation,
        problems: MutableList<ValueProblem>,
    ): DataValue? {
        val current = valueAt(location.path)
        if (current == null) {
            problems += ValueProblem(location = location, code = "expected_collection")
            return null
        }
        if (current.itemsOrNull() != null) return current
        if (current != DataValue.UNFILLED) {
            problems += ValueProblem(location = location, code = "expected_collection")
            return null
        }
        val collection = declaredCollection(location)
        if (collection == null) {
            problems += ValueProblem(location = location, code = "expected_collection")
            return null
        }
        val payload =
            when (collection.representation.kind) {
                CollectionKind.LIST -> DataValue.listValue(emptyList())
                CollectionKind.SET -> DataValue.setValue(emptyList())
                else -> unknownVariant(collection.representation.kind)
            }
        return DataValue.named(collection.type, payload)
    }

    private fun AuthoringRecord.declaredCollection(location: ValueLocation): AuthoredCollection? {
        val type = authoredTypeAt(location.path, catalog).namedType() ?: return null
        val checked = (catalog.resolve(type.use) as? Resolution.Ready)?.value ?: return null
        val representation = checked.schema.representation as? ResolvedRepresentation.SequenceWrapper ?: return null
        return AuthoredCollection(type, representation.value)
    }

    private fun disconnect(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        occurrence: LinkOccurrenceId,
        problems: MutableList<ValueProblem>,
    ) {
        val current = resourceLinks(resources, occurrence.location.resource).singleOrNull { it.id == occurrence }
        if (current == null) {
            problems += ValueProblem(location = occurrence.location, code = "link_occurrence_missing")
            return
        }
        clearLocation(resources, occurrence.location, problems)
        current.target.opposite?.let { opposite ->
            val other = ValueLocation(resource = current.target.resource, path = opposite)
            val oppositeValue = resources[other.resource]?.valueAt(other.path)
            val oppositeLink = (oppositeValue as? DataValue.NamedWrapper)?.payload as? DataValue.LinkWrapper
            if (oppositeLink != null && oppositeLink.value.target.resource == current.source) {
                clearLocation(resources, other, problems)
            }
        }
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

    private fun clearCounterpart(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        deleted: ResourceId,
        projection: LinkProjection,
        problems: MutableList<ValueProblem>,
    ) {
        val candidates =
            buildList {
                val firstLocation = projection.firstLocation
                if (projection.first != deleted && firstLocation != null) {
                    add(ValueLocation.of(projection.first, firstLocation))
                }
                val secondLocation = projection.secondLocation
                if (projection.second != deleted && secondLocation != null) {
                    add(ValueLocation.of(projection.second, secondLocation))
                }
            }
        candidates.forEach { clearLocation(resources, it, problems) }
    }

    private fun clearLocation(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        location: ValueLocation,
        problems: MutableList<ValueProblem>,
    ) {
        val last = location.path.segments.lastOrNull()
        if (last is PathSegment.ItemWrapper) {
            val parent = location.copy(path = ValuePath(segments = location.path.segments.dropLast(1)))
            remove(resources, EditIntent.createRemove(at = parent, item = last.id), problems)
            return
        }
        val nullable = resources[location.resource]?.authoredTypeAt(location.path, catalog) is TypeUse.NullableWrapper
        update(resources, location, if (nullable) DataValue.NULL else DataValue.UNFILLED, problems)
    }
}

private fun validateOwnership(
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val ownership =
        contracts.filter { it.ownsResources }.mapTo(hashSetOf(), RelationContract::id)
    val owned = projections.filter { it.contract in ownership }.groupBy { it.second }
    owned
        .filterValues { links -> links.size > 1 && links.any { it.first in affected || it.second in affected } }
        .forEach { (resource, _) -> problems += problem(resource, "multiple_immediate_owners") }
}

/**
 * Keeps every resource reachable from the single realm root. An affected resource whose type is the member of an
 * ownership relation needs an owner (owner_required); catalog assembly makes every concrete resource type except the
 * realm root such a member, so this is every resource but the root. The root and each concrete realm section type
 * have exactly one instance, so a second one is rejected (singleton_exists) and so is removing or retyping the last
 * one (singleton_required).
 */
private fun validateRealmStructure(
    before: Map<ResourceId, AuthoringRecord>,
    resources: Map<ResourceId, AuthoringRecord>,
    affected: Set<ResourceId>,
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    catalog: CheckedCatalog,
    problems: MutableList<ValueProblem>,
) {
    fun AuthoringRecord.isRealmRoot() =
        configuration.definition.let {
            it == RealmRootDefinition.id ||
                catalog.isNominalSubtype(it, RealmRootDefinition.id)
        }

    fun AuthoringRecord.singletonKey(): TypeDefinitionId? =
        when {
            isRealmRoot() -> RealmRootDefinition.id
            catalog.isNominalSubtype(configuration.definition, RealmSectionDefinition.id) -> configuration.definition
            else -> null
        }

    val ownership = contracts.filter { it.ownsResources }
    val members = ownership.map { it.second.resource.definition }
    val owned = projections.filter { projection -> ownership.any { it.id == projection.contract } }.mapTo(hashSetOf()) { it.second }

    fun AuthoringRecord.isOwnable() =
        configuration.definition.let { type -> members.any { it == type || catalog.isNominalSubtype(type, it) } }

    // A member without a back reference loses its owner when only the owner's record changes, so the resources an
    // affected resource owned before the change are checked too.
    val formerlyOwned =
        ResourceValueMapper
            .project(ResourceValueMapper.discover(before.filterKeys { it in affected }), before, contracts, catalog)
            .projections
            .filter { projection -> projection.first in affected && ownership.any { it.id == projection.contract } }
            .map { it.second }
    (affected + formerlyOwned)
        .distinct()
        .filter { id -> resources[id]?.let { !it.isRealmRoot() && it.isOwnable() } == true && id !in owned }
        .forEach { id -> problems += problem(id, "owner_required") }
    val singletons = resources.entries.groupBy({ it.value.singletonKey() }, { it.key })
    singletons
        .filterKeys { it != null }
        .filterValues { ids -> ids.size > 1 && ids.any { it in affected } }
        .values
        .forEach { ids -> ids.filter { it in affected }.forEach { id -> problems += problem(id, "singleton_exists") } }
    before
        .filterKeys { it in affected }
        .forEach { (id, record) ->
            val key = record.singletonKey() ?: return@forEach
            if (resources[id]?.singletonKey() != key && singletons[key].isNullOrEmpty()) problems += problem(id, "singleton_required")
        }
}

private fun validateCardinality(
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val byContract = projections.groupBy { it.contract }
    contracts.forEach { contract ->
        val links = byContract[contract.id].orEmpty()
        if (contract.first.cardinality == EndpointCardinality.ONE) {
            links
                .groupBy { it.second }
                .filterValues { grouped -> grouped.size > 1 && grouped.any { it.first in affected || it.second in affected } }
                .forEach { (resource, _) ->
                    problems += problem(resource, "first_endpoint_cardinality_exceeded")
                }
        }
        if (contract.second.cardinality == EndpointCardinality.ONE) {
            links
                .groupBy { it.first }
                .filterValues { grouped -> grouped.size > 1 && grouped.any { it.first in affected || it.second in affected } }
                .forEach { (resource, _) ->
                    problems += problem(resource, "second_endpoint_cardinality_exceeded")
                }
        }
    }
}

/**
 * Rejects a cycle through any acyclic relation reachable from an affected resource.
 *
 * Walks first to second endpoints iteratively so long chains cannot exhaust the stack, and finishes every resource
 * once per contract.
 */
private fun validateAcyclic(
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val byContract = projections.groupBy { it.contract }
    contracts.filter { it.isAcyclic }.forEach { contract ->
        val next = byContract[contract.id].orEmpty().groupBy({ it.first }, { it.second })
        val finished = hashSetOf<ResourceId>()
        affected.forEach root@{ root ->
            val active = hashSetOf<ResourceId>()
            val stack = ArrayDeque(listOf(root to false))
            while (stack.isNotEmpty()) {
                val (id, leaving) = stack.removeLast()
                if (leaving) {
                    active -= id
                    finished += id
                    continue
                }
                if (id in finished) continue
                if (!active.add(id)) {
                    problems += problem(root, "relation_cycle")
                    return@root
                }
                stack.addLast(id to true)
                next[id].orEmpty().forEach { stack.addLast(it to false) }
            }
        }
    }
}

private fun AuthoringRecord.set(
    path: ValuePath,
    value: DataValue,
): AuthoringRecord? {
    if (path.segments.isEmpty()) return (value as? DataValue.RecordWrapper)?.let { copy(fields = it.value.fields) }
    val updated =
        (DataValue.RecordWrapper(payload).writeField(path, value) as? ValueReplacement.Replaced)
            ?.value as? DataValue.RecordWrapper
            ?: return null
    return copy(fields = updated.value.fields)
}

private fun DataValue?.itemsOrNull(): List<ListItem>? =
    when (this) {
        is DataValue.NamedWrapper -> payload.itemsOrNull()
        is DataValue.ListValueWrapper -> items
        is DataValue.SetValueWrapper -> items
        else -> null
    }

private fun DataValue.withItems(items: List<ListItem>): DataValue =
    when (this) {
        is DataValue.NamedWrapper -> DataValue.named(actualType, payload.withItems(items))
        is DataValue.ListValueWrapper -> DataValue.listValue(items)
        is DataValue.SetValueWrapper -> DataValue.setValue(items)
        else -> error("Expected a collection value.")
    }

private fun DataValue.namedType(): NamedTypeUse? = (this as? DataValue.NamedWrapper)?.actualType

private fun TypeUse?.namedType(): NamedTypeUse? =
    when (this) {
        is TypeUse.NamedWrapper -> value
        is TypeUse.NullableWrapper -> value.value.namedType()
        else -> null
    }

private fun deterministicItem(
    batch: String,
    ordinal: Int,
    containing: ValueLocation,
): ItemId {
    val content = "$batch:$ordinal:${containing.resource.value}:${ValuePath.serializer.toJsonCode(containing.path)}"
    return ItemId(value = "relation:${content.sha256Hex()}")
}

private fun ValuePath.startsWith(prefix: ValuePath): Boolean =
    segments.size >= prefix.segments.size && segments.take(prefix.segments.size) == prefix.segments

private fun insertionIndex(
    items: List<ListItem>,
    after: ItemId?,
): Int? = if (after == null) 0 else items.indexOfFirst { it.id == after }.takeIf { it >= 0 }?.plus(1)

private fun ValueProblem.on(resource: ResourceId): ValueProblem = copy(location = location.copy(resource = resource))

private fun problem(
    resource: ResourceId,
    code: String,
): ValueProblem = ValueProblem(location = ValueLocation.of(resource), code = code)

private fun projectionKey(value: LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}:" +
        "${value.firstLocation?.let(ValuePath.serializer::toJsonCode)}:${value.secondLocation?.let(ValuePath.serializer::toJsonCode)}"

private fun resourceLinks(
    resources: Map<ResourceId, AuthoringRecord>,
    resource: ResourceId,
): List<LinkOccurrence> = resources[resource]?.let { ResourceValueMapper.discover(mapOf(resource to it)) }.orEmpty()
