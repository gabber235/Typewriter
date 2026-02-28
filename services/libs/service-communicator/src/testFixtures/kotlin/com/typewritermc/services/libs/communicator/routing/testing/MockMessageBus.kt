package com.typewritermc.services.libs.communicator.routing.testing

import com.typewritermc.services.libs.communicator.interfaces.Message
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.interfaces.Subscription
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlin.time.Duration

class MockMessageBus : MessageBus {
    private val subscriptions = mutableMapOf<String, Channel<Message>>()
    private val publishedMessages = mutableListOf<Message>()
    private val requestHandlers = mutableMapOf<String, suspend (ByteArray) -> ByteArray>()

    val published: List<Message> get() = publishedMessages.toList()

    override suspend fun request(subject: String, data: ByteArray, timeout: Duration): Message {
        val handler = requestHandlers[subject]
        if (handler != null) {
            val responseData = handler(data)
            return Message(subject = "reply", data = responseData)
        }
        return Message(subject = "reply", data = null)
    }

    override suspend fun subscribe(subject: String): Subscription {
        val channel = Channel<Message>(Channel.UNLIMITED)
        subscriptions[subject] = channel
        return MockSubscription(channel)
    }

    override suspend fun publish(subject: String, data: ByteArray) {
        publishedMessages.add(Message(subject = subject, data = data, replyTo = null))
    }

    suspend fun simulateMessage(subject: String, data: ByteArray, replyTo: String? = null) {
        val message = Message(subject = subject, data = data, replyTo = replyTo)
        subscriptions.forEach { (pattern, channel) ->
            if (subjectMatchesPattern(subject, pattern)) {
                channel.send(message)
            }
        }
    }

    fun onRequest(subject: String, handler: suspend (ByteArray) -> ByteArray) {
        requestHandlers[subject] = handler
    }

    fun clear() {
        publishedMessages.clear()
        subscriptions.values.forEach { it.close() }
        subscriptions.clear()
        requestHandlers.clear()
    }

    private fun subjectMatchesPattern(subject: String, pattern: String): Boolean {
        val subjectParts = subject.split(".")
        val patternParts = pattern.split(".")

        if (subjectParts.size != patternParts.size) return false

        return subjectParts.zip(patternParts).all { (s, p) ->
            p == "*" || p == s
        }
    }

    private class MockSubscription(private val channel: Channel<Message>) : Subscription {
        override val messages: Flow<Message> = channel.receiveAsFlow()

        override suspend fun unsubscribe() {
            channel.close()
        }
    }
}
