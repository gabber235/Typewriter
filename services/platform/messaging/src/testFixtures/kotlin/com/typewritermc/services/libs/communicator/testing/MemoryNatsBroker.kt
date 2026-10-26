package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsClientAdapter
import com.typewritermc.services.libs.communicator.nats.NatsClientConnectivity
import com.typewritermc.services.libs.communicator.nats.NatsClientMessage
import com.typewritermc.services.libs.communicator.nats.NatsClientSubscription
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import java.util.UUID
import kotlin.time.Duration

/** One message as the broker saw it, with framing headers readable by tests. */
data class BrokerMessage(
    val subject: String,
    val payload: ByteArray,
    val headers: Map<String, List<String>>,
    val replyTo: String?,
) {
    fun header(name: String): String? =
        headers.entries
            .firstOrNull { it.key.equals(name, ignoreCase = true) }
            ?.value
            ?.firstOrNull()
}

/**
 * An in memory stand in for one NATS server, so the real [NatsMessageTransport] runs unchanged in tests.
 *
 * Core publish and subscribe match subjects token by token with `*` and `>`, keep the order of each publisher's
 * messages and deliver to every matching subscription without blocking the publisher. [intercept] sees every
 * published message and returns what is delivered, so tests can drop, duplicate or alter messages. Queue groups
 * and permissions are not modelled.
 */
class MemoryNatsBroker(
    @Volatile var intercept: (BrokerMessage) -> List<BrokerMessage> = { listOf(it) },
) {
    private val lock = Any()
    private val subscriptions = mutableListOf<Pair<List<String>, Channel<NatsClientMessage>>>()
    private val history = mutableListOf<BrokerMessage>()

    /** How many subscriptions, including reply inboxes, are open. */
    val activeSubscriptionCount: Int get() = synchronized(lock) { subscriptions.size }

    /** Every message published so far, before interception, in publish order. */
    val published: List<BrokerMessage> get() = synchronized(lock) { history.toList() }

    /** A connected transport of one client of this broker. */
    suspend fun transport(limits: TransportLimits): NatsMessageTransport {
        val prefix = "_INBOX.${UUID.randomUUID().toString().replace("-", "")}."
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration("nats://memory", inboxPrefix = prefix) },
                { NatsAuthentication() },
                { _, _ -> Client() },
            )
        connection.connect()
        return NatsMessageTransport(connection, limits)
    }

    private fun publish(message: NatsClientMessage) {
        val seen =
            BrokerMessage(message.subject, message.payload?.toByteArray() ?: byteArrayOf(), message.headers.orEmpty(), message.replyTo)
        val targets =
            synchronized(lock) {
                history += seen
                intercept(seen).map { delivered ->
                    delivered to subscriptions.filter { (pattern, _) -> pattern.matches(delivered.subject.split('.')) }.map { it.second }
                }
            }
        for ((delivered, channels) in targets) {
            val native =
                NatsClientMessage(
                    subject = delivered.subject,
                    payload =
                        com.typewritermc.services.libs.communicator.transport.Payload
                            .copyOf(delivered.payload),
                    headers = delivered.headers,
                    replyTo = delivered.replyTo,
                    status = null,
                    statusDescription = null,
                )
            channels.forEach { it.trySend(native) }
        }
    }

    private inner class Client : NatsClientAdapter {
        override val connectivity = MutableStateFlow(NatsClientConnectivity.Connected)

        override suspend fun connect(): Result<Unit> = Result.success(Unit)

        override suspend fun disconnect() = Unit

        override suspend fun drain(timeout: Duration) = Unit

        override suspend fun flush() = Unit

        override suspend fun publish(message: NatsClientMessage) = this@MemoryNatsBroker.publish(message)

        override suspend fun subscribe(
            subject: String,
            queueGroup: String?,
        ): NatsClientSubscription {
            val channel = Channel<NatsClientMessage>(Channel.UNLIMITED)
            val entry = subject.split('.') to channel
            synchronized(lock) { subscriptions += entry }
            return object : NatsClientSubscription {
                override val messages: Flow<NatsClientMessage> = channel.receiveAsFlow()
                override val isActive: StateFlow<Boolean> = MutableStateFlow(true)

                override suspend fun unsubscribe() {
                    synchronized(lock) { subscriptions.remove(entry) }
                    channel.close()
                }
            }
        }
    }
}

private fun List<String>.matches(subject: List<String>): Boolean {
    for ((index, token) in withIndex()) {
        if (token == ">") return subject.size > index
        if (index >= subject.size || (token != "*" && token != subject[index])) return false
    }
    return size == subject.size
}
