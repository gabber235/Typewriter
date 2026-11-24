package com.typewritermc.loader.api.work.testing

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkItem
import com.typewritermc.loader.api.work.WorkObserver
import com.typewritermc.loader.api.work.WorkSubject

/** A Minecraft player's subject, as Typewriter names its protagonist. */
fun minecraftSubject(uuid: String) = WorkSubject("minecraft", uuid)

/** One event an observer of [InFlightWork] heard. */
sealed interface WorkEvent {
    val name: String

    data class Began(
        override val name: String,
        val subjects: Set<WorkSubject>?,
    ) : WorkEvent

    data class Ended(
        override val name: String,
    ) : WorkEvent

    data class Failed(
        override val name: String,
        val cause: String?,
    ) : WorkEvent
}

/**
 * An [InFlightWork] with an observer attached from the start, which records every item event in order together with
 * how many items ran at that moment.
 */
class RecordedWork {
    val work = InFlightWork()
    private val recorded = mutableListOf<WorkEvent>()

    /** Every event heard so far, in order. */
    val events: List<WorkEvent> get() = synchronized(recorded) { recorded.toList() }

    /** The events of items whose name starts with [prefix], in order. */
    fun eventsOf(prefix: String): List<WorkEvent> = events.filter { it.name.startsWith(prefix) }

    init {
        work.observe(
            object : WorkObserver {
                override fun began(item: WorkItem) = record(WorkEvent.Began(item.name, item.subjects))

                override fun ended(
                    item: WorkItem,
                    failure: Throwable?,
                ) = record(if (failure == null) WorkEvent.Ended(item.name) else WorkEvent.Failed(item.name, failure.message))
            },
        )
    }

    private fun record(event: WorkEvent) {
        synchronized(recorded) { recorded += event }
    }
}
