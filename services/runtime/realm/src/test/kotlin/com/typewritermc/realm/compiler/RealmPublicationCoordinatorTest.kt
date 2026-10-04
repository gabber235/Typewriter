package com.typewritermc.realm.compiler

import com.surrealdb.Surreal
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.AuthoringSnapshotDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.SnapshotLease
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.DataValue
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
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

val RealmPublicationCoordinatorTest by testSuite {
    test("durable publication claim survives restart and releases the single slot after recovery") {
        runTest {
            val telemetry = TelemetryTestHarness.create()
            val database = publicationDatabase(telemetry)
            try {
                val first = publication("first")
                val competing = publication("competing")
                val original = SurrealPublicationAttemptStore(database)

                original.claim(first) shouldBe true
                original.claim(competing) shouldBe false

                val restarted = SurrealPublicationAttemptStore(database)
                restarted.unfinished() shouldContainExactly listOf(first)
                restarted.transition(first.id, PublicationState.Checking, PublicationState.Compiling) shouldBe true
                restarted.unfinished() shouldContainExactly listOf(first.copy(state = PublicationState.Compiling))
                restarted.transition(first.id, PublicationState.Compiling, PublicationState.Interrupted) shouldBe true

                restarted.unfinished() shouldBe emptyList()
                restarted.claim(competing) shouldBe true
            } finally {
                database.close()
                telemetry.close()
            }
        }
    }

    test("publication activates the captured snapshot while a later edit remains pending") {
        runTest {
            val catalog =
                TestCatalogLease(
                    definitions = PUBLICATION_DEFINITIONS,
                    resourceRoot = PUBLICATION_PAGE,
                )
            val resource = ResourceId("captured")
            val initial = mapOf(resource to publicationPageRecord("captured"))
            val store =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(SnapshotId("s0"), initial, tokensFor(initial, catalog.generation)),
                )
            val acceptance =
                acceptedSnapshot(
                    store,
                    listOf(NativeBindingRequirement(PUBLICATION_PAGE_USE, NativeBindingId("publication_page"), "page:v1")),
                )
            val recordedAttempts = RecordingPublicationAttemptStore()
            val claimStarted = CompletableDeferred<Unit>()
            val allowClaim = CompletableDeferred<Unit>()
            val attempts =
                object : PublicationAttemptStore by recordedAttempts {
                    override suspend fun claim(attempt: PublicationAttempt): Boolean {
                        claimStarted.complete(Unit)
                        allowClaim.await()
                        return recordedAttempts.claim(attempt)
                    }
                }
            val content = RecordingCompiledContentRepository()
            val captureStarted = CountDownLatch(1)
            val allowCapture = CountDownLatch(1)
            val engine =
                ControlledEngineImplementationSource(
                    engineInputs("engine:captured"),
                    captureStarted = captureStarted,
                    captureAllowed = allowCapture,
                )
            val coordinator = publicationCoordinator(acceptance, attempts, content, engine)
            val transitions = mutableListOf<PublicationState>()
            val checkingStarted = CompletableDeferred<Unit>()
            val allowChecking = CompletableDeferred<Unit>()

            val publishing =
                async(Dispatchers.Default) {
                    coordinator.publish(PublicationId("captured"), SnapshotId("s0"), catalog.generation) {
                        transitions += it.state
                        if (it.state == PublicationState.Checking) {
                            checkingStarted.complete(Unit)
                            allowChecking.await()
                        }
                    }
                }
            captureStarted.await(5, TimeUnit.SECONDS) shouldBe true
            val duringCapture = mapOf(resource to publicationPageRecord("during capture"))
            store.install(
                AuthoringSnapshotDelta(
                    snapshot = SnapshotId("s1"),
                    upsertedResources = duringCapture,
                    inputTokens = tokensFor(duringCapture, catalog.generation, prefix = "during_capture"),
                    resourceDefinitions = mapOf(resource to ResourceDefinitionId("test")),
                ),
            )
            allowCapture.countDown()
            claimStarted.await()
            val later = mapOf(resource to publicationPageRecord("later"))
            store.install(
                AuthoringSnapshotDelta(
                    snapshot = SnapshotId("s2"),
                    upsertedResources = later,
                    inputTokens = tokensFor(later, catalog.generation, prefix = "later"),
                    resourceDefinitions = mapOf(resource to ResourceDefinitionId("test")),
                ),
            )
            coordinator.publish(PublicationId("competing"), SnapshotId("s2"), catalog.generation) shouldBe
                PublicationResult.Publishing
            engine.captureCount shouldBe 1
            allowClaim.complete(Unit)
            checkingStarted.await()
            val latest = mapOf(resource to publicationPageRecord("latest"))
            store.install(
                AuthoringSnapshotDelta(
                    snapshot = SnapshotId("s3"),
                    upsertedResources = latest,
                    inputTokens = tokensFor(latest, catalog.generation, prefix = "latest"),
                    resourceDefinitions = mapOf(resource to ResourceDefinitionId("test")),
                ),
            )
            allowChecking.complete(Unit)

            publishing.await().shouldBeInstanceOf<PublicationResult.Activated>()
            content.activeManifest()?.sourceRevision shouldBe "s0"
            val shard =
                publicationJson.decodeFromString<CompiledPageShard>(
                    content.publishedArtifacts
                        .single()
                        .payload
                        .decodeToString(),
                )
            val compiledFields =
                (
                    shard.resources
                        .single()
                        .value.payload as DataValue.Record
                ).fields
            compiledFields.getValue("value") shouldBe DataValue.StringValue("captured")
            store.capture().use { current ->
                current.root.resources
                    .getValue(resource)
                    .fields
                    .getValue("value") shouldBe DataValue.StringValue("latest")
            }
            transitions shouldContainExactly
                listOf(
                    PublicationState.Checking,
                    PublicationState.Compiling,
                    PublicationState.Activating,
                    PublicationState.Complete,
                )
            store.close()
        }
    }

    test("changed engine inputs reject activation and retain the prior active content") {
        runTest {
            val catalog = TestCatalogLease()
            val store =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(SnapshotId("s0"), emptyMap(), tokensFor(emptyMap(), catalog.generation)),
                )
            val acceptance = acceptedSnapshot(store)
            val prior = publicationManifest("before", "prior:engine")
            val content = RecordingCompiledContentRepository(PublicationId("prior"), prior)
            val activationStarted = CompletableDeferred<Unit>()
            val activationAllowed = CompletableDeferred<Unit>()
            val engine =
                ControlledEngineImplementationSource(
                    engineInputs("engine:one"),
                    activationStarted,
                    activationAllowed,
                )
            val coordinator = publicationCoordinator(acceptance, RecordingPublicationAttemptStore(), content, engine)

            val publishing = async { coordinator.publish(PublicationId("next"), SnapshotId("s0"), catalog.generation) }
            activationStarted.await()
            engine.inputs = engineInputs("engine:two")
            activationAllowed.complete(Unit)

            val blocked = publishing.await().shouldBeInstanceOf<PublicationResult.Blocked>()
            blocked.findings.map { it.code } shouldBe listOf("engine_inputs_changed")
            content.activePublication() shouldBe PublicationId("prior")
            content.activeManifest() shouldBe prior
            store.close()
        }
    }

    test("transition cancellation releases the durable slot as interrupted") {
        runTest {
            val catalog = TestCatalogLease()
            val store =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(SnapshotId("s0"), emptyMap(), tokensFor(emptyMap(), catalog.generation)),
                )
            val attempts = RecordingPublicationAttemptStore()
            val coordinator =
                publicationCoordinator(
                    acceptedSnapshot(store),
                    attempts,
                    RecordingCompiledContentRepository(),
                    ControlledEngineImplementationSource(engineInputs("engine")),
                )
            val transitions = mutableListOf<PublicationState>()

            shouldThrow<CancellationException> {
                coordinator.publish(PublicationId("cancelled"), SnapshotId("s0"), catalog.generation) { attempt ->
                    transitions += attempt.state
                    if (attempt.state == PublicationState.Compiling) throw CancellationException("subscriber cancelled")
                }
            }

            transitions shouldContainExactly
                listOf(PublicationState.Checking, PublicationState.Compiling, PublicationState.Interrupted)
            attempts.unfinished() shouldBe emptyList()
            coordinator.currentAttempt()?.state shouldBe PublicationState.Interrupted
            store.close()
        }
    }

    test("ordinary transition delivery failure does not overwrite successful activation") {
        runTest {
            val catalog = TestCatalogLease()
            val store =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(SnapshotId("s0"), emptyMap(), tokensFor(emptyMap(), catalog.generation)),
                )
            val content = RecordingCompiledContentRepository()
            val coordinator =
                publicationCoordinator(
                    acceptedSnapshot(store),
                    RecordingPublicationAttemptStore(),
                    content,
                    ControlledEngineImplementationSource(engineInputs("engine")),
                )

            coordinator
                .publish(PublicationId("delivered"), SnapshotId("s0"), catalog.generation) { attempt ->
                    if (attempt.state == PublicationState.Activating) error("subscriber unavailable")
                }.shouldBeInstanceOf<PublicationResult.Activated>()

            coordinator.currentAttempt()?.state shouldBe PublicationState.Complete
            content.activePublication() shouldBe PublicationId("delivered")
            store.close()
        }
    }

    test("terminal notification cancellation keeps successful activation complete") {
        runTest {
            val catalog = TestCatalogLease()
            val store =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(SnapshotId("s0"), emptyMap(), tokensFor(emptyMap(), catalog.generation)),
                )
            val attempts = RecordingPublicationAttemptStore()
            val content = RecordingCompiledContentRepository()
            val coordinator =
                publicationCoordinator(
                    acceptedSnapshot(store),
                    attempts,
                    content,
                    ControlledEngineImplementationSource(engineInputs("engine")),
                )

            shouldThrow<CancellationException> {
                coordinator.publish(PublicationId("complete"), SnapshotId("s0"), catalog.generation) { attempt ->
                    if (attempt.state == PublicationState.Complete) throw CancellationException("subscriber cancelled")
                }
            }

            coordinator.currentAttempt()?.state shouldBe PublicationState.Complete
            content.activePublication() shouldBe PublicationId("complete")
            attempts.unfinished() shouldBe emptyList()
            store.close()
        }
    }
}

