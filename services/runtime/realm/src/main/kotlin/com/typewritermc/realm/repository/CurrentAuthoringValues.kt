package com.typewritermc.realm.repository

import com.typewritermc.authoring.links
import com.typewritermc.authoring.resourceIds
import com.typewritermc.types.actualType
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.ExpectationConflict
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation

internal interface CurrentAuthoringValues {
    fun value(at: ValueLocation): DataValue?

    fun resource(id: ResourceId): AuthoringRecord?

    fun configuration(at: ValueLocation): TypeSelection? =
        if (at.path.segments.isEmpty()) {
            resource(at.resource)?.configuration
        } else {
            (value(at) as? DataValue.NamedWrapper)?.actualType?.let(TypeSelection::CompleteWrapper)
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
                    TraversalDirection.FORWARD -> projection.first == resource
                    TraversalDirection.REVERSE -> projection.second == resource
                    TraversalDirection.BOTH -> projection.first == resource || projection.second == resource
                    else -> unknownVariant(direction)
                }
        }
}

internal fun CurrentAuthoringValues.actual(expected: EditExpectation): EditExpectation =
    when (expected) {
        is EditExpectation.ValueWrapper -> {
            EditExpectation.ValueWrapper(expected.value.copy(expected = value(expected.value.at)))
        }

        is EditExpectation.ResourceWrapper -> {
            EditExpectation.ResourceWrapper(expected.value.copy(expected = resource(expected.value.id)))
        }

        is EditExpectation.ResourceExistsWrapper -> {
            EditExpectation.ResourceExistsWrapper(expected.value.copy(expected = resource(expected.value.id) != null))
        }

        is EditExpectation.ConfigurationWrapper -> {
            EditExpectation.ConfigurationWrapper(expected.value.copy(expected = configuration(expected.value.at)))
        }

        is EditExpectation.ResourceIdsWrapper -> {
            EditExpectation.resourceIds(resourceIds())
        }

        is EditExpectation.LinksWrapper -> {
            EditExpectation.links(
                expected.value.resource,
                expected.value.contract,
                expected.value.direction,
                links(expected.value.resource, expected.value.contract, expected.value.direction),
            )
        }

        else -> {
            unknownVariant(expected)
        }
    }

internal fun CurrentAuthoringValues.conflicts(expectations: List<EditExpectation>): List<ExpectationConflict> =
    expectations.mapNotNull { expected ->
        val actual = actual(expected)
        if (actual == expected) null else ExpectationConflict(expected = expected, actual = actual)
    }
