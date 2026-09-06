@file:Suppress("ForbiddenImport")

package com.typewritermc.loader.paper

import com.typewritermc.loader.LoaderLogOutput
import com.typewritermc.services.libs.telemetry.console.ConsoleLogRecord
import io.opentelemetry.api.logs.Severity
import java.util.logging.Level
import java.util.logging.Logger

/**
 * Bridges loader telemetry into the Paper plugin logger while preserving severity. Sends only the record message
 * because Paper owns timestamp and level formatting. The borrowed logger is neither configured nor closed by this
 * adapter.
 */
internal class PaperLogOutput(
    private val logger: Logger,
) : LoaderLogOutput {
    override fun write(record: ConsoleLogRecord) {
        logger.log(record.severity.toJavaLevel(), record.message)
    }
}

private fun Severity.toJavaLevel(): Level =
    when {
        severityNumber >= Severity.ERROR.severityNumber -> Level.SEVERE
        severityNumber >= Severity.WARN.severityNumber -> Level.WARNING
        severityNumber >= Severity.INFO.severityNumber -> Level.INFO
        severityNumber >= Severity.DEBUG.severityNumber -> Level.FINE
        severityNumber >= Severity.TRACE.severityNumber -> Level.FINEST
        else -> Level.INFO
    }
