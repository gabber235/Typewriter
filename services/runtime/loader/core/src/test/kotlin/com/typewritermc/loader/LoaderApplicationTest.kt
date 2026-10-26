package com.typewritermc.loader

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor
import io.opentelemetry.sdk.trace.export.SpanExporter
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.TimeUnit

val LoaderApplicationTest by testSuite {
    test("closing the loader exports pending spans") {
        val exporter = RecordingSpanExporter()
        // The batch never exports on its own schedule, so the span stays pending until the loader closes.
        val processor = BatchSpanProcessor.builder(exporter).setScheduleDelay(1, TimeUnit.HOURS).build()
        val openTelemetry =
            OpenTelemetrySdk
                .builder()
                .setTracerProvider(SdkTracerProvider.builder().addSpanProcessor(processor).build())
                .build()
        val application = loaderApplication(LoaderSettings(), openTelemetry)

        application.telemetry.mainSpanBlocking("loader.test.work", ErrorSlug.of("loader-test-work-failed")) { }
        exporter.exported.shouldBeEmpty()

        application.close()

        exporter.exported.map(SpanData::getName) shouldBe listOf("loader.test.work")
        exporter.shutDown shouldBe true
    }
}

/** Keeps exported spans after shutdown, unlike the SDK's in memory exporter, which clears them. */
private class RecordingSpanExporter : SpanExporter {
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
