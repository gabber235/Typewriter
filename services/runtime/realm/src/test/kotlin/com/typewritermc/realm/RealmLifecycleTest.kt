package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobChunk
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.BlobWriteSession
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactCatalog
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.loader.api.artifact.SharedCatalogRevision
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.realm.routes.UnavailableRealmEditorCatalogSource
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
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val RealmLifecycleTest by testSuite {
    test("startup waits until Realm responders are registered") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val startup = async { fixture.start() }
                runCurrent()

                fixture.databaseOpen shouldBe true
                startup.isCompleted shouldBe false

                val session = fixture.session(1)
                fixture.messaging.value = session.session
                runCurrent()

                startup.await()
                session.transport.activeSubscriptionCount shouldBeGreaterThan 0
            } finally {
                fixture.close()
            }
        }
    }

    test("messaging replacement preserves the Realm runtime and swaps routers") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                fixture.start()
                runCurrent()
                fixture.artifactWrites shouldBe 1
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

    test("failed router replacement closes the old router before retry succeeds") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                fixture.start()
                runCurrent()
                val routeCount = first.transport.activeSubscriptionCount

                val second = fixture.session(2)
                second.transport.failNextSubscribe(TransportError.Unavailable(IllegalStateException("not ready")))
                fixture.messaging.value = second.session
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
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

    test("terminal route loss is retried within the active messaging session") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val session = fixture.session(1)
                fixture.messaging.value = session.session
                fixture.start()
                val routeCount = session.transport.activeSubscriptionCount

                session.transport.deliver(
                    com.typewritermc.services.libs.communicator.transport.TransportDelivery.Failure(
                        TransportError.Unavailable(IllegalStateException("connection lost")),
                    ),
                )
                runCurrent()

                session.transport.activeSubscriptionCount shouldBe 0
                fixture.delayScheduler.awaitRequest()
                fixture.delayScheduler.resume()
                runCurrent()

                session.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("disconnect closes responders and reconnect installs one replacement") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                fixture.start()
                val routeCount = first.transport.activeSubscriptionCount

                fixture.messaging.value = null
                runCurrent()
                first.transport.activeSubscriptionCount shouldBe 0

                val second = fixture.session(2)
                fixture.messaging.value = second.session
                runCurrent()
                second.transport.activeSubscriptionCount shouldBe routeCount

                val third = fixture.session(3)
                fixture.messaging.value = third.session
                runCurrent()
                second.transport.activeSubscriptionCount shouldBe 0
                third.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("replacement cancellation closes the superseded router without duplicates") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val closeStarted = Channel<Unit>(Channel.UNLIMITED)
                val allowClose = Channel<Unit>(Channel.UNLIMITED)
                val first = fixture.session(1)
                first.transport.closeSubscriptionWith(1) {
                    closeStarted.send(Unit)
                    allowClose.receive()
                }
                fixture.messaging.value = first.session
                fixture.start()
                val routeCount = first.transport.activeSubscriptionCount

                val second = fixture.session(2)
                fixture.messaging.value = second.session
                closeStarted.receive()

                val third = fixture.session(3)
                fixture.messaging.value = third.session
                allowClose.send(Unit)
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe 0
                third.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("shutdown closes every Realm responder") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            val session = fixture.session(1)
            fixture.messaging.value = session.session
            fixture.start()

            fixture.close()

            session.transport.activeSubscriptionCount shouldBe 0
            fixture.databaseOpen shouldBe false
        }
    }
}

private class RealmLifecycleFixture(
    scope: kotlinx.coroutines.CoroutineScope,
) {
    private val telemetry = TelemetryTestHarness.create()
    private val sharedArtifacts = InMemorySharedArtifacts()
    val messaging = MutableStateFlow<HostedMessagingSession?>(null)
    val delayScheduler = FakeDelayScheduler()
    var databaseOpen = false
        private set
    val artifactWrites: Int
        get() = sharedArtifacts.completedWrites
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
            presentationSearch = UnavailableRealmPresentationSearchSource(),
            scope = scope,
            telemetry = telemetry.telemetry,
            retryPolicy = RetryPolicy.fixed(1.seconds),
            delayScheduler = delayScheduler,
            catalogInvalidations =
                RealmCatalogInvalidationProcess(
                    snapshots = RealmDiscoverySnapshotStore(),
                    scope = scope,
                    telemetry = telemetry.telemetry,
                ),
            discoverySnapshots = RealmDiscoverySnapshotStore(),
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

private class InMemorySharedArtifacts : SharedArtifactAccess {
    private val artifacts = mutableMapOf<ArtifactDigest, ByteArray>()
    private val writes = mutableMapOf<TransferId, PendingBlobWrite>()
    var completedWrites = 0
        private set

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        artifacts[digest]
            ?.let { BlobResult.Success(BlobMetadata(digest, it.size.toLong())) }
            ?: BlobResult.NotFound

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> {
        val value = artifacts[digest] ?: return BlobResult.NotFound
        val start = offset.toInt().coerceAtMost(value.size)
        val end = (start + maximumBytes).coerceAtMost(value.size)
        return BlobResult.Success(BlobChunk(offset, value.copyOfRange(start, end), end == value.size))
    }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> {
        writes[transfer] = PendingBlobWrite(expected)
        return BlobResult.Success(BlobWriteSession(transfer, expected, 0))
    }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> {
        val pending = writes.getValue(transfer)
        if (pending.bytes.size.toLong() != offset) return BlobResult.Conflict("Unexpected write offset.")
        pending.bytes += bytes
        return BlobResult.Success(pending.bytes.size.toLong())
    }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> {
        val pending = writes.remove(transfer) ?: return BlobResult.NotFound
        if (ArtifactDigest.sha256(pending.bytes) != pending.expected.digest) {
            return BlobResult.Invalid("Digest mismatch.")
        }
        artifacts[pending.expected.digest] = pending.bytes
        completedWrites++
        return BlobResult.Success(pending.expected)
    }

    override suspend fun publish(command: PublishSharedArtifact): PublishResult = error("Catalog writes are not used.")

    override suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult = error("Catalog deletes are not used.")

    override suspend fun catalog() = SharedArtifactCatalog(SharedCatalogRevision(0), emptyList())

    private data class PendingBlobWrite(
        val expected: BlobMetadata,
        var bytes: ByteArray = byteArrayOf(),
    )
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
