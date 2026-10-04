package com.typewritermc.capability

import com.typewritermc.types.TypeUse
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class CapabilityId(
    val value: String,
)

@Serializable
sealed interface RealmCapabilityDescriptor {
    val id: CapabilityId
    val requestType: TypeUse

    @Serializable
    @SerialName("search")
    data class Search(
        override val id: CapabilityId,
        override val requestType: TypeUse,
        val resultType: TypeUse,
    ) : RealmCapabilityDescriptor

    @Serializable
    @SerialName("computation")
    data class Computation(
        override val id: CapabilityId,
        override val requestType: TypeUse,
        val resultType: TypeUse,
    ) : RealmCapabilityDescriptor

    @Serializable
    @SerialName("command")
    data class Command(
        override val id: CapabilityId,
        override val requestType: TypeUse,
    ) : RealmCapabilityDescriptor
}
