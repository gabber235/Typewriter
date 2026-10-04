package com.typewritermc.checking

import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RuleOrigin
import kotlinx.serialization.Serializable

@Serializable
enum class DiagnosticSeverity {
    Info,
    Warning,
    Error,
}

@Serializable
data class DiagnosticTemplate(
    val code: String,
    val message: String,
    val severity: DiagnosticSeverity,
    val targets: List<RelativeFieldPattern>,
)

@Serializable
data class Diagnostic(
    val id: DiagnosticId,
    val origin: RuleOrigin,
    val code: String,
    val message: String,
    val severity: DiagnosticSeverity,
    val primary: ValueLocation?,
    val related: List<ValueLocation>,
)

@Serializable
sealed interface FindingStatus {
    @Serializable
    data object Current : FindingStatus

    @Serializable
    data object Outdated : FindingStatus
}
