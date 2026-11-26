package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import com.typewritermc.services.libs.communicator.kv.NatsKeyValueBuckets
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsClientMessage
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.testTimeSource
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import java.time.Clock
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlin.time.toJavaDuration

private val bucketNumbers = AtomicInteger()

/**
 * A key value store and the broker around it, for the holders and engines a test starts on it: in [Memory] on virtual
 * time, or on a real nats-server through the client production uses ([Broker]). One test kit runs on either, so the
 * same steps prove rules exactly on virtual time and tell a story end to end through the broker. The bucket contract
 * runs against both, so the memory store behaves as a real JetStream store does.
 *
 * Holders run in [scope] and read [clock] and [time]. Each holder reaches the store through its own [connect], whose
 * requests the test may hold or fail. Time passes the store's own way: [advance] and [settle] move virtual time in
 * memory and wait on the broker; [eventually] waits until a condition holds, bounded.
 */
sealed interface KeyValueStore : AutoCloseable {
    val name: String

    /** The store as an observer outside every holder sees it. */
    val buckets: KeyValueBuckets

    /** Where holders and engines of a test on this store run. */
    val scope: CoroutineScope

    /** The time holders measure intervals on. */
    val time: TimeSource.WithComparableMarks

    /** A clock on the store's time, [ahead] of the store's own. */
    fun clock(ahead: Duration = Duration.ZERO): Clock

    /** One holder's own way to the store, whose requests the test may hold or fail. */
    suspend fun connect(): ScriptedBuckets

    /** A message transport of one client of the broker around the store. */
    suspend fun transport(): MessageTransport

    /** Lets [time] pass for every holder and runs everything due by then. */
    suspend fun advance(time: Duration)

    /** Runs everything due now, without letting time pass. */
    suspend fun settle()

    /** Returns once [condition] holds; fails when it does not within [within]. */
    suspend fun eventually(
        within: Duration = 10.seconds,
        condition: suspend () -> Boolean,
    )

    /** Lets [ttl] pass and returns once [condition] holds; fails when it never does. */
    suspend fun outlive(
        ttl: Duration,
        condition: suspend () -> Boolean,
    )

    /** Creates [declaration]'s bucket, as its owner does; until then every holder finds it missing. */
    suspend fun createBucket(declaration: KeyValueBucketDeclaration) {
        val opened = buckets.ensure(declaration)
        check(opened is KeyValueOpen.Opened) { "Bucket ${declaration.name} did not open: $opened" }
    }

    /** Creates a bucket no other case of this store touches. */
    suspend fun freshBucket(): KeyValueBucket {
        val name = "contract-${bucketNumbers.incrementAndGet()}"
        val opened = buckets.ensure(KeyValueBucketDeclaration(name, markerTtl = 1.seconds))
        return checkNotNull(opened as? KeyValueOpen.Opened) { "Bucket $name did not open: $opened" }.bucket
    }

    /** The raw value under [key] in [bucket], or null when no live entry is there. */
    suspend fun read(
        key: String,
        bucket: String,
    ): ByteArray? {
        val opened = buckets.open(bucket) as? KeyValueOpen.Opened ?: return null
        return (opened.bucket.get(key) as? KeyValueRead.Found)?.entry?.value
    }

    /** Writes [value] under [key] of [bucket] with [ttl], as a writer outside the holders would. */
    suspend fun write(
        key: String,
        value: ByteArray,
        ttl: Duration,
        bucket: String,
    ) {
        val opened = buckets.open(bucket) as KeyValueOpen.Opened
        check(opened.bucket.create(key, value, ttl) is KeyValueWrite.Written)
    }

    /**
     * Buckets and a broker in memory on the virtual time of [test]: nothing waits on wall clock time, [advance] moves
     * every clock, every refresh and every expiry together, and [settle] runs what is due now.
     */
    class Memory(
        private val test: TestScope = TestScope(),
    ) : KeyValueStore {
        private val broker = MemoryNatsBroker()
        override val name: String = "memory"
        override val buckets: KeyValueBuckets = MemoryKeyValueBuckets { test.testScheduler.currentTime.milliseconds }
        override val scope: CoroutineScope get() = test.backgroundScope
        override val time: TimeSource.WithComparableMarks get() = test.testTimeSource

        override fun clock(ahead: Duration): Clock = VirtualClock(ahead)

        override suspend fun connect(): ScriptedBuckets = ScriptedBuckets(buckets)

        override suspend fun transport(): MessageTransport = broker.transport(brokerLimits)

        override suspend fun advance(time: Duration) {
            test.testScheduler.advanceTimeBy(time.inWholeMilliseconds)
            test.runCurrent()
        }

        override suspend fun settle() = test.runCurrent()

        override suspend fun eventually(
            within: Duration,
            condition: suspend () -> Boolean,
        ) {
            settle()
            var waited = Duration.ZERO
            while (!condition()) {
                check(waited < within) { "The condition did not hold within $within" }
                advance(STEP)
                waited += STEP
            }
        }

        override suspend fun outlive(
            ttl: Duration,
            condition: suspend () -> Boolean,
        ) {
            advance(ttl)
            check(condition()) { "The condition did not hold once $ttl passed" }
        }

        override fun close() = Unit

        private inner class VirtualClock(
            private val ahead: Duration,
        ) : Clock() {
            override fun getZone() = ZoneOffset.UTC

            override fun withZone(zone: ZoneId?): Clock = this

            override fun instant(): Instant = START.plusMillis(test.testScheduler.currentTime).plus(ahead.toJavaDuration())
        }

        companion object {
            /** Where every virtual clock starts. */
            val START: Instant = Instant.parse("2026-01-01T00:00:00Z")

            /** How far [eventually] moves virtual time between two looks. */
            private val STEP = 10.milliseconds
        }
    }

