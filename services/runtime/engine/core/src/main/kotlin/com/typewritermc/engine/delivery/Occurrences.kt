package com.typewritermc.engine.delivery

import com.typewritermc.events.EventResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The occurrences someone asks this engine about, each with the one run that gives its result, so asking again with
 * the same occurrence waits on that run instead of starting another. A final occurrence is forgotten once the
 * [timings]' window passed after its last ask, after which [knows] no longer finds it. The inbox keeps the occurrences it
 * holds, a client gateway the occurrences its clients emit.
 */
class Occurrences(
    private val scope: CoroutineScope,
    private val timings: DeliveryTimings = DeliveryTimings(),
    private val time: TimeSource = TimeSource.Monotonic,
) {
    private class Taken(
        val result: Deferred<EventResult>,
        @Volatile var asked: TimeMark,
    )

    private val taken = ConcurrentHashMap<String, Taken>()

    init {
        scope.launch {
            while (isActive) {
                delay(timings.kept / 2)
                taken.entries.removeIf { (_, occurrence) -> occurrence.result.isCompleted && occurrence.asked.elapsedNow() > timings.kept }
            }
        }
    }

    /** Whether occurrence [id] was taken and is not yet forgotten. */
    fun knows(id: String): Boolean = taken.containsKey(id)

    /**
     * The result of occurrence [id] once it is final within [wait], or null while it still runs. An occurrence not taken
     * yet starts [run]; when two first asks race, one run is kept and the other never starts.
     */
    suspend fun answer(
        id: String,
        wait: Duration,
        run: suspend () -> EventResult,
    ): EventResult? {
        val occurrence =
            taken[id] ?: Taken(scope.async(start = CoroutineStart.LAZY) { run() }, time.markNow()).let { taken.putIfAbsent(id, it) ?: it }
        occurrence.result.start()
        occurrence.asked = time.markNow()
        return withTimeoutOrNull(wait) { occurrence.result.await() }.also { occurrence.asked = time.markNow() }
    }
}
