package com.typewritermc.checking

import com.typewritermc.authoring.ValueLocation
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface CheckOutcome {
    @Serializable
    @SerialName("finished")
    data object Finished : CheckOutcome

    @Serializable
    @SerialName("needs_input")
    data class NeedsInput(
        val locations: List<ValueLocation>,
    ) : CheckOutcome

    @Serializable
    @SerialName("failed")
    data class Failed(
        val diagnostics: List<Diagnostic>,
    ) : CheckOutcome

    @Serializable
    @SerialName("incomplete")
    data class Incomplete(
        val reason: String,
    ) : CheckOutcome
}
