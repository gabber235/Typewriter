package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.NatsKeyValueBuckets
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsClientMessage
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

private val bucketNumbers = AtomicInteger()

/**
 * A key value store the bucket contract runs against, so the memory buckets that keeper tests use behave as a real
 * JetStream store does. Each store lets a key's time to live pass its own way: the memory store moves its clock, the
 * broker store waits for the broker, bounded far above the time to live, so a loaded runner never misses the window.
 */
sealed interface KeyValueStore : AutoCloseable {
    val name: String
    val buckets: KeyValueBuckets

    /** Creates a bucket no other case of this store touches. */
    suspend fun freshBucket(): KeyValueBucket {
        val name = "contract-${bucketNumbers.incrementAndGet()}"
        val opened = buckets.ensure(KeyValueBucketDeclaration(name, markerTtl = 1.seconds))
        return checkNotNull(opened as? KeyValueOpen.Opened) { "Bucket $name did not open: $opened" }.bucket
    }

    /** Lets [ttl] pass and returns once [condition] holds; fails when it never does. */
    suspend fun outlive(
        ttl: Duration,
        condition: suspend () -> Boolean,
    )

    /** Buckets in memory on a clock the store moves itself. */
    class Memory : KeyValueStore {
        private var now = Duration.ZERO
        override val name: String = "memory"
        override val buckets: KeyValueBuckets = MemoryKeyValueBuckets { now }

        override suspend fun outlive(
            ttl: Duration,
            condition: suspend () -> Boolean,
        ) {
            now += ttl
            check(condition()) { "The condition did not hold once $ttl passed" }
        }

        override fun close() = Unit
    }

    /** Buckets on a fresh nats-server with JetStream, through the client production uses. */
    class Broker private constructor(
        private val server: NatsTestServer,
        private val connection: NatsConnection,
    ) : KeyValueStore {
        override val name: String = "nats-server"
        override val buckets: KeyValueBuckets = NatsKeyValueBuckets(connection)

        override suspend fun outlive(
            ttl: Duration,
            condition: suspend () -> Boolean,
        ) {
            withTimeout(ttl + EXPIRY_BOUND) { while (!condition()) delay(50.milliseconds) }
        }

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
                        if (it.subject ==
                            "$subjects.$key"
                        ) {
                            count++
                        }
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

        override fun close() {
            runBlocking { connection.shutdown() }
            server.close()
        }

        companion object {
            /** How long past a time to live the broker may take to expire a key before the contract fails. */
            private val EXPIRY_BOUND = 30.seconds

            /** The key [publishesTo] publishes last to know every earlier publish arrived. */
            private const val MARKER = "publishes-counted"

            /** A store on a nats-server started for it. */
            fun start(): Broker {
                val server = NatsTestServer.startWithJetStream()
                val connection =
                    NatsConnection(
                        { NatsConnectionConfiguration(server.url, maxReconnects = 0) },
                        { NatsAuthentication() },
                    )
                val connected = runBlocking { connection.connect() }
                check(connected == NatsLifecycleResult.Success) { "The broker connection failed with $connected" }
                return Broker(server, connection)
            }
        }
    }
}
