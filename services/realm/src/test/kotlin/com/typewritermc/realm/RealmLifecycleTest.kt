package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.realm.routes.UnavailableRealmEditorCatalogSource
import com.typewritermc.realm.routes.UnavailableRealmElementCatalogSource
import com.typewritermc.realm.routes.UnavailableRealmPresentationSearchSource
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val RealmLifecycleTest by testSuite {
    test("messaging replacement preserves the Realm runtime and swaps routers") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                fixture.start()
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                runCurrent()
                val routeCount = first.transport.activeSubscriptionCount
                routeCount shouldBeGreaterThan 0

                val second = fixture.session(2)
                fixture.messaging.value = second.session
                runCurrent()

                fixture.databaseOpen shouldBe true
                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("failed router replacement retains the healthy router until retry succeeds") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                fixture.start()
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                runCurrent()
                val routeCount = first.transport.activeSubscriptionCount

                val second = fixture.session(2)
                second.transport.failNextSubscribe(TransportError.Unavailable(IllegalStateException("not ready")))
                fixture.messaging.value = second.session
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe routeCount
                second.transport.activeSubscriptionCount shouldBe 0
                fixture.delayScheduler.awaitRequest()
                fixture.delayScheduler.resume()
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }
}

private class RealmLifecycleFixture(
    scope: kotlinx.coroutines.CoroutineScope,
) {
    private val telemetry = TelemetryTestHarness.create()
    private val sharedArtifacts = mockk<SharedArtifactAccess>(relaxed = true)
    val messaging = MutableStateFlow<HostedMessagingSession?>(null)
    val delayScheduler = FakeDelayScheduler()
    var databaseOpen = false
        private set
    private val host =
        object : HostedRuntimeHost {
            override val messaging = this@RealmLifecycleFixture.messaging
            override val openTelemetry = telemetry.openTelemetry
            override val sharedArtifacts = this@RealmLifecycleFixture.sharedArtifacts
        }
    private val realm =
        Realm(
            databaseProvider = TestDatabaseProvider({ databaseOpen = true }, { databaseOpen = false }),
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
            host = host,
        )

    fun session(id: Long): TestSession {
        val transport = FakeMessageTransport()
        val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
        return TestSession(HostedMessagingSession(id, "organization", communicator), transport)
    }

    suspend fun start() {
        telemetry.telemetry.mainSpan(
            name = "test.realm.start",
            unhandledFailureSlug = ErrorSlug.of("test-realm-start-failed"),
        ) {
            realm.start("realm")
        }
        databaseOpen shouldBe true
    }

    suspend fun close() {
        try {
            realm.shutdown()
            databaseOpen shouldBe false
        } finally {
            telemetry.close()
        }
    }
}

private data class TestSession(
    val session: HostedMessagingSession,
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
