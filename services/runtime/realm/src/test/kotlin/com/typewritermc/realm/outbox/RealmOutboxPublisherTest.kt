package com.typewritermc.realm.outbox

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.realm.repository.RepositoryFixture
import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.successValue
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.client.EncodedPublication
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
val RealmOutboxPublisherTest by testSuite {
    test("reconnection retries the same durable bytes and shutdown prevents further publication") {
        runTest {
            val outbox = FakeRealmOutbox(event("original"))
            val delay = GateDelayScheduler()
            val telemetry = TelemetryTestHarness.create()
            val firstTransport = FakeMessageTransport()
            firstTransport.failNextPublish(TransportError.Unavailable())
            val first = Communicator(firstTransport, telemetry.telemetry, ContextPropagators.noop())
            val publisher =
                RealmOutboxPublisher(
                    outbox,
                    backgroundScope,
                    Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC),
                    RetryPolicy.fixed(1.seconds),
                    delay,
                )

            publisher.replaceCommunicator(first)
            runCurrent()
            delay.requested.receive() shouldBe 1.seconds
            outbox.failed shouldBe 1

            val secondTransport = FakeMessageTransport()
            val second = Communicator(secondTransport, telemetry.telemetry, ContextPropagators.noop())
            publisher.replaceCommunicator(second)
            runCurrent()

            val publication = secondTransport.actions.filterIsInstance<FakeMessageTransport.Action.Publish>().single()
            publication.message.payload shouldBe Payload.copyOf("original".encodeToByteArray())
            outbox.published shouldBe 1

            publisher.stop()
            outbox.add(event("after-stop"))
            runCurrent()
            secondTransport.actions.filterIsInstance<FakeMessageTransport.Action.Publish>().size shouldBe 1

            firstTransport.close()
            secondTransport.close()
            telemetry.close()
        }
    }

    test("a delayed head Page event blocks every newer row") {
        runTest {
            val first = event("page-first")
            val second = event("page-second")
            val outbox = FakeRealmOutbox(first).apply { add(second) }
            val delay = GateDelayScheduler()
            val telemetry = TelemetryTestHarness.create()
            val transport = FakeMessageTransport()
            transport.failNextPublish(TransportError.Unavailable())
            val publisher =
                RealmOutboxPublisher(
                    outbox,
                    backgroundScope,
                    fixedClock("2030-01-01T00:00:00Z"),
                    RetryPolicy.fixed(1.seconds),
                    delay,
                )

            publisher.replaceCommunicator(Communicator(transport, telemetry.telemetry, ContextPropagators.noop()))
            runCurrent()
            delay.requested.receive() shouldBe 1.seconds
            transport.actions.filterIsInstance<FakeMessageTransport.Action.Publish>().map { it.message.payload } shouldBe
                listOf(first.payload)

            delay.release()
            runCurrent()
            transport.actions.filterIsInstance<FakeMessageTransport.Action.Publish>().map { it.message.payload } shouldBe
                listOf(first.payload, first.payload, second.payload)

            publisher.stop()
            transport.close()
            telemetry.close()
        }
    }

    test("a new publisher drains a pending Surreal row after restart") {
        runTest {
            RepositoryFixture().use { fixture ->
                val stored = event("persisted-across-restart")
                fixture.books
                    .createBook("restart_book", "book", Color(argb = 0), emptyList()) { listOf(stored) }
                    .successValue()
                val telemetry = TelemetryTestHarness.create()
                val firstTransport = FakeMessageTransport()
                firstTransport.failNextPublish(TransportError.Unavailable())
                val gate = GateDelayScheduler()
                val firstPublisher =
                    RealmOutboxPublisher(
                        fixture.outbox,
                        backgroundScope,
                        fixedClock("2030-01-01T00:00:00Z"),
                        RetryPolicy.fixed(1.seconds),
                        gate,
                    )
                firstPublisher.replaceCommunicator(
                    Communicator(firstTransport, telemetry.telemetry, ContextPropagators.noop()),
                )
                runCurrent()
                gate.requested.receive()
                firstPublisher.stop()

                val secondTransport = FakeMessageTransport()
                val secondPublisher =
                    RealmOutboxPublisher(
                        fixture.outbox,
                        backgroundScope,
                        fixedClock("2030-01-01T00:00:02Z"),
                        RetryPolicy.fixed(1.seconds),
                        GateDelayScheduler(),
                    )
                secondPublisher.replaceCommunicator(
                    Communicator(secondTransport, telemetry.telemetry, ContextPropagators.noop()),
                )
                runCurrent()

                publishedPayload(secondTransport) shouldBe stored.payload
                secondPublisher.stop()
                firstTransport.close()
                secondTransport.close()
                telemetry.close()
            }
        }
    }

    test("completion failure republishes the exact payload after restart") {
        runTest {
            RepositoryFixture().use { fixture ->
                val stored = event("published-before-crash")
                fixture.books
                    .createBook("duplicate_book", "book", Color(argb = 0), emptyList()) { listOf(stored) }
                    .successValue()
                val telemetry = TelemetryTestHarness.create()
                val ignoredFailure = CoroutineExceptionHandler { _, _ -> }
                val failingScope =
                    CoroutineScope(SupervisorJob() + StandardTestDispatcher(testScheduler) + ignoredFailure)
                val firstTransport = FakeMessageTransport()
                val firstPublisher =
                    RealmOutboxPublisher(
                        CompletionFailingOutbox(fixture.outbox),
                        failingScope,
                        fixedClock("2030-01-01T00:00:00Z"),
                        RetryPolicy.fixed(1.seconds),
                        GateDelayScheduler(),
                    )
                firstPublisher.replaceCommunicator(
                    Communicator(firstTransport, telemetry.telemetry, ContextPropagators.noop()),
                )
                runCurrent()
                publishedPayload(firstTransport) shouldBe stored.payload
                failingScope.cancel()

                val secondTransport = FakeMessageTransport()
                val secondPublisher =
                    RealmOutboxPublisher(
                        fixture.outbox,
                        backgroundScope,
                        fixedClock("2030-01-01T00:00:00Z"),
                        RetryPolicy.fixed(1.seconds),
                        GateDelayScheduler(),
                    )
                secondPublisher.replaceCommunicator(
                    Communicator(secondTransport, telemetry.telemetry, ContextPropagators.noop()),
                )
                runCurrent()
                publishedPayload(secondTransport) shouldBe stored.payload

                secondPublisher.stop()
                firstTransport.close()
                secondTransport.close()
                telemetry.close()
            }
        }
    }
}

