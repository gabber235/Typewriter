package com.typewritermc.services.libs.communicator.kv

import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.Clock
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import java.util.logging.Logger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.toJavaDuration

/**
 * How long leased keys live. A held key is rewritten every [refresh] with [ttl], so a holder that loses the broker for
 * less than [ttl] loses nothing; a released key stays vacant for [vacancy], its holder kind's time for a takeover. A
 * failed request waits [retry] before it tries again. A claim read more than [skew] ahead of the reader's clock is
 * reported.
 */
data class LeaseTimings(
    val refresh: Duration,
    val ttl: Duration,
    val vacancy: Duration,
    val retry: Duration = 1.seconds,
    val skew: Duration = 1.seconds,
) {
    init {
        require(refresh < ttl) { "A held key is refreshed before it expires." }
    }
}

/** One leased key's entry: who holds it, if anyone, and the [value] it keeps; [H] identifies holders. */
data class LeaseEntry<H : Comparable<H>, V>(
    val state: LeaseState<H>,
    val value: V,
) {
    /** The holder keeping the key alive, or null while the key is vacant. */
    val holder: H?
        get() =
            when (val state = state) {
                is LeaseState.Held -> state.holder
                LeaseState.Vacant -> null
            }
}

/**
 * Who holds a leased key. A held key names its holder and when its claim began; a vacant key is alive but held by
 * nobody: its holder released it, and it waits for a takeover until its vacancy ends.
 */
sealed interface LeaseState<out H : Comparable<@UnsafeVariance H>> {
    data class Held<H : Comparable<H>>(
        val holder: H,
        val claimed: Instant,
    ) : LeaseState<H> {
        /** Whether this claim is newer than [other]: claimed later, or at the same instant by a greater holder. */
        fun newerThan(other: Held<H>): Boolean = claimed > other.claimed || (claimed == other.claimed && holder > other.holder)
    }

    data object Vacant : LeaseState<Nothing>
}

/** Writes a lease's entry and reads it back; [decode] returns null for a value it cannot read, which counts as no entry. */
interface LeaseCodec<H : Comparable<H>, V> {
    fun encode(entry: LeaseEntry<H, V>): ByteArray

    fun decode(bytes: ByteArray): LeaseEntry<H, V>?
}

/**
 * The keys one holder leases in one bucket: a session, a mirror, a demand entry. Each key names one holder at a time,
 * and of two holders claiming a key the newer claim holds it, whatever order the broker sees their writes in.
 *
 * A [claim] writes the key naming this holder, the instant of the claim on [clock], and its value. Whenever a claim reads the key, also after a conflict, it writes over an absent,
 * unreadable or vacant entry, its own, or an older claim; a newer claim of another holder means the key is lost for
 * good. A held key is rewritten every refresh with the time to live and follows the same rule on a conflict, except
 * that a vacant entry means another holder took the key and let it go, so the key is lost for good: a holder that
 * missed its protagonist leaving stops once a newer claim took the key, even after that claim was released, and one
 * whose key expired during an outage writes it again. A [release] writes the key vacant at its own revision, with the vacancy as its time to live:
 * the key stays alive for a takeover, but nobody holds it. A conflict on a key this holder still holds came from its own
 * write whose answer was lost, so the release goes on at the key's current revision; a release never writes over
 * another holder's claim. A conflict costs one read and one write; only a failed request waits before it tries again.
 * [close] stops every write and leaves the keys, so a reloaded holder takes them over and a crashed one lets them
 * expire.
 *
 * Calls return at once; their writes run on [parent]'s dispatcher, per key in the order of the calls, and a newer call
 * stops an older claim before its next write.
 */
