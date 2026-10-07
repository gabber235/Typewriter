package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.authoring.validateStructure
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import java.security.MessageDigest

internal sealed interface MutationPlanningResult {
    data class Accepted(
        val plan: AuthoringMutationPlan,
    ) : MutationPlanningResult

    data class Rejected(
        val problems: List<ValueProblem>,
    ) : MutationPlanningResult
}

private data class AuthoredCollection(
    val type: TypeUse.Named,
    val representation: ResolvedRepresentation.Sequence,
)

/** Replays ordered intent over the latest compatible root and validates the complete result. */
internal class AuthoringMutationPlanner(
    private val catalog: CheckedCatalog,
    private val contracts: List<RelationContract>,
    private val endpointBindings: List<EndpointBindingTemplate>? = null,
) {
    fun plan(
        latestResources: Map<ResourceId, AuthoringRecord>,
        edit: PreparedEdit,
    ): MutationPlanningResult {
        val resources = latestResources.toMutableMap()
        val removed = linkedSetOf<ResourceId>()
        val problems = mutableListOf<ValueProblem>()

        edit.intents.forEachIndexed { index, intent ->
            if (problems.isNotEmpty()) return@forEachIndexed
            when (intent) {
                is EditIntent.CreateResource -> {
                    create(resources, removed, intent, problems)
                }

                is EditIntent.DeleteResource -> {
                    delete(resources, removed, intent.id, problems)
                }

                is EditIntent.SetValue -> {
                    val before = ResourceValueMapper.discover(resources)
                    update(resources, intent.at, intent.value, problems)
                    synchronizeValueMutation(before, resources, canonicalPreparedIntentDigest(edit), index, problems)
                }

                is EditIntent.Insert -> {
                    val before = ResourceValueMapper.discover(resources)
                    insert(resources, intent, problems)
                    synchronizeValueMutation(before, resources, canonicalPreparedIntentDigest(edit), index, problems)
                }

                is EditIntent.Remove -> {
                    val before = ResourceValueMapper.discover(resources)
                    remove(resources, intent, problems)
                    synchronizeValueMutation(before, resources, canonicalPreparedIntentDigest(edit), index, problems)
                }

                is EditIntent.Move -> {
                    move(resources, intent, problems)
                }

                is EditIntent.ConnectRelation -> {
                    connect(resources, intent, canonicalPreparedIntentDigest(edit), index, problems)
                }

                is EditIntent.DisconnectRelation -> {
                    disconnect(resources, intent.occurrence, problems)
                }

                is EditIntent.Retag -> {
                    retag(resources, intent, problems)
                }

                is EditIntent.ConfigureResource -> {
                    configureResource(resources, intent, problems)
                }
            }
        }
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)

        val affected =
            buildSet {
                addAll(removed)
                resources.forEach { (id, record) -> if (latestResources[id] != record) add(id) }
            }
        resources.filterKeys { it in affected }.forEach { (id, record) ->
            when (val structural = record.validateStructure(catalog)) {
                StructuralResult.Valid -> Unit
                is StructuralResult.Invalid -> problems += structural.problems.map { it.on(id) }
            }
        }
        val proposedLinks = ResourceValueMapper.discover(resources)
        val projection = ResourceValueMapper.project(proposedLinks, resources, contracts, catalog)
        val affectedLocations =
            proposedLinks
                .filter { it.source in affected || it.target.resource in affected }
                .mapTo(hashSetOf()) { it.id.location }
        problems += projection.problems.filter { it.location in affectedLocations }
        validateOwnership(projection.projections, contracts, affected, problems)
        validateCardinality(projection.projections, contracts, affected, problems)
        if (problems.isNotEmpty()) return MutationPlanningResult.Rejected(problems)

        val beforeLinks =
            ResourceValueMapper
                .project(ResourceValueMapper.discover(latestResources), latestResources, contracts, catalog)
                .projections
        val beforeSet = beforeLinks.toSet()
        val afterSet = projection.projections.toSet()
        val relations =
            RelationProjectionDelta(
                removed = (beforeSet - afterSet).sortedBy(::projectionKey),
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

    private fun create(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        removed: MutableSet<ResourceId>,
        intent: EditIntent.CreateResource,
        problems: MutableList<ValueProblem>,
    ) {
        if (intent.id in resources) {
            problems += problem(intent.id, "resource_already_exists")
            return
        }
        resources[intent.id] = intent.record
        removed -= intent.id
    }

    private fun delete(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        removed: MutableSet<ResourceId>,
        requested: ResourceId,
        problems: MutableList<ValueProblem>,
    ) {
        if (requested !in resources) {
            problems += problem(requested, "resource_missing")
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
        val pending = ArrayDeque<ResourceId>().also { it += requested }
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
            problems += ValueProblem(location, "resource_missing")
            return
        }
        val updated = record.set(location.path, value)
        if (updated == null) problems += ValueProblem(location, "location_missing") else resources[location.resource] = updated
    }

    private fun insert(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.Insert,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[intent.at.resource]
        if (record == null) {
            problems += ValueProblem(intent.at, "expected_collection")
            return
        }
        val current = record.collectionValue(intent.at, problems) ?: return
        val items = current.itemsOrNull() ?: return
        if (items.any { it.id == intent.item.id }) {
            problems += ValueProblem(intent.at, "duplicate_item_id")
            return
        }
        val index = insertionIndex(items, intent.after)
        if (index == null) {
            problems += ValueProblem(intent.at, "anchor_missing")
            return
        }
        val next = items.toMutableList().also { it.add(index, intent.item) }
        update(resources, intent.at, current.withItems(next), problems)
    }

    private fun remove(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.Remove,
        problems: MutableList<ValueProblem>,
    ) {
        val current = resources[intent.at.resource]?.valueAt(intent.at.path)
        if (current == null) {
            problems += ValueProblem(intent.at, "expected_collection")
            return
        }
        val items = current.itemsOrNull()
        if (items == null) {
            problems += ValueProblem(intent.at, "expected_collection")
            return
        }
        if (items.none { it.id == intent.item }) {
            problems += ValueProblem(intent.at, "item_missing")
            return
        }
        update(resources, intent.at, current.withItems(items.filterNot { it.id == intent.item }), problems)
    }

    private fun move(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.Move,
        problems: MutableList<ValueProblem>,
    ) {
        if (intent.item == intent.after) {
            problems += ValueProblem(intent.at, "item_cannot_follow_itself")
            return
        }
        val current = resources[intent.at.resource]?.valueAt(intent.at.path)
        if (current == null) {
            problems += ValueProblem(intent.at, "item_missing")
            return
        }
        val items = current.itemsOrNull()
        val moving = items?.singleOrNull { it.id == intent.item }
        if (items == null || moving == null) {
            problems += ValueProblem(intent.at, "item_missing")
            return
        }
        val without = items.filterNot { it.id == intent.item }
        val index = insertionIndex(without, intent.after)
        if (index == null) {
            problems += ValueProblem(intent.at, "anchor_missing")
            return
        }
        val next = without.toMutableList().also { it.add(index, moving) }
        update(resources, intent.at, current.withItems(next), problems)
    }

    private fun connect(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.ConnectRelation,
        batch: String,
        ordinal: Int,
        problems: MutableList<ValueProblem>,
    ) {
        val source = intent.intent.source
        if (source.source != source.id.location.resource) {
            problems += ValueProblem(source.id.location, "source_location_resource_mismatch")
            return
        }
        val contract = contracts.singleOrNull { it.first.id == source.id.endpoint || it.second.id == source.id.endpoint }
        if (contract == null) {
            problems += ValueProblem(source.id.location, "unknown_endpoint")
            return
        }
        val oppositeEndpoint = if (contract.first.id == source.id.endpoint) contract.second.id else contract.first.id
        val counterpartLocation =
            when (val counterpart = intent.intent.counterpart) {
                null -> {
                    val targetRecord = resources[intent.intent.target]
                    val binding =
                        targetRecord?.let {
                            ResourceValueMapper.counterpartBinding(
                                oppositeEndpoint,
                                intent.intent.target,
                                it,
                                catalog,
                            )
                        } ?: CounterpartBinding.Missing
                    when (binding) {
                        is CounterpartBinding.Scalar -> {
                            val target = LinkTarget(source.source, source.id.location.path)
                            clearPreviousOpposite(
                                resources,
                                LinkOccurrence(LinkOccurrenceId(oppositeEndpoint, binding.location), intent.intent.target, target),
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
                                LinkTarget(source.source, source.id.location.path),
                                batch,
                                ordinal,
                                problems,
                            )
                        }

                        CounterpartBinding.ExplicitChoice -> {
                            problems += ValueProblem(source.id.location, "counterpart_choice_required")
                            return
                        }

                        CounterpartBinding.Missing -> {
                            null
                        }
                    }
                }

                is CounterpartChoice.Existing -> {
                    val existing = counterpart.occurrence
                    if (existing.source != intent.intent.target || existing.id.location.resource != intent.intent.target) {
                        problems += ValueProblem(existing.id.location, "counterpart_resource_mismatch")
                        return
                    }
                    if (existing.id.endpoint != oppositeEndpoint) {
                        problems += ValueProblem(existing.id.location, "counterpart_endpoint_mismatch")
                        return
                    }
                    if (existing.id.location == source.id.location) {
                        problems += ValueProblem(existing.id.location, "self_link_requires_distinct_occurrences")
                        return
                    }
                    clearPreviousOpposite(
                        resources,
                        existing,
                        LinkTarget(source.source, source.id.location.path),
                        problems,
                    )
                    if (problems.isNotEmpty()) return
                    writeLink(
                        resources,
                        existing.id.location,
                        existing.id.endpoint,
                        LinkTarget(source.source, source.id.location.path),
                        problems,
                    )
                    existing.id.location
                }

                is CounterpartChoice.New -> {
                    if (counterpart.containing.resource != intent.intent.target) {
                        problems += ValueProblem(counterpart.containing, "counterpart_resource_mismatch")
                        return
                    }
                    val prepared = counterpart.prepared.record
                    val actual = (prepared.configuration as? TypeSelection.Complete)?.use
                    if (actual == null) {
                        problems += ValueProblem(counterpart.containing, "counterpart_type_pending")
                        return
                    }
                    val materialized = DataValue.Named(actual, DataValue.Record(prepared.fields))
                    val targetRecord = resources[intent.intent.target]
                    val collection = targetRecord?.declaredCollection(counterpart.containing)
                    val embedded =
                        if (collection != null) {
                            val current = targetRecord.collectionValue(counterpart.containing, problems) ?: return
                            val item = deterministicItem(batch, ordinal, counterpart.containing)
                            insert(
                                resources,
                                EditIntent.Insert(
                                    counterpart.containing,
                                    current.itemsOrNull()?.lastOrNull()?.id,
                                    ListItem(item, materialized),
                                ),
                                problems,
                            )
                            counterpart.containing.item(item)
                        } else {
                            update(resources, counterpart.containing, materialized, problems)
                            counterpart.containing
                        }
                    if (problems.isNotEmpty()) return
                    val resolvedTargetRecord = targetRecord ?: return
                    val locations =
                        ResourceValueMapper
                            .declaredLocations(
                                oppositeEndpoint,
                                intent.intent.target,
                                resolvedTargetRecord,
                                catalog,
                            ).filter { it.path.startsWith(embedded.path) }
                    if (locations.size != 1) {
                        problems += ValueProblem(counterpart.containing, "new_counterpart_location_ambiguous")
                        return
                    }
                    val location = locations.single()
                    writeLink(
                        resources,
                        location,
                        oppositeEndpoint,
                        LinkTarget(source.source, source.id.location.path),
                        problems,
                    )
                    location
                }
            }
        if (problems.isNotEmpty()) return
        val sourceTarget = LinkTarget(intent.intent.target, counterpartLocation?.path)
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
        batch: String,
        ordinal: Int,
        problems: MutableList<ValueProblem>,
    ) {
        if (problems.isNotEmpty()) return
        val intended = ResourceValueMapper.discover(resources).associateBy(LinkOccurrence::id)
        val previous = before.associateBy(LinkOccurrence::id)
        previous.values.filter { intended[it.id] != it }.forEach { occurrence ->
            clearOppositeIfPresent(resources, occurrence, problems)
        }
        if (problems.isNotEmpty()) return
        intended.values.filter { previous[it.id] != it }.forEachIndexed { offset, occurrence ->
            val contract = contracts.singleOrNull { it.first.id == occurrence.id.endpoint || it.second.id == occurrence.id.endpoint }
            if (contract == null) {
                problems += ValueProblem(occurrence.id.location, "unknown_endpoint")
                return@forEachIndexed
            }
            val oppositeEndpoint = if (contract.first.id == occurrence.id.endpoint) contract.second.id else contract.first.id
            val counterpart =
                occurrence.target.opposite?.let { path ->
                    val location = ValueLocation(occurrence.target.resource, path)
                    CounterpartChoice.Existing(
                        LinkOccurrence(
                            LinkOccurrenceId(oppositeEndpoint, location),
                            occurrence.target.resource,
                            LinkTarget(occurrence.source, occurrence.id.location.path),
                        ),
                    )
                }
            connect(
                resources,
                EditIntent.ConnectRelation(ConnectIntent(occurrence, occurrence.target.resource, counterpart)),
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
        val location = ValueLocation(occurrence.target.resource, opposite)
        val current = ResourceValueMapper.discover(resources).singleOrNull { it.id.location == location } ?: return
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
        val current = ResourceValueMapper.discover(resources).associateBy(LinkOccurrence::id)[proposed.id] ?: return
        if (current.target == target) return
        val opposite = current.target.opposite ?: return
        val location = ValueLocation(current.target.resource, opposite)
        val other =
            ResourceValueMapper.discover(resources).associateBy(LinkOccurrence::id).values.singleOrNull {
                it.id.location == location && it.target.resource == current.source
            }
        if (other != null) clearLocation(resources, location, problems)
    }

    private fun writeLink(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        location: ValueLocation,
        endpoint: com.typewritermc.types.EndpointId,
        target: LinkTarget,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[location.resource]
        if (record == null) {
            problems += ValueProblem(location, "resource_missing")
            return
        }
        val current = record.valueAt(location.path)
        if (current == null) {
            val item = location.path.segments.lastOrNull() as? PathSegment.Item
            val collection = location.copy(path = ValuePath(location.path.segments.dropLast(1)))
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
                    problems += ValueProblem(location, "expected_named_link")
                    return
                }
                if (values == null) return
                insert(
                    resources,
                    EditIntent.Insert(
                        collection,
                        values.lastOrNull()?.id,
                        ListItem(item.id, DataValue.Named(named, DataValue.Link(endpoint, target))),
                    ),
                    problems,
                )
                return
            }
        }
        val named = current?.namedType() ?: record.authoredTypeAt(location.path, catalog).namedType()
        if (named == null) {
            problems += ValueProblem(location, "expected_named_link")
            return
        }
        update(resources, location, DataValue.Named(named, DataValue.Link(endpoint, target)), problems)
    }

    private fun appendDirectLink(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        collection: ValueLocation,
        endpoint: com.typewritermc.types.EndpointId,
        target: LinkTarget,
        batch: String,
        ordinal: Int,
        problems: MutableList<ValueProblem>,
    ): ValueLocation? {
        val record = resources[collection.resource]
        if (record == null) {
            problems += ValueProblem(collection, "expected_collection")
            return null
        }
        val current = record.collectionValue(collection, problems) ?: return null
        val items = current.itemsOrNull() ?: return null
        val item = deterministicItem(batch, ordinal, collection)
        val location = collection.item(item)
        val named = record.authoredTypeAt(location.path, catalog).namedType()
        if (named == null) {
            problems += ValueProblem(location, "expected_named_link")
            return null
        }
        insert(
            resources,
            EditIntent.Insert(
                collection,
                items.lastOrNull()?.id,
                ListItem(item, DataValue.Named(named, DataValue.Link(endpoint, target))),
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
            problems += ValueProblem(location, "expected_collection")
            return null
        }
        if (current.itemsOrNull() != null) return current
        if (current != DataValue.Unfilled) {
            problems += ValueProblem(location, "expected_collection")
            return null
        }
        val collection = declaredCollection(location)
        if (collection == null) {
            problems += ValueProblem(location, "expected_collection")
            return null
        }
        val payload =
            when (collection.representation.kind) {
                CollectionKind.List -> DataValue.ListValue(emptyList())
                CollectionKind.Set -> DataValue.SetValue(emptyList())
            }
        return DataValue.Named(collection.type, payload)
    }

    private fun AuthoringRecord.declaredCollection(location: ValueLocation): AuthoredCollection? {
        val type = authoredTypeAt(location.path, catalog).namedType() ?: return null
        val checked = (catalog.resolve(type) as? Resolution.Ready)?.value ?: return null
        val representation = checked.schema.representation as? ResolvedRepresentation.Sequence ?: return null
        return AuthoredCollection(type, representation)
    }

    private fun disconnect(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        occurrence: LinkOccurrenceId,
        problems: MutableList<ValueProblem>,
    ) {
        val current = ResourceValueMapper.discover(resources).associateBy(LinkOccurrence::id)[occurrence]
        if (current == null) {
            problems += ValueProblem(occurrence.location, "link_occurrence_missing")
            return
        }
        clearLocation(resources, occurrence.location, problems)
        current.target.opposite?.let { opposite ->
            val other = ValueLocation(current.target.resource, opposite)
            val oppositeValue = resources[other.resource]?.valueAt(other.path)
            val oppositeLink = (oppositeValue as? DataValue.Named)?.payload as? DataValue.Link
            if (oppositeLink != null && oppositeLink.target.resource == current.source) {
                clearLocation(resources, other, problems)
            }
        }
    }

    private fun retag(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.Retag,
        problems: MutableList<ValueProblem>,
    ) {
        val record = resources[intent.at.resource]
        if (record == null) {
            problems += ValueProblem(intent.at, "resource_missing")
            return
        }
        if (intent.at.path.segments
                .isEmpty()
        ) {
            problems += ValueProblem(intent.at, "resource_configuration_requires_preview")
            return
        }
        val current = record.valueAt(intent.at.path) as? DataValue.Named
        if (current == null) {
            problems += ValueProblem(intent.at, "expected_named")
            return
        }
        update(resources, intent.at, current.copy(actualType = intent.type), problems)
    }

    private fun configureResource(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        intent: EditIntent.ConfigureResource,
        problems: MutableList<ValueProblem>,
    ) {
        val location = ValueLocation(intent.resource, ValuePath())
        val record = resources[intent.resource]
        if (record == null) {
            problems += ValueProblem(location, "resource_missing")
            return
        }
        if (record.configuration.definition != intent.configuration.definition) {
            problems += ValueProblem(location, "type_argument_definition_changed")
            return
        }
        resources[intent.resource] = record.copy(configuration = intent.configuration)
    }

    private fun clearCounterpart(
        resources: MutableMap<ResourceId, AuthoringRecord>,
        deleted: ResourceId,
        projection: com.typewritermc.authoring.LinkProjection,
        problems: MutableList<ValueProblem>,
    ) {
        val candidates =
            buildList {
                val firstLocation = projection.firstLocation
                if (projection.first != deleted && firstLocation != null) {
                    add(ValueLocation(projection.first, firstLocation))
                }
                val secondLocation = projection.secondLocation
                if (projection.second != deleted && secondLocation != null) {
                    add(ValueLocation(projection.second, secondLocation))
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
        if (last is PathSegment.Item) {
            val parent = location.copy(path = ValuePath(location.path.segments.dropLast(1)))
            remove(resources, EditIntent.Remove(parent, last.id), problems)
            return
        }
        val nullable = resources[location.resource]?.authoredTypeAt(location.path, catalog) is TypeUse.Nullable
        update(resources, location, if (nullable) DataValue.Null else DataValue.Unfilled, problems)
    }
}

private fun validateOwnership(
    projections: List<com.typewritermc.authoring.LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val ownership =
        contracts.filter { RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in it.families }.mapTo(hashSetOf()) { it.id }
    val owned = projections.filter { it.contract in ownership }.groupBy { it.second }
    owned
        .filterValues { links -> links.size > 1 && links.any { it.first in affected || it.second in affected } }
        .forEach { (resource, _) -> problems += problem(resource, "multiple_immediate_owners") }
}

private fun validateCardinality(
    projections: List<com.typewritermc.authoring.LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val byContract = projections.groupBy { it.contract }
    contracts.forEach { contract ->
        val links = byContract[contract.id].orEmpty()
        if (contract.first.cardinality == com.typewritermc.types.EndpointCardinality.One) {
            links
                .groupBy { it.second }
                .filterValues { grouped -> grouped.size > 1 && grouped.any { it.first in affected || it.second in affected } }
                .forEach { (resource, _) ->
                    problems += problem(resource, "first_endpoint_cardinality_exceeded")
                }
        }
        if (contract.second.cardinality == com.typewritermc.types.EndpointCardinality.One) {
            links
                .groupBy { it.first }
                .filterValues { grouped -> grouped.size > 1 && grouped.any { it.first in affected || it.second in affected } }
                .forEach { (resource, _) ->
                    problems += problem(resource, "second_endpoint_cardinality_exceeded")
                }
        }
    }
}

private val TypeSelection.definition
    get() =
        when (this) {
            is TypeSelection.Complete -> use.definition
            is TypeSelection.Pending -> definition
        }

internal fun AuthoringRecord.valueAt(path: ValuePath): DataValue? = DataValue.Record(fields).valueAt(path.segments)

private fun DataValue.valueAt(segments: List<PathSegment>): DataValue? {
    if (segments.isEmpty()) return this
    if (this is DataValue.Named) return payload.valueAt(segments)
    val next =
        when (val segment = segments.first()) {
            is PathSegment.Field -> {
                (this as? DataValue.Record)?.fields?.get(segment.name)
            }

            is PathSegment.Item -> {
                when (this) {
                    is DataValue.ListValue -> {
                        items.singleOrNull { it.id == segment.id }?.value
                    }

                    is DataValue.SetValue -> {
                        items.singleOrNull { it.id == segment.id }?.value
                    }

                    is DataValue.MapValue -> {
                        rows.singleOrNull { it.id == segment.id }?.let {
                            DataValue.Record(
                                mapOf(
                                    "key" to it.key,
                                    "value" to it.value,
                                ),
                            )
                        }
                    }

                    else -> {
                        null
                    }
                }
            }

            PathSegment.MapKey -> {
                (this as? DataValue.Record)?.fields?.get("key")
            }

            PathSegment.MapValue -> {
                (this as? DataValue.Record)?.fields?.get("value")
            }
        } ?: return null
    return next.valueAt(segments.drop(1))
}

private fun AuthoringRecord.set(
    path: ValuePath,
    value: DataValue,
): AuthoringRecord? {
    if (path.segments.isEmpty()) return (value as? DataValue.Record)?.let { copy(fields = it.fields) }
    val updated = DataValue.Record(fields).set(path.segments, value) as? DataValue.Record ?: return null
    return copy(fields = updated.fields)
}

private fun DataValue.set(
    segments: List<PathSegment>,
    replacement: DataValue,
): DataValue? {
    if (segments.isEmpty()) return replacement
    if (this is DataValue.Named) return copy(payload = payload.set(segments, replacement) ?: return null)
    val tail = segments.drop(1)
    return when (val segment = segments.first()) {
        is PathSegment.Field -> {
            val record = this as? DataValue.Record ?: return null
            val child = record.fields[segment.name]
            if (child == null && tail.isEmpty()) {
                return record.copy(fields = record.fields + (segment.name to replacement))
            }
            child ?: return null
            val changed = child.set(tail, replacement) ?: return null
            record.copy(fields = record.fields + (segment.name to changed))
        }

        is PathSegment.Item -> {
            when (this) {
                is DataValue.ListValue -> {
                    copy(items = items.replace(segment.id, tail, replacement) ?: return null)
                }

                is DataValue.SetValue -> {
                    copy(items = items.replace(segment.id, tail, replacement) ?: return null)
                }

                is DataValue.MapValue -> {
                    val index = rows.indexOfFirst { it.id == segment.id }
                    if (index < 0) return null
                    val row = rows[index]
                    val changed =
                        when (tail.firstOrNull()) {
                            PathSegment.MapKey -> row.copy(key = row.key.set(tail.drop(1), replacement) ?: return null)
                            PathSegment.MapValue -> row.copy(value = row.value.set(tail.drop(1), replacement) ?: return null)
                            else -> return null
                        }
                    copy(rows = rows.toMutableList().also { it[index] = changed })
                }

                else -> {
                    null
                }
            }
        }

        PathSegment.MapKey, PathSegment.MapValue -> {
            null
        }
    }
}

private fun List<ListItem>.replace(
    id: ItemId,
    tail: List<PathSegment>,
    replacement: DataValue,
): List<ListItem>? {
    val index = indexOfFirst { it.id == id }
    if (index < 0) return null
    val next = this[index].value.set(tail, replacement) ?: return null
    return toMutableList().also { it[index] = it[index].copy(value = next) }
}

private fun DataValue?.itemsOrNull(): List<ListItem>? =
    when (this) {
        is DataValue.Named -> payload.itemsOrNull()
        is DataValue.ListValue -> items
        is DataValue.SetValue -> items
        else -> null
    }

private fun DataValue.withItems(items: List<ListItem>): DataValue =
    when (this) {
        is DataValue.Named -> copy(payload = payload.withItems(items))
        is DataValue.ListValue -> copy(items = items)
        is DataValue.SetValue -> copy(items = items)
        else -> error("Expected a collection value.")
    }

private fun DataValue.namedType(): TypeUse.Named? = (this as? DataValue.Named)?.actualType

private fun TypeUse?.namedType(): TypeUse.Named? =
    when (this) {
        is TypeUse.Named -> this
        is TypeUse.Nullable -> value.namedType()
        else -> null
    }

private fun deterministicItem(
    batch: String,
    ordinal: Int,
    containing: ValueLocation,
): ItemId {
    val content = "$batch:$ordinal:${containing.resource.value}:${containing.path}"
    val digest =
        MessageDigest
            .getInstance("SHA-256")
            .digest(content.toByteArray())
            .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
    return ItemId("relation:$digest")
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
): ValueProblem = ValueProblem(ValueLocation(resource, ValuePath()), code)

private fun ValueLocation.item(id: ItemId) = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun projectionKey(value: com.typewritermc.authoring.LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}:${value.firstLocation}:${value.secondLocation}"

private fun projectionEndpoints(value: com.typewritermc.authoring.LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}"
