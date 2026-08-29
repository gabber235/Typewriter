package com.typewritermc.services.libs.telemetry.console

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import java.time.Instant
import java.util.logging.Level
import java.util.logging.LogRecord
import java.util.logging.Logger

val OpenTelemetrySdkDiagnosticsTest by testSuite {
    test("formats SDK warning as one concise line") {
        val lines = mutableListOf<String>()
        val handler = OpenTelemetrySdkDiagnosticHandler(lines::add)
        val record =
            LogRecord(Level.WARNING, "Failed to export logs.\nServer rejected the request.").apply {
                instant = Instant.parse("2026-08-04T08:55:46Z")
            }

        handler.publish(record)

        lines shouldContainExactly
            listOf("2026-08-04T08:55:46Z WARN  Failed to export logs. Server rejected the request. [otel.sdk]")
    }

    test("ignores diagnostics below warning") {
        val lines = mutableListOf<String>()
        val handler = OpenTelemetrySdkDiagnosticHandler(lines::add)

        handler.publish(LogRecord(Level.INFO, "connection opened"))

        lines.isEmpty() shouldBe true
    }

    test("console failure does not escape the diagnostic handler") {
        val handler = OpenTelemetrySdkDiagnosticHandler { error("console unavailable") }

        handler.publish(LogRecord(Level.SEVERE, "export failed"))
    }

    test("installation captures OpenTelemetry child loggers and restores configuration") {
        val logger = Logger.getLogger("io.opentelemetry.test.${System.nanoTime()}")
        val parent = Logger.getLogger("io.opentelemetry")
        val previousLevel = parent.level
        val previousUseParentHandlers = parent.useParentHandlers
        val previousHandlers = parent.handlers.toList()
        val lines = mutableListOf<String>()

        installOpenTelemetrySdkDiagnostics(lines::add).use {
            logger.warning("export failed")
        }

        lines.single().endsWith("WARN  export failed [otel.sdk]") shouldBe true
        parent.level shouldBe previousLevel
        parent.useParentHandlers shouldBe previousUseParentHandlers
        parent.handlers.toList() shouldContainExactly previousHandlers
    }
}
