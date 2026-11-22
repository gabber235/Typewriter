package com.typewritermc.engine.delivery

import com.typewritermc.engine.events.Elsewhere
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.SubjectHolding
import com.typewritermc.events.Emitter
import com.typewritermc.events.Event
import com.typewritermc.events.EventResult
import com.typewritermc.events.Origin
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Identity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withTimeoutOrNull
import skirout.editor.v1.event.DeliverEventRequest
import skirout.editor.v1.event.DeliverEventResponse
import skirout.editor.v1.event.EventDelivery
import skirout.editor.v1.event.EventStatus
import skirout.editor.v1.event.OccurrenceId
import skirout.editor.v1.type_catalog.DataValue
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * How long a sender waits at each step of a delivery. [wait] is how long a holder holds an answer for a sender that
 * waits for the result, [askAgain] how long when asking again about an occurrence still running, [answer] how much
 * longer than its wait the sender waits for one answer. A holder that answers nothing for [noResponse] gives
 * `no_response`, an occurrence without a final result after [limit] gives `timeout`, and a lost ask is asked again
 * after a gap that starts at [firstGap] and doubles up to [lastGap]. A holder keeps a final occurrence for [kept] after
 * its last ask; a sender asks again far sooner, unless it gave up. An engine kind may bind its own; these are the
 * defaults.
 */
data class DeliveryTimings(
    val wait: Duration = 200.milliseconds,
    val askAgain: Duration = 3.seconds,
    val answer: Duration = 1.seconds,
    val noResponse: Duration = 5.seconds,
    val limit: Duration = 60.seconds,
    val firstGap: Duration = 50.milliseconds,
    val lastGap: Duration = 1.seconds,
    val kept: Duration = 60.seconds,
) {
    /** The gap before asking again after [lost] asks in a row went unanswered. */
    fun gap(lost: Int): Duration = (firstGap * (1 shl (lost - 1).coerceIn(0, MAX_DOUBLINGS))).coerceAtMost(lastGap)

    private companion object {
        const val MAX_DOUBLINGS = 16
    }
}

/**
 * The sender side of delivery: sends an occurrence to every engine that holds its subject and merges their results.
 * This engine runs it itself when it holds the subject, by its own sessions, without asking; every other holder, by
 * this engine's copy of the Realm's sessions, is asked through [link] until it answers with the final result. An engine
 * that answers it no longer holds the subject is left out and the holders are resolved again, so a delivery follows a
 * protagonist that moved. Toward each holder one delivery per subject is outstanding until the holder answered it,
 * so a holder queues the occurrences about one subject in the order this engine sent them.
 */
