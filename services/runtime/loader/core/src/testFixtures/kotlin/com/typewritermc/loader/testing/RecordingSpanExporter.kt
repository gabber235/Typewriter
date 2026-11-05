package com.typewritermc.loader.testing

import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.SpanExporter
import java.util.concurrent.CopyOnWriteArrayList

/** Keeps exported spans after shutdown, unlike the SDK's in memory exporter, which clears them. */
class RecordingSpanExporter : SpanExporter {
    val exported = CopyOnWriteArrayList<SpanData>()

    @Volatile
    var shutDown = false
        private set

    override fun export(spans: Collection<SpanData>): CompletableResultCode {
        exported += spans
        return CompletableResultCode.ofSuccess()
    }

    override fun flush(): CompletableResultCode = CompletableResultCode.ofSuccess()

    override fun shutdown(): CompletableResultCode {
        shutDown = true
        return CompletableResultCode.ofSuccess()
    }
}