private fun fixedClock(instant: String) = Clock.fixed(Instant.parse(instant), ZoneOffset.UTC)

private fun publishedPayload(transport: FakeMessageTransport) =
    transport.actions
        .filterIsInstance<FakeMessageTransport.Action.Publish>()
        .single()
        .message.payload

private fun event(value: String) =
    EncodedPublication(
        MessageAddress.of("service.from.realm.organization.organization.realm.page.watch"),
        Payload.copyOf(value.encodeToByteArray()),
    )

private class GateDelayScheduler : DelayScheduler {
    val requested = Channel<Duration>(Channel.UNLIMITED)
    private val releases = Channel<Unit>(Channel.UNLIMITED)

    override suspend fun delay(duration: Duration) {
        requested.send(duration)
        releases.receive()
    }

    fun release() {
        releases.trySend(Unit).getOrThrow()
    }
}

private class FakeRealmOutbox(
    initial: EncodedPublication,
) : RealmOutbox {
    private val signal = Channel<Unit>(Channel.CONFLATED)
    private var nextId = 0L
    private val rows = mutableListOf(row(initial))
    var failed = 0
    var published = 0

    override fun enqueue(
        transaction: Transaction,
        events: List<OutboxEvent>,
    ) = error("Not used")

    override suspend fun pending(limit: Int) = rows.take(limit)

    override suspend fun markPublished(
        id: RecordId,
        publishedAt: Instant,
    ) {
        rows.removeAll { it.id == id }
        published++
    }

    override suspend fun markFailed(
        id: RecordId,
        availableAt: Instant,
    ) {
        failed++
    }

    override fun signalPending() {
        signal.trySend(Unit).getOrThrow()
    }

    override suspend fun awaitPending() {
        signal.receive()
    }

    fun add(event: EncodedPublication) {
        rows += row(event)
        signalPending()
    }

    private fun row(event: EncodedPublication) =
        PendingOutboxEvent(RecordId("realm_outbox", nextId++), event, failed.toLong(), Instant.EPOCH)
}

private class CompletionFailingOutbox(
    private val delegate: RealmOutbox,
) : RealmOutbox by delegate {
    override suspend fun markPublished(
        id: RecordId,
        publishedAt: Instant,
    ): Nothing = error("completion storage unavailable")
}
