package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation

/** Facts from the original read view that must still hold when an edit is accepted. */
sealed interface EditExpectation {
    /** A missing value is distinct from the authored [DataValue.NULL] variant. */
    data class Value(
        val at: ValueLocation,
        val expected: DataValue?,
    ) : EditExpectation

    data class Resource(
        val id: ResourceId,
        val expected: AuthoringRecord?,
    ) : EditExpectation

    data class ResourceExists(
        val id: ResourceId,
        val expected: Boolean,
    ) : EditExpectation

    data class Configuration(
        val at: ValueLocation,
        val expected: TypeSelection?,
    ) : EditExpectation

    data class ResourceIds(
        val expected: Set<ResourceId>,
    ) : EditExpectation

    data class Links(
        val resource: ResourceId,
        val contract: RelationId,
        val direction: TraversalDirection,
        val expected: Set<LinkProjection>,
    ) : EditExpectation
}

data class ExpectationConflict(
    val expected: EditExpectation,
    val actual: EditExpectation,
)
