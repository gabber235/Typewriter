package com.typewritermc.engine.session.testing

import com.typewritermc.engine.session.SessionEntry
import com.typewritermc.engine.session.SessionKeeper
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.readSessionEntry
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.kv.NatsKeyValueBuckets
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.brokerLimits
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.util.UUID
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Engines of one Realm on a real nats-server with JetStream, as in production but in one process: each engine keeps its
 * sessions through its own connection, and the Realm's sessions bucket exists once [createBucket] made it the way the
 * Realm does. The broker, not a fake, decides every expiry and conflict, so a check waits for it with [eventually];
 * keeper rules are proven on virtual time with VirtualSessions instead.
 */
class SessionHarness private constructor(
    private val server: NatsTestServer,
) : AutoCloseable {
    /** The Realm the engines belong to. */
    val realm: String = "realm"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val connections = mutableListOf<NatsConnection>()
    private val keepers = mutableListOf<SessionKeeper>()

    /** A Minecraft player's session, of a protagonist whose session id is its UUID. */
    fun player(): Session {
        val uuid = UUID.randomUUID().toString()
        return Session(Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid)), SessionId(uuid))
    }

    /** Starts engine [id] of the Realm on a connection of its own, whose sessions a test changes through its [HarnessEngine.online]. */
    suspend fun engine(
        id: String,
        timings: SessionTimings = SHORT,
    ): HarnessEngine {
        val online = OnlineSet()
        return HarnessEngine(EngineId(id), keeper(id, timings, online), online)
    }

    /** Starts engine [id] of the Realm on a connection of its own, keeping the sessions its engine kind has in [online]. */
    suspend fun keeper(
        id: String,
        timings: SessionTimings,
        online: OnlineSessions,
    ): SessionKeeper {
        val buckets = MutableStateFlow<KeyValueBuckets?>(NatsKeyValueBuckets(connect()))
        return SessionKeeper(EngineId(id), buckets, SessionsBucket.name(realm), timings, online, scope).also(keepers::add)
    }

    /** Creates the Realm's sessions bucket, as the Realm does when it starts. */
    suspend fun createBucket() {
        val opened = NatsKeyValueBuckets(connect()).ensure(SessionsBucket.declaration(realm))
        check(opened is KeyValueOpen.Opened) { "The sessions bucket could not be created: $opened" }
    }

    /** The live entry of [protagonist]'s session [id], or null when there is none. */
    suspend fun entry(
        protagonist: Protagonist,
        id: SessionId,
    ): SessionEntry? = bucket().readSessionEntry(protagonist, id)

    /** [session] connects to [engine]; returns once the bucket names it the holder. */
    suspend fun joined(
        engine: HarnessEngine,
        session: Session,
    ) {
        engine.online.join(session)
        eventually { entry(session.protagonist, session.id)?.holder == engine.id }
    }

    /** Waits until [condition] holds, polling the broker, and fails after [within]. */
    suspend fun eventually(
        within: Duration = 10.seconds,
        condition: suspend () -> Boolean,
    ) {
        withTimeout(within) {
            while (!condition()) delay(50.milliseconds)
        }
    }

    /** The messaging of a new connection to the broker, as a host lends it to its runtimes. */
    suspend fun messaging(): HostedMessagingSession {
        val connection = connect()
        val telemetry = OpenTelemetry.noop()
        return HostedMessagingSession(
            id = 1,
            organizationId = ORGANIZATION,
            communicator =
                Communicator(
                    NatsMessageTransport(connection, brokerLimits),
                    telemetry.serviceTelemetry("session harness"),
                    ContextPropagators.noop(),
                ),
            buckets = NatsKeyValueBuckets(connection),
        )
    }

    private var observer: KeyValueBucket? = null

    private suspend fun bucket(): KeyValueBucket =
        observer ?: when (val opened = NatsKeyValueBuckets(connect()).open(SessionsBucket.name(realm))) {
            is KeyValueOpen.Opened -> opened.bucket.also { observer = it }
            else -> error("The sessions bucket is not open: $opened")
        }

    private suspend fun connect(): NatsConnection {
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration(server.url, maxReconnects = 0) },
                { NatsAuthentication() },
            )
        val connected = connection.connect()
        check(connected == NatsLifecycleResult.Success) { "The broker connection failed with $connected" }
        connections += connection
        return connection
    }

    override fun close() {
        keepers.forEach { it.close() }
        scope.cancel()
        runBlocking { connections.forEach { it.shutdown() } }
        server.close()
    }

    companion object {
        /** The organization the harness's Realm belongs to. */
        const val ORGANIZATION: String = "organization"

        /** Seconds instead of minutes: refresh every 300 ms, live 2 s, a vacancy of 1 s. */
        val SHORT: SessionTimings =
            SessionTimings(LeaseTimings(refresh = 300.milliseconds, ttl = 2.seconds, vacancy = 1.seconds, retry = 100.milliseconds))

        /** A harness on a fresh nats-server with JetStream. */
        fun start(): SessionHarness = SessionHarness(NatsTestServer.startWithJetStream())
    }
}

/** One engine of the harness; [online] is the sessions it has. */
class HarnessEngine(
    val id: EngineId,
    val keeper: SessionKeeper,
    val online: OnlineSet,
)
