package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.ConsumerGroup
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.yield
import kotlin.time.Duration
import kotlin.time.Duration.Companion.microseconds
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

@ExperimentalCoroutinesApi
val NatsAdapterTest by testSuite {
    test("authentication never prints secrets and retains value equality") {
        val authentication =
            NatsAuthentication(
                authToken = "auth-secret",
                username = "user-secret",
                password = "password-secret",
                jwt = "jwt-secret",
                signature = "signature-secret",
                nkey = "nkey-secret",
            )

        authentication shouldBe
            NatsAuthentication(
                "auth-secret",
                "user-secret",
                "password-secret",
                "jwt-secret",
                "signature-secret",
                "nkey-secret",
            )
        authentication.hashCode() shouldBe
            NatsAuthentication(
                "auth-secret",
                "user-secret",
                "password-secret",
                "jwt-secret",
                "signature-secret",
                "nkey-secret",
            ).hashCode()
        authentication.toString() shouldBe "NatsAuthentication([REDACTED])"
    }

    test("configuration validates public settings") {
        shouldThrow<IllegalArgumentException> { NatsConnectionConfiguration(" ") }
        shouldThrow<IllegalArgumentException> { NatsConnectionConfiguration("http://localhost") }
        shouldThrow<IllegalArgumentException> {
            NatsConnectionConfiguration(
                "nats://localhost",
                connectTimeout = Duration.ZERO,
            )
        }
        NatsConnectionConfiguration(
            "nats://localhost:4222",
            maxReconnects = 0,
        ).serverUrl shouldBe "nats://localhost:4222"
    }

    test("configuration normalizes NATS attempt and millisecond values") {
        val zero =
            NatsConnectionConfiguration(
                "nats://localhost",
                connectTimeout = 1.microseconds,
                maxReconnects = 0,
                reconnectDelay = 1501.microseconds,
            )
        zero.natsMaxConnectionAttempts shouldBe 1
        zero.normalizedConnectTimeout shouldBe 1.milliseconds
        zero.normalizedReconnectDelay shouldBe 2.milliseconds
        NatsConnectionConfiguration("nats://localhost", maxReconnects = 4).natsMaxConnectionAttempts shouldBe 5
        NatsConnectionConfiguration(
            "nats://localhost",
            maxReconnects = Int.MAX_VALUE,
        ).natsMaxConnectionAttempts shouldBe Int.MAX_VALUE
    }

    test("native connectivity transitions gate transport and update lifecycle state") {
        val client = FakeClient()
        val connection = connection(client)
        connection.connect()
        val transport = NatsMessageTransport(connection, TEST_LIMITS)

        client.connectivity.value = NatsClientConnectivity.Connecting
        testScope.advanceTimeBy(25.milliseconds)
        connection.state.value shouldBe NatsConnectionState.Reconnecting
        (transport.publish(outbound()) as TransportResult.Failure).error::class shouldBe TransportError.Unavailable::class

        client.connectivity.value = NatsClientConnectivity.Connected
        testScope.advanceTimeBy(25.milliseconds)
        connection.state.value shouldBe NatsConnectionState.Connected
        transport.publish(outbound()) shouldBe TransportResult.Success(Unit)

        client.connectivity.value = NatsClientConnectivity.Disconnected
        testScope.advanceTimeBy(25.milliseconds)
        connection.state.value shouldBe NatsConnectionState.Disconnected
        connection.shutdown()
    }

    test("authentication maps nonce signing and connected state only after success") {
        val client = FakeClient()
        var challengeHasNonce = false
        val factory =
            FakeFactory(client) { auth ->
                val mapped = auth(true) { "signed:$it" }
                mapped.signature shouldBe "signed:seed"
            }
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration("nats://localhost") },
                { challenge ->
                    challengeHasNonce = challenge.hasNonce
                    NatsAuthentication(jwt = "jwt", signature = challenge.signNonce("seed"), nkey = "public")
                },
                factory,
            )
        connection.state.value shouldBe NatsConnectionState.Disconnected
        connection.connect() shouldBe NatsLifecycleResult.Success
        challengeHasNonce shouldBe true
        connection.state.value shouldBe NatsConnectionState.Connected
    }

    test("connect failure is typed and cancellation is unchanged") {
        val failed = FakeClient(connectResult = Result.failure(IllegalStateException("no")))
        val connection = connection(failed)
        (connection.connect() as NatsLifecycleResult.Failure).error::class shouldBe NatsLifecycleError.Connection::class

        val cancelled = connection(FakeClient(connectResult = Result.failure(CancellationException("stop"))))
        shouldThrow<CancellationException> { cancelled.connect() }
    }

    test("canceling vendor authentication preserves the connection timeout and permits another attempt") {
        val timeout = IllegalStateException("timed out connecting to server")
        val failedClient = FakeClient(connectResult = Result.failure(timeout))
        val replacementClient = FakeClient()
        val clients = ArrayDeque(listOf(failedClient, replacementClient))
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration("nats://localhost") },
                { awaitCancellation() },
                { _, authentication ->
                    clients.removeFirst().also { client ->
                        if (client === failedClient) {
                            client.onConnect = {
                                coroutineScope {
                                    val entered = CompletableDeferred<Unit>()
                                    val callback =
                                        launch {
                                            entered.complete(Unit)
                                            authentication(true) { "signed" }
                                        }
                                    entered.await()
                                    callback.cancelAndJoin()
                                }
                            }
                        }
                    }
                },
            )

        val failure = connection.connect().shouldBeInstanceOf<NatsLifecycleResult.Failure>()
        failure.error.shouldBeInstanceOf<NatsLifecycleError.Connection>().cause shouldBe timeout
        currentCoroutineContext().isActive shouldBe true
        connection.state.value shouldBe NatsConnectionState.Disconnected
        failedClient.events.shouldContainExactly("connect", "disconnect")
        connection.connect() shouldBe NatsLifecycleResult.Success
        connection.shutdown() shouldBe NatsLifecycleResult.Success
    }

    test("caller cancellation propagates and releases the partially connected client") {
        coroutineScope {
            val entered = CompletableDeferred<Unit>()
            val client = FakeClient()
            val connection =
                NatsConnection(
                    { NatsConnectionConfiguration("nats://localhost") },
                    { NatsAuthentication() },
                    FakeFactory(client) {
                        entered.complete(Unit)
                        awaitCancellation()
                    },
                )
            val pending = async { connection.connect() }
            entered.await()

            pending.cancel()

            shouldThrow<CancellationException> { pending.await() }
            pending.join()
            currentCoroutineContext().isActive shouldBe true
            connection.state.value shouldBe NatsConnectionState.Disconnected
            client.events.shouldContainExactly("connect", "disconnect")
        }
    }

    test("reconnect reloads providers and shutdown drains before disconnect") {
        val firstClient = FakeClient()
        val replacementClient = FakeClient()
        val clients = ArrayDeque(listOf(firstClient, replacementClient))
        var configurations = 0
        val connection =
            NatsConnection(
                {
                    configurations++
                    NatsConnectionConfiguration("nats://localhost")
                },
                { NatsAuthentication() },
                { _, _ -> clients.removeFirst() },
            )
        connection.connect()
        connection.reconnect()
        configurations shouldBe 2
        connection.shutdown() shouldBe NatsLifecycleResult.Success
        firstClient.events.shouldContainExactly("connect", "disconnect")
        replacementClient.events.shouldContainExactly("connect", "drain", "disconnect")
        connection.shutdown() shouldBe NatsLifecycleResult.Success
    }

    test("reconnect creates a fresh client when no active client remains") {
        val failedClient = FakeClient(connectResult = Result.failure(IllegalStateException("closed")))
        val replacementClient = FakeClient()
        val clients = ArrayDeque(listOf(failedClient, replacementClient))
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration("nats://localhost") },
                { NatsAuthentication() },
                { _, _ -> clients.removeFirst() },
            )

        connection.connect().shouldBeInstanceOf<NatsLifecycleResult.Failure>()
        connection.reconnect() shouldBe NatsLifecycleResult.Success
        connection.state.value shouldBe NatsConnectionState.Connected
        failedClient.events.shouldContainExactly("connect", "disconnect")
        replacementClient.events.shouldContainExactly("connect")
    }

    test("shutdown preserves drain failure and suppressed disconnect failure") {
        val drain = IllegalStateException("drain")
        val disconnect = IllegalStateException("disconnect")
        val client = FakeClient(drainFailure = drain, disconnectFailure = disconnect)
        val connection = connection(client)
        connection.connect()
        val failure = connection.shutdown() as NatsLifecycleResult.Failure
        failure.error.cause shouldBe drain
        drain.suppressed.toList() shouldContainExactly listOf(disconnect)
        connection.state.value shouldBe NatsConnectionState.ShuttingDown
        client.drainFailure = null
        client.disconnectFailure = null
        connection.shutdown() shouldBe NatsLifecycleResult.Success
        connection.shutdown() shouldBe NatsLifecycleResult.Success
        client.events.shouldContainExactly("connect", "drain", "disconnect", "drain", "disconnect")
        connection.state.value shouldBe NatsConnectionState.Disconnected
    }

    test("publish and request preserve headers and reply through an owned inbox") {
        val reply = NatsClientMessage("reply", null, mapOf("X" to listOf("a", "b")), "return", null, null)
        val subscription = FakeSubscription(flowOf(reply))
        val client = FakeClient(subscription = subscription)
        val connection = connection(client)
        connection.connect()
        val transport = NatsMessageTransport(connection, TEST_LIMITS)
        val outbound =
            OutboundMessage(
                MessageAddress.of("work"),
                byteArrayOf(1),
                MessageAddress.of("inbox"),
                MessageHeaders.of("X" to "a", "X" to "b"),
            )
        transport.publish(outbound) shouldBe TransportResult.Success(Unit)
        val result = transport.request(outbound.copy(replyTo = null), 1250.milliseconds) as TransportResult.Success
        result.value.payload shouldBe Payload.Empty
        result.value.headers["x"] shouldBe listOf("a", "b")
        result.value.replyTo shouldBe MessageAddress.of("return")
        client.publishCalls shouldBe 2
        val request = client.publishedMessages.last()
        request.payload?.toByteArray() shouldBe byteArrayOf(1)
        request.headers shouldBe mapOf("X" to listOf("a", "b"))
        val inbox = requireNotNull(request.replyTo)
        inbox.startsWith("_INBOX.") shouldBe true
        client.events.takeLast(2) shouldBe listOf("subscribe:$inbox:null", "flush")
        subscription.unsubscribeCalls shouldBe 1
    }

    test("request maps statuses timeouts and generic failures") {
        suspend fun result(
            replies: Flow<NatsClientMessage>,
            publishFailure: Throwable? = null,
        ): TransportError {
            val client = FakeClient(subscription = FakeSubscription(replies), publishFailure = publishFailure)
            val connection = connection(client)
            connection.connect()
            return (NatsMessageTransport(connection, TEST_LIMITS).request(outbound(), 1.seconds) as TransportResult.Failure).error
        }
        result(flowOf(status(503)))::class shouldBe TransportError.NoResponders::class
        result(flowOf(status(404)))::class shouldBe TransportError.Failure::class
        result(flow { awaitCancellation() })::class shouldBe TransportError.Timeout::class
        result(flowOf())::class shouldBe TransportError.Unavailable::class
        result(flowOf(), IllegalStateException("broken"))::class shouldBe TransportError.Failure::class
    }

    test("subscribe maps options flushes and closes once") {
        val subscription =
            FakeSubscription(
                flowOf(
                    NatsClientMessage(
                        "jobs.one",
                        Payload.copyOf(byteArrayOf(2)),
                        mapOf("X" to listOf("v")),
                        null,
                        null,
                        null,
                    ),
                ),
            )
        val client = FakeClient(subscription = subscription)
        val connection = connection(client)
        connection.connect()
        val result =
            NatsMessageTransport(connection, TEST_LIMITS).subscribe(
                AddressPattern.of("jobs.*"),
                SubscriptionOptions(ConsumerGroup.of("workers")),
            ) as TransportResult.Success
        client.events.takeLast(2) shouldBe listOf("subscribe:jobs.*:workers", "flush")
        val deliveries = mutableListOf<TransportDelivery>()
        result.value.deliveries.collect(deliveries::add)
        (deliveries.first() as TransportDelivery.Message).message.headers["x"] shouldBe listOf("v")
        deliveries.last() shouldBe TransportDelivery.Completed
        result.value.close()
        result.value.close()
        subscription.unsubscribeCalls shouldBe 1
    }

    test("reply channels use the configured NATS inbox prefix") {
        val subscription = FakeSubscription(flowOf())
        val client = FakeClient(subscription = subscription)
        val connection =
            NatsConnection(
                { NatsConnectionConfiguration("nats://localhost", inboxPrefix = "_TYPEWRITER_REPLY.") },
                { NatsAuthentication() },
                FakeFactory(client),
            )
        connection.connect()

        val result = NatsMessageTransport(connection, TEST_LIMITS).openReplyChannel() as TransportResult.Success

        result.value.address.value
            .startsWith("_TYPEWRITER_REPLY.") shouldBe true
        client.events.takeLast(2) shouldBe
            listOf(
                "subscribe:${result.value.address.value}:null",
                "flush",
            )
        result.value.close()
        connection.shutdown()
    }

    test("closing active subscription completes deliveries") {
        coroutineScope {
            val closed = CompletableDeferred<Unit>()
            val subscription =
                FakeSubscription(
                    messages = flow { closed.await() },
                    onUnsubscribe = { closed.complete(Unit) },
                )
            val client = FakeClient(subscription = subscription)
            val connection = connection(client)
            connection.connect()
            val result =
                NatsMessageTransport(connection, TEST_LIMITS).subscribe(
                    AddressPattern.of("jobs.*"),
                ) as TransportResult.Success
            val deliveries = async { result.value.deliveries.toList() }
            yield()

            result.value.close()

            deliveries.await() shouldContainExactly listOf(TransportDelivery.Completed)
            subscription.unsubscribeCalls shouldBe 1
        }
    }

    test("flush failure rolls subscription back") {
        val subscription = FakeSubscription(flowOf())
        val client = FakeClient(subscription = subscription, flushFailure = IllegalStateException("flush"))
        val connection = connection(client)
        connection.connect()
        NatsMessageTransport(connection, TEST_LIMITS).subscribe(AddressPattern.of("jobs.*"))::class shouldBe TransportResult.Failure::class
        subscription.unsubscribeCalls shouldBe 1
    }

    test("disconnected and invalid request timeout fail explicitly") {
        val transport = NatsMessageTransport(connection(FakeClient()), TEST_LIMITS)
        (transport.publish(outbound()) as TransportResult.Failure).error::class shouldBe TransportError.Unavailable::class
        shouldThrow<IllegalArgumentException> { transport.request(outbound(), 0.milliseconds) }
    }
}

