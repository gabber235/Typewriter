package com.typewritermc.loader.standalone.shell

import org.jline.reader.LineReader
import org.jline.reader.LineReaderBuilder
import org.jline.terminal.impl.DumbTerminal
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

/** A real JLine dumb terminal that reads [input] and records everything printed to it. */
internal class ShellTerminal(
    input: String = "",
) : AutoCloseable {
    private val output = ByteArrayOutputStream()
    private val terminal = DumbTerminal(ByteArrayInputStream(input.encodeToByteArray()), output)
    val reader: LineReader = LineReaderBuilder.builder().terminal(terminal).build()

    /** Everything the terminal printed so far, with platform line endings normalized. */
    val printed: String
        get() {
            terminal.flush()
            return output.toString(Charsets.UTF_8).replace("\r\n", "\n")
        }

    override fun close() {
        terminal.close()
    }
}
