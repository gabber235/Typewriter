package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.coroutineScope
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** Limits of the broker tests: 512 KiB chunks, and replies that stream without credit. */
val brokerLimits: TransportLimits =
    TransportLimits(
        chunkBytes = 512 * 1024,
        windowFrames = 8,
        requestMaxBytes = 512L * 1024,
        replyMaxBytes = 32L * 1024 * 1024,
        frameInactivity = 30.seconds,
        replyTtl = 5.minutes,
        replyCredit = false,
    )

/** The connections of one test, each shut down when the test ends. */
class BrokerClients(
    scope: CoroutineScope,
    private val url: String,
) : CoroutineScope by scope {
    val connections = mutableListOf<NatsConnection>()

    /** A transport on a new connection to the broker; the connection must succeed. */
    suspend fun transport(inboxPrefix: String = "_INBOX."): NatsMessageTransport {
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration(url, inboxPrefix = inboxPrefix, maxReconnects = 0) },
                { NatsAuthentication() },
            )
        connections += connection
        val connected = connection.connect()
        check(connected == NatsLifecycleResult.Success) { "The broker connection failed with $connected" }
        return NatsMessageTransport(connection, brokerLimits)
    }
}

/** Runs [block] with [BrokerClients] for the broker at [url], shutting every connection down afterwards. */
suspend fun onBroker(
    url: String,
    block: suspend BrokerClients.() -> Unit,
) = coroutineScope {
    val clients = BrokerClients(this, url)
    try {
        clients.block()
    } finally {
        clients.connections.forEach { it.shutdown() }
    }
}

/** The subscription a successful subscribe returned, or the broker's failure as an [AssertionError]. */
fun TransportResult<TransportSubscription>.requireSubscription(): TransportSubscription = requireSuccess()

/** The value of a successful result, or the broker's failure as an [AssertionError]. */
fun <T> TransportResult<T>.requireSuccess(): T =
    when (this) {
        is TransportResult.Success -> value
        is TransportResult.Failure -> throw AssertionError("The broker answered with $error", error.cause)
    }

/** The value of a successful transport result; fails the test with the result's message when it is a failure. */
fun <T> TransportResult<T>.success(): T = (this as? TransportResult.Success)?.value ?: error("Expected a success, got $this")
