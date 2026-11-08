package com.typewritermc.realm.authoring

import com.typewritermc.authoring.links
import com.typewritermc.authoring.resourceIds
import com.typewritermc.checking.InputIdentity
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
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

internal interface CurrentAuthoringValues {
    fun value(at: ValueLocation): DataValue?

    fun resource(id: ResourceId): AuthoringRecord?

    fun configuration(at: ValueLocation): TypeSelection? =
        if (at.path.segments.isEmpty()) {
            resource(at.resource)?.configuration
        } else {
            (value(at) as? DataValue.NamedWrapper)?.actualType?.let(TypeSelection::CompleteWrapper)
        }

    /** The types [resource] declares; empty when it declares none or does not exist. */
    fun types(resource: ResourceId): List<TypeDefinition> = resource(resource)?.types.orEmpty()

    fun resourceIds(): Set<ResourceId>

    fun links(
        resource: ResourceId,
        contract: RelationId,
        direction: TraversalDirection,
    ): Set<LinkProjection>

    /** What [name] means where the formula at [at] looks it up. */
    fun scope(
        at: ValueLocation,
        name: String,
    ): List<ResourceId>
}

/**
 * Values of one view. Links are read per node from [projectionsAt], so reading one node's links judges only that node;
 * what a name means comes from [scopes], which only the realm's graph can answer.
 */
internal class CapturedAuthoringValues(
    private val resources: Map<ResourceId, AuthoringRecord>,
    private val scopes: (ValueLocation, String) -> List<ResourceId> = { _, _ ->
        throw IllegalStateException("These values cannot judge what a name means.")
    },
    private val projectionsAt: (ResourceId) -> Collection<LinkProjection>,
) : CurrentAuthoringValues {
    override fun value(at: ValueLocation): DataValue? = resources[at.resource]?.valueAt(at.path)

    override fun resource(id: ResourceId): AuthoringRecord? = resources[id]

    override fun resourceIds(): Set<ResourceId> = resources.keys

    override fun scope(
        at: ValueLocation,
        name: String,
    ): List<ResourceId> = scopes(at, name)

    override fun links(
        resource: ResourceId,
        contract: RelationId,
        direction: TraversalDirection,
    ): Set<LinkProjection> =
        projectionsAt(resource).filterTo(linkedSetOf()) { projection ->
            projection.contract == contract &&
                when (direction) {
                    TraversalDirection.FORWARD -> projection.first == resource
                    TraversalDirection.REVERSE -> projection.second == resource
                    TraversalDirection.BOTH -> projection.first == resource || projection.second == resource
                    else -> unknownVariant(direction)
                }
        }
}

/** The commit guard expectations a read of [identity] stands for in this view. */
internal fun AuthoringView.expectations(identity: InputIdentity): List<EditExpectation> =
    when (identity) {
        is InputIdentity.Value, is InputIdentity.Membership, is InputIdentity.Order -> {
            val at = identity.locationOf()
            listOf(EditExpectation.createValue(at = at, expected = values.value(at)))
        }

        is InputIdentity.Form -> {
            listOf(EditExpectation.createConfiguration(at = identity.at, expected = values.configuration(identity.at)))
        }

        is InputIdentity.Existence -> {
            listOf(EditExpectation.createResourceExists(id = identity.resource, expected = values.resource(identity.resource) != null))
        }

        is InputIdentity.Resource -> {
            listOf(EditExpectation.createResource(id = identity.resource, expected = values.resource(identity.resource)))
        }

        is InputIdentity.Selection -> {
            listOf(EditExpectation.resourceIds(values.resourceIds()))
        }

        is InputIdentity.Incoming -> {
            catalog.relations.filter { identity.relation == null || it.id == identity.relation }.map { contract ->
                EditExpectation.links(
                    identity.resource,
                    contract.id,
                    TraversalDirection.BOTH,
                    values.links(identity.resource, contract.id, TraversalDirection.BOTH),
                )
            }
        }

        is InputIdentity.Types -> {
            listOf(EditExpectation.createTypes(resource = identity.resource, expected = values.types(identity.resource)))
        }

        is InputIdentity.Catalog -> {
            emptyList()
        }
    }

private fun InputIdentity.locationOf(): ValueLocation =
    when (this) {
        is InputIdentity.Value -> at
        is InputIdentity.Membership -> at
        is InputIdentity.Order -> at
        else -> error("$this has no value location.")
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

        is EditExpectation.TypesWrapper -> {
            EditExpectation.createTypes(resource = expected.value.resource, expected = types(expected.value.resource))
        }

        is EditExpectation.ScopeWrapper -> {
            EditExpectation.ScopeWrapper(expected.value.copy(expected = scope(expected.value.at, expected.value.name)))
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
