@file:Suppress("ForbiddenImport")

package com.typewritermc.loader.standalone.shell

import com.typewritermc.services.libs.telemetry.console.ConsoleLogRecord
import de.infix.testBalloon.framework.core.testSuite
import io.mockk.mockk
import io.mockk.verify
import io.opentelemetry.api.logs.Severity
import org.jline.reader.LineReader
import java.time.Instant

val LoaderConsoleLogOutputTest by testSuite {
    test("prints above an attached interactive prompt") {
        val reader = mockk<LineReader>(relaxed = true)
        val output = LoaderConsoleLogOutput()

        output.attach(reader)
        output.write(ConsoleLogRecord(Instant.EPOCH, Severity.INFO, "Realm is ready"))

        verify(exactly = 1) { reader.printAbove("1970-01-01T00:00:00Z INFO  Realm is ready") }
    }

    test("stops using the prompt after detachment") {
        val reader = mockk<LineReader>(relaxed = true)
        val output = LoaderConsoleLogOutput()

        output.attach(reader)
        output.detach()
        output.write(ConsoleLogRecord(Instant.EPOCH, Severity.INFO, "Realm stopped"))

        verify(exactly = 0) { reader.printAbove(any<String>()) }
    }
}
