package com.typewritermc.realm.shell

import ch.qos.logback.classic.spi.ILoggingEvent
import ch.qos.logback.core.AppenderBase
import ch.qos.logback.core.ConsoleAppender
import org.jline.reader.LineReader
import java.nio.charset.StandardCharsets

class RealmShellLogbackAppender(
    private val delegate: ConsoleAppender<ILoggingEvent>,
) : AppenderBase<ILoggingEvent>() {

    @Volatile
    private var lineReader: LineReader? = null

    fun attach(reader: LineReader) {
        this.lineReader = reader
    }

    fun detach() {
        this.lineReader = null
    }

    override fun append(event: ILoggingEvent) {
        val reader = lineReader ?: return
        val encoder = delegate.encoder ?: return

        val bytes = encoder.encode(event)
        val message = String(bytes, StandardCharsets.UTF_8).trimEnd()

        reader.printAbove(message)
    }
}
