package com.typewritermc.realm.repository

import com.typewritermc.authoring.field
import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.authoring.text
import com.typewritermc.authoring.use
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
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
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import java.util.Collections

/**
 * The planner rejected a staged write or a finished edit. [problems] name every broken rule, such as
 * `relation_cycle`, `owner_required` or `singleton_exists`, at the location it applies to.
 */
internal class AuthoringPlanRejected(
    val problems: List<ValueProblem>,
) : IllegalArgumentException(problems.joinToString { "${it.location.resource.value} ${it.location.path.text}: ${it.code}" })

/**
 * Owns the request local graph and normalized intent sequence used during operation preparation.
 *
 * New counterpart records and collection items are allocated before staged content becomes visible to later
 * callbacks. The emitted edit therefore replays without allocation history. [finish] validates the complete
 * graph and checks that replay reproduces staged resources; the enclosing edit context adds baseline evidence.
 */
internal class AuthoringPlanningSession(
    val baseline: AuthoringView,
    private val invocationId: String,
) {
    val planner = AuthoringMutationPlanner(baseline.catalog.checked, baseline.catalog.relations, baseline.catalog.endpointBindings)
    private val staged = baseline.resources.toMutableMap()
    private val removed = linkedSetOf<ResourceId>()
    val resources: Map<ResourceId, AuthoringRecord> = Collections.unmodifiableMap(staged)
    private val emitted = mutableListOf<EditIntent>()
    val intents: List<EditIntent> get() = emitted.toList()
    private var allocation = 0L

    fun deleteAll(ids: List<ResourceId>) {
        val deletion = ids.distinct().map { EditIntent.createDeleteResource(id = it) }
        val problems =
            planner.replayStaged(
                staged,
                removed,
                PreparedEdit(catalog = baseline.catalog.generation, expectations = emptyList(), intents = deletion),
            )
        if (problems.isNotEmpty()) throw AuthoringPlanRejected(problems)
        emitted += deletion
    }

    fun append(intent: EditIntent) {
        when (intent) {
            is EditIntent.ConnectRelationWrapper -> {
                connection(intent.value)
            }

            is EditIntent.CreateResourceWrapper -> {
                val created = intent.value
                val references = mutableListOf<LinkOccurrence>()
                val fields =
                    strip(
                        DataValue.RecordWrapper(created.record.payload),
                        ValueLocation.of(created.id),
                        references,
                    ) as DataValue.RecordWrapper
                emit(EditIntent.CreateResourceWrapper(created.copy(record = created.record.copy(fields = fields.value.fields))))
                references.forEach {
                    connection(
                        ConnectIntent(source = it, target = it.target.resource, counterpart = explicitOpposite(it)),
                    )
                }
            }

            is EditIntent.SetValueWrapper -> {
                val set = intent.value
                val references = mutableListOf<LinkOccurrence>()
                val value = strip(set.value, set.at, references)
                if (references.size == 1 && references.single().id.location == set.at) {
                    val ref = references.single()
                    connection(ConnectIntent(source = ref, target = ref.target.resource, counterpart = explicitOpposite(ref)))
                } else {
                    clearReferences(set.at)
                    writeAt(set.at, value)
                    references.forEach {
                        connection(
                            ConnectIntent(source = it, target = it.target.resource, counterpart = explicitOpposite(it)),
                        )
                    }
                }
            }

            is EditIntent.InsertWrapper -> {
                val insert = intent.value
                val references = mutableListOf<LinkOccurrence>()
                val value = strip(insert.item.value, insert.at.item(insert.item.id), references)
                emit(EditIntent.InsertWrapper(insert.copy(item = insert.item.copy(value = value))))
                references.forEach {
                    connection(
                        ConnectIntent(source = it, target = it.target.resource, counterpart = explicitOpposite(it)),
                    )
                }
            }

            is EditIntent.RemoveWrapper -> {
                val remove = intent.value
                clearReferences(remove.at.item(remove.item))
                if (resources[remove.at.resource]?.valueAt(remove.at.path.item(remove.item)) != null) emit(intent)
            }

            else -> {
                emit(intent)
            }
        }
    }

    /**
     * Plans the complete normalized edit against the baseline. Throws [AuthoringPlanRejected] when the finished graph
     * breaks a planner rule, such as an ownership cycle or a resource left without an owner.
     */
    fun finish(): Pair<PreparedEdit, AuthoringMutationPlan> {
        val edit = PreparedEdit(catalog = baseline.catalog.generation, expectations = emptyList(), intents = intents)
        val plan = accepted(planner.plan(baseline.resources, edit))
        check(
            baseline.resources + plan.resources - plan.removedResources == resources,
        ) { "Normalized edit replay changed the staged graph" }
        return edit to plan
    }

    private fun emit(intent: EditIntent) {
        val edit = PreparedEdit(catalog = baseline.catalog.generation, expectations = emptyList(), intents = listOf(intent))
        val problems = planner.replayStaged(staged, removed, edit)
        if (problems.isNotEmpty()) throw AuthoringPlanRejected(problems)
        emitted += intent
    }

    private fun connection(intent: ConnectIntent) {
        val source = intent.source
        val contract =
            baseline.catalog.relations.singleOrNull { it.first.id == source.id.endpoint || it.second.id == source.id.endpoint }
                ?: error("Unknown relation endpoint ${source.id.endpoint}")
        val endpoint = if (contract.first.id == source.id.endpoint) contract.second.id else contract.first.id
        val target = resources[intent.target] ?: error("The relation target is unavailable")
        val counterpart =
            when (val requested = intent.counterpart) {
                is CounterpartChoice.ExistingWrapper -> {
                    requested
                }

                is CounterpartChoice.NewWrapper -> {
                    val record =
                        (requested.value.prepared.content as? PreparedContent.RecordWrapper)?.record
                            ?: error("A counterpart must be a prepared record")
                    val configured =
                        (record.configuration as? TypeSelection.CompleteWrapper)?.use ?: error("The counterpart type is incomplete")
                    val value = DataValue.named(configured, DataValue.RecordWrapper(record.payload))
                    val existing = target.valueAt(requested.value.containing.path)
                    val declared = target.authoredTypeAt(requested.value.containing.path, baseline.catalog.checked)
                    val schema = declared?.let { baseline.catalog.checked.resolve(it) } as? Resolution.Ready
                    val embedded =
                        if (schema?.value?.schema?.representation is ResolvedRepresentation.SequenceWrapper) {
                            val id =
                                item(
                                    "counterpart:${LinkOccurrenceId.serializer.toJsonCode(
                                        source.id,
                                    )}:${ValueLocation.serializer.toJsonCode(requested.value.containing)}",
                                )
                            val items =
                                when (val payload = if (existing is DataValue.NamedWrapper) existing.payload else existing) {
                                    is DataValue.ListValueWrapper -> payload.items
                                    is DataValue.SetValueWrapper -> payload.items
                                    else -> emptyList()
                                }
                            append(
                                EditIntent.createInsert(
                                    at = requested.value.containing,
                                    after = items.lastOrNull()?.id,
                                    item = ListItem(id = id, value = value),
                                ),
                            )
                            requested.value.containing.item(id)
                        } else {
                            append(EditIntent.createSetValue(at = requested.value.containing, value = value))
                            requested.value.containing
                        }
                    val locations =
                        ResourceValueMapper
                            .declaredLocations(
                                endpoint,
                                intent.target,
                                resources.getValue(intent.target),
                                baseline.catalog.checked,
                            ).filter { it.path.atOrBelow(embedded.path) }
                    require(locations.size == 1) { "The prepared counterpart has ambiguous endpoints" }
                    CounterpartChoice.ExistingWrapper(
                        LinkOccurrence(
                            id = LinkOccurrenceId(endpoint = endpoint, location = locations.single()),
                            source = intent.target,
                            target = LinkTarget(resource = source.source, opposite = source.id.location.path),
                        ),
                    )
                }

                null -> {
                    when (val binding = ResourceValueMapper.counterpartBinding(endpoint, intent.target, target, baseline.catalog.checked)) {
                        is CounterpartBinding.Scalar -> {
                            CounterpartChoice.ExistingWrapper(
                                LinkOccurrence(
                                    id = LinkOccurrenceId(endpoint = endpoint, location = binding.location),
                                    source = intent.target,
                                    target = LinkTarget(resource = source.source, opposite = source.id.location.path),
                                ),
                            )
                        }

                        is CounterpartBinding.Collection -> {
                            CounterpartChoice.ExistingWrapper(
                                LinkOccurrence(
                                    id =
                                        LinkOccurrenceId(
                                            endpoint = endpoint,
                                            location =
                                                binding.location.item(
                                                    item(
                                                        "inverse:${LinkOccurrenceId.serializer.toJsonCode(
                                                            source.id,
                                                        )}:${ValueLocation.serializer.toJsonCode(binding.location)}",
                                                    ),
                                                ),
                                        ),
                                    source = intent.target,
                                    target = LinkTarget(resource = source.source, opposite = source.id.location.path),
                                ),
                            )
                        }

                        CounterpartBinding.Missing -> {
                            null
                        }

                        CounterpartBinding.ExplicitChoice -> {
                            error("Choose an exact relation counterpart")
                        }
                    }
                }

                else -> {
                    unknownVariant(requested)
                }
            }
        emit(EditIntent.ConnectRelationWrapper(intent.copy(counterpart = counterpart)))
    }

    private fun explicitOpposite(source: LinkOccurrence): CounterpartChoice? {
        val path = source.target.opposite ?: return null
        val contract = baseline.catalog.relations.single { it.first.id == source.id.endpoint || it.second.id == source.id.endpoint }
        val endpoint = if (contract.first.id == source.id.endpoint) contract.second.id else contract.first.id
        return CounterpartChoice.ExistingWrapper(
            LinkOccurrence(
                id = LinkOccurrenceId(endpoint = endpoint, location = ValueLocation(resource = source.target.resource, path = path)),
                source = source.target.resource,
                target = LinkTarget(resource = source.source, opposite = source.id.location.path),
            ),
        )
    }

    private fun clearReferences(at: ValueLocation) {
        ResourceValueMapper
            .discover(
                mapOf(at.resource to resources.getValue(at.resource)),
            ).filter {
                it.id.location.path
                    .atOrBelow(at.path)
            }.forEach { emit(EditIntent.DisconnectRelationWrapper(it.id)) }
    }

    private fun writeAt(
        at: ValueLocation,
        value: DataValue,
    ) {
        if (resources[at.resource]?.valueAt(at.path) == null && at.path.segments.lastOrNull() is PathSegment.ItemWrapper) {
            val id = (at.path.segments.last() as PathSegment.ItemWrapper).id
            emit(
                EditIntent.createInsert(
                    at = at.copy(path = ValuePath(segments = at.path.segments.dropLast(1))),
                    after = null,
                    item = ListItem(id = id, value = value),
                ),
            )
        } else {
            emit(EditIntent.createSetValue(at = at, value = value))
        }
    }

    private fun strip(
        value: DataValue,
        at: ValueLocation,
        links: MutableList<LinkOccurrence>,
    ): DataValue =
        when (value) {
            is DataValue.LinkWrapper -> {
                links +=
                    LinkOccurrence(
                        id = LinkOccurrenceId(endpoint = value.endpoint, location = at),
                        source = at.resource,
                        target = value.value.target,
                    )
                DataValue.UNFILLED
            }

            is DataValue.NamedWrapper -> {
                DataValue.named(value.actualType, strip(value.payload, at, links))
            }

            is DataValue.RecordWrapper -> {
                DataValue.record(value.fields.associate { field -> field.name to strip(field.value, at.field(field.name), links) })
            }

            is DataValue.ListValueWrapper -> {
                DataValue.listValue(value.items.map { it.copy(value = strip(it.value, at.item(it.id), links)) })
            }

            is DataValue.SetValueWrapper -> {
                DataValue.setValue(value.items.map { it.copy(value = strip(it.value, at.item(it.id), links)) })
            }

            is DataValue.MapValueWrapper -> {
                DataValue.mapValue(
                    value.rows.map {
                        it.copy(
                            key = strip(it.key, at.item(it.id).mapKey(), links),
                            value = strip(it.value, at.item(it.id).mapValue(), links),
                        )
                    },
                )
            }

            else -> {
                value
            }
        }

    private fun item(key: String): ItemId = ItemId(value = "operation:" + "$invocationId:$key:${allocation++}".sha256Hex())

    private fun accepted(result: MutationPlanningResult): AuthoringMutationPlan =
        when (result) {
            is MutationPlanningResult.Accepted -> result.plan
            is MutationPlanningResult.Rejected -> throw AuthoringPlanRejected(result.problems)
        }
}

private fun ValuePath.atOrBelow(other: ValuePath) =
    segments.size >= other.segments.size && segments.take(other.segments.size) == other.segments
