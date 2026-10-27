package com.typewritermc.loader.paper.testing

import java.util.logging.Handler
import java.util.logging.LogRecord

/** A log handler that keeps every record it publishes, in order, so a test can check what a logger forwarded. */
class RecordingLogHandler : Handler() {
    /** Every record published to this handler, in publication order. */
    val records = mutableListOf<LogRecord>()

    override fun publish(record: LogRecord) {
        records.add(record)
    }

    override fun flush() = Unit

    override fun close() = Unit
}
