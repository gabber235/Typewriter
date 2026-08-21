@file:Suppress("ForbiddenMethodCall")

package com.typewritermc.loader.standalone.shell

import com.typewritermc.services.libs.telemetry.console.ConsoleLogOutput
import org.jline.reader.LineReader

class LoaderConsoleLogOutput : ConsoleLogOutput {
    @Volatile
    private var reader: LineReader? = null

    fun attach(reader: LineReader) {
        this.reader = reader
    }

    fun detach() {
        reader = null
    }

    override fun write(line: String) {
        reader?.printAbove(line) ?: System.err.println(line)
    }
}
