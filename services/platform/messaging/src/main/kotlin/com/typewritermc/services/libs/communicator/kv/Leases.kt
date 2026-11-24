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
 * less than [ttl] loses nothing; a released key lives [grace], its holder kind's time to come back. A failed request
 * waits [retry] before it tries again. A claim read more than [skew] ahead of the reader's clock is reported.
 */
data class LeaseTimings(
    val refresh: Duration,
    val ttl: Duration,
    val grace: Duration,
    val retry: Duration = 1.seconds,
    val skew: Duration = 1.seconds,
) {
    init {
        require(refresh < ttl) { "A held key is refreshed before it expires." }
    }
}

/** One leased key's entry: the [holder], the instant its claim began on that holder's clock, and the [value] it keeps. */
data class LeaseEntry<V>(
    val holder: String,
    val claimed: Instant,
    val value: V,
) {
    /** Whether this claim is newer than [other]: claimed later, or at the same instant by a greater holder id. */
    fun newerThan(other: LeaseEntry<*>): Boolean = claimed > other.claimed || (claimed == other.claimed && holder > other.holder)
}

/** Writes a lease's entry and reads it back; [decode] returns null for a value it cannot read, which counts as no entry. */
interface LeaseCodec<V> {
    fun encode(entry: LeaseEntry<V>): ByteArray

    fun decode(bytes: ByteArray): LeaseEntry<V>?
}

/**
 * The keys one holder leases in one bucket: a session, a mirror, a demand entry. Each key names one holder at a time,
 * and of two holders claiming a key the newer claim holds it, whatever order the broker sees their writes in.
 *
 * A [claim] counts in [holds] at once, without the network, and writes the key naming this holder, the instant of the
 * claim on [clock], and its value. Whenever a claim reads the key, also after a conflict, it writes over an absent or
 * unreadable entry, its own, or an older claim; a newer claim of another holder means the key is lost for good. A held
 * key is rewritten every refresh with the time to live and follows the same rule on a conflict, so a holder that missed
 * its protagonist leaving stops once a newer claim took the key, and one whose key expired during an outage writes it
 * again. A [release] writes the key once more with the grace as its time to live; a conflict on a key this holder still
 * holds came from its own write whose answer was lost, so the release goes on at the key's current revision. A conflict
 * costs one read and one write; only a failed request waits before it tries again. [close] stops every write and leaves
 * the keys, so a reloaded holder takes them over and a crashed one lets them expire.
 *
 * Calls return at once; their writes run on [parent]'s dispatcher, per key in the order of the calls, and a newer call
 * stops an older claim before its next write.
 */
