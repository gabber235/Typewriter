package com.typewritermc.realm.compiler

import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompileDiagnosticSeverity
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.encodeShard
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringView
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
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

val RealmPublicationCoordinatorTest by testSuite {
    test("preparing and unchanged content create no attempt or blob write") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.Ready>()
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.release()
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.Current>()
        fixture.publisher.publish(PublicationCandidateId("obsolete")) shouldBe PublicationResult.NoChanges
        fixture.attempts.started shouldBe 1
        fixture.close()
    }
    test("initial empty content stays empty while removing the last root is a release") {
        val fixture = PublicationFixture(initial = emptyMap())
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.Empty>()
        fixture.attempts.started shouldBe 0
        fixture.update("Quest")
        fixture.release()
        fixture.views.install(fixture.views.prepare(AuthoringViewDelta(emptyMap(), removedResources = setOf(ResourceId("page")))))
        fixture.publisher.refresh()
        val ready =
            fixture.publisher.views.value.status
                .shouldBeInstanceOf<PublicationStatus.Ready>()
        ready.changes.allChanges shouldBe listOf(PublicationChange.RootRemoved(fixture.root))
        fixture.publisher
            .publish(ready.candidate)
            .shouldBeInstanceOf<PublicationResult.Activated>()
            .content.outputs shouldBe emptyList()
        fixture.close()
    }
    test("an old candidate cannot start an attempt after another save or baseline change") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val old = fixture.ready()
        fixture.update("Story")
        fixture.publisher.publish(old.candidate).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.publisher.refresh()
        (fixture.ready().candidate == old.candidate) shouldBe false
        fixture.attempts.installed =
            PublishedContent(PublicationId("other"), 2, CatalogGeneration("other"), "implementation", emptySet(), emptyList())
        fixture.publisher.publish(fixture.ready().candidate).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.attempts.started shouldBe 0
        fixture.close()
    }
    test("reverted edits and catalog metadata do not create another release") {
        val fixture = PublicationFixture()
        fixture.release()
        fixture.update("Story")
        fixture.publisher.refresh()
        fixture.ready()
        fixture.update("Quest")
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.Current>()
        fixture.attempts.started shouldBe 1
        fixture.close()
    }
    test("background findings revoke a candidate without a saved content change") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val old = fixture.ready().candidate
        fixture.publisher.invalidate()
        fixture.publisher.publish(old).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.publisher.refresh()
        (fixture.ready().candidate == old) shouldBe false
        fixture.close()
    }
    test("missing saved content reports unavailable and can recover on the next refresh") {
        val fixture = PublicationFixture()
        fixture.captureFailure = true
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.Unavailable>()
        fixture.attempts.started shouldBe 0
        fixture.captureFailure = false
        fixture.publisher.refresh()
        fixture.ready()
        fixture.close()
    }
    test("publication freezes reviewed bytes and later edits are compared with that release") {
        runTest {
            val fixture = PublicationFixture()
            fixture.publisher.refresh()
            val candidate = fixture.ready()
            val storing = CompletableDeferred<Unit>()
            val proceed = CompletableDeferred<Unit>()
            fixture.attempts.beforeStart = {
                storing.complete(Unit)
                proceed.await()
            }
            val first = async { fixture.publisher.publish(candidate.candidate) }
            storing.await()
            fixture.publisher.publish(candidate.candidate) shouldBe PublicationResult.Publishing
            fixture.update("Story")
            fixture.publisher.refresh()
            val active =
                fixture.publisher.views.value.status
                    .shouldBeInstanceOf<PublicationStatus.Publishing>()
            active.next.confirmedChanges shouldBe listOf(PublicationChange.RootUpdated(fixture.root))
            proceed.complete(Unit)
            val published = first.await().shouldBeInstanceOf<PublicationResult.Activated>()
            val expected = fixture.compiled("Quest")
            published.content.outputs
                .single()
                .reference.semanticDigest shouldBe expected.semanticDigest
            fixture.publisher.refresh()
            fixture.ready().changes.allChanges shouldBe listOf(PublicationChange.RootUpdated(fixture.root))
            fixture.attempts.started shouldBe 1
            fixture.close()
        }
    }
    test("blocked compilation retains successful roots and source and target locations without effects") {
        val fixture = PublicationFixture(producers = listOf(PageCompiledArtifactProducer(), blockedProducer()))
        fixture.publisher.refresh()
        val blocked =
            fixture.publisher.views.value.status
                .shouldBeInstanceOf<PublicationStatus.Blocked>()
        blocked.confirmedChanges shouldBe listOf(PublicationChange.RootAdded(fixture.root))
        blocked.pendingRoots.single().resource shouldBe ResourceId("broken")
        blocked.blockers.first.diagnostic.primary
            ?.resource shouldBe ResourceId("broken")
        blocked.blockers.first.diagnostic.related
            .single()
            .resource shouldBe ResourceId("target")
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.publisher.publish(PublicationCandidateId("forged")).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.close()
    }
    test("engine requirements revoke a candidate before effects") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val candidate = fixture.ready()
        fixture.engineInputs = EngineImplementationInputs(emptySet(), com.typewritermc.checking.InputToken("new"))
        fixture.publisher.publish(candidate.candidate).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.close()
    }
    test("saved invalidation automatically replaces the immutable view and close stops observation") {
        runTest {
            val fixture = PublicationFixture()
            fixture.publisher.start(backgroundScope, fixture.views.changes)
            runCurrent()
            val first = fixture.publisher.views.value
            fixture.update("Story")
            runCurrent()
            (fixture.publisher.views.value.id == first.id) shouldBe false
            fixture.ready()
            fixture.publisher.close()
            val closed = fixture.publisher.views.value
            fixture.update("Later")
            runCurrent()
            fixture.publisher.views.value shouldBe closed
            fixture.views.close()
        }
    }
    test("Page compilation preserves shard bytes and format metadata") {
        val fixture = PublicationFixture()
        fixture.views.capture().use { capture ->
            val expected =
                with(capture.root) {
                    PageCompiler(emptySet(), fixture.bindings.associateBy(NativeBindingRequirement::actual)).compile(ResourceId("page"))
                }.shouldBeInstanceOf<PageCompileResult.Success>()
            val inputs = CompilationInputs(capture.root, fixture.bindings)
            val artifact = with(inputs) { pageCompilation().compile().single() }.shouldBeInstanceOf<CompilationResult.Success>().artifact
            artifact.formatRevision shouldBe 2
            artifact.mediaType shouldBe "application/vnd.typewriter.page+json"
            artifact.inputFingerprint shouldBe expected.inputFingerprint
            artifact.semanticDigest shouldBe expected.shard.digest
            artifact.payload.toList() shouldBe
                expected.shard.facts
                    .encodeShard()
                    .toList()
        }
        fixture.close()
    }
}

