package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

/** Facts from the original read view that must still hold when an edit is accepted. */
@Serializable
sealed interface EditExpectation {
    /** A missing value is distinct from the authored [DataValue.Null] variant. */
    @Serializable
    data class Value(
        val at: ValueLocation,
        val expected: DataValue?,
    ) : EditExpectation

    @Serializable
    data class Resource(
        val id: ResourceId,
        val expected: AuthoringRecord?,
    ) : EditExpectation

    @Serializable
    data class ResourceExists(
        val id: ResourceId,
        val expected: Boolean,
    ) : EditExpectation

    @Serializable
    data class Configuration(
        val at: ValueLocation,
        val expected: TypeSelection?,
    ) : EditExpectation

    @Serializable
    data class ResourceIds(
        val expected: Set<ResourceId>,
    ) : EditExpectation

    @Serializable
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