class Leases<V>(
    private val holder: String,
    private val buckets: StateFlow<KeyValueBuckets?>,
    private val bucketName: String,
    private val codec: LeaseCodec<V>,
    private val timings: LeaseTimings,
    parent: CoroutineScope,
    private val clock: Clock = Clock.systemUTC(),
    openTelemetry: OpenTelemetry = OpenTelemetry.noop(),
) : AutoCloseable {
    private val scope = CoroutineScope(parent.coroutineContext + SupervisorJob(parent.coroutineContext[Job]))
    private val slots = ConcurrentHashMap<String, Slot<V>>()
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
        val (slot, call) = call(key, holding = true)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                slot.refresher = null
                when (val taken = take(key, Claim(claimed, value), slot, call)) {
                    is Taken.Held -> {
                        slot.held = taken.held
                        if (slot.calls == call) slot.refresher = scope.launch { keep(key, slot, taken.held, call) }
                    }

                    // A newer call came: it leaves the key the way it finds it, so a release still shortens the last held key.
                    Taken.Superseded -> Unit

                    Taken.Lost -> slot.lose(call)
                }
            }
        }
    }

    /** Lets [key] go: it lives the grace, so this holder or another can claim it again before it expires. */
    fun release(key: String) {
        val (slot, call) = call(key, holding = false)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                slot.refresher = null
                slot.held?.let { shorten(key, it) }
                slot.held = null
                // Forget the key unless a call came since, so a holder keeps no state for keys it let go.
                slots.computeIfPresent(key) { _, current -> current.takeUnless { it === slot && it.calls == call } }
            }
        }
    }

    /** Whether this holder holds [key]: claimed, not released since, and not lost to a newer claim. */
    fun holds(key: String): Boolean = slots[key]?.holding == true

    /** The live entries of the keys matching [filter], skipping values no holder can read; a failed read throws its cause. */
    suspend fun entries(filter: String): List<LeaseEntry<V>> {
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
    private fun call(
        key: String,
        holding: Boolean,
    ): Pair<Slot<V>, Long> {
        var call = 0L
        val slot =
            slots.compute(key) { _, current ->
                (current ?: Slot()).also {
                    call = ++it.calls
                    it.holding = holding
                }
            }!!
        return slot to call
    }

    /** Writes [claim] under [key] until it holds the key, a newer claim holds it, or a newer call on the key came. */
    private suspend fun take(
        key: String,
        claim: Claim<V>,
        slot: Slot<V>,
        call: Long,
    ): Taken<V> {
        while (slot.calls == call) {
            val bucket = bucket()
            val outcome = bucket?.let { write(it, key, claim) { slot.calls == call } } ?: Write.Failed
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
     * Reads [key] and writes [claim] over it when the rule lets it: over an absent or unreadable entry, its own, or an
     * older claim. [current] says whether the call is still the slot's latest, checked right before the write.
     */
    private suspend fun write(
        bucket: KeyValueBucket,
        key: String,
        claim: Claim<V>,
        current: () -> Boolean = { true },
    ): Write<V> =
        when (val read = bucket.get(key)) {
            is KeyValueRead.Failed -> {
                Write.Failed
            }

            KeyValueRead.Absent -> {
                if (!current()) return Write.Conflict
                val entry = LeaseEntry(holder, claim.claimed, claim.value(null))
                bucket.create(key, codec.encode(entry), timings.ttl).outcome(entry, claim)
            }

            is KeyValueRead.Found -> {
                val found = codec.decode(read.entry.value)
                val mine = LeaseEntry(holder, claim.claimed, Unit)
                if (found != null && found.holder != holder) report(found)
                if (found != null && found.holder != holder && found.newerThan(mine)) return Write.Lost
                if (!current()) return Write.Conflict
                val entry = LeaseEntry(holder, claim.claimed, claim.value(found?.value))
                bucket.update(key, codec.encode(entry), timings.ttl, read.entry.revision).outcome(entry, claim)
            }
        }

    /** Rewrites the held key every refresh; a conflict reads the key again and writes it by the claim rule. */
    private suspend fun keep(
        key: String,
        slot: Slot<V>,
        initial: Held<V>,
        call: Long,
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
                    when (val again = write(bucket, key, held.claim)) {
                        is Write.Held -> held = again.held
                        Write.Lost -> return slot.lose(call)
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
     * Writes [held] once more with the grace as its time to live, until it is written, another holder holds the key, or
     * the key is gone. A conflict on a key this holder still holds came from its own write whose answer was lost.
     */
    private suspend fun shorten(
        key: String,
        held: Held<V>,
    ) {
        var revision = held.revision
        while (true) {
            val bucket = bucket()
            if (bucket != null) {
                when (bucket.update(key, codec.encode(held.entry), timings.grace, revision)) {
                    is KeyValueWrite.Written -> {
                        return
                    }

                    KeyValueWrite.Conflict -> {
                        when (val read = bucket.get(key)) {
                            is KeyValueRead.Found -> {
                                if (codec.decode(read.entry.value)?.holder != holder) return
                                revision = read.entry.revision
                                continue
                            }

                            KeyValueRead.Absent -> {
                                return
                            }

                            is KeyValueRead.Failed -> {
                                Unit
                            }
                        }
                    }

                    is KeyValueWrite.Failed -> {
                        Unit
                    }
                }
            }
            delay(timings.retry)
        }
    }

    /** Logs and counts [found] when its claim is further ahead of this holder's clock than the skew bound. */
    private fun report(found: LeaseEntry<V>) {
        val bound = clock.instant().plus(timings.skew.toJavaDuration())
        if (found.claimed <= bound) return
        ahead.add(1, bucketAttributes)
        log.warning(
            "A claim of ${found.holder} in $bucketName is stamped ${found.claimed}, beyond the skew bound of this holder's clock ($bound); " +
                "leases order claims by these stamps, so the holders' clocks disagree",
        )
    }

    private suspend fun bucket(): KeyValueBucket? =
        when (val opened = buckets.filterNotNull().first().open(bucketName)) {
            is KeyValueOpen.Opened -> opened.bucket
            KeyValueOpen.Missing, is KeyValueOpen.Failed -> null
        }

    private fun KeyValueWrite.outcome(
        entry: LeaseEntry<V>,
        claim: Claim<V>,
    ): Write<V> =
        when (this) {
            is KeyValueWrite.Written -> Write.Held(Held(entry, revision, claim))
            KeyValueWrite.Conflict -> Write.Conflict
            is KeyValueWrite.Failed -> Write.Failed
        }

    /** Lets the key go after a newer claim took it, unless a call came since [call]. */
    private fun Slot<V>.lose(call: Long) {
        held = null
        refresher = null
        if (calls == call) holding = false
    }

    private class Slot<V> {
        val lock = Mutex()

        /** Counts the calls on the key, so an older claim stops before its next write once a newer call came. */
        @Volatile
        var calls = 0L

        @Volatile
        var holding = false
        var held: Held<V>? = null
        var refresher: Job? = null
    }

    /** A claim as it was made: its instant, and how it derives its value from the value the key kept. */
    private class Claim<V>(
        val claimed: Instant,
        val value: (previous: V?) -> V,
    )

    /** A key this holder wrote: the entry, the revision it is at, and the claim that keeps it. */
    private data class Held<V>(
        val entry: LeaseEntry<V>,
        val revision: Long,
        val claim: Claim<V>,
    )

    private sealed interface Write<out V> {
        data class Held<V>(
            val held: Leases.Held<V>,
        ) : Write<V>

        data object Conflict : Write<Nothing>

        data object Lost : Write<Nothing>

        data object Failed : Write<Nothing>
    }

    private sealed interface Taken<out V> {
        data class Held<V>(
            val held: Leases.Held<V>,
        ) : Taken<V>

        data object Superseded : Taken<Nothing>

        data object Lost : Taken<Nothing>
    }

    private companion object {
        val log: Logger = Logger.getLogger(Leases::class.java.name)
    }
}
