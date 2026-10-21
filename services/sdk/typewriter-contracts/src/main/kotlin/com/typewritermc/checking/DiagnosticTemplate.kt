package com.typewritermc.checking

import com.typewritermc.configuration.RelativeFieldPattern
import skirout.editor.v1.diagnostic.DiagnosticSeverity

data class DiagnosticTemplate(
    val code: String,
    val message: String,
    val severity: DiagnosticSeverity,
    val targets: List<RelativeFieldPattern>,
)
