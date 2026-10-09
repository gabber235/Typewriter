package com.typewritermc.realm

import build.skir.Serializer
import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputToken
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
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
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.CreationEvaluator
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.compiler.EngineImplementationInputs
import com.typewritermc.realm.compiler.StagedEngineImplementationSource
import com.typewritermc.realm.repository.AuthoringMutationPlan
import com.typewritermc.realm.repository.SurrealAuthoringStorage
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration

@OptIn(ExperimentalCoroutinesApi::class)
val RealmLifecycleTest by testSuite {
    test("catalog activation completes before Realm routes are exposed") {
        runTest {
            val activationStarted = CompletableDeferred<Unit>()
            val finishActivation = CompletableDeferred<Unit>()
            val fixture =
                RealmLifecycleFixture(this) { _, _ ->
                    activationStarted.complete(Unit)
                    finishActivation.await()
                    error("catalog activation failed")
                }
            val session = fixture.session(1)
            fixture.messaging.value = session.session

            val startup = async { runCatching { fixture.start() } }
            activationStarted.await()

            fixture.databaseOpen shouldBe true
            startup.isCompleted shouldBe false
            session.transport.activeSubscriptionCount shouldBe 0

            finishActivation.complete(Unit)
            startup.await().exceptionOrNull()?.message shouldBe "catalog activation failed"
            fixture.databaseOpen shouldBe false
            session.transport.activeSubscriptionCount shouldBe 0
            fixture.close()
        }
    }

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

    test("Realm startup preserves unavailable authored data while serving unrelated resources") {
        runTest {
            val valid = TypeDefinitionId(TypeId.Qualified("lifecycle", "valid"), 1)
            val unavailable = TypeDefinitionId(TypeId.Qualified("lifecycle", "unavailable"), 1)
            val availableResource = ResourceId("available")
            val unavailableResource = ResourceId("unavailable")
            val availableRecord =
                AuthoringRecord(
                    TypeSelection.Complete(TypeUse.Named(valid)),
                    mapOf("name" to DataValue.StringValue("Book")),
                )
            val unavailableRecord =
                AuthoringRecord(
                    TypeSelection.Complete(TypeUse.Named(unavailable)),
                    mapOf("legacy" to DataValue.StringValue("preserved")),
                )
            val resources = mapOf(availableResource to availableRecord, unavailableResource to unavailableRecord)
            val incarnation = lifecycleIsolationCatalog(valid, unavailable)
            val fixture =
                RealmLifecycleFixture(
                    this,
                    catalog = incarnation,
                    initialSeed =
                        AuthoringSeed(
                            resources,
                            mapOf(
                                availableResource to ResourceDefinitionId("valid"),
                                unavailableResource to ResourceDefinitionId("removed"),
                            ),
                        ),
                )
            try {
                val session = fixture.session(1)
                fixture.messaging.value = session.session
                fixture.start()

                val catalogResult =
                    fixture.request(
                        session,
                        "editor.catalog.fetch",
                        CatalogFetchRequest(expectedGeneration = null, transferId = "lifecycle_catalog"),
                        CatalogFetchRequest.serializer,
                        CatalogFetchResult.serializer,
                    ) as CatalogFetchResult.ChunkWrapper
                val catalog =
                    EditorCatalogWireSnapshot.serializer.fromBytes(
                        catalogResult.value.transfer.payload
                            .toByteArray(),
                    )
                catalog.generation.value shouldBe incarnation.assembly.snapshot.generation.value
                catalog.types.map { SkirTypeCodec.decode(it.definition).getOrThrow().id }.containsAll(listOf(valid, unavailable)) shouldBe
                    true

                val snapshotResult =
                    fixture.request(
                        session,
                        "editor.authoring.state.query",
                        QueryAuthoringStateRequest(
                            generation = SkirCatalogGeneration(value = incarnation.assembly.snapshot.generation.value),
                            transferId = "lifecycle_snapshot",
                        ),
                        QueryAuthoringStateRequest.serializer,
                        QueryAuthoringStateResponse.serializer,
                    ) as QueryAuthoringStateResponse.ChunkWrapper
                val snapshot =
                    SkirAuthoringState.serializer.fromBytes(
                        snapshotResult.value.transfer.payload
                            .toByteArray(),
                    )
                snapshot.resources.associate { resource ->
                    resource.id.value to SkirAuthoringValueCodec.decode(resource.content).getOrThrow()
                } shouldBe
                    mapOf(
                        availableResource.value to availableRecord,
                        unavailableResource.value to unavailableRecord,
                    )
                snapshot.resources.associate { it.id.value to it.definition.value } shouldBe
                    mapOf(availableResource.value to "valid", unavailableResource.value to "removed")
            } finally {
                fixture.close()
            }
        }
    }
}

