package com.typewritermc.engine.session.testing

import com.typewritermc.engine.session.SessionEntry
import com.typewritermc.engine.session.SessionKeeper
import com.typewritermc.engine.session.SessionLeaseCodec
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.SessionValue
import com.typewritermc.engine.session.sessionKey
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.kv.LeaseEntry
import com.typewritermc.services.libs.communicator.kv.LeaseState
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import com.typewritermc.services.libs.communicator.testing.ScriptedBuckets
import com.typewritermc.services.libs.communicator.testing.VirtualLeases
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.flow.MutableStateFlow
import java.time.Instant
import java.util.UUID
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * Engines of one Realm keeping sessions in the Realm's sessions bucket on [store]: in memory on virtual time, where
 * every ordering and timing rule is set up exactly, or on a real nats-server, where the broker decides every expiry and
 * conflict for a story told end to end. Each engine reaches the bucket through its own connection, whose requests a
 * test may hold or fail, and keeps the sessions a test changes in its [HarnessEngine.online]. Closing stops every
 * engine and the store.
 */
class SessionHarness(
    val store: KeyValueStore,
    val timings: SessionTimings = SHORT,
) : AutoCloseable {
    /** The Realm the engines belong to. */
    val realm: String = "realm"

    private val bucket = SessionsBucket.name(realm)
    private val keepers = mutableListOf<SessionKeeper>()

    /** A Minecraft player's session, of a protagonist whose session id is its UUID. */
    fun player(): Session {
        val uuid = UUID.randomUUID().toString()
        return Session(Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid)), SessionId(uuid))
    }

    /** Creates the Realm's sessions bucket, as the Realm does when it starts. */
    suspend fun createBucket() = store.createBucket(SessionsBucket.declaration(realm))

    /** Starts engine [id] of the Realm on a connection of its own, already having the sessions in [online]. */
    suspend fun engine(
        id: String,
        online: Set<Session> = emptySet(),
    ): HarnessEngine {
        val buckets = store.connect()
        val sessions = OnlineSet(store.clock(), online)
        return HarnessEngine(EngineId(id), keeper(id, sessions, buckets), buckets, sessions)
    }

    /** Starts engine [id] of the Realm keeping the sessions its engine kind has in [online], through [buckets]. */
    suspend fun keeper(
        id: String,
        online: OnlineSessions,
        buckets: ScriptedBuckets? = null,
    ): SessionKeeper =
        SessionKeeper(EngineId(id), MutableStateFlow(buckets ?: store.connect()), bucket, timings, online, store.scope, store.clock())
            .also(keepers::add)

    /** The live entry of [protagonist]'s session [id], or null when there is none or no engine can read it. */
    suspend fun entry(
        protagonist: Protagonist,
        id: SessionId,
    ): SessionEntry? = store.read(sessionKey(protagonist, id), bucket)?.let(SessionLeaseCodec::decode)

    /** [session] connects to [engine]; returns once the bucket names it the holder. */
    suspend fun joined(
        engine: HarnessEngine,
        session: Session,
    ) {
        engine.online.join(session)
        store.eventually { entry(session.protagonist, session.id)?.holder == engine.id }
    }

    /** Writes an empty value no engine can read under [protagonist]'s session [id], as a damaged write would. */
    suspend fun unreadable(
        protagonist: Protagonist,
        id: SessionId,
    ) = store.write(sessionKey(protagonist, id), ByteArray(0), timings.lease.ttl, bucket)

    /** Writes the first half of a real session entry under [protagonist]'s session [id], as a cut off write would. */
    suspend fun truncated(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        val whole =
            SessionLeaseCodec.encode(
                LeaseEntry(LeaseState.Held(EngineId("engine-gone"), Instant.EPOCH), SessionValue(protagonist, Instant.EPOCH)),
            )
        store.write(sessionKey(protagonist, id), whole.copyOf(whole.size / 2), timings.lease.ttl, bucket)
    }

    /** The messaging of a new client of the store's broker, as a host lends it to its runtimes. */
    suspend fun messaging(): HostedMessagingSession =
        HostedMessagingSession(
            id = 1,
            organizationId = ORGANIZATION,
            communicator =
                Communicator(
                    store.transport(),
                    OpenTelemetry.noop().serviceTelemetry("session harness"),
                    ContextPropagators.noop(),
                ),
            buckets = store.connect(),
        )

    override fun close() {
        keepers.forEach { it.close() }
        store.close()
    }

    companion object {
        /** The organization the harness's Realm belongs to. */
        const val ORGANIZATION: String = "organization"

        /** The leases' short timings, for virtual time: refresh every 300 ms, live 2 s, a vacancy of 1 s. */
        val SHORT: SessionTimings = SessionTimings(VirtualLeases.SHORT)

        /**
         * For stories on a real broker: keys live minutes, so whatever must still be there is, while a vacancy of 1 s
         * lets what must end end soon.
         */
        val BROKER: SessionTimings =
            SessionTimings(LeaseTimings(refresh = 1.seconds, ttl = 5.minutes, vacancy = 1.seconds, retry = 100.milliseconds))
    }
}

/** One engine of a [SessionHarness]; [buckets] is its way to the sessions bucket and [online] the sessions it has. */
class HarnessEngine(
    val id: EngineId,
    val keeper: SessionKeeper,
    val buckets: ScriptedBuckets,
    val online: OnlineSet,
)
