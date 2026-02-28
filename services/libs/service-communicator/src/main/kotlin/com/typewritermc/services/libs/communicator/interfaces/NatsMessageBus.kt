package com.typewritermc.services.libs.communicator.interfaces

import com.typewritermc.services.libs.utils.StateProvider
import com.typewritermc.services.libs.utils.require
import io.natskt.api.NatsClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlin.time.Duration

class NatsMessageBus(private val natsClientProvider: StateProvider<NatsClient?>) : MessageBus {

    override suspend fun request(
        subject: String,
        data: ByteArray,
        timeout: Duration
    ): Message {
        val client = natsClientProvider.require()
        val response = client.request(subject, data, timeoutMs = timeout.inWholeMilliseconds)
        return Message(
            subject = response.subject.toString(),
            data = response.data,
            replyTo = response.replyTo?.toString()
        )
    }

    override suspend fun subscribe(subject: String): Subscription {
        val client = natsClientProvider.require()
        val natsSubscription = client.subscribe(subject)
        return NatsSubscription(natsSubscription)
    }

    override suspend fun publish(subject: String, data: ByteArray) {
        val client = natsClientProvider.require()
        client.publish(subject, data)
    }
}

private class NatsSubscription(
    private val subscription: io.natskt.api.Subscription
) : Subscription {

    override val messages: Flow<Message> = subscription.messages.map { msg ->
        Message(
            subject = msg.subject.toString(),
            data = msg.data,
            replyTo = msg.replyTo?.toString()
        )
    }

    override suspend fun unsubscribe() {
        subscription.unsubscribe()
    }
}