private fun publicationCoordinator(
    acceptance: PublicationAcceptance,
    attempts: PublicationAttemptStore,
    content: RegisteredCompiledContentRepository,
    engine: EngineImplementationSource,
) = RealmPublicationCoordinator(
    acceptance,
    attempts,
    content,
    RegisteredCompiledArtifactStore(InMemoryBlobEndpoint()),
    engine,
)

private fun acceptedSnapshot(
    store: InMemoryAuthoringSnapshotStore,
    bindings: List<NativeBindingRequirement> = emptyList(),
): PublicationAcceptance =
    object : PublicationAcceptance {
        override fun retain(
            expectedSnapshot: SnapshotId,
            expectedCatalog: CatalogGeneration,
        ): SnapshotLease {
            val retained = store.retain(expectedSnapshot)
            require(retained.root.catalog.generation == expectedCatalog)
            return retained
        }

        override suspend fun evaluate(capture: SnapshotLease): AcceptanceResult =
            AcceptanceResult.Accepted(
                AcceptedSnapshot(
                    capture.root.id,
                    capture.root.catalog.generation,
                    CheckCoverage(emptySet(), emptySet()),
                    emptyList(),
                    bindings,
                ),
            )
    }

private fun engineInputs(token: String) = EngineImplementationInputs(emptySet(), InputToken(token))