internal class PublicationFixture(
    initial: Map<ResourceId, com.typewritermc.authoring.AuthoringRecord> = mapOf(ResourceId("page") to publicationPageRecord("Quest")),
    producers: List<CompiledArtifactProducer> = listOf(PageCompiledArtifactProducer()),
) {
    val views =
        InMemoryAuthoringViewStore(
            TestCatalogLease(definitions = PUBLICATION_DEFINITIONS, resourceRoot = PUBLICATION_PAGE),
            AuthoringSeed(initial),
        )
    val attempts = RecordingAttempts()
    val bindings = listOf(NativeBindingRequirement(PUBLICATION_PAGE_USE, NativeBindingId("publication_page"), "page:v1"))
    val root = CompilationRoot(CompilationProjectionId("typewriter.page"), ResourceId("page"))
    var engineInputs = testEngineInputs()
    var blobRequests = 0
    var captureFailure = false
    private val blobs = InMemoryBlobEndpoint()
    val publisher =
        RealmPublicationCoordinator(
            object : PublicationAcceptance {
                override fun capture(): AuthoringLease {
                    check(!captureFailure) { "Saved content is unavailable" }
                    return views.capture()
                }

                override fun <T> withCurrent(block: (AuthoringView) -> T): T = views.read(block)

                override suspend fun evaluate(capture: AuthoringLease) =
                    AuthoringAssessment.Accepted(
                        AcceptedAuthoring(capture.root.catalog.generation, CheckCoverage(emptySet(), emptySet()), emptyList(), bindings),
                    )
            },
            attempts,
            RegisteredCompiledArtifactStore(
                object : BlobEndpoint by blobs {
                    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> {
                        blobRequests++
                        return blobs.metadata(digest)
                    }
                },
            ),
            object : EngineImplementationSource {
                override fun capture() = engineInputs
            },
            CompiledArtifactProducerRegistry(producers),
            attempts,
        )

    fun ready() =
        publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.Ready>()

    fun update(value: String) = views.install(views.prepare(AuthoringViewDelta(mapOf(ResourceId("page") to publicationPageRecord(value)))))

    suspend fun release(): PublicationResult.Activated {
        publisher.refresh()
        return publisher.publish(ready().candidate).shouldBeInstanceOf<PublicationResult.Activated>()
    }

    fun compiled(value: String): CompiledArtifact {
        val store =
            InMemoryAuthoringViewStore(
                TestCatalogLease(definitions = PUBLICATION_DEFINITIONS, resourceRoot = PUBLICATION_PAGE),
                AuthoringSeed(
                    mapOf(ResourceId("page") to publicationPageRecord(value)),
                ),
            )
        try {
            return store.capture().use { capture ->
                with(CompilationInputs(capture.root, bindings)) {
                    pageCompilation().compile().single()
                }.shouldBeInstanceOf<CompilationResult.Success>().artifact
            }
        } finally {
            store.close()
        }
    }

    suspend fun close() {
        publisher.close()
        views.close()
    }
}

internal class RecordingAttempts :
    PublicationAttemptStore,
    PublicationResults {
    var started = 0
    var installed: PublishedContent? = null
    var beforeStart: suspend () -> Unit = {}
    val phases = mutableListOf<PublicationState>()

    override suspend fun start(
        id: PublicationId,
        catalog: CatalogGeneration,
        engineInputs: EngineImplementationInputs,
    ) {
        started++
        beforeStart()
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
    ) {}

    override suspend fun install(result: PublishedContent) {
        installed = result
    }

    override suspend fun interruptUnfinished() {}

    override suspend fun selected() = installed

    override suspend fun latestReport(): PublicationReport? = null
}

private fun blockedProducer() =
    object : CompiledArtifactProducer {
        override val projection = CompilationProjectionId("fixture.blocked")
        override val mediaType = "application/blocked"

        override fun roots(view: AuthoringView) = setOf(CompilationRoot(projection, ResourceId("broken")))

        context(inputs: CompilationInputs)
        override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> =
            listOf(
                CompilationResult.Blocked(
                    roots.single(),
                    ContentDigest("a".repeat(64)),
                    listOf(
                        CompileDiagnostic(
                            "broken_link",
                            "The target is missing",
                            CompileDiagnosticSeverity.ERROR,
                            ResourceId("broken"),
                            ResourceId("target"),
                        ),
                    ),
                ),
            )
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
