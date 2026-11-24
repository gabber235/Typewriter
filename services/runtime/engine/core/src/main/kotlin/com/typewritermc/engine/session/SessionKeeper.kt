package com.typewritermc.engine.session

import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.SessionReporter
import com.typewritermc.identity.Sessions
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.kv.Leases
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow
import java.time.Clock
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration.Companion.seconds

/** How long each engine kind's session keys live; a key left behind by a quit lives the grace, the kind's time to come back. */
object SessionTimings {
    /** A Minecraft player: 20 second refresh, 60 second time to live, 10 second grace. */
    val MINECRAFT: LeaseTimings = LeaseTimings(refresh = 20.seconds, ttl = 60.seconds, grace = 10.seconds)

    /** A panel tab, refreshed by its heartbeat: 45 second time to live, 10 second grace after it leaves. */
    val PANEL: LeaseTimings = LeaseTimings(refresh = 15.seconds, ttl = 45.seconds, grace = 10.seconds)
}

/**
 * Keeps this engine's sessions in the Realm's sessions bucket, one lease per session. A connect claims the session's
 * key with the instant it connected; of two engines claiming one session, the later connection holds it, so a server
 * move works in either order of join and quit and a late write of an engine the protagonist left never displaces the
 * engine it moved to. A quit lets the key live the grace. Closing stops every write and leaves the keys, so a reloaded
 * engine takes them over and a crashed one lets them expire.
 *
 * Reporter calls return at once and count in [holds] at once, without the network; their writes run on [parent]'s
 * dispatcher, per session in the order of the calls.
 */
class SessionKeeper(
    engine: EngineId,
    buckets: StateFlow<KeyValueBuckets?>,
    bucketName: String,
    timings: LeaseTimings,
    parent: CoroutineScope,
    private val clock: Clock = Clock.systemUTC(),
    openTelemetry: OpenTelemetry = OpenTelemetry.noop(),
) : SessionReporter,
    Sessions,
    AutoCloseable {
    private val leases = Leases(engine.value, buckets, bucketName, SessionLeaseCodec, timings, parent, clock, openTelemetry)
    private val connected = ConcurrentHashMap<SessionId, Protagonist>()

    override fun connected(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        connected[id] = protagonist
        leases.claim(sessionKey(protagonist, id)) { previous -> SessionValue(protagonist, previous?.since ?: clock.instant()) }
    }

    override fun disconnected(id: SessionId) {
        val protagonist = connected.remove(id) ?: return
        leases.release(sessionKey(protagonist, id))
    }

    override suspend fun holders(protagonist: Protagonist): Set<EngineId> =
        leases.entries(protagonistKeys(protagonist)).mapTo(linkedSetOf()) { EngineId(it.holder) }

    /** Whether this engine holds a session of [protagonist]: connected here, and not taken over by a later connection. */
    fun holds(protagonist: Protagonist): Boolean =
        connected.any { (id, connectedAs) -> connectedAs == protagonist && leases.holds(sessionKey(protagonist, id)) }

    /** Stops every write and leaves the keys as they are. */
    override fun close() = leases.close()
}