private class ControlledEngineImplementationSource(
    initial: EngineImplementationInputs,
    private val activationStarted: CompletableDeferred<Unit> = CompletableDeferred(Unit),
    private val activationAllowed: CompletableDeferred<Unit> = CompletableDeferred(Unit),
    private val captureStarted: CountDownLatch? = null,
    private val captureAllowed: CountDownLatch? = null,
) : EngineImplementationSource {
    var inputs = initial
    var captureCount = 0
        private set

    override fun capture(): EngineImplementationInputs {
        captureCount++
        captureStarted?.countDown()
        captureAllowed?.await()
        return inputs
    }

    override suspend fun activate(
        captured: EngineImplementationInputs,
        publish: suspend () -> Boolean,
    ): Boolean {
        activationStarted.complete(Unit)
        activationAllowed.await()
        return captured == inputs && publish()
    }
}

private class RecordingPublicationAttemptStore : PublicationAttemptStore {
    private var attempt: PublicationAttempt? = null

    override suspend fun claim(attempt: PublicationAttempt): Boolean {
        if (this.attempt != null) return false
        this.attempt = attempt
        return true
    }

    override suspend fun transition(
        id: PublicationId,
        from: PublicationState,
        to: PublicationState,
    ): Boolean {
        val current = attempt ?: return false
        if (current.id != id || current.state != from) return false
        attempt =
            if (to.isTerminal()) {
                null
            } else {
                current.copy(state = to)
            }
        return true
    }

