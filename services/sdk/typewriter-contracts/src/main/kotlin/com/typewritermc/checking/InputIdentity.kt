package com.typewritermc.checking

import com.typewritermc.authoring.SelectionId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@JvmInline @Serializable
value class SnapshotId(
    val value: String,
)

@JvmInline @Serializable
value class CatalogGeneration(
    val value: String,
)

@JvmInline @Serializable
value class InputToken(
    val value: String,
)

@Serializable
sealed interface InputIdentity {
    @Serializable
    @SerialName("value")
    data class Value(
        val at: ValueLocation,
    ) : InputIdentity

    @Serializable
    @SerialName("existence")
    data class Existence(
        val resource: ResourceId,
    ) : InputIdentity

    @Serializable
    @SerialName("form")
    data class Form(
        val at: ValueLocation,
    ) : InputIdentity

    @Serializable
    @SerialName("membership")
    data class Membership(
        val at: ValueLocation,
    ) : InputIdentity

    @Serializable
    @SerialName("order")
    data class Order(
        val at: ValueLocation,
    ) : InputIdentity

    @Serializable
    @SerialName("selection")
    data class Selection(
        val query: SelectionId,
    ) : InputIdentity

    @Serializable
    @SerialName("incoming")
    data class Incoming(
        val resource: ResourceId,
        val relation: RelationId?,
    ) : InputIdentity

    @Serializable
    @SerialName("catalog")
    data class Catalog(
        val generation: CatalogGeneration,
    ) : InputIdentity
}

@Serializable
data class InputObservation(
    val identity: InputIdentity,
    val token: InputToken,
)
