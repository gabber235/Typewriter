package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId

/** Derives mandatory guards independently of client supplied expectations. */
internal fun CurrentAuthoringValues.requiredExpectations(
    edit: PreparedEdit,
    resources: Map<ResourceId, AuthoringRecord>,
    relations: Set<RelationId>,
    plan: AuthoringMutationPlan? = null,
): List<EditExpectation> {
    val required = linkedSetOf<EditExpectation>()

    fun expectValue(at: ValueLocation) {
        required += EditExpectation.Value(at, value(at))
    }

    fun expectResource(id: ResourceId) {
        required += EditExpectation.Resource(id, resource(id))
    }

    fun path(at: ValueLocation) {
        required += EditExpectation.ResourceExists(at.resource, resource(at.resource) != null)
        for (length in 0..at.path.segments.size) {
            val parent = at.copy(path = ValuePath(at.path.segments.take(length)))
            required += EditExpectation.Configuration(parent, configuration(parent))
        }
    }

    fun links(id: ResourceId) {
        relations.forEach { relation ->
            required += EditExpectation.Links(id, relation, TraversalDirection.Both, links(id, relation, TraversalDirection.Both))
        }
    }

    val occurrences = ResourceValueMapper.discover(resources).associateBy { it.id }
    edit.intents.forEach { intent ->
        when (intent) {
            is EditIntent.CreateResource -> {
                required += EditExpectation.ResourceExists(intent.id, resource(intent.id) != null)
            }

            is EditIntent.DeleteResource -> {
                expectResource(intent.id)
                links(intent.id)
            }

            is EditIntent.SetValue -> {
                path(intent.at)
                expectValue(intent.at)
            }

            is EditIntent.Insert -> {
                path(intent.at)
                expectValue(intent.at)
            }

            is EditIntent.Remove -> {
                path(intent.at)
                expectValue(intent.at)
            }

            is EditIntent.Move -> {
                path(intent.at)
                expectValue(intent.at)
            }

            is EditIntent.ConnectRelation -> {
                path(intent.intent.source.id.location)
                expectValue(intent.intent.source.id.location)
                path(ValueLocation(intent.intent.target, ValuePath()))
                links(intent.intent.source.source)
                links(intent.intent.target)
                when (val counterpart = intent.intent.counterpart) {
                    null -> {
                        Unit
                    }

                    is CounterpartChoice.Existing -> {
                        path(counterpart.occurrence.id.location)
                        expectValue(counterpart.occurrence.id.location)
                    }

                    is CounterpartChoice.New -> {
                        path(counterpart.containing)
                        expectValue(counterpart.containing)
                    }
                }
            }

            is EditIntent.DisconnectRelation -> {
                path(intent.occurrence.location)
                expectValue(intent.occurrence.location)
                links(intent.occurrence.location.resource)
                occurrences[intent.occurrence]?.target?.resource?.let(::links)
            }

            is EditIntent.Retag -> {
                path(intent.at)
                expectValue(intent.at)
                links(intent.at.resource)
            }

            is EditIntent.ConfigureResource -> {
                expectResource(intent.resource)
                links(intent.resource)
            }
        }
    }
    plan?.removedResources?.forEach {
        expectResource(it)
        links(it)
    }
    val delta = plan?.relations ?: RelationProjectionDelta(emptyList(), emptyList(), emptyList())
    (delta.removed + delta.created + delta.metadataChanged).forEach { edge ->
        links(edge.first)
        links(edge.second)
        listOfNotNull(
            edge.firstLocation?.let { ValueLocation(edge.first, it) },
            edge.secondLocation?.let { ValueLocation(edge.second, it) },
        ).forEach { at ->
            path(at)
            expectValue(at)
            val item = at.path.segments.indexOfLast { it is PathSegment.Item }
            if (item >= 0) expectValue(at.copy(path = ValuePath(at.path.segments.take(item))))
        }
    }
    return required.toList()
}

internal fun EditExpectation.sameFact(other: EditExpectation): Boolean =
    when (this) {
        is EditExpectation.Value -> {
            other is EditExpectation.Value && at == other.at
        }

        is EditExpectation.Resource -> {
            other is EditExpectation.Resource && id == other.id
        }

        is EditExpectation.ResourceExists -> {
            other is EditExpectation.ResourceExists && id == other.id
        }

        is EditExpectation.Configuration -> {
            other is EditExpectation.Configuration && at == other.at
        }

        is EditExpectation.ResourceIds -> {
            other is EditExpectation.ResourceIds
        }

        is EditExpectation.Links -> {
            other is EditExpectation.Links && resource == other.resource && contract == other.contract &&
                direction == other.direction
        }
    }
