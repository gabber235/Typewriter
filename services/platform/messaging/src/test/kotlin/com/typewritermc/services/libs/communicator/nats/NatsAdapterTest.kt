package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.testing.FakeNatsClient
import com.typewritermc.services.libs.communicator.testing.FakeNatsClientFactory
import com.typewritermc.services.libs.communicator.testing.FakeNatsSubscription
import com.typewritermc.services.libs.communicator.testing.natsConnection
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
    val testLimits =
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

    test("authentication never prints its secrets") {
        val authentication =
            NatsAuthentication(
                authToken = "auth-secret",
                username = "user-secret",
                password = "password-secret",
                jwt = "jwt-secret",
                signature = "signature-secret",
                nkey = "nkey-secret",
            )

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

    test("native connectivity transitions gate transport and update lifecycle state") {
        val client = FakeNatsClient()
        val connection = natsConnection(client)
        connection.connect()
        val transport = NatsMessageTransport(connection, testLimits)

        client.connectivity.value = NatsClientConnectivity.Connecting
        testScope.advanceTimeBy(25.milliseconds)
        connection.state.value shouldBe NatsConnectionState.Reconnecting
        (transport.publish(OutboundMessage(MessageAddress.of("work"), byteArrayOf())) as TransportResult.Failure).error::class shouldBe
            TransportError.Unavailable::class

        client.connectivity.value = NatsClientConnectivity.Connected
        testScope.advanceTimeBy(25.milliseconds)
        connection.state.value shouldBe NatsConnectionState.Connected
        transport.publish(OutboundMessage(MessageAddress.of("work"), byteArrayOf())) shouldBe TransportResult.Success(Unit)

        client.connectivity.value = NatsClientConnectivity.Disconnected
        testScope.advanceTimeBy(25.milliseconds)
        connection.state.value shouldBe NatsConnectionState.Disconnected
        connection.shutdown()
    }

    test("authentication maps nonce signing and connected state only after success") {
        val client = FakeNatsClient()
        var challengeHasNonce = false
        val factory =
            FakeNatsClientFactory(client) { auth ->
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
        val failed = FakeNatsClient(connectResult = Result.failure(IllegalStateException("no")))
        val connection = natsConnection(failed)
        (connection.connect() as NatsLifecycleResult.Failure).error::class shouldBe NatsLifecycleError.Connection::class

        val cancelled = natsConnection(FakeNatsClient(connectResult = Result.failure(CancellationException("stop"))))
        shouldThrow<CancellationException> { cancelled.connect() }
    }

    test("canceling vendor authentication preserves the connection timeout and permits another attempt") {
        val timeout = IllegalStateException("timed out connecting to server")
        val failedClient = FakeNatsClient(connectResult = Result.failure(timeout))
        val replacementClient = FakeNatsClient()
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
            val client = FakeNatsClient()
            val connection =
                NatsConnection(
                    { NatsConnectionConfiguration("nats://localhost") },
                    { NatsAuthentication() },
                    FakeNatsClientFactory(client) {
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
        val firstClient = FakeNatsClient()
        val replacementClient = FakeNatsClient()
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
        val failedClient = FakeNatsClient(connectResult = Result.failure(IllegalStateException("closed")))
        val replacementClient = FakeNatsClient()
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
        val client = FakeNatsClient(drainFailure = drain, disconnectFailure = disconnect)
        val connection = natsConnection(client)
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

    test("request maps statuses timeouts and generic failures") {
        suspend fun result(
            replies: Flow<NatsClientMessage>,
            publishFailure: Throwable? = null,
        ): TransportError {
            val client = FakeNatsClient(subscription = FakeNatsSubscription(replies), publishFailure = publishFailure)
            val connection = natsConnection(client)
            connection.connect()
            return (
                NatsMessageTransport(
                    connection,
                    testLimits,
                ).request(OutboundMessage(MessageAddress.of("work"), byteArrayOf()), 1.seconds) as TransportResult.Failure
            ).error
        }
        result(flowOf(NatsClientMessage("reply", null, null, null, 503, "status")))::class shouldBe TransportError.NoResponders::class
        result(flowOf(NatsClientMessage("reply", null, null, null, 404, "status")))::class shouldBe TransportError.Failure::class
        result(flow { awaitCancellation() })::class shouldBe TransportError.Timeout::class
        result(flowOf())::class shouldBe TransportError.Unavailable::class
        result(flowOf(), IllegalStateException("broken"))::class shouldBe TransportError.Failure::class
    }

    test("flush failure rolls subscription back") {
        val subscription = FakeNatsSubscription(flowOf())
        val client = FakeNatsClient(subscription = subscription, flushFailure = IllegalStateException("flush"))
        val connection = natsConnection(client)
        connection.connect()
        NatsMessageTransport(connection, testLimits).subscribe(AddressPattern.of("jobs.*"))::class shouldBe TransportResult.Failure::class
        subscription.unsubscribeCalls shouldBe 1
    }

    test("disconnected and invalid request timeout fail explicitly") {
        val transport = NatsMessageTransport(natsConnection(FakeNatsClient()), testLimits)
        (transport.publish(OutboundMessage(MessageAddress.of("work"), byteArrayOf())) as TransportResult.Failure).error::class shouldBe
            TransportError.Unavailable::class
        shouldThrow<IllegalArgumentException> {
            transport.request(
                OutboundMessage(MessageAddress.of("work"), byteArrayOf()),
                0.milliseconds,
            )
        }
    }
}
