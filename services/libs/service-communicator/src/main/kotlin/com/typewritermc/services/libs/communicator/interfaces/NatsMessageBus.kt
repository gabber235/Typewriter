package com.typewritermc.services.libs.communicator.interfaces

import io.natskt.api.NatsClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class NatsMessageBus(private val natsClient: NatsClient) : MessageBus {

    override suspend fun request(
        subject: String,
        data: ByteArray,
        timeoutMs: Long
    ): Message {
        val response = natsClient.request(subject, data, timeoutMs = timeoutMs)
        return Message(
            subject = response.subject.toString(),
            data = response.data,
            replyTo = response.replyTo?.toString()
        )
    }

    override suspend fun subscribe(subject: String): Subscription {
        val natsSubscription = natsClient.subscribe(subject)
        return NatsSubscription(natsSubscription)
    }

    override suspend fun publish(subject: String, data: ByteArray) {
        natsClient.publish(subject, data)
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
