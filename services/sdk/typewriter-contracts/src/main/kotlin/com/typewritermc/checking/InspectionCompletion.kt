package com.typewritermc.checking

import com.typewritermc.types.ResourceId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ValueLocation

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

data class UndecidedCandidate(
    val resource: ResourceId,
    val inputs: List<ValueLocation>,
)
