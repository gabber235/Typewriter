@file:Suppress("ForbiddenMethodCall")

package com.typewritermc.loader.standalone.shell

import com.typewritermc.loader.LoaderLogOutput
import org.jline.reader.LineReader

/**
 * Routes formatted telemetry to the active JLine prompt through printAbove. Before attachment and after
 * detachment, writes to standard error so startup and shutdown records remain visible. The shell owns the reader
 * and must detach it before closing the terminal.
 */
class LoaderConsoleLogOutput : LoaderLogOutput {
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
