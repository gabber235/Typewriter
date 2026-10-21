package com.typewritermc.capability

import com.typewritermc.types.PresentationId
import com.typewritermc.types.TypeUse
import kotlinx.serialization.Serializable
import skirout.editor.v1.operation.OperationTargets

@JvmInline
@Serializable
value class CapabilityId(
    val value: String,
)

sealed interface RealmCapabilityDescriptor {
    val id: CapabilityId
    val requestType: TypeUse?

    data class Search(
        override val id: CapabilityId,
        override val requestType: TypeUse,
        val resultType: TypeUse,
    ) : RealmCapabilityDescriptor

    data class Computation(
        override val id: CapabilityId,
        override val requestType: TypeUse,
        val resultType: TypeUse,
    ) : RealmCapabilityDescriptor

    data class Command(
        override val id: CapabilityId,
        override val requestType: TypeUse,
    ) : RealmCapabilityDescriptor

    data class Authoring(
        override val id: CapabilityId,
        override val requestType: TypeUse?,
        val targets: OperationTargets,
        val inputPresentation: PresentationId? = null,
    ) : RealmCapabilityDescriptor {
        val hasInput: Boolean get() = requestType != null
    }
}