class Leases<H : Comparable<H>, V>(
    private val holder: H,
    private val buckets: StateFlow<KeyValueBuckets?>,
    private val bucketName: String,
    private val codec: LeaseCodec<H, V>,
    private val timings: LeaseTimings,
    parent: CoroutineScope,
    private val clock: Clock = Clock.systemUTC(),
    openTelemetry: OpenTelemetry = OpenTelemetry.noop(),
) : AutoCloseable {
    private val scope = CoroutineScope(parent.coroutineContext + SupervisorJob(parent.coroutineContext[Job]))
    private val slots = ConcurrentHashMap<String, Slot<H, V>>()
    private val ahead =
        openTelemetry
            .meterBuilder(Leases::class.java.name)
            .build()
            .counterBuilder("typewriter.lease.claim.ahead")
            .setDescription("Claims read further ahead of this holder's clock than the skew bound, so their order may be wrong")
            .setUnit("{claim}")
            .build()
    private val bucketAttributes = Attributes.of(AttributeKey.stringKey("lease.bucket"), bucketName)

    /** Claims [key] for this holder; [value] gets the value the key kept before, null when it kept none it can read. */
    fun claim(
        key: String,
        value: (previous: V?) -> V,
    ) {
        val claimed = clock.instant()
        val (slot, call) = call(key)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                slot.refresher = null
                when (val taken = take(key, Claim(LeaseState.Held(holder, claimed), value), slot, call)) {
                    is Taken.Held -> {
                        slot.held = taken.held
                        if (slot.calls == call) slot.refresher = scope.launch { keep(key, slot, taken.held) }
                    }

                    // A newer call came: it leaves the key the way it finds it, so a release still vacates the last held key.
                    Taken.Superseded -> {
                        Unit
                    }

                    Taken.Lost -> {
                        slot.lose()
                    }
                }
            }
        }
    }

    /** Lets [key] go: it stays vacant for the vacancy, held by nobody, so this holder or another can take it over. */
    fun release(key: String) {
        val (slot, call) = call(key)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                slot.refresher = null
                slot.held?.let { vacate(key, it) }
                slot.held = null
                // Forget the key unless a call came since, so a holder keeps no state for keys it let go.
                slots.computeIfPresent(key) { _, current -> current.takeUnless { it === slot && it.calls == call } }
            }
        }
    }

    /** The live entries of the keys matching [filter], held and vacant, skipping values no holder can read; a failed read throws its cause. */
    suspend fun entries(filter: String): List<LeaseEntry<H, V>> {
        val bucket = bucket() ?: return emptyList()
        val keys =
            when (val listed = bucket.keys(filter)) {
                is KeyValueKeys.Listed -> listed.keys
                is KeyValueKeys.Failed -> throw listed.cause
            }
        return keys.mapNotNull { key ->
            when (val read = bucket.get(key)) {
                is KeyValueRead.Found -> codec.decode(read.entry.value)
                KeyValueRead.Absent -> null
                is KeyValueRead.Failed -> throw read.cause
            }
        }
    }

    /** Stops every write and leaves the keys as they are. */
    override fun close() {
        scope.cancel()
    }

    /** Counts a call on [key]'s slot, made atomically with the slot's creation and removal. */
    private fun call(key: String): Pair<Slot<H, V>, Long> {
        var call = 0L
        val slot = slots.compute(key) { _, current -> (current ?: Slot()).also { call = ++it.calls } }!!
        return slot to call
    }

    /** Writes [claim] under [key] until it holds the key, a newer claim holds it, or a newer call on the key came. */
    private suspend fun take(
        key: String,
        claim: Claim<H, V>,
        slot: Slot<H, V>,
        call: Long,
    ): Taken<H, V> {
        while (slot.calls == call) {
            val bucket = bucket()
            val outcome = bucket?.let { write(it, key, claim, takesVacant = true) { slot.calls == call } } ?: Write.Failed
            when (outcome) {
                is Write.Held -> return Taken.Held(outcome.held)
                Write.Lost -> return Taken.Lost
                Write.Conflict -> continue
                Write.Failed -> delay(timings.retry)
            }
        }
        return Taken.Superseded
    }

    /**
     * Reads [key] and writes [claim] over it when the rule lets it: over an absent or unreadable entry, its own, an older
     * claim, or a vacant entry when [takesVacant]. [current] says whether the call is still the slot's latest, checked
     * right before the write.
     */
    private suspend fun write(
        bucket: KeyValueBucket,
        key: String,
        claim: Claim<H, V>,
        takesVacant: Boolean,
        current: () -> Boolean = { true },
    ): Write<H, V> =
        when (val read = bucket.get(key)) {
            is KeyValueRead.Failed -> {
                Write.Failed
            }

            KeyValueRead.Absent -> {
                if (!current()) return Write.Conflict
                val entry = LeaseEntry(claim.state, claim.value(null))
                bucket.create(key, codec.encode(entry), timings.ttl).outcome(entry, claim)
            }

            is KeyValueRead.Found -> {
                val found = codec.decode(read.entry.value)
                val other =
                    when (val state = found?.state) {
                        is LeaseState.Held -> state.takeIf { it.holder != holder }
                        LeaseState.Vacant, null -> null
                    }
                other?.let(::report)
                if (other != null && other.newerThan(claim.state)) return Write.Lost
                if (found?.state == LeaseState.Vacant && !takesVacant) return Write.Lost
                if (!current()) return Write.Conflict
                val entry = LeaseEntry(claim.state, claim.value(found?.value))
                bucket.update(key, codec.encode(entry), timings.ttl, read.entry.revision).outcome(entry, claim)
            }
        }

    /**
     * Rewrites the held key every refresh. A conflict means another write came after this holder's: it reads the key
     * again and writes it by the claim rule, but a vacant key was taken and let go by a newer claim, so it is lost.
     */
    private suspend fun keep(
        key: String,
        slot: Slot<H, V>,
        initial: Held<H, V>,
    ) {
        var held = initial
        while (true) {
            delay(timings.refresh)
            val bucket = bucket() ?: continue
            when (val written = bucket.update(key, codec.encode(held.entry), timings.ttl, held.revision)) {
                is KeyValueWrite.Written -> {
                    held = held.copy(revision = written.revision)
                }

                KeyValueWrite.Conflict -> {
                    when (val again = write(bucket, key, held.claim, takesVacant = false)) {
                        is Write.Held -> held = again.held

                        Write.Lost -> return slot.lose()

                        // Tried again at the next refresh.
                        Write.Conflict, Write.Failed -> Unit
                    }
                }

                is KeyValueWrite.Failed -> {
                    Unit
                }
            }
            slot.held = held
        }
    }

    /**
     * Writes [held] vacant with the vacancy as its time to live, until it is written, the key is no longer this holder's,
     * or the key is gone. A conflict on a key this holder still holds came from its own write whose answer was lost.
     */
    private suspend fun vacate(
        key: String,
        held: Held<H, V>,
    ) {
        var revision = held.revision
        while (true) {
            when (val step = bucket()?.let { vacateAt(it, key, held, revision) } ?: Vacate.Retry) {
                Vacate.Done -> return
                is Vacate.Again -> revision = step.revision
                Vacate.Retry -> delay(timings.retry)
            }
        }
    }

    /** One try of [vacate] at [revision]: done, again at the key's current revision, or again after the retry wait. */
    private suspend fun vacateAt(
        bucket: KeyValueBucket,
        key: String,
        held: Held<H, V>,
        revision: Long,
    ): Vacate =
        when (bucket.update(key, codec.encode(held.entry.copy(state = LeaseState.Vacant)), timings.vacancy, revision)) {
            is KeyValueWrite.Written -> {
                Vacate.Done
            }

            KeyValueWrite.Conflict -> {
                when (val read = bucket.get(key)) {
                    is KeyValueRead.Found -> {
                        if (codec.decode(read.entry.value)?.holder == holder) Vacate.Again(read.entry.revision) else Vacate.Done
                    }

                    KeyValueRead.Absent -> {
                        Vacate.Done
                    }

                    is KeyValueRead.Failed -> {
                        Vacate.Retry
                    }
                }
            }

            is KeyValueWrite.Failed -> {
                Vacate.Retry
            }
        }

    /** Logs and counts [found] when its claim is further ahead of this holder's clock than the skew bound. */
    private fun report(found: LeaseState.Held<H>) {
        val bound = clock.instant().plus(timings.skew.toJavaDuration())
        if (found.claimed <= bound) return
        ahead.add(1, bucketAttributes)
        log.warning(
            "A claim of ${found.holder} in $bucketName is stamped ${found.claimed}, " +
                "beyond the skew bound of this holder's clock ($bound); " +
                "leases order claims by these stamps, so the holders' clocks disagree",
        )
    }

    private suspend fun bucket(): KeyValueBucket? =
        when (val opened = buckets.filterNotNull().first().open(bucketName)) {
            is KeyValueOpen.Opened -> opened.bucket
            KeyValueOpen.Missing, is KeyValueOpen.Failed -> null
        }

    private fun KeyValueWrite.outcome(
        entry: LeaseEntry<H, V>,
        claim: Claim<H, V>,
    ): Write<H, V> =
        when (this) {
            is KeyValueWrite.Written -> Write.Held(Held(entry, revision, claim))
            KeyValueWrite.Conflict -> Write.Conflict
            is KeyValueWrite.Failed -> Write.Failed
        }

    /** Lets the key go after a newer claim took it. */
    private fun Slot<H, V>.lose() {
        held = null
        refresher = null
    }

    private class Slot<H : Comparable<H>, V> {
        val lock = Mutex()

        /** Counts the calls on the key, so an older claim stops before its next write once a newer call came. */
        @Volatile
        var calls = 0L
        var held: Held<H, V>? = null
        var refresher: Job? = null
    }

    /** A claim as it was made: its instant, and how it derives its value from the value the key kept. */
    private class Claim<H : Comparable<H>, V>(
        val state: LeaseState.Held<H>,
        val value: (previous: V?) -> V,
    )

    /** A key this holder wrote: the entry, the revision it is at, and the claim that keeps it. */
    private data class Held<H : Comparable<H>, V>(
        val entry: LeaseEntry<H, V>,
        val revision: Long,
        val claim: Claim<H, V>,
    )

    private sealed interface Write<out H : Comparable<@UnsafeVariance H>, out V> {
        data class Held<H : Comparable<H>, V>(
            val held: Leases.Held<H, V>,
        ) : Write<H, V>

        data object Conflict : Write<Nothing, Nothing>

        data object Lost : Write<Nothing, Nothing>

        data object Failed : Write<Nothing, Nothing>
    }

    private sealed interface Vacate {
        data object Done : Vacate

        data class Again(
            val revision: Long,
        ) : Vacate

        data object Retry : Vacate
    }

    private sealed interface Taken<out H : Comparable<@UnsafeVariance H>, out V> {
        data class Held<H : Comparable<H>, V>(
            val held: Leases.Held<H, V>,
        ) : Taken<H, V>

        data object Superseded : Taken<Nothing, Nothing>

        data object Lost : Taken<Nothing, Nothing>
    }

    private companion object {
        val log: Logger = Logger.getLogger(Leases::class.java.name)
    }
}
