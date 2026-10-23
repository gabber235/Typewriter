package com.typewritermc.realm.edit

import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.authoring.use
import com.typewritermc.realm.authoring.CounterpartBinding
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.endpoint
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Keeps relation values canonical while intents replay: connecting, disconnecting or rewriting a link also writes
 * or clears its inverse occurrence, and deleting a resource clears the counterparts that reference it.
 */
internal class RelationValueSynchronizer(
    private val catalog: CheckedCatalog,
    private val contracts: List<RelationContract>,
) {
    fun connect(
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
                    val collection = targetRecord?.declaredCollection(counterpart.value.containing, catalog)
                    val embedded =
                        if (collection != null) {
                            val current = targetRecord.collectionValue(counterpart.value.containing, catalog, problems) ?: return
                            val item = deterministicItem(batch, ordinal, counterpart.value.containing)
                            insert(
                                resources,
                                EditIntent.createInsert(
                                    at = counterpart.value.containing,
                                    after = current.itemsOrNull()?.lastOrNull()?.id,
                                    item = ListItem(id = item, value = materialized),
                                ),
                                catalog,
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

    fun synchronizeValueMutation(
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
                val values = record.collectionValue(collection, catalog, problems)?.itemsOrNull()
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
                    catalog,
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
        val current = record.collectionValue(collection, catalog, problems) ?: return null
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
            catalog,
            problems,
        )
        return location.takeIf { problems.isEmpty() }
    }

    fun disconnect(
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

    fun clearCounterpart(
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
