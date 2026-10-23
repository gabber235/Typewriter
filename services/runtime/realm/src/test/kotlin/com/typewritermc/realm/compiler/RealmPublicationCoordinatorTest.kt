package com.typewritermc.realm.compiler

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.encodeShard
import com.typewritermc.engine.semanticDigest
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
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationBaseline
import skirout.editor.v1.publication.PublicationCandidateId
import skirout.editor.v1.publication.PublicationChange
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.publication.PublicationStatus
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import skirout.editor.v1.type_catalog.PublicationId as SkirPublicationId

val RealmPublicationCoordinatorTest by testSuite {
    test("checking preserves runtime invalidation even when authoring witnesses still match") {
        val fixture = PublicationFixture()
        try {
            val location = ValueLocation.of(ResourceId(value = "page"))
            val current =
                fixture.views.read { view ->
                    FindingSet(
                        ticket =
                            CheckTicket(
                                instance =
                                    CheckInstanceId(
                                        rule =
                                            skirout.editor.v1.type_catalog.RuleId(
                                                origin =
                                                    skirout.editor.v1.type_catalog
                                                        .RuleOrigin(owner = PUBLICATION_PAGE, ordinal = 0),
                                                localIndex = 0,
                                            ),
                                        location = location,
                                    ),
                                incarnation = "external_input",
                                execution = CheckExecutionId(value = "execution"),
                                catalog = view.catalog.generation,
                            ),
                        expectations =
                            listOf<skirout.editor.v1.authoring_facts.EditExpectation>(
                                skirout.editor.v1.authoring_facts.EditExpectation
                                    .createResource(id = location.resource, expected = view.resources.getValue(location.resource)),
                            ),
                        outcome = CheckOutcome.FINISHED,
                        findings =
                            listOf(
                                compilationDiagnostic("external_check", "An external input requires attention.", location = location),
                            ),
                        status = skirout.editor.v1.checking.FindingStatus.CURRENT,
                    )
                }
            val invalidated =
                current.copy(
                    ticket =
                        current.ticket.copy(
                            instance =
                                current.ticket.instance.copy(
                                    rule =
                                        current.ticket.instance.rule
                                            .copy(localIndex = 1),
                                ),
                        ),
                    status = skirout.editor.v1.checking.FindingStatus.OUTDATED,
                )
            fixture.findings = listOf(current, invalidated)
            var observed: PublicationStatus.Checking? = null
            fixture.onEvaluate = { observed = (fixture.publisher.views.value.status as PublicationStatus.CheckingWrapper).value }
            fixture.publisher.refresh()
            observed!!.findings.map { it.status } shouldBe
                listOf(
                    skirout.editor.v1.checking.FindingStatus.CURRENT,
                    skirout.editor.v1.checking.FindingStatus.OUTDATED,
                )
        } finally {
            fixture.close()
        }
    }
    test("preparing and unchanged content create no attempt or blob write") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.ReadyWrapper>()
            .value
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.release()
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.CurrentWrapper>()
            .value
        fixture.publisher.publish(PublicationCandidateId(value = "obsolete")) shouldBe PublicationResult.NoChanges
        fixture.attempts.started shouldBe 1
        fixture.close()
    }
    test("unchanged assessment cannot repair or report an obsolete selected publication") {
        runTest {
            val fixture = PublicationFixture()
            try {
                val first = fixture.release().content
                val digest =
                    ArtifactDigest(
                        com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm.SHA_256,
                        first.outputs
                            .single()
                            .blob.digest,
                    )
                fixture.blobs.remove(digest)
                val assessing = CompletableDeferred<Unit>()
                val resume = CompletableDeferred<Unit>()
                fixture.onEvaluate = {
                    assessing.complete(Unit)
                    resume.await()
                }
                val refresh = async { fixture.publisher.refresh() }
                assessing.await()
                val replacement = first.copy(publication = PublicationId(value = "replacement"), outputs = emptyList())
                fixture.attempts.install(replacement)
                val requests = fixture.blobRequests
                resume.complete(Unit)
                refresh.await()

                fixture.blobRequests shouldBe requests
                fixture.blobs.metadata(digest) shouldBe BlobResult.NotFound
                fixture.attempts.selected() shouldBe replacement
                fixture.publisher.views.value.status
                    .shouldBeInstanceOf<PublicationStatus.CheckingWrapper>()
                    .value

                fixture.onEvaluate = null
                fixture.publisher.refresh()
                fixture.ready().baseline shouldBe
                    PublicationBaseline.SelectedWrapper(SkirPublicationId(value = replacement.publication.value))
            } finally {
                fixture.close()
            }
        }
    }
    test("initial empty content stays empty while removing the last root is a release") {
        val fixture = PublicationFixture(initial = emptyMap())
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.EmptyWrapper>()
            .value
        fixture.attempts.started shouldBe 0
        fixture.update("Quest")
        fixture.release()
        fixture.views.install(fixture.views.prepare(AuthoringViewDelta(emptyMap(), removedResources = setOf(ResourceId(value = "page")))))
        fixture.publisher.refresh()
        val ready =
            fixture.publisher.views.value.status
                .shouldBeInstanceOf<PublicationStatus.ReadyWrapper>()
                .value
        ready.changes.allChanges shouldBe listOf(PublicationChange.RootRemovedWrapper(fixture.root))
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
            PublishedContent(
                publication = PublicationId(value = "other"),
                formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
                catalog = CatalogGeneration(value = "other"),
                implementationToken = "implementation",
                outputs = emptyList(),
            )
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
            .shouldBeInstanceOf<PublicationStatus.CurrentWrapper>()
            .value
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
            .shouldBeInstanceOf<PublicationStatus.UnavailableWrapper>()
            .value
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
                    .shouldBeInstanceOf<PublicationStatus.PublishingWrapper>()
                    .value
            active.next.confirmedChanges shouldBe listOf(PublicationChange.RootUpdatedWrapper(fixture.root))
            proceed.complete(Unit)
            val published = first.await().shouldBeInstanceOf<PublicationResult.Activated>()
            val expected = fixture.compiled("Quest")
            published.content.outputs
                .single()
                .reference.semanticDigest shouldBe expected.semanticDigest.value
            fixture.publisher.refresh()
            fixture.ready().changes.allChanges shouldBe listOf(PublicationChange.RootUpdatedWrapper(fixture.root))
            fixture.attempts.started shouldBe 1
            fixture.close()
        }
    }
    test("blocked compilation retains successful roots and source and target locations without effects") {
        val fixture = PublicationFixture(producers = listOf(ResourceGraphArtifactProducer, blockedProducer()))
        fixture.publisher.refresh()
        val blocked =
            fixture.publisher.views.value.status
                .shouldBeInstanceOf<PublicationStatus.BlockedWrapper>()
                .value
        blocked.confirmedChanges shouldBe listOf(PublicationChange.RootAddedWrapper(fixture.root))
        blocked.pendingRoots.single().resource shouldBe ResourceId(value = "broken")
        blocked.blockers.first.details.primary
            ?.resource shouldBe ResourceId(value = "broken")
        blocked.blockers.first.details.related
            .single()
            .resource shouldBe ResourceId(value = "target")
        fixture.attempts.started shouldBe 0
        fixture.blobRequests shouldBe 0
        fixture.publisher.publish(PublicationCandidateId(value = "forged")).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.close()
    }
    test("engine requirements revoke a candidate before effects") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val candidate = fixture.ready()
        fixture.engineInputs =
            EngineImplementationInputs(
                token =
                    skirout.editor.v1.type_catalog
                        .InputToken(value = "new"),
            )
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
    test("resource graph compilation preserves shard bytes and format metadata") {
        val fixture = PublicationFixture()
        fixture.views.capture().use { capture ->
            val expected =
                with(capture.root) {
                    OwnershipClosureCompiler(
                        emptySet(),
                        testAssessment(capture.root, fixture.bindings).resources,
                    ).compile(ResourceId(value = "page"))
                }.shouldBeInstanceOf<ResourceGraphCompileResult.Success>()
            val inputs = CompilationInputs(capture.root, testAssessment(capture.root, fixture.bindings).resources)
            val artifact =
                with(
                    inputs,
                ) { resourceGraphCompilation().compile().single() }.shouldBeInstanceOf<CompilationResult.Success>().artifact
            artifact.formatRevision shouldBe com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION
            artifact.mediaType shouldBe "application/vnd.typewriter.resource-graph+json"
            artifact.inputFingerprint shouldBe expected.inputFingerprint
            artifact.semanticDigest shouldBe expected.shard.semanticDigest
            artifact.payload.toList() shouldBe
                expected.shard.facts
                    .encodeShard()
                    .toList()
        }
        fixture.close()
    }
}

