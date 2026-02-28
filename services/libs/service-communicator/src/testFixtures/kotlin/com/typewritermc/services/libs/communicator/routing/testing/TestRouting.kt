package com.typewritermc.services.libs.communicator.routing.testing

import com.typewritermc.services.libs.communicator.interfaces.Message
import com.typewritermc.services.libs.communicator.routing.NatsContext
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.communicator.routing.SubjectParams
import io.opentelemetry.api.trace.Span
import protokt.v1.AbstractDeserializer
import protokt.v1.AbstractMessage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.time.Duration

class TestNatsContext(
    override val message: Message,
    override val params: SubjectParams,
    private val mockBus: MockMessageBus,
    override val span: Span = Span.getInvalid()
) : NatsContext {
    private val _replies = mutableListOf<ByteArray>()
    private val _sent = mutableListOf<Pair<String, ByteArray>>()

    val replies: List<ByteArray> get() = _replies.toList()
    val sent: List<Pair<String, ByteArray>> get() = _sent.toList()

    override suspend fun reply(data: ByteArray) {
        _replies.add(data)
        message.replyTo?.let { mockBus.publish(it, data) }
    }

    override suspend fun send(subject: String, data: ByteArray) {
        _sent.add(subject to data)
        mockBus.publish(subject, data)
    }

    override suspend fun request(subject: String, data: ByteArray, timeout: Duration): Message {
        return mockBus.request(subject, data, timeout)
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
        val response = mockBus.request(subject, requestBytes, timeout)
        val responseData = response.data
            ?: throw IllegalStateException("Cannot deserialize response: response data is null for $subject")
        return responseDeserializer.deserialize(ByteArrayInputStream(responseData))
    }
}

class TestRouteResult(
    val context: TestNatsContext,
    val error: Throwable? = null
) {
    val replies: List<ByteArray> get() = context.replies
    val sent: List<Pair<String, ByteArray>> get() = context.sent
    val success: Boolean get() = error == null
}

suspend fun testRoute(
    routing: NatsRouting.() -> Unit,
    subject: String,
    data: ByteArray,
    replyTo: String? = "test.reply"
): TestRouteResult {
    val mockBus = MockMessageBus()
    val natsRouting = NatsRouting(mockBus).apply(routing)

    val route = natsRouting.routes.find { it.pattern.matches(subject) }
        ?: error("No route found matching subject: $subject")

    val params = route.pattern.extractParams(subject)
    val message = Message(subject = subject, data = data, replyTo = replyTo)
    val context = TestNatsContext(message, SubjectParams(params), mockBus)

    val error = runCatching { route.handler.invoke(context) }.exceptionOrNull()

    return TestRouteResult(context, error)
}