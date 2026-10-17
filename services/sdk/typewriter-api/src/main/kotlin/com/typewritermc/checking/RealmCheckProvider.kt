package com.typewritermc.checking

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.ValueLocation

interface RealmCheckProvider {
    fun RealmChecks.register()
}

interface RealmChecks {
    fun <D> each(
        type: DraftType<D>,
        check: CheckContext.(D) -> Unit,
    )

    fun realm(check: CheckContext.() -> Unit)
}

class CheckContext private constructor(
    val reads: AuthoredReads,
    val diagnostics: DiagnosticReporter,
    private val diagnosticFactory: (String, ValueLocation, List<ValueLocation>) -> Diagnostic,
) : AuthoredReads by reads {
    companion object {
        fun create(
            reads: AuthoredReads,
            diagnostics: DiagnosticReporter,
            diagnosticFactory: (String, ValueLocation, List<ValueLocation>) -> Diagnostic,
        ): CheckContext = CheckContext(reads, diagnostics, diagnosticFactory)
    }

    internal fun report(
        message: String,
        at: ValueLocation,
        related: List<ValueLocation>,
    ) {
        diagnostics.report(diagnosticFactory(message, at, related))
    }
}
