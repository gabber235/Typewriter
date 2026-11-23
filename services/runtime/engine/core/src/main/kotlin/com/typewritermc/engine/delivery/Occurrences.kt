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
 * the same occurrence waits on that run instead of starting another. Only the first ask decides: it either starts the
 * run or is refused, and a refused occurrence is not taken, so its next ask decides again. A final occurrence is
 * forgotten once the [timings]' window passed after its last ask. The inbox keeps the occurrences it holds, a client
 * gateway the occurrences its clients emit.
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

    /** What the first ask about an occurrence leads to: a [Run] that gives its result, or an answer of type [A] that refuses it. */
    sealed interface First<out A> {
        class Run(
            val run: suspend () -> EventResult,
        ) : First<Nothing>

        class Refused<out A>(
            val answer: A,
        ) : First<A>
    }

    /**
     * The answer to an ask about occurrence [id]: [status] of its result once it is final within [wait], or of null while it
     * still runs. An occurrence not taken yet asks [first], which starts its run or refuses it with its own answer; when
     * two first asks race, one run is kept and the other never starts.
     */
    suspend fun <A> answer(
        id: String,
        wait: Duration,
        first: suspend () -> First<A>,
        status: (EventResult?) -> A,
    ): A {
        val occurrence =
            taken[id] ?: when (val decided = first()) {
                is First.Refused -> return decided.answer
                is First.Run -> Taken(scope.async(start = CoroutineStart.LAZY) { decided.run() }, time.markNow()).let { taken.putIfAbsent(id, it) ?: it }
            }
        occurrence.result.start()
        occurrence.asked = time.markNow()
        return status(withTimeoutOrNull(wait) { occurrence.result.await() }.also { occurrence.asked = time.markNow() })
    }
}
