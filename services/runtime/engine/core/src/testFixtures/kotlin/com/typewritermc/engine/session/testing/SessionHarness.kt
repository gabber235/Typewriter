package com.typewritermc.engine.session.testing

import com.typewritermc.engine.session.HeldSessions
import com.typewritermc.engine.session.SessionEntry
import com.typewritermc.engine.session.SessionKeeper
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.encode
import com.typewritermc.engine.session.readSessionEntry
import com.typewritermc.engine.session.sessionKey
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
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
 * Realm does. Timings are short, so keys expire in seconds; the broker, not a fake, decides every expiry and conflict.
 */
class SessionHarness private constructor(
    private val server: NatsTestServer,
) : AutoCloseable {
    /** The Realm the engines belong to. */
    val realm: String = "realm"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val connections = mutableListOf<NatsConnection>()
    private val engines = mutableListOf<HarnessEngine>()

    /** A Minecraft player, a protagonist whose session id is its UUID. */
    fun player(): Pair<Protagonist, SessionId> {
        val uuid = UUID.randomUUID().toString()
        return Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid)) to SessionId(uuid)
    }

    /** Starts engine [id] of the Realm on a connection of its own. */
    suspend fun engine(
        id: String,
        timings: SessionTimings = SHORT,
    ): HarnessEngine {
        val connection = connect()
        val buckets = MutableStateFlow<KeyValueBuckets?>(NatsKeyValueBuckets(connection))
        val events = EmittedEvents()
        val keeper = SessionKeeper(EngineId(id), buckets, SessionsBucket.name(realm), timings, HeldSessions(), events, scope)
        return HarnessEngine(EngineId(id), keeper, events, connection).also(engines::add)
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

    /** [engine] reports that [protagonist] connected with session [id]; returns once the bucket names it the holder. */
    suspend fun joined(
        engine: HarnessEngine,
        protagonist: Protagonist,
        id: SessionId,
    ) {
        engine.keeper.connected(protagonist, id)
        eventually { entry(protagonist, id)?.holder == engine.id }
    }

    /** Writes an empty value no engine can read under [protagonist]'s session [id], as a damaged write would. */
    suspend fun unreadable(
        protagonist: Protagonist,
        id: SessionId,
    ) = unreadable(sessionKey(protagonist, id))

    /** Writes the first half of a real session entry under [protagonist]'s session [id], as a cut off write would. */
    suspend fun truncated(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        val whole = SessionEntry(protagonist, EngineId("engine-gone"), java.time.Instant.EPOCH).encode()
        val written = bucket().create(sessionKey(protagonist, id), whole.copyOf(whole.size / 2), SHORT.ttl)
        check(written is KeyValueWrite.Written) { "The truncated value was not written: $written" }
    }

    /** Writes an empty value no engine can read under [key] of the sessions bucket, as a damaged or foreign write would. */
    suspend fun unreadable(key: String) {
        val written = bucket().create(key, ByteArray(0), SHORT.ttl)
        check(written is KeyValueWrite.Written) { "The unreadable value was not written: $written" }
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
        engines.forEach { it.keeper.close() }
        scope.cancel()
        runBlocking { connections.forEach { it.shutdown() } }
        server.close()
    }

    companion object {
        /** The organization the harness's Realm belongs to. */
        const val ORGANIZATION: String = "organization"

        /** Seconds instead of minutes: refresh every 300 ms, live 2 s, a grace of 1 s. */
        val SHORT: SessionTimings =
            SessionTimings(refresh = 300.milliseconds, ttl = 2.seconds, grace = 1.seconds, retry = 100.milliseconds)

        /** A harness on a fresh nats-server with JetStream. */
        fun start(): SessionHarness = SessionHarness(NatsTestServer.startWithJetStream())
    }
}

/** One engine of the harness; [events] holds what its keeper emitted. */
class HarnessEngine(
    val id: EngineId,
    val keeper: SessionKeeper,
    val events: EmittedEvents,
    private val connection: NatsConnection,
) {
    /** The engine stops as a crash would: no further write, its connection gone. */
    suspend fun crash() {
        keeper.close()
        connection.shutdown()
    }
}
