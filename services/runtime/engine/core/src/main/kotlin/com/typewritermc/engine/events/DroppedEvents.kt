package com.typewritermc.engine.events

import com.typewritermc.events.Event
import com.typewritermc.identity.Protagonist
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import java.util.concurrent.ConcurrentHashMap
import java.util.logging.Logger
import kotlin.reflect.KClass

/**
 * Makes every occurrence the event runtime drops visible: a log line naming the event, its protagonist and why, and
 * one count on the counter [DROPPED] with the event class as [HandlerCosts.EVENT_ATTRIBUTE].
 */
class DroppedEvents(
    openTelemetry: OpenTelemetry,
) {
    private val counter =
        openTelemetry
            .meterBuilder("com.typewritermc.engine.events")
            .build()
            .counterBuilder(DROPPED)
            .setDescription("Occurrences that ran no handler, per event class.")
            .build()
    private val attributes = ConcurrentHashMap<KClass<out Event>, Attributes>()

    /** Records that [event], about [protagonist], ran no handler because this engine holds no session of it. */
    fun unheld(
        event: Event,
        protagonist: Protagonist,
    ) {
        val name = event::class.simpleName ?: event::class.java.name
        log.warning("Dropped $name about $protagonist: this engine holds no session of it.")
        counter.add(1, attributes.computeIfAbsent(event::class) { Attributes.of(EVENT, name) })
    }

    companion object {
        /** The counter of dropped occurrences. */
        const val DROPPED = "typewriter.event.dropped"

        private val EVENT: AttributeKey<String> = AttributeKey.stringKey(HandlerCosts.EVENT_ATTRIBUTE)
        private val log: Logger = Logger.getLogger(DroppedEvents::class.java.name)
    }
}
