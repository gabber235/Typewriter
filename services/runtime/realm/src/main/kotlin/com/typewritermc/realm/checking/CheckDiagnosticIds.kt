package com.typewritermc.realm.checking

import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.atomic.AtomicLong

/**
 * Draws the `check:N` diagnostic ids of one [RealmCheckRuntime].
 *
 * Catalog collection, subject discovery, and evaluation share this sequence, so every id stays unique within
 * the runtime.
 */
internal class CheckDiagnosticIds {
    private val next = AtomicLong()

    fun next(): DiagnosticId = DiagnosticId(value = "check:${next.getAndIncrement()}")

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
}
