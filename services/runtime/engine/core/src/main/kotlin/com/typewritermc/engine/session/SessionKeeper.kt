package com.typewritermc.engine.session

import com.typewritermc.identity.EngineId
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.Sessions
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.kv.Leases
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.Clock
import kotlin.time.Duration.Companion.seconds

/**
 * How an engine kind keeps its sessions: the [lease] timings of their keys. A session left by a quit stays vacant for
 * the lease's vacancy, the kind's time for a takeover.
 */
data class SessionTimings(
    val lease: LeaseTimings,
) {
    companion object {
        /** A Minecraft player: 20 second refresh, 60 second time to live, 10 second vacancy. */
        val MINECRAFT: SessionTimings = SessionTimings(LeaseTimings(refresh = 20.seconds, ttl = 60.seconds, vacancy = 10.seconds))

        /** A panel tab, refreshed by its heartbeat: 45 second time to live, 45 second vacancy after it leaves, the presence expiry. */
        val PANEL: SessionTimings = SessionTimings(LeaseTimings(refresh = 15.seconds, ttl = 45.seconds, vacancy = 45.seconds))
    }
}

/**
 * Keeps this engine's sessions in the Realm's sessions bucket, exactly the sessions its engine kind has in [online],
 * one lease per session. A session added to the set claims its key with the instant it connected; of two engines
 * claiming one session, the later connection holds it, so a server move works in either order of join and quit and a
 * late write of an engine the protagonist left never displaces the engine it moved to. A session removed from the set
 * is left vacant at once: alive for the vacancy so another engine or a rejoin takes it over, but held by nobody, and
 * this engine never refreshes it again. Closing stops every write and leaves the keys, so a reloaded engine takes over
 * the sessions it starts with and a crashed one lets them expire.
 *
 * The set may change on any thread; the writes run on [parent]'s dispatcher, per session in the order the set changed.
 * A session added and removed again before the keeper saw the set is never written.
 */
class SessionKeeper(
    engine: EngineId,
    buckets: StateFlow<KeyValueBuckets?>,
    bucketName: String,
    timings: SessionTimings,
    online: OnlineSessions,
    parent: CoroutineScope,
    private val clock: Clock = Clock.systemUTC(),
    openTelemetry: OpenTelemetry = OpenTelemetry.noop(),
) : Sessions,
    AutoCloseable {
    private val leases = Leases(engine, buckets, bucketName, SessionLeaseCodec, timings.lease, parent, clock, openTelemetry)

    private val keeping: Job =
        parent.launch(start = CoroutineStart.UNDISPATCHED) {
            var kept = emptySet<Session>()
            online.sessions.collect { current ->
                (kept - current).forEach { leases.release(it.key) }
                (current - kept).forEach { session ->
                    leases.claim(session.key) { previous -> SessionValue(session.protagonist, previous?.since ?: clock.instant()) }
                }
                kept = current
            }
        }

    override suspend fun holders(protagonist: Protagonist): Set<EngineId> =
        leases.entries(protagonistKeys(protagonist)).mapNotNullTo(linkedSetOf()) { it.holder }

    /** Stops every write and leaves the keys as they are. */
    override fun close() {
        keeping.cancel()
        leases.close()
    }
}

private val Session.key: String get() = sessionKey(protagonist, id)