internal class PublicationFixture(
    initial: Map<ResourceId, AuthoringRecord> = mapOf(ResourceId(value = "page") to publicationPageRecord("Quest")),
    producers: List<CompiledArtifactProducer> = listOf(ResourceGraphArtifactProducer),
) {
    val views =
        InMemoryAuthoringViewStore(
            TestCatalogLease(definitions = PUBLICATION_DEFINITIONS),
            AuthoringSeed(initial),
        )
    val attempts = RecordingAttempts()
    val bindings = listOf(NativeBindingRequirement(PUBLICATION_PAGE_USE, NativeBindingId(value = "publication_page"), "page:v1"))
    val root =
        CompilationRoot(projection = CompilationProjectionId(value = "typewriter.resource-graph"), resource = ResourceId(value = "page"))
    var engineInputs = testEngineInputs()
    var blobRequests = 0
    var captureFailure = false
    var findings = emptyList<FindingSet>()
    var onEvaluate: (suspend () -> Unit)? = null
    val blobs = InMemoryBlobEndpoint()
    val publisher =
        RealmPublicationCoordinator(
            object : PublicationAcceptance {
                override fun capture(): AuthoringLease {
                    check(!captureFailure) { "Saved content is unavailable" }
                    return views.capture()
                }

                override fun <T> withCurrent(block: (AuthoringView) -> T): T = views.read(block)

                override suspend fun evaluate(capture: AuthoringLease): CapturedAssessment {
                    onEvaluate?.invoke()
                    return testAssessment(capture.root, bindings)
                }
            },
            attempts,
            RegisteredCompiledArtifactStore(
                object : BlobEndpoint by blobs {
                    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> {
                        blobRequests++
                        return blobs.metadata(digest)
                    }
                },
                TestPublicationRetention(),
            ),
            object : EngineImplementationSource {
                override fun capture() = engineInputs
            },
            CompiledArtifactProducerRegistry(producers),
            attempts,
            findings = { findings },
        )

    fun ready() =
        publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.ReadyWrapper>()
            .value

    fun update(value: String) =
        views.install(
            views.prepare(
                AuthoringViewDelta(
                    mapOf(ResourceId(value = "page") to publicationPageRecord(value)),
                ),
            ),
        )

    suspend fun release(): PublicationResult.Activated {
        publisher.refresh()
        return publisher.publish(ready().candidate).shouldBeInstanceOf<PublicationResult.Activated>()
    }

    fun compiled(value: String): CompiledArtifact {
        val store =
            InMemoryAuthoringViewStore(
                TestCatalogLease(definitions = PUBLICATION_DEFINITIONS),
                AuthoringSeed(
                    mapOf(ResourceId(value = "page") to publicationPageRecord(value)),
                ),
            )
        try {
            return store.capture().use { capture ->
                with(CompilationInputs(capture.root, testAssessment(capture.root, bindings).resources)) {
                    resourceGraphCompilation().compile().single()
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
        findings: List<Diagnostic>,
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
        override val projection = CompilationProjectionId(value = "fixture.blocked")
        override val mediaType = "application/blocked"

        override fun roots(view: AuthoringView) = setOf(CompilationRoot(projection = projection, resource = ResourceId(value = "broken")))

        context(inputs: CompilationInputs)
        override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> =
            listOf(
                CompilationResult.Blocked(
                    roots.single(),
                    ContentDigest("a".repeat(64)),
                    listOf(
                        compilationDiagnostic(
                            "broken_link",
                            "The target is missing",
                            DiagnosticSeverity.ERROR,
                            ResourceId(value = "broken"),
                            ResourceId(value = "target"),
                        ),
                    ),
                ),
            )
    }

private fun publicationPageRecord(value: String) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(PUBLICATION_PAGE_USE),
        mapOf("value" to DataValue.StringValueWrapper(value)),
    )

private val PUBLICATION_PAGE = TypeDefinitionId.qualified("publication", "page")
private val PUBLICATION_PAGE_USE = PUBLICATION_PAGE.namedUse()
private val PUBLICATION_DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = CompilationUnitDefinition.id,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
        ),
        TypeDefinition.partial(
            id = PUBLICATION_PAGE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = PUBLICATION_PAGE, name = "value"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = false,
                ),
            parents = listOf(CompilationUnitDefinition.id.namedTemplate()),
        ),
    )

private fun resourceGraphCompilation() = CompiledArtifactProducerRegistry(listOf(ResourceGraphArtifactProducer))