class Delivery(
    private val self: EngineId,
    private val holding: SubjectHolding,
    private val holders: Holders,
    private val link: EngineLink,
    private val runtime: EventRuntime,
    private val codec: EventCodec,
    private val scope: CoroutineScope,
    private val timings: DeliveryTimings = DeliveryTimings(),
    private val time: TimeSource = TimeSource.Monotonic,
) : Emitter,
    Elsewhere {
    private val gates = ConcurrentHashMap<Pair<Identity, EngineId>, Gate>()

    override suspend fun send(
        event: Event,
        origin: Origin?,
    ): EventResult {
        val subject = runtime.subjectOf(event) ?: return runtime.run(event, origin)
        return deliver(Occurrence(newOccurrence(), event, subject, origin), waits = true, here = holding.holds(subject))
    }

    override fun forward(
        event: Event,
        subject: Identity,
        origin: Origin?,
    ) {
        val occurrence = Occurrence(newOccurrence(), event, subject, origin)
        val tried = setOf(self)
        // Taking the gates before the first suspension keeps the order of forwards from one thread.
        scope.launch(start = CoroutineStart.UNDISPATCHED) { deliver(occurrence, waits = false, here = false, tried = tried) }
    }

    private class Occurrence(
        val id: OccurrenceId,
        val event: Event,
        val subject: Identity,
        val origin: Origin?,
    ) {
        var encoded: DataValue? = null
    }

    /**
     * Runs [occurrence] here when [here] and asks every other holder not in [tried]. An engine that answers it no longer
     * holds the subject is asked again only once this engine's copy of the sessions changed, so the delivery follows a
     * protagonist that moved; once every listed holder answered, merges what they gave. Without every answer within the
     * limit, also while this engine's copy of the sessions has not caught up, the delivery ends as `timeout`; what runs
     * keeps running.
     */
    private suspend fun deliver(
        occurrence: Occurrence,
        waits: Boolean,
        here: Boolean,
        tried: Set<EngineId> = setOf(self),
    ): EventResult =
        withTimeoutOrNull(timings.limit) { deliverInTime(occurrence, waits, here, tried) } ?: TIMEOUT

    private suspend fun deliverInTime(
        occurrence: Occurrence,
        waits: Boolean,
        here: Boolean,
        tried: Set<EngineId>,
    ): EventResult =
        coroutineScope {
            val answered = tried.toMutableSet()
            val results = mutableListOf<EventResult>()
            val local = if (here) async(start = CoroutineStart.UNDISPATCHED) { runtime.run(occurrence.event, occurrence.origin) } else null
            var notHeld = emptySet<EngineId>()
            while (true) {
                val seen = holders.version
                val listed = holders.of(occurrence.subject) - answered
                val engines = listed - notHeld
                if (engines.isEmpty()) {
                    if (listed.isEmpty()) break
                    // An engine said it no longer holds the subject while this copy still lists it: wait for the copy.
                    holders.changedSince(seen)
                    notHeld = emptySet()
                    continue
                }
                val answers = engines.map { engine -> async(start = CoroutineStart.UNDISPATCHED) { engine to ask(engine, occurrence, waits) } }.awaitAll()
                answers.forEach { (engine, asked) ->
                    when (asked) {
                        is Asked.Answered -> {
                            answered += engine
                            results += asked.result
                        }

                        Asked.NotHeld -> notHeld = notHeld + engine
                    }
                }
            }
            merged(listOfNotNull(local?.await()) + results)
        }

    private sealed interface Asked {
        data class Answered(
            val result: EventResult,
        ) : Asked

        data object NotHeld : Asked
    }

    /**
     * Asks [engine] about [occurrence] until it answers with the final result, or, when nobody [waits] for it, until it
     * answers at all. The first ask goes through the gate of the subject toward [engine], which opens at the first answer.
     */
    private suspend fun ask(
        engine: EngineId,
        occurrence: Occurrence,
        waits: Boolean,
    ): Asked {
        val event =
            occurrence.encoded ?: codec.encode(occurrence.event)?.also { occurrence.encoded = it }
                ?: return Asked.Answered(notEncodable(occurrence.event))
        val delivery = EventDelivery(occurrence = occurrence.id, subject = occurrence.subject.toWire(), event = event, origin = occurrence.origin?.toWire())
        val started = time.markNow()
        var answered = time.markNow()
        var confirmed = false
        var lost = 0
        val gate = gate(occurrence.subject to engine)
        var holdsGate = false
        try {
            gate.lock()
            holdsGate = true
            while (true) {
                if (started.elapsedNow() >= timings.limit) return Asked.Answered(TIMEOUT)
                val wait =
                    when {
                        confirmed -> timings.askAgain
                        !waits || gate.queued() -> Duration.ZERO
                        else -> timings.wait
                    }
                val response = link.ask(engine, DeliverEventRequest(delivery = delivery, waitMs = wait.inWholeMilliseconds.toInt(), confirmed = confirmed), wait + timings.answer)
                if (response == null) {
                    if (answered.elapsedNow() >= timings.noResponse) return Asked.Answered(NO_RESPONSE)
                    lost++
                    delay(timings.gap(lost))
                    continue
                }
                answered = time.markNow()
                lost = 0
                if (holdsGate) gate.unlock().also { holdsGate = false }
                when (response) {
                    is DeliverEventResponse.SuccessWrapper -> {
                        val status = response.value
                        if (status is EventStatus.FinalWrapper) return Asked.Answered(status.value.toResult(codec))
                        if (!waits) return Asked.Answered(EventResult.NotHandled)
                        confirmed = true
                    }

                    is DeliverEventResponse.NotHeldErrorWrapper -> return Asked.NotHeld

                    is DeliverEventResponse.ForgottenErrorWrapper -> return Asked.Answered(HOLDER_RESTARTED)

                    else -> return Asked.Answered(HOLDER_ERROR)
                }
            }
        } finally {
            if (holdsGate) gate.unlock()
            release(occurrence.subject to engine)
        }
    }

    /**
     * The order of deliveries about one subject toward one holder: the next goes once the previous got an answer. It
     * counts who waits behind the current delivery, so that one asks for an instant answer.
     */
    private class Gate {
        private val mutex = Mutex()
        private var waiting = 0
        var users = 0

        suspend fun lock() {
            synchronized(this) { waiting++ }
            try {
                mutex.lock()
            } finally {
                synchronized(this) { waiting-- }
            }
        }

        fun queued(): Boolean = synchronized(this) { waiting > 0 }

        fun unlock() = mutex.unlock()
    }

    private fun gate(key: Pair<Identity, EngineId>): Gate = gates.compute(key) { _, gate -> (gate ?: Gate()).also { it.users++ } }!!

    private fun release(key: Pair<Identity, EngineId>) {
        gates.computeIfPresent(key) { _, gate -> gate.takeIf { --it.users > 0 } }
    }

    @OptIn(ExperimentalUuidApi::class)
    private fun newOccurrence() = OccurrenceId(value = Uuid.generateV7().toString())

    private companion object {
        val NO_RESPONSE = deliveryFailure("no_response", "The engine holding the subject did not answer.")
        val TIMEOUT = deliveryFailure("timeout", "The event did not finish in time; it may still finish.")
        val HOLDER_RESTARTED = deliveryFailure("holder_restarted", "The engine holding the subject restarted and lost the event.")
        val HOLDER_ERROR = deliveryFailure("holder_error", "The engine holding the subject failed to take the event.")

        fun notEncodable(event: Event) = deliveryFailure("unknown_type", "The event ${event::class.simpleName} has no catalog type, so it cannot leave this engine.")
    }
}
