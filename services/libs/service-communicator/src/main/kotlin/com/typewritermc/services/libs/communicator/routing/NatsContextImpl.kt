package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.interfaces.Message
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import io.github.oshai.kotlinlogging.KotlinLogging
import io.opentelemetry.api.trace.Span
import protokt.v1.AbstractDeserializer
import protokt.v1.AbstractMessage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.time.Duration

private val logger = KotlinLogging.logger {}

class NatsContextImpl(
    override val message: Message,
    override val params: SubjectParams,
    private val messageBus: MessageBus,
    override val span: Span
) : NatsContext {

    override suspend fun reply(data: ByteArray) {
        val replyTo = message.replyTo
        if (replyTo == null) {
            span.addEvent("reply_failed_no_replyTo")
            span.setAttribute("error.reason", "no replyTo subject")
            return
        }
        messageBus.publish(replyTo, data)
    }

    override suspend fun send(subject: String, data: ByteArray) {
        messageBus.publish(subject, data)
    }

    override suspend fun request(
        subject: String,
        data: ByteArray,
        timeout: Duration
    ): Message {
        return messageBus.request(subject, data, timeout)
    }

    override fun <T : AbstractMessage> receive(deserializer: AbstractDeserializer<T>): T {
        val data = message.data
            ?: throw IllegalStateException("Cannot receive: message data is null for ${message.subject}")
        return deserializer.deserialize(ByteArrayInputStream(data))
    }

    override suspend fun <T : AbstractMessage> reply(message: T) {
        val bytes = ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
        reply(bytes)
    }

    override suspend fun <T : AbstractMessage> send(subject: String, message: T) {
        val bytes = ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
        send(subject, bytes)
    }

    override suspend fun <T : AbstractMessage, R : AbstractMessage> request(
        subject: String,
        message: T,
        responseDeserializer: AbstractDeserializer<R>,
        timeout: Duration
    ): R {
        val requestBytes = ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
        val response = messageBus.request(subject, requestBytes, timeout)
        val responseData = response.data
            ?: throw IllegalStateException("Cannot deserialize response: response data is null for $subject")
        return responseDeserializer.deserialize(ByteArrayInputStream(responseData))
    }
}
