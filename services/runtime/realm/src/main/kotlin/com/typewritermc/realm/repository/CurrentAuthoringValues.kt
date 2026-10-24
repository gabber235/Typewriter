package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.ExpectationConflict
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId

internal interface CurrentAuthoringValues {
    fun value(at: ValueLocation): DataValue?

    fun resource(id: ResourceId): AuthoringRecord?

    fun configuration(at: ValueLocation): TypeSelection? =
        if (at.path.segments.isEmpty()) {
            resource(at.resource)?.configuration
        } else {
            (value(at) as? DataValue.Named)?.actualType?.let(TypeSelection::Complete)
        }

    fun resourceIds(): Set<ResourceId>

    fun links(
        resource: ResourceId,
        contract: RelationId,
        direction: TraversalDirection,
    ): Set<LinkProjection>
}

internal class CapturedAuthoringValues(
    private val resources: Map<ResourceId, AuthoringRecord>,
    private val projections: Collection<LinkProjection>,
) : CurrentAuthoringValues {
    override fun value(at: ValueLocation): DataValue? = resources[at.resource]?.valueAt(at.path)

    override fun resource(id: ResourceId): AuthoringRecord? = resources[id]

    override fun resourceIds(): Set<ResourceId> = resources.keys

    override fun links(
        resource: ResourceId,
        contract: RelationId,
        direction: TraversalDirection,
    ): Set<LinkProjection> =
        projections.filterTo(linkedSetOf()) { projection ->
            projection.contract == contract &&
                when (direction) {
                    TraversalDirection.Forward -> projection.first == resource
                    TraversalDirection.Reverse -> projection.second == resource
                    TraversalDirection.Both -> projection.first == resource || projection.second == resource
                }
        }
}

internal fun CurrentAuthoringValues.actual(expected: EditExpectation): EditExpectation =
    when (expected) {
        is EditExpectation.Value -> expected.copy(expected = value(expected.at))
        is EditExpectation.Resource -> expected.copy(expected = resource(expected.id))
        is EditExpectation.ResourceExists -> expected.copy(expected = resource(expected.id) != null)
        is EditExpectation.Configuration -> expected.copy(expected = configuration(expected.at))
        is EditExpectation.ResourceIds -> expected.copy(expected = resourceIds())
        is EditExpectation.Links -> expected.copy(expected = links(expected.resource, expected.contract, expected.direction))
    }

internal fun CurrentAuthoringValues.conflicts(expectations: List<EditExpectation>): List<ExpectationConflict> =
    expectations.mapNotNull { expected ->
        val actual = actual(expected)
        if (actual == expected) null else ExpectationConflict(expected, actual)
    }