    /** Buckets on a fresh nats-server with JetStream, through the client production uses, on the wall clock. */
    class Broker private constructor(
        private val server: NatsTestServer,
        private val connection: NatsConnection,
    ) : KeyValueStore {
        private val connections = mutableListOf(connection)
        override val name: String = "nats-server"
        override val buckets: KeyValueBuckets = NatsKeyValueBuckets(connection)
        override val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        override val time: TimeSource.WithComparableMarks = TimeSource.Monotonic

        override fun clock(ahead: Duration): Clock = Clock.offset(Clock.systemUTC(), ahead.toJavaDuration())

        override suspend fun connect(): ScriptedBuckets = ScriptedBuckets(NatsKeyValueBuckets(newConnection()))

        override suspend fun transport(): MessageTransport = NatsMessageTransport(newConnection(), brokerLimits)

        override suspend fun advance(time: Duration) = delay(time)

        override suspend fun settle() = yield()

        override suspend fun eventually(
            within: Duration,
            condition: suspend () -> Boolean,
        ) {
            withTimeout(within) { while (!condition()) delay(POLL) }
        }

        override suspend fun outlive(
            ttl: Duration,
            condition: suspend () -> Boolean,
        ) = eventually(ttl + EXPIRY_BOUND, condition)

        /**
         * How many messages the store's own client published to [key] of [bucket] while [during] ran, counted by a
         * subscription on the key's subject, which sees every publish, also one the stream rejects.
         */
        suspend fun publishesTo(
            bucket: String,
            key: String,
            during: suspend () -> Unit,
        ): Int =
            coroutineScope {
                val client = checkNotNull(connection.connectedClient()) { "The store's connection is not connected" }
                val subjects = "\$KV.$bucket"
                val subscription = client.subscribe("$subjects.>", queueGroup = null)
                subscription.isActive.first { it }
                val counted = CompletableDeferred<Int>()
                launch(start = CoroutineStart.UNDISPATCHED) {
                    var count = 0
                    subscription.messages.takeWhile { it.subject != "$subjects.$MARKER" }.collect {
                        if (it.subject == "$subjects.$key") count++
                    }
                    counted.complete(count)
                }
                client.flush()
                during()
                // The server delivers this client's publishes in order, so the marker comes after every one before it.
                client.publish(
                    NatsClientMessage(
                        "$subjects.$MARKER",
                        payload = null,
                        headers = null,
                        replyTo = null,
                        status = null,
                        statusDescription = null,
                    ),
                )
                counted.await().also { subscription.unsubscribe() }
            }

        private suspend fun newConnection(): NatsConnection = connect(server).also { synchronized(connections) { connections += it } }

        override fun close() {
            scope.cancel()
            runBlocking { synchronized(connections) { connections.toList() }.forEach { it.shutdown() } }
            server.close()
        }

        companion object {
            /** How long past a time to live the broker may take to expire a key before a wait fails. */
            private val EXPIRY_BOUND = 30.seconds

            /** How often [eventually] looks again. */
            private val POLL = 50.milliseconds

            /** The key [publishesTo] publishes last to know every earlier publish arrived. */
            private const val MARKER = "publishes-counted"

            /** A store on a nats-server started for it. */
            fun start(): Broker {
                val server = NatsTestServer.startWithJetStream()
                return Broker(server, runBlocking { connect(server) })
            }

            private suspend fun connect(server: NatsTestServer): NatsConnection {
                val connection =
                    NatsConnection(
                        { NatsConnectionConfiguration(server.url, maxReconnects = 0) },
                        { NatsAuthentication() },
                    )
                val connected = connection.connect()
                check(connected == NatsLifecycleResult.Success) { "The broker connection failed with $connected" }
                return connection
            }
        }
    }
}
