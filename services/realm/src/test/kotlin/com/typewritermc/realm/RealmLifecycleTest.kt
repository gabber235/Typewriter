package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.routes.UnavailableRealmEditorCatalogSource
import com.typewritermc.realm.routes.UnavailableRealmElementCatalogSource
import com.typewritermc.realm.routes.UnavailableRealmPresentationSearchSource
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val RealmLifecycleTest by testSuite {
    test("loader connection attempts replace routes even when the connection generation repeats") {
        runTest {
            RealmLifecycleFixture(this).use { fixture ->
                val first = fixture.ready(attempt = 1, generation = 4)
                val states = MutableStateFlow(first.snapshot)
                fixture.start(states)

                first.transport.activeSubscriptionCount shouldBe ROUTE_COUNT
                val second = fixture.ready(attempt = 2, generation = 4)
                states.value = second.snapshot
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe ROUTE_COUNT
                fixture.realm.shutdown()
                second.transport.activeSubscriptionCount shouldBe 0
            }
        }
    }

    test("failed route replacement retries while the ready session remains current") {
        runTest {
            RealmLifecycleFixture(this).use { fixture ->
                val first = fixture.ready(attempt = 1, generation = 1)
                val states = MutableStateFlow(first.snapshot)
                fixture.start(states)

                val second = fixture.ready(attempt = 2, generation = 2)
                second.transport.failNextSubscribe(TransportError.Unavailable(IllegalStateException("not ready")))
                states.value = second.snapshot
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe 0
                fixture.delayScheduler.awaitRequest()
                fixture.delayScheduler.resume()
                runCurrent()

                second.transport.activeSubscriptionCount shouldBe ROUTE_COUNT
                fixture.realm.shutdown()
            }
        }
    }
}

private const val ROUTE_COUNT = 19

private class RealmLifecycleFixture(
    scope: kotlinx.coroutines.CoroutineScope,
) : AutoCloseable {
    private val communicators = mutableMapOf<Long, Communicator>()
    private val transports = mutableListOf<FakeMessageTransport>()
    private val telemetry = TelemetryTestHarness.create()
    private val lifecycleEvents = mutableListOf<String>()
    val delayScheduler = FakeDelayScheduler()
    val realm =
        Realm(
            databaseProvider =
                TestDatabaseProvider(
                    onConnect = { lifecycleEvents += "database.connect" },
                    onClose = {
                        check(transports.all { it.activeSubscriptionCount == 0 })
                        lifecycleEvents += "database.close"
                    },
                ),
            editorCatalog = UnavailableRealmEditorCatalogSource(),
            elementCatalog = UnavailableRealmElementCatalogSource(),
            presentationSearch = UnavailableRealmPresentationSearchSource(),
            scope = scope,
            telemetry = telemetry.telemetry,
            retryPolicy = RetryPolicy.fixed(1.seconds),
            delayScheduler = delayScheduler,
            clock = java.time.Clock.systemUTC(),
            catalogInvalidations =
                RealmCatalogInvalidationProcess(
                    snapshots = RealmDiscoverySnapshotStore(),
                    scope = scope,
                    telemetry = telemetry.telemetry,
                ),
        )

    fun ready(
        attempt: Long,
        generation: Long,
    ): ReadyState {
        val transport = FakeMessageTransport()
        transports += transport
        val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
        val identity = ServiceIdentity("loader", "Loader", "loader", ServiceRole.Host("1.0.0"))
        communicators[generation] = communicator
        val session = ReadySession(identity, OrganizationBinding("organization", "Organization"))
        return ReadyState(
            RegistrarSnapshot(attempt, attempt, RegistrarState.Ready(session, generation)),
            transport,
        )
    }

    suspend fun start(states: MutableStateFlow<RegistrarSnapshot>) {
        telemetry.telemetry.mainSpan(
            name = "test.realm.start",
            unhandledFailureSlug = ErrorSlug.of("test-realm-start-failed"),
        ) {
            realm.start("realm", states) { generation ->
                lifecycleEvents += "communicator"
                RegistrarResult.Success(communicators.getValue(generation))
            }
        }
        lifecycleEvents.take(2) shouldBe listOf("database.connect", "communicator")
    }

    override fun close() {
        try {
            runBlocking { realm.shutdown() }
            lifecycleEvents.lastOrNull() shouldBe "database.close"
        } finally {
            telemetry.close()
        }
    }
}

private data class ReadyState(
    val snapshot: RegistrarSnapshot,
    val transport: FakeMessageTransport,
)

private class TestDatabaseProvider(
    private val onConnect: () -> Unit,
    private val onClose: () -> Unit,
) : RealmDatabaseProvider {
    context(_: MainSpanScope)
    override fun connect(): Surreal {
        onConnect()
        return Surreal().apply {
            connect("memory")
            useNs("realm_lifecycle_test").useDb("realm_lifecycle_test")
            SchemaMigrator(this).migrate()
        }
    }

    override fun close(database: Surreal) {
        try {
            onClose()
        } finally {
            database.close()
        }
    }
}

private class FakeDelayScheduler : DelayScheduler {
    private val requested = Channel<Duration>(Channel.UNLIMITED)
    private val resumed = Channel<Unit>(Channel.UNLIMITED)

    override suspend fun delay(duration: Duration) {
        requested.send(duration)
        resumed.receive()
    }

    suspend fun awaitRequest() {
        requested.receive() shouldBe 1.seconds
    }

    fun resume() {
        check(resumed.trySend(Unit).isSuccess)
    }
}
