package com.typewritermc.engine.session

import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.SessionReporter
import com.typewritermc.identity.Sessions
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueKeys
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
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
import java.time.Clock
import java.util.concurrent.ConcurrentHashMap
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
 */
class SessionKeeper(
    private val engine: EngineId,
    private val buckets: StateFlow<KeyValueBuckets?>,
    private val bucketName: String,
    private val timings: SessionTimings,
    parent: CoroutineScope,
    private val clock: Clock = Clock.systemUTC(),
) : SessionReporter,
    Sessions,
    AutoCloseable {
    private val scope = CoroutineScope(parent.coroutineContext + SupervisorJob(parent.coroutineContext[Job]))
    private val sessions = ConcurrentHashMap<SessionId, SessionSlot>()

    override fun connected(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        val slot = sessions.computeIfAbsent(id) { SessionSlot() }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            slot.lock.withLock {
                slot.refresher?.cancelAndJoin()
                val held = take(protagonist, id)
                slot.held = held
                slot.refresher = scope.launch { refresh(slot, held) }
            }
        }
    }

    override fun disconnected(id: SessionId) {
        val slot = sessions[id] ?: return
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
        val keys =
            when (val listed = bucket.keys(protagonistKeys(protagonist))) {
                is KeyValueKeys.Listed -> listed.keys
                is KeyValueKeys.Failed -> throw listed.cause
            }
        return keys.mapNotNullTo(linkedSetOf()) { key ->
            when (val read = bucket.get(key)) {
                is KeyValueRead.Found -> decodeSessionEntry(read.entry.value).holder
                KeyValueRead.Absent -> null
                is KeyValueRead.Failed -> throw read.cause
            }
        }
    }

    /** Stops every write and leaves the keys as they are. */
    override fun close() {
        scope.cancel()
    }

    /** Writes the session's key as held by this engine, keeping when it began, and retries until it succeeds. */
    private suspend fun take(
        protagonist: Protagonist,
        id: SessionId,
    ): HeldSession {
        val key = sessionKey(protagonist, id)
        while (true) {
            val bucket = bucket()
            if (bucket != null) {
                val written =
                    when (val read = bucket.get(key)) {
                        is KeyValueRead.Found -> {
                            val entry = decodeSessionEntry(read.entry.value).copy(holder = engine)
                            bucket.update(key, entry.encode(), timings.ttl, read.entry.revision).heldAs(key, entry)
                        }
                        KeyValueRead.Absent -> {
                            val entry = SessionEntry(protagonist, engine, clock.instant())
                            bucket.create(key, entry.encode(), timings.ttl).heldAs(key, entry)
                        }
                        is KeyValueRead.Failed -> null
                    }
                if (written != null) return written
            }
            delay(timings.retry)
        }
    }

    /**
     * Rewrites the held key every refresh. When another engine wrote it, this engine lets the session go; when it
     * expired while NATS was unreachable, the protagonist is still here, so the session starts again.
     */
    private suspend fun refresh(
        slot: SessionSlot,
        initial: HeldSession,
    ) {
        var held = initial
        while (true) {
            delay(timings.refresh)
            val bucket = bucket() ?: continue
            when (val written = bucket.update(held.key, held.entry.encode(), timings.ttl, held.revision)) {
                is KeyValueWrite.Written -> held = held.copy(revision = written.revision)
                KeyValueWrite.Conflict -> {
                    held = recover(bucket, held) ?: return slot.letGo()
                }
                is KeyValueWrite.Failed -> Unit
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
                val current = decodeSessionEntry(read.entry.value)
                if (current.holder != engine) null else held.copy(entry = current, revision = read.entry.revision)
            }
            KeyValueRead.Absent -> {
                val entry = held.entry.copy(since = clock.instant())
                bucket.create(held.key, entry.encode(), timings.ttl).heldAs(held.key, entry) ?: held
            }
            is KeyValueRead.Failed -> held
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

    private fun SessionSlot.letGo() {
        held = null
        refresher = null
    }

    private class SessionSlot {
        val lock = Mutex()
        var held: HeldSession? = null
        var refresher: Job? = null
    }

    private data class HeldSession(
        val key: String,
        val entry: SessionEntry,
        val revision: Long,
    )
}
