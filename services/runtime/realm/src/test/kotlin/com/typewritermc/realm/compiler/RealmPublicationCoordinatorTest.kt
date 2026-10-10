package com.typewritermc.realm.compiler

import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.encodeShard
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
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
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runTest

val RealmPublicationCoordinatorTest by testSuite {
    test("the local publication gate captures once and rejects overlapping publication") {
        runTest {
            val id = ResourceId("page")
            val catalog = TestCatalogLease(definitions = PUBLICATION_DEFINITIONS, resourceRoot = PUBLICATION_PAGE)
            val views = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to publicationPageRecord("Quest"))))
            val checking = CompletableDeferred<Unit>()
            val proceed = CompletableDeferred<Unit>()
            val attempts = RecordingAttempts()
            val acceptance =
                object : PublicationAcceptance {
                    override fun capture() = views.capture()

                    override suspend fun evaluate(capture: AuthoringLease): AcceptanceResult {
                        checking.complete(Unit)
                        proceed.await()
                        capture.root.resources[id] shouldBe publicationPageRecord("Quest")
                        return accepted(
                            capture,
                            listOf(NativeBindingRequirement(PUBLICATION_PAGE_USE, NativeBindingId("publication_page"), "page:v1")),
                        )
                    }
                }
            val engine = StagedEngineImplementationSource(testEngineInputs())
            val publisher =
                RealmPublicationCoordinator(
                    acceptance,
                    attempts,
                    RegisteredCompiledArtifactStore(InMemoryBlobEndpoint()),
                    engine,
                    pageCompilation(),
                )
            val first = async { publisher.publish() }
            checking.await()
            publisher.publish() shouldBe PublicationResult.Publishing
            views.install(views.prepare(AuthoringViewDelta(mapOf(id to publicationPageRecord("Story")))))
            proceed.complete(Unit)
            val result = first.await().shouldBeInstanceOf<PublicationResult.Activated>()
            result.content.outputs
                .single()
                .reference.root.resource shouldBe id
            attempts.installed shouldBe result.content
            attempts.started shouldBe 1
            attempts.phases shouldBe listOf(PublicationState.Compiling, PublicationState.Activating)
            publisher.currentAttempt()?.state shouldBe PublicationState.Complete
            views.capture().use { it.root.resources[id] shouldBe publicationPageRecord("Story") }
            views.close()
        }
    }
    test("blocked acceptance does not compile or install and the gate permits another publication") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        val attempts = RecordingAttempts()
        val acceptance =
            object : PublicationAcceptance {
                override fun capture() = views.capture()

                override suspend fun evaluate(capture: AuthoringLease) = AcceptanceResult.Blocked(emptyList())
            }
        val publisher =
            RealmPublicationCoordinator(
                acceptance,
                attempts,
                RegisteredCompiledArtifactStore(InMemoryBlobEndpoint()),
                StagedEngineImplementationSource(testEngineInputs()),
                pageCompilation(),
            )
        publisher.publish().shouldBeInstanceOf<PublicationResult.Blocked>()
        publisher.publish().shouldBeInstanceOf<PublicationResult.Blocked>()
        attempts.started shouldBe 2
        attempts.phases shouldBe emptyList()
        attempts.installed shouldBe null
        views.close()
    }
    test("engine incompatibility before installation preserves the previous selected content") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        val attempts = RecordingAttempts()
        val engine =
            object : EngineImplementationSource {
                override fun capture() = testEngineInputs()

                override suspend fun activate(
                    captured: EngineImplementationInputs,
                    publish: suspend () -> Boolean,
                ) = false
            }
        val acceptance =
            object : PublicationAcceptance {
                override fun capture() = views.capture()

                override suspend fun evaluate(capture: AuthoringLease) = accepted(capture)
            }
        val publisher =
            RealmPublicationCoordinator(
                acceptance,
                attempts,
                RegisteredCompiledArtifactStore(InMemoryBlobEndpoint()),
                engine,
                pageCompilation(),
            )
        val result = publisher.publish().shouldBeInstanceOf<PublicationResult.Blocked>()
        result.findings.single().code shouldBe "engine_inputs_changed"
        attempts.installed shouldBe null
        views.close()
    }
    test("startup interrupts unfinished work and an empty successful publication installs a complete empty set") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        val attempts = RecordingAttempts()
        val acceptance =
            object : PublicationAcceptance {
                override fun capture() = views.capture()

                override suspend fun evaluate(capture: AuthoringLease) = accepted(capture)
            }
        val publisher =
            RealmPublicationCoordinator(
                acceptance,
                attempts,
                RegisteredCompiledArtifactStore(InMemoryBlobEndpoint()),
                StagedEngineImplementationSource(testEngineInputs()),
                pageCompilation(),
            )
        publisher.recoverInterrupted()
        attempts.recovered shouldBe true
        publisher
            .publish()
            .shouldBeInstanceOf<PublicationResult.Activated>()
            .content.outputs shouldBe emptyList()
        views.close()
    }
    test("Page producer preserves the exact shard bytes and metadata") {
        val page = ResourceId("page")
        val views =
            InMemoryAuthoringViewStore(
                TestCatalogLease(definitions = PUBLICATION_DEFINITIONS, resourceRoot = PUBLICATION_PAGE),
                AuthoringSeed(mapOf(page to publicationPageRecord("Quest"))),
            )
        views.capture().use { capture ->
            val bindings = listOf(NativeBindingRequirement(PUBLICATION_PAGE_USE, NativeBindingId("publication_page"), "page:v1"))
            val expected =
                with(capture.root) {
                    PageCompiler(emptySet(), bindings.associateBy(NativeBindingRequirement::actual)).compile(page)
                }.shouldBeInstanceOf<PageCompileResult.Success>()
            val producer = PageCompiledArtifactProducer()
            val inputs = CompilationInputs(capture.root, bindings)
            val artifact =
                with(inputs) { producer.compile(producer.roots(capture.root)) }
                    .shouldBeInstanceOf<CompilationOutcome.Ready>()
                    .artifacts
                    .single()

            artifact.root.projection shouldBe producer.projection
            artifact.root.resource shouldBe page
            artifact.mediaType shouldBe "application/vnd.typewriter.page+json"
            artifact.formatRevision shouldBe 2
            artifact.inputFingerprint shouldBe expected.inputFingerprint
            artifact.semanticDigest shouldBe expected.shard.digest
            artifact.payload.toList() shouldBe
                expected.shard.facts
                    .encodeShard()
                    .toList()
        }
        views.close()
    }

    test("a blocked producer prevents storage and installation of otherwise ready Page output") {
        val page = ResourceId("page")
        val views =
            InMemoryAuthoringViewStore(
                TestCatalogLease(definitions = PUBLICATION_DEFINITIONS, resourceRoot = PUBLICATION_PAGE),
                AuthoringSeed(mapOf(page to publicationPageRecord("Quest"))),
            )
        val attempts = RecordingAttempts()
        var storageRequests = 0
        val backing = InMemoryBlobEndpoint()
        val blobs =
            object : BlobEndpoint by backing {
                override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> {
                    storageRequests++
                    return backing.metadata(digest)
                }
            }
        val bindings = listOf(NativeBindingRequirement(PUBLICATION_PAGE_USE, NativeBindingId("publication_page"), "page:v1"))
        val acceptance =
            object : PublicationAcceptance {
                override fun capture() = views.capture()

                override suspend fun evaluate(capture: AuthoringLease) = accepted(capture, bindings)
            }
        val blocked =
            object : CompiledArtifactProducer {
                override val projection = CompilationProjectionId("fixture.blocked")
                override val mediaType = "application/blocked"

                override fun roots(view: com.typewritermc.realm.authoring.AuthoringView) = emptySet<CompilationRoot>()

                context(inputs: CompilationInputs)
                override fun compile(roots: Set<CompilationRoot>) = CompilationOutcome.Blocked(emptyList())
            }
        val publisher =
            RealmPublicationCoordinator(
                acceptance,
                attempts,
                RegisteredCompiledArtifactStore(blobs),
                StagedEngineImplementationSource(testEngineInputs()),
                CompiledArtifactProducerRegistry(listOf(PageCompiledArtifactProducer(), blocked)),
            )

        publisher.publish().shouldBeInstanceOf<PublicationResult.Blocked>()
        storageRequests shouldBe 0
        attempts.installed shouldBe null
        attempts.phases shouldBe listOf(PublicationState.Compiling)
        views.close()
    }
}

private fun accepted(
    capture: AuthoringLease,
    bindings: List<NativeBindingRequirement> = emptyList(),
) = AcceptanceResult.Accepted(
    AcceptedAuthoring(capture.root.catalog.generation, CheckCoverage(emptySet(), emptySet()), emptyList(), bindings),
)

private class RecordingAttempts : PublicationAttemptStore {
    var started = 0
    var recovered = false
    var installed: PublishedContent? = null
    val phases = mutableListOf<PublicationState>()

    override suspend fun start(
        id: PublicationId,
        catalog: CatalogGeneration,
        engineInputs: EngineImplementationInputs,
    ) {
        started++
    }

    override suspend fun phase(
        id: PublicationId,
        phase: PublicationState,
    ) {
        phases += phase
    }

    override suspend fun blocked(
        id: PublicationId,
        findings: List<com.typewritermc.checking.Diagnostic>,
    ) { }

    override suspend fun install(result: PublishedContent) {
        installed = result
    }

    override suspend fun interruptUnfinished() {
        recovered = true
    }
}

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

private fun pageCompilation() = CompiledArtifactProducerRegistry(listOf(PageCompiledArtifactProducer()))
