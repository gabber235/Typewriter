package com.typewritermc.engine.events

import com.typewritermc.events.Event
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

/**
 * Records the time of every handler run as the histogram [HANDLER_DURATION], in seconds, with the event class of the
 * occurrence as [EVENT_ATTRIBUTE]. The engine's host exports it with the rest of its telemetry, so a run on real Paper
 * reads the average tick handler time from the collected metric.
 */
class HandlerCosts(
    openTelemetry: OpenTelemetry,
) {
    private val duration =
        openTelemetry
            .meterBuilder("com.typewritermc.engine.events")
            .build()
            .histogramBuilder(HANDLER_DURATION)
            .setUnit("s")
            .setDescription("The time of one handler run, per event class of the occurrence.")
            .setExplicitBucketBoundariesAdvice(BOUNDARIES)
            .build()
    private val attributes = ConcurrentHashMap<KClass<out Event>, Attributes>()

    /** Records one handler run on an occurrence of [event] that took [nanos]. */
    fun record(
        event: KClass<out Event>,
        nanos: Long,
    ) {
        val tagged = attributes.computeIfAbsent(event) { Attributes.of(EVENT, it.simpleName ?: it.java.name) }
        duration.record(nanos / NANOS_PER_SECOND, tagged)
    }

    companion object {
        /** The histogram of handler run times. */
        const val HANDLER_DURATION = "typewriter.event.handler.duration"

        /** The attribute naming the event class of the occurrence a handler ran for, such as `Tick`. */
        const val EVENT_ATTRIBUTE = "typewriter.event"

        private val EVENT: AttributeKey<String> = AttributeKey.stringKey(EVENT_ATTRIBUTE)
        private const val NANOS_PER_SECOND = 1e9

        /** Handler runs take microseconds to milliseconds, so the buckets resolve that range. */
        private val BOUNDARIES = listOf(1e-6, 5e-6, 1e-5, 2.5e-5, 5e-5, 1e-4, 2.5e-4, 5e-4, 1e-3, 2.5e-3, 5e-3, 1e-2, 5e-2, 1e-1)
    }
}
