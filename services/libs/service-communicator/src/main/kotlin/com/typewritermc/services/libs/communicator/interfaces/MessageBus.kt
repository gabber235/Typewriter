package com.typewritermc.services.libs.communicator.interfaces

import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow

data class Message(
    val subject: String,
    val data: ByteArray?,
    val replyTo: String? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as Message
        return subject == other.subject && data.contentEquals(other.data) && replyTo == other.replyTo
    }

    override fun hashCode(): Int {
        var result = subject.hashCode()
        result = 31 * result + (data?.contentHashCode() ?: 0)
        result = 31 * result + (replyTo?.hashCode() ?: 0)
        return result
    }
}

interface Subscription {
    val messages: Flow<Message>
    suspend fun unsubscribe()
}

interface MessageBus {
    suspend fun request(
        subject: String,
        data: ByteArray,
        timeoutMs: Long = 10_000
    ): Message

    suspend fun subscribe(subject: String): Subscription

    suspend fun publish(subject: String, data: ByteArray)
}
