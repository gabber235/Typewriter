package com.typewritermc.engine.session

import com.typewritermc.events.ChainQueueing
import com.typewritermc.events.ProtagonistJoined
import com.typewritermc.events.ProtagonistLeft
import com.typewritermc.events.SessionArrived
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.SessionReporter
import com.typewritermc.identity.Sessions
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueChange
import com.typewritermc.services.libs.communicator.kv.KeyValueKeys
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWatch
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
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
import java.io.IOException
import java.time.Clock
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import java.util.logging.Logger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * How long session keys live. A held key is rewritten every [refresh] with [ttl], so an engine that loses NATS for
 * less than [ttl] ends nothing; a key left behind by a quit lives [grace], the engine kind's time to come back.
 */
data class SessionTimings(
    val refresh: Duration,
    val ttl: Duration,
    val grace: Duration,
    /** How long a failed write waits before it tries again. */
    val retry: Duration = 1.seconds,
) {
    init {
        require(refresh < ttl) { "A held key is refreshed before it expires." }
    }

    companion object {
        /** A Minecraft player: 20 second refresh, 60 second time to live, 10 second grace. */
        val MINECRAFT: SessionTimings = SessionTimings(refresh = 20.seconds, ttl = 60.seconds, grace = 10.seconds)

        /** A panel tab, refreshed by its heartbeat: 45 second time to live, 10 second grace after it leaves. */
        val PANEL: SessionTimings = SessionTimings(refresh = 15.seconds, ttl = 45.seconds, grace = 10.seconds)
    }
}

/**
 * Keeps this engine's sessions in the Realm's sessions bucket. Every write checks the key's revision: an engine that
 * takes a session over (a server move) overwrites the key, and the engine that held it sees its next write fail and
 * lets the session go, whichever of join and quit comes first. Closing stops every write and leaves the keys, so a
 * reloaded engine takes them over and a crashed one lets them expire.
 *
 * Reporter calls return at once; their writes run on [parent]'s dispatcher, per session in the order of the calls:
 * each call queues on its session's lock before it returns.
 *
 * Every reported session counts in [holding] from its `connected` call until its `disconnected` call or until another
 * engine takes it over, written in call order and without NATS, so this engine knows what it holds while NATS is down.
 *
 * Every successful take emits [SessionArrived] to [events], after [ProtagonistJoined] when the protagonist had no
 * session key anywhere. The keeper follows the whole bucket, so when a key expires, the engine its last value names
 * as holder emits [ProtagonistLeft] once no other key of the protagonist lives. That is best effort: after a crash no
 * engine names itself holder, and an expiry while this engine's watch was down longer than the bucket keeps its marker
 * goes unseen.
 */
