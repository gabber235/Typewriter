package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.SurrealBookRepository
import com.typewritermc.realm.repository.SurrealPageRepository
import com.typewritermc.realm.repository.SurrealTagRepository
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.DeferredProvider
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
val RealmLifecycleTest by testSuite {
    test("registrar attempts replace routes even when the connection generation repeats") {
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
                advanceTimeBy(1_000)
                runCurrent()

                second.transport.activeSubscriptionCount shouldBe ROUTE_COUNT
                fixture.realm.shutdown()
            }
        }
    }
}

private const val ROUTE_COUNT = 17

private class RealmLifecycleFixture(
    scope: kotlinx.coroutines.CoroutineScope,
) : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    private val database = DeferredProvider<Surreal>()
    private val tags = SurrealTagRepository(database)
    private val books = SurrealBookRepository(database)
    private val pages = SurrealPageRepository(database)
    val realm = Realm(
        database = database,
        databaseProvider = TestDatabaseProvider(),
        routeFactory = RealmRouteFactory(books, pages, tags),
        scope = scope,
        telemetry = telemetry.telemetry,
    )

    fun ready(attempt: Long, generation: Long): ReadyState {
        val transport = FakeMessageTransport()
        val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
        val identity = ServiceIdentity("realm", "Realm", "realm", listOf(ServiceRole.Realm("1.0.0")))
        val session = ReadySession(identity, OrganizationBinding("organization", "Organization"), communicator)
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
            realm.start(states)
        }
    }

    override fun close() {
        database.getOrNull()?.close()
        telemetry.close()
    }
}

private data class ReadyState(
    val snapshot: RegistrarSnapshot,
    val transport: FakeMessageTransport,
)

private class TestDatabaseProvider : RealmDatabaseProvider {
    context(_: MainSpanScope)
    override fun connect(): Surreal = Surreal().apply {
        connect("memory")
        useNs("realm_lifecycle_test").useDb("realm_lifecycle_test")
        SchemaMigrator(this).migrate()
    }
}
