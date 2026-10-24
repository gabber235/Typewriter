package com.typewritermc.realm.edit

import com.typewritermc.authoring.links
import com.typewritermc.authoring.of
import com.typewritermc.realm.authoring.CurrentAuthoringValues
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** Derives mandatory guards independently of client supplied expectations. */
internal fun CurrentAuthoringValues.requiredExpectations(
    edit: PreparedEdit,
    resources: Map<ResourceId, AuthoringRecord>,
    relations: Set<RelationId>,
    plan: AuthoringMutationPlan? = null,
): List<EditExpectation> {
    val required = linkedSetOf<EditExpectation>()

    fun expectValue(at: ValueLocation) {
        required += EditExpectation.createValue(at = at, expected = value(at))
    }

    fun expectResource(id: ResourceId) {
        required += EditExpectation.createResource(id = id, expected = resource(id))
    }

    fun path(at: ValueLocation) {
        required += EditExpectation.createResourceExists(id = at.resource, expected = resource(at.resource) != null)
        for (length in 0..at.path.segments.size) {
            val parent = at.copy(path = ValuePath(segments = at.path.segments.take(length)))
            required += EditExpectation.createConfiguration(at = parent, expected = configuration(parent))
        }
    }

    fun links(id: ResourceId) {
        relations.forEach { relation ->
            required += EditExpectation.links(id, relation, TraversalDirection.BOTH, links(id, relation, TraversalDirection.BOTH))
        }
    }

    val occurrences = ResourceValueMapper.discover(resources).associateBy { it.id }
    edit.intents.forEach { intent ->
        when (intent) {
            is EditIntent.CreateResourceWrapper -> {
                required += EditExpectation.createResourceExists(id = intent.value.id, expected = resource(intent.value.id) != null)
            }

            is EditIntent.DeleteResourceWrapper -> {
                expectResource(intent.value.id)
                links(intent.value.id)
            }

            is EditIntent.SetValueWrapper -> {
                path(intent.value.at)
                expectValue(intent.value.at)
            }

            is EditIntent.InsertWrapper -> {
                path(intent.value.at)
                expectValue(intent.value.at)
            }

            is EditIntent.RemoveWrapper -> {
                path(intent.value.at)
                expectValue(intent.value.at)
            }

            is EditIntent.MoveWrapper -> {
                path(intent.value.at)
                expectValue(intent.value.at)
            }

            is EditIntent.ConnectRelationWrapper -> {
                path(intent.value.source.id.location)
                expectValue(intent.value.source.id.location)
                path(ValueLocation.of(intent.value.target))
                links(
                    intent.value.source.source,
                )
                links(intent.value.target)
                when (val counterpart = intent.value.counterpart) {
                    null -> {
                        Unit
                    }

                    is CounterpartChoice.ExistingWrapper -> {
                        path(counterpart.value.id.location)
                        expectValue(counterpart.value.id.location)
                    }

                    is CounterpartChoice.NewWrapper -> {
                        path(counterpart.value.containing)
                        expectValue(counterpart.value.containing)
                    }

                    else -> {
                        unknownVariant(counterpart)
                    }
                }
            }

            is EditIntent.DisconnectRelationWrapper -> {
                path(intent.value.location)
                expectValue(intent.value.location)
                links(
                    intent.value.location.resource,
                )
                occurrences[intent.value]
                    ?.target
                    ?.resource

                    ?.let(::links)
            }

            is EditIntent.RetagWrapper -> {
                path(intent.value.at)
                expectValue(intent.value.at)
                links(intent.value.at.resource)
            }

            is EditIntent.ConfigureResourceWrapper -> {
                expectResource(intent.value.resource)
                links(intent.value.resource)
            }

            else -> {
                unknownVariant(intent)
            }
        }
    }
    plan?.removedResources?.forEach {
        expectResource(it)
        links(it)
    }
    val delta = plan?.relations ?: RelationProjectionDelta(removals = emptyList(), created = emptyList(), metadataChanged = emptyList())
    (delta.removals + delta.created + delta.metadataChanged).forEach { edge ->
        links(edge.first)
        links(edge.second)
        listOfNotNull(
            edge.firstLocation?.let { ValueLocation.of(edge.first, it) },
            edge.secondLocation?.let { ValueLocation.of(edge.second, it) },
        ).forEach { at ->
            path(at)
            expectValue(at)
            val item = at.path.segments.indexOfLast { it is PathSegment.ItemWrapper }
            if (item >= 0) expectValue(at.copy(path = ValuePath(segments = at.path.segments.take(item))))
        }
    }
    return required.toList()
}

internal fun EditExpectation.sameFact(other: EditExpectation): Boolean =
    when (this) {
        is EditExpectation.ValueWrapper -> {
            other is EditExpectation.ValueWrapper && value.at == other.value.at
        }

        is EditExpectation.ResourceWrapper -> {
            other is EditExpectation.ResourceWrapper && value.id == other.value.id
        }

        is EditExpectation.ResourceExistsWrapper -> {
            other is EditExpectation.ResourceExistsWrapper && value.id == other.value.id
        }

        is EditExpectation.ConfigurationWrapper -> {
            other is EditExpectation.ConfigurationWrapper && value.at == other.value.at
        }

        is EditExpectation.ResourceIdsWrapper -> {
            other is EditExpectation.ResourceIdsWrapper
        }

        is EditExpectation.LinksWrapper -> {
            other is EditExpectation.LinksWrapper && value.resource == other.value.resource && value.contract == other.value.contract &&
                value.direction == other.value.direction
        }

        else -> {
            unknownVariant(this)
        }
    }