private fun lifecycleIsolationCatalog(
    valid: TypeDefinitionId,
    unavailable: TypeDefinitionId,
): RealmCatalogIncarnation {
    fun origin(name: String): ProviderOrigin {
        val key = ContributionKey(ContributionSourceId("lifecycle"), "main", ProducerId("test"), ContributionName(name))
        return ProviderOrigin(DeclarationOwner(key, name), ArtifactId("test:lifecycle"), "main")
    }

    val validDefinition =
        TypeDefinition(
            valid,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(valid, "name"), TypeTemplate.Scalar(ScalarKind.Text))),
                ),
        )
    val unavailableDefinition =
        TypeDefinition(
            unavailable,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(unavailable, "legacy"), TypeTemplate.Scalar(ScalarKind.Text))),
                ),
        )
    val contributions =
        CatalogContributions(
            declarations =
                listOf(
                    OwnedTypeDeclaration(origin("valid"), validDefinition),
                    OwnedTypeDeclaration(origin("unavailable_first"), unavailableDefinition),
                    OwnedTypeDeclaration(origin("unavailable_second"), unavailableDefinition),
                ),
            resources =
                listOf(
                    AuthoringResourceDefinition(ResourceDefinitionId("valid"), valid),
                    AuthoringResourceDefinition(ResourceDefinitionId("removed"), unavailable),
                ),
        )
    val deployment = GeneratedProviderLoader().load(emptyList(), DeploymentFacts(), DiscoveryDomains.Realm)
    val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration("lifecycle_isolation")))
    return RealmCatalogIncarnation(assembly, deployment)
}

private class RealmLifecycleFixture(
    scope: kotlinx.coroutines.CoroutineScope,
    catalog: RealmCatalogIncarnation? = null,
    initialSeed: AuthoringSeed? = null,
    catalogActivator: RealmCatalogActivator? = null,
) {
    private val telemetry = TelemetryTestHarness.create()
    private val sharedArtifacts = InMemorySharedArtifacts()
    private val catalogs =
        RealmCatalogStore().also { store ->
            if (catalog == null) store.installTestCatalog("lifecycle_catalog") else store.replace(catalog)
        }
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
            databaseProvider =
                TestDatabaseProvider(
                    onConnect = { databaseOpen = true },
                    onClose = { databaseOpen = false },
                    initialize = { database ->
                        if (initialSeed != null) {
                            SurrealAuthoringStorage(database).persistAtomic(
                                AuthoringMutationPlan(
                                    initialSeed.resources,
                                    emptySet(),
                                    RelationProjectionDelta(emptyList(), emptyList(), emptyList()),
                                    initialSeed.resourceDefinitions,
                                ),
                            )
                        }
                    },
                ),
            catalogs = catalogs,
            scope = scope,
            telemetry = telemetry.telemetry,
            retryPolicy = RetryPolicy.fixed(1.seconds),
            delayScheduler = delayScheduler,
            host = host,
            registrars = emptyList(),
            facts = DeploymentFacts(),
            creationEvaluator = CreationEvaluator { _, _ -> error("Creation is not used by lifecycle tests.") },
            engine = StagedEngineImplementationSource(EngineImplementationInputs(emptySet(), InputToken("engine"))),
            catalogActivator =
                catalogActivator ?: RealmCatalogActivator { repository, catalog ->
                    repository.activateCatalog(catalog, install = {}, publish = {})
                },
        )

    fun session(id: Long): TestSession {
        val transport = FakeMessageTransport()
        val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
        return TestSession(HostedMessagingSession(id, "organization", communicator), transport)
    }

    suspend fun <Request : Any, Response : Any> request(
        session: TestSession,
        suffix: String,
        request: Request,
        requestSerializer: Serializer<Request>,
        responseSerializer: Serializer<Response>,
    ): Response {
        val reply = MessageAddress.of("test.lifecycle.reply.${replySequence++}")
        session.transport.deliver(
            TransportDelivery.Message(
                InboundMessage(
                    address = MessageAddress.of("service.to.realm.organization.organization.realm.$suffix"),
                    payload = requestSerializer.toBytes(request).toByteArray(),
                    replyTo = reply,
                ),
            ),
        )
        val publication =
            withTimeout(2.seconds) {
                while (true) {
                    session.transport.actions
                        .filterIsInstance<FakeMessageTransport.Action.Publish>()
                        .lastOrNull { it.message.address == reply }
                        ?.let { return@withTimeout it }
                    yield()
                }
                error("Reply wait ended unexpectedly")
            }
        return responseSerializer.fromBytes(publication.message.payload.toByteArray())
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
            catalogs.close()
            telemetry.close()
        }
    }

    private var replySequence = 0
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
    private val initialize: (Surreal) -> Unit = {},
) : RealmDatabaseProvider {
    context(_: MainSpanScope)
    override fun connect(): Surreal {
        onConnect()
        return Surreal().apply {
            connect("memory")
            useNs("realm_lifecycle_test").useDb("realm_lifecycle_test")
            SchemaMigrator(this).migrate()
            initialize(this)
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
