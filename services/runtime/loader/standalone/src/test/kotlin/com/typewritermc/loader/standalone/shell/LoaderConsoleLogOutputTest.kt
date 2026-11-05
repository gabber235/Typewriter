@file:Suppress("ForbiddenImport")

package com.typewritermc.loader.standalone.shell

import com.typewritermc.loader.standalone.shell.testing.ShellTerminal
import com.typewritermc.services.libs.telemetry.console.ConsoleLogRecord
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldNotContain
import io.opentelemetry.api.logs.Severity
import java.time.Instant

val LoaderConsoleLogOutputTest by testSuite {
    test("prints above an attached interactive prompt") {
        ShellTerminal().use { terminal ->
            val output = LoaderConsoleLogOutput()

            output.attach(terminal.reader)
            output.write(ConsoleLogRecord(Instant.EPOCH, Severity.INFO, "Realm is ready"))

            terminal.printed shouldBe "1970-01-01T00:00:00Z INFO  Realm is ready\n"
        }
    }

    test("stops using the prompt after detachment") {
        ShellTerminal().use { terminal ->
            val output = LoaderConsoleLogOutput()

            output.attach(terminal.reader)
            output.detach()
            output.write(ConsoleLogRecord(Instant.EPOCH, Severity.INFO, "Realm stopped"))

            terminal.printed shouldNotContain "Realm stopped"
        }
    }
}
