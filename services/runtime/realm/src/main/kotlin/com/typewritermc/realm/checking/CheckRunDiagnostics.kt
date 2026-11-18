package com.typewritermc.realm.checking

import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.atomic.AtomicInteger

/**
 * Numbers the diagnostics of one run in the order it reports them, under a prefix that names what ran. So ids repeat
 * across equal runs, which keeps an equal rerun's set equal, and stay unique across instances.
 */
internal class CheckRunDiagnostics private constructor(
    private val prefix: String,
) {
    private val next = AtomicInteger()

    fun next(): DiagnosticId = DiagnosticId(value = "$prefix:${next.getAndIncrement()}")

    /** An error diagnostic with the next id. */
    fun error(
        origin: RuleOrigin,
        code: String,
        message: String,
        at: ValueLocation?,
        related: List<ValueLocation> = emptyList(),
    ): Diagnostic =
        Diagnostic(
            id = next(),
            origin = origin,
            code = code,
            message = message,
            severity = DiagnosticSeverity.ERROR,
            primary = at,
            related = related,
        )

    companion object {
        /** The diagnostics of one check instance's run. */
        fun of(instance: CheckInstanceId): CheckRunDiagnostics =
            CheckRunDiagnostics("check:${CheckInstanceId.serializer.toJsonCode(instance)}")

        /**
         * The diagnostics a rule's discovery reports outside any instance's run, under [part]. Registration does not
         * number its diagnostic here: it has one fixed id per rule.
         */
        fun of(
            rule: RuleId,
            part: String,
        ): CheckRunDiagnostics = CheckRunDiagnostics("$part:${RuleId.serializer.toJsonCode(rule)}")
    }
}