    override suspend fun unfinished(): List<PublicationAttempt> = listOfNotNull(attempt)
}

private fun PublicationState.isTerminal(): Boolean =
    this is PublicationState.Complete || this is PublicationState.Blocked || this is PublicationState.Interrupted

private class RecordingCompiledContentRepository(
    private var publication: PublicationId? = null,
    private var manifest: CompiledArtifactManifest? = null,
) : RegisteredCompiledContentRepository {
    private var activation: CompiledArtifactActivation? = null
    var publishedArtifacts: List<CompiledArtifact> = emptyList()
        private set

    override suspend fun activePublication(): PublicationId? = publication

    override suspend fun activeManifest(): CompiledArtifactManifest? = manifest

    override suspend fun activeActivation(): CompiledArtifactActivation? = activation

    override suspend fun nextActivationRevision(): Long = (activation?.activationRevision ?: 0L) + 1L

    override suspend fun states(roots: Set<CompilationRoot>): Map<CompilationRoot, RegisteredCompiledState> =
        roots.associateWith { RegisteredCompiledState.NotCompiled }

    override suspend fun recordBlocked(
        sourceRevision: String,
        catalogRevision: String,
        roots: Collection<CompilationRoot>,
        diagnostics: List<CompileDiagnostic>,
    ): Boolean = true

    override suspend fun publish(
        publication: PublicationId,
        manifest: CompiledArtifactManifest,
        artifacts: Collection<CompiledArtifact>,
        activation: CompiledArtifactActivation,
    ): Boolean {
        this.publication = publication
        this.manifest = manifest
        this.activation = activation
        publishedArtifacts = artifacts.toList()
        return true
    }
}

private fun publicationManifest(
    source: String,
    implementation: String,
) = CompiledArtifactManifest(
    formatRevision = 1,
    digest = com.typewritermc.engine.ContentDigest("a".repeat(64)),
    sourceRevision = source,
    catalogRevision = "catalog",
    implementationToken = implementation,
    runtimeSignatures = emptySet(),
    artifacts = emptyList(),
)

private fun publicationPageRecord(value: String) =
    com.typewritermc.authoring.AuthoringRecord(
        com.typewritermc.authoring.TypeSelection
            .Complete(PUBLICATION_PAGE_USE),
        mapOf("value" to DataValue.StringValue(value)),
    )

private val PUBLICATION_PAGE = TypeDefinitionId(TypeId.Qualified("publication", "page"), 1)
private val PUBLICATION_PAGE_USE = TypeUse.Named(PUBLICATION_PAGE)
private val PUBLICATION_DEFINITIONS =
    listOf(
        TypeDefinition(
            PAGE_CONTRACT_TYPE,
            representation = RepresentationTemplate.Record(emptyList(), abstract = true),
        ),
        TypeDefinition(
            PUBLICATION_PAGE,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(PUBLICATION_PAGE, "value"), TypeTemplate.Scalar(ScalarKind.Text))),
                ),
            parents = listOf(TypeTemplate.Named(PAGE_CONTRACT_TYPE)),
        ),
    )

private val publicationJson = Json { encodeDefaults = true }

private fun publication(name: String) =
    PublicationAttempt(
        id = PublicationId(name),
        capture = SnapshotId("snapshot"),
        catalog = CatalogGeneration("catalog"),
        engineInputs = EngineImplementationInputs(emptySet(), InputToken("engine")),
        state = PublicationState.Checking,
    )

private fun publicationDatabase(telemetry: TelemetryTestHarness): Surreal =
    Surreal().apply {
        connect("memory")
        useNs("publication_test").useDb("publication_test")
        telemetry.telemetry.mainSpanBlocking(
            name = "test.publication.schema",
            unhandledFailureSlug = ErrorSlug.of("test-publication-schema-failed"),
        ) {
            SchemaMigrator(this@apply).migrate()
        }
    }
