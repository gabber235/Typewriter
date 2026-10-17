package com.typewritermc.checking

import com.typewritermc.authoring.ValueLocation
import com.typewritermc.types.ResourceId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface InspectionCompletion {
    @Serializable
    @SerialName("complete")
    data object Complete : InspectionCompletion

    @Serializable
    @SerialName("interrupted")
    data class Interrupted(
        val reason: String,
    ) : InspectionCompletion
}

@Serializable
data class UndecidedCandidate(
    val resource: ResourceId,
    val inputs: List<ValueLocation>,
)
