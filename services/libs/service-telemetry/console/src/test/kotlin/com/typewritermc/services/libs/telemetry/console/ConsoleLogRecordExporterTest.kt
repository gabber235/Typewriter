@file:Suppress("ForbiddenImport")

package com.typewritermc.services.libs.telemetry.console

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.logs.Severity
import io.opentelemetry.sdk.testing.logs.TestLogRecordData
import java.time.Instant

val ConsoleLogRecordExporterTest by testSuite {
    test("formats informational record as one plain line") {
        val exporter = ConsoleLogRecordExporter(ConsoleLogOutput {})
        val record =
            TestLogRecordData
                .builder()
                .setTimestamp(Instant.parse("2026-08-04T06:33:12Z"))
                .setSeverity(Severity.INFO)
                .setBody("Realm is ready")
                .build()

        exporter.format(record) shouldBe "2026-08-04T06:33:12Z INFO  Realm is ready"
    }

    test("adds event reference to warning") {
        val exporter = ConsoleLogRecordExporter(ConsoleLogOutput {})
        val record =
            TestLogRecordData
                .builder()
                .setTimestamp(Instant.parse("2026-08-04T06:33:12Z"))
                .setSeverity(Severity.WARN)
                .setEventName("registrar.state.changed")
                .setBody("Messaging is unavailable")
                .build()

        exporter.format(record) shouldBe
            "2026-08-04T06:33:12Z WARN  Messaging is unavailable [registrar.state.changed]"
    }

    test("adds an exception slug to an error once") {
        val exporter = ConsoleLogRecordExporter(ConsoleLogOutput {})
        val record =
            TestLogRecordData
                .builder()
                .setTimestamp(Instant.parse("2026-08-04T06:33:12Z"))
                .setSeverity(Severity.ERROR)
                .setBody("Realm startup failed")
                .setAttributes(Attributes.of(AttributeKey.stringKey("exception.slug"), "realm-start-failed"))
                .build()

        exporter.format(record) shouldBe
            "2026-08-04T06:33:12Z ERROR Realm startup failed [realm-start-failed]"
    }

    test("output failure is reported as exporter failure") {
        val exporter = ConsoleLogRecordExporter(ConsoleLogOutput { error("console unavailable") })
        val record = TestLogRecordData.builder().setBody("message").build()

        exporter.export(listOf(record)).isSuccess shouldBe false
    }
}
