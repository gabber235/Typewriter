@file:Suppress("ForbiddenMethodCall")

package com.typewritermc.realm.shell

import com.typewritermc.services.libs.telemetry.console.ConsoleLogOutput
import org.jline.reader.LineReader

class RealmConsoleLogOutput : ConsoleLogOutput {
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
