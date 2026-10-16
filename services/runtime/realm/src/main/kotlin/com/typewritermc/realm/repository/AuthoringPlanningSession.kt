package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.immutableCopy
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.authoredTypeAt
import com.typewritermc.types.DataValue
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.immutableCopy
import com.typewritermc.types.immutableListCopy
import java.security.MessageDigest

/** Lowers allocations before exposing staged content, so later replay needs no allocation history. */
internal class AuthoringPlanningSession(
    val baseline: AuthoringView,
    private val invocationId: String,
) {
    val planner = AuthoringMutationPlanner(baseline.catalog.checked, baseline.catalog.relations, baseline.catalog.endpointBindings)
    private val staged = baseline.resources.toMutableMap()
    private val removed = linkedSetOf<ResourceId>()
    val resources: Map<ResourceId, AuthoringRecord> = java.util.Collections.unmodifiableMap(staged)
    private val emitted = mutableListOf<EditIntent>()
    val intents: List<EditIntent> get() = emitted.immutableListCopy()
    private var allocation = 0L

    fun deleteAll(ids: List<ResourceId>) {
        val deletion = ids.distinct().map { EditIntent.DeleteResource(it) }
        val problems = planner.replayStaged(staged, removed, PreparedEdit(baseline.catalog.generation, emptyList(), deletion))
        require(problems.isEmpty()) { problems.joinToString { "${it.location}: ${it.code}" } }
        emitted += deletion
    }

    fun append(intent: EditIntent) {
        when (intent) {
            is EditIntent.ConnectRelation -> {
                connection(intent.intent)
            }

            is EditIntent.CreateResource -> {
                val references = mutableListOf<LinkOccurrence>()
                val fields =
                    strip(
                        DataValue.Record(intent.record.fields),
                        ValueLocation(intent.id, ValuePath()),
                        references,
                    ) as DataValue.Record
                emit(intent.copy(record = intent.record.copy(fields = fields.fields)))
                references.forEach { connection(ConnectIntent(it, it.target.resource, explicitOpposite(it))) }
            }

            is EditIntent.SetValue -> {
                val references = mutableListOf<LinkOccurrence>()
                val value = strip(intent.value, intent.at, references)
                if (references.size == 1 && references.single().id.location == intent.at) {
                    val ref = references.single()
                    connection(ConnectIntent(ref, ref.target.resource, explicitOpposite(ref)))
                } else {
                    clearReferences(intent.at)
                    writeAt(intent.at, value)
                    references.forEach { connection(ConnectIntent(it, it.target.resource, explicitOpposite(it))) }
                }
            }

            is EditIntent.Insert -> {
                val references = mutableListOf<LinkOccurrence>()
                val value = strip(intent.item.value, intent.at.item(intent.item.id), references)
                emit(intent.copy(item = intent.item.copy(value = value)))
                references.forEach { connection(ConnectIntent(it, it.target.resource, explicitOpposite(it))) }
            }

            is EditIntent.Remove -> {
                clearReferences(intent.at.item(intent.item))
                if (resources[intent.at.resource]?.valueAt(intent.at.path.item(intent.item)) != null) emit(intent)
            }

            else -> {
                emit(intent)
            }
        }
    }

    fun finish(): Pair<PreparedEdit, AuthoringMutationPlan> {
        val edit = PreparedEdit(baseline.catalog.generation, emptyList(), intents)
        val plan = accepted(planner.plan(baseline.resources, edit))
        check(
            baseline.resources + plan.resources - plan.removedResources == resources,
        ) { "Normalized edit replay changed the staged graph" }
        return edit to plan
    }

    private fun emit(intent: EditIntent) {
        val stable = intent.freeze()
        val edit = PreparedEdit(baseline.catalog.generation, emptyList(), listOf(stable))
        val problems = planner.replayStaged(staged, removed, edit)
        require(problems.isEmpty()) { problems.joinToString { "${it.location}: ${it.code}" } }
        emitted += stable
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
                is CounterpartChoice.Existing -> {
                    requested
                }

                is CounterpartChoice.New -> {
                    val record =
                        (requested.prepared.content as? PreparedContent.Record)?.record ?: error("A counterpart must be a prepared record")
                    val configured = (record.configuration as? TypeSelection.Complete)?.use ?: error("The counterpart type is incomplete")
                    val value = DataValue.Named(configured, DataValue.Record(record.fields))
                    val existing = target.valueAt(requested.containing.path)
                    val declared = target.authoredTypeAt(requested.containing.path, baseline.catalog.checked)
                    val schema = declared?.let { baseline.catalog.checked.resolve(it) } as? Resolution.Ready
                    val embedded =
                        if (schema?.value?.schema?.representation is ResolvedRepresentation.Sequence) {
                            val id = item("counterpart:${source.id}:${requested.containing}")
                            val items =
                                when (val payload = if (existing is DataValue.Named) existing.payload else existing) {
                                    is DataValue.ListValue -> payload.items
                                    is DataValue.SetValue -> payload.items
                                    else -> emptyList()
                                }
                            append(EditIntent.Insert(requested.containing, items.lastOrNull()?.id, ListItem(id, value)))
                            requested.containing.item(id)
                        } else {
                            append(EditIntent.SetValue(requested.containing, value))
                            requested.containing
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
                    CounterpartChoice.Existing(
                        LinkOccurrence(
                            LinkOccurrenceId(endpoint, locations.single()),
                            intent.target,
                            LinkTarget(source.source, source.id.location.path),
                        ),
                    )
                }

                null -> {
                    when (val binding = ResourceValueMapper.counterpartBinding(endpoint, intent.target, target, baseline.catalog.checked)) {
                        is CounterpartBinding.Scalar -> {
                            CounterpartChoice.Existing(
                                LinkOccurrence(
                                    LinkOccurrenceId(endpoint, binding.location),
                                    intent.target,
                                    LinkTarget(source.source, source.id.location.path),
                                ),
                            )
                        }

                        is CounterpartBinding.Collection -> {
                            CounterpartChoice.Existing(
                                LinkOccurrence(
                                    LinkOccurrenceId(endpoint, binding.location.item(item("inverse:${source.id}:${binding.location}"))),
                                    intent.target,
                                    LinkTarget(source.source, source.id.location.path),
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
            }
        emit(EditIntent.ConnectRelation(intent.copy(counterpart = counterpart)))
    }

    private fun explicitOpposite(source: LinkOccurrence): CounterpartChoice? {
        val path = source.target.opposite ?: return null
        val contract = baseline.catalog.relations.single { it.first.id == source.id.endpoint || it.second.id == source.id.endpoint }
        val endpoint = if (contract.first.id == source.id.endpoint) contract.second.id else contract.first.id
        return CounterpartChoice.Existing(
            LinkOccurrence(
                LinkOccurrenceId(endpoint, ValueLocation(source.target.resource, path)),
                source.target.resource,
                LinkTarget(source.source, source.id.location.path),
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
            }.forEach { emit(EditIntent.DisconnectRelation(it.id)) }
    }

    private fun writeAt(
        at: ValueLocation,
        value: DataValue,
    ) {
        if (resources[at.resource]?.valueAt(at.path) == null && at.path.segments.lastOrNull() is PathSegment.Item) {
            val id = (at.path.segments.last() as PathSegment.Item).id
            emit(EditIntent.Insert(at.copy(path = ValuePath(at.path.segments.dropLast(1))), null, ListItem(id, value)))
        } else {
            emit(EditIntent.SetValue(at, value))
        }
    }

    private fun strip(
        value: DataValue,
        at: ValueLocation,
        links: MutableList<LinkOccurrence>,
    ): DataValue =
        when (value) {
            is DataValue.Link -> {
                links += LinkOccurrence(LinkOccurrenceId(value.endpoint, at), at.resource, value.target)
                DataValue.Unfilled
            }

            is DataValue.Named -> {
                value.copy(payload = strip(value.payload, at, links))
            }

            is DataValue.Record -> {
                value.copy(fields = value.fields.mapValues { (key, child) -> strip(child, at.field(key), links) })
            }

            is DataValue.ListValue -> {
                value.copy(items = value.items.map { it.copy(value = strip(it.value, at.item(it.id), links)) })
            }

            is DataValue.SetValue -> {
                value.copy(items = value.items.map { it.copy(value = strip(it.value, at.item(it.id), links)) })
            }

            is DataValue.MapValue -> {
                value.copy(
                    rows =
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

    private fun item(key: String): ItemId {
        val bytes = MessageDigest.getInstance("SHA-256").digest("$invocationId:$key:${allocation++}".toByteArray())
        return ItemId("operation:" + bytes.joinToString("") { "%02x".format(it.toInt() and 255) })
    }

    private fun accepted(result: MutationPlanningResult): AuthoringMutationPlan =
        when (result) {
            is MutationPlanningResult.Accepted -> result.plan

            is MutationPlanningResult.Rejected -> throw IllegalArgumentException(
                result.problems.joinToString { "${it.location}: ${it.code}" },
            )
        }
}

private fun ValueLocation.freeze() = copy(path = path.immutableCopy())

private fun EditIntent.freeze(): EditIntent =
    when (this) {
        is EditIntent.CreateResource -> {
            copy(record = record.immutableCopy())
        }

        is EditIntent.DeleteResource -> {
            this
        }

        is EditIntent.SetValue -> {
            copy(at = at.freeze(), value = value.immutableCopy())
        }

        is EditIntent.Insert -> {
            copy(at = at.freeze(), item = item.copy(value = item.value.immutableCopy()))
        }

        is EditIntent.Remove -> {
            copy(at = at.freeze())
        }

        is EditIntent.Move -> {
            copy(at = at.freeze())
        }

        is EditIntent.ConnectRelation -> {
            copy(
                intent =
                    intent.copy(
                        source = intent.source.immutableCopy(),
                        counterpart =
                            when (val choice = intent.counterpart) {
                                null -> {
                                    null
                                }

                                is CounterpartChoice.Existing -> {
                                    choice.copy(occurrence = choice.occurrence.immutableCopy())
                                }

                                is CounterpartChoice.New -> {
                                    choice
                                        .copy(
                                            containing = choice.containing.freeze(),
                                            prepared =
                                                choice.prepared
                                                    .copy(
                                                        content = choice.prepared.content.immutableCopy(),
                                                        findings =
                                                            choice.prepared.findings.immutableListCopy {
                                                                it.copy(relativePath = it.relativePath?.immutableCopy())
                                                            },
                                                    ),
                                        )
                                }
                            },
                    ),
            )
        }

        is EditIntent.DisconnectRelation -> {
            copy(occurrence = occurrence.copy(location = occurrence.location.freeze()))
        }

        is EditIntent.Retag -> {
            copy(at = at.freeze(), type = type.immutableCopy() as TypeUse.Named)
        }

        is EditIntent.ConfigureResource -> {
            copy(configuration = configuration.immutableCopy())
        }
    }

private fun ValuePath.atOrBelow(other: ValuePath) =
    segments.size >= other.segments.size && segments.take(other.segments.size) == other.segments

private fun ValuePath.item(id: ItemId) = ValuePath(segments + PathSegment.Item(id))

private fun ValueLocation.item(id: ItemId) = copy(path = path.item(id))

private fun ValueLocation.field(name: String) = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.mapKey() = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue() = copy(path = ValuePath(path.segments + PathSegment.MapValue))