private typealias AuthenticationCallback = suspend (Boolean, suspend (String) -> String?) -> NatsAuthentication

private class FakeFactory(
    private val client: FakeClient,
    private val created: suspend (AuthenticationCallback) -> Unit = {},
) : NatsClientFactory {
    override fun create(
        configuration: NatsConnectionConfiguration,
        authentication: suspend (Boolean, suspend (String) -> String?) -> NatsAuthentication,
    ): NatsClientAdapter {
        client.onConnect = { created(authentication) }
        return client
    }
}

private class FakeClient(
    private val connectResult: Result<Unit> = Result.success(Unit),
    private val publishFailure: Throwable? = null,
    private val subscription: FakeSubscription = FakeSubscription(flowOf()),
    private val flushFailure: Throwable? = null,
    var drainFailure: Throwable? = null,
    var disconnectFailure: Throwable? = null,
) : NatsClientAdapter {
    override val connectivity = MutableStateFlow(NatsClientConnectivity.Connected)
    val events = mutableListOf<String>()
    var publishCalls = 0
    val publishedMessages = mutableListOf<NatsClientMessage>()
    var onConnect: suspend () -> Unit = {}

    override suspend fun connect(): Result<Unit> {
        events += "connect"
        onConnect()
        return connectResult
    }

    override suspend fun disconnect() {
        events += "disconnect"
        disconnectFailure?.let { throw it }
    }

    override suspend fun drain(timeout: Duration) {
        events += "drain"
        drainFailure?.let { throw it }
    }

    override suspend fun flush() {
        events += "flush"
        flushFailure?.let { throw it }
    }

    override suspend fun publish(message: NatsClientMessage) {
        publishCalls++
        publishedMessages += message
        publishFailure?.let { throw it }
    }

    override suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription {
        events += "subscribe:$subject:$queueGroup"
        return subscription
    }
}

private class FakeSubscription(
    override val messages: Flow<NatsClientMessage>,
    private val onUnsubscribe: suspend () -> Unit = {},
) : NatsClientSubscription {
    override val isActive: StateFlow<Boolean> = MutableStateFlow(true)
    var unsubscribeCalls = 0

    override suspend fun unsubscribe() {
        unsubscribeCalls++
        onUnsubscribe()
    }
}

private fun connection(client: FakeClient) =
    NatsConnection(
        { NatsConnectionConfiguration("nats://localhost") },
        { NatsAuthentication() },
        FakeFactory(client),
    )

private fun outbound() = OutboundMessage(MessageAddress.of("work"), byteArrayOf())

private fun status(code: Int) = NatsClientMessage("reply", null, null, null, code, "status")

private val TEST_LIMITS =
    TransportLimits(
        chunkBytes = 512 * 1024,
        windowFrames = 8,
        requestMaxBytes = 512L * 1024,
        replyMaxBytes =
            32L * 1024 * 1024,
        frameInactivity = 30.seconds,
        replyTtl = 5.minutes,
        replyCredit = false,
    )
