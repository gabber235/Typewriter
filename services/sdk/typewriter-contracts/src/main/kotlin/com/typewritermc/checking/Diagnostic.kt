package com.typewritermc.checking

import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.types.skir.RuleOriginSerializer
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.RuleOrigin

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
    @Serializable(with = RuleOriginSerializer::class)
    val origin: RuleOrigin,
    val code: String,
    val message: String,
    val severity: DiagnosticSeverity,
    val primary: ValueLocation?,
    val related: List<ValueLocation>,
)