class SessionKeeper(
    private val engine: EngineId,
    private val buckets: StateFlow<KeyValueBuckets?>,
    private val bucketName: String,
    private val timings: SessionTimings,
    private val holding: HeldSessions,
    private val events: ChainQueueing,
    parent: CoroutineScope,
    private val clock: Clock = Clock.systemUTC(),
) : SessionReporter,
    Sessions,
    AutoCloseable {
    private val scope = CoroutineScope(parent.coroutineContext + SupervisorJob(parent.coroutineContext[Job]))
    private val sessions = ConcurrentHashMap<SessionId, SessionSlot>()

    init {
        scope.launch { follow() }
    }

    override fun connected(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        val slot = sessions.computeIfAbsent(id) { SessionSlot() }
        val generation = slot.generation.incrementAndGet()
        holding.hold(protagonist, id)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                val held = take(protagonist, id)
                slot.held = held
                slot.refresher = scope.launch { refresh(id, slot, held, generation) }
            }
        }
    }

    override fun disconnected(id: SessionId) {
        val slot = sessions[id] ?: return
        slot.generation.incrementAndGet()
        holding.release(id)
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                slot.refresher = null
                slot.held?.let { release(it) }
                slot.held = null
            }
        }
    }

    override suspend fun holders(protagonist: Protagonist): Set<EngineId> {
        val bucket = bucket() ?: return emptySet()
        return when (val read = bucket.liveEntries(protagonist)) {
            is LiveEntries.Read -> read.entries.mapTo(linkedSetOf()) { it.holder }
            is LiveEntries.Failed -> throw read.cause
        }
    }

    /** Stops every write and leaves the keys as they are. */
    override fun close() {
        scope.cancel()
    }

    /**
     * Writes the session's key as held by this engine, keeping when it began, and retries until it succeeds; then
     * emits the session's arrival, after the protagonist's join when no key of it lived before the write.
     */
    private suspend fun take(
        protagonist: Protagonist,
        id: SessionId,
    ): HeldSession {
        val key = sessionKey(protagonist, id)
        while (true) {
            val bucket = bucket()
            val online = (bucket?.liveEntries(protagonist) as? LiveEntries.Read)?.entries?.isNotEmpty()
            if (bucket != null && online != null) {
                val written =
                    when (val read = bucket.get(key)) {
                        is KeyValueRead.Found -> {
                            val stored = readable(key, read.entry.value) ?: SessionEntry(protagonist, engine, clock.instant())
                            val entry = stored.copy(holder = engine)
                            bucket.update(key, entry.encode(), timings.ttl, read.entry.revision).heldAs(key, entry)
                        }

                        KeyValueRead.Absent -> {
                            val entry = SessionEntry(protagonist, engine, clock.instant())
                            bucket.create(key, entry.encode(), timings.ttl).heldAs(key, entry)
                        }

                        is KeyValueRead.Failed -> {
                            null
                        }
                    }
                if (written != null) {
                    if (!online) events.emit(ProtagonistJoined(protagonist))
                    events.emit(SessionArrived(Session(protagonist, id)))
                    return written
                }
            }
            delay(timings.retry)
        }
    }

    /**
     * Keeps a copy of every live session entry in the bucket, watching again whenever the watch breaks. The copy
     * survives a new watch, so an expiry whose marker the new watch replays still finds the key's last holder.
     */
    private suspend fun follow() {
        val live = HashMap<String, SessionEntry>()
        while (true) {
            val watch = bucket()?.watch(SessionsBucket.EVERY_KEY)
            if (watch is KeyValueWatch.Watching) watch.changes.collect { live.record(it) }
            delay(timings.retry)
        }
    }

    private fun MutableMap<String, SessionEntry>.record(change: KeyValueChange) {
        when (change) {
            is KeyValueChange.Put -> {
                val entry = readable(change.entry.key, change.entry.value) ?: return
                this[change.entry.key] = entry
            }

            is KeyValueChange.Expired -> {
                val last = remove(change.key) ?: return
                if (last.holder == engine && values.none { it.protagonist == last.protagonist }) {
                    events.emit(ProtagonistLeft(last.protagonist))
                }
            }
        }
    }

    /**
     * The session entry stored under [key], or null when no engine can read [value]. Every read of the bucket goes
     * through here: a damaged or foreign value is logged and read as no entry, so a join writes over it, a leave check
     * ignores it, and the watch keeps the key's last readable holder.
     */
    private fun readable(
        key: String,
        value: ByteArray,
    ): SessionEntry? =
        try {
            decodeSessionEntry(value)
        } catch (failure: IllegalArgumentException) {
            skipped(key, failure)
        } catch (failure: IOException) {
            // A cut off value ends the decoder's input early.
            skipped(key, failure)
        }

    private fun skipped(
        key: String,
        failure: Exception,
    ): SessionEntry? {
        log.warning("Skipped the unreadable value of session key $key: $failure")
        return null
    }

    /** The live session entries of [protagonist], or the first failed read. */
    private suspend fun KeyValueBucket.liveEntries(protagonist: Protagonist): LiveEntries {
        val keys =
            when (val listed = keys(protagonistKeys(protagonist))) {
                is KeyValueKeys.Listed -> listed.keys
                is KeyValueKeys.Failed -> return LiveEntries.Failed(listed.cause)
            }
        val entries =
            keys.mapNotNull { key ->
                when (val read = get(key)) {
                    is KeyValueRead.Found -> readable(key, read.entry.value)
                    KeyValueRead.Absent -> null
                    is KeyValueRead.Failed -> return LiveEntries.Failed(read.cause)
                }
            }
        return LiveEntries.Read(entries)
    }

    /**
     * Rewrites the held key every refresh. When another engine wrote it, this engine lets the session go; when it
     * expired while NATS was unreachable, the protagonist is still here, so the session starts again.
     */
    private suspend fun refresh(
        id: SessionId,
        slot: SessionSlot,
        initial: HeldSession,
        generation: Long,
    ) {
        var held = initial
        while (true) {
            delay(timings.refresh)
            val bucket = bucket() ?: continue
            when (val written = bucket.update(held.key, held.entry.encode(), timings.ttl, held.revision)) {
                is KeyValueWrite.Written -> {
                    held = held.copy(revision = written.revision)
                }

                KeyValueWrite.Conflict -> {
                    held = recover(bucket, held) ?: return slot.letGo(id, generation)
                }

                is KeyValueWrite.Failed -> {
                    Unit
                }
            }
            slot.held = held
        }
    }

    /** After a refresh conflict: null when another engine holds the session now, else the session written again. */
    private suspend fun recover(
        bucket: KeyValueBucket,
        held: HeldSession,
    ): HeldSession? =
        when (val read = bucket.get(held.key)) {
            is KeyValueRead.Found -> {
                val current = readable(held.key, read.entry.value) ?: held.entry
                if (current.holder != engine) null else held.copy(entry = current, revision = read.entry.revision)
            }

            KeyValueRead.Absent -> {
                val entry = held.entry.copy(since = clock.instant())
                bucket.create(held.key, entry.encode(), timings.ttl).heldAs(held.key, entry) ?: held
            }

            is KeyValueRead.Failed -> {
                held
            }
        }

    /** Shortens the key to the grace, unless another engine holds the session by now. */
    private suspend fun release(held: HeldSession) {
        while (true) {
            val bucket = bucket()
            if (bucket != null) {
                when (bucket.update(held.key, held.entry.encode(), timings.grace, held.revision)) {
                    is KeyValueWrite.Written, KeyValueWrite.Conflict -> return
                    is KeyValueWrite.Failed -> Unit
                }
            }
            delay(timings.retry)
        }
    }

    private suspend fun bucket(): KeyValueBucket? =
        when (val opened = buckets.filterNotNull().first().open(bucketName)) {
            is KeyValueOpen.Opened -> opened.bucket
            KeyValueOpen.Missing, is KeyValueOpen.Failed -> null
        }

    private fun KeyValueWrite.heldAs(
        key: String,
        entry: SessionEntry,
    ): HeldSession? = (this as? KeyValueWrite.Written)?.let { HeldSession(key, entry, it.revision) }

    /** Lets the session go after another engine took it, unless it was reported again since this refresher began. */
    private fun SessionSlot.letGo(
        id: SessionId,
        since: Long,
    ) {
        held = null
        refresher = null
        if (generation.get() == since) holding.release(id)
    }

    private sealed interface LiveEntries {
        data class Read(
            val entries: List<SessionEntry>,
        ) : LiveEntries

        data class Failed(
            val cause: Throwable,
        ) : LiveEntries
    }

    private class SessionSlot {
        val lock = Mutex()

        /** Counts the session's reporter calls, so a refresher that began before the last one leaves holding alone. */
        val generation = AtomicLong()
        var held: HeldSession? = null
        var refresher: Job? = null
    }

    private data class HeldSession(
        val key: String,
        val entry: SessionEntry,
        val revision: Long,
    )

    private companion object {
        val log: Logger = Logger.getLogger(SessionKeeper::class.java.name)
    }
}
