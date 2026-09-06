@file:Suppress("ForbiddenImport")

package com.typewritermc.loader.paper

import com.typewritermc.services.libs.telemetry.console.ConsoleLogRecord
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.logs.Severity
import java.time.Instant
import java.util.logging.Handler
import java.util.logging.Level
import java.util.logging.LogRecord
import java.util.logging.Logger

val PaperLogOutputTest by testSuite {
    test("forwards messages without prefixes and preserves severity families") {
        val records = mutableListOf<LogRecord>()
        val logger =
            Logger.getAnonymousLogger().apply {
                useParentHandlers = false
                level = Level.ALL
                addHandler(
                    object : Handler() {
                        override fun publish(record: LogRecord) {
                            records.add(record)
                        }

                        override fun flush() = Unit

                        override fun close() = Unit
                    },
                )
            }
        val output = PaperLogOutput(logger)
        val levels =
            listOf(
                Severity.UNDEFINED_SEVERITY_NUMBER to Level.INFO,
                Severity.TRACE to Level.FINEST,
                Severity.TRACE4 to Level.FINEST,
                Severity.DEBUG to Level.FINE,
                Severity.DEBUG4 to Level.FINE,
                Severity.INFO to Level.INFO,
                Severity.INFO4 to Level.INFO,
                Severity.WARN to Level.WARNING,
                Severity.WARN4 to Level.WARNING,
                Severity.ERROR to Level.SEVERE,
                Severity.ERROR4 to Level.SEVERE,
                Severity.FATAL to Level.SEVERE,
                Severity.FATAL4 to Level.SEVERE,
            )

        levels.forEach { (severity, _) ->
            output.write(ConsoleLogRecord(Instant.EPOCH, severity, "Realm failed [realm.failure]"))
        }

        records.map { it.level } shouldBe levels.map { it.second }
        records.map { it.message } shouldBe levels.map { "Realm failed [realm.failure]" }
    }
}
