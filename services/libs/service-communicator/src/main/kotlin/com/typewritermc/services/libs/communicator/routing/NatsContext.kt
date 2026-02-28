package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.interfaces.Message
import protokt.v1.AbstractDeserializer
import protokt.v1.AbstractMessage
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

interface NatsContext {
    val message: Message
    val params: SubjectParams

    suspend fun reply(data: ByteArray)

    suspend fun send(subject: String, data: ByteArray)

    suspend fun request(
        subject: String,
        data: ByteArray,
        timeout: Duration = 5.seconds
    ): Message

    fun <T : AbstractMessage> receive(deserializer: AbstractDeserializer<T>): T

    suspend fun <T : AbstractMessage> reply(message: T)

    suspend fun <T : AbstractMessage> send(subject: String, message: T)

    suspend fun <T : AbstractMessage, R : AbstractMessage> request(
        subject: String,
        message: T,
        responseDeserializer: AbstractDeserializer<R>,
        timeout: Duration = 5.seconds
    ): R
}
